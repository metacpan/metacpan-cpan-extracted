if (NOT TARGET unievent-http-manager)
    find_package(unievent-http REQUIRED)
    include("${CMAKE_CURRENT_LIST_DIR}/unievent-http-manager-targets.cmake")
endif()
