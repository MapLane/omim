# Map library.

TARGET = map
TEMPLATE = lib
CONFIG += staticlib

ROOT_DIR = ..
DEPENDENCIES = search yg indexer geometry coding base expat

include($$ROOT_DIR/common.pri)

HEADERS += \
    framework.hpp \
    feature_vec_model.hpp \
    events.hpp \
    navigator.hpp \
    drawer_yg.hpp \
    draw_processor.hpp \
    draw_info.hpp \
    window_handle.hpp \
    render_queue.hpp \
    render_queue_routine.hpp \
    information_display.hpp \
    location_state.hpp \
    benchmark_provider.hpp \
    languages.hpp \
    render_policy.hpp \
    tiling_render_policy_mt.hpp \
    tiling_render_policy_st.hpp \
    benchmark_tiling_render_policy_mt.hpp \
    benchmark_framework.hpp \
    framework_factory.hpp \
    render_policy_st.hpp \
    coverage_generator.hpp \
    tiler.hpp \
    tile.hpp \
    tile_cache.hpp

SOURCES += \
    feature_vec_model.cpp \
    framework.cpp \
    navigator.cpp \
    drawer_yg.cpp \
    draw_processor.cpp \
    render_queue.cpp \
    render_queue_routine.cpp \
    information_display.cpp \
    location_state.cpp \
    benchmark_provider.cpp \
    languages.cpp \
    render_policy.cpp \
    benchmark_tiling_render_policy_mt.cpp \
    tiling_render_policy_st.cpp \
    tiling_render_policy_mt.cpp \
    benchmark_framework.cpp \
    framework_factory.cpp \
    render_policy_st.cpp \
    coverage_generator.cpp \
    tiler.cpp \
    tile_cache.cpp \
    tile.cpp

!iphone*:!bada*:!android* {
  HEADERS += qgl_render_context.hpp
  SOURCES += qgl_render_context.cpp
  QT += opengl
}
