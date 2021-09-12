set(CMAKE_C_STANDARD_REQUIRED TRUE)
set(CMAKE_C_EXTENSIONS OFF)

option(C_SANITIZE_ADDRESS "Enable AddressSanitizer")
option(C_SANITIZE_LEAK "Enable LeakSanitizer")
option(C_SANITIZE_UNDEFINED "Enable UndefinedBehaviorSanitizer" ON)
option(C_SANITIZE_THREAD "Enable ThreadSanitizer")
option(C_SANITIZE_MEMORY "Enable MemorySanitizer")
option(C_STATIC_ANALYSIS "Enable built-in compiler static analyzer")

if (${CMAKE_C_COMPILER_ID} STREQUAL "GNU")
    set(GNU_C_WARNINGS "-Wall -Wextra -Wshadow -Wrestrict -Wconversion -Wsign-conversion -Wjump-misses-init")

    set(GNU_C_FLAGS "-Werror=implicit-function-declaration -Werror=pedantic")

    set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS} -g")

    if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        if (C_SANITIZE_ADDRESS)
            if (C_SANITIZE_THREAD)
                message(FATAL_ERROR "ASan and TSan cannot be used together")
            endif()

            message(STATUS "Enable ASan for GCC")
            set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS_DEBUG} -fsanitize=address")
        endif()

        if (C_SANITIZE_LEAK)
            if (C_SANITIZE_THREAD)
                message(FATAL_ERROR "LSan and TSan cannot be used together")
            endif()

            message(STATUS "Enable LSan for GCC")
            set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS_DEBUG} -fsanitize=leak")
        endif()

        if (C_SANITIZE_UNDEFINED)
            message(STATUS "Enable UbSan for GCC")
            set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS_DEBUG} -fsanitize=undefined")
        endif()

        if (C_SANITIZE_THREAD)
            message(STATUS "Enable TSan for GCC")
            set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS_DEBUG} -fsanitize=thread")
        endif()
    endif()

    if (C_STATIC_ANALYSIS)
        message(STATUS "Enable static analysis for GCC")
        set(GNU_C_FLAGS_DEBUG "${GNU_C_FLAGS_DEBUG} -fanalyzer")
    endif()

    set(GNU_C_FLAGS_RELEASE "${GNU_C_FLAGS} -march=x86-64-v2 -O3 -DNDEBUG")

    string(APPEND CMAKE_C_FLAGS_DEBUG " ${GNU_C_WARNINGS} ${GNU_C_FLAGS_DEBUG}")
    string(APPEND CMAKE_C_FLAGS_RELEASE " ${GNU_C_WARNINGS} ${GNU_C_FLAGS_RELEASE}")
endif()

if (${CMAKE_C_COMPILER_ID} STREQUAL "Clang")
    set(CLANG_C_WARNINGS "-Wall -Wextra -Wshadow -Wconversion -Wsign-conversion -Wno-unused-command-line-argument")

    set(CLANG_C_FLAGS "-Werror=implicit-function-declaration -Werror=pedantic")

    set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS} -g")

    if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        if (C_SANITIZE_ADDRESS)
            if (C_SANITIZE_THREAD)
                message(FATAL_ERROR "ASan and TSan cannot be used together")
            endif()
            if (C_SANITIZE_MEMORY)
                message(FATAL_ERROR "ASan and MSan cannot be used together")
            endif()

            message(STATUS "Enable ASan for Clang")
            set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -fsanitize=address")
        endif()

        if (C_SANITIZE_LEAK)
            if (C_SANITIZE_THREAD)
                message(FATAL_ERROR "LSan and TSan cannot be used together")
            endif()
            if (C_SANITIZE_MEMORY)
                message(FATAL_ERROR "LSan and MSan cannot be used together")
            endif()

            message(STATUS "Enable LSan for Clang")
            set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -fsanitize=leak")
        endif()

        if (C_SANITIZE_UNDEFINED)
            message(STATUS "Enable UbSan for Clang")
            set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -fsanitize=undefined")
        endif()

        if (C_SANITIZE_THREAD)
            if (C_SANITIZE_MEMORY)
                message(FATAL_ERROR "TSan and MSan cannot be used together")
            endif()

            message(STATUS "Enable TSan for Clang")
            set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -fsanitize=thread")
        endif()

        if (C_SANITIZE_MEMORY)
            message(STATUS "Enable MSan for Clang")
            set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -fsanitize=memory")
        endif()
    endif()

    if (C_STATIC_ANALYSIS)
        message(STATUS "Enable static analysis for Clang")
        set(CLANG_C_FLAGS_DEBUG "${CLANG_C_FLAGS_DEBUG} -analyzer")
    endif()

    set(CLANG_C_FLAGS_RELEASE "${CLANG_C_FLAGS} -march=x86-64-v2 -O3 -DNDEBUG")

    string(APPEND CMAKE_C_FLAGS_DEBUG " ${CLANG_C_WARNINGS} ${CLANG_C_FLAGS_DEBUG}")
    string(APPEND CMAKE_C_FLAGS_RELEASE " ${CLANG_C_WARNINGS} ${CLANG_C_FLAGS_RELEASE}")
endif()
