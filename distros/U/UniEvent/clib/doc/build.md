# Building UniEvent based projects

UniEvent uses CMake as a build tool. It can be used as subdirectory of another CMake project or be built separately. There are no special instructions or details about building UniEvent itself but there are some dependencies with special needs. This document contains a description of problems and two manuals:
* [How to build UniEvent separately](#dedicated-build)
* [How to use UniEvent as subdirectory](#using-add_subdirectory)

First one requires one time manual build of all dependencies and minimum changes in your CMakeLists. The second one is easier to start with. Choose your way and just follow the instructions.

## libUV

[libUV](https://github.com/libuv/libuv) is the only supported event loop for now. It has different target names for the static and dynamic library and it cannot be changed by config. So UniEvent cannot use any of these targets because it will force a library user to link libUV statically or dynamically. To make the build flexible, UniEvent reads the CMake variable `UNIEVENT_UV_TARGET` and links against it. It also solves a problem that in case of using libUV as a subdirectory it does not define the same alias for its targets as in install script (uv vs libuv::uv). The default value of `UNIEVENT_UV_TARGET` is `libuv::uv_a` so UniEvent statically links against installed libUV. It works when you have installed libUV CMake package but it does not in any other cases: subdirectory or installed as system package (.deb by `apt install`).

`libUV` also has a [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/) support. You can use [FindPkgConfig](https://cmake.org/cmake/help/latest/module/FindPkgConfig.html) from your CMake file to find a system (or any custom) installation of libUV.

## c-ares

[c-ares](https://github.com/c-ares/c-ares) handles CMake targets much better. It always defines `c-ares::c-ares` target and UniEvent always links against it. The only thing you should do ist to set `CARES_SHARED` or `CARES_STATIC` to `ON`. If you set both `c-ares::c-ares` aliases the dynamic library because its definition goes first.

## Catch2

[Catch2](https://github.com/catchorg/Catch2) is an optional dependency. It is used only for tests. If you want to build tests then set `UNIEVENT_TESTS` to `ON` and provide Catch2 (either `add_subdirectory` or just be discoverable for `find_package`). By default tests are not built as part of target `ALL` if UniEvent is a subproject and are built if it is a stadalone project. You can change this behaviour by setting `UNIEVENT_TESTS_IN_ALL`.

## Dedicated Build

This way is much simpler for CMakeLists.txt of your project it but requires much more manual work than `add_subdirectory` [method](#using-add_subdirectory).

First we should install all the dependencies somewhere. Clone these
* [panda-lib](https://github.com/CrazyPandaLimited/panda-lib)
* [panda-net-sockaddr](https://github.com/CrazyPandaLimited/Net-SockAddr)
* [c-ares](https://github.com/c-ares/c-ares)
* [libuv](https://github.com/libuv/libuv)
* [UniEvent itself](https://github.com/CrazyPandaLimited/UniEvent)

For each module from the list do
```bash
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/home/user/somewhere ..
cmake --build . -j
cmake --build . --target install
```

For c-ares set `CARES_SHARED` or `CARES_STATIC` to `ON` as described [above](#c-ares)

```bash
cmake -DCMAKE_INSTALL_PREFIX=/home/user/somewhere -DCARES_STATIC=ON ..
```

For UniEvent set UNIEVENT_UV_TARGET to libuv::uv if you want to link against the shared library and to libuv::uv_a for the static.

After doing this you can add installation folder to CMAKE_MODULE_PATH of your project and just add this to CMakeLists.txt

```CMake
find_package(unievent)
target_link_libraries(${PROJECT_NAME} PUBLIC unievent)
```

## Using `add_subdirectory`

In this section we assume that all the dependencies are provided as subdirectories of the main project and placed in folder `deps`. If some of them are installed in [CMAKE_MODULE_PATH](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html#variable:CMAKE_MODULE_PATH) or any other way then remove it from the example below to use in your project.

```CMake
cmake_minimum_required(VERSION 3.0.0)
project(github_check VERSION 0.1.0)

add_executable(github_check main.cpp)

add_subdirectory(deps/panda-lib)
add_subdirectory(deps/Net-SockAddr)

set(CARES_STATIC ON)
add_subdirectory(deps/c-ares)

add_subdirectory(deps/libuv)

# it's better to set CACHE variables via command line -DUNIEVENT_UV_TARGET or cache editor
# for example we force shared library uv from here
set(UNIEVENT_UV_TARGET uv CACHE STRING "uv target name")

add_subdirectory(deps/UniEvent)

target_link_libraries(${PROJECT_NAME} PUBLIC unievent)
```