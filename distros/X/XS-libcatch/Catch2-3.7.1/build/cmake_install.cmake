# Install script for directory: /tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "cmake_prefix")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Catch2" TYPE FILE FILES
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/build/Catch2Config.cmake"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/build/Catch2ConfigVersion.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/share/doc/Catch2" TYPE DIRECTORY FILES "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/docs/" REGEX "/doxygen$" EXCLUDE)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Catch2" TYPE FILE FILES
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/ParseAndAddCatchTests.cmake"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/Catch.cmake"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/CatchAddTests.cmake"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/CatchShardTests.cmake"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/CatchShardTestsImpl.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/share/Catch2" TYPE FILE FILES
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/gdbinit"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/extras/lldbinit"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/share/pkgconfig" TYPE FILE FILES
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/build/catch2.pc"
    "/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/build/catch2-with-main.pc"
    )
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/tmp/XS-libcatch-XAgmTxpIj__m/Catch2-3.7.1/build/src/cmake_install.cmake")

endif()

