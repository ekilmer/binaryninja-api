cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(workflow_inliner)

file(GLOB SOURCES CONFIGURE_DEPENDS
	*.cpp
	*.c
	*.h)

add_library(workflow_inliner SHARED ${SOURCES})

if(NOT TARGET binaryninjaapi)
	find_package(BinaryNinjaAPI REQUIRED)
endif()

target_link_libraries(workflow_inliner binaryninjaapi)

set_target_properties(workflow_inliner PROPERTIES
	CXX_STANDARD 20
	CXX_VISIBILITY_PRESET hidden
	CXX_STANDARD_REQUIRED ON
	C_STANDARD 99
	C_STANDARD_REQUIRED ON
	C_VISIBILITY_PRESET hidden
	VISIBILITY_INLINES_HIDDEN ON
	POSITION_INDEPENDENT_CODE ON)

if(BN_INTERNAL_BUILD)
	plugin_rpath(workflow_inliner)
	set_target_properties(workflow_inliner PROPERTIES
		LIBRARY_OUTPUT_DIRECTORY ${BN_CORE_PLUGIN_DIR}
		RUNTIME_OUTPUT_DIRECTORY ${BN_CORE_PLUGIN_DIR})
else()
	bn_install_plugin(workflow_inliner)
endif()
