CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(UniEvent VERSION 1.0.2 LANGUAGES CXX)
enable_testing()

set(LIB_TYPE CACHE STRING STATIC)

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc" "backend-uv/*.cc")
add_library(unievent ${LIB_TYPE} ${libSource})
set(pub_includes ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/backend-uv/src ${CMAKE_CURRENT_SOURCE_DIR}/backend-uv/include)
target_include_directories(unievent PUBLIC
    "$<BUILD_INTERFACE:${pub_includes}>"
    $<INSTALL_INTERFACE:include>
)
set_target_properties(unievent PROPERTIES
    CXX_STANDARD 14
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS NO
)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_SOURCE_DIR}/cmake/modules")
message(STATUS modules ${CMAKE_MODULE_PATH})

find_package(panda-lib REQUIRED)
find_package(net-sockaddr REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(c-ares REQUIRED)
find_package(libuv REQUIRED)

target_link_libraries(unievent PUBLIC panda::panda-lib panda::net-sockaddr LibUV::uv OpenSSL::SSL c-ares::cares)

#tests
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(unievent-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(unievent-tests PUBLIC unievent)

find_package(Catch2)
target_link_libraries(unievent-tests PUBLIC Catch2::Catch2)

#ctest
add_library(test-lib STATIC tests/lib/test.cc)
target_compile_definitions(test-lib PRIVATE CATCH_CONFIG_MAIN)
target_link_libraries(test-lib Catch2::Catch2 unievent)
list(FILTER testSource EXCLUDE REGEX "lib")
foreach(tobj ${testSource})
    get_filename_component(tname ${tobj} NAME_WE)
    add_executable(t_${tname} ${tobj})
    target_link_libraries(t_${tname} test-lib)
    add_test(NAME ${tobj} COMMAND t_${tname} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endforeach()

#install
install(DIRECTORY src DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS unievent EXPORT unieventTargets ARCHIVE DESTINATION lib)

install(EXPORT unieventTargets
    FILE unievent-config.cmake
    NAMESPACE panda::
    DESTINATION lib/cmake/unievent
)
