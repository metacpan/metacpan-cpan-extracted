cmake_minimum_required(VERSION 3.12)

project("uid2-client" VERSION 3.0.1)

configure_file(VERSION.in VERSION @ONLY)

option(WARNING_AS_ERROR "Treat compiler warnings as errors" ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS_DEBUG "-ggdb")
add_compile_options(-Wall -Wextra)
if(WARNING_AS_ERROR)
	add_compile_options(-Werror)
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	if (NOT DEFINED OPENSSL_ROOT_DIR)
		set(OPENSSL_ROOT_DIR /usr/local/opt/openssl)
	endif()
endif()

add_subdirectory(lib)
