file(GLOB UID2_TEST_SOURCES CONFIGURE_DEPENDS "*.cpp")

find_package(GTest REQUIRED)

add_executable (uid2_test ${UID2_TEST_SOURCES})
target_include_directories(uid2_test PRIVATE ../include ../lib ${GTEST_INCLUDE_DIRS})
target_link_libraries(uid2_test uid2client ${GTEST_BOTH_LIBRARIES})

add_test(Uid2Tests uid2_test)
