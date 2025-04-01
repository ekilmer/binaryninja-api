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
