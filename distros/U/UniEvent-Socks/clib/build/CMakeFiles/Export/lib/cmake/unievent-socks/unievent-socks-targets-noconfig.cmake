#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "unievent-socks" for configuration ""
set_property(TARGET unievent-socks APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(unievent-socks PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libunievent-socks.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS unievent-socks )
list(APPEND _IMPORT_CHECK_FILES_FOR_unievent-socks "${_IMPORT_PREFIX}/lib/libunievent-socks.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
