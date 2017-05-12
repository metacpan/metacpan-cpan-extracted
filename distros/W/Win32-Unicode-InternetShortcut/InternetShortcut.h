#ifndef INTERNETSHORTCUT_H
#define INTERNETSHORTCUT_H

#ifdef WIN32
#define swprintf _snwprintf
#endif
#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#define COBJMACROS
#define WIN32_LEAN_AND_MEAN	/* Tell windows.h to skip much */
#define INITGUID
#include <windows.h>
#include <objbase.h>
#include <shlobj.h>
#include <shlguid.h>
#include <intshcut.h>
#include <isguids.h>

typedef enum {
    HK_PATH = 0,      /* "path" */
    HK_FULLPATH,      /* "fullpath" */
    HK_PROP,          /* "properties" */
    HK_SITE_PROP,     /* "site_properties" */
    HK_URL,           /* "url" */
    HK_NAME,          /* "name" */
    HK_WORKDIR,       /* "workdir" */
    HK_HOTKEY,        /* "hotkey" */
    HK_SHOWCMD,       /* "showcmd" */
    HK_ICONINDEX,     /* "iconindex" */
    HK_ICONFILE,      /* "iconfile" */
    HK_WHATSNEW,      /* "whatsnew" */
    HK_AUTHOR,        /* "author" */
    HK_DESC,          /* "description" */
    HK_COMMENT,       /* "comment" */
    HK_LASTVISITS,    /* "lastvisits" */
    HK_LASTMOD,       /* "lastmod" */
    HK_FLAGS,         /* "flags" */
    HK_VISITCOUNT,    /* "visitcount" */
    HK_TITLE,         /* "title" */
    HK_CODEPAGE,      /* "codepage" */
    HK_MODIFIED,      /* "modified" */
    HK_TRACKING,      /* "tracking" */
} hk_e;

#define IK_URL           L"URL"
#define IK_MODIFIED      L"Modified"
#define IK_ICONINDEX     L"IconIndex"
#define IK_ICONFILE      L"IconFile"

#define SAFEFREE(sv) { Safefree((sv)); (sv) = NULL; }

#define hash_get(hash, key, value) {                                 \
        SV **v;                                                      \
        if ((v = hv_fetch((hash), key, strlen(key), 0)) != NULL) {   \
            if (SvOK(*v)) {                                          \
                (value) = sv_to_wstr(aTHX_ *v);                      \
            }                                                        \
        }                                                            \
    }
#define hash_store(hash, key, value) hv_store((hash), (key), strlen((key)), (value), 0)

#define HASH_STORE(hash, hash_key_e, value) {                                          \
        switch ((hash_key_e)) {                                                        \
            case HK_PATH      : hash_store((hash), "path", (value)); break;            \
            case HK_FULLPATH  : hash_store((hash), "fullpath", (value)); break;        \
            case HK_PROP      : hash_store((hash), "properties", (value)); break;      \
            case HK_SITE_PROP : hash_store((hash), "site_properties", (value)); break; \
            case HK_URL       : hash_store((hash), "url", (value)); break;             \
            case HK_NAME      : hash_store((hash), "name", (value)); break;            \
            case HK_WORKDIR   : hash_store((hash), "workdir", (value)); break;         \
            case HK_HOTKEY    : hash_store((hash), "hotkey", (value)); break;          \
            case HK_SHOWCMD   : hash_store((hash), "showcmd", (value)); break;         \
            case HK_ICONINDEX : hash_store((hash), "iconindex", (value)); break;       \
            case HK_ICONFILE  : hash_store((hash), "iconfile", (value)); break;        \
            case HK_WHATSNEW  : hash_store((hash), "whatsnew", (value)); break;        \
            case HK_AUTHOR    : hash_store((hash), "author", (value)); break;          \
            case HK_DESC      : hash_store((hash), "description", (value)); break;     \
            case HK_COMMENT   : hash_store((hash), "comment", (value)); break;         \
            case HK_LASTVISITS: hash_store((hash), "lastvisits", (value)); break;      \
            case HK_LASTMOD   : hash_store((hash), "lastmod", (value)); break;         \
            case HK_FLAGS     : hash_store((hash), "flags", (value)); break;           \
            case HK_VISITCOUNT: hash_store((hash), "visitcount", (value)); break;      \
            case HK_TITLE     : hash_store((hash), "title", (value)); break;           \
            case HK_CODEPAGE  : hash_store((hash), "codepage", (value)); break;        \
            case HK_MODIFIED  : hash_store((hash), "modified", (value)); break;        \
            case HK_TRACKING  : hash_store((hash), "tracking", (value)); break;        \
            default: ComErrorMsg(1, "HK_TO_LOCAL_STRING", E_UNEXPECTED);               \
    }                                                                                  \
}

#define HASH_GET(hash, hash_key_e, value) {                                          \
        switch ((hash_key_e)) {                                                      \
            case HK_PATH      : hash_get((hash), "path", (value)); break;            \
            case HK_FULLPATH  : hash_get((hash), "fullpath", (value)); break;        \
            case HK_PROP      : hash_get((hash), "properties", (value)); break;      \
            case HK_SITE_PROP : hash_get((hash), "site_properties", (value)); break; \
            case HK_URL       : hash_get((hash), "url", (value)); break;             \
            case HK_NAME      : hash_get((hash), "name", (value)); break;            \
            case HK_WORKDIR   : hash_get((hash), "workdir", (value)); break;         \
            case HK_HOTKEY    : hash_get((hash), "hotkey", (value)); break;          \
            case HK_SHOWCMD   : hash_get((hash), "showcmd", (value)); break;         \
            case HK_ICONINDEX : hash_get((hash), "iconindex", (value)); break;       \
            case HK_ICONFILE  : hash_get((hash), "iconfile", (value)); break;        \
            case HK_WHATSNEW  : hash_get((hash), "whatsnew", (value)); break;        \
            case HK_AUTHOR    : hash_get((hash), "author", (value)); break;          \
            case HK_DESC      : hash_get((hash), "description", (value)); break;     \
            case HK_COMMENT   : hash_get((hash), "comment", (value)); break;         \
            case HK_LASTVISITS: hash_get((hash), "lastvisits", (value)); break;      \
            case HK_LASTMOD   : hash_get((hash), "lastmod", (value)); break;         \
            case HK_FLAGS     : hash_get((hash), "flags", (value)); break;           \
            case HK_VISITCOUNT: hash_get((hash), "visitcount", (value)); break;      \
            case HK_TITLE     : hash_get((hash), "title", (value)); break;           \
            case HK_CODEPAGE  : hash_get((hash), "codepage", (value)); break;        \
            case HK_MODIFIED  : hash_get((hash), "modified", (value)); break;        \
            case HK_TRACKING  : hash_get((hash), "tracking", (value)); break;        \
            default: ComErrorMsg(1, "HK_TO_LOCAL_STRING", E_UNEXPECTED);             \
    }                                                                                \
}

#define _STGM_SHARE_READ  (STGM_READ      | STGM_SHARE_DENY_WRITE)
#define _STGM_SHARE_WRITE (STGM_WRITE     | STGM_CREATE | STGM_DIRECT | STGM_SHARE_EXCLUSIVE)
#define _STGM_SHARE_READWRITE  (STGM_READWRITE | STGM_CREATE | STGM_DIRECT | STGM_SHARE_EXCLUSIVE)

/* should use CTime or something like that? */
#define _stringify_systime(buf, systime)		\
  sprintf((buf), "%04d-%02d-%02d %02d:%02d:%02d",	\
	  (systime).wYear,				\
	  (systime).wMonth,				\
	  (systime).wDay,				\
	  (systime).wHour,				\
	  (systime).wMinute,				\
	  (systime).wSecond				\
  )

/* should use CTime or something like that? */
#define _wunstringify_systime(buf, systime)		\
  swscanf((buf), L"%04d-%02d-%02d %02d:%02d:%02d",	\
	  &((systime).wYear),				\
	  &((systime).wMonth),				\
	  &((systime).wDay),				\
	  &((systime).wHour),				\
	  &((systime).wMinute),				\
	  &((systime).wSecond)				\
  )

/***** to make MinGW gcc happy *****/

/* from MSVC objidl.h */
#ifndef _PROPVARIANTINIT_DEFINED_
WINOLEAPI PropVariantClear ( PROPVARIANT * pvar );
#   ifdef __cplusplus
inline void PropVariantInit ( PROPVARIANT * pvar )
{
    memset ( pvar, 0, sizeof(PROPVARIANT) );
}
#   else
#   define PropVariantInit(pvar) memset ( pvar, 0, sizeof(PROPVARIANT) )
#endif
#endif

/* from MSVC shlobj.h */
#ifndef PID_IS_URL
#define PID_IS_URL           2
#define PID_IS_NAME          4
#define PID_IS_WORKINGDIR    5
#define PID_IS_HOTKEY        6
#define PID_IS_SHOWCMD       7
#define PID_IS_ICONINDEX     8
#define PID_IS_ICONFILE      9
#define PID_IS_WHATSNEW      10
#define PID_IS_AUTHOR        11
#define PID_IS_DESCRIPTION   12
#define PID_IS_COMMENT       13

#define PID_INTSITE_WHATSNEW      2
#define PID_INTSITE_AUTHOR        3
#define PID_INTSITE_LASTVISIT     4
#define PID_INTSITE_LASTMOD       5
#define PID_INTSITE_VISITCOUNT    6
#define PID_INTSITE_DESCRIPTION   7
#define PID_INTSITE_COMMENT       8
#define PID_INTSITE_FLAGS         9
#define PID_INTSITE_CONTENTLEN    10
#define PID_INTSITE_CONTENTCODE   11
#define PID_INTSITE_RECURSE       12
#define PID_INTSITE_WATCH         13
#define PID_INTSITE_SUBSCRIPTION  14
#define PID_INTSITE_URL           15
#define PID_INTSITE_TITLE         16
#define PID_INTSITE_CODEPAGE      18
#define PID_INTSITE_TRACKING      19
#define PID_INTSITE_ICONINDEX     20;
#define PID_INTSITE_ICONFILE      21;
#endif

#ifndef MAX_PATHW
#define	MAX_PATHW 32767
#endif

#define MY_MAX_PATHW MAX_PATHW

#define null_arg(sv)	(  SvROK(sv)  &&  SVt_PVAV == SvTYPE(SvRV(sv))	\
			   &&  -1 == av_len((AV*)SvRV(sv))  )

#endif
