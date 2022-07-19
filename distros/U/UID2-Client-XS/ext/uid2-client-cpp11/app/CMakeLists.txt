cmake_minimum_required (VERSION 3.12)

add_executable (example "example.cpp")

find_package(Threads REQUIRED)

if(THREADS_HAVE_PTHREAD_ARG)
	target_compile_options(example PUBLIC "-pthread")
endif()

target_link_libraries(example uid2client ${CMAKE_THREAD_LIBS_INIT})
