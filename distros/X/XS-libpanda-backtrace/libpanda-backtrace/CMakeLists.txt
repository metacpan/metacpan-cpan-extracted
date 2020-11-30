CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(Panda-Backtrace VERSION 1.0.2 LANGUAGES CXX)
enable_testing()
set(CMAKE_CXX_EXTENSIONS OFF)

set(LIB_TYPE CACHE STRING STATIC)

file(GLOB_RECURSE libSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/*.cc")
add_library(panda-backtrace ${LIB_TYPE} ${libSource})
set(pub_includes ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_include_directories(panda-backtrace PUBLIC
    "$<BUILD_INTERFACE:${pub_includes}>"
    $<INSTALL_INTERFACE:include>
)
target_compile_features(panda-backtrace PUBLIC cxx_std_14)

find_package(panda-lib REQUIRED)
find_package(libdwarf REQUIRED)

target_link_libraries(panda-backtrace PUBLIC panda::panda-lib unwind libdwarf::dwarf-static)

########################tests#######################################
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "tests/*.cc")
list(FILTER testSource EXCLUDE REGEX "tests/main.cc")

list(APPEND compile_opts ${CMAKE_CXX_FLAGS_DEBUG})
set_property(SOURCE ${testSource} PROPERTY COMPILE_OPTIONS ${compile_opts})

add_library(panda-backtrace-tests  STATIC ${testSource})

find_package(Catch2)
target_link_libraries(panda-backtrace-tests PUBLIC panda-backtrace Catch2::Catch2)

add_executable(MyTest ${testSource} "tests/main.cc")
target_link_libraries(MyTest panda-backtrace-tests panda-backtrace)
add_test(test-all MyTest)

#install
install(DIRECTORY src DESTINATION include FILES_MATCHING PATTERN "*.h")
install(TARGETS panda-backtrace EXPORT panda-backtraceTargets ARCHIVE DESTINATION lib)

install(EXPORT panda-backtraceTargets
    FILE panda-backtrace-config.cmake
    NAMESPACE panda::
    DESTINATION lib/cmake/panda-backtrace
)
