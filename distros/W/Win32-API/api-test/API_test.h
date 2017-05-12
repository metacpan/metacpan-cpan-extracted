//
// API_test.h
//
// $Id$

// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the API_TEST_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// API_TEST_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.

#ifdef API_TEST_EXPORTS
#define API_TEST_API __declspec(dllexport)
#else
#define API_TEST_API __declspec(dllimport)
#endif

typedef struct _simple_struct {
	int a;
	double b;
	char * c;
	DWORD_PTR d;
} simple_struct, LPsimple_struct;

typedef struct {
    char a;
    char b;
    char c;
    char d;
}
four_char_struct;

typedef struct {
    int one;
    int two;
    int three;
    int four;
    int five; //should be some padding right here
    double six;
}
SIX_MEMS; //MEMS=members, not memory

typedef struct {
    unsigned int first;
    CHAR str [32];
    unsigned int last;
} ARR_IN_STRUCT;

typedef struct {
    unsigned int first;
    WCHAR str [32];
    unsigned int last;
} WARR_IN_STRUCT;

typedef enum _WLAN_CONNECTION_MODE {
    wlan_connection_mode_profile = 0,
    wlan_connection_mode_temporary_profile,
    wlan_connection_mode_discovery_secure,
    wlan_connection_mode_discovery_unsecure,
    wlan_connection_mode_auto,
    wlan_connection_mode_invalid
} WLAN_CONNECTION_MODE, *PWLAN_CONNECTION_MODE;

#define DOT11_SSID_MAX_LENGTH   32      // 32 bytes
typedef struct _DOT11_SSID {
    ULONG uSSIDLength;
    UCHAR ucSSID[DOT11_SSID_MAX_LENGTH];
} DOT11_SSID, * PDOT11_SSID;

typedef struct _NDIS_OBJECT_HEADER
{
    UCHAR   Type;
    UCHAR   Revision;
    USHORT  Size;
} NDIS_OBJECT_HEADER, *PNDIS_OBJECT_HEADER;

// These are needed for wlanapi.h for pre-vista targets
#ifdef __midl
    typedef struct _DOT11_MAC_ADDRESS {
        UCHAR ucDot11MacAddress[6];
    } DOT11_MAC_ADDRESS, * PDOT11_MAC_ADDRESS;
#else
    typedef UCHAR DOT11_MAC_ADDRESS[6];
    typedef DOT11_MAC_ADDRESS * PDOT11_MAC_ADDRESS;
#endif

// A list of DOT11_MAC_ADDRESS
typedef struct DOT11_BSSID_LIST {
    #define DOT11_BSSID_LIST_REVISION_1  1
    NDIS_OBJECT_HEADER Header;
    ULONG uNumOfEntries;
    ULONG uTotalNumOfEntries;
#ifdef __midl
    [unique, size_is(uTotalNumOfEntries)] DOT11_MAC_ADDRESS BSSIDs[*];
#else
    DOT11_MAC_ADDRESS BSSIDs[1];
#endif
} DOT11_BSSID_LIST, * PDOT11_BSSID_LIST;

typedef enum _DOT11_BSS_TYPE {
    dot11_BSS_type_infrastructure = 1,
    dot11_BSS_type_independent = 2,
    dot11_BSS_type_any = 3
} DOT11_BSS_TYPE, * PDOT11_BSS_TYPE;

typedef struct _WLAN_CONNECTION_PARAMETERS {
    WLAN_CONNECTION_MODE wlanConnectionMode;
#ifdef __midl
    [string] LPCWSTR strProfile;
#else
    LPCWSTR strProfile;
#endif
    PDOT11_SSID pDot11Ssid;
    PDOT11_BSSID_LIST pDesiredBssidList;
    DOT11_BSS_TYPE dot11BssType;
    DWORD dwFlags;
} WLAN_CONNECTION_PARAMETERS, *PWLAN_CONNECTION_PARAMETERS;

#define WLAN_CONNECTION_HIDDEN_NETWORK      0x00000001

// typedef int callback_func(int);

typedef int (__stdcall * callback_func)(int);

typedef double (__stdcall * callback_func_void_d)();
typedef float  (__stdcall * callback_func_void_f)();
typedef unsigned __int64  (__stdcall * callback_func_void_q)();
typedef int    (__stdcall * callback_func_5_param)
(char, unsigned __int64, four_char_struct *, float, double);
typedef int    (__cdecl   * callback_func_5_param_cdec)
(char, unsigned __int64, four_char_struct *, float, double);


extern API_TEST_API int nAPI_test;

API_TEST_API ULONG  __stdcall highbit_unsigned();
API_TEST_API int    __stdcall sum_integers(int a, int b);
API_TEST_API short  __stdcall sum_shorts(short a, short b);
API_TEST_API short  __stdcall sum_shorts_ref(short a, short b, short *c);
API_TEST_API double __stdcall sum_doubles(double a, double b);
API_TEST_API float  __stdcall sum_floats(float a, float b);
API_TEST_API int    __stdcall has_char(char *string, char ch);
API_TEST_API char * __stdcall find_char(char *string, char ch);
API_TEST_API void   __stdcall dump_struct(simple_struct *x);
API_TEST_API int    __stdcall mangle_simple_struct(simple_struct *x);
API_TEST_API BOOL   __stdcall GetHandle(LPHANDLE pHandle);
API_TEST_API BOOL   __stdcall FreeHandle(HANDLE Handle);
API_TEST_API int    __cdecl   c_sum_integers(int a, int b);