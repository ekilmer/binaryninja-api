cmake_minimum_required(VERSION 3.14)

project(BinaryNinjaAPI CXX C)

# Allow building against external, non-vendored, dependencies
option(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES "Use external non-vendored dependencies" OFF)
mark_as_advanced(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)

option(BinaryNinjaAPI_HEADLESS "Whether to build only HEADLESS functionality" ON)
option(BinaryNinjaAPI_BUILD_EXAMPLES "Builds example plugins" OFF)
option(BinaryNinjaAPI_RUST_API "Build the Rust API" OFF)

option(BinaryNinjaAPI_REF_COUNT_DEBUG "Add extra debugging checks for RefCountObject leaks" OFF)
mark_as_advanced(BinaryNinjaAPI_REF_COUNT_DEBUG)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    if (MSVC)
        message(FATAL_ERROR "Binary Ninja is 64-bit only (try -G \"${CMAKE_GENERATOR} Win64\")")
    else()
        message(FATAL_ERROR "Binary Ninja is 64-bit only")
    endif()
endif()

# Helper macro to set variables only if they haven't been defined yet
macro(set_default_var var val)
    if(NOT DEFINED ${var})
        set(${var} "${val}")
    endif()
endmacro()

# All code will be loaded as a shared library, so we must ensure static libraries are PIC
set_default_var(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

if(NOT BUILD_SHARED_LIBS)
    # Hide symbols by default for static library targets
    set_default_var(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
    set_default_var(CMAKE_CXX_VISIBILITY_PRESET "hidden")
    set_default_var(CMAKE_C_VISIBILITY_PRESET "hidden")
endif()

# Allow find_package to use our Find modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/find")

# Include plugin helper functions
include(cmake/BinjaPluginFunctions.cmake)

add_library(binaryninjaapi)
target_sources(binaryninjaapi PRIVATE
    activity.cpp
    architecture.cpp
    backgroundtask.cpp
    basedetection.cpp
    basicblock.cpp
    binaryninjaapi.cpp
    binaryreader.cpp
    binaryview.cpp
    binaryviewtype.cpp
    binarywriter.cpp
    callingconvention.cpp
    collaboration.cpp
    component.cpp
    database.cpp
    databuffer.cpp
    datarenderer.cpp
    debuginfo.cpp
    demangle.cpp
    downloadprovider.cpp
    enterprise.cpp
    exceptions.cpp
    externallibrary.cpp
    ffi.cpp
    fileaccessor.cpp
    filemetadata.cpp
    firmwareninja.cpp
    flowgraph.cpp
    flowgraphlayout.cpp
    flowgraphnode.cpp
    function.cpp
    functionrecognizer.cpp
    highlevelil.cpp
    highlevelilinstruction.cpp
    http.cpp
    interaction.cpp
    languagerepresentation.cpp
    linearviewcursor.cpp
    linearviewobject.cpp
    lineformatter.cpp
    log.cpp
    lowlevelil.cpp
    lowlevelilinstruction.cpp
    mainthread.cpp
    mediumlevelil.cpp
    mediumlevelilinstruction.cpp
    metadata.cpp
    platform.cpp
    plugin.cpp
    pluginmanager.cpp
    project.cpp
    relocationhandler.cpp
    renderlayer.cpp
    scriptingprovider.cpp
    secretsprovider.cpp
    settings.cpp
    tempfile.cpp
    transform.cpp
    type.cpp
    typearchive.cpp
    typecontainer.cpp
    typelibrary.cpp
    typeparser.cpp
    typeprinter.cpp
    undoaction.cpp
    unicode.cpp
    update.cpp
    user.cpp
    websocketprovider.cpp
    workflow.cpp
)
# Vendored (and modified) JsonCpp source
target_sources(binaryninjaapi PRIVATE json/jsoncpp.cpp)

target_include_directories(binaryninjaapi PUBLIC "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>")

if(BinaryNinjaAPI_REF_COUNT_DEBUG)
    target_compile_definitions(binaryninjaapi PUBLIC BN_REF_COUNT_DEBUG)
endif()

target_compile_features(binaryninjaapi PUBLIC cxx_std_17)

if(NOT TARGET binaryninjacore)
    find_package(BinaryNinjaCore)
endif()
target_link_libraries(binaryninjaapi PUBLIC binaryninjacore)

if(NOT BinaryNinjaAPI_HEADLESS)
    set_target_properties(binaryninjaapi
        PROPERTIES BinaryNinjaUI_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/ui"
    )
    if(NOT TARGET binaryninjaui)
        find_package(BinaryNinjaUI REQUIRED)
    endif()
endif()

if(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)
    find_package(fmt REQUIRED)
    find_package(nlohmann_json REQUIRED)
    find_package(RapidJSON REQUIRED)
else()
    add_subdirectory(vendor)
endif()
target_link_libraries(binaryninjaapi PUBLIC
    fmt::fmt
    nlohmann_json::nlohmann_json
    RapidJSON
)

if(BinaryNinjaAPI_RUST_API)
    add_subdirectory(rust)
endif()

if(BinaryNinjaAPI_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(NOT CMAKE_SKIP_INSTALL_RULES)
    if(PROJECT_IS_TOP_LEVEL)
        set(CMAKE_INSTALL_INCLUDEDIR "include/binaryninjaapi" CACHE STRING "")
        set_property(CACHE CMAKE_INSTALL_INCLUDEDIR PROPERTY TYPE PATH)
    endif()

    # find_package(<package>) call for consumers to find this project
    set(package BinaryNinjaAPI)

    include(GNUInstallDirs)

    set(BN_API_HEADERS
        .doxygen.h
        binaryninjaapi.h
        binaryninjacore.h
        enterprise.h
        exceptions.h
        ffi.h
        genericrange.h
        highlevelilinstruction.h
        http.h
        lowlevelilinstruction.h
        mediumlevelilinstruction.h
        rapidjsonwrapper.h
    )
    install(
        FILES ${BN_API_HEADERS}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    install(
        FILES
            json/json-forwards.h
            json/json.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/json
    )
    install(
        DIRECTORY ui
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

    install(
        TARGETS binaryninjaapi
        EXPORT BinaryNinjaAPITargets
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

    # cmake --install build --component BinaryNinjaAPIDistrib --prefix /Applications/Binary\ Ninja.app/Contents/MacOS
    set(vendor_targets "")
    if(NOT BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)
        list(APPEND vendor_targets fmt nlohmann_json RapidJSON)
    endif()
    install(
        TARGETS binaryninjaapi ${vendor_targets}
        LIBRARY
            DESTINATION "api"
            COMPONENT BinaryNinjaAPIDistrib EXCLUDE_FROM_ALL
        PUBLIC_HEADER
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
            COMPONENT BinaryNinjaAPISuppressWarningAndDoNotInstall EXCLUDE_FROM_ALL
    )

    # Allow package maintainers to freely override the path for the configs
    set(
        BinaryNinjaAPI_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${package}"
        CACHE STRING "CMake package config location relative to the install prefix"
    )
    set_property(CACHE BinaryNinjaAPI_INSTALL_CMAKEDIR PROPERTY TYPE PATH)
    mark_as_advanced(BinaryNinjaAPI_INSTALL_CMAKEDIR)

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        cmake/install-config.cmake.in
        install-config.cmake
        INSTALL_DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
        PATH_VARS CMAKE_INSTALL_INCLUDEDIR
    )
    install(
        FILES ${PROJECT_BINARY_DIR}/install-config.cmake
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
        RENAME "${package}Config.cmake"
    )

    install(
        FILES cmake/BinjaPluginFunctions.cmake
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
    )

    install(
        EXPORT BinaryNinjaAPITargets
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
    )

    set(
        BinaryNinjaCore_INSTALL_CMAKEDIR "${CMAKE_INSTALL_DATADIR}/cmake/BinaryNinjaCore"
        CACHE STRING "CMake package config location relative to the install prefix"
    )
    set_property(CACHE BinaryNinjaCore_INSTALL_CMAKEDIR PROPERTY TYPE PATH)
    mark_as_advanced(BinaryNinjaCore_INSTALL_CMAKEDIR)
    install(
        FILES cmake/find/FindBinaryNinjaCore.cmake
        DESTINATION "${BinaryNinjaCore_INSTALL_CMAKEDIR}"
        RENAME BinaryNinjaCoreConfig.cmake
    )

    set(
        BinaryNinjaUI_INSTALL_CMAKEDIR "${CMAKE_INSTALL_DATADIR}/cmake/BinaryNinjaUI"
        CACHE STRING "CMake package config location relative to the install prefix"
    )
    set_property(CACHE BinaryNinjaUI_INSTALL_CMAKEDIR PROPERTY TYPE PATH)
    mark_as_advanced(BinaryNinjaUI_INSTALL_CMAKEDIR)
    install(
        FILES cmake/find/FindBinaryNinjaUI.cmake
        DESTINATION "${BinaryNinjaUI_INSTALL_CMAKEDIR}"
        RENAME BinaryNinjaUIConfig.cmake
    )
endif()
