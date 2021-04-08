if (NOT TARGET panda-uri)
    find_package(panda-lib REQUIRED)
    include(${CMAKE_CURRENT_LIST_DIR}/panda-uri-targets.cmake)
endif()
