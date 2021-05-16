find_package(Ruby REQUIRED)
set(UNITY_RUNNER_GENERATOR "${Ruby_EXECUTABLE} ${PROJECT_SOURCE_DIR}/modules/Unity/auto/generate_test_runner.rb")
separate_arguments(UNITY_RUNNER_GENERATOR NATIVE_COMMAND ${UNITY_RUNNER_GENERATOR})

function(add_test_suite TARGET TEST_SOURCE)
    set(TEST_RUNNER "${TARGET}_Runner.c")
    set(TEST_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_SOURCE}")
    set(TEST_RUNNER "${CMAKE_CURRENT_BINARY_DIR}/${TEST_RUNNER}")
    add_custom_command(
        OUTPUT ${TEST_RUNNER}
        DEPENDS ${TEST_SOURCE}
        COMMAND ${UNITY_RUNNER_GENERATOR} ${TEST_SOURCE} ${TEST_RUNNER}
    )
    add_executable(${TARGET} ${TEST_RUNNER} ${TEST_SOURCE})
    target_include_directories(${TARGET} PRIVATE "${PROJECT_SOURCE_DIR}/src" "${PROJECT_SOURCE_DIR}/include/DataStructures/")
    target_link_libraries(${TARGET} PRIVATE unity)
endfunction()
