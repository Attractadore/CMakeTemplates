cmake_minimum_required(VERSION 3.3)

enable_language(C)
function(add_shader SHADER_TARGET SHADER_SOURCE)
    # TODO:
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

    set(SHADER_SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${SHADER_SOURCE}")
    if (NOT EXISTS ${SHADER_SOURCE_FILE})
        message(FATAL_ERROR "Could not find shader source file ${SHADER_SOURCE}")
    endif()

    set(ARGS_OPTIONS EMBEDDED)
    set(ARGS_ONE TARGET_ENV)
    set(ARGS_MULTI _MULTI_STUB)
    cmake_parse_arguments(
        PARSE_ARGV 2 OPTION ${ARGS_OPTIONS} ${ARGS_ONE} ${ARGS_MULTI}
    )

    if (NOT OPTION_TARGET_ENV)
        set (OPTION_TARGET_ENV "VULKAN")
    endif()
    set(TARGET_ENV ${OPTION_TARGET_ENV})

    set(ALLOWED_TARGET_ENVS
        "VULKAN10"
        "VULKAN11"
        "VULKAN12"
        "VULKAN13"
        "VULKAN"
        "OPENGL45"
        "OPENGL"
    )

    set(GLSLC_TARGET_ENVS
        "vulkan1.0"
        "vulkan1.1"
        "vulkan1.2"
        "vulkan1.3"
        "vulkan"
        "opengl4.5"
        "opengl"
    )

    list(FIND ALLOWED_TARGET_ENVS ${TARGET_ENV} ENV_IDX)
    if (${ENV_IDX} EQUAL -1)
        string(JOIN " " PRINT_TARGET_ENVS ${ALLOWED_TARGET_ENVS})
        message(
            FATAL_ERROR "Invalid target environment ${TARGET_ENV}. "
                        "The following environments are supported: ${PRINT_TARGET_ENVS}"
        )
    else()
        list(GET GLSLC_TARGET_ENVS ${ENV_IDX} GLSLC_TARGET_ENV)
        list(APPEND GLSLC_OPTIONS "--target-env=${GLSLC_TARGET_ENV}")
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
    )

    get_filename_component(SHADER_EXT ${SHADER_SOURCE} LAST_EXT)
    if(NOT ${SHADER_EXT} IN_LIST ALLOWED_EXTENSIONS)
        string(JOIN " " PRINT_EXTENSIONS ${ALLOWED_EXTENSIONS})
        message(
            FATAL_ERROR "File extension ${SHADER_EXT} for shader ${SHADER_SOURCE} is not supported. "
                        "The following extensions are supported: ${PRINT_EXTENSIONS}"
        )
    endif()
    if (OPTION_EMBEDDED)
        list(APPEND GLSLC_OPTIONS "-mfmt=num")
    endif()
    list(APPEND GLSLC_OPTIONS "-MD")
    list(APPEND GLSLC_OPTIONS "-Os")

    if (NOT OPTION_EMBEDDED)
        set(SHADER_BINARY "${SHADER_SOURCE}.spv")
        set(SHADER_BINARY_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_BINARY}")
        add_custom_command(
            OUTPUT ${SHADER_BINARY_FILE}
            DEPENDS ${SHADER_SOURCE_FILE}
            COMMAND ${GLSLC} ${GLSLC_OPTIONS} ${SHADER_SOURCE_FILE} -o ${SHADER_BINARY_FILE}
            COMMAND_EXPAND_LISTS
            DEPFILE ${SHADER_BINARY}.d
        )
        add_custom_target(${SHADER_TARGET} DEPENDS ${SHADER_BINARY_FILE})
    else()
        set(SHADER_H "${SHADER_TARGET}.h")
        set(SHADER_BIT "${SHADER_TARGET}.bit")
        set(SHADER_H_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_H}")
        set(SHADER_BIT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_BIT}")

        set(SHADER_H_SOURCE
            "#pragma once\n"
            "#include <stddef.h>\n"
            "\n"
            "#ifdef __cplusplus\n"
            "extern \"C\" {\n"
            "#endif\n"
            "\n"
            "static const unsigned ${SHADER_TARGET}[] = {\n"
            "#include \"${SHADER_BIT}\"\n"
            "}\;\n"
            "\n"
            "#ifdef __cplusplus\n"
            "}\n"
            "#endif"
        )

        file(WRITE ${SHADER_H_FILE} ${SHADER_H_SOURCE})

        add_custom_command(
            OUTPUT ${SHADER_BIT_FILE}
            DEPENDS ${SHADER_SOURCE_FILE}
            COMMAND ${GLSLC} ${GLSLC_OPTIONS} ${SHADER_SOURCE_FILE} -o ${SHADER_BIT_FILE}
            COMMAND_EXPAND_LISTS
            DEPFILE ${SHADER_BIT}.d
        )
        set(SHADER_BIT_FILE_TARGET ${SHADER_TARGET}BitFile)
        add_custom_target(${SHADER_BIT_FILE_TARGET} DEPENDS ${SHADER_BIT_FILE})

        add_library(${SHADER_TARGET} INTERFACE ${SHADER_H_FILE})
        target_include_directories(${SHADER_TARGET} INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
        add_dependencies(${SHADER_TARGET} ${SHADER_BIT_FILE_TARGET})
    endif()
endfunction()
