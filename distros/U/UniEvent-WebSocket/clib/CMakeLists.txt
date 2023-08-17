CMAKE_MINIMUM_REQUIRED(VERSION 3.0)

if (NOT DEFINED ${PROJECT_NAME})
    set(NOT_SUBPROJECT ON)
else()
    set(NOT_SUBPROJECT OFF)
endif()

PROJECT(unievent-websocket LANGUAGES CXX)

set(LIB_TYPE STATIC)
option(UNIEVENT_WEBSOCKET_TESTS OFF)
option(UNIEVENT_WEBSOCKET ${NOT_SUBPROJECT})

if (${UNIEVENT_WEBSOCKET})
    set(EXCLUDE_TEST)
else()
    set(EXCLUDE_TEST EXCLUDE_FROM_ALL)
endif()

if (UNIEVENT_WEBSOCKET_FETCH_DEPS)
    include(FetchDeps.cmake)
endif()

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/panda/*.cc")
add_library(${PROJECT_NAME} ${LIB_TYPE} ${libSource})
set(pub_includes ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_include_directories(${PROJECT_NAME} PUBLIC
    "$<BUILD_INTERFACE:${pub_includes}>"
    $<INSTALL_INTERFACE:include>
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_14)

if (NOT TARGET unievent-http)
    find_package(unievent-http REQUIRED)
endif()
if (NOT TARGET panda-protocol-websocket)
    find_package(panda-protocol-websocket REQUIRED)
endif()
if (NOT TARGET panda-encode-base2n)
    find_package(panda-encode-base2n REQUIRED)
endif()

target_link_libraries(${PROJECT_NAME} PUBLIC unievent-http panda-protocol-websocket panda-encode-base2n)

#tests
if (UNIEVENT_WEBSOCKET_TESTS)
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")

add_library(unievent-websocket-tests STATIC EXCLUDE_FROM_ALL ${testSource})
target_link_libraries(unievent-websocket-tests PUBLIC ${PROJECT_NAME})

if (NOT TARGET Catch2::Catch2)
    find_package(Catch2)
endif()
target_link_libraries(unievent-websocket-tests PUBLIC Catch2::Catch2)

#ctest
enable_testing()
add_executable(${PROJECT_NAME}-runtests ${EXCLUDE_TEST} ${testSource})
target_link_libraries(${PROJECT_NAME}-runtests ${PROJECT_NAME}-tests Catch2::Catch2WithMain)
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME}-runtests WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
endif()

#install
install(DIRECTORY src/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}-targets ARCHIVE DESTINATION lib)

install(EXPORT ${PROJECT_NAME}-targets
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION lib/cmake/${PROJECT_NAME}
)
install(FILES ${PROJECT_NAME}-config.cmake DESTINATION lib/cmake/${PROJECT_NAME})
