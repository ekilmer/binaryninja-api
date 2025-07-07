cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(x86_extension CXX C)

add_library(${PROJECT_NAME} SHARED
    src/x86_extension.cpp
    src/asmx86/asmx86.c
    src/asmx86/asmx86.h)

if(NOT TARGET binaryninjaapi)
    find_package(BinaryNinjaAPI REQUIRED)
endif()

target_link_libraries(${PROJECT_NAME} binaryninjaapi)

set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 20
    CXX_VISIBILITY_PRESET hidden
    CXX_STANDARD_REQUIRED ON
    VISIBILITY_INLINES_HIDDEN ON
    POSITION_INDEPENDENT_CODE ON
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/out/bin)

bn_install_plugin(${PROJECT_NAME})
