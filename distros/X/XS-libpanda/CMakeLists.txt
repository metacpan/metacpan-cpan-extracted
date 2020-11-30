CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(Panda-Lib VERSION 1.1.5 LANGUAGES CXX)
enable_testing()

set(LIB_TYPE STATIC)

file(GLOB_RECURSE libPandaSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/*.cc")
add_library(panda-lib ${LIB_TYPE} ${libPandaSource})
target_include_directories(panda-lib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(panda-lib PUBLIC cxx_std_14)
add_library(panda::panda-lib ALIAS panda-lib)

if (UNIX)
    # needed for *bsd
    set(CMAKE_REQUIRED_INCLUDES "/usr/local/include" "/usr/include")
    include(CheckIncludeFileCXX)
    CHECK_INCLUDE_FILE_CXX(execinfo.h execinfo_header)
    CHECK_INCLUDE_FILE_CXX(libunwind.h libunwind_header)
    find_library(execinfo_lib execinfo)
    find_library(libunwind_lib unwind)
    #  OR ((NOT execinfo_lib) AND (NOT libunwind_lib))
    if(((NOT execinfo_header) AND (NOT libunwind_header)))
        message(FATAL_ERROR "execinfo.h nor libunwind.h not found")
    endif()
    if (execinfo_header)
        target_compile_definitions(panda-lib PRIVATE "PANDA_HAS_EXECINFO")
        message(STATUS "PANDA_HAS_EXECINFO")
        if (execinfo_lib)
            list(APPEND panda-lib-libraries execinfo)
        endif()
    endif()
    if (libunwind_header)
        target_compile_definitions(panda-lib PRIVATE "PANDA_HAS_LIBUNWIND")
        message(STATUS "PANDA_HAS_LIBUNWIND")
        if (libunwind_lib)
            list(APPEND panda-lib-libraries unwind)
        endif()
    endif()
else()
    list(APPEND panda-lib-libraries dbgeng ole32)
endif()

target_link_libraries(panda-lib PUBLIC ${panda-lib-libraries})

########################tests#######################################
file(GLOB_RECURSE testSource RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "t/*.cc")
list(FILTER testSource EXCLUDE REGEX "t/main.cc")

add_library(panda-lib-tests  STATIC ${testSource})
target_link_libraries(panda-lib-tests PUBLIC panda-lib)

find_package(Catch2)
target_link_libraries(panda-lib-tests PUBLIC Catch2::Catch2)

########################ctests######################################
#executable should be MyTest to pass test esception.cc that checks "library" name
add_executable(MyTest ${testSource} "t/main.cc")
target_link_libraries(MyTest panda-lib-tests)
add_test(test-all MyTest)

########################install#####################################
install(DIRECTORY src/ DESTINATION include
    FILES_MATCHING PATTERN "*.h")
install(TARGETS panda-lib EXPORT panda-libTargets
    ARCHIVE DESTINATION lib
)

install(EXPORT panda-libTargets
    FILE panda-libTargets.cmake
    NAMESPACE panda::
    DESTINATION lib/cmake/panda-lib
)

install(FILES panda-libConfig.cmake DESTINATION lib/cmake/panda-lib)
