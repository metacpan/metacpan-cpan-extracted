CMAKE_MINIMUM_REQUIRED(VERSION 3.10)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

PROJECT(unievent-socks VERSION 1.0.1 LANGUAGES CXX)

set(LIB_TYPE CACHE STRING STATIC)
set(CMAKE_CXX_EXTENSIONS OFF)

option(UNIEVENT_SOCKS_TESTS OFF)
option(UNIEVENT_SOCKS_TESTS_IN_ALL ${NOT_SUBPROJECT})

if (${UNIEVENT_SOCKS_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (UNIEVENT_SOCKS_FETCH_DEPS)
    include(FetchDeps.cmake)
endif()

set(LIB_TYPE STATIC)
option(UNIEVENT_SOCKS_BUILD_TESTS OFF)
if (${UNIEVENT_SOCKS_BUILD_TESTS})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
list(APPEND libSource "src/panda/unievent/socks/SocksParser.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
target_include_directories(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra)
set_source_files_properties(src/panda/unievent/socks/SocksParser.cc PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-unused-const-variable")

find_program(ragel_bin ragel)
if (ragel_bin)
    add_custom_command(
        OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/src/panda/unievent/socks/SocksParser.cc
        COMMAND ragel -C -G2 src/panda/unievent/socks/SocksParser.rl -o src/panda/unievent/socks/SocksParser.cc
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/panda/unievent/socks/SocksParser.rl
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
endif()

if (NOT TARGET unievent)
    find_package(unievent REQUIRED)
endif()
if (NOT TARGET panda-uri)
    find_package(panda-uri REQUIRED)
endif()
target_link_libraries(${PROJECT_NAME} unievent panda-uri)

########################tests#######################################
if (UNIEVENT_SOCKS_TESTS)
enable_testing()
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(${PROJECT_NAME}-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(${PROJECT_NAME}-tests PUBLIC ${PROJECT_NAME})

if (NOT TARGET Catch2)
    find_package(Catch2)
endif()
target_link_libraries(${PROJECT_NAME}-tests PUBLIC Catch2::Catch2)

########################ctests######################################
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource})
target_link_libraries(${PROJECT_NAME}-runtests ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME}-runtests WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

endif()

########################install#####################################
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)

install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
