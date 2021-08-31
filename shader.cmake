function(add_shader SHADER_TARGET SHADER_SOURCE)
    # TODO:
    # * add dependency generation for includes
    # * add OpenGL support
    # * add options for compile env
    # * add support for different build types
    # * add support for hlsl

    if (NOT GLSLC)
        find_package(Vulkan COMPONENTS glslc)
        if(TARGET Vulkan::glslc)
            set(GLSLC Vulkan::glslc)
        endif()
        find_program(
            GLSLC NAMES glslc REQUIRED
            DOC "Path to glslc compiler"
        )
    endif()

    set(SHADER_BINARY "${SHADER_SOURCE}.spv")
    set(SHADER_SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${SHADER_SOURCE}")
    set(SHADER_BINARY_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_BINARY}")
    if (NOT EXISTS ${SHADER_SOURCE_FILE})
        message(FATAL_ERROR "Could not find shader source file ${SHADER_SOURCE}")
    endif()

    set(ALLOWED_EXTENSIONS
        ".vert"
        ".tesc"
        ".tese"
        ".geom"
        ".frag"
        ".comp"
        ".mesh"
        ".task"
        ".rgen"
        ".rint"
        ".rahit"
        ".rchit"
        ".rmiss"
        ".rcall"
    )
    get_filename_component(SHADER_EXT ${SHADER_SOURCE} LAST_EXT)
    if(NOT ${SHADER_EXT} IN_LIST ALLOWED_EXTENSIONS)
        string(JOIN " " PRINT_EXTENSIONS ${ALLOWED_EXTENSIONS})
        message(
            FATAL_ERROR "File extension ${SHADER_EXT} for shader ${SHADER_SOURCE} is not supported. "
                        "The following extensions are supported: ${PRINT_EXTENSIONS}"
        )
    endif()

    add_custom_command(
        OUTPUT ${SHADER_BINARY_FILE}
        DEPENDS ${SHADER_SOURCE_FILE}
        COMMAND ${GLSLC} ${SHADER_SOURCE_FILE} -o ${SHADER_BINARY_FILE}
    )
    add_custom_target(
        ${SHADER_TARGET}
        DEPENDS ${SHADER_BINARY_FILE}
    )
endfunction()
