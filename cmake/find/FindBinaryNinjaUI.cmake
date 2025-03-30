option(BinaryNinjaUI_COMPILE_ONLY_QT
    "Do not link against Qt targets. Useful when building plugins against system Qt. Requires CMake 3.27+"
    OFF
)

include(CMakeFindDependencyMacro)

# NOTE: We only need to find BinaryNinjaAPI because the binaryninjaapi target
#   knows where the UI include directory is located. This (likely) also follows
#   the internal BinaryNinja build dependency organization
if(NOT TARGET binaryninjaapi)
    find_dependency(BinaryNinjaAPI
        # Assume default installation options
        HINTS ${CMAKE_CURRENT_LIST_DIR}/../../..
    )
endif()

find_dependency(Qt6 COMPONENTS Core Gui Widgets)

find_library(BinaryNinjaUI_LIBRARY
    NAMES binaryninjaui libbinaryninjaui.so.1
    HINTS ${BinaryNinjaCore_LIBRARY_DIR}
)

# Allow missing binaryninjaui library file, so we can build in CI more easily
if(BinaryNinjaUI_LIBRARY)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        BinaryNinjaUI DEFAULT_MSG BinaryNinjaUI_LIBRARY
    )
else()
    message(AUTHOR_WARNING "Could not find BinaryNinjaUI_LIBRARY. Continuing without")
    set(BinaryNinjaUI_FOUND True)
endif()

# Create a library target only if the above checks passed
if(BinaryNinjaUI_FOUND AND NOT TARGET binaryninjaui)
    if(EXISTS "${BinaryNinjaUI_LIBRARY}")
        add_library(binaryninjaui UNKNOWN IMPORTED)
        set_property(
            TARGET binaryninjaui PROPERTY
            IMPORTED_LOCATION "${BinaryNinjaUI_LIBRARY}"
        )
    else()
        add_library(binaryninjaui INTERFACE IMPORTED)
    endif()

    target_link_libraries(binaryninjaui INTERFACE binaryninjaapi)

    set(_bn_qt_targets Qt::Core Qt::Gui Qt::Widgets)
    # We want everything from the Qt targets _except_ real linking, but we can
    # only do that with CMake version greater or equal to 3.27.0
    if(NOT BinaryNinjaUI_COMPILE_ONLY_QT OR CMAKE_VERSION VERSION_LESS "3.27.0")
        target_link_libraries(binaryninjaui INTERFACE ${_bn_qt_targets})
    else()
        target_link_libraries(binaryninjaui INTERFACE $<COMPILE_ONLY:${_bn_qt_targets}>)
    endif()

    get_target_property(_ui_include_dir binaryninjaapi BinaryNinjaUI_INCLUDE_DIR)
    target_include_directories(binaryninjaui INTERFACE "${_ui_include_dir}")
endif()
