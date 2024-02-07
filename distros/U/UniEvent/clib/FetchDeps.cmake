include(FetchContent)

set(panda-lib_repository https://github.com/CrazyPandaLimited/panda-lib.git)
set(panda-net-sockaddr_repository https://github.com/CrazyPandaLimited/Net-SockAddr.git)
set(cares_repository https://github.com/c-ares/c-ares.git)
set(cares_repository_tag main)
set(libuv_repository https://github.com/libuv/libuv.git)
set(libuv_repository_tag v1.41.0)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps panda-lib panda-net-sockaddr cares libuv)

set(PANDALIB_FETCH_DEPS ON)
set(NET_SOCKADDR_FETCH_DEPS ON)

if (${UNIEVENT_TESTS})
    list(APPEND deps Catch2)
endif()

foreach(dep ${deps})
    if (NOT DEFINED ${${dep}_repository_tag})
        set (${${dep}_repository_tag} master)
    endif()
    FetchContent_Declare(${dep}
        GIT_REPOSITORY ${${dep}_repository}
        GIT_TAG ${${dep}_repository_tag}
    )
endforeach()
FetchContent_MakeAvailable(${deps})