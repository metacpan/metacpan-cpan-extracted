include(FetchContent)

set(panda-protocol-http_repository https://github.com/CrazyPandaLimited/Protocol-HTTP)
set(unievent_repository https://github.com/CrazyPandaLimited/UniEvent.git)
set(unievent-socks_repository https://github.com/CrazyPandaLimited/UniEvent-Socks.git)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps panda-protocol-http unievent unievent-socks)

set(UNIEVENT_FETCH_DEPS ON)
set(PROTOCOL_HTTP_FETCH_DEPS ON)

if (${UNIEVENT_HTTP_TESTS})
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