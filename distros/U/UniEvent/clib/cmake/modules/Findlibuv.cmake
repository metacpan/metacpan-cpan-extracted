if (TARGET LibUV::uv OR TARGET uv)
    #do nothing, it is already exists, ussually it is subdirrectory included
    message(STATUS "found libuv with defined target LibUV::uv")
else()
    #try config mode
    find_package(libuv QUIET CONFIG)
    if (libuv_FOUND)
        #do nothing, find_package makes all job
        message(STATUS "found libuv with CONFIG mode")
    else()
        #try pkg-config
        find_package(PkgConfig)
        set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH TRUE)
        pkg_check_modules(libuv QUIET IMPORTED_TARGET GLOBAL libuv)

        if (TARGET PkgConfig::libuv)
            message(STATUS "found libuv with pkg-conf")
            add_library(LibUV::uv ALIAS PkgConfig::libuv)
        else()
            message(ERROR "Cannot find libuv")
        endif()
    endif()
endif()

