#define HK_PATH          "path"
#define HK_FULLPATH      "fullpath"

#define HK_PROP          "properties"
#define HK_SITE_PROP     "site_properties"

#define HK_URL           "url"
#define HK_NAME          "name"
#define HK_WORKDIR       "workdir"
#define HK_HOTKEY        "hotkey"
#define HK_SHOWCMD       "showcmd"
#define HK_ICONINDEX     "iconindex"
#define HK_ICONFILE      "iconfile"
#define HK_WHATSNEW      "whatsnew"
#define HK_AUTHOR        "author"
#define HK_DESC          "description"
#define HK_COMMENT       "comment"

#define HK_LASTVISITS    "lastvisits"
#define HK_LASTMOD       "lastmod"
#define HK_FLAGS         "flags"
#define HK_VISITCOUNT    "visitcount"
#define HK_TITLE         "title"
#define HK_CODEPAGE      "codepage"

#define HK_MODIFIED      "modified"

#define IK_URL           "URL"
#define IK_MODIFIED      "Modified"
#define IK_ICONINDEX     "IconIndex"
#define IK_ICONFILE      "IconFile"

#define hash_store(hash, key, value) \
  hv_store(hash, key, strlen(key), value, 0)

#define _STGM_SHARE_READ (STGM_READ | STGM_SHARE_DENY_WRITE)

/* should use CTime or something like that? */
#define _stringify_systime(buf, systime) \
  sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", \
    systime.wYear,     \
    systime.wMonth,    \
    systime.wDay,      \
    systime.wHour,     \
    systime.wMinute,   \
    systime.wSecond    \
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
#endif
