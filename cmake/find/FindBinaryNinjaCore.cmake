# NOTE: Do not use find_package(... REQUIRED) unless you _require_ linking
# against actual Core library (like for testing)

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
    if(TARGET binaryninjaapi)
        # Assume the installed library lives next to the API
        get_target_property(_api_lib_loc binaryninjaapi IMPORTED_LOCATION)
        list(APPEND PATH_HINTS "${api_lib_loc}")
    endif()
elseif(APPLE)
    if(DEFINED BN_INSTALL_DIR)
        list(APPEND PATH_HINTS "${BN_INSTALL_DIR}/Contents/MacOS")
    endif()
    if(DEFINED ENV{BN_INSTALL_DIR})
        list(APPEND PATH_HINTS "$ENV{BN_INSTALL_DIR}/Contents/MacOS")
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

# Allow missing binaryninjacore library file, so we can build without an
# installation of Binary Ninja
if(BinaryNinjaCore_LIBRARY)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        BinaryNinjaCore DEFAULT_MSG BinaryNinjaCore_LIBRARY
    )
else()
    # Windows installs a stub library for linking
    set(_stub_target_file "${CMAKE_CURRENT_LIST_DIR}/BinaryNinjaCoreStubTargets.cmake")
    if(EXISTS "${_stub_target_file}")
        include("${_stub_target_file}")
        set(BinaryNinjaCore_FOUND True)
    else()
        set(BinaryNinjaCore_FOUND False)
    endif()
endif()

if(NOT TARGET binaryninjacore)
    if(BinaryNinjaCore_FOUND AND EXISTS "${BinaryNinjaCore_LIBRARY}")
        add_library(binaryninjacore UNKNOWN IMPORTED)

        get_filename_component(BinaryNinjaCore_LIBRARY_DIR "${BinaryNinjaCore_LIBRARY}" DIRECTORY)
        set_property(
            TARGET binaryninjacore PROPERTY
            IMPORTED_LOCATION "${BinaryNinjaCore_LIBRARY}"
        )

        # TODO: Figure out if this variable should be removed or attached to the target?
        if(NOT DEFINED BN_INSTALL_BIN_DIR)
            set(BN_INSTALL_BIN_DIR "${BinaryNinjaCore_LIBRARY_DIR}" CACHE PATH "Binary Ninja Core Library Directory")
        endif()
        message(STATUS "Binary Ninja Core Library Directory: ${BN_INSTALL_BIN_DIR}")

    # Do not create a target for WIN32. Creation of the target will be taken
    # care of in binaryninja-api CMakeLists.txt with stubs. This shouldn't
    # happen when this file is installed
    elseif(NOT WIN32)
        message(WARNING "Could NOT find BinaryNinjaCore: using INTERFACE library. BinaryNinjaCore allows undefined symbols during linking. This could cause issues at runtime")
        add_library(binaryninjacore INTERFACE IMPORTED)

        if(APPLE)
            target_link_options(binaryninjacore INTERFACE -undefined dynamic_lookup)
        else()
            target_link_options(binaryninjacore INTERFACE "LINKER:--unresolved-symbols=ignore-all")
        endif()
    endif()
endif()
