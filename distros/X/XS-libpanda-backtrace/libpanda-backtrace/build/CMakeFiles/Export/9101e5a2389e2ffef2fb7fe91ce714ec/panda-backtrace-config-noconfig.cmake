#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "panda::panda-backtrace" for configuration ""
set_property(TARGET panda::panda-backtrace APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(panda::panda-backtrace PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_NOCONFIG "CXX"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libpanda-backtrace.a"
  )

list(APPEND _cmake_import_check_targets panda::panda-backtrace )
list(APPEND _cmake_import_check_files_for_panda::panda-backtrace "${_IMPORT_PREFIX}/lib/libpanda-backtrace.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
