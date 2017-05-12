AC_DEFUN(AC_LIBAPREQ, [
	AC_ARG_WITH(apache-includes,
		[  --with-apache-includes  where the apache header files live],
		[APACHE_INCLUDES=$withval],
		[APACHE_INCLUDES="/usr/local/apache/include"])
	LIBAPREQ_INCLUDES="-I$APACHE_INCLUDES"
	AC_SUBST(LIBAPREQ_INCLUDES)
])