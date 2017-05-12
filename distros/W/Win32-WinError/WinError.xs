#if !defined(__MINGW32__) && !(defined(__BORLANDC__) && __BORLANDC__ >= 0x0550)
#include <wtypes.h>
#endif
#include <WinError.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	if (strEQ(name, "CACHE_E_FIRST"))
#ifdef CACHE_E_FIRST
	    return CACHE_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_E_LAST"))
#ifdef CACHE_E_LAST
	    return CACHE_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_E_NOCACHE_UPDATED"))
#ifdef CACHE_E_NOCACHE_UPDATED
	    return CACHE_E_NOCACHE_UPDATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_S_FIRST"))
#ifdef CACHE_S_FIRST
	    return CACHE_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_S_FORMATETC_NOTSUPPORTED"))
#ifdef CACHE_S_FORMATETC_NOTSUPPORTED
	    return CACHE_S_FORMATETC_NOTSUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_S_LAST"))
#ifdef CACHE_S_LAST
	    return CACHE_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_S_SAMECACHE"))
#ifdef CACHE_S_SAMECACHE
	    return CACHE_S_SAMECACHE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CACHE_S_SOMECACHES_NOTUPDATED"))
#ifdef CACHE_S_SOMECACHES_NOTUPDATED
	    return CACHE_S_SOMECACHES_NOTUPDATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASSFACTORY_E_FIRST"))
#ifdef CLASSFACTORY_E_FIRST
	    return CLASSFACTORY_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASSFACTORY_E_LAST"))
#ifdef CLASSFACTORY_E_LAST
	    return CLASSFACTORY_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASSFACTORY_S_FIRST"))
#ifdef CLASSFACTORY_S_FIRST
	    return CLASSFACTORY_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASSFACTORY_S_LAST"))
#ifdef CLASSFACTORY_S_LAST
	    return CLASSFACTORY_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASS_E_CLASSNOTAVAILABLE"))
#ifdef CLASS_E_CLASSNOTAVAILABLE
	    return CLASS_E_CLASSNOTAVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLASS_E_NOAGGREGATION"))
#ifdef CLASS_E_NOAGGREGATION
	    return CLASS_E_NOAGGREGATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIENTSITE_E_FIRST"))
#ifdef CLIENTSITE_E_FIRST
	    return CLIENTSITE_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIENTSITE_E_LAST"))
#ifdef CLIENTSITE_E_LAST
	    return CLIENTSITE_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIENTSITE_S_FIRST"))
#ifdef CLIENTSITE_S_FIRST
	    return CLIENTSITE_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIENTSITE_S_LAST"))
#ifdef CLIENTSITE_S_LAST
	    return CLIENTSITE_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_BAD_DATA"))
#ifdef CLIPBRD_E_BAD_DATA
	    return CLIPBRD_E_BAD_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_CANT_CLOSE"))
#ifdef CLIPBRD_E_CANT_CLOSE
	    return CLIPBRD_E_CANT_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_CANT_EMPTY"))
#ifdef CLIPBRD_E_CANT_EMPTY
	    return CLIPBRD_E_CANT_EMPTY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_CANT_OPEN"))
#ifdef CLIPBRD_E_CANT_OPEN
	    return CLIPBRD_E_CANT_OPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_CANT_SET"))
#ifdef CLIPBRD_E_CANT_SET
	    return CLIPBRD_E_CANT_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_FIRST"))
#ifdef CLIPBRD_E_FIRST
	    return CLIPBRD_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_E_LAST"))
#ifdef CLIPBRD_E_LAST
	    return CLIPBRD_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_S_FIRST"))
#ifdef CLIPBRD_S_FIRST
	    return CLIPBRD_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CLIPBRD_S_LAST"))
#ifdef CLIPBRD_S_LAST
	    return CLIPBRD_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_FIRST"))
#ifdef CONVERT10_E_FIRST
	    return CONVERT10_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_LAST"))
#ifdef CONVERT10_E_LAST
	    return CONVERT10_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_OLESTREAM_BITMAP_TO_DIB"))
#ifdef CONVERT10_E_OLESTREAM_BITMAP_TO_DIB
	    return CONVERT10_E_OLESTREAM_BITMAP_TO_DIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_OLESTREAM_FMT"))
#ifdef CONVERT10_E_OLESTREAM_FMT
	    return CONVERT10_E_OLESTREAM_FMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_OLESTREAM_GET"))
#ifdef CONVERT10_E_OLESTREAM_GET
	    return CONVERT10_E_OLESTREAM_GET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_OLESTREAM_PUT"))
#ifdef CONVERT10_E_OLESTREAM_PUT
	    return CONVERT10_E_OLESTREAM_PUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_STG_DIB_TO_BITMAP"))
#ifdef CONVERT10_E_STG_DIB_TO_BITMAP
	    return CONVERT10_E_STG_DIB_TO_BITMAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_STG_FMT"))
#ifdef CONVERT10_E_STG_FMT
	    return CONVERT10_E_STG_FMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_E_STG_NO_STD_STREAM"))
#ifdef CONVERT10_E_STG_NO_STD_STREAM
	    return CONVERT10_E_STG_NO_STD_STREAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_S_FIRST"))
#ifdef CONVERT10_S_FIRST
	    return CONVERT10_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_S_LAST"))
#ifdef CONVERT10_S_LAST
	    return CONVERT10_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CONVERT10_S_NO_PRESENTATION"))
#ifdef CONVERT10_S_NO_PRESENTATION
	    return CONVERT10_S_NO_PRESENTATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_ALREADYINITIALIZED"))
#ifdef CO_E_ALREADYINITIALIZED
	    return CO_E_ALREADYINITIALIZED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_APPDIDNTREG"))
#ifdef CO_E_APPDIDNTREG
	    return CO_E_APPDIDNTREG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_APPNOTFOUND"))
#ifdef CO_E_APPNOTFOUND
	    return CO_E_APPNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_APPSINGLEUSE"))
#ifdef CO_E_APPSINGLEUSE
	    return CO_E_APPSINGLEUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_BAD_PATH"))
#ifdef CO_E_BAD_PATH
	    return CO_E_BAD_PATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_CANTDETERMINECLASS"))
#ifdef CO_E_CANTDETERMINECLASS
	    return CO_E_CANTDETERMINECLASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_CLASSSTRING"))
#ifdef CO_E_CLASSSTRING
	    return CO_E_CLASSSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_CLASS_CREATE_FAILED"))
#ifdef CO_E_CLASS_CREATE_FAILED
	    return CO_E_CLASS_CREATE_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_DLLNOTFOUND"))
#ifdef CO_E_DLLNOTFOUND
	    return CO_E_DLLNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_ERRORINAPP"))
#ifdef CO_E_ERRORINAPP
	    return CO_E_ERRORINAPP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_ERRORINDLL"))
#ifdef CO_E_ERRORINDLL
	    return CO_E_ERRORINDLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_FIRST"))
#ifdef CO_E_FIRST
	    return CO_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_IIDSTRING"))
#ifdef CO_E_IIDSTRING
	    return CO_E_IIDSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_CLASS_CACHE"))
#ifdef CO_E_INIT_CLASS_CACHE
	    return CO_E_INIT_CLASS_CACHE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_MEMORY_ALLOCATOR"))
#ifdef CO_E_INIT_MEMORY_ALLOCATOR
	    return CO_E_INIT_MEMORY_ALLOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_ONLY_SINGLE_THREADED"))
#ifdef CO_E_INIT_ONLY_SINGLE_THREADED
	    return CO_E_INIT_ONLY_SINGLE_THREADED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_RPC_CHANNEL"))
#ifdef CO_E_INIT_RPC_CHANNEL
	    return CO_E_INIT_RPC_CHANNEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_SCM_EXEC_FAILURE"))
#ifdef CO_E_INIT_SCM_EXEC_FAILURE
	    return CO_E_INIT_SCM_EXEC_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_SCM_FILE_MAPPING_EXISTS"))
#ifdef CO_E_INIT_SCM_FILE_MAPPING_EXISTS
	    return CO_E_INIT_SCM_FILE_MAPPING_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_SCM_MAP_VIEW_OF_FILE"))
#ifdef CO_E_INIT_SCM_MAP_VIEW_OF_FILE
	    return CO_E_INIT_SCM_MAP_VIEW_OF_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_SCM_MUTEX_EXISTS"))
#ifdef CO_E_INIT_SCM_MUTEX_EXISTS
	    return CO_E_INIT_SCM_MUTEX_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_SHARED_ALLOCATOR"))
#ifdef CO_E_INIT_SHARED_ALLOCATOR
	    return CO_E_INIT_SHARED_ALLOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_TLS"))
#ifdef CO_E_INIT_TLS
	    return CO_E_INIT_TLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_TLS_CHANNEL_CONTROL"))
#ifdef CO_E_INIT_TLS_CHANNEL_CONTROL
	    return CO_E_INIT_TLS_CHANNEL_CONTROL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_TLS_SET_CHANNEL_CONTROL"))
#ifdef CO_E_INIT_TLS_SET_CHANNEL_CONTROL
	    return CO_E_INIT_TLS_SET_CHANNEL_CONTROL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_INIT_UNACCEPTED_USER_ALLOCATOR"))
#ifdef CO_E_INIT_UNACCEPTED_USER_ALLOCATOR
	    return CO_E_INIT_UNACCEPTED_USER_ALLOCATOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_LAST"))
#ifdef CO_E_LAST
	    return CO_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_NOTINITIALIZED"))
#ifdef CO_E_NOTINITIALIZED
	    return CO_E_NOTINITIALIZED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_OBJISREG"))
#ifdef CO_E_OBJISREG
	    return CO_E_OBJISREG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_OBJNOTCONNECTED"))
#ifdef CO_E_OBJNOTCONNECTED
	    return CO_E_OBJNOTCONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_OBJNOTREG"))
#ifdef CO_E_OBJNOTREG
	    return CO_E_OBJNOTREG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_OBJSRV_RPC_FAILURE"))
#ifdef CO_E_OBJSRV_RPC_FAILURE
	    return CO_E_OBJSRV_RPC_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_RELEASED"))
#ifdef CO_E_RELEASED
	    return CO_E_RELEASED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_SCM_ERROR"))
#ifdef CO_E_SCM_ERROR
	    return CO_E_SCM_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_SCM_RPC_FAILURE"))
#ifdef CO_E_SCM_RPC_FAILURE
	    return CO_E_SCM_RPC_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_SERVER_EXEC_FAILURE"))
#ifdef CO_E_SERVER_EXEC_FAILURE
	    return CO_E_SERVER_EXEC_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_SERVER_STOPPING"))
#ifdef CO_E_SERVER_STOPPING
	    return CO_E_SERVER_STOPPING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_E_WRONGOSFORAPP"))
#ifdef CO_E_WRONGOSFORAPP
	    return CO_E_WRONGOSFORAPP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_S_FIRST"))
#ifdef CO_S_FIRST
	    return CO_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "CO_S_LAST"))
#ifdef CO_S_LAST
	    return CO_S_LAST;
#else
	    goto not_there;
#endif
	break;
    case 'D':
	if (strEQ(name, "DATA_E_FIRST"))
#ifdef DATA_E_FIRST
	    return DATA_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DATA_E_LAST"))
#ifdef DATA_E_LAST
	    return DATA_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DATA_S_FIRST"))
#ifdef DATA_S_FIRST
	    return DATA_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DATA_S_LAST"))
#ifdef DATA_S_LAST
	    return DATA_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DATA_S_SAMEFORMATETC"))
#ifdef DATA_S_SAMEFORMATETC
	    return DATA_S_SAMEFORMATETC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_ARRAYISLOCKED"))
#ifdef DISP_E_ARRAYISLOCKED
	    return DISP_E_ARRAYISLOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_BADCALLEE"))
#ifdef DISP_E_BADCALLEE
	    return DISP_E_BADCALLEE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_BADINDEX"))
#ifdef DISP_E_BADINDEX
	    return DISP_E_BADINDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_BADPARAMCOUNT"))
#ifdef DISP_E_BADPARAMCOUNT
	    return DISP_E_BADPARAMCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_BADVARTYPE"))
#ifdef DISP_E_BADVARTYPE
	    return DISP_E_BADVARTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_EXCEPTION"))
#ifdef DISP_E_EXCEPTION
	    return DISP_E_EXCEPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_MEMBERNOTFOUND"))
#ifdef DISP_E_MEMBERNOTFOUND
	    return DISP_E_MEMBERNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_NONAMEDARGS"))
#ifdef DISP_E_NONAMEDARGS
	    return DISP_E_NONAMEDARGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_NOTACOLLECTION"))
#ifdef DISP_E_NOTACOLLECTION
	    return DISP_E_NOTACOLLECTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_OVERFLOW"))
#ifdef DISP_E_OVERFLOW
	    return DISP_E_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_PARAMNOTFOUND"))
#ifdef DISP_E_PARAMNOTFOUND
	    return DISP_E_PARAMNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_PARAMNOTOPTIONAL"))
#ifdef DISP_E_PARAMNOTOPTIONAL
	    return DISP_E_PARAMNOTOPTIONAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_TYPEMISMATCH"))
#ifdef DISP_E_TYPEMISMATCH
	    return DISP_E_TYPEMISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_UNKNOWNINTERFACE"))
#ifdef DISP_E_UNKNOWNINTERFACE
	    return DISP_E_UNKNOWNINTERFACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_UNKNOWNLCID"))
#ifdef DISP_E_UNKNOWNLCID
	    return DISP_E_UNKNOWNLCID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DISP_E_UNKNOWNNAME"))
#ifdef DISP_E_UNKNOWNNAME
	    return DISP_E_UNKNOWNNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_E_ALREADYREGISTERED"))
#ifdef DRAGDROP_E_ALREADYREGISTERED
	    return DRAGDROP_E_ALREADYREGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_E_FIRST"))
#ifdef DRAGDROP_E_FIRST
	    return DRAGDROP_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_E_INVALIDHWND"))
#ifdef DRAGDROP_E_INVALIDHWND
	    return DRAGDROP_E_INVALIDHWND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_E_LAST"))
#ifdef DRAGDROP_E_LAST
	    return DRAGDROP_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_E_NOTREGISTERED"))
#ifdef DRAGDROP_E_NOTREGISTERED
	    return DRAGDROP_E_NOTREGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_S_CANCEL"))
#ifdef DRAGDROP_S_CANCEL
	    return DRAGDROP_S_CANCEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_S_DROP"))
#ifdef DRAGDROP_S_DROP
	    return DRAGDROP_S_DROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_S_FIRST"))
#ifdef DRAGDROP_S_FIRST
	    return DRAGDROP_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_S_LAST"))
#ifdef DRAGDROP_S_LAST
	    return DRAGDROP_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DRAGDROP_S_USEDEFAULTCURSORS"))
#ifdef DRAGDROP_S_USEDEFAULTCURSORS
	    return DRAGDROP_S_USEDEFAULTCURSORS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_CLIPFORMAT"))
#ifdef DV_E_CLIPFORMAT
	    return DV_E_CLIPFORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_DVASPECT"))
#ifdef DV_E_DVASPECT
	    return DV_E_DVASPECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_DVTARGETDEVICE"))
#ifdef DV_E_DVTARGETDEVICE
	    return DV_E_DVTARGETDEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_DVTARGETDEVICE_SIZE"))
#ifdef DV_E_DVTARGETDEVICE_SIZE
	    return DV_E_DVTARGETDEVICE_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_FORMATETC"))
#ifdef DV_E_FORMATETC
	    return DV_E_FORMATETC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_LINDEX"))
#ifdef DV_E_LINDEX
	    return DV_E_LINDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_NOIVIEWOBJECT"))
#ifdef DV_E_NOIVIEWOBJECT
	    return DV_E_NOIVIEWOBJECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_STATDATA"))
#ifdef DV_E_STATDATA
	    return DV_E_STATDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_STGMEDIUM"))
#ifdef DV_E_STGMEDIUM
	    return DV_E_STGMEDIUM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "DV_E_TYMED"))
#ifdef DV_E_TYMED
	    return DV_E_TYMED;
#else
	    goto not_there;
#endif
	break;
    case 'E':
	if (strEQ(name, "ENUM_E_FIRST"))
#ifdef ENUM_E_FIRST
	    return ENUM_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENUM_E_LAST"))
#ifdef ENUM_E_LAST
	    return ENUM_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENUM_S_FIRST"))
#ifdef ENUM_S_FIRST
	    return ENUM_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENUM_S_LAST"))
#ifdef ENUM_S_LAST
	    return ENUM_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EPT_S_CANT_CREATE"))
#ifdef EPT_S_CANT_CREATE
	    return EPT_S_CANT_CREATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EPT_S_CANT_PERFORM_OP"))
#ifdef EPT_S_CANT_PERFORM_OP
	    return EPT_S_CANT_PERFORM_OP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EPT_S_INVALID_ENTRY"))
#ifdef EPT_S_INVALID_ENTRY
	    return EPT_S_INVALID_ENTRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EPT_S_NOT_REGISTERED"))
#ifdef EPT_S_NOT_REGISTERED
	    return EPT_S_NOT_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACCESS_DENIED"))
#ifdef ERROR_ACCESS_DENIED
	    return ERROR_ACCESS_DENIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACCOUNT_DISABLED"))
#ifdef ERROR_ACCOUNT_DISABLED
	    return ERROR_ACCOUNT_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACCOUNT_EXPIRED"))
#ifdef ERROR_ACCOUNT_EXPIRED
	    return ERROR_ACCOUNT_EXPIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACCOUNT_LOCKED_OUT"))
#ifdef ERROR_ACCOUNT_LOCKED_OUT
	    return ERROR_ACCOUNT_LOCKED_OUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACCOUNT_RESTRICTION"))
#ifdef ERROR_ACCOUNT_RESTRICTION
	    return ERROR_ACCOUNT_RESTRICTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ACTIVE_CONNECTIONS"))
#ifdef ERROR_ACTIVE_CONNECTIONS
	    return ERROR_ACTIVE_CONNECTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ADAP_HDW_ERR"))
#ifdef ERROR_ADAP_HDW_ERR
	    return ERROR_ADAP_HDW_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ADDRESS_ALREADY_ASSOCIATED"))
#ifdef ERROR_ADDRESS_ALREADY_ASSOCIATED
	    return ERROR_ADDRESS_ALREADY_ASSOCIATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ADDRESS_NOT_ASSOCIATED"))
#ifdef ERROR_ADDRESS_NOT_ASSOCIATED
	    return ERROR_ADDRESS_NOT_ASSOCIATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALIAS_EXISTS"))
#ifdef ERROR_ALIAS_EXISTS
	    return ERROR_ALIAS_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALLOTTED_SPACE_EXCEEDED"))
#ifdef ERROR_ALLOTTED_SPACE_EXCEEDED
	    return ERROR_ALLOTTED_SPACE_EXCEEDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALREADY_ASSIGNED"))
#ifdef ERROR_ALREADY_ASSIGNED
	    return ERROR_ALREADY_ASSIGNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALREADY_EXISTS"))
#ifdef ERROR_ALREADY_EXISTS
	    return ERROR_ALREADY_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALREADY_REGISTERED"))
#ifdef ERROR_ALREADY_REGISTERED
	    return ERROR_ALREADY_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALREADY_RUNNING_LKG"))
#ifdef ERROR_ALREADY_RUNNING_LKG
	    return ERROR_ALREADY_RUNNING_LKG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ALREADY_WAITING"))
#ifdef ERROR_ALREADY_WAITING
	    return ERROR_ALREADY_WAITING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ARENA_TRASHED"))
#ifdef ERROR_ARENA_TRASHED
	    return ERROR_ARENA_TRASHED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ARITHMETIC_OVERFLOW"))
#ifdef ERROR_ARITHMETIC_OVERFLOW
	    return ERROR_ARITHMETIC_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ATOMIC_LOCKS_NOT_SUPPORTED"))
#ifdef ERROR_ATOMIC_LOCKS_NOT_SUPPORTED
	    return ERROR_ATOMIC_LOCKS_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_AUTODATASEG_EXCEEDS_64k"))
#ifdef ERROR_AUTODATASEG_EXCEEDS_64k
	    return ERROR_AUTODATASEG_EXCEEDS_64k;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BADDB"))
#ifdef ERROR_BADDB
	    return ERROR_BADDB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BADKEY"))
#ifdef ERROR_BADKEY
	    return ERROR_BADKEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_ARGUMENTS"))
#ifdef ERROR_BAD_ARGUMENTS
	    return ERROR_BAD_ARGUMENTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_COMMAND"))
#ifdef ERROR_BAD_COMMAND
	    return ERROR_BAD_COMMAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_DESCRIPTOR_FORMAT"))
#ifdef ERROR_BAD_DESCRIPTOR_FORMAT
	    return ERROR_BAD_DESCRIPTOR_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_DEVICE"))
#ifdef ERROR_BAD_DEVICE
	    return ERROR_BAD_DEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_DEV_TYPE"))
#ifdef ERROR_BAD_DEV_TYPE
	    return ERROR_BAD_DEV_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_DRIVER"))
#ifdef ERROR_BAD_DRIVER
	    return ERROR_BAD_DRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_DRIVER_LEVEL"))
#ifdef ERROR_BAD_DRIVER_LEVEL
	    return ERROR_BAD_DRIVER_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_ENVIRONMENT"))
#ifdef ERROR_BAD_ENVIRONMENT
	    return ERROR_BAD_ENVIRONMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_EXE_FORMAT"))
#ifdef ERROR_BAD_EXE_FORMAT
	    return ERROR_BAD_EXE_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_FORMAT"))
#ifdef ERROR_BAD_FORMAT
	    return ERROR_BAD_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_IMPERSONATION_LEVEL"))
#ifdef ERROR_BAD_IMPERSONATION_LEVEL
	    return ERROR_BAD_IMPERSONATION_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_INHERITANCE_ACL"))
#ifdef ERROR_BAD_INHERITANCE_ACL
	    return ERROR_BAD_INHERITANCE_ACL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_LENGTH"))
#ifdef ERROR_BAD_LENGTH
	    return ERROR_BAD_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_LOGON_SESSION_STATE"))
#ifdef ERROR_BAD_LOGON_SESSION_STATE
	    return ERROR_BAD_LOGON_SESSION_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_NETPATH"))
#ifdef ERROR_BAD_NETPATH
	    return ERROR_BAD_NETPATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_NET_NAME"))
#ifdef ERROR_BAD_NET_NAME
	    return ERROR_BAD_NET_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_NET_RESP"))
#ifdef ERROR_BAD_NET_RESP
	    return ERROR_BAD_NET_RESP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_PATHNAME"))
#ifdef ERROR_BAD_PATHNAME
	    return ERROR_BAD_PATHNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_PIPE"))
#ifdef ERROR_BAD_PIPE
	    return ERROR_BAD_PIPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_PROFILE"))
#ifdef ERROR_BAD_PROFILE
	    return ERROR_BAD_PROFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_PROVIDER"))
#ifdef ERROR_BAD_PROVIDER
	    return ERROR_BAD_PROVIDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_REM_ADAP"))
#ifdef ERROR_BAD_REM_ADAP
	    return ERROR_BAD_REM_ADAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_THREADID_ADDR"))
#ifdef ERROR_BAD_THREADID_ADDR
	    return ERROR_BAD_THREADID_ADDR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_TOKEN_TYPE"))
#ifdef ERROR_BAD_TOKEN_TYPE
	    return ERROR_BAD_TOKEN_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_UNIT"))
#ifdef ERROR_BAD_UNIT
	    return ERROR_BAD_UNIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_USERNAME"))
#ifdef ERROR_BAD_USERNAME
	    return ERROR_BAD_USERNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BAD_VALIDATION_CLASS"))
#ifdef ERROR_BAD_VALIDATION_CLASS
	    return ERROR_BAD_VALIDATION_CLASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BEGINNING_OF_MEDIA"))
#ifdef ERROR_BEGINNING_OF_MEDIA
	    return ERROR_BEGINNING_OF_MEDIA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BOOT_ALREADY_ACCEPTED"))
#ifdef ERROR_BOOT_ALREADY_ACCEPTED
	    return ERROR_BOOT_ALREADY_ACCEPTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BROKEN_PIPE"))
#ifdef ERROR_BROKEN_PIPE
	    return ERROR_BROKEN_PIPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BUFFER_OVERFLOW"))
#ifdef ERROR_BUFFER_OVERFLOW
	    return ERROR_BUFFER_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BUSY"))
#ifdef ERROR_BUSY
	    return ERROR_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BUSY_DRIVE"))
#ifdef ERROR_BUSY_DRIVE
	    return ERROR_BUSY_DRIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_BUS_RESET"))
#ifdef ERROR_BUS_RESET
	    return ERROR_BUS_RESET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CALL_NOT_IMPLEMENTED"))
#ifdef ERROR_CALL_NOT_IMPLEMENTED
	    return ERROR_CALL_NOT_IMPLEMENTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANCELLED"))
#ifdef ERROR_CANCELLED
	    return ERROR_CANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANCEL_VIOLATION"))
#ifdef ERROR_CANCEL_VIOLATION
	    return ERROR_CANCEL_VIOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANNOT_COPY"))
#ifdef ERROR_CANNOT_COPY
	    return ERROR_CANNOT_COPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANNOT_FIND_WND_CLASS"))
#ifdef ERROR_CANNOT_FIND_WND_CLASS
	    return ERROR_CANNOT_FIND_WND_CLASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANNOT_IMPERSONATE"))
#ifdef ERROR_CANNOT_IMPERSONATE
	    return ERROR_CANNOT_IMPERSONATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANNOT_MAKE"))
#ifdef ERROR_CANNOT_MAKE
	    return ERROR_CANNOT_MAKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANNOT_OPEN_PROFILE"))
#ifdef ERROR_CANNOT_OPEN_PROFILE
	    return ERROR_CANNOT_OPEN_PROFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANTOPEN"))
#ifdef ERROR_CANTOPEN
	    return ERROR_CANTOPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANTREAD"))
#ifdef ERROR_CANTREAD
	    return ERROR_CANTREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANTWRITE"))
#ifdef ERROR_CANTWRITE
	    return ERROR_CANTWRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANT_ACCESS_DOMAIN_INFO"))
#ifdef ERROR_CANT_ACCESS_DOMAIN_INFO
	    return ERROR_CANT_ACCESS_DOMAIN_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANT_DISABLE_MANDATORY"))
#ifdef ERROR_CANT_DISABLE_MANDATORY
	    return ERROR_CANT_DISABLE_MANDATORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CANT_OPEN_ANONYMOUS"))
#ifdef ERROR_CANT_OPEN_ANONYMOUS
	    return ERROR_CANT_OPEN_ANONYMOUS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CAN_NOT_COMPLETE"))
#ifdef ERROR_CAN_NOT_COMPLETE
	    return ERROR_CAN_NOT_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CAN_NOT_DEL_LOCAL_WINS"))
#ifdef ERROR_CAN_NOT_DEL_LOCAL_WINS
	    return ERROR_CAN_NOT_DEL_LOCAL_WINS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CHILD_MUST_BE_VOLATILE"))
#ifdef ERROR_CHILD_MUST_BE_VOLATILE
	    return ERROR_CHILD_MUST_BE_VOLATILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CHILD_NOT_COMPLETE"))
#ifdef ERROR_CHILD_NOT_COMPLETE
	    return ERROR_CHILD_NOT_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CHILD_WINDOW_MENU"))
#ifdef ERROR_CHILD_WINDOW_MENU
	    return ERROR_CHILD_WINDOW_MENU;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CIRCULAR_DEPENDENCY"))
#ifdef ERROR_CIRCULAR_DEPENDENCY
	    return ERROR_CIRCULAR_DEPENDENCY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CLASS_ALREADY_EXISTS"))
#ifdef ERROR_CLASS_ALREADY_EXISTS
	    return ERROR_CLASS_ALREADY_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CLASS_DOES_NOT_EXIST"))
#ifdef ERROR_CLASS_DOES_NOT_EXIST
	    return ERROR_CLASS_DOES_NOT_EXIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CLASS_HAS_WINDOWS"))
#ifdef ERROR_CLASS_HAS_WINDOWS
	    return ERROR_CLASS_HAS_WINDOWS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CLIPBOARD_NOT_OPEN"))
#ifdef ERROR_CLIPBOARD_NOT_OPEN
	    return ERROR_CLIPBOARD_NOT_OPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CLIPPING_NOT_SUPPORTED"))
#ifdef ERROR_CLIPPING_NOT_SUPPORTED
	    return ERROR_CLIPPING_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_ABORTED"))
#ifdef ERROR_CONNECTION_ABORTED
	    return ERROR_CONNECTION_ABORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_ACTIVE"))
#ifdef ERROR_CONNECTION_ACTIVE
	    return ERROR_CONNECTION_ACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_COUNT_LIMIT"))
#ifdef ERROR_CONNECTION_COUNT_LIMIT
	    return ERROR_CONNECTION_COUNT_LIMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_INVALID"))
#ifdef ERROR_CONNECTION_INVALID
	    return ERROR_CONNECTION_INVALID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_REFUSED"))
#ifdef ERROR_CONNECTION_REFUSED
	    return ERROR_CONNECTION_REFUSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONNECTION_UNAVAIL"))
#ifdef ERROR_CONNECTION_UNAVAIL
	    return ERROR_CONNECTION_UNAVAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CONTROL_ID_NOT_FOUND"))
#ifdef ERROR_CONTROL_ID_NOT_FOUND
	    return ERROR_CONTROL_ID_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_COUNTER_TIMEOUT"))
#ifdef ERROR_COUNTER_TIMEOUT
	    return ERROR_COUNTER_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CRC"))
#ifdef ERROR_CRC
	    return ERROR_CRC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_CURRENT_DIRECTORY"))
#ifdef ERROR_CURRENT_DIRECTORY
	    return ERROR_CURRENT_DIRECTORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DATABASE_DOES_NOT_EXIST"))
#ifdef ERROR_DATABASE_DOES_NOT_EXIST
	    return ERROR_DATABASE_DOES_NOT_EXIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DC_NOT_FOUND"))
#ifdef ERROR_DC_NOT_FOUND
	    return ERROR_DC_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DEPENDENT_SERVICES_RUNNING"))
#ifdef ERROR_DEPENDENT_SERVICES_RUNNING
	    return ERROR_DEPENDENT_SERVICES_RUNNING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DESTROY_OBJECT_OF_OTHER_THREAD"))
#ifdef ERROR_DESTROY_OBJECT_OF_OTHER_THREAD
	    return ERROR_DESTROY_OBJECT_OF_OTHER_THREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DEVICE_ALREADY_REMEMBERED"))
#ifdef ERROR_DEVICE_ALREADY_REMEMBERED
	    return ERROR_DEVICE_ALREADY_REMEMBERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DEVICE_IN_USE"))
#ifdef ERROR_DEVICE_IN_USE
	    return ERROR_DEVICE_IN_USE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DEVICE_NOT_PARTITIONED"))
#ifdef ERROR_DEVICE_NOT_PARTITIONED
	    return ERROR_DEVICE_NOT_PARTITIONED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DEV_NOT_EXIST"))
#ifdef ERROR_DEV_NOT_EXIST
	    return ERROR_DEV_NOT_EXIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DIRECTORY"))
#ifdef ERROR_DIRECTORY
	    return ERROR_DIRECTORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DIRECT_ACCESS_HANDLE"))
#ifdef ERROR_DIRECT_ACCESS_HANDLE
	    return ERROR_DIRECT_ACCESS_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DIR_NOT_EMPTY"))
#ifdef ERROR_DIR_NOT_EMPTY
	    return ERROR_DIR_NOT_EMPTY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DIR_NOT_ROOT"))
#ifdef ERROR_DIR_NOT_ROOT
	    return ERROR_DIR_NOT_ROOT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISCARDED"))
#ifdef ERROR_DISCARDED
	    return ERROR_DISCARDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_CHANGE"))
#ifdef ERROR_DISK_CHANGE
	    return ERROR_DISK_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_CORRUPT"))
#ifdef ERROR_DISK_CORRUPT
	    return ERROR_DISK_CORRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_FULL"))
#ifdef ERROR_DISK_FULL
	    return ERROR_DISK_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_OPERATION_FAILED"))
#ifdef ERROR_DISK_OPERATION_FAILED
	    return ERROR_DISK_OPERATION_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_RECALIBRATE_FAILED"))
#ifdef ERROR_DISK_RECALIBRATE_FAILED
	    return ERROR_DISK_RECALIBRATE_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DISK_RESET_FAILED"))
#ifdef ERROR_DISK_RESET_FAILED
	    return ERROR_DISK_RESET_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DLL_INIT_FAILED"))
#ifdef ERROR_DLL_INIT_FAILED
	    return ERROR_DLL_INIT_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DOMAIN_CONTROLLER_NOT_FOUND"))
#ifdef ERROR_DOMAIN_CONTROLLER_NOT_FOUND
	    return ERROR_DOMAIN_CONTROLLER_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DOMAIN_EXISTS"))
#ifdef ERROR_DOMAIN_EXISTS
	    return ERROR_DOMAIN_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DOMAIN_LIMIT_EXCEEDED"))
#ifdef ERROR_DOMAIN_LIMIT_EXCEEDED
	    return ERROR_DOMAIN_LIMIT_EXCEEDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DOMAIN_TRUST_INCONSISTENT"))
#ifdef ERROR_DOMAIN_TRUST_INCONSISTENT
	    return ERROR_DOMAIN_TRUST_INCONSISTENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DRIVE_LOCKED"))
#ifdef ERROR_DRIVE_LOCKED
	    return ERROR_DRIVE_LOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DUPLICATE_SERVICE_NAME"))
#ifdef ERROR_DUPLICATE_SERVICE_NAME
	    return ERROR_DUPLICATE_SERVICE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DUP_DOMAINNAME"))
#ifdef ERROR_DUP_DOMAINNAME
	    return ERROR_DUP_DOMAINNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DUP_NAME"))
#ifdef ERROR_DUP_NAME
	    return ERROR_DUP_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_DYNLINK_FROM_INVALID_RING"))
#ifdef ERROR_DYNLINK_FROM_INVALID_RING
	    return ERROR_DYNLINK_FROM_INVALID_RING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EAS_DIDNT_FIT"))
#ifdef ERROR_EAS_DIDNT_FIT
	    return ERROR_EAS_DIDNT_FIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EAS_NOT_SUPPORTED"))
#ifdef ERROR_EAS_NOT_SUPPORTED
	    return ERROR_EAS_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EA_ACCESS_DENIED"))
#ifdef ERROR_EA_ACCESS_DENIED
	    return ERROR_EA_ACCESS_DENIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EA_FILE_CORRUPT"))
#ifdef ERROR_EA_FILE_CORRUPT
	    return ERROR_EA_FILE_CORRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EA_LIST_INCONSISTENT"))
#ifdef ERROR_EA_LIST_INCONSISTENT
	    return ERROR_EA_LIST_INCONSISTENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EA_TABLE_FULL"))
#ifdef ERROR_EA_TABLE_FULL
	    return ERROR_EA_TABLE_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_END_OF_MEDIA"))
#ifdef ERROR_END_OF_MEDIA
	    return ERROR_END_OF_MEDIA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ENVVAR_NOT_FOUND"))
#ifdef ERROR_ENVVAR_NOT_FOUND
	    return ERROR_ENVVAR_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EOM_OVERFLOW"))
#ifdef ERROR_EOM_OVERFLOW
	    return ERROR_EOM_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EVENTLOG_CANT_START"))
#ifdef ERROR_EVENTLOG_CANT_START
	    return ERROR_EVENTLOG_CANT_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EVENTLOG_FILE_CHANGED"))
#ifdef ERROR_EVENTLOG_FILE_CHANGED
	    return ERROR_EVENTLOG_FILE_CHANGED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EVENTLOG_FILE_CORRUPT"))
#ifdef ERROR_EVENTLOG_FILE_CORRUPT
	    return ERROR_EVENTLOG_FILE_CORRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EXCEPTION_IN_SERVICE"))
#ifdef ERROR_EXCEPTION_IN_SERVICE
	    return ERROR_EXCEPTION_IN_SERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EXCL_SEM_ALREADY_OWNED"))
#ifdef ERROR_EXCL_SEM_ALREADY_OWNED
	    return ERROR_EXCL_SEM_ALREADY_OWNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EXE_MARKED_INVALID"))
#ifdef ERROR_EXE_MARKED_INVALID
	    return ERROR_EXE_MARKED_INVALID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_EXTENDED_ERROR"))
#ifdef ERROR_EXTENDED_ERROR
	    return ERROR_EXTENDED_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FAILED_SERVICE_CONTROLLER_CONNECT"))
#ifdef ERROR_FAILED_SERVICE_CONTROLLER_CONNECT
	    return ERROR_FAILED_SERVICE_CONTROLLER_CONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FAIL_I24"))
#ifdef ERROR_FAIL_I24
	    return ERROR_FAIL_I24;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILEMARK_DETECTED"))
#ifdef ERROR_FILEMARK_DETECTED
	    return ERROR_FILEMARK_DETECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILENAME_EXCED_RANGE"))
#ifdef ERROR_FILENAME_EXCED_RANGE
	    return ERROR_FILENAME_EXCED_RANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILE_CORRUPT"))
#ifdef ERROR_FILE_CORRUPT
	    return ERROR_FILE_CORRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILE_EXISTS"))
#ifdef ERROR_FILE_EXISTS
	    return ERROR_FILE_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILE_INVALID"))
#ifdef ERROR_FILE_INVALID
	    return ERROR_FILE_INVALID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FILE_NOT_FOUND"))
#ifdef ERROR_FILE_NOT_FOUND
	    return ERROR_FILE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FLOPPY_BAD_REGISTERS"))
#ifdef ERROR_FLOPPY_BAD_REGISTERS
	    return ERROR_FLOPPY_BAD_REGISTERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FLOPPY_ID_MARK_NOT_FOUND"))
#ifdef ERROR_FLOPPY_ID_MARK_NOT_FOUND
	    return ERROR_FLOPPY_ID_MARK_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FLOPPY_UNKNOWN_ERROR"))
#ifdef ERROR_FLOPPY_UNKNOWN_ERROR
	    return ERROR_FLOPPY_UNKNOWN_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FLOPPY_WRONG_CYLINDER"))
#ifdef ERROR_FLOPPY_WRONG_CYLINDER
	    return ERROR_FLOPPY_WRONG_CYLINDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FULLSCREEN_MODE"))
#ifdef ERROR_FULLSCREEN_MODE
	    return ERROR_FULLSCREEN_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_FULL_BACKUP"))
#ifdef ERROR_FULL_BACKUP
	    return ERROR_FULL_BACKUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_GENERIC_NOT_MAPPED"))
#ifdef ERROR_GENERIC_NOT_MAPPED
	    return ERROR_GENERIC_NOT_MAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_GEN_FAILURE"))
#ifdef ERROR_GEN_FAILURE
	    return ERROR_GEN_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_GLOBAL_ONLY_HOOK"))
#ifdef ERROR_GLOBAL_ONLY_HOOK
	    return ERROR_GLOBAL_ONLY_HOOK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_GRACEFUL_DISCONNECT"))
#ifdef ERROR_GRACEFUL_DISCONNECT
	    return ERROR_GRACEFUL_DISCONNECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_GROUP_EXISTS"))
#ifdef ERROR_GROUP_EXISTS
	    return ERROR_GROUP_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HANDLE_DISK_FULL"))
#ifdef ERROR_HANDLE_DISK_FULL
	    return ERROR_HANDLE_DISK_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HANDLE_EOF"))
#ifdef ERROR_HANDLE_EOF
	    return ERROR_HANDLE_EOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HOOK_NEEDS_HMOD"))
#ifdef ERROR_HOOK_NEEDS_HMOD
	    return ERROR_HOOK_NEEDS_HMOD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HOOK_NOT_INSTALLED"))
#ifdef ERROR_HOOK_NOT_INSTALLED
	    return ERROR_HOOK_NOT_INSTALLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HOST_UNREACHABLE"))
#ifdef ERROR_HOST_UNREACHABLE
	    return ERROR_HOST_UNREACHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HOTKEY_ALREADY_REGISTERED"))
#ifdef ERROR_HOTKEY_ALREADY_REGISTERED
	    return ERROR_HOTKEY_ALREADY_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HOTKEY_NOT_REGISTERED"))
#ifdef ERROR_HOTKEY_NOT_REGISTERED
	    return ERROR_HOTKEY_NOT_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_HWNDS_HAVE_DIFF_PARENT"))
#ifdef ERROR_HWNDS_HAVE_DIFF_PARENT
	    return ERROR_HWNDS_HAVE_DIFF_PARENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ILL_FORMED_PASSWORD"))
#ifdef ERROR_ILL_FORMED_PASSWORD
	    return ERROR_ILL_FORMED_PASSWORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INCORRECT_ADDRESS"))
#ifdef ERROR_INCORRECT_ADDRESS
	    return ERROR_INCORRECT_ADDRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INC_BACKUP"))
#ifdef ERROR_INC_BACKUP
	    return ERROR_INC_BACKUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INFLOOP_IN_RELOC_CHAIN"))
#ifdef ERROR_INFLOOP_IN_RELOC_CHAIN
	    return ERROR_INFLOOP_IN_RELOC_CHAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INSUFFICIENT_BUFFER"))
#ifdef ERROR_INSUFFICIENT_BUFFER
	    return ERROR_INSUFFICIENT_BUFFER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INTERNAL_DB_CORRUPTION"))
#ifdef ERROR_INTERNAL_DB_CORRUPTION
	    return ERROR_INTERNAL_DB_CORRUPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INTERNAL_DB_ERROR"))
#ifdef ERROR_INTERNAL_DB_ERROR
	    return ERROR_INTERNAL_DB_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INTERNAL_ERROR"))
#ifdef ERROR_INTERNAL_ERROR
	    return ERROR_INTERNAL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ACCEL_HANDLE"))
#ifdef ERROR_INVALID_ACCEL_HANDLE
	    return ERROR_INVALID_ACCEL_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ACCESS"))
#ifdef ERROR_INVALID_ACCESS
	    return ERROR_INVALID_ACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ACCOUNT_NAME"))
#ifdef ERROR_INVALID_ACCOUNT_NAME
	    return ERROR_INVALID_ACCOUNT_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ACL"))
#ifdef ERROR_INVALID_ACL
	    return ERROR_INVALID_ACL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ADDRESS"))
#ifdef ERROR_INVALID_ADDRESS
	    return ERROR_INVALID_ADDRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_AT_INTERRUPT_TIME"))
#ifdef ERROR_INVALID_AT_INTERRUPT_TIME
	    return ERROR_INVALID_AT_INTERRUPT_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_BLOCK"))
#ifdef ERROR_INVALID_BLOCK
	    return ERROR_INVALID_BLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_BLOCK_LENGTH"))
#ifdef ERROR_INVALID_BLOCK_LENGTH
	    return ERROR_INVALID_BLOCK_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_CATEGORY"))
#ifdef ERROR_INVALID_CATEGORY
	    return ERROR_INVALID_CATEGORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_COMBOBOX_MESSAGE"))
#ifdef ERROR_INVALID_COMBOBOX_MESSAGE
	    return ERROR_INVALID_COMBOBOX_MESSAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_COMPUTERNAME"))
#ifdef ERROR_INVALID_COMPUTERNAME
	    return ERROR_INVALID_COMPUTERNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_CURSOR_HANDLE"))
#ifdef ERROR_INVALID_CURSOR_HANDLE
	    return ERROR_INVALID_CURSOR_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DATA"))
#ifdef ERROR_INVALID_DATA
	    return ERROR_INVALID_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DATATYPE"))
#ifdef ERROR_INVALID_DATATYPE
	    return ERROR_INVALID_DATATYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DOMAINNAME"))
#ifdef ERROR_INVALID_DOMAINNAME
	    return ERROR_INVALID_DOMAINNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DOMAIN_ROLE"))
#ifdef ERROR_INVALID_DOMAIN_ROLE
	    return ERROR_INVALID_DOMAIN_ROLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DOMAIN_STATE"))
#ifdef ERROR_INVALID_DOMAIN_STATE
	    return ERROR_INVALID_DOMAIN_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DRIVE"))
#ifdef ERROR_INVALID_DRIVE
	    return ERROR_INVALID_DRIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_DWP_HANDLE"))
#ifdef ERROR_INVALID_DWP_HANDLE
	    return ERROR_INVALID_DWP_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EA_HANDLE"))
#ifdef ERROR_INVALID_EA_HANDLE
	    return ERROR_INVALID_EA_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EA_NAME"))
#ifdef ERROR_INVALID_EA_NAME
	    return ERROR_INVALID_EA_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EDIT_HEIGHT"))
#ifdef ERROR_INVALID_EDIT_HEIGHT
	    return ERROR_INVALID_EDIT_HEIGHT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ENVIRONMENT"))
#ifdef ERROR_INVALID_ENVIRONMENT
	    return ERROR_INVALID_ENVIRONMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EVENTNAME"))
#ifdef ERROR_INVALID_EVENTNAME
	    return ERROR_INVALID_EVENTNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EVENT_COUNT"))
#ifdef ERROR_INVALID_EVENT_COUNT
	    return ERROR_INVALID_EVENT_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_EXE_SIGNATURE"))
#ifdef ERROR_INVALID_EXE_SIGNATURE
	    return ERROR_INVALID_EXE_SIGNATURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FILTER_PROC"))
#ifdef ERROR_INVALID_FILTER_PROC
	    return ERROR_INVALID_FILTER_PROC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FLAGS"))
#ifdef ERROR_INVALID_FLAGS
	    return ERROR_INVALID_FLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FLAG_NUMBER"))
#ifdef ERROR_INVALID_FLAG_NUMBER
	    return ERROR_INVALID_FLAG_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FORM_NAME"))
#ifdef ERROR_INVALID_FORM_NAME
	    return ERROR_INVALID_FORM_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FORM_SIZE"))
#ifdef ERROR_INVALID_FORM_SIZE
	    return ERROR_INVALID_FORM_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_FUNCTION"))
#ifdef ERROR_INVALID_FUNCTION
	    return ERROR_INVALID_FUNCTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_GROUPNAME"))
#ifdef ERROR_INVALID_GROUPNAME
	    return ERROR_INVALID_GROUPNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_GROUP_ATTRIBUTES"))
#ifdef ERROR_INVALID_GROUP_ATTRIBUTES
	    return ERROR_INVALID_GROUP_ATTRIBUTES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_GW_COMMAND"))
#ifdef ERROR_INVALID_GW_COMMAND
	    return ERROR_INVALID_GW_COMMAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_HANDLE"))
#ifdef ERROR_INVALID_HANDLE
	    return ERROR_INVALID_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_HOOK_FILTER"))
#ifdef ERROR_INVALID_HOOK_FILTER
	    return ERROR_INVALID_HOOK_FILTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_HOOK_HANDLE"))
#ifdef ERROR_INVALID_HOOK_HANDLE
	    return ERROR_INVALID_HOOK_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ICON_HANDLE"))
#ifdef ERROR_INVALID_ICON_HANDLE
	    return ERROR_INVALID_ICON_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ID_AUTHORITY"))
#ifdef ERROR_INVALID_ID_AUTHORITY
	    return ERROR_INVALID_ID_AUTHORITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_INDEX"))
#ifdef ERROR_INVALID_INDEX
	    return ERROR_INVALID_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_LB_MESSAGE"))
#ifdef ERROR_INVALID_LB_MESSAGE
	    return ERROR_INVALID_LB_MESSAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_LEVEL"))
#ifdef ERROR_INVALID_LEVEL
	    return ERROR_INVALID_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_LIST_FORMAT"))
#ifdef ERROR_INVALID_LIST_FORMAT
	    return ERROR_INVALID_LIST_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_LOGON_HOURS"))
#ifdef ERROR_INVALID_LOGON_HOURS
	    return ERROR_INVALID_LOGON_HOURS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_LOGON_TYPE"))
#ifdef ERROR_INVALID_LOGON_TYPE
	    return ERROR_INVALID_LOGON_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MEMBER"))
#ifdef ERROR_INVALID_MEMBER
	    return ERROR_INVALID_MEMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MENU_HANDLE"))
#ifdef ERROR_INVALID_MENU_HANDLE
	    return ERROR_INVALID_MENU_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MESSAGE"))
#ifdef ERROR_INVALID_MESSAGE
	    return ERROR_INVALID_MESSAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MESSAGEDEST"))
#ifdef ERROR_INVALID_MESSAGEDEST
	    return ERROR_INVALID_MESSAGEDEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MESSAGENAME"))
#ifdef ERROR_INVALID_MESSAGENAME
	    return ERROR_INVALID_MESSAGENAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MINALLOCSIZE"))
#ifdef ERROR_INVALID_MINALLOCSIZE
	    return ERROR_INVALID_MINALLOCSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MODULETYPE"))
#ifdef ERROR_INVALID_MODULETYPE
	    return ERROR_INVALID_MODULETYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_MSGBOX_STYLE"))
#ifdef ERROR_INVALID_MSGBOX_STYLE
	    return ERROR_INVALID_MSGBOX_STYLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_NAME"))
#ifdef ERROR_INVALID_NAME
	    return ERROR_INVALID_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_NETNAME"))
#ifdef ERROR_INVALID_NETNAME
	    return ERROR_INVALID_NETNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_ORDINAL"))
#ifdef ERROR_INVALID_ORDINAL
	    return ERROR_INVALID_ORDINAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_OWNER"))
#ifdef ERROR_INVALID_OWNER
	    return ERROR_INVALID_OWNER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PARAMETER"))
#ifdef ERROR_INVALID_PARAMETER
	    return ERROR_INVALID_PARAMETER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PASSWORD"))
#ifdef ERROR_INVALID_PASSWORD
	    return ERROR_INVALID_PASSWORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PASSWORDNAME"))
#ifdef ERROR_INVALID_PASSWORDNAME
	    return ERROR_INVALID_PASSWORDNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PIXEL_FORMAT"))
#ifdef ERROR_INVALID_PIXEL_FORMAT
	    return ERROR_INVALID_PIXEL_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PRIMARY_GROUP"))
#ifdef ERROR_INVALID_PRIMARY_GROUP
	    return ERROR_INVALID_PRIMARY_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PRINTER_COMMAND"))
#ifdef ERROR_INVALID_PRINTER_COMMAND
	    return ERROR_INVALID_PRINTER_COMMAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PRINTER_NAME"))
#ifdef ERROR_INVALID_PRINTER_NAME
	    return ERROR_INVALID_PRINTER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PRINTER_STATE"))
#ifdef ERROR_INVALID_PRINTER_STATE
	    return ERROR_INVALID_PRINTER_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_PRIORITY"))
#ifdef ERROR_INVALID_PRIORITY
	    return ERROR_INVALID_PRIORITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SCROLLBAR_RANGE"))
#ifdef ERROR_INVALID_SCROLLBAR_RANGE
	    return ERROR_INVALID_SCROLLBAR_RANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SECURITY_DESCR"))
#ifdef ERROR_INVALID_SECURITY_DESCR
	    return ERROR_INVALID_SECURITY_DESCR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SEGDPL"))
#ifdef ERROR_INVALID_SEGDPL
	    return ERROR_INVALID_SEGDPL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SEGMENT_NUMBER"))
#ifdef ERROR_INVALID_SEGMENT_NUMBER
	    return ERROR_INVALID_SEGMENT_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SEPARATOR_FILE"))
#ifdef ERROR_INVALID_SEPARATOR_FILE
	    return ERROR_INVALID_SEPARATOR_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SERVER_STATE"))
#ifdef ERROR_INVALID_SERVER_STATE
	    return ERROR_INVALID_SERVER_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SERVICENAME"))
#ifdef ERROR_INVALID_SERVICENAME
	    return ERROR_INVALID_SERVICENAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SERVICE_ACCOUNT"))
#ifdef ERROR_INVALID_SERVICE_ACCOUNT
	    return ERROR_INVALID_SERVICE_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SERVICE_CONTROL"))
#ifdef ERROR_INVALID_SERVICE_CONTROL
	    return ERROR_INVALID_SERVICE_CONTROL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SERVICE_LOCK"))
#ifdef ERROR_INVALID_SERVICE_LOCK
	    return ERROR_INVALID_SERVICE_LOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SHARENAME"))
#ifdef ERROR_INVALID_SHARENAME
	    return ERROR_INVALID_SHARENAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SHOWWIN_COMMAND"))
#ifdef ERROR_INVALID_SHOWWIN_COMMAND
	    return ERROR_INVALID_SHOWWIN_COMMAND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SID"))
#ifdef ERROR_INVALID_SID
	    return ERROR_INVALID_SID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SIGNAL_NUMBER"))
#ifdef ERROR_INVALID_SIGNAL_NUMBER
	    return ERROR_INVALID_SIGNAL_NUMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SPI_VALUE"))
#ifdef ERROR_INVALID_SPI_VALUE
	    return ERROR_INVALID_SPI_VALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_STACKSEG"))
#ifdef ERROR_INVALID_STACKSEG
	    return ERROR_INVALID_STACKSEG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_STARTING_CODESEG"))
#ifdef ERROR_INVALID_STARTING_CODESEG
	    return ERROR_INVALID_STARTING_CODESEG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_SUB_AUTHORITY"))
#ifdef ERROR_INVALID_SUB_AUTHORITY
	    return ERROR_INVALID_SUB_AUTHORITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_TARGET_HANDLE"))
#ifdef ERROR_INVALID_TARGET_HANDLE
	    return ERROR_INVALID_TARGET_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_THREAD_ID"))
#ifdef ERROR_INVALID_THREAD_ID
	    return ERROR_INVALID_THREAD_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_TIME"))
#ifdef ERROR_INVALID_TIME
	    return ERROR_INVALID_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_USER_BUFFER"))
#ifdef ERROR_INVALID_USER_BUFFER
	    return ERROR_INVALID_USER_BUFFER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_VERIFY_SWITCH"))
#ifdef ERROR_INVALID_VERIFY_SWITCH
	    return ERROR_INVALID_VERIFY_SWITCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_WINDOW_HANDLE"))
#ifdef ERROR_INVALID_WINDOW_HANDLE
	    return ERROR_INVALID_WINDOW_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_WINDOW_STYLE"))
#ifdef ERROR_INVALID_WINDOW_STYLE
	    return ERROR_INVALID_WINDOW_STYLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_INVALID_WORKSTATION"))
#ifdef ERROR_INVALID_WORKSTATION
	    return ERROR_INVALID_WORKSTATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IOPL_NOT_ENABLED"))
#ifdef ERROR_IOPL_NOT_ENABLED
	    return ERROR_IOPL_NOT_ENABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IO_DEVICE"))
#ifdef ERROR_IO_DEVICE
	    return ERROR_IO_DEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IO_INCOMPLETE"))
#ifdef ERROR_IO_INCOMPLETE
	    return ERROR_IO_INCOMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IO_PENDING"))
#ifdef ERROR_IO_PENDING
	    return ERROR_IO_PENDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IRQ_BUSY"))
#ifdef ERROR_IRQ_BUSY
	    return ERROR_IRQ_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_JOINED"))
#ifdef ERROR_IS_JOINED
	    return ERROR_IS_JOINED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_JOIN_PATH"))
#ifdef ERROR_IS_JOIN_PATH
	    return ERROR_IS_JOIN_PATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_JOIN_TARGET"))
#ifdef ERROR_IS_JOIN_TARGET
	    return ERROR_IS_JOIN_TARGET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_SUBSTED"))
#ifdef ERROR_IS_SUBSTED
	    return ERROR_IS_SUBSTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_SUBST_PATH"))
#ifdef ERROR_IS_SUBST_PATH
	    return ERROR_IS_SUBST_PATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_IS_SUBST_TARGET"))
#ifdef ERROR_IS_SUBST_TARGET
	    return ERROR_IS_SUBST_TARGET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_ITERATED_DATA_EXCEEDS_64k"))
#ifdef ERROR_ITERATED_DATA_EXCEEDS_64k
	    return ERROR_ITERATED_DATA_EXCEEDS_64k;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_JOIN_TO_JOIN"))
#ifdef ERROR_JOIN_TO_JOIN
	    return ERROR_JOIN_TO_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_JOIN_TO_SUBST"))
#ifdef ERROR_JOIN_TO_SUBST
	    return ERROR_JOIN_TO_SUBST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_JOURNAL_HOOK_SET"))
#ifdef ERROR_JOURNAL_HOOK_SET
	    return ERROR_JOURNAL_HOOK_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_KEY_DELETED"))
#ifdef ERROR_KEY_DELETED
	    return ERROR_KEY_DELETED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_KEY_HAS_CHILDREN"))
#ifdef ERROR_KEY_HAS_CHILDREN
	    return ERROR_KEY_HAS_CHILDREN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LABEL_TOO_LONG"))
#ifdef ERROR_LABEL_TOO_LONG
	    return ERROR_LABEL_TOO_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LAST_ADMIN"))
#ifdef ERROR_LAST_ADMIN
	    return ERROR_LAST_ADMIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LB_WITHOUT_TABSTOPS"))
#ifdef ERROR_LB_WITHOUT_TABSTOPS
	    return ERROR_LB_WITHOUT_TABSTOPS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LISTBOX_ID_NOT_FOUND"))
#ifdef ERROR_LISTBOX_ID_NOT_FOUND
	    return ERROR_LISTBOX_ID_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LM_CROSS_ENCRYPTION_REQUIRED"))
#ifdef ERROR_LM_CROSS_ENCRYPTION_REQUIRED
	    return ERROR_LM_CROSS_ENCRYPTION_REQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOCAL_USER_SESSION_KEY"))
#ifdef ERROR_LOCAL_USER_SESSION_KEY
	    return ERROR_LOCAL_USER_SESSION_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOCKED"))
#ifdef ERROR_LOCKED
	    return ERROR_LOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOCK_FAILED"))
#ifdef ERROR_LOCK_FAILED
	    return ERROR_LOCK_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOCK_VIOLATION"))
#ifdef ERROR_LOCK_VIOLATION
	    return ERROR_LOCK_VIOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGIN_TIME_RESTRICTION"))
#ifdef ERROR_LOGIN_TIME_RESTRICTION
	    return ERROR_LOGIN_TIME_RESTRICTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGIN_WKSTA_RESTRICTION"))
#ifdef ERROR_LOGIN_WKSTA_RESTRICTION
	    return ERROR_LOGIN_WKSTA_RESTRICTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGON_FAILURE"))
#ifdef ERROR_LOGON_FAILURE
	    return ERROR_LOGON_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGON_NOT_GRANTED"))
#ifdef ERROR_LOGON_NOT_GRANTED
	    return ERROR_LOGON_NOT_GRANTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGON_SESSION_COLLISION"))
#ifdef ERROR_LOGON_SESSION_COLLISION
	    return ERROR_LOGON_SESSION_COLLISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGON_SESSION_EXISTS"))
#ifdef ERROR_LOGON_SESSION_EXISTS
	    return ERROR_LOGON_SESSION_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOGON_TYPE_NOT_GRANTED"))
#ifdef ERROR_LOGON_TYPE_NOT_GRANTED
	    return ERROR_LOGON_TYPE_NOT_GRANTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LOG_FILE_FULL"))
#ifdef ERROR_LOG_FILE_FULL
	    return ERROR_LOG_FILE_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_LUIDS_EXHAUSTED"))
#ifdef ERROR_LUIDS_EXHAUSTED
	    return ERROR_LUIDS_EXHAUSTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MAPPED_ALIGNMENT"))
#ifdef ERROR_MAPPED_ALIGNMENT
	    return ERROR_MAPPED_ALIGNMENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MAX_THRDS_REACHED"))
#ifdef ERROR_MAX_THRDS_REACHED
	    return ERROR_MAX_THRDS_REACHED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEDIA_CHANGED"))
#ifdef ERROR_MEDIA_CHANGED
	    return ERROR_MEDIA_CHANGED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEMBERS_PRIMARY_GROUP"))
#ifdef ERROR_MEMBERS_PRIMARY_GROUP
	    return ERROR_MEMBERS_PRIMARY_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEMBER_IN_ALIAS"))
#ifdef ERROR_MEMBER_IN_ALIAS
	    return ERROR_MEMBER_IN_ALIAS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEMBER_IN_GROUP"))
#ifdef ERROR_MEMBER_IN_GROUP
	    return ERROR_MEMBER_IN_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEMBER_NOT_IN_ALIAS"))
#ifdef ERROR_MEMBER_NOT_IN_ALIAS
	    return ERROR_MEMBER_NOT_IN_ALIAS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MEMBER_NOT_IN_GROUP"))
#ifdef ERROR_MEMBER_NOT_IN_GROUP
	    return ERROR_MEMBER_NOT_IN_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_METAFILE_NOT_SUPPORTED"))
#ifdef ERROR_METAFILE_NOT_SUPPORTED
	    return ERROR_METAFILE_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_META_EXPANSION_TOO_LONG"))
#ifdef ERROR_META_EXPANSION_TOO_LONG
	    return ERROR_META_EXPANSION_TOO_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MOD_NOT_FOUND"))
#ifdef ERROR_MOD_NOT_FOUND
	    return ERROR_MOD_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MORE_DATA"))
#ifdef ERROR_MORE_DATA
	    return ERROR_MORE_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MORE_WRITES"))
#ifdef ERROR_MORE_WRITES
	    return ERROR_MORE_WRITES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_MR_MID_NOT_FOUND"))
#ifdef ERROR_MR_MID_NOT_FOUND
	    return ERROR_MR_MID_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NEGATIVE_SEEK"))
#ifdef ERROR_NEGATIVE_SEEK
	    return ERROR_NEGATIVE_SEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NESTING_NOT_ALLOWED"))
#ifdef ERROR_NESTING_NOT_ALLOWED
	    return ERROR_NESTING_NOT_ALLOWED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NETLOGON_NOT_STARTED"))
#ifdef ERROR_NETLOGON_NOT_STARTED
	    return ERROR_NETLOGON_NOT_STARTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NETNAME_DELETED"))
#ifdef ERROR_NETNAME_DELETED
	    return ERROR_NETNAME_DELETED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NETWORK_ACCESS_DENIED"))
#ifdef ERROR_NETWORK_ACCESS_DENIED
	    return ERROR_NETWORK_ACCESS_DENIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NETWORK_BUSY"))
#ifdef ERROR_NETWORK_BUSY
	    return ERROR_NETWORK_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NETWORK_UNREACHABLE"))
#ifdef ERROR_NETWORK_UNREACHABLE
	    return ERROR_NETWORK_UNREACHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NET_WRITE_FAULT"))
#ifdef ERROR_NET_WRITE_FAULT
	    return ERROR_NET_WRITE_FAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOACCESS"))
#ifdef ERROR_NOACCESS
	    return ERROR_NOACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT"))
#ifdef ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT
	    return ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOLOGON_SERVER_TRUST_ACCOUNT"))
#ifdef ERROR_NOLOGON_SERVER_TRUST_ACCOUNT
	    return ERROR_NOLOGON_SERVER_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT"))
#ifdef ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT
	    return ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NONE_MAPPED"))
#ifdef ERROR_NONE_MAPPED
	    return ERROR_NONE_MAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NON_MDICHILD_WINDOW"))
#ifdef ERROR_NON_MDICHILD_WINDOW
	    return ERROR_NON_MDICHILD_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOTIFY_ENUM_DIR"))
#ifdef ERROR_NOTIFY_ENUM_DIR
	    return ERROR_NOTIFY_ENUM_DIR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_ALL_ASSIGNED"))
#ifdef ERROR_NOT_ALL_ASSIGNED
	    return ERROR_NOT_ALL_ASSIGNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_CHILD_WINDOW"))
#ifdef ERROR_NOT_CHILD_WINDOW
	    return ERROR_NOT_CHILD_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_CONNECTED"))
#ifdef ERROR_NOT_CONNECTED
	    return ERROR_NOT_CONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_CONTAINER"))
#ifdef ERROR_NOT_CONTAINER
	    return ERROR_NOT_CONTAINER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_DOS_DISK"))
#ifdef ERROR_NOT_DOS_DISK
	    return ERROR_NOT_DOS_DISK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_ENOUGH_MEMORY"))
#ifdef ERROR_NOT_ENOUGH_MEMORY
	    return ERROR_NOT_ENOUGH_MEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_ENOUGH_QUOTA"))
#ifdef ERROR_NOT_ENOUGH_QUOTA
	    return ERROR_NOT_ENOUGH_QUOTA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_ENOUGH_SERVER_MEMORY"))
#ifdef ERROR_NOT_ENOUGH_SERVER_MEMORY
	    return ERROR_NOT_ENOUGH_SERVER_MEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_JOINED"))
#ifdef ERROR_NOT_JOINED
	    return ERROR_NOT_JOINED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_LOCKED"))
#ifdef ERROR_NOT_LOCKED
	    return ERROR_NOT_LOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_LOGON_PROCESS"))
#ifdef ERROR_NOT_LOGON_PROCESS
	    return ERROR_NOT_LOGON_PROCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_OWNER"))
#ifdef ERROR_NOT_OWNER
	    return ERROR_NOT_OWNER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_READY"))
#ifdef ERROR_NOT_READY
	    return ERROR_NOT_READY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_REGISTRY_FILE"))
#ifdef ERROR_NOT_REGISTRY_FILE
	    return ERROR_NOT_REGISTRY_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_SAME_DEVICE"))
#ifdef ERROR_NOT_SAME_DEVICE
	    return ERROR_NOT_SAME_DEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_SUBSTED"))
#ifdef ERROR_NOT_SUBSTED
	    return ERROR_NOT_SUBSTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NOT_SUPPORTED"))
#ifdef ERROR_NOT_SUPPORTED
	    return ERROR_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_BROWSER_SERVERS_FOUND"))
#ifdef ERROR_NO_BROWSER_SERVERS_FOUND
	    return ERROR_NO_BROWSER_SERVERS_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_DATA"))
#ifdef ERROR_NO_DATA
	    return ERROR_NO_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_DATA_DETECTED"))
#ifdef ERROR_NO_DATA_DETECTED
	    return ERROR_NO_DATA_DETECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_IMPERSONATION_TOKEN"))
#ifdef ERROR_NO_IMPERSONATION_TOKEN
	    return ERROR_NO_IMPERSONATION_TOKEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_INHERITANCE"))
#ifdef ERROR_NO_INHERITANCE
	    return ERROR_NO_INHERITANCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_LOGON_SERVERS"))
#ifdef ERROR_NO_LOGON_SERVERS
	    return ERROR_NO_LOGON_SERVERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_LOG_SPACE"))
#ifdef ERROR_NO_LOG_SPACE
	    return ERROR_NO_LOG_SPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_MEDIA_IN_DRIVE"))
#ifdef ERROR_NO_MEDIA_IN_DRIVE
	    return ERROR_NO_MEDIA_IN_DRIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_MORE_FILES"))
#ifdef ERROR_NO_MORE_FILES
	    return ERROR_NO_MORE_FILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_MORE_ITEMS"))
#ifdef ERROR_NO_MORE_ITEMS
	    return ERROR_NO_MORE_ITEMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_MORE_SEARCH_HANDLES"))
#ifdef ERROR_NO_MORE_SEARCH_HANDLES
	    return ERROR_NO_MORE_SEARCH_HANDLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_NETWORK"))
#ifdef ERROR_NO_NETWORK
	    return ERROR_NO_NETWORK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_NET_OR_BAD_PATH"))
#ifdef ERROR_NO_NET_OR_BAD_PATH
	    return ERROR_NO_NET_OR_BAD_PATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_PROC_SLOTS"))
#ifdef ERROR_NO_PROC_SLOTS
	    return ERROR_NO_PROC_SLOTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_QUOTAS_FOR_ACCOUNT"))
#ifdef ERROR_NO_QUOTAS_FOR_ACCOUNT
	    return ERROR_NO_QUOTAS_FOR_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SCROLLBARS"))
#ifdef ERROR_NO_SCROLLBARS
	    return ERROR_NO_SCROLLBARS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SECURITY_ON_OBJECT"))
#ifdef ERROR_NO_SECURITY_ON_OBJECT
	    return ERROR_NO_SECURITY_ON_OBJECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SHUTDOWN_IN_PROGRESS"))
#ifdef ERROR_NO_SHUTDOWN_IN_PROGRESS
	    return ERROR_NO_SHUTDOWN_IN_PROGRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SIGNAL_SENT"))
#ifdef ERROR_NO_SIGNAL_SENT
	    return ERROR_NO_SIGNAL_SENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SPOOL_SPACE"))
#ifdef ERROR_NO_SPOOL_SPACE
	    return ERROR_NO_SPOOL_SPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_ALIAS"))
#ifdef ERROR_NO_SUCH_ALIAS
	    return ERROR_NO_SUCH_ALIAS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_DOMAIN"))
#ifdef ERROR_NO_SUCH_DOMAIN
	    return ERROR_NO_SUCH_DOMAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_GROUP"))
#ifdef ERROR_NO_SUCH_GROUP
	    return ERROR_NO_SUCH_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_LOGON_SESSION"))
#ifdef ERROR_NO_SUCH_LOGON_SESSION
	    return ERROR_NO_SUCH_LOGON_SESSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_MEMBER"))
#ifdef ERROR_NO_SUCH_MEMBER
	    return ERROR_NO_SUCH_MEMBER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_PACKAGE"))
#ifdef ERROR_NO_SUCH_PACKAGE
	    return ERROR_NO_SUCH_PACKAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_PRIVILEGE"))
#ifdef ERROR_NO_SUCH_PRIVILEGE
	    return ERROR_NO_SUCH_PRIVILEGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SUCH_USER"))
#ifdef ERROR_NO_SUCH_USER
	    return ERROR_NO_SUCH_USER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_SYSTEM_MENU"))
#ifdef ERROR_NO_SYSTEM_MENU
	    return ERROR_NO_SYSTEM_MENU;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_TOKEN"))
#ifdef ERROR_NO_TOKEN
	    return ERROR_NO_TOKEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_TRUST_LSA_SECRET"))
#ifdef ERROR_NO_TRUST_LSA_SECRET
	    return ERROR_NO_TRUST_LSA_SECRET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_TRUST_SAM_ACCOUNT"))
#ifdef ERROR_NO_TRUST_SAM_ACCOUNT
	    return ERROR_NO_TRUST_SAM_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_UNICODE_TRANSLATION"))
#ifdef ERROR_NO_UNICODE_TRANSLATION
	    return ERROR_NO_UNICODE_TRANSLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_USER_SESSION_KEY"))
#ifdef ERROR_NO_USER_SESSION_KEY
	    return ERROR_NO_USER_SESSION_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_VOLUME_LABEL"))
#ifdef ERROR_NO_VOLUME_LABEL
	    return ERROR_NO_VOLUME_LABEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NO_WILDCARD_CHARACTERS"))
#ifdef ERROR_NO_WILDCARD_CHARACTERS
	    return ERROR_NO_WILDCARD_CHARACTERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NT_CROSS_ENCRYPTION_REQUIRED"))
#ifdef ERROR_NT_CROSS_ENCRYPTION_REQUIRED
	    return ERROR_NT_CROSS_ENCRYPTION_REQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_NULL_LM_PASSWORD"))
#ifdef ERROR_NULL_LM_PASSWORD
	    return ERROR_NULL_LM_PASSWORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OPEN_FAILED"))
#ifdef ERROR_OPEN_FAILED
	    return ERROR_OPEN_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OPEN_FILES"))
#ifdef ERROR_OPEN_FILES
	    return ERROR_OPEN_FILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OPERATION_ABORTED"))
#ifdef ERROR_OPERATION_ABORTED
	    return ERROR_OPERATION_ABORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OUTOFMEMORY"))
#ifdef ERROR_OUTOFMEMORY
	    return ERROR_OUTOFMEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OUT_OF_PAPER"))
#ifdef ERROR_OUT_OF_PAPER
	    return ERROR_OUT_OF_PAPER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_OUT_OF_STRUCTURES"))
#ifdef ERROR_OUT_OF_STRUCTURES
	    return ERROR_OUT_OF_STRUCTURES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PARTIAL_COPY"))
#ifdef ERROR_PARTIAL_COPY
	    return ERROR_PARTIAL_COPY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PARTITION_FAILURE"))
#ifdef ERROR_PARTITION_FAILURE
	    return ERROR_PARTITION_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PASSWORD_EXPIRED"))
#ifdef ERROR_PASSWORD_EXPIRED
	    return ERROR_PASSWORD_EXPIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PASSWORD_MUST_CHANGE"))
#ifdef ERROR_PASSWORD_MUST_CHANGE
	    return ERROR_PASSWORD_MUST_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PASSWORD_RESTRICTION"))
#ifdef ERROR_PASSWORD_RESTRICTION
	    return ERROR_PASSWORD_RESTRICTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PATH_BUSY"))
#ifdef ERROR_PATH_BUSY
	    return ERROR_PATH_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PATH_NOT_FOUND"))
#ifdef ERROR_PATH_NOT_FOUND
	    return ERROR_PATH_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PIPE_BUSY"))
#ifdef ERROR_PIPE_BUSY
	    return ERROR_PIPE_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PIPE_CONNECTED"))
#ifdef ERROR_PIPE_CONNECTED
	    return ERROR_PIPE_CONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PIPE_LISTENING"))
#ifdef ERROR_PIPE_LISTENING
	    return ERROR_PIPE_LISTENING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PIPE_NOT_CONNECTED"))
#ifdef ERROR_PIPE_NOT_CONNECTED
	    return ERROR_PIPE_NOT_CONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_POPUP_ALREADY_ACTIVE"))
#ifdef ERROR_POPUP_ALREADY_ACTIVE
	    return ERROR_POPUP_ALREADY_ACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PORT_UNREACHABLE"))
#ifdef ERROR_PORT_UNREACHABLE
	    return ERROR_PORT_UNREACHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_POSSIBLE_DEADLOCK"))
#ifdef ERROR_POSSIBLE_DEADLOCK
	    return ERROR_POSSIBLE_DEADLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINTER_ALREADY_EXISTS"))
#ifdef ERROR_PRINTER_ALREADY_EXISTS
	    return ERROR_PRINTER_ALREADY_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINTER_DELETED"))
#ifdef ERROR_PRINTER_DELETED
	    return ERROR_PRINTER_DELETED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINTER_DRIVER_ALREADY_INSTALLED"))
#ifdef ERROR_PRINTER_DRIVER_ALREADY_INSTALLED
	    return ERROR_PRINTER_DRIVER_ALREADY_INSTALLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINTER_DRIVER_IN_USE"))
#ifdef ERROR_PRINTER_DRIVER_IN_USE
	    return ERROR_PRINTER_DRIVER_IN_USE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINTQ_FULL"))
#ifdef ERROR_PRINTQ_FULL
	    return ERROR_PRINTQ_FULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINT_CANCELLED"))
#ifdef ERROR_PRINT_CANCELLED
	    return ERROR_PRINT_CANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINT_MONITOR_ALREADY_INSTALLED"))
#ifdef ERROR_PRINT_MONITOR_ALREADY_INSTALLED
	    return ERROR_PRINT_MONITOR_ALREADY_INSTALLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRINT_PROCESSOR_ALREADY_INSTALLED"))
#ifdef ERROR_PRINT_PROCESSOR_ALREADY_INSTALLED
	    return ERROR_PRINT_PROCESSOR_ALREADY_INSTALLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRIVATE_DIALOG_INDEX"))
#ifdef ERROR_PRIVATE_DIALOG_INDEX
	    return ERROR_PRIVATE_DIALOG_INDEX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PRIVILEGE_NOT_HELD"))
#ifdef ERROR_PRIVILEGE_NOT_HELD
	    return ERROR_PRIVILEGE_NOT_HELD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PROCESS_ABORTED"))
#ifdef ERROR_PROCESS_ABORTED
	    return ERROR_PROCESS_ABORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PROC_NOT_FOUND"))
#ifdef ERROR_PROC_NOT_FOUND
	    return ERROR_PROC_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_PROTOCOL_UNREACHABLE"))
#ifdef ERROR_PROTOCOL_UNREACHABLE
	    return ERROR_PROTOCOL_UNREACHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_READ_FAULT"))
#ifdef ERROR_READ_FAULT
	    return ERROR_READ_FAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REC_NON_EXISTENT"))
#ifdef ERROR_REC_NON_EXISTENT
	    return ERROR_REC_NON_EXISTENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REDIRECTOR_HAS_OPEN_HANDLES"))
#ifdef ERROR_REDIRECTOR_HAS_OPEN_HANDLES
	    return ERROR_REDIRECTOR_HAS_OPEN_HANDLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REDIR_PAUSED"))
#ifdef ERROR_REDIR_PAUSED
	    return ERROR_REDIR_PAUSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REGISTRY_CORRUPT"))
#ifdef ERROR_REGISTRY_CORRUPT
	    return ERROR_REGISTRY_CORRUPT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REGISTRY_IO_FAILED"))
#ifdef ERROR_REGISTRY_IO_FAILED
	    return ERROR_REGISTRY_IO_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REGISTRY_RECOVERED"))
#ifdef ERROR_REGISTRY_RECOVERED
	    return ERROR_REGISTRY_RECOVERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RELOC_CHAIN_XEEDS_SEGLIM"))
#ifdef ERROR_RELOC_CHAIN_XEEDS_SEGLIM
	    return ERROR_RELOC_CHAIN_XEEDS_SEGLIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REMOTE_SESSION_LIMIT_EXCEEDED"))
#ifdef ERROR_REMOTE_SESSION_LIMIT_EXCEEDED
	    return ERROR_REMOTE_SESSION_LIMIT_EXCEEDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REM_NOT_LIST"))
#ifdef ERROR_REM_NOT_LIST
	    return ERROR_REM_NOT_LIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REQUEST_ABORTED"))
#ifdef ERROR_REQUEST_ABORTED
	    return ERROR_REQUEST_ABORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REQ_NOT_ACCEP"))
#ifdef ERROR_REQ_NOT_ACCEP
	    return ERROR_REQ_NOT_ACCEP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RESOURCE_DATA_NOT_FOUND"))
#ifdef ERROR_RESOURCE_DATA_NOT_FOUND
	    return ERROR_RESOURCE_DATA_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RESOURCE_LANG_NOT_FOUND"))
#ifdef ERROR_RESOURCE_LANG_NOT_FOUND
	    return ERROR_RESOURCE_LANG_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RESOURCE_NAME_NOT_FOUND"))
#ifdef ERROR_RESOURCE_NAME_NOT_FOUND
	    return ERROR_RESOURCE_NAME_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RESOURCE_TYPE_NOT_FOUND"))
#ifdef ERROR_RESOURCE_TYPE_NOT_FOUND
	    return ERROR_RESOURCE_TYPE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RETRY"))
#ifdef ERROR_RETRY
	    return ERROR_RETRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_REVISION_MISMATCH"))
#ifdef ERROR_REVISION_MISMATCH
	    return ERROR_REVISION_MISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RING2SEG_MUST_BE_MOVABLE"))
#ifdef ERROR_RING2SEG_MUST_BE_MOVABLE
	    return ERROR_RING2SEG_MUST_BE_MOVABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RING2_STACK_IN_USE"))
#ifdef ERROR_RING2_STACK_IN_USE
	    return ERROR_RING2_STACK_IN_USE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RPL_NOT_ALLOWED"))
#ifdef ERROR_RPL_NOT_ALLOWED
	    return ERROR_RPL_NOT_ALLOWED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RXACT_COMMIT_FAILURE"))
#ifdef ERROR_RXACT_COMMIT_FAILURE
	    return ERROR_RXACT_COMMIT_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_RXACT_INVALID_STATE"))
#ifdef ERROR_RXACT_INVALID_STATE
	    return ERROR_RXACT_INVALID_STATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SAME_DRIVE"))
#ifdef ERROR_SAME_DRIVE
	    return ERROR_SAME_DRIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SCREEN_ALREADY_LOCKED"))
#ifdef ERROR_SCREEN_ALREADY_LOCKED
	    return ERROR_SCREEN_ALREADY_LOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SECRET_TOO_LONG"))
#ifdef ERROR_SECRET_TOO_LONG
	    return ERROR_SECRET_TOO_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SECTOR_NOT_FOUND"))
#ifdef ERROR_SECTOR_NOT_FOUND
	    return ERROR_SECTOR_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEEK"))
#ifdef ERROR_SEEK
	    return ERROR_SEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEEK_ON_DEVICE"))
#ifdef ERROR_SEEK_ON_DEVICE
	    return ERROR_SEEK_ON_DEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEM_IS_SET"))
#ifdef ERROR_SEM_IS_SET
	    return ERROR_SEM_IS_SET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEM_NOT_FOUND"))
#ifdef ERROR_SEM_NOT_FOUND
	    return ERROR_SEM_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEM_OWNER_DIED"))
#ifdef ERROR_SEM_OWNER_DIED
	    return ERROR_SEM_OWNER_DIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEM_TIMEOUT"))
#ifdef ERROR_SEM_TIMEOUT
	    return ERROR_SEM_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SEM_USER_LIMIT"))
#ifdef ERROR_SEM_USER_LIMIT
	    return ERROR_SEM_USER_LIMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERIAL_NO_DEVICE"))
#ifdef ERROR_SERIAL_NO_DEVICE
	    return ERROR_SERIAL_NO_DEVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVER_DISABLED"))
#ifdef ERROR_SERVER_DISABLED
	    return ERROR_SERVER_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVER_HAS_OPEN_HANDLES"))
#ifdef ERROR_SERVER_HAS_OPEN_HANDLES
	    return ERROR_SERVER_HAS_OPEN_HANDLES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVER_NOT_DISABLED"))
#ifdef ERROR_SERVER_NOT_DISABLED
	    return ERROR_SERVER_NOT_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_ALREADY_RUNNING"))
#ifdef ERROR_SERVICE_ALREADY_RUNNING
	    return ERROR_SERVICE_ALREADY_RUNNING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_CANNOT_ACCEPT_CTRL"))
#ifdef ERROR_SERVICE_CANNOT_ACCEPT_CTRL
	    return ERROR_SERVICE_CANNOT_ACCEPT_CTRL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_DATABASE_LOCKED"))
#ifdef ERROR_SERVICE_DATABASE_LOCKED
	    return ERROR_SERVICE_DATABASE_LOCKED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_DEPENDENCY_DELETED"))
#ifdef ERROR_SERVICE_DEPENDENCY_DELETED
	    return ERROR_SERVICE_DEPENDENCY_DELETED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_DEPENDENCY_FAIL"))
#ifdef ERROR_SERVICE_DEPENDENCY_FAIL
	    return ERROR_SERVICE_DEPENDENCY_FAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_DISABLED"))
#ifdef ERROR_SERVICE_DISABLED
	    return ERROR_SERVICE_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_DOES_NOT_EXIST"))
#ifdef ERROR_SERVICE_DOES_NOT_EXIST
	    return ERROR_SERVICE_DOES_NOT_EXIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_EXISTS"))
#ifdef ERROR_SERVICE_EXISTS
	    return ERROR_SERVICE_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_LOGON_FAILED"))
#ifdef ERROR_SERVICE_LOGON_FAILED
	    return ERROR_SERVICE_LOGON_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_MARKED_FOR_DELETE"))
#ifdef ERROR_SERVICE_MARKED_FOR_DELETE
	    return ERROR_SERVICE_MARKED_FOR_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_NEVER_STARTED"))
#ifdef ERROR_SERVICE_NEVER_STARTED
	    return ERROR_SERVICE_NEVER_STARTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_NOT_ACTIVE"))
#ifdef ERROR_SERVICE_NOT_ACTIVE
	    return ERROR_SERVICE_NOT_ACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_NOT_FOUND"))
#ifdef ERROR_SERVICE_NOT_FOUND
	    return ERROR_SERVICE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_NO_THREAD"))
#ifdef ERROR_SERVICE_NO_THREAD
	    return ERROR_SERVICE_NO_THREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_REQUEST_TIMEOUT"))
#ifdef ERROR_SERVICE_REQUEST_TIMEOUT
	    return ERROR_SERVICE_REQUEST_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_SPECIFIC_ERROR"))
#ifdef ERROR_SERVICE_SPECIFIC_ERROR
	    return ERROR_SERVICE_SPECIFIC_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SERVICE_START_HANG"))
#ifdef ERROR_SERVICE_START_HANG
	    return ERROR_SERVICE_START_HANG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SESSION_CREDENTIAL_CONFLICT"))
#ifdef ERROR_SESSION_CREDENTIAL_CONFLICT
	    return ERROR_SESSION_CREDENTIAL_CONFLICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SETCOUNT_ON_BAD_LB"))
#ifdef ERROR_SETCOUNT_ON_BAD_LB
	    return ERROR_SETCOUNT_ON_BAD_LB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SETMARK_DETECTED"))
#ifdef ERROR_SETMARK_DETECTED
	    return ERROR_SETMARK_DETECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SHARING_BUFFER_EXCEEDED"))
#ifdef ERROR_SHARING_BUFFER_EXCEEDED
	    return ERROR_SHARING_BUFFER_EXCEEDED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SHARING_PAUSED"))
#ifdef ERROR_SHARING_PAUSED
	    return ERROR_SHARING_PAUSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SHARING_VIOLATION"))
#ifdef ERROR_SHARING_VIOLATION
	    return ERROR_SHARING_VIOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SHUTDOWN_IN_PROGRESS"))
#ifdef ERROR_SHUTDOWN_IN_PROGRESS
	    return ERROR_SHUTDOWN_IN_PROGRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SIGNAL_PENDING"))
#ifdef ERROR_SIGNAL_PENDING
	    return ERROR_SIGNAL_PENDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SIGNAL_REFUSED"))
#ifdef ERROR_SIGNAL_REFUSED
	    return ERROR_SIGNAL_REFUSED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SOME_NOT_MAPPED"))
#ifdef ERROR_SOME_NOT_MAPPED
	    return ERROR_SOME_NOT_MAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPECIAL_ACCOUNT"))
#ifdef ERROR_SPECIAL_ACCOUNT
	    return ERROR_SPECIAL_ACCOUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPECIAL_GROUP"))
#ifdef ERROR_SPECIAL_GROUP
	    return ERROR_SPECIAL_GROUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPECIAL_USER"))
#ifdef ERROR_SPECIAL_USER
	    return ERROR_SPECIAL_USER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPL_NO_ADDJOB"))
#ifdef ERROR_SPL_NO_ADDJOB
	    return ERROR_SPL_NO_ADDJOB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPL_NO_STARTDOC"))
#ifdef ERROR_SPL_NO_STARTDOC
	    return ERROR_SPL_NO_STARTDOC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SPOOL_FILE_NOT_FOUND"))
#ifdef ERROR_SPOOL_FILE_NOT_FOUND
	    return ERROR_SPOOL_FILE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_STACK_OVERFLOW"))
#ifdef ERROR_STACK_OVERFLOW
	    return ERROR_STACK_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_STATIC_INIT"))
#ifdef ERROR_STATIC_INIT
	    return ERROR_STATIC_INIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SUBST_TO_JOIN"))
#ifdef ERROR_SUBST_TO_JOIN
	    return ERROR_SUBST_TO_JOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SUBST_TO_SUBST"))
#ifdef ERROR_SUBST_TO_SUBST
	    return ERROR_SUBST_TO_SUBST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SUCCESS"))
#ifdef ERROR_SUCCESS
	    return ERROR_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SWAPERROR"))
#ifdef ERROR_SWAPERROR
	    return ERROR_SWAPERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_SYSTEM_TRACE"))
#ifdef ERROR_SYSTEM_TRACE
	    return ERROR_SYSTEM_TRACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_THREAD_1_INACTIVE"))
#ifdef ERROR_THREAD_1_INACTIVE
	    return ERROR_THREAD_1_INACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TLW_WITH_WSCHILD"))
#ifdef ERROR_TLW_WITH_WSCHILD
	    return ERROR_TLW_WITH_WSCHILD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOKEN_ALREADY_IN_USE"))
#ifdef ERROR_TOKEN_ALREADY_IN_USE
	    return ERROR_TOKEN_ALREADY_IN_USE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_CMDS"))
#ifdef ERROR_TOO_MANY_CMDS
	    return ERROR_TOO_MANY_CMDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_CONTEXT_IDS"))
#ifdef ERROR_TOO_MANY_CONTEXT_IDS
	    return ERROR_TOO_MANY_CONTEXT_IDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_LUIDS_REQUESTED"))
#ifdef ERROR_TOO_MANY_LUIDS_REQUESTED
	    return ERROR_TOO_MANY_LUIDS_REQUESTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_MODULES"))
#ifdef ERROR_TOO_MANY_MODULES
	    return ERROR_TOO_MANY_MODULES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_MUXWAITERS"))
#ifdef ERROR_TOO_MANY_MUXWAITERS
	    return ERROR_TOO_MANY_MUXWAITERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_NAMES"))
#ifdef ERROR_TOO_MANY_NAMES
	    return ERROR_TOO_MANY_NAMES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_OPEN_FILES"))
#ifdef ERROR_TOO_MANY_OPEN_FILES
	    return ERROR_TOO_MANY_OPEN_FILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_POSTS"))
#ifdef ERROR_TOO_MANY_POSTS
	    return ERROR_TOO_MANY_POSTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_SECRETS"))
#ifdef ERROR_TOO_MANY_SECRETS
	    return ERROR_TOO_MANY_SECRETS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_SEMAPHORES"))
#ifdef ERROR_TOO_MANY_SEMAPHORES
	    return ERROR_TOO_MANY_SEMAPHORES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_SEM_REQUESTS"))
#ifdef ERROR_TOO_MANY_SEM_REQUESTS
	    return ERROR_TOO_MANY_SEM_REQUESTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_SESS"))
#ifdef ERROR_TOO_MANY_SESS
	    return ERROR_TOO_MANY_SESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_SIDS"))
#ifdef ERROR_TOO_MANY_SIDS
	    return ERROR_TOO_MANY_SIDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TOO_MANY_TCBS"))
#ifdef ERROR_TOO_MANY_TCBS
	    return ERROR_TOO_MANY_TCBS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TRANSFORM_NOT_SUPPORTED"))
#ifdef ERROR_TRANSFORM_NOT_SUPPORTED
	    return ERROR_TRANSFORM_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TRUSTED_DOMAIN_FAILURE"))
#ifdef ERROR_TRUSTED_DOMAIN_FAILURE
	    return ERROR_TRUSTED_DOMAIN_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TRUSTED_RELATIONSHIP_FAILURE"))
#ifdef ERROR_TRUSTED_RELATIONSHIP_FAILURE
	    return ERROR_TRUSTED_RELATIONSHIP_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_TRUST_FAILURE"))
#ifdef ERROR_TRUST_FAILURE
	    return ERROR_TRUST_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNABLE_TO_LOCK_MEDIA"))
#ifdef ERROR_UNABLE_TO_LOCK_MEDIA
	    return ERROR_UNABLE_TO_LOCK_MEDIA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNABLE_TO_UNLOAD_MEDIA"))
#ifdef ERROR_UNABLE_TO_UNLOAD_MEDIA
	    return ERROR_UNABLE_TO_UNLOAD_MEDIA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNEXP_NET_ERR"))
#ifdef ERROR_UNEXP_NET_ERR
	    return ERROR_UNEXP_NET_ERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNKNOWN_PORT"))
#ifdef ERROR_UNKNOWN_PORT
	    return ERROR_UNKNOWN_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNKNOWN_PRINTER_DRIVER"))
#ifdef ERROR_UNKNOWN_PRINTER_DRIVER
	    return ERROR_UNKNOWN_PRINTER_DRIVER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNKNOWN_PRINTPROCESSOR"))
#ifdef ERROR_UNKNOWN_PRINTPROCESSOR
	    return ERROR_UNKNOWN_PRINTPROCESSOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNKNOWN_PRINT_MONITOR"))
#ifdef ERROR_UNKNOWN_PRINT_MONITOR
	    return ERROR_UNKNOWN_PRINT_MONITOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNKNOWN_REVISION"))
#ifdef ERROR_UNKNOWN_REVISION
	    return ERROR_UNKNOWN_REVISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNRECOGNIZED_MEDIA"))
#ifdef ERROR_UNRECOGNIZED_MEDIA
	    return ERROR_UNRECOGNIZED_MEDIA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_UNRECOGNIZED_VOLUME"))
#ifdef ERROR_UNRECOGNIZED_VOLUME
	    return ERROR_UNRECOGNIZED_VOLUME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_USER_EXISTS"))
#ifdef ERROR_USER_EXISTS
	    return ERROR_USER_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_USER_MAPPED_FILE"))
#ifdef ERROR_USER_MAPPED_FILE
	    return ERROR_USER_MAPPED_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_VC_DISCONNECTED"))
#ifdef ERROR_VC_DISCONNECTED
	    return ERROR_VC_DISCONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WAIT_NO_CHILDREN"))
#ifdef ERROR_WAIT_NO_CHILDREN
	    return ERROR_WAIT_NO_CHILDREN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WINDOW_NOT_COMBOBOX"))
#ifdef ERROR_WINDOW_NOT_COMBOBOX
	    return ERROR_WINDOW_NOT_COMBOBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WINDOW_NOT_DIALOG"))
#ifdef ERROR_WINDOW_NOT_DIALOG
	    return ERROR_WINDOW_NOT_DIALOG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WINDOW_OF_OTHER_THREAD"))
#ifdef ERROR_WINDOW_OF_OTHER_THREAD
	    return ERROR_WINDOW_OF_OTHER_THREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WINS_INTERNAL"))
#ifdef ERROR_WINS_INTERNAL
	    return ERROR_WINS_INTERNAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WRITE_FAULT"))
#ifdef ERROR_WRITE_FAULT
	    return ERROR_WRITE_FAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WRITE_PROTECT"))
#ifdef ERROR_WRITE_PROTECT
	    return ERROR_WRITE_PROTECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WRONG_DISK"))
#ifdef ERROR_WRONG_DISK
	    return ERROR_WRONG_DISK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ERROR_WRONG_PASSWORD"))
#ifdef ERROR_WRONG_PASSWORD
	    return ERROR_WRONG_PASSWORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_ABORT"))
#ifdef E_ABORT
	    return E_ABORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_ACCESSDENIED"))
#ifdef E_ACCESSDENIED
	    return E_ACCESSDENIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_FAIL"))
#ifdef E_FAIL
	    return E_FAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_HANDLE"))
#ifdef E_HANDLE
	    return E_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_INVALIDARG"))
#ifdef E_INVALIDARG
	    return E_INVALIDARG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_NOINTERFACE"))
#ifdef E_NOINTERFACE
	    return E_NOINTERFACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_NOTIMPL"))
#ifdef E_NOTIMPL
	    return E_NOTIMPL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_OUTOFMEMORY"))
#ifdef E_OUTOFMEMORY
	    return E_OUTOFMEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_POINTER"))
#ifdef E_POINTER
	    return E_POINTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "E_UNEXPECTED"))
#ifdef E_UNEXPECTED
	    return E_UNEXPECTED;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "FACILITY_CONTROL"))
#ifdef FACILITY_CONTROL
	    return FACILITY_CONTROL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_DISPATCH"))
#ifdef FACILITY_DISPATCH
	    return FACILITY_DISPATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_ITF"))
#ifdef FACILITY_ITF
	    return FACILITY_ITF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_NT_BIT"))
#ifdef FACILITY_NT_BIT
	    return FACILITY_NT_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_NULL"))
#ifdef FACILITY_NULL
	    return FACILITY_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_RPC"))
#ifdef FACILITY_RPC
	    return FACILITY_RPC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_STORAGE"))
#ifdef FACILITY_STORAGE
	    return FACILITY_STORAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_WIN32"))
#ifdef FACILITY_WIN32
	    return FACILITY_WIN32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FACILITY_WINDOWS"))
#ifdef FACILITY_WINDOWS
	    return FACILITY_WINDOWS;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	if (strEQ(name, "INPLACE_E_FIRST"))
#ifdef INPLACE_E_FIRST
	    return INPLACE_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_E_LAST"))
#ifdef INPLACE_E_LAST
	    return INPLACE_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_E_NOTOOLSPACE"))
#ifdef INPLACE_E_NOTOOLSPACE
	    return INPLACE_E_NOTOOLSPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_E_NOTUNDOABLE"))
#ifdef INPLACE_E_NOTUNDOABLE
	    return INPLACE_E_NOTUNDOABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_S_FIRST"))
#ifdef INPLACE_S_FIRST
	    return INPLACE_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_S_LAST"))
#ifdef INPLACE_S_LAST
	    return INPLACE_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "INPLACE_S_TRUNCATED"))
#ifdef INPLACE_S_TRUNCATED
	    return INPLACE_S_TRUNCATED;
#else
	    goto not_there;
#endif
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MARSHAL_E_FIRST"))
#ifdef MARSHAL_E_FIRST
	    return MARSHAL_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MARSHAL_E_LAST"))
#ifdef MARSHAL_E_LAST
	    return MARSHAL_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MARSHAL_S_FIRST"))
#ifdef MARSHAL_S_FIRST
	    return MARSHAL_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MARSHAL_S_LAST"))
#ifdef MARSHAL_S_LAST
	    return MARSHAL_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MEM_E_INVALID_LINK"))
#ifdef MEM_E_INVALID_LINK
	    return MEM_E_INVALID_LINK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MEM_E_INVALID_ROOT"))
#ifdef MEM_E_INVALID_ROOT
	    return MEM_E_INVALID_ROOT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MEM_E_INVALID_SIZE"))
#ifdef MEM_E_INVALID_SIZE
	    return MEM_E_INVALID_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_CANTOPENFILE"))
#ifdef MK_E_CANTOPENFILE
	    return MK_E_CANTOPENFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_CONNECTMANUALLY"))
#ifdef MK_E_CONNECTMANUALLY
	    return MK_E_CONNECTMANUALLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_ENUMERATION_FAILED"))
#ifdef MK_E_ENUMERATION_FAILED
	    return MK_E_ENUMERATION_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_EXCEEDEDDEADLINE"))
#ifdef MK_E_EXCEEDEDDEADLINE
	    return MK_E_EXCEEDEDDEADLINE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_FIRST"))
#ifdef MK_E_FIRST
	    return MK_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_INTERMEDIATEINTERFACENOTSUPPORTED"))
#ifdef MK_E_INTERMEDIATEINTERFACENOTSUPPORTED
	    return MK_E_INTERMEDIATEINTERFACENOTSUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_INVALIDEXTENSION"))
#ifdef MK_E_INVALIDEXTENSION
	    return MK_E_INVALIDEXTENSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_LAST"))
#ifdef MK_E_LAST
	    return MK_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_MUSTBOTHERUSER"))
#ifdef MK_E_MUSTBOTHERUSER
	    return MK_E_MUSTBOTHERUSER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NEEDGENERIC"))
#ifdef MK_E_NEEDGENERIC
	    return MK_E_NEEDGENERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOINVERSE"))
#ifdef MK_E_NOINVERSE
	    return MK_E_NOINVERSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOOBJECT"))
#ifdef MK_E_NOOBJECT
	    return MK_E_NOOBJECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOPREFIX"))
#ifdef MK_E_NOPREFIX
	    return MK_E_NOPREFIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOSTORAGE"))
#ifdef MK_E_NOSTORAGE
	    return MK_E_NOSTORAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOTBINDABLE"))
#ifdef MK_E_NOTBINDABLE
	    return MK_E_NOTBINDABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NOTBOUND"))
#ifdef MK_E_NOTBOUND
	    return MK_E_NOTBOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_NO_NORMALIZED"))
#ifdef MK_E_NO_NORMALIZED
	    return MK_E_NO_NORMALIZED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_SYNTAX"))
#ifdef MK_E_SYNTAX
	    return MK_E_SYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_E_UNAVAILABLE"))
#ifdef MK_E_UNAVAILABLE
	    return MK_E_UNAVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_FIRST"))
#ifdef MK_S_FIRST
	    return MK_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_HIM"))
#ifdef MK_S_HIM
	    return MK_S_HIM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_LAST"))
#ifdef MK_S_LAST
	    return MK_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_ME"))
#ifdef MK_S_ME
	    return MK_S_ME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_MONIKERALREADYREGISTERED"))
#ifdef MK_S_MONIKERALREADYREGISTERED
	    return MK_S_MONIKERALREADYREGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_REDUCED_TO_SELF"))
#ifdef MK_S_REDUCED_TO_SELF
	    return MK_S_REDUCED_TO_SELF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MK_S_US"))
#ifdef MK_S_US
	    return MK_S_US;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	if (strEQ(name, "NOERROR"))
#ifdef NOERROR
	    return NOERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NO_ERROR"))
#ifdef NO_ERROR
	    return NO_ERROR;
#else
	    goto not_there;
#endif
	break;
    case 'O':
	if (strEQ(name, "OLEOBJ_E_FIRST"))
#ifdef OLEOBJ_E_FIRST
	    return OLEOBJ_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_E_INVALIDVERB"))
#ifdef OLEOBJ_E_INVALIDVERB
	    return OLEOBJ_E_INVALIDVERB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_E_LAST"))
#ifdef OLEOBJ_E_LAST
	    return OLEOBJ_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_E_NOVERBS"))
#ifdef OLEOBJ_E_NOVERBS
	    return OLEOBJ_E_NOVERBS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_S_CANNOT_DOVERB_NOW"))
#ifdef OLEOBJ_S_CANNOT_DOVERB_NOW
	    return OLEOBJ_S_CANNOT_DOVERB_NOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_S_FIRST"))
#ifdef OLEOBJ_S_FIRST
	    return OLEOBJ_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_S_INVALIDHWND"))
#ifdef OLEOBJ_S_INVALIDHWND
	    return OLEOBJ_S_INVALIDHWND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_S_INVALIDVERB"))
#ifdef OLEOBJ_S_INVALIDVERB
	    return OLEOBJ_S_INVALIDVERB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLEOBJ_S_LAST"))
#ifdef OLEOBJ_S_LAST
	    return OLEOBJ_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_ADVF"))
#ifdef OLE_E_ADVF
	    return OLE_E_ADVF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_ADVISENOTSUPPORTED"))
#ifdef OLE_E_ADVISENOTSUPPORTED
	    return OLE_E_ADVISENOTSUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_BLANK"))
#ifdef OLE_E_BLANK
	    return OLE_E_BLANK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_CANTCONVERT"))
#ifdef OLE_E_CANTCONVERT
	    return OLE_E_CANTCONVERT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_CANT_BINDTOSOURCE"))
#ifdef OLE_E_CANT_BINDTOSOURCE
	    return OLE_E_CANT_BINDTOSOURCE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_CANT_GETMONIKER"))
#ifdef OLE_E_CANT_GETMONIKER
	    return OLE_E_CANT_GETMONIKER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_CLASSDIFF"))
#ifdef OLE_E_CLASSDIFF
	    return OLE_E_CLASSDIFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_ENUM_NOMORE"))
#ifdef OLE_E_ENUM_NOMORE
	    return OLE_E_ENUM_NOMORE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_FIRST"))
#ifdef OLE_E_FIRST
	    return OLE_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_INVALIDHWND"))
#ifdef OLE_E_INVALIDHWND
	    return OLE_E_INVALIDHWND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_INVALIDRECT"))
#ifdef OLE_E_INVALIDRECT
	    return OLE_E_INVALIDRECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_LAST"))
#ifdef OLE_E_LAST
	    return OLE_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_NOCACHE"))
#ifdef OLE_E_NOCACHE
	    return OLE_E_NOCACHE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_NOCONNECTION"))
#ifdef OLE_E_NOCONNECTION
	    return OLE_E_NOCONNECTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_NOSTORAGE"))
#ifdef OLE_E_NOSTORAGE
	    return OLE_E_NOSTORAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_NOTRUNNING"))
#ifdef OLE_E_NOTRUNNING
	    return OLE_E_NOTRUNNING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_NOT_INPLACEACTIVE"))
#ifdef OLE_E_NOT_INPLACEACTIVE
	    return OLE_E_NOT_INPLACEACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_OLEVERB"))
#ifdef OLE_E_OLEVERB
	    return OLE_E_OLEVERB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_PROMPTSAVECANCELLED"))
#ifdef OLE_E_PROMPTSAVECANCELLED
	    return OLE_E_PROMPTSAVECANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_STATIC"))
#ifdef OLE_E_STATIC
	    return OLE_E_STATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_E_WRONGCOMPOBJ"))
#ifdef OLE_E_WRONGCOMPOBJ
	    return OLE_E_WRONGCOMPOBJ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_S_FIRST"))
#ifdef OLE_S_FIRST
	    return OLE_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_S_LAST"))
#ifdef OLE_S_LAST
	    return OLE_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_S_MAC_CLIPFORMAT"))
#ifdef OLE_S_MAC_CLIPFORMAT
	    return OLE_S_MAC_CLIPFORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_S_STATIC"))
#ifdef OLE_S_STATIC
	    return OLE_S_STATIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "OLE_S_USEREG"))
#ifdef OLE_S_USEREG
	    return OLE_S_USEREG;
#else
	    goto not_there;
#endif
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	if (strEQ(name, "REGDB_E_CLASSNOTREG"))
#ifdef REGDB_E_CLASSNOTREG
	    return REGDB_E_CLASSNOTREG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_FIRST"))
#ifdef REGDB_E_FIRST
	    return REGDB_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_IIDNOTREG"))
#ifdef REGDB_E_IIDNOTREG
	    return REGDB_E_IIDNOTREG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_INVALIDVALUE"))
#ifdef REGDB_E_INVALIDVALUE
	    return REGDB_E_INVALIDVALUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_KEYMISSING"))
#ifdef REGDB_E_KEYMISSING
	    return REGDB_E_KEYMISSING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_LAST"))
#ifdef REGDB_E_LAST
	    return REGDB_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_READREGDB"))
#ifdef REGDB_E_READREGDB
	    return REGDB_E_READREGDB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_E_WRITEREGDB"))
#ifdef REGDB_E_WRITEREGDB
	    return REGDB_E_WRITEREGDB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_S_FIRST"))
#ifdef REGDB_S_FIRST
	    return REGDB_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "REGDB_S_LAST"))
#ifdef REGDB_S_LAST
	    return REGDB_S_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_ATTEMPTED_MULTITHREAD"))
#ifdef RPC_E_ATTEMPTED_MULTITHREAD
	    return RPC_E_ATTEMPTED_MULTITHREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CALL_CANCELED"))
#ifdef RPC_E_CALL_CANCELED
	    return RPC_E_CALL_CANCELED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CALL_REJECTED"))
#ifdef RPC_E_CALL_REJECTED
	    return RPC_E_CALL_REJECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTCALLOUT_AGAIN"))
#ifdef RPC_E_CANTCALLOUT_AGAIN
	    return RPC_E_CANTCALLOUT_AGAIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTCALLOUT_INASYNCCALL"))
#ifdef RPC_E_CANTCALLOUT_INASYNCCALL
	    return RPC_E_CANTCALLOUT_INASYNCCALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTCALLOUT_INEXTERNALCALL"))
#ifdef RPC_E_CANTCALLOUT_INEXTERNALCALL
	    return RPC_E_CANTCALLOUT_INEXTERNALCALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTCALLOUT_ININPUTSYNCCALL"))
#ifdef RPC_E_CANTCALLOUT_ININPUTSYNCCALL
	    return RPC_E_CANTCALLOUT_ININPUTSYNCCALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTPOST_INSENDCALL"))
#ifdef RPC_E_CANTPOST_INSENDCALL
	    return RPC_E_CANTPOST_INSENDCALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CANTTRANSMIT_CALL"))
#ifdef RPC_E_CANTTRANSMIT_CALL
	    return RPC_E_CANTTRANSMIT_CALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CHANGED_MODE"))
#ifdef RPC_E_CHANGED_MODE
	    return RPC_E_CHANGED_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CLIENT_CANTMARSHAL_DATA"))
#ifdef RPC_E_CLIENT_CANTMARSHAL_DATA
	    return RPC_E_CLIENT_CANTMARSHAL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CLIENT_CANTUNMARSHAL_DATA"))
#ifdef RPC_E_CLIENT_CANTUNMARSHAL_DATA
	    return RPC_E_CLIENT_CANTUNMARSHAL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CLIENT_DIED"))
#ifdef RPC_E_CLIENT_DIED
	    return RPC_E_CLIENT_DIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_CONNECTION_TERMINATED"))
#ifdef RPC_E_CONNECTION_TERMINATED
	    return RPC_E_CONNECTION_TERMINATED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_DISCONNECTED"))
#ifdef RPC_E_DISCONNECTED
	    return RPC_E_DISCONNECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_FAULT"))
#ifdef RPC_E_FAULT
	    return RPC_E_FAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_INVALIDMETHOD"))
#ifdef RPC_E_INVALIDMETHOD
	    return RPC_E_INVALIDMETHOD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_INVALID_CALLDATA"))
#ifdef RPC_E_INVALID_CALLDATA
	    return RPC_E_INVALID_CALLDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_INVALID_DATA"))
#ifdef RPC_E_INVALID_DATA
	    return RPC_E_INVALID_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_INVALID_DATAPACKET"))
#ifdef RPC_E_INVALID_DATAPACKET
	    return RPC_E_INVALID_DATAPACKET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_INVALID_PARAMETER"))
#ifdef RPC_E_INVALID_PARAMETER
	    return RPC_E_INVALID_PARAMETER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_NOT_REGISTERED"))
#ifdef RPC_E_NOT_REGISTERED
	    return RPC_E_NOT_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_OUT_OF_RESOURCES"))
#ifdef RPC_E_OUT_OF_RESOURCES
	    return RPC_E_OUT_OF_RESOURCES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_RETRY"))
#ifdef RPC_E_RETRY
	    return RPC_E_RETRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVERCALL_REJECTED"))
#ifdef RPC_E_SERVERCALL_REJECTED
	    return RPC_E_SERVERCALL_REJECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVERCALL_RETRYLATER"))
#ifdef RPC_E_SERVERCALL_RETRYLATER
	    return RPC_E_SERVERCALL_RETRYLATER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVERFAULT"))
#ifdef RPC_E_SERVERFAULT
	    return RPC_E_SERVERFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVER_CANTMARSHAL_DATA"))
#ifdef RPC_E_SERVER_CANTMARSHAL_DATA
	    return RPC_E_SERVER_CANTMARSHAL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVER_CANTUNMARSHAL_DATA"))
#ifdef RPC_E_SERVER_CANTUNMARSHAL_DATA
	    return RPC_E_SERVER_CANTUNMARSHAL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVER_DIED"))
#ifdef RPC_E_SERVER_DIED
	    return RPC_E_SERVER_DIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SERVER_DIED_DNE"))
#ifdef RPC_E_SERVER_DIED_DNE
	    return RPC_E_SERVER_DIED_DNE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_SYS_CALL_FAILED"))
#ifdef RPC_E_SYS_CALL_FAILED
	    return RPC_E_SYS_CALL_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_THREAD_NOT_INIT"))
#ifdef RPC_E_THREAD_NOT_INIT
	    return RPC_E_THREAD_NOT_INIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_UNEXPECTED"))
#ifdef RPC_E_UNEXPECTED
	    return RPC_E_UNEXPECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_E_WRONG_THREAD"))
#ifdef RPC_E_WRONG_THREAD
	    return RPC_E_WRONG_THREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ADDRESS_ERROR"))
#ifdef RPC_S_ADDRESS_ERROR
	    return RPC_S_ADDRESS_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ALREADY_LISTENING"))
#ifdef RPC_S_ALREADY_LISTENING
	    return RPC_S_ALREADY_LISTENING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ALREADY_REGISTERED"))
#ifdef RPC_S_ALREADY_REGISTERED
	    return RPC_S_ALREADY_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_BINDING_HAS_NO_AUTH"))
#ifdef RPC_S_BINDING_HAS_NO_AUTH
	    return RPC_S_BINDING_HAS_NO_AUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_BINDING_INCOMPLETE"))
#ifdef RPC_S_BINDING_INCOMPLETE
	    return RPC_S_BINDING_INCOMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CALL_CANCELLED"))
#ifdef RPC_S_CALL_CANCELLED
	    return RPC_S_CALL_CANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CALL_FAILED"))
#ifdef RPC_S_CALL_FAILED
	    return RPC_S_CALL_FAILED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CALL_FAILED_DNE"))
#ifdef RPC_S_CALL_FAILED_DNE
	    return RPC_S_CALL_FAILED_DNE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CALL_IN_PROGRESS"))
#ifdef RPC_S_CALL_IN_PROGRESS
	    return RPC_S_CALL_IN_PROGRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CANNOT_SUPPORT"))
#ifdef RPC_S_CANNOT_SUPPORT
	    return RPC_S_CANNOT_SUPPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_CANT_CREATE_ENDPOINT"))
#ifdef RPC_S_CANT_CREATE_ENDPOINT
	    return RPC_S_CANT_CREATE_ENDPOINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_COMM_FAILURE"))
#ifdef RPC_S_COMM_FAILURE
	    return RPC_S_COMM_FAILURE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_DUPLICATE_ENDPOINT"))
#ifdef RPC_S_DUPLICATE_ENDPOINT
	    return RPC_S_DUPLICATE_ENDPOINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ENTRY_ALREADY_EXISTS"))
#ifdef RPC_S_ENTRY_ALREADY_EXISTS
	    return RPC_S_ENTRY_ALREADY_EXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ENTRY_NOT_FOUND"))
#ifdef RPC_S_ENTRY_NOT_FOUND
	    return RPC_S_ENTRY_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_FP_DIV_ZERO"))
#ifdef RPC_S_FP_DIV_ZERO
	    return RPC_S_FP_DIV_ZERO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_FP_OVERFLOW"))
#ifdef RPC_S_FP_OVERFLOW
	    return RPC_S_FP_OVERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_FP_UNDERFLOW"))
#ifdef RPC_S_FP_UNDERFLOW
	    return RPC_S_FP_UNDERFLOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_GROUP_MEMBER_NOT_FOUND"))
#ifdef RPC_S_GROUP_MEMBER_NOT_FOUND
	    return RPC_S_GROUP_MEMBER_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INCOMPLETE_NAME"))
#ifdef RPC_S_INCOMPLETE_NAME
	    return RPC_S_INCOMPLETE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INTERFACE_NOT_FOUND"))
#ifdef RPC_S_INTERFACE_NOT_FOUND
	    return RPC_S_INTERFACE_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INTERNAL_ERROR"))
#ifdef RPC_S_INTERNAL_ERROR
	    return RPC_S_INTERNAL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_AUTH_IDENTITY"))
#ifdef RPC_S_INVALID_AUTH_IDENTITY
	    return RPC_S_INVALID_AUTH_IDENTITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_BINDING"))
#ifdef RPC_S_INVALID_BINDING
	    return RPC_S_INVALID_BINDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_BOUND"))
#ifdef RPC_S_INVALID_BOUND
	    return RPC_S_INVALID_BOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_ENDPOINT_FORMAT"))
#ifdef RPC_S_INVALID_ENDPOINT_FORMAT
	    return RPC_S_INVALID_ENDPOINT_FORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_NAF_ID"))
#ifdef RPC_S_INVALID_NAF_ID
	    return RPC_S_INVALID_NAF_ID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_NAME_SYNTAX"))
#ifdef RPC_S_INVALID_NAME_SYNTAX
	    return RPC_S_INVALID_NAME_SYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_NETWORK_OPTIONS"))
#ifdef RPC_S_INVALID_NETWORK_OPTIONS
	    return RPC_S_INVALID_NETWORK_OPTIONS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_NET_ADDR"))
#ifdef RPC_S_INVALID_NET_ADDR
	    return RPC_S_INVALID_NET_ADDR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_OBJECT"))
#ifdef RPC_S_INVALID_OBJECT
	    return RPC_S_INVALID_OBJECT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_RPC_PROTSEQ"))
#ifdef RPC_S_INVALID_RPC_PROTSEQ
	    return RPC_S_INVALID_RPC_PROTSEQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_STRING_BINDING"))
#ifdef RPC_S_INVALID_STRING_BINDING
	    return RPC_S_INVALID_STRING_BINDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_STRING_UUID"))
#ifdef RPC_S_INVALID_STRING_UUID
	    return RPC_S_INVALID_STRING_UUID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_TAG"))
#ifdef RPC_S_INVALID_TAG
	    return RPC_S_INVALID_TAG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_TIMEOUT"))
#ifdef RPC_S_INVALID_TIMEOUT
	    return RPC_S_INVALID_TIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_INVALID_VERS_OPTION"))
#ifdef RPC_S_INVALID_VERS_OPTION
	    return RPC_S_INVALID_VERS_OPTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_MAX_CALLS_TOO_SMALL"))
#ifdef RPC_S_MAX_CALLS_TOO_SMALL
	    return RPC_S_MAX_CALLS_TOO_SMALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NAME_SERVICE_UNAVAILABLE"))
#ifdef RPC_S_NAME_SERVICE_UNAVAILABLE
	    return RPC_S_NAME_SERVICE_UNAVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NOTHING_TO_EXPORT"))
#ifdef RPC_S_NOTHING_TO_EXPORT
	    return RPC_S_NOTHING_TO_EXPORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NOT_ALL_OBJS_UNEXPORTED"))
#ifdef RPC_S_NOT_ALL_OBJS_UNEXPORTED
	    return RPC_S_NOT_ALL_OBJS_UNEXPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NOT_CANCELLED"))
#ifdef RPC_S_NOT_CANCELLED
	    return RPC_S_NOT_CANCELLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NOT_LISTENING"))
#ifdef RPC_S_NOT_LISTENING
	    return RPC_S_NOT_LISTENING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NOT_RPC_ERROR"))
#ifdef RPC_S_NOT_RPC_ERROR
	    return RPC_S_NOT_RPC_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_BINDINGS"))
#ifdef RPC_S_NO_BINDINGS
	    return RPC_S_NO_BINDINGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_CALL_ACTIVE"))
#ifdef RPC_S_NO_CALL_ACTIVE
	    return RPC_S_NO_CALL_ACTIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_CONTEXT_AVAILABLE"))
#ifdef RPC_S_NO_CONTEXT_AVAILABLE
	    return RPC_S_NO_CONTEXT_AVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_ENDPOINT_FOUND"))
#ifdef RPC_S_NO_ENDPOINT_FOUND
	    return RPC_S_NO_ENDPOINT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_ENTRY_NAME"))
#ifdef RPC_S_NO_ENTRY_NAME
	    return RPC_S_NO_ENTRY_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_INTERFACES"))
#ifdef RPC_S_NO_INTERFACES
	    return RPC_S_NO_INTERFACES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_MORE_BINDINGS"))
#ifdef RPC_S_NO_MORE_BINDINGS
	    return RPC_S_NO_MORE_BINDINGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_MORE_MEMBERS"))
#ifdef RPC_S_NO_MORE_MEMBERS
	    return RPC_S_NO_MORE_MEMBERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_PRINC_NAME"))
#ifdef RPC_S_NO_PRINC_NAME
	    return RPC_S_NO_PRINC_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_PROTSEQS"))
#ifdef RPC_S_NO_PROTSEQS
	    return RPC_S_NO_PROTSEQS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_NO_PROTSEQS_REGISTERED"))
#ifdef RPC_S_NO_PROTSEQS_REGISTERED
	    return RPC_S_NO_PROTSEQS_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_OBJECT_NOT_FOUND"))
#ifdef RPC_S_OBJECT_NOT_FOUND
	    return RPC_S_OBJECT_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_OUT_OF_RESOURCES"))
#ifdef RPC_S_OUT_OF_RESOURCES
	    return RPC_S_OUT_OF_RESOURCES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_PROCNUM_OUT_OF_RANGE"))
#ifdef RPC_S_PROCNUM_OUT_OF_RANGE
	    return RPC_S_PROCNUM_OUT_OF_RANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_PROTOCOL_ERROR"))
#ifdef RPC_S_PROTOCOL_ERROR
	    return RPC_S_PROTOCOL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_PROTSEQ_NOT_FOUND"))
#ifdef RPC_S_PROTSEQ_NOT_FOUND
	    return RPC_S_PROTSEQ_NOT_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_PROTSEQ_NOT_SUPPORTED"))
#ifdef RPC_S_PROTSEQ_NOT_SUPPORTED
	    return RPC_S_PROTSEQ_NOT_SUPPORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_SEC_PKG_ERROR"))
#ifdef RPC_S_SEC_PKG_ERROR
	    return RPC_S_SEC_PKG_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_SERVER_TOO_BUSY"))
#ifdef RPC_S_SERVER_TOO_BUSY
	    return RPC_S_SERVER_TOO_BUSY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_SERVER_UNAVAILABLE"))
#ifdef RPC_S_SERVER_UNAVAILABLE
	    return RPC_S_SERVER_UNAVAILABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_STRING_TOO_LONG"))
#ifdef RPC_S_STRING_TOO_LONG
	    return RPC_S_STRING_TOO_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_TYPE_ALREADY_REGISTERED"))
#ifdef RPC_S_TYPE_ALREADY_REGISTERED
	    return RPC_S_TYPE_ALREADY_REGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_AUTHN_LEVEL"))
#ifdef RPC_S_UNKNOWN_AUTHN_LEVEL
	    return RPC_S_UNKNOWN_AUTHN_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_AUTHN_SERVICE"))
#ifdef RPC_S_UNKNOWN_AUTHN_SERVICE
	    return RPC_S_UNKNOWN_AUTHN_SERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_AUTHN_TYPE"))
#ifdef RPC_S_UNKNOWN_AUTHN_TYPE
	    return RPC_S_UNKNOWN_AUTHN_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_AUTHZ_SERVICE"))
#ifdef RPC_S_UNKNOWN_AUTHZ_SERVICE
	    return RPC_S_UNKNOWN_AUTHZ_SERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_IF"))
#ifdef RPC_S_UNKNOWN_IF
	    return RPC_S_UNKNOWN_IF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNKNOWN_MGR_TYPE"))
#ifdef RPC_S_UNKNOWN_MGR_TYPE
	    return RPC_S_UNKNOWN_MGR_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNSUPPORTED_AUTHN_LEVEL"))
#ifdef RPC_S_UNSUPPORTED_AUTHN_LEVEL
	    return RPC_S_UNSUPPORTED_AUTHN_LEVEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNSUPPORTED_NAME_SYNTAX"))
#ifdef RPC_S_UNSUPPORTED_NAME_SYNTAX
	    return RPC_S_UNSUPPORTED_NAME_SYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNSUPPORTED_TRANS_SYN"))
#ifdef RPC_S_UNSUPPORTED_TRANS_SYN
	    return RPC_S_UNSUPPORTED_TRANS_SYN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UNSUPPORTED_TYPE"))
#ifdef RPC_S_UNSUPPORTED_TYPE
	    return RPC_S_UNSUPPORTED_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UUID_LOCAL_ONLY"))
#ifdef RPC_S_UUID_LOCAL_ONLY
	    return RPC_S_UUID_LOCAL_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_UUID_NO_ADDRESS"))
#ifdef RPC_S_UUID_NO_ADDRESS
	    return RPC_S_UUID_NO_ADDRESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_WRONG_KIND_OF_BINDING"))
#ifdef RPC_S_WRONG_KIND_OF_BINDING
	    return RPC_S_WRONG_KIND_OF_BINDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_S_ZERO_DIVIDE"))
#ifdef RPC_S_ZERO_DIVIDE
	    return RPC_S_ZERO_DIVIDE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_BAD_STUB_DATA"))
#ifdef RPC_X_BAD_STUB_DATA
	    return RPC_X_BAD_STUB_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_BYTE_COUNT_TOO_SMALL"))
#ifdef RPC_X_BYTE_COUNT_TOO_SMALL
	    return RPC_X_BYTE_COUNT_TOO_SMALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_ENUM_VALUE_OUT_OF_RANGE"))
#ifdef RPC_X_ENUM_VALUE_OUT_OF_RANGE
	    return RPC_X_ENUM_VALUE_OUT_OF_RANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_INVALID_ES_ACTION"))
#ifdef RPC_X_INVALID_ES_ACTION
	    return RPC_X_INVALID_ES_ACTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_NO_MORE_ENTRIES"))
#ifdef RPC_X_NO_MORE_ENTRIES
	    return RPC_X_NO_MORE_ENTRIES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_NULL_REF_POINTER"))
#ifdef RPC_X_NULL_REF_POINTER
	    return RPC_X_NULL_REF_POINTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_CANNOT_GET_CALL_HANDLE"))
#ifdef RPC_X_SS_CANNOT_GET_CALL_HANDLE
	    return RPC_X_SS_CANNOT_GET_CALL_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_CHAR_TRANS_OPEN_FAIL"))
#ifdef RPC_X_SS_CHAR_TRANS_OPEN_FAIL
	    return RPC_X_SS_CHAR_TRANS_OPEN_FAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_CHAR_TRANS_SHORT_FILE"))
#ifdef RPC_X_SS_CHAR_TRANS_SHORT_FILE
	    return RPC_X_SS_CHAR_TRANS_SHORT_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_CONTEXT_DAMAGED"))
#ifdef RPC_X_SS_CONTEXT_DAMAGED
	    return RPC_X_SS_CONTEXT_DAMAGED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_HANDLES_MISMATCH"))
#ifdef RPC_X_SS_HANDLES_MISMATCH
	    return RPC_X_SS_HANDLES_MISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_SS_IN_NULL_CONTEXT"))
#ifdef RPC_X_SS_IN_NULL_CONTEXT
	    return RPC_X_SS_IN_NULL_CONTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_WRONG_ES_VERSION"))
#ifdef RPC_X_WRONG_ES_VERSION
	    return RPC_X_WRONG_ES_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "RPC_X_WRONG_STUB_VERSION"))
#ifdef RPC_X_WRONG_STUB_VERSION
	    return RPC_X_WRONG_STUB_VERSION;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SEVERITY_ERROR"))
#ifdef SEVERITY_ERROR
	    return SEVERITY_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEVERITY_SUCCESS"))
#ifdef SEVERITY_SUCCESS
	    return SEVERITY_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_ABNORMALAPIEXIT"))
#ifdef STG_E_ABNORMALAPIEXIT
	    return STG_E_ABNORMALAPIEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_ACCESSDENIED"))
#ifdef STG_E_ACCESSDENIED
	    return STG_E_ACCESSDENIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_CANTSAVE"))
#ifdef STG_E_CANTSAVE
	    return STG_E_CANTSAVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_DISKISWRITEPROTECTED"))
#ifdef STG_E_DISKISWRITEPROTECTED
	    return STG_E_DISKISWRITEPROTECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_EXTANTMARSHALLINGS"))
#ifdef STG_E_EXTANTMARSHALLINGS
	    return STG_E_EXTANTMARSHALLINGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_FILEALREADYEXISTS"))
#ifdef STG_E_FILEALREADYEXISTS
	    return STG_E_FILEALREADYEXISTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_FILENOTFOUND"))
#ifdef STG_E_FILENOTFOUND
	    return STG_E_FILENOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INSUFFICIENTMEMORY"))
#ifdef STG_E_INSUFFICIENTMEMORY
	    return STG_E_INSUFFICIENTMEMORY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INUSE"))
#ifdef STG_E_INUSE
	    return STG_E_INUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDFLAG"))
#ifdef STG_E_INVALIDFLAG
	    return STG_E_INVALIDFLAG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDFUNCTION"))
#ifdef STG_E_INVALIDFUNCTION
	    return STG_E_INVALIDFUNCTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDHANDLE"))
#ifdef STG_E_INVALIDHANDLE
	    return STG_E_INVALIDHANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDHEADER"))
#ifdef STG_E_INVALIDHEADER
	    return STG_E_INVALIDHEADER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDNAME"))
#ifdef STG_E_INVALIDNAME
	    return STG_E_INVALIDNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDPARAMETER"))
#ifdef STG_E_INVALIDPARAMETER
	    return STG_E_INVALIDPARAMETER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_INVALIDPOINTER"))
#ifdef STG_E_INVALIDPOINTER
	    return STG_E_INVALIDPOINTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_LOCKVIOLATION"))
#ifdef STG_E_LOCKVIOLATION
	    return STG_E_LOCKVIOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_MEDIUMFULL"))
#ifdef STG_E_MEDIUMFULL
	    return STG_E_MEDIUMFULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_NOMOREFILES"))
#ifdef STG_E_NOMOREFILES
	    return STG_E_NOMOREFILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_NOTCURRENT"))
#ifdef STG_E_NOTCURRENT
	    return STG_E_NOTCURRENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_NOTFILEBASEDSTORAGE"))
#ifdef STG_E_NOTFILEBASEDSTORAGE
	    return STG_E_NOTFILEBASEDSTORAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_OLDDLL"))
#ifdef STG_E_OLDDLL
	    return STG_E_OLDDLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_OLDFORMAT"))
#ifdef STG_E_OLDFORMAT
	    return STG_E_OLDFORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_PATHNOTFOUND"))
#ifdef STG_E_PATHNOTFOUND
	    return STG_E_PATHNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_READFAULT"))
#ifdef STG_E_READFAULT
	    return STG_E_READFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_REVERTED"))
#ifdef STG_E_REVERTED
	    return STG_E_REVERTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_SEEKERROR"))
#ifdef STG_E_SEEKERROR
	    return STG_E_SEEKERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_SHAREREQUIRED"))
#ifdef STG_E_SHAREREQUIRED
	    return STG_E_SHAREREQUIRED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_SHAREVIOLATION"))
#ifdef STG_E_SHAREVIOLATION
	    return STG_E_SHAREVIOLATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_TOOMANYOPENFILES"))
#ifdef STG_E_TOOMANYOPENFILES
	    return STG_E_TOOMANYOPENFILES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_UNIMPLEMENTEDFUNCTION"))
#ifdef STG_E_UNIMPLEMENTEDFUNCTION
	    return STG_E_UNIMPLEMENTEDFUNCTION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_UNKNOWN"))
#ifdef STG_E_UNKNOWN
	    return STG_E_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_E_WRITEFAULT"))
#ifdef STG_E_WRITEFAULT
	    return STG_E_WRITEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "STG_S_CONVERTED"))
#ifdef STG_S_CONVERTED
	    return STG_S_CONVERTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "S_FALSE"))
#ifdef S_FALSE
	    return S_FALSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "S_OK"))
#ifdef S_OK
	    return S_OK;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TYPE_E_AMBIGUOUSNAME"))
#ifdef TYPE_E_AMBIGUOUSNAME
	    return TYPE_E_AMBIGUOUSNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_BADMODULEKIND"))
#ifdef TYPE_E_BADMODULEKIND
	    return TYPE_E_BADMODULEKIND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_BUFFERTOOSMALL"))
#ifdef TYPE_E_BUFFERTOOSMALL
	    return TYPE_E_BUFFERTOOSMALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_CANTCREATETMPFILE"))
#ifdef TYPE_E_CANTCREATETMPFILE
	    return TYPE_E_CANTCREATETMPFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_CANTLOADLIBRARY"))
#ifdef TYPE_E_CANTLOADLIBRARY
	    return TYPE_E_CANTLOADLIBRARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_CIRCULARTYPE"))
#ifdef TYPE_E_CIRCULARTYPE
	    return TYPE_E_CIRCULARTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_DLLFUNCTIONNOTFOUND"))
#ifdef TYPE_E_DLLFUNCTIONNOTFOUND
	    return TYPE_E_DLLFUNCTIONNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_DUPLICATEID"))
#ifdef TYPE_E_DUPLICATEID
	    return TYPE_E_DUPLICATEID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_ELEMENTNOTFOUND"))
#ifdef TYPE_E_ELEMENTNOTFOUND
	    return TYPE_E_ELEMENTNOTFOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_INCONSISTENTPROPFUNCS"))
#ifdef TYPE_E_INCONSISTENTPROPFUNCS
	    return TYPE_E_INCONSISTENTPROPFUNCS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_INVALIDID"))
#ifdef TYPE_E_INVALIDID
	    return TYPE_E_INVALIDID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_INVALIDSTATE"))
#ifdef TYPE_E_INVALIDSTATE
	    return TYPE_E_INVALIDSTATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_INVDATAREAD"))
#ifdef TYPE_E_INVDATAREAD
	    return TYPE_E_INVDATAREAD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_IOERROR"))
#ifdef TYPE_E_IOERROR
	    return TYPE_E_IOERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_LIBNOTREGISTERED"))
#ifdef TYPE_E_LIBNOTREGISTERED
	    return TYPE_E_LIBNOTREGISTERED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_NAMECONFLICT"))
#ifdef TYPE_E_NAMECONFLICT
	    return TYPE_E_NAMECONFLICT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_OUTOFBOUNDS"))
#ifdef TYPE_E_OUTOFBOUNDS
	    return TYPE_E_OUTOFBOUNDS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_QUALIFIEDNAMEDISALLOWED"))
#ifdef TYPE_E_QUALIFIEDNAMEDISALLOWED
	    return TYPE_E_QUALIFIEDNAMEDISALLOWED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_REGISTRYACCESS"))
#ifdef TYPE_E_REGISTRYACCESS
	    return TYPE_E_REGISTRYACCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_SIZETOOBIG"))
#ifdef TYPE_E_SIZETOOBIG
	    return TYPE_E_SIZETOOBIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_TYPEMISMATCH"))
#ifdef TYPE_E_TYPEMISMATCH
	    return TYPE_E_TYPEMISMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_UNDEFINEDTYPE"))
#ifdef TYPE_E_UNDEFINEDTYPE
	    return TYPE_E_UNDEFINEDTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_UNKNOWNLCID"))
#ifdef TYPE_E_UNKNOWNLCID
	    return TYPE_E_UNKNOWNLCID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_UNSUPFORMAT"))
#ifdef TYPE_E_UNSUPFORMAT
	    return TYPE_E_UNSUPFORMAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TYPE_E_WRONGTYPEKIND"))
#ifdef TYPE_E_WRONGTYPEKIND
	    return TYPE_E_WRONGTYPEKIND;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	break;
    case 'V':
	if (strEQ(name, "VIEW_E_DRAW"))
#ifdef VIEW_E_DRAW
	    return VIEW_E_DRAW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VIEW_E_FIRST"))
#ifdef VIEW_E_FIRST
	    return VIEW_E_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VIEW_E_LAST"))
#ifdef VIEW_E_LAST
	    return VIEW_E_LAST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VIEW_S_ALREADY_FROZEN"))
#ifdef VIEW_S_ALREADY_FROZEN
	    return VIEW_S_ALREADY_FROZEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VIEW_S_FIRST"))
#ifdef VIEW_S_FIRST
	    return VIEW_S_FIRST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "VIEW_S_LAST"))
#ifdef VIEW_S_LAST
	    return VIEW_S_LAST;
#else
	    goto not_there;
#endif
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Win32::WinError   PACKAGE = Win32::WinError

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *          name
	int             arg

