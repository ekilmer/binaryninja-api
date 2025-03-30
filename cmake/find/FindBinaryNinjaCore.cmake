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

if(BinaryNinjaCore_LIBRARY)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        BinaryNinjaCore DEFAULT_MSG BinaryNinjaCore_LIBRARY
    )
else()
    set(BinaryNinjaCore_FOUND True)
    message(STATUS "Found BinaryNinjaCore: INTERFACE library binaryninjacore")
endif()

if(BinaryNinjaCore_FOUND AND NOT TARGET binaryninjacore)
    if(EXISTS "${BinaryNinjaCore_LIBRARY}")
        add_library(binaryninjacore UNKNOWN IMPORTED)

        get_filename_component(BinaryNinjaCore_LIBRARY_DIR "${BinaryNinjaCore_LIBRARY}" DIRECTORY)
        set_property(
            TARGET binaryninjacore PROPERTY
            IMPORTED_LOCATION "${BinaryNinjaCore_LIBRARY}"
        )

        # TODO: Figure out if this variable should be removed
        if(NOT DEFINED BN_INSTALL_BIN_DIR)
            set(BN_INSTALL_BIN_DIR "${BinaryNinjaCore_LIBRARY_DIR}" CACHE PATH "Binary Ninja Core Library Directory")
        endif()
        message(STATUS "Binary Ninja Core Library Directory: ${BN_INSTALL_BIN_DIR}")
    else()
        add_library(binaryninjacore INTERFACE IMPORTED)

        # Allow building of plugins without an installation of Binary Ninja
        if(APPLE)
            target_link_options(binaryninjacore INTERFACE -undefined dynamic_lookup)
        elseif(MSVC)
            target_link_options(binaryninjacore INTERFACE "/FORCE:UNRESOLVED")
        else()
            target_link_options(binaryninjacore INTERFACE "LINKER:--allow-shlib-undefined")
        endif()
    endif()
endif()
