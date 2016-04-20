#pragma once

#include "point2d.hpp"

#include "std/vector.hpp"

namespace m2
{

template <typename T> struct Triangle
{
  Point<T> m_points[3];

  Triangle(Point<T> const & p1, Point<T> const & p2, Point<T> const & p3)
  {
    m_points[0] = p1;
    m_points[1] = p2;
    m_points[2] = p3;
  }

  Point<T> const & p1() const { return m_points[0]; }
  Point<T> const & p2() const { return m_points[1]; }
  Point<T> const & p3() const { return m_points[2]; }
};

using TriangleF = Triangle<float>;
using TriangleD = Triangle<double>;

template <class T>
double GetTriangleArea(Point<T> const & p1, Point<T> const & p2, Point<T> const & p3)
{
  return 0.5 * fabs((p2.x - p1.x)*(p3.y - p1.y) - (p3.x - p1.x)*(p2.y - p1.y));
}

m2::PointD GetRandomPointInsideTriangle(m2::TriangleD const & t);
m2::PointD GetRandomPointInsideTriangles(vector<m2::TriangleD> const & v);

m2::PointD GetNearestPointToTriangles(m2::PointD const & pt, vector<m2::TriangleD> const & v);

/// @param[in] pt - Point to check
/// @param[in] p1, p2, p3 - Triangle
//@{
bool IsPointInsideTriangle(m2::PointD const & pt, m2::PointD const & p1,
                           m2::PointD const & p2, m2::PointD const & p3);

bool IsPointStrictlyInsideTriangle(m2::PointD const & pt, m2::PointD const & p1,
                                   m2::PointD const & p2, m2::PointD const & p3);

bool IsPointInsideTriangles(m2::PointD const & pt, vector<m2::TriangleD> const & v);
//@}

} // namespace m2
