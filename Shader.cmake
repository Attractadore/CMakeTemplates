cmake_minimum_required(VERSION 3.3)
function(add_shader SHADER_TARGET SHADER_SOURCE)
    # TODO:
    # * add dependency generation for includes
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
        "VULKAN"
        "OPENGL45"
        "OPENGL"
    )

    set(GLSLC_TARGET_ENVS
        "vulkan1.0"
        "vulkan1.1"
        "vulkan1.2"
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
    
    if (${TARGET_ENV} STREQUAL "VULKAN12")
        set(RT_ALLOWED_EXTENSIONS
            ".rgen"
            ".rint"
            ".rahit"
            ".rchit"
            ".rmiss"
            ".rcall"
        )
        list(APPEND ALLOWED_EXTENSIONS ${RT_ALLOWED_EXTENSIONS})
    endif()

    get_filename_component(SHADER_EXT ${SHADER_SOURCE} LAST_EXT)
    if(NOT ${SHADER_EXT} IN_LIST ALLOWED_EXTENSIONS)
        string(JOIN " " PRINT_EXTENSIONS ${ALLOWED_EXTENSIONS})
        message(
            FATAL_ERROR "File extension ${SHADER_EXT} for shader ${SHADER_SOURCE} is not supported. "
                        "The following extensions are supported: ${PRINT_EXTENSIONS}"
        )
    endif()

    if (NOT OPTION_EMBEDDED)
        set(SHADER_BINARY "${SHADER_SOURCE}.spv")
        set(SHADER_BINARY_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_BINARY}")
        add_custom_command(
            OUTPUT ${SHADER_BINARY_FILE}
            DEPENDS ${SHADER_SOURCE_FILE}
            COMMAND ${GLSLC} ${GLSLC_OPTIONS} ${SHADER_SOURCE_FILE} -o ${SHADER_BINARY_FILE}
            COMMAND_EXPAND_LISTS
        )
        add_custom_target(
            ${SHADER_TARGET}
            DEPENDS ${SHADER_BINARY_FILE}
        )
    else()
        set(SHADER_H "${SHADER_TARGET}.h")
        set(SHADER_C "${SHADER_TARGET}.c")
        set(SHADER_H_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_H}")
        set(SHADER_C_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_C}")
    
        list(APPEND GLSLC_OPTIONS "-mfmt=num")

        set(PAYLOAD_NAME ${SHADER_TARGET})
        set(PAYLOAD_SIZE_NAME "${SHADER_TARGET}Size")
        set(SHADER_H_SOURCE
            "#pragma once\n"
            "#ifdef __cplusplus\n"
            "#include <cstddef>\n"
            "#else\n"
            "#include <stddef.h>\n"
            "#endif\n"
            "\n"
            "#ifdef __cplusplus\n"
            "extern \"C\" {\n"
            "#endif\n"
            "extern const int ${PAYLOAD_NAME}[]\;\n"
            "extern const size_t ${PAYLOAD_SIZE_NAME}\;\n"
            "#ifdef __cplusplus\n"
            "}\n"
            "#endif"
        )
        set(SHADER_C_TOP_SOURCE
            "#include \"${SHADER_H}\"\n"
            "\n"
            "const int ${PAYLOAD_NAME}[] = {\n"
        )
        set(SHADER_C_BOTTOM_SOURCE
            "}\;\n"
            "\n"
            "const size_t ${PAYLOAD_SIZE_NAME} = sizeof(${PAYLOAD_NAME})\;"
        )
        
        set(SHADER_H_SOURCE_NAME "${SHADER_TARGET}HSource.h")
        set(SHADER_C_TOP_SOURCE_NAME "${SHADER_TARGET}CTopSource.c")
        set(SHADER_BIT_NAME "${SHADER_TARGET}.bit")
        set(SHADER_C_BOTTOM_SOURCE_NAME "${SHADER_TARGET}CBottomSource.c")

        set(SHADER_H_SOURCE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_H_SOURCE_NAME}")
        set(SHADER_C_TOP_SOURCE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_C_TOP_SOURCE_NAME}")
        set(SHADER_BIT_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_BIT_NAME}")
        set(SHADER_C_BOTTOM_SOURCE_FILE "${CMAKE_CURRENT_BINARY_DIR}/${SHADER_C_BOTTOM_SOURCE_NAME}")

        file(WRITE ${SHADER_H_SOURCE_FILE} ${SHADER_H_SOURCE})
        file(WRITE ${SHADER_C_TOP_SOURCE_FILE} ${SHADER_C_TOP_SOURCE})
        file(WRITE ${SHADER_C_BOTTOM_SOURCE_FILE} ${SHADER_C_BOTTOM_SOURCE})

        add_custom_command(
            OUTPUT ${SHADER_H_FILE}
            DEPENDS ${SHADER_H_SOURCE_FILE}
            COMMAND ${CMAKE_COMMAND} -E cat ${SHADER_H_SOURCE_FILE} > ${SHADER_H_FILE} 
            COMMAND_EXPAND_LISTS
        )
        add_custom_command(
            OUTPUT ${SHADER_BIT_FILE}
            DEPENDS ${SHADER_SOURCE_FILE}
            COMMAND ${GLSLC} ${GLSLC_OPTIONS} ${SHADER_SOURCE_FILE} -o ${SHADER_BIT_FILE}
            COMMAND_EXPAND_LISTS
        )
        add_custom_command(
            OUTPUT ${SHADER_C_FILE}
            DEPENDS ${SHADER_C_TOP_SOURCE_FILE} ${SHADER_BIT_FILE} ${SHADER_C_BOTTOM_SOURCE_FILE}
            COMMAND ${CMAKE_COMMAND} -E cat ${SHADER_C_TOP_SOURCE_FILE} ${SHADER_BIT_FILE} ${SHADER_C_BOTTOM_SOURCE_FILE} > ${SHADER_C_FILE} 
            COMMAND_EXPAND_LISTS
        )
     
        add_library(
            ${SHADER_TARGET} ${SHADER_H_FILE} ${SHADER_C_FILE}
        )
        target_include_directories(${SHADER_TARGET} INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
    endif()
endfunction()
