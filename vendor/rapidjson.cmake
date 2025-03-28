set(rapidjson_src "${CMAKE_CURRENT_SOURCE_DIR}/rapidjson")

add_library(RapidJSON INTERFACE)
target_include_directories(
    RapidJSON
    INTERFACE
    "$<BUILD_INTERFACE:${rapidjson_src}/include>"
)
target_compile_features(RapidJSON INTERFACE cxx_std_17)

if(NOT CMAKE_SKIP_INSTALL_RULES)
    include(GNUInstallDirs)
    install(
        DIRECTORY ${rapidjson_src}/include/
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )
    install(
        TARGETS RapidJSON
        EXPORT RapidJSONTargets
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

    set(
        RapidJSON_INSTALL_CMAKEDIR "${CMAKE_INSTALL_DATADIR}/RapidJSON"
        CACHE STRING "CMake package config location relative to the install prefix"
    )
    set_property(CACHE RapidJSON_INSTALL_CMAKEDIR PROPERTY TYPE PATH)
    mark_as_advanced(RapidJSON_INSTALL_CMAKEDIR)

    install(
        FILES ${CMAKE_CURRENT_SOURCE_DIR}/rapidjson-install-config.cmake
        DESTINATION "${RapidJSON_INSTALL_CMAKEDIR}"
        RENAME "RapidJSONConfig.cmake"
    )

    install(
        EXPORT RapidJSONTargets
        DESTINATION "${RapidJSON_INSTALL_CMAKEDIR}"
    )
endif()
