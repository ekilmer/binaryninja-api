# Try to find a Binary Ninja installation
# Once done this will define
#  BinaryNinjaCore_FOUND - If Binary Ninja Core is found
#  BinaryNinjaCore_ROOT_DIR - The installation path of Binary Ninja
#  BinaryNinjaCore_USER_PLUGINS_DIR - The path for user plugins
#  BinaryNinjaCore_INCLUDE_DIRS - The directories to include for compiling core plugins
#  BinaryNinjaCore_LIBRARY - The library for linking core plugins
#  BinaryNinjaCore_LIBRARY_DIRS - The link paths required for core plugins
#  BinaryNinjaCore_DEFINITIONS - Compiler switches required for core plugins
#
# According to Good CMake Hygiene, we should use BinaryNinjaCore_<VAR> named variables.
# Existing plugins likely use BN_<VAR> names already, so both are provided.

set(PATH_HINTS "")
if(DEFINED ENV{BN_INSTALL_DIR})
    list(APPEND PATH_HINTS "$ENV{BN_INSTALL_DIR}")
endif()
if(DEFINED BN_INSTALL_DIR)
    list(APPEND PATH_HINTS "${BN_INSTALL_DIR}")
endif()

# Set OS-specific paths
if(WIN32)
    # System-wide install
    list(APPEND PATH_HINTS "C:\\Program Files\\Vector35\\BinaryNinja")
    # User install
    list(APPEND PATH_HINTS "$ENV{LocalAppData}\\Vector35\\BinaryNinja")
elseif(APPLE)
    if(DEFINED ENV{BN_INSTALL_DIR})
        list(APPEND PATH_HINTS "$ENV{BN_INSTALL_DIR}/Contents/MacOS")
    endif()
    if(DEFINED BN_INSTALL_DIR)
        list(APPEND PATH_HINTS "${BN_INSTALL_DIR}/Contents/MacOS")
    endif()
    list(APPEND PATH_HINTS "/Applications/Binary Ninja.app/Contents/MacOS")
    list(APPEND PATH_HINTS "$ENV{HOME}/Applications/Binary Ninja.app/Contents/MacOS")
else()
    list(APPEND PATH_HINTS "$ENV{HOME}/binaryninja")
endif()

find_library(BinaryNinjaCore_LIBRARY
    NAMES binaryninjacore
    HINTS ${PATH_HINTS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    BinaryNinjaCore DEFAULT_MSG BinaryNinjaCore_LIBRARY
)

# Create a library target only if the above checks passed
if(BinaryNinjaCore_FOUND AND NOT TARGET binaryninjacore)
    add_library(binaryninjacore UNKNOWN IMPORTED)

    if(EXISTS "${BinaryNinjaCore_LIBRARY}")
        set_property(
            TARGET binaryninjacore PROPERTY
            IMPORTED_LOCATION "${BinaryNinjaCore_LIBRARY}"
        )
        get_filename_component(BinaryNinjaCore_LIBRARY_DIR "${BinaryNinjaCore_LIBRARY}" DIRECTORY)
    endif()
endif()
