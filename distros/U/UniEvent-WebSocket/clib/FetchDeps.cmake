include(FetchContent)
include(CMakeDependentOption)

set(protocol-websocket_repository https://github.com/CrazyPandaLimited/Protocol-WebSocket-Fast.git)
set(unievent-http_repository https://github.com/CrazyPandaLimited/UniEvent-HTTP.git)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps protocol-websocket unievent-http)

set(PROTOCOL_WEBSOCKET_FETCH_DEPS ON)
set(UNIEVENT_HTTP_FETCH_DEPS ON)

if (UNIEVENT_WEBSOCKET_TESTS)
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