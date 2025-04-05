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
include(APISources.cmake)

target_include_directories(binaryninjaapi PUBLIC "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>")

if(BinaryNinjaAPI_REF_COUNT_DEBUG)
    target_compile_definitions(binaryninjaapi PUBLIC BN_REF_COUNT_DEBUG)
endif()

target_compile_features(binaryninjaapi PUBLIC cxx_std_17)

if(NOT TARGET binaryninjacore)
    find_package(BinaryNinjaCore)
    if(WIN32 AND NOT BinaryNinjaCore_FOUND)
        find_package(Python3 COMPONENTS Interpreter REQUIRED)
        # Generate stubs.cpp with implementations of all the BNAPI functions
        add_custom_command(
            OUTPUT ${PROJECT_BINARY_DIR}/stubs/stubs.cpp
            COMMAND ${Python3_EXECUTABLE}
                ${PROJECT_SOURCE_DIR}/cmake/generate_stubs.py
                ${PROJECT_SOURCE_DIR}/binaryninjacore.h
                ${PROJECT_BINARY_DIR}/stubs
            DEPENDS
                ${PROJECT_SOURCE_DIR}/cmake/generate_stubs.py
                ${PROJECT_SOURCE_DIR}/binaryninjacore.h
        )
        # Compile those stubs into a stub library we can use to fool the linker
        add_library(binaryninjacore SHARED ${PROJECT_BINARY_DIR}/stubs/stubs.cpp)
        set_target_properties(binaryninjacore
            PROPERTIES OUTPUT_NAME binaryninjacore
            SOVERSION 1
            ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/stubs
            LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/stubs
            RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/stubs
        )
        target_include_directories(binaryninjacore PRIVATE $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>)
    endif()
endif()
target_link_libraries(binaryninjaapi PUBLIC binaryninjacore)

if(NOT BinaryNinjaAPI_HEADLESS)
    # Set this property on the API so that the UI target can attach it to itself
    # This allows plugin devs to specify only binaryninjaui target dependency
    set_target_properties(binaryninjaapi
        PROPERTIES BinaryNinjaUI_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/ui"
    )
    if(NOT TARGET binaryninjaui)
        find_package(BinaryNinjaUI)
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

if(NOT CMAKE_SKIP_INSTALL_RULES)
    include(cmake/InstallRules.cmake)
endif()

# ----- Extras -----

if(BinaryNinjaAPI_RUST_API)
    add_subdirectory(rust)
endif()

if(BinaryNinjaAPI_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
