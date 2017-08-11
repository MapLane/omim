@objc(MWMRouteManagerViewController)
final class RouteManagerViewController: MWMViewController, UITableViewDataSource, UITableViewDelegate {
  let viewModel: RouteManagerViewModelProtocol

  @IBOutlet private var dimView: RouteManagerDimView!
  @IBOutlet private weak var footerViewHeight: NSLayoutConstraint!
  @IBOutlet private weak var headerView: RouteManagerHeaderView!
  @IBOutlet private weak var footerView: RouteManagerFooterView!
  @IBOutlet private weak var headerViewHeight: NSLayoutConstraint!
  @IBOutlet private weak var managerView: UIView!
  @IBOutlet private weak var managerWidth: NSLayoutConstraint!
  @IBOutlet private weak var minManagerTopOffset: NSLayoutConstraint!
  @IBOutlet private weak var tableView: RouteManagerTableView!

  lazy var chromeView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.blackStatusBarBackground()
    return view
  }()

  weak var containerView: UIView!

  final class DragCell {
    weak var controller: RouteManagerViewController!
    let snapshot: UIView
    var indexPath: IndexPath

    init(controller: RouteManagerViewController, cell: UITableViewCell, dragPoint: CGPoint, indexPath: IndexPath) {
      self.controller = controller
      snapshot = cell.snapshot
      self.indexPath = indexPath
      addSubView(cell: cell, dragPoint: dragPoint)
      controller.tableView.heightUpdateStyle = .off
      controller.dimView.state = .visible
    }

    private func addSubView(cell: UITableViewCell, dragPoint: CGPoint) {
      let view = controller.containerView!
      view.addSubview(snapshot)
      snapshot.center = view.convert(cell.center, from: controller.tableView)
      cell.isHidden = true
      UIView.animate(withDuration: kDefaultAnimationDuration,
                     animations: { [snapshot] in
                      snapshot.center = dragPoint
                      let scaleFactor: CGFloat = 1.05
                      snapshot.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        })
    }

    func move(dragPoint: CGPoint, indexPath: IndexPath?, inManagerView: Bool) {
      snapshot.center = dragPoint
      controller.dimView.state = inManagerView ? .visible : .binOpenned
      guard let indexPath = indexPath else { return }
      let tv = controller.tableView!
      let cell = tv.cellForRow(at: indexPath)
      let canMoveCell: Bool
      if let cell = cell {
        let (centerX, centerY) = (snapshot.width / 2, snapshot.height / 2)
        canMoveCell = cell.point(inside: cell.convert(CGPoint(x: centerX, y: 1.5 * centerY), from: snapshot), with: nil) &&
                      cell.point(inside: cell.convert(CGPoint(x: centerX, y: 0.5 * centerY), from: snapshot), with: nil)
      } else {
        canMoveCell = true
      }
      guard canMoveCell else { return }
      let selfIndexPath = self.indexPath
      if indexPath != selfIndexPath {
        controller.viewModel.movePoint(at: selfIndexPath.row, to: indexPath.row)

        tv.moveRow(at: selfIndexPath, to: indexPath)
        tv.reloadRows(at: [selfIndexPath, indexPath], with: .fade)
        tv.cellForRow(at: indexPath)?.isHidden = true

        self.indexPath = indexPath
      }
    }

    func drop(inManagerView: Bool) {
      let removeSnapshot = {
        self.snapshot.removeFromSuperview()
        self.controller.dimView.state = .hidden
      }
      let containerView = controller.containerView!
      let tv = controller.tableView!
      if inManagerView {
        let dropCenter = tv.cellForRow(at: indexPath)?.center ?? snapshot.center
        UIView.animate(withDuration: kDefaultAnimationDuration,
                       animations: { [snapshot] in
                        snapshot.center = containerView.convert(dropCenter, from: tv)
                        snapshot.transform = CGAffineTransform.identity
          },
                       completion: { [indexPath] _ in
                        tv.reloadRows(at: [indexPath], with: .none)
                        removeSnapshot()
        })
      } else {
        controller.viewModel.deletePoint(at: indexPath.row)
        tv.heightUpdateStyle = .animated
        tv.deleteRows(at: [indexPath], with: .automatic)
        let dimView = controller.dimView!
        UIView.animate(withDuration: kDefaultAnimationDuration,
                       animations: { [snapshot] in
                        snapshot.center = containerView.convert(dimView.binDropPoint, from: dimView)
                        let scaleFactor: CGFloat = 0.2
                        snapshot.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
          },
                       completion: { _ in
                        removeSnapshot()
        })
      }
    }

    deinit {
      controller.tableView.heightUpdateStyle = .deferred
    }
  }

  var dragCell: DragCell?

  init(viewModel: RouteManagerViewModelProtocol) {
    self.viewModel = viewModel
    super.init(nibName: toString(type(of: self)), bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
    setupLayout()

    viewModel.refreshControlsCallback = { [unowned viewModel, unowned self] in
      let points = viewModel.routePoints
      self.footerView.isPlanButtonEnabled = points.count >= 2
      self.headerView.isLocationButtonEnabled = true
      points.forEach {
        if $0.isMyPosition {
          self.headerView.isLocationButtonEnabled = false
        }
      }
    }
    viewModel.refreshControlsCallback()
    viewModel.startTransaction()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    dimView.setViews(container: containerView, controller: view, manager: managerView)
    containerView.insertSubview(chromeView, at: 0)
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    if preferredContentSize != managerView.size {
      preferredContentSize = managerView.size
    }
  }

  private func setupLayout() {
    alternative(iPhone: { self.managerWidth.isActive = false },
                iPad: { self.minManagerTopOffset.isActive = false })()
  }

  private func setupTableView() {
    tableView.register(cellClass: RouteManagerCell.self)
    tableView.estimatedRowHeight = 48
    tableView.rowHeight = UITableViewAutomaticDimension
  }

  @IBAction func onCancel() {
    viewModel.cancelTransaction()
    dismiss(animated: true, completion: nil)
  }

  @IBAction func onPlan() {
    viewModel.finishTransaction()
    dismiss(animated: true, completion: nil)
  }

  @IBAction func onAdd() {
    viewModel.addLocationPoint()
    tableView.heightUpdateStyle = .off
    tableView.update({
      tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
    }, completion: {
      self.tableView.heightUpdateStyle = .deferred
    })
  }

  @IBAction private func longPressGestureRecognized(_ longPress: UILongPressGestureRecognizer) {
    let locationInView = gestureLocation(longPress, in: containerView)
    let locationInTableView = gestureLocation(longPress, in: tableView)
    switch longPress.state {
    case .began:
      guard let indexPath = tableView.indexPathForRow(at: locationInTableView),
            let cell = tableView.cellForRow(at: indexPath) else { return }
      dragCell = DragCell(controller: self, cell: cell, dragPoint: locationInView, indexPath: indexPath)
    case .changed:
      guard let dragCell = dragCell else { return }
      let indexPath = tableView.indexPathForRow(at: locationInTableView)
      let inManagerView = managerView.point(inside: gestureLocation(longPress, in: managerView), with: nil)
      dragCell.move(dragPoint: locationInView, indexPath: indexPath, inManagerView: inManagerView)
    default:
      guard let dragCell = dragCell else { return }
      let inManagerView = managerView.point(inside: gestureLocation(longPress, in: managerView), with: nil)
      dragCell.drop(inManagerView: inManagerView)
      self.dragCell = nil
    }
  }

  private func gestureLocation(_ gestureRecognizer: UIGestureRecognizer, in view: UIView) -> CGPoint {
    var location = gestureRecognizer.location(in: view)
    iPhoneSpecific { location.x = view.width / 2 }
    return location
  }

// MARK: - UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.routePoints.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withCellClass: RouteManagerCell.self, indexPath: indexPath) as! RouteManagerCell
    let row = indexPath.row
    cell.set(model: viewModel.routePoints[row], atIndex: row)
    return cell
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    viewModel.deletePoint(at: indexPath.row)
    tableView.deleteRows(at: [indexPath], with: .automatic)
  }

// MARK: - UITableViewDelegate
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    return .delete
  }
}