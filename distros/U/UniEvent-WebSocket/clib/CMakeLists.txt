CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(unievent-websocket LANGUAGES CXX)

set(LIB_TYPE CACHE STRING STATIC)
set(CMAKE_CXX_EXTENSIONS OFF)
option(UNIEVENT_WEBSOCKET_BUILD_TESTS OFF)
if (${UNIEVENT_WEBSOCKET_BUILD_TESTS})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
set(pub_includes ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_include_directories(${PROJECT_NAME} PUBLIC
    "$<BUILD_INTERFACE:${pub_includes}>"
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

find_package(unievent-http REQUIRED)
find_package(panda-protocol-websocket REQUIRED)
find_package(panda-encode-base2n REQUIRED)

target_link_libraries(${PROJECT_NAME} PUBLIC unievent-http panda-protocol-websocket panda-encode-base2n)

#tests
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(unievent-websocket-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(unievent-websocket-tests PUBLIC ${PROJECT_NAME})

find_package(Catch2)
target_link_libraries(unievent-websocket-tests PUBLIC Catch2::Catch2)

#ctest
enable_testing()
add_library(${PROJECT_NAME}-test-lib STATIC EXCLUDE_FROM_ALL tests/lib/test.cc)
target_compile_definitions(${PROJECT_NAME}-test-lib PRIVATE CATCH_CONFIG_MAIN)
target_link_libraries(${PROJECT_NAME}-test-lib Catch2::Catch2 ${PROJECT_NAME})
list(FILTER testSource EXCLUDE REGEX "lib")
#foreach(tobj ${testSource})
#    get_filename_component(tname ${tobj} NAME_WE)
#    add_executable(t_${tname} ${EXCLUDE_TEST} ${tobj})
#    target_link_libraries(t_${tname} test-lib)
#    add_test(NAME ${tobj} COMMAND t_${tname} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
#endforeach()

#install
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
