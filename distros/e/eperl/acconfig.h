#ifndef CONFIG_AC_H
#define CONFIG_AC_H
/*
**  config_ac.h -- AUTO configuration header file
**  Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>
*/

@TOP@

/*  defined if Perl support the DynLoader
    interface for dynamic library loading */
#undef HAVE_PERL_DYNALOADER

/*  define type bool for Perl 5 headers if missing */
#undef bool

/*  define DEBUG if we compile with debugging */
#undef DEBUG_ENABLED

/*  define if libdmalloc.a is available */
#undef HAVE_DMALLOC

@BOTTOM@

#endif /* CONFIG_AC_H */
