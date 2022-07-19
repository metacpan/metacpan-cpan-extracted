add_compile_definitions(CPPHTTPLIB_OPENSSL_SUPPORT)

find_package(OpenSSL REQUIRED)
message( ${OPENSSL_INCLUDE_DIR} )
message( ${OPENSSL_LIBRARIES} )

find_package(Threads REQUIRED)

file(GLOB UID2_PUBLIC_HEADERS CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/include/uid2/*.h")
file(GLOB UID2_HEADERS CONFIGURE_DEPENDS "*.h*")
file(GLOB UID2_SOURCES CONFIGURE_DEPENDS "*.cpp")

add_library(uid2client ${UID2_PUBLIC_HEADERS} ${UID2_HEADERS} ${UID2_SOURCES})

target_include_directories(uid2client
	PUBLIC ../include
	PRIVATE ${OPENSSL_INCLUDE_DIR})
target_compile_features(uid2client PUBLIC cxx_std_11)

if(THREADS_HAVE_PTHREAD_ARG)
	target_compile_options(uid2client PUBLIC "-pthread")
endif()

target_link_libraries(uid2client ${OPENSSL_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})

install(TARGETS uid2client DESTINATION lib)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
