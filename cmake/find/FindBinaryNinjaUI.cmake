# Try to find Binary Ninja UI
# Once done this will define
#  BinaryNinjaUI_FOUND - If Binary Ninja UI is found
#  BinaryNinjaUI_INCLUDE_DIRS - The directories to include for compiling UI plugins
#  BinaryNinjaUI_LIBRARIES - The libraries for linking UI plugins
#  BinaryNinjaUI_LIBRARY_DIRS - The link paths required for ui plugins
#  BinaryNinjaUI_DEFINITIONS - Compiler switches required for UI plugins

include(CMakeFindDependencyMacro)

find_dependency(BinaryNinjaCore)

# Also find Qt6 which is required
find_dependency(Qt6 COMPONENTS Core Gui Widgets)

find_library(BinaryNinjaUI_LIBRARY
    NAMES binaryninjaui libbinaryninjaui.so.1
    HINTS ${BinaryNinjaCore_LIBRARY_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(BinaryNinjaUI
    FOUND_VAR BinaryNinjaUI_FOUND
    REQUIRED_VARS BinaryNinjaUI_LIBRARY
    FAIL_MESSAGE "Could NOT find Binary Ninja UI installation. Check that you are using a valid Binary Ninja, non-headless install, and qmake is in your PATH.")

# Create a library target only if the above checks passed
if(BinaryNinjaUI_FOUND AND NOT TARGET binaryninjaui)
    add_library(binaryninjaui UNKNOWN IMPORTED)

    if(EXISTS "${BinaryNinjaUI_LIBRARY}")
        set_property(
            TARGET binaryninjaui PROPERTY
            IMPORTED_LOCATION "${BinaryNinjaUI_LIBRARY}"
        )
    endif()

    target_link_libraries(binaryninjaui INTERFACE binaryninjacore)
    target_link_libraries(binaryninjaui INTERFACE Qt::Core Qt::Gui Qt::Widgets)
endif()
