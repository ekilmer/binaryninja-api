# Set the user-plugin installation path based on OS-specific path
if(WIN32)
    set(user_plugin_dir "$ENV{APPDATA}\\Binary Ninja\\plugins")
elseif(APPLE)
    set(user_plugin_dir "$ENV{HOME}/Library/Application Support/Binary Ninja/plugins")
else()
    set(user_plugin_dir "$ENV{HOME}/.binaryninja/plugins")
endif()
set(BinaryNinjaAPI_USER_PLUGINS_DIR "${user_plugin_dir}" CACHE PATH "Binary Ninja user plugins directory")


# Handle installation of the user plugin
function(bn_install_plugin target)
    get_property(plugin_name TARGET ${target} PROPERTY OUTPUT_NAME)
    if(NOT plugin_name)
        set(plugin_name ${target})
    endif()
    message(STATUS "Binary Ninja user plugin ${plugin_name} installing to '${BinaryNinjaAPI_USER_PLUGINS_DIR}'")

    if(WIN32)
        install(
            FILES $<TARGET_PDB_FILE:${target}>
            DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
            COMPONENT BinaryNinjaUserPlugin
            OPTIONAL
        )
    endif()

    # Adjust rpath for case when API is built as shared library and is
    # installed at $BN_BINARY_DIR/api/libbinaryninjaapi.{dll,so,dylib}
    if(TARGET binaryninjaapi)
        get_target_property(binaryninjaapi_type binaryninjaapi TYPE)
        if(binaryninjaapi_type STREQUAL SHARED_LIBRARY)
            if(APPLE)
                set_property(TARGET ${target} PROPERTY INSTALL_RPATH "@executable_path/api")
            elseif(UNIX)
                set_property(TARGET ${target} PROPERTY INSTALL_RPATH "$ORIGIN/api")
            endif()
        endif()
    endif()

    install(
        TARGETS ${target}
        LIBRARY
            DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
            COMPONENT BinaryNinjaUserPlugin
        RUNTIME
            DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
            COMPONENT BinaryNinjaUserPlugin
    )
endfunction()
