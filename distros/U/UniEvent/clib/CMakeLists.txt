CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

PROJECT(unievent LANGUAGES CXX)

set(LIB_TYPE CACHE STRING STATIC)
set(CMAKE_CXX_EXTENSIONS OFF)

option(UNIEVENT_TESTS OFF)
option(UNIEVENT_TESTS_IN_ALL ${NOT_SUBPROJECT})

if (${UNIEVENT_TESTS_IN_ALL})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

set(UNIEVENT_UV_TARGET libuv::uv_a CACHE STRING "CMake target name of libuv")

if (${UNIEVENT_FETCH_DEPS})
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc" "backend-uv/*.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
set(pub_includes ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/backend-uv/src ${CMAKE_CURRENT_SOURCE_DIR}/backend-uv/include)
target_include_directories(${PROJECT_NAME} PUBLIC
    "$<BUILD_INTERFACE:${pub_includes}>"
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)


if (NOT TARGET panda-lib)
    find_package(panda-lib REQUIRED)
endif()
if (NOT TARGET panda-net-sockaddr)
    find_package(panda-net-sockaddr REQUIRED)
endif()
if (NOT TARGET c-ares::cares)
    find_package(c-ares REQUIRED)
endif()

if (NOT TARGET ${UNIEVENT_UV_TARGET})
    message(STATUS "no target: ${UNIEVENT_UV_TARGET}")
    if (TARGET uv_a)
        message(STATUS "using uv_a")
        add_library(${UNIEVENT_UV_TARGET} ALIAS uv_a)
        set(EXPORT_UV_TARGET uv_a) # hack for old uv versions that did not export targets in install. remove after uv update
    else()
        find_package(libuv REQUIRED)
    endif()
endif()

find_package(OpenSSL REQUIRED)

target_link_libraries(${PROJECT_NAME} PUBLIC panda-lib panda-net-sockaddr ${UNIEVENT_UV_TARGET} OpenSSL::SSL c-ares::cares)

#tests
if (${UNIEVENT_TESTS})

file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(unievent-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(unievent-tests PUBLIC ${PROJECT_NAME})

if (NOT TARGET Catch2::Catch2)
    find_package(Catch2)
endif()
target_link_libraries(unievent-tests PUBLIC Catch2::Catch2)

#ctest
enable_testing()
add_library(${PROJECT_NAME}-test-lib STATIC EXCLUDE_FROM_ALL tests/lib/test.cc)
target_link_libraries(${PROJECT_NAME}-test-lib Catch2::Catch2WithMain ${PROJECT_NAME})
list(FILTER testSource EXCLUDE REGEX "lib")
foreach(tobj ${testSource})
    get_filename_component(tname ${tobj} NAME_WE)
    add_executable(t_${tname} ${EXCLUDE_TEST} ${tobj})
    target_link_libraries(t_${tname} ${PROJECT_NAME}-test-lib)
    add_test(NAME ${tobj} COMMAND t_${tname} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endforeach()

endif() # if (UNIEVENT_TESTS)

#install
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(DIRECTORY backend-uv/src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(DIRECTORY backend-uv/include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} ${EXPORT_UV_TARGET} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
