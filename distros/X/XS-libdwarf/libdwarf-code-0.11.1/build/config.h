
/* Define if building universal (internal helper macro) */
/* #undef AC_APPLE_UNIVERSAL_BUILD */

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if you have the <dlfcn.h> header file. */
/* #undef HAVE_DLFCN_H */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the <malloc.h> header file. */
/* #undef HAVE_MALLOC_H */

/* Set to 1 if big endian . */
/* #undef WORDS_BIGENDIAN */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1


/*  Define to the uintptr_t to the type of an unsigned integer
    type wide enough to hold a pointer
    if the system does not define it. */
/* #undef uintptr_t */
/* #undef intptr_t */

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Set to 1 if zlib decompression is available. */
#define HAVE_ZLIB 1

/* Define to 1 if you have the <zlib.h> header file. */
#define HAVE_ZLIB_H 1

/* Set to 1 if zstd decompression is available. */
#define HAVE_ZSTD 1

/* Define to 1 if you have the <zstd.h> header file. */
#define HAVE_ZSTD_H 1

/* Define to the sub-directory where libtool stores uninstalled libraries. */
/* #undef LT_OBJDIR */

/* Name of package */
/* #undef PACKAGE */

#define PACKAGE_VERSION "0.11.1"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "https://github.com/davea42/libdwarf-code/issues"

/* Define to the full name of this package. */
#define PACKAGE_NAME "libdwarf"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libdwarf 0.11.1"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME

/* Define to the home page for this package. */
#define PACKAGE_URL "https://github.com/davea42/libdwarf-code.git"


/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at runtime.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
/* #undef STDC_HEADERS */

/* Define to the version of this package. */
/* #undef PACKAGE_VERSION */

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
/* #undef WORDS_BIGENDIAN */
# endif
#else
# ifndef WORDS_BIGENDIAN
#  undef WORDS_BIGENDIAN
# endif
#endif

/* Define to `unsigned int' if <sys/types.h> does not define. */
#undef size_t

