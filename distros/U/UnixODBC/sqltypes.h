/*
  Definitions from the unixODBC sqltypes.h, included if necessary.
  iODBC also defines some of these, so make sure that they're
  not already defined if libiodbc is also installed.
  (That's the _SQLTYPES_H define, down below.)
*/

#ifndef __SQLTYPES_H
#define __SQLTYPES_H

#ifndef ODBCVER
#define ODBCVER	0x0351
#endif

#ifndef SIZEOF_LONG
# if defined(__alpha) || defined(__sparcv9)
# define SIZEOF_LONG        8
#else
# define SIZEOF_LONG        4
#endif
#endif

#if (SIZEOF_LONG == 8)
#ifndef DO_YOU_KNOW_WHAT_YOUR_ARE_DOING
#ifndef _SQLTYPES_H     /* Have definition from iodbc header... */
typedef int             SQLINTEGER;
typedef unsigned int    SQLUINTEGER;
#endif
#define SQLLEN          SQLINTEGER
#define SQLULEN         SQLUINTEGER
#define SQLSETPOSIROW   SQLUSMALLINT
typedef SQLULEN         SQLROWCOUNT;
typedef SQLULEN         SQLROWSETSIZE;
typedef SQLULEN         SQLTRANSID;
typedef SQLLEN          SQLROWOFFSET;
#else
#ifndef _SQLTYPES_H     
typedef int             SQLINTEGER;
typedef unsigned int    SQLUINTEGER;
#endif
typedef long            SQLLEN;
typedef unsigned long   SQLULEN;
typedef unsigned long   SQLSETPOSIROW;
#endif
#else
#ifndef _SQLTYPES_H     
typedef long            SQLINTEGER;
typedef unsigned long   SQLUINTEGER;
#endif
#define SQLLEN          SQLINTEGER
#define SQLULEN         SQLUINTEGER
#define SQLSETPOSIROW   SQLUSMALLINT
typedef SQLULEN         SQLROWCOUNT;
typedef SQLULEN         SQLROWSETSIZE;
typedef SQLULEN         SQLTRANSID;
typedef SQLLEN          SQLROWOFFSET;
#endif

#endif  /* __SQLTYPES_H */
