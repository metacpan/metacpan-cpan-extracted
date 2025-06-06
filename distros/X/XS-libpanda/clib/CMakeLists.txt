CMAKE_MINIMUM_REQUIRED(VERSION 3.10)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

PROJECT(panda-lib LANGUAGES CXX)

set(LIB_TYPE STATIC)

option(PANDALIB_TESTS OFF)
option(PANDALIB_TESTS_IN_ALL ${NOT_SUBPROJECT})

if (${PANDALIB_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (PANDALIB_FETCH_DEPS)
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libPandaSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/*.cc")
file(GLOB_RECURSE win_sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/win/*.cc")
file(GLOB_RECURSE unix_sources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/unix/*.cc")

if (UNIX)
    list(REMOVE_ITEM libPandaSource ${win_sources})
else()
    list(REMOVE_ITEM libPandaSource ${unix_sources})
endif()

add_library(${PROJECT_NAME} ${LIB_TYPE} ${libPandaSource})

target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
target_compile_options(${PROJECT_NAME} PRIVATE -Wall)

if (UNIX)
    # needed for *bsd
    set(CMAKE_REQUIRED_INCLUDES "/usr/local/include" "/usr/include")
    include(CheckIncludeFileCXX)
    CHECK_INCLUDE_FILE_CXX(execinfo.h execinfo_header)
    CHECK_INCLUDE_FILE_CXX(libunwind.h libunwind_header)
    if (libunwind_header)
        target_compile_definitions(${PROJECT_NAME} PRIVATE "PANDA_HAS_LIBUNWIND")
        message(STATUS "PANDA_HAS_LIBUNWIND")
        find_library(libunwind_lib unwind)
        find_library(libunwind_generic_lib unwind-generic)
        if (libunwind_lib)
            list(APPEND panda-lib-libraries unwind)
        endif()
    elseif (execinfo_header)
        target_compile_definitions(${PROJECT_NAME} PRIVATE "PANDA_HAS_EXECINFO")
        message(STATUS "PANDA_HAS_EXECINFO")
        find_library(execinfo_lib execinfo)
        if (execinfo_lib)
            list(APPEND panda-lib-libraries execinfo)
        endif()
    else()
        message(FATAL_ERROR "execinfo.h nor libunwind.h not found")
    endif()
else()
    list(APPEND panda-lib-libraries dbgeng ole32)
endif()

target_link_libraries(${PROJECT_NAME} PUBLIC ${panda-lib-libraries})

########################tests#######################################
if (${PANDALIB_TESTS})

file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(${PROJECT_NAME}-tests STATIC EXCLUDE_FROM_ALL ${testSource})
find_package(Threads)
find_package(Catch2)
target_link_libraries(${PROJECT_NAME}-tests PUBLIC ${PROJECT_NAME} ${CMAKE_THREAD_LIBS_INIT} Catch2::Catch2)

########################ctests######################################
#executable should be MyTest to pass test exception.cc that checks "library" name
include(CTest)
enable_testing()
add_executable(MyTest ${EXCLUDE_TEST} ${testSource})
target_link_libraries(MyTest ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(${PROJECT_NAME} MyTest)
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} DEPENDS MyTest)

endif()

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
