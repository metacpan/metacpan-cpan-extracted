if (NOT TARGET panda-uri-router)
    find_package(panda-lib REQUIRED)
    include(${CMAKE_CURRENT_LIST_DIR}/panda-uri-router-targets.cmake)
endif()
