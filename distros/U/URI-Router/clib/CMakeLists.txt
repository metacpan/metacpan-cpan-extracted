cmake_minimum_required(VERSION 3.10)
project(panda-uri-router VERSION 2.1.1 LANGUAGES CXX)
enable_testing()

set(LIB_TYPE STATIC)
option(PANDA_URI_ROUTER_BUILD_TESTS OFF)
if (${PANDA_URI_ROUTER_BUILD_TESTS})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
list(APPEND libSource "src/panda/uri/router/RegexpParse.cc")
file(GLOB_RECURSE ragelSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/ragel/*.cpp")
list(APPEND libSource ${ragelSource})

add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)

set_source_files_properties(src/panda/uri/router/Regexp.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough")
set_source_files_properties(src/panda/uri/router/RegexpParse.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")

set_source_files_properties(${ragelSource} PROPERTIES COMPILE_FLAGS "-Wno-class-memaccess -Wno-unused-parameter -Wno-deprecated-declarations -Wno-type-limits -Wno-deprecated-copy -Wno-shift-negative-value")
set_source_files_properties(src/ragel/rlscan.cpp PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-deprecated-copy -Wno-unused-const-variable")
set_source_files_properties(src/panda/uri/router/RagelHelper.cc PROPERTIES COMPILE_FLAGS "-Wno-deprecated-copy")
set_source_files_properties(src/panda/uri/router/Dfa.cc PROPERTIES COMPILE_FLAGS "-Wno-deprecated-copy")

find_program(ragel_bin ragel)
if (ragel_bin)
    add_custom_command(
        OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/src/panda/uri/router/RegexpParse.cc
        COMMAND ragel -C -G2 src/panda/uri/router/RegexpParse.rl -o src/panda/uri/router/RegexpParse.cc
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/panda/uri/router/RegexpParse.rl
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

find_package(panda-lib REQUIRED)
target_link_libraries(${PROJECT_NAME} panda-lib)

########################tests#######################################
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")
set_source_files_properties(${testSource} PROPERTIES COMPILE_FLAGS "-Wno-potentially-evaluated-expression")

add_library(${PROJECT_NAME}-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(${PROJECT_NAME}-tests PUBLIC ${PROJECT_NAME})

find_package(Catch2)
target_link_libraries(${PROJECT_NAME}-tests PUBLIC Catch2::Catch2)

########################ctests######################################
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource})
target_link_libraries(${PROJECT_NAME}-runtests ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(${PROJECT_NAME} ${PROJECT_NAME}-runtests)

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
