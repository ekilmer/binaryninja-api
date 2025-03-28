include(CMakeFindDependencyMacro)

find_dependency(fmt)
find_dependency(nlohmann_json)
find_dependency(RapidJSON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/find")

set(_supported_components CORE UI)
foreach(_comp ${BinaryNinjaAPI_FIND_COMPONENTS})
    if(NOT _comp IN_LIST _supported_components)
        set(BinaryNinjaAPI_FOUND False)
        set(BinaryNinjaAPI_NOT_FOUND_MESSAGE "Unsupported component: ${_comp}")
    endif()
    if (_comp STREQUAL "CORE")
        find_package(BinaryNinjaCore)
    elseif (_comp STREQUAL "UI")
        find_package(BinaryNinjaUI)
    endif()
endforeach()

include("${CMAKE_CURRENT_LIST_DIR}/BinjaPluginFunctions.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/BinaryNinjaAPITargets.cmake")
