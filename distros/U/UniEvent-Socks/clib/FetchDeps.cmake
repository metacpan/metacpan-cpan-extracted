include(FetchContent)

set(unievent_repository https://github.com/CrazyPandaLimited/UniEvent.git)
set(panda-uri_repository https://github.com/CrazyPandaLimited/Panda-URI.git)

set(Catch2_repository https://github.com/catchorg/Catch2.git)
set(Catch2_repository_tag devel)

set(deps unievent panda-uri)

set(UNIEVENT_FETCH_DEPS ON)
set(PANDA_URI_FETCH_DEPS ON)

if (${UNIEVENT_SOCKS_TESTS})
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