cmake_minimum_required(VERSION 3.14)

project(BinaryNinjaAPI CXX C)

macro(set_default_var var val)
    if(NOT DEFINED ${var})
        set(${var} "${val}")
    endif()
endmacro()
# Hide symbols by default
set_default_var(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
set_default_var(CMAKE_CXX_VISIBILITY_PRESET "hidden")
set_default_var(CMAKE_C_VISIBILITY_PRESET "hidden")
# All code will be loaded as a shared library, so we must ensure static libraries are PIC
set_default_var(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

# Allow find_package to use our Find modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/find")

# Allow building against external, non-vendored, dependencies
option(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES "Use external non-vendored dependencies" OFF)
mark_as_advanced(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)

option(BinaryNinjaAPI_HEADLESS "Whether to build only HEADLESS functionality" ON)
option(BinaryNinjaAPI_BUILD_EXAMPLES "Builds example plugins" OFF)
option(BinaryNinjaAPI_RUST_API "Build the Rust API" OFF)

option(BinaryNinjaAPI_REF_COUNT_DEBUG "Add extra debugging checks for RefCountObject leaks" OFF)
mark_as_advanced(BinaryNinjaAPI_REF_COUNT_DEBUG)

# Include plugin helper functions
include(cmake/BinjaPluginFunctions.cmake)

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    if (MSVC)
        message(FATAL_ERROR "Binary Ninja is 64-bit only (try -G \"${CMAKE_GENERATOR} Win64\")")
    else()
        message(FATAL_ERROR "Binary Ninja is 64-bit only")
    endif()
endif()

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
# JsonCpp sources
target_sources(binaryninjaapi PRIVATE json/jsoncpp.cpp)

target_include_directories(binaryninjaapi PUBLIC "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>")

if(BinaryNinjaAPI_REF_COUNT_DEBUG)
    target_compile_definitions(binaryninjaapi PUBLIC BN_REF_COUNT_DEBUG)
endif()

target_compile_features(binaryninjaapi PUBLIC cxx_std_17)

if(TARGET binaryninjacore)
    target_link_libraries(binaryninjaapi PUBLIC binaryninjacore)
else()
    if(APPLE)
        target_link_options(binaryninjaapi PUBLIC -undefined dynamic_lookup)
    elseif(MSVC)
        target_link_options(binaryninjaapi PUBLIC "/FORCE:UNRESOLVED")
    else()
        target_link_options(binaryninjaapi PUBLIC "LINKER:--allow-shlib-undefined")
    endif()
endif()

if(NOT BinaryNinjaAPI_HEADLESS)
    if(NOT TARGET binaryninjaui)
        find_package(BinaryNinjaUI REQUIRED)
    endif()
    # NOTE: Not sure if binaryninjaapi should be linking to binaryninjaui
    # but we need to add the ui directory to include path
    target_include_directories(binaryninjaapi PUBLIC "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/ui>")
endif()

if(BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)
    find_package(fmt)
else()
    add_subdirectory(vendor/fmt)
endif()
target_link_libraries(binaryninjaapi PUBLIC fmt::fmt)

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
        DIRECTORY ui rapidjson
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )
    install(
        DIRECTORY vendor/nlohmann
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/vendor"
    )

    install(
        TARGETS binaryninjaapi
        EXPORT BinaryNinjaAPITargets
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )
    target_include_directories(binaryninjaapi INTERFACE "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/ui>")

    # cmake --install build --component BinaryNinjaAPIDistrib
    set(vendor_targets "")
    if(NOT BinaryNinjaAPI_EXTERNAL_DEPENDENCIES)
        list(APPEND vendor_targets fmt)
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

    install(
        FILES cmake/install-config.cmake
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
        RENAME "${package}Config.cmake"
    )

    install(
        FILES cmake/BinjaPluginFunctions.cmake
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
    )
    install(
        DIRECTORY cmake/find
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
    )

    install(
        EXPORT BinaryNinjaAPITargets
        DESTINATION "${BinaryNinjaAPI_INSTALL_CMAKEDIR}"
    )
endif()
