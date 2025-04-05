cmake_minimum_required(VERSION 3.10)

project(triage CXX C)

file(GLOB SOURCES
	*.cpp
	*.h)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(DEMO)
	add_library(triage STATIC ${SOURCES} ${MOCS})
else()
	add_library(triage SHARED ${SOURCES} ${MOCS})
endif()

if(NOT TARGET binaryninjaapi)
	find_package(BinaryNinjaAPI REQUIRED)
endif()

target_link_libraries(triage binaryninjaui)

set_target_properties(triage PROPERTIES
    CXX_STANDARD 17
	CXX_VISIBILITY_PRESET hidden
	CXX_STANDARD_REQUIRED ON
    VISIBILITY_INLINES_HIDDEN ON
	POSITION_INDEPENDENT_CODE ON)

if(BN_INTERNAL_BUILD)
	ui_plugin_rpath(triage)
	set_target_properties(triage PROPERTIES
		LIBRARY_OUTPUT_DIRECTORY ${BN_CORE_PLUGIN_DIR}
		RUNTIME_OUTPUT_DIRECTORY ${BN_CORE_PLUGIN_DIR})
else()
	bn_install_plugin(triage)
endif()
