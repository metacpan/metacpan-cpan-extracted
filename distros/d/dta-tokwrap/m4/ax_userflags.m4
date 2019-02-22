dnl -*- Mode: autoconf -*-

##==============================================================================
AC_DEFUN([AX_SAVE_USERFLAGS],
[
AC_MSG_NOTICE([saving user *FLAGS variables])
##-- save user's *FLAGS
USER_LIBS="$LIBS"
USER_LDFLAGS="$LDFLAGS"
USER_CPPFLAGS="$CPPFLAGS"
USER_CFLAGS="$CFLAGS"
USER_CXXFLAGS="$CXXFLAGS"
])

##==============================================================================
AC_DEFUN([AX_RESTORE_USERFLAGS],
[
##-- resture
AC_MSG_NOTICE([restoring user *FLAGS variables])
#test -n "$USER_LIBS" && LIBS="$USER_LIBS"
#test -n "$USER_LDFLAGS" && LDFLAGS="$USER_LDFLAGS"
#test -n "$USER_CPPFLAGS" && CPPFLAGS="$USER_CPPFLAGS"
test -n "$USER_CFLAGS" && CFLAGS="$USER_CFLAGS";
test -n "$USER_CXXFLAGS" && CXXFLAGS="$USER_CXXFLAGS";
])
