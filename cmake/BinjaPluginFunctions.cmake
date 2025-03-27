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
            TARGETS ${target}
            RUNTIME
                DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
                COMPONENT BinaryNinjaUserPlugin
        )

        install(
            FILES $<TARGET_PDB_FILE:${target}>
            DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
            COMPONENT BinaryNinjaUserPlugin
            OPTIONAL
        )
    else()
        # Adjust rpath for case when API is built as shared library
        # TODO: Check if API is shared library
        if(APPLE)
            set_property(TARGET ${target} PROPERTY INSTALL_RPATH "@executable_path/api")
            #install(CODE "execute_process(COMMAND /usr/bin/install_name_tool -add_rpath \"@executable_path/api\" \"\$ENV{DESTDIR}$<TARGET_FILE:${target}>\")")
        elseif(UNIX)
            set_property(TARGET ${target} PROPERTY INSTALL_RPATH "$ORIGIN/api")
            #install(CODE "execute_process(COMMAND /usr/bin/install_name_tool -add_rpath \"$ORIGIN/api\" \"\$ENV{DESTDIR}$<TARGET_FILE:${target}>\")")
        endif()
        install(
            TARGETS ${target}
            LIBRARY
                DESTINATION ${BinaryNinjaAPI_USER_PLUGINS_DIR}
                COMPONENT BinaryNinjaUserPlugin
        )
    endif()
endfunction()


# Ignore missing/undefined symbols when linking a target
function(bn_ignore_missing_symbols target)
    if(APPLE)
        target_link_options(binaryninjaapi PUBLIC -undefined dynamic_lookup)
    elseif(MSVC)
        target_link_options(binaryninjaapi PUBLIC "/FORCE:UNRESOLVED")
    else()
        target_link_options(binaryninjaapi PUBLIC "LINKER:--allow-shlib-undefined")
    endif()
endfunction()
