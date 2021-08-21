set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS OFF)

option(CXX_SANITIZE_ADDRESS "Enable AddressSanitizer")
option(CXX_SANITIZE_LEAK "Enable LeakSanitizer")
option(CXX_SANITIZE_UNDEFINED "Enable UndefinedBehaviorSanitizer" ON)
option(CXX_SANITIZE_THREAD "Enable ThreadSanitizer")
option(CXX_SANITIZE_MEMORY "Enable MemorySanitizer")
option(CXX_STATICXX_ANALYSIS "Enable built-in compiler static analyzer")

if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    set(GNU_CXX_WARNINGS "-Wall -Wextra -Wshadow -Wrestrict -Wconversion -Wsign-conversion -Wpedantic -Wold-style-cast")

    set(GNU_CXX_FLAGS "")

    set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS} -g")

    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        if(CXX_SANITIZE_ADDRESS)
            if(CXX_SANITIZE_THREAD)
                message(FATAL_ERROR "ASan and TSan cannot be used together")
            endif()

            message(STATUS "Enable ASan for G++")
            set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS_DEBUG} -fsanitize=address")
        endif()

        if(CXX_SANITIZE_LEAK)
            if(CXX_SANITIZE_THREAD)
                message(FATAL_ERROR "LSan and TSan cannot be used together")
            endif()

            message(STATUS "Enable LSan for G++")
            set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS_DEBUG} -fsanitize=leak")
        endif()

        if(CXX_SANITIZE_UNDEFINED)
            message(STATUS "Enable UbSan for G++")
            set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS_DEBUG} -fsanitize=undefined")
        endif()

        if(CXX_SANITIZE_THREAD)
            message(STATUS "Enable TSan for G++")
            set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS_DEBUG} -fsanitize=thread")
        endif()
    endif()

    if(CXX_STATIC_ANALYSIS)
        message(STATUS "Enable static analysis for G++")
        set(GNU_CXX_FLAGS_DEBUG "${GNU_CXX_FLAGS_DEBUG} -fanalyzer")
    endif()

    set(GNU_CXX_FLAGS_RELEASE "${GNU_CXX_FLAGS} -O3 -DNDEBUG")

    string(APPEND CMAKE_CXX_FLAGS_DEBUG " ${GNU_CXX_WARNINGS} ${GNU_CXX_FLAGS_DEBUG}")
    string(APPEND CMAKE_CXX_FLAGS_RELEASE " ${GNU_CXX_WARNINGS} ${GNU_CXX_FLAGS_RELEASE}")
endif()

if(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
    set(CLANG_CXX_WARNINGS "-Wall -Wextra -Wshadow -Wconversion -Wsign-conversion -Wpedantic -Wold-style-cast -Wno-unused-command-line-argument")

    set(CLANG_CXX_FLAGS "")

    set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS} -g")

    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        if(CXX_SANITIZE_ADDRESS)
            if(CXX_SANITIZE_THREAD)
                message(FATAL_ERROR "ASan and TSan cannot be used together")
            endif()
            if(CXX_SANITIZE_MEMORY)
                message(FATAL_ERROR "ASan and MSan cannot be used together")
            endif()

            message(STATUS "Enable ASan for Clang++")
            set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -fsanitize=address")
        endif()

        if(CXX_SANITIZE_LEAK)
            if(CXX_SANITIZE_THREAD)
                message(FATAL_ERROR "LSan and TSan cannot be used together")
            endif()
            if(CXX_SANITIZE_MEMORY)
                message(FATAL_ERROR "LSan and MSan cannot be used together")
            endif()

            message(STATUS "Enable LSan for Clang++")
            set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -fsanitize=leak")
        endif()

        if(CXX_SANITIZE_UNDEFINED)
            message(STATUS "Enable UbSan for Clang++")
            set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -fsanitize=undefined")
        endif()

        if(CXX_SANITIZE_THREAD)
            if(CXX_SANITIZE_MEMORY)
                message(FATAL_ERROR "TSan and MSan cannot be used together")
            endif()

            message(STATUS "Enable TSan for Clang++")
            set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -fsanitize=thread")
        endif()

        if(CXX_SANITIZE_MEMORY)
            message(STATUS "Enable MSan for Clang++")
            set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -fsanitize=memory")
        endif()
    endif()

    if(CXX_STATIC_ANALYSIS)
        message(STATUS "Enable static analysis for Clang++")
        set(CLANG_CXX_FLAGS_DEBUG "${CLANG_CXX_FLAGS_DEBUG} -analyzer")
    endif()

    set(CLANG_CXX_FLAGS_RELEASE "${CLANG_CXX_FLAGS} -O3 -DNDEBUG")

    string(APPEND CMAKE_CXX_FLAGS_DEBUG " ${CLANG_CXX_WARNINGS} ${CLANG_CXX_FLAGS_DEBUG}")
    string(APPEND CMAKE_CXX_FLAGS_RELEASE " ${CLANG_CXX_WARNINGS} ${CLANG_CXX_FLAGS_RELEASE}")
endif()

set(CXX_STL_LIBSTDCXX "libstdc++")
set(CXX_STL_LIBCXX "libc++")
set(CXX_STL_MSVC "MSVC")
set(CXX_STL_UNKNOWN "unknown STL")
set_property(GLOBAL PROPERTY CXX_STL ${CMAKE_STL_UNKNOWN})
function(cxx_detect_stl)
    message(STATUS "Detect C++ STL:")

    message(STATUS "Detection requires Boost headers:")
    find_package(Boost QUIET COMPONENTS headers)
    if(Boost_FOUND)
        message(STATUS "Found Boost headers.")
        cmake_minimum_required(VERSION 3.17)
        foreach (STL ${CXX_STL_LIBSTDCXX} ${CXX_STL_LIBCXX} ${CXX_STL_MSVC})
            try_compile(RESULT_VAR
                        ${CMAKE_CURRENT_BINARY_DIR}
                        SOURCES "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/check_${STL}.cpp"
                        LINK_LIBRARIES Boost::boost)
            if(RESULT_VAR)
                set(CXX_STL ${STL} CACHE INTERNAL "")
                break()
            endif()
        endforeach()
    else()
        message(STATUS "Could NOT find Boost headers.")
    endif()

    if(CXX_STL)
        message(STATUS "Detected C++ STL as ${CXX_STL}.")
    else()
        set(CXX_STL ${CXX_STL_UNKNOWN} CACHE INTERNAL "")
        message(STATUS "Could NOT detect C++ STL.")
    endif()
endfunction()

function(find_cxx_parallel_algorithms_for_stl STL)
    message(STATUS "Find C++ parallel algorithms for ${STL}:")

    if(${STL} STREQUAL ${CXX_STL_LIBSTDCXX})
        message(STATUS "${CXX_STL_LIBSTDCXX} parallel algorithms require TBB:")
        find_package(TBB)
        if(TBB_FOUND)
            message(STATUS "Found TBB.")
            add_library(cxx_parallel_algorithms INTERFACE)
            target_link_libraries(cxx_parallel_algorithms INTERFACE TBB::tbb)
        else()
            message(STATUS "Could NOT find TBB.")
        endif()
    elseif(${STL} STREQUAL ${CXX_STL_LIBCXX})
    elseif(${STL} STREQUAL ${CXX_STL_MSVC})
        add_library(cxx_parallel_algorithms INTERFACE)
    endif()

    if(TARGET cxx_parallel_algorithms)
        message(STATUS "Found C++ parallel algorithms for ${STL}.")
    else()
        message(STATUS "Could NOT find parallel algorithms for ${STL}.")
    endif()
endfunction()

function(find_cxx_parallel_algorithms)
    if(NOT CXX_STL)
        cxx_detect_stl()
    endif()
    find_cxx_parallel_algorithms_for_stl(${CXX_STL})
endfunction()
