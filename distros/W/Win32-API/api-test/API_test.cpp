//
// API_test.cpp : Defines the entry point for the DLL application.
//
// $Id$

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <malloc.h>
#include <stdio.h>
#include "API_test.h"

#ifdef _WIN64
#define DEFAULT_SECURITY_COOKIE 0x00002B992DDFA232
#else  /* _WIN64 */
#define DEFAULT_SECURITY_COOKIE 0xBB40E64E
#endif  /* _WIN64 */

extern "C" DWORD_PTR __security_cookie = DEFAULT_SECURITY_COOKIE;
extern "C" __declspec(dllimport) DWORD_PTR rtc_security_cookie;

HMODULE g_hModule = NULL;
BOOL APIENTRY ApiDllMain(   HANDLE hModule,
                            DWORD  ul_reason_for_call,
                            LPVOID lpReserved
					 )
{
    switch (ul_reason_for_call)
	{
		case DLL_PROCESS_ATTACH:
/* it seems that __security_cookie cant be imported across DLLs,
   probably because an imported var has different machine code
   (2 reads instructions) vs a same DLL var which has 1 read, and VC doesnt
   listen to any C code declarations about __security_cookie and is hard coded
   to always use the 1 read variant
   API_test error LNK2019: unresolved external symbol ___security_cookie referenced in function _printf
*/
	    __security_cookie = rtc_security_cookie;
            g_hModule = (HMODULE)hModule;
		case DLL_THREAD_ATTACH:
		case DLL_THREAD_DETACH:
		case DLL_PROCESS_DETACH:
			break;
    }
    return TRUE;
}

extern "C" __declspec(selectany) DWORD _fltused = 0;

/* CharUpperA not so efficient, calls LCMapStringW internally
   and LCMapStringW is slow compared to CRT toupper for low ascii */
#define toupper(x) (char)CharUpperA((LPTSTR)x)
#define sprintf wsprintf

int printf(const char * format, ...)
{
    char buf[1024];
    int ret;
    DWORD NumberOfBytesWritten;
    va_list args;

    va_start(args, format);
    /* wvsprintf is from user32.dll not any CRT,
    this makes API_test.dll almost CRT-free */
    ret = wvsprintf(buf, format, args );
    va_end( args );

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), buf, ret,&NumberOfBytesWritten, NULL);
    /* not sure if ret is 100% accurate as real printf */
    return ret;
}

/* know which VC version was used to build this DLL, helps in reproducibility
   and keeps git diff smallers when you use the same VC version */
#define stringify(x) #x
#define stringifym(x) stringify(x)
extern API_TEST_API const char cc_name_str [] = "VC " stringifym(_MSC_VER);

// This is an example of an exported variable
API_TEST_API int nAPI_test=0;

API_TEST_API ULONG __stdcall highbit_unsigned() {
	return 0x80005000;
}

API_TEST_API int __stdcall sum_integers(int a, int b) {
	return a + b;
}

API_TEST_API short __stdcall sum_shorts(short a, short b) {
	return a + b;
}
API_TEST_API int __stdcall sum_uchar_ret_int(unsigned char a, unsigned char b) {
	return a + b;
}

API_TEST_API short __stdcall sum_shorts_ref(short a, short b, short*c) {
    if(!IsBadReadPtr(c, sizeof(short))){
        *c = a + b;
        return -32768;
    }
    else {
        return 0;
    }
}

API_TEST_API char __stdcall sum_char_ref(char a, char b, char *c) {
    if(!IsBadReadPtr(c, sizeof(char))){
        *c = a + b;
        return -128;
    }
    else {
        return 0;
    }
}

API_TEST_API BOOL __stdcall str_cmp(char *string) {
    if(memcmp("Just another perl hacker", string,
              sizeof("Just another perl hacker")) == 0){
        return TRUE;
    }
    else{
        return FALSE;
    }
}

API_TEST_API BOOL __stdcall wstr_cmp(WCHAR * string) {
    if(memcmp(L"Just another perl hacker", string,
               sizeof(L"Just another perl hacker")) == 0){
        return TRUE;
    }
    else{
        return FALSE;
    }
}

API_TEST_API void __stdcall buffer_overflow(char *string) {
    memcpy(string, "JAPHJAPH", sizeof("JAPHJAPH")-1);
}

API_TEST_API int __stdcall sum_integers_ref(int a, int b, int *c) {
	*c = a + b;
	return 1;
}

API_TEST_API LONG64 __stdcall sum_quads_ref(LONG64 a, LONG64 b, LONG64 * c) {
	*c = a + b;
	return *c;
}

API_TEST_API double __stdcall sum_doubles(double a, double b) {
	return a + b;
}

API_TEST_API int __stdcall sum_doubles_ref(double a, double b, double *c) {
	*c = a + b;
	return 1;
}

API_TEST_API float __stdcall sum_floats(float a, float b) {
	return a + b;
}

API_TEST_API int __stdcall sum_floats_ref(float a, float b, float *c) {
	*c = a + b;
	return 1;
}

API_TEST_API float * __stdcall ret_float_ptr(){
    static float ret_float_var;
    ret_float_var = 7.5;
    return &ret_float_var;
}

API_TEST_API int __stdcall has_char(char *string, char ch) {
	char *tmp;
	tmp = string;
	while(tmp[0]) {
		if(tmp[0] == ch) return 1;
		tmp++;
	}
	return 0;
}

API_TEST_API char * __stdcall find_char(char *string, char ch) {
	char *tmp;
	printf("find_char: got '%s', '%c'\n", string, ch);
	tmp = string;
	while(tmp[0]) {
		printf("find_char: tmp now '%s'\n", tmp);
		if(tmp[0] == ch) return tmp;
		tmp++;
	}
	return NULL;
}

API_TEST_API void __stdcall dump_struct(const char *name, simple_struct *x) {
	int i;
	printf("dump_struct: \n");	
	for(i=0; i<= sizeof(simple_struct); i++) {
		printf("    %02d: 0x%02x\n", i, (unsigned char) *((unsigned char*)x+i));	
	}
	printf("dump_struct: [%s at 0x%08x] ", name, x);
	printf("a=%d ", x->a);
	printf("b=%f ", x->b);
	printf("c=0x%p ", x->c);
	if(x->c != NULL) {
		printf("'%s' ", x->c);
	}
	printf("d=0x%p ", x->d);
	printf("\n"); 

}

API_TEST_API int __stdcall mangle_simple_struct(simple_struct *x) {
	char *tmp;

	simple_struct mine;

	mine.a = 5;
	mine.b = 2.5;
	mine.c = NULL;
	mine.d = 0x12345678;

/* this generates too much noise during testing
	dump_struct("mine", &mine);
	dump_struct("yours", x);

*/
	x->a /= 2;
	x->b *= 2;
	x->d = ~x->d;

/*	tmp = (char *) malloc(strlen(x->c)); */
	tmp = x->c;
/*
	printf("x.a=%d\n", x->a);
	printf("x.b=%f\n", x->b);
	printf("x.c=0x%08x\n", x->c);
	printf("x.c='%s'\n", x->c);
*/
	// return 1;
	while(tmp[0] != 0) {
/*
		printf("char='%c' toupper='%c'\n", tmp[0], toupper(tmp[0]));
*/
		tmp[0] = toupper(tmp[0]);
		tmp++;
	}
/*
	printf("x.d=0x%08x\n", x->d);
*/
	return 1;
}

API_TEST_API int __stdcall do_callback(callback_func function, int value) {
	int r = function(value);
	printf("do_callback: returning %ld\n", r); 
	return r;
}

API_TEST_API int __stdcall do_callback_5_param(callback_func_5_param function) {
    four_char_struct fourCvar = {'J','A','P','H'};
	int r = function('P', 0x12345678ABCDEF12, &fourCvar, 2.5, 3.5);
	printf("do_callback_5_param: returning %ld\n", r); 
	return r;
}

API_TEST_API int __stdcall do_callback_5_param_cdec(callback_func_5_param_cdec function) {
    four_char_struct fourCvar = {'J','A','P','H'};
	int r ;
    r = function('P', 0x12345678ABCDEF12, &fourCvar, 2.5, 3.5);
	printf("do_callback_5_param_cdec: returning %ld\n", r); 
	return r;
}

API_TEST_API double __stdcall do_callback_void_d(callback_func_void_d function) {
	double r;
    r = function();
	printf("do_callback_void_d: returning %10.10lf\n", r); 
	return r;
}

API_TEST_API float __stdcall do_callback_void_f(callback_func_void_f function) {
	float r;
    r = function();
	printf("do_callback_void_f: returning %10.10f\n", r); 
	return r;
}

API_TEST_API unsigned __int64 __stdcall do_callback_void_q(callback_func_void_q function) {
	unsigned __int64 r;
    r = function();
	printf("do_callback_void_q: returning sgnd %I64d unsgnd %I64u\n", r, r); 
	return r;
}

API_TEST_API BOOL __stdcall GetHandle(LPHANDLE pHandle) {
	if(!IsBadReadPtr(pHandle, sizeof(*pHandle))){
        *pHandle =  (HANDLE)4000;
        return TRUE;
    }
    else return FALSE;
}
API_TEST_API void * __stdcall GetGetHandle() {
    return GetHandle;
}
API_TEST_API BOOL __stdcall FreeHandle(HANDLE Handle) {
    if(Handle == (HANDLE)4000) return TRUE;
    else return FALSE;
}

API_TEST_API void * __stdcall Take41Params(
    void * p0, void * p1, void * p2, void * p3,
    void * p4, void * p5, void * p6, void * p7,
    void * p8, void * p9, void * p10, void * p11,
    void * p12, void * p13, void * p14, void * p15,
    void * p16, void * p17, void * p18, void * p19,
    void * p20, void * p21, void * p22, void * p23,
    void * p24, void * p25, void * p26, void * p27,
    void * p28, void * p29, void * p30, void * p31,
    void * p32, void * p33, void * p34, void * p35,
    void * p36, void * p37, void * p38, void * p39,
    void * p40) {
    if (
   p0 != (void *)0 || p1 != (void *)1   || p2 != (void *)2   || p3 != (void *)3   || p4 != (void *)4
   || p5 != (void *)5   || p6 != (void *)6   || p7 != (void *)7   || p8 != (void *)8
   || p9 != (void *)9   || p10 != (void *)10   || p11 != (void *)11   || p12 != (void *)12
   || p13 != (void *)13   || p14 != (void *)14   || p15 != (void *)15   || p16 != (void *)16
   || p17 != (void *)17   || p18 != (void *)18   || p19 != (void *)19   || p20 != (void *)20
   || p21 != (void *)21   || p22 != (void *)22   || p23 != (void *)23   || p24 != (void *)24
   || p25 != (void *)25   || p26 != (void *)26   || p27 != (void *)27   || p28 != (void *)28
   || p29 != (void *)29   || p30 != (void *)30   || p31 != (void *)31   || p32 != (void *)32
   || p33 != (void *)33   || p34 != (void *)34   || p35 != (void *)35   || p36 != (void *)36
   || p37 != (void *)37   || p38 != (void *)38   || p39 != (void *)39   || p40 != (void *)40
    ){
        printf("One of the 40 In params was bad\n");
        memset(&p0, 255, ((char *)&p40)-((char *)&p0) + sizeof(void *));
        return (void *)0;
    }
    memset(&p0, 255, ((char *)&p40)-((char *)&p0) + sizeof(void *));
    return (void *)1;
}

API_TEST_API void * __stdcall Take253Params(
    void * p0, void * p1, void * p2, void * p3,
    void * p4, void * p5, void * p6, void * p7,
    void * p8, void * p9, void * p10, void * p11,
    void * p12, void * p13, void * p14, void * p15,
    void * p16, void * p17, void * p18, void * p19,
    void * p20, void * p21, void * p22, void * p23,
    void * p24, void * p25, void * p26, void * p27,
    void * p28, void * p29, void * p30, void * p31,
    void * p32, void * p33, void * p34, void * p35,
    void * p36, void * p37, void * p38, void * p39,
    void * p40, void * p41, void * p42, void * p43,
    void * p44, void * p45, void * p46, void * p47,
    void * p48, void * p49, void * p50, void * p51,
    void * p52, void * p53, void * p54, void * p55,
    void * p56, void * p57, void * p58, void * p59,
    void * p60, void * p61, void * p62, void * p63,
    void * p64, void * p65, void * p66, void * p67,
    void * p68, void * p69, void * p70, void * p71,
    void * p72, void * p73, void * p74, void * p75,
    void * p76, void * p77, void * p78, void * p79,
    void * p80, void * p81, void * p82, void * p83,
    void * p84, void * p85, void * p86, void * p87,
    void * p88, void * p89, void * p90, void * p91,
    void * p92, void * p93, void * p94, void * p95,
    void * p96, void * p97, void * p98, void * p99,
    void * p100, void * p101, void * p102, void * p103,
    void * p104, void * p105, void * p106, void * p107,
    void * p108, void * p109, void * p110, void * p111,
    void * p112, void * p113, void * p114, void * p115,
    void * p116, void * p117, void * p118, void * p119,
    void * p120, void * p121, void * p122, void * p123,
    void * p124, void * p125, void * p126, void * p127,
    void * p128, void * p129, void * p130, void * p131,
    void * p132, void * p133, void * p134, void * p135,
    void * p136, void * p137, void * p138, void * p139,
    void * p140, void * p141, void * p142, void * p143,
    void * p144, void * p145, void * p146, void * p147,
    void * p148, void * p149, void * p150, void * p151,
    void * p152, void * p153, void * p154, void * p155,
    void * p156, void * p157, void * p158, void * p159,
    void * p160, void * p161, void * p162, void * p163,
    void * p164, void * p165, void * p166, void * p167,
    void * p168, void * p169, void * p170, void * p171,
    void * p172, void * p173, void * p174, void * p175,
    void * p176, void * p177, void * p178, void * p179,
    void * p180, void * p181, void * p182, void * p183,
    void * p184, void * p185, void * p186, void * p187,
    void * p188, void * p189, void * p190, void * p191,
    void * p192, void * p193, void * p194, void * p195,
    void * p196, void * p197, void * p198, void * p199,
    void * p200, void * p201, void * p202, void * p203,
    void * p204, void * p205, void * p206, void * p207,
    void * p208, void * p209, void * p210, void * p211,
    void * p212, void * p213, void * p214, void * p215,
    void * p216, void * p217, void * p218, void * p219,
    void * p220, void * p221, void * p222, void * p223,
    void * p224, void * p225, void * p226, void * p227,
    void * p228, void * p229, void * p230, void * p231,
    void * p232, void * p233, void * p234, void * p235,
    void * p236, void * p237, void * p238, void * p239,
    void * p240, void * p241, void * p242, void * p243,
    void * p244, void * p245, void * p246, void * p247,
    void * p248, void * p249, void * p250, void * p251,
    void * p252) {
    void * ret;
    if (p252 == (void *)252 && p0 == (void *)0 && p130 == (void *)130) ret = (void *)1;
    else ret = (void *)0;
    memset(&p0, 255, ((char *)&p252)-((char *)&p0) + sizeof(void *));
    return ret;
}

/* cdecl functions */
API_TEST_API int __cdecl c_sum_integers(int a, int b) {
	return a + b;
}

API_TEST_API DWORD WINAPI 
WlanConnect(
    unsigned __int64 quad,
    HANDLE hClientHandle,
    CONST GUID *pInterfaceGuid, 
    CONST PWLAN_CONNECTION_PARAMETERS pConnectionParameters,
    PVOID pReserved
){
//{04030201-0605-0807-0910-111213141516}
static const GUID wlanguid  = 
{ 0x04030201, 0x0605, 0x0807, { 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16 } };
    if(quad != 0x8000000050000000
       ||hClientHandle != (HANDLE)0x12344321
       ||!IsEqualGUID(*&(wlanguid), *pInterfaceGuid)
       || pConnectionParameters->wlanConnectionMode != wlan_connection_mode_profile
       || memcmp(pConnectionParameters->strProfile,
                 L"TheProfileName", sizeof(L"TheProfileName")) != 0
       || pConnectionParameters->pDot11Ssid->uSSIDLength != sizeof("TheSSID")-1
       || memcmp(&(pConnectionParameters->pDot11Ssid->ucSSID), "TheSSID" ,sizeof("TheSSID")-1) != 0
       || pConnectionParameters->pDesiredBssidList != NULL
       || pConnectionParameters->dot11BssType != dot11_BSS_type_any
       || pConnectionParameters->dwFlags != WLAN_CONNECTION_HIDDEN_NETWORK
       || pReserved != (PVOID)0xF080F080
#ifdef WIN64
       || (DWORD_PTR)(&quad) % 16 != 0 //C stack alignment test for x64
#endif
       ){
        DebugBreak();
	return ERROR_INVALID_ADDRESS;
    }
    else{
	return ERROR_SUCCESS;
    }
}


API_TEST_API DWORD WINAPI
MyGetTimeZoneInformation(
    LPTIME_ZONE_INFORMATION lpTimeZoneInformation
) {
    if(IsBadWritePtr(lpTimeZoneInformation, sizeof(TIME_ZONE_INFORMATION)))
        return 0;
    lpTimeZoneInformation->Bias = 1;
    memcpy(lpTimeZoneInformation->StandardName,  L"vwxyzvwxyzvwxyzvwxyzvwxyzvwxyzwx",
           sizeof(L"vwxyzvwxyzvwxyzvwxyzvwxyzvwxyzwx"));
    lpTimeZoneInformation->StandardDate.wYear = 1;
    lpTimeZoneInformation->StandardDate.wMonth = 2;
    lpTimeZoneInformation->StandardDate.wDayOfWeek = 3;
    lpTimeZoneInformation->StandardDate.wDay = 4;
    lpTimeZoneInformation->StandardDate.wHour = 5;
    lpTimeZoneInformation->StandardDate.wMinute = 6;
    lpTimeZoneInformation->StandardDate.wSecond = 7;
    lpTimeZoneInformation->StandardDate.wMilliseconds = 8;
    lpTimeZoneInformation->StandardBias = 2;
    memcpy(lpTimeZoneInformation->DaylightName,  L"DAYLNDAYLNDAYLNDAYLNDAYLNDAYLNDA",
           sizeof(L"DAYLNDAYLNDAYLNDAYLNDAYLNDAYLNDA"));
    lpTimeZoneInformation->DaylightDate.wYear = 1;
    lpTimeZoneInformation->DaylightDate.wMonth = 2;
    lpTimeZoneInformation->DaylightDate.wDayOfWeek = 3;
    lpTimeZoneInformation->DaylightDate.wDay = 4;
    lpTimeZoneInformation->DaylightDate.wHour = 5;
    lpTimeZoneInformation->DaylightDate.wMinute = 6;
    lpTimeZoneInformation->DaylightDate.wSecond = 7;
    lpTimeZoneInformation->DaylightDate.wMilliseconds = 8;
    lpTimeZoneInformation->DaylightBias = 3;
    return 1;
}

API_TEST_API DWORD WINAPI
MySetTimeZoneInformation(
    LPTIME_ZONE_INFORMATION lpTimeZoneInformation
) {
    if(IsBadReadPtr(lpTimeZoneInformation, sizeof(TIME_ZONE_INFORMATION)))
        return 0;
    if( lpTimeZoneInformation->Bias == 1
        && memcmp(lpTimeZoneInformation->StandardName,  L"vwxyzvwxyzvwxyzvwxyzvwxyzvwxyzwx",
              sizeof(L"vwxyzvwxyzvwxyzvwxyzvwxyzvwxyzwx")-2) == 0
        && lpTimeZoneInformation->StandardDate.wYear == 1
        && lpTimeZoneInformation->StandardDate.wMonth == 2
        && lpTimeZoneInformation->StandardDate.wDayOfWeek == 3
        && lpTimeZoneInformation->StandardDate.wDay == 4
        && lpTimeZoneInformation->StandardDate.wHour == 5
        && lpTimeZoneInformation->StandardDate.wMinute == 6
        && lpTimeZoneInformation->StandardDate.wSecond == 7
        && lpTimeZoneInformation->StandardDate.wMilliseconds == 8
        && lpTimeZoneInformation->StandardBias == 2
        && memcmp(lpTimeZoneInformation->DaylightName,  L"DAYLNDAYLNDAYLNDAYLNDAYLNDAYLNDA",
              sizeof(L"DAYLNDAYLNDAYLNDAYLNDAYLNDAYLNDA")-2) == 0
        && lpTimeZoneInformation->DaylightDate.wYear == 1
        && lpTimeZoneInformation->DaylightDate.wMonth == 2
        && lpTimeZoneInformation->DaylightDate.wDayOfWeek == 3
        && lpTimeZoneInformation->DaylightDate.wDay == 4
        && lpTimeZoneInformation->DaylightDate.wHour == 5
        && lpTimeZoneInformation->DaylightDate.wMinute == 6
        && lpTimeZoneInformation->DaylightDate.wSecond == 7
        && lpTimeZoneInformation->DaylightDate.wMilliseconds == 8
        && lpTimeZoneInformation->DaylightBias == 3)
        return 1;
    else
        return 0;
}

API_TEST_API void __stdcall WriteArrayInStruct(ARR_IN_STRUCT * s){
    s->first = 0xFFFFFFFF;
    memcpy(s->str, "12345123451234512345\0\0\0\0\0\0\0\0\0\0\0\0",
            sizeof("12345123451234512345\0\0\0\0\0\0\0\0\0\0\0\0")-1);
    s->last = 0xFFFFFFFF;
}

API_TEST_API void __stdcall WriteWArrayInStruct(WARR_IN_STRUCT * s){
    s->first = 0xFFFFFFFF;
    memcpy(s->str, L"12345123451234512345\0\0\0\0\0\0\0\0\0\0\0\0",
            sizeof(L"12345123451234512345\0\0\0\0\0\0\0\0\0\0\0\0")-2);
    s->last = 0xFFFFFFFF;
}

API_TEST_API BOOL __stdcall Take6MemsStruct( SIX_MEMS str){
    if(str.one == 1
       && str.two == 2
       && str.three == 3
       && str.four == 4
       && str.five == 5
       && str.six == 6.0)
        return TRUE;
    else
        return FALSE;
}
typedef struct {
    PWLAN_CONNECTION_PARAMETERS params;
} WLANPARAMCONTAINER;

static const DOT11_SSID Dot11SsidVar = {
    sizeof("TheFilledSSID")-1,
    "TheFilledSSID"
};

static const WLAN_CONNECTION_PARAMETERS s_Wlan_params = {
    wlan_connection_mode_profile,
    L"FilledTheProfileName",
    (DOT11_SSID *)&Dot11SsidVar,
    NULL,
    dot11_BSS_type_any,
    1
};
API_TEST_API void __stdcall GetConParams(BOOL Fill, WLANPARAMCONTAINER * param){
    if(Fill){
        param->params = (WLAN_CONNECTION_PARAMETERS *)&s_Wlan_params;
    }
    else{
        param->params = NULL;
    }
}
API_TEST_API BOOL __stdcall MyQueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCount){
    return QueryPerformanceCounter(lpPerformanceCount);
}

API_TEST_API HMODULE __stdcall GetTestDllHModule(void){
    return g_hModule;
}
API_TEST_API char * __stdcall setlasterror_loop(int iterations){
    /*sloppy code, no buffer overrun prevention */
    int i;
    LARGE_INTEGER start;
    BOOL startbool;
    LARGE_INTEGER end;
    BOOL endbool;
    LARGE_INTEGER freq;
    BOOL freqbool;
    double delta;
    static char msg [256] = {0};
    freqbool = QueryPerformanceFrequency(&freq);
    if(! freqbool) DebugBreak();
    startbool = QueryPerformanceCounter(&start);
    for(i = 0; i < iterations; i++){
        SetLastError(1);
    }
    endbool = QueryPerformanceCounter(&end);
    if(!startbool || !endbool) DebugBreak();
    delta = (double)(end.QuadPart - start.QuadPart)/(double)(freq.QuadPart);
    sprintf(msg, "time was %.17f secs, %.17f ms per C call", delta, (delta/(double)iterations)*1000);
    return (char *)msg;
}

API_TEST_API int __stdcall is_null(void * ptr){
    if(!ptr) return TRUE;
    else return FALSE;
}

/* enlarge .text from Virtual Size 0xF34 which is pretty close to 0x1000,
   to 0x1024 Virtual size so that .text is 0x1400 bytes long in the PE file to
   allow room for API_test.dll to grow with large git diffs, .rdata starts at
   0x3000 instead of 0x2000 with this padding, which means pointers to .rdata
   won't change in future recompiles of this dll because there is atleast
   4 KB of space between the end of .text and start of .rdata

   The amount of nulls bytes here can be reduced in the future if API_test
   gains new functions
*/
#pragma code_seg(push, ".text")
__declspec(allocate(".text")) char code_padding []=
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
#pragma code_seg(pop)
