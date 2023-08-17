include(FetchContent)

if (${PANDALIB_TESTS})
    FetchContent_Declare(Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG devel
    )
    FetchContent_MakeAvailable(Catch2)
endif()
