cmake_minimum_required(VERSION 3.28)

project(uinotification CXX C)

file(GLOB SOURCES
	*.cpp
	*.h)

add_library(uinotification SHARED ${SOURCES})

if(NOT TARGET binaryninjaapi OR NOT TARGET binaryninjaui)
	find_package(BinaryNinjaAPI COMPONENTS UI REQUIRED)
	find_package(BinaryNinjaUI)
endif()

target_link_libraries(uinotification PRIVATE
	binaryninjaapi
	# Use COMPILE_ONLY to avoid macOS rpath issues
	$<COMPILE_ONLY:binaryninjaui>
)

set_target_properties(uinotification PROPERTIES
    CXX_STANDARD 17
	CXX_VISIBILITY_PRESET hidden
	CXX_STANDARD_REQUIRED ON
    VISIBILITY_INLINES_HIDDEN ON
	POSITION_INDEPENDENT_CODE ON
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/out/bin)

if(BN_INTERNAL_BUILD)
	ui_plugin_rpath(uinotification)
endif()

bn_install_plugin(${PROJECT_NAME})
