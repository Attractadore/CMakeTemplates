cmake_minimum_required(VERSION 3.4)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

function(find_platform_dynamic_linker_with_platform PLATFORM)
    message(STATUS "Find dynamic linker for ${PLATFORM}:")

    if(${PLATFORM} STREQUAL "Linux")
        add_library(platform_dynamic_linker INTERFACE)
        target_link_libraries(platform_dynamic_linker INTERFACE ${CMAKE_DL_LIBS})
    elseif(${PLATFORM} STREQUAL "Windows")
        add_library(platform_dynamic_linker INTERFACE)
    endif()

    if(TARGET platform_dynamic_linker)
        message(STATUS "Found dynamic linker for ${PLATFORM}.")
    else ()
        message(STATUS "Could NOT find dynamic linker for ${PLATFORM}.")
    endif()
endfunction()

function(find_platform_dynamic_linker)
    find_platform_dynamic_linker_with_platform(${CMAKE_SYSTEM_NAME})
endfunction()
