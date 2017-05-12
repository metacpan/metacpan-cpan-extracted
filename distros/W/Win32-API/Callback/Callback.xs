/*
    # Win32::API::Callback - Perl Win32 API Import Facility
    #
    # Original Author: Aldo Calpini <dada@perl.it>
    # Rewrite Author: Daniel Dragan <bulk88@hotmail.com>
    # Maintainer: Cosimo Streppone <cosimo@cpan.org>
    #
    # Other Credits:
    # Changes for gcc/cygwin by Reini Urban <rurban@x-ray.at>  (code removed)
    #
    # $Id$
 */

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <memory.h>

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"

//undo perl messing with stdio
//perl's stdio emulation layer is not OS thread safe
#define NO_XSLOCKS
#include "XSUB.h"
#define CROAK croak

#ifndef _WIN64
#define WIN32BIT
#define WIN32BITBOOL 1
#else
#define WIN32BITBOOL 0
#endif


#include "../API.h"

#define IMAGE_SNAP_BY_ORDINAL_CAST(x) IMAGE_SNAP_BY_ORDINAL((DWORD_PTR) x )
#define IMAGE_ORDINAL_CAST(x) IMAGE_ORDINAL((DWORD_PTR) x )

//older VSes dont have this flag
#ifndef HEAP_CREATE_ENABLE_EXECUTE
#define HEAP_CREATE_ENABLE_EXECUTE      0x00040000
#endif

HANDLE execHeap;

/*dont run CRT init code on MSVC, see note in API.xs*/
#ifdef _MSC_VER
BOOL WINAPI _DllMainCRTStartup(
#else
BOOL WINAPI DllMain(
#endif
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    switch( fdwReason ) 
    { 
        case DLL_PROCESS_ATTACH:
            DISABLE_T_L_CALLS;
            execHeap = HeapCreate(HEAP_CREATE_ENABLE_EXECUTE
                              | HEAP_GENERATE_EXCEPTIONS, 0, 0);
            if(!execHeap) return FALSE;
            break;
        case DLL_PROCESS_DETACH:
            return HeapDestroy(execHeap);
            break;
    }
    return TRUE;
}



/*
 * some Perl macros for backward compatibility
 */
#ifdef NT_BUILD_NUMBER
#define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

#ifndef SvPV_nolen
#	define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#ifndef call_pv
#	define call_pv(name, flags) perl_call_pv(name, flags)
#endif

#ifndef call_sv
#	define call_sv(name, flags) perl_call_sv(name, flags)
#endif

#ifdef WIN32BIT
typedef struct {
    unsigned short unwind_len;
    unsigned char F_Or_D;
    unsigned char unused;
} FuncRtnCxt;

#if 0
////the template used in the MakeCB for x86
unsigned __int64 CALLBACK CallbackTemplate2() {
    void (*PerlCallback)(SV *, void *, unsigned __int64 *, FuncRtnCxt *) = 0xC0DE0001;
    FuncRtnCxt FuncRtnCxtVar;
    unsigned __int64 retval;
    PerlCallback((SV *)0xC0DE0002, (void*)0xC0DE0003, &retval, &FuncRtnCxtVar);
    return retval;
}


typedef union {
    float f;
    double d;
} FDUNION;


////the template used in the MakeCB for x86
double CALLBACK CallbackTemplateD() {
    void (*PerlCallback)(SV *, void *, unsigned __int64 *, FuncRtnCxt *) = 0xC0DE0001;
    FuncRtnCxt FuncRtnCxtVar;
    FDUNION retval;
    PerlCallback((SV *)0xC0DE0002, (void*)0xC0DE0003, (unsigned __int64 *)&retval, &FuncRtnCxtVar);
    if(FuncRtnCxtVar.F_Or_D){
        return (double) retval.f;
    }
    else{
        return retval.d;        
    }
}
#endif //#if 0
#endif

////unused due to debugger callstack corruption
////alternate design was implemented
//#ifdef _WIN64
//
//#pragma optimize( "y", off)
//////the template used in the MakeCBx64
//void * CALLBACK CallbackTemplate64fin( void * a
//                                      //, void * b, void * c, void * d
//                                      , ...
//                                      ) {
//    void (*LPerlCallback)(SV *, void *, unsigned __int64 *, void *) =
//    ( void (*)(SV *, void *, unsigned __int64 *, void *)) 0xC0DE00FFFF000001;
//    __m128 arr [4];
//    __m128 retval;
//     arr[0].m128_u64[0] = 0xFFFF00000000FF10;
//     arr[0].m128_u64[1] = 0xFFFF00000000FF11;
//     arr[1].m128_u64[0] = 0xFFFF00000000FF20;
//     arr[1].m128_u64[1] = 0xFFFF00000000FF21;
//     arr[2].m128_u64[0] = 0xFFFF00000000FF30;
//     arr[2].m128_u64[1] = 0xFFFF00000000FF31;
//     arr[3].m128_u64[0] = 0xFFFF00000000FF40;
//     arr[3].m128_u64[1] = 0xFFFF00000000FF41;
//
//    LPerlCallback((SV *)0xC0DE00FFFF000002, (void*) arr, (unsigned __int64 *)&retval,
//                  (DWORD_PTR)&a);
//    return *(void **)&retval;
//}
//#pragma optimize( "", on )
//#endif

#ifdef WIN32BIT
typedef unsigned __int64 CBRETVAL; //8 bytes
#else
//using a M128 SSE variable casues VS to use aligned SSE movs, Perl's malloc
//(ithread mempool tracking included) on x64 apprently aligns to 8 bytes,
//not 16, then it crashes so DONT use a SSE type, even though it is
typedef struct {
    char arr[16];
} CHAR16ARR;
typedef CHAR16ARR CBRETVAL; //16 bytes
#endif

void PerlCallback(SV * obj, void * ebp, CBRETVAL * retval
#ifdef WIN32BIT               
                  ,FuncRtnCxt * rtncxt
#endif                  
                  ) {
    dTHX;
#if defined(USE_ITHREADS)
    {
        if(aTHX == NULL) {
            //due to NO_XSLOCKS, these are real CRT and not perl stdio hooks
            fprintf(stderr, "Win32::API::Callback (XS) no perl interp "
                   "in thread id %u, callback can not run\n", GetCurrentThreadId());
            //can't return safely without stack unwind count from perl on x86,
            //so exit thread is next safest thing, some/most libs will leak
            //from this
            ExitThread(0); // 0 means failure? IDK.
        }
    }
#endif
    {
	dSP;
    SV * retvalSV;
#ifdef WIN32BIT
    SV * unwindSV;
    SV * F_Or_DSV;
#endif
	ENTER;
    SAVETMPS;
	PUSHMARK(SP);
    EXTEND(SP, (WIN32BITBOOL?5:3));
    mPUSHs(newRV_inc((SV*)obj));
    mPUSHs(newSVuv((UV)ebp));
    retvalSV = sv_newmortal();
	PUSHs(retvalSV);
#ifdef WIN32BIT
    unwindSV = sv_newmortal();
    PUSHs(unwindSV);
    F_Or_DSV = sv_newmortal();
    PUSHs(F_Or_DSV);
#endif
	PUTBACK;
	call_pv("Win32::API::Callback::RunCB", G_VOID);
#ifdef WIN32BIT
    rtncxt->F_Or_D = (unsigned char) SvUV(F_Or_DSV);
    rtncxt->unwind_len = (unsigned short) SvUV(unwindSV);
#endif
    //pad out the buffer, uninit irrelavent
    *retval = *(CBRETVAL *)SvGROW(retvalSV, sizeof(CBRETVAL));
    FREETMPS;
	LEAVE;
    return;
    }
}

#ifdef _WIN64

//on entry R10 register must be a HV *
//, ... triggers copying to shadow space the 4 param registers on VS
//relying on compiler to not optimize away copying void *s b,c,d to shadow space
void CALLBACK Stage2CallbackX64( void * a
                                      //, void * b, void * c, void * d
                                      , ...
                                      ) {
    //CONTEXT is a macro in Perl, can't use it
    struct _CONTEXT cxt;
    CBRETVAL retval; //RtlCaptureContext is using a bomb to light a cigarette
    //a more efficient version is to write this in ASM, but that means GCC and
    //MASM versions, this func is pure C, "struct _CONTEXT cxt;" is 1232 bytes
    //long, pure hand written machine code in a string, like the jump trampoline
    //corrupts the callstack in VS 2008, RtlAddFunctionTable is ignored by VS
    //2008 but not WinDbg, but WinDbg is impossibly hard to use, if its not
    //in a DLL enumeratable by ToolHelp/Process Status API, VS won't see it
    //I tried a MMF of a .exe, the pages were formally backed by a copy of the
    //original .exe, VMMap verified, did a RtlAddFunctionTable, VS 2008 ignored
    //it, having Win32::API::Callback generate 1 function 1 time use DLLs from
    //a binary blob template in pure Perl is possible but insane
    RtlCaptureContext(&cxt); //null R10 in context is a flag to return
    if(!cxt.R10){//stack unwinding is not done
        return; //by callee on x64 so all funcs are vararg/cdecl safe
    }
    //don't assume there aren't any secret variables or secret alignment padding
    //, security cookie, etc, dont try to hard code &cxt-&a into a perl const sub
    //C compiler won't produce such a offset unless you run callbacktemplate live
    //calculating the offset in C watch window and hard coding it is going to
    //break in the future
    cxt.Rax = (unsigned __int64) &a;
    PerlCallback((SV *) cxt.R10, (void*) &cxt, &retval);
    cxt.Rax = *(unsigned __int64 *)&retval;
    cxt.Xmm0 = *(M128A *)&retval;
    cxt.R10 = (unsigned __int64)NULL; //trigger a return
    RtlRestoreContext(&cxt, NULL);//this jumps to the RtlCaptureContext line
    //unreachable
}
#endif


#if defined(USE_ITHREADS)
//Code here to make a inter thread refcount to deal with ithreads cloning
//to prevent a double free
    
int HeapBlockMgDup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    InterlockedIncrement((LONG *)mg->mg_ptr);
    return 1;
}
const static struct mgvtbl vtbl_HeapBlock = {
    NULL, NULL, NULL, NULL, NULL, NULL, HeapBlockMgDup, NULL, 
};
#endif

/* loops through the import table of a DLL, if the target import func is found
  it will be replaced, if OldFunc not null, old func ptr will be placed in OldFunc.
  On failure returns FALSE and error is in GLR. oldFunc is the only parameter
  which may be NULL. ImportFunctionName is treated as an ordinal if it is not
  POK*/
static BOOL PatchIAT(pTHX_ PIMAGE_DOS_HEADER dosHeader, SV * ImportDllName,
    SV * ImportFunctionName, void ** oldFunc, void * newFunc){
#define APPRVA2ABS(x) ((DWORD_PTR)dosHeader + (DWORD_PTR)(x))
    if( dosHeader
    && !IsBadReadPtr(dosHeader, sizeof(*dosHeader))
    && dosHeader->e_magic == IMAGE_DOS_SIGNATURE){
        PIMAGE_NT_HEADERS ntHeader = (PIMAGE_NT_HEADERS)APPRVA2ABS(dosHeader->e_lfanew);
        if( ntHeader
        && !IsBadReadPtr(ntHeader, sizeof(*ntHeader))
        && ntHeader->Signature == IMAGE_NT_SIGNATURE
        && ntHeader->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR_MAGIC
        //not a OBJ file, bug below if some of the entrys are not present?
        && ntHeader->FileHeader.SizeOfOptionalHeader >= sizeof(IMAGE_OPTIONAL_HEADER)
        && ntHeader->OptionalHeader.NumberOfRvaAndSizes >= IMAGE_DIRECTORY_ENTRY_IMPORT+1
        ){
            DWORD pDataDirImportRVA = ntHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
            DWORD pDataDirImportSize = ntHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;
            PIMAGE_IMPORT_DESCRIPTOR importDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)APPRVA2ABS(pDataDirImportRVA);
            if(pDataDirImportSize
               && pDataDirImportRVA
               && !IsBadReadPtr(importDescriptor, pDataDirImportSize)){
STRLEN DllNameLen;
char * DllNameStr = SvPV(ImportDllName, DllNameLen);
while (importDescriptor->Name != 0){
    const char * const TargetDllNameStr = (char *)APPRVA2ABS(importDescriptor->Name);
    const int TargetDllNameLen = lstrlenA(TargetDllNameStr); /*lstrlenA has SEH, strlen doesn't*/
#ifdef WIN32_API_DEBUG                                                              
    Perl_warn(aTHX_ "IATPatch::new saw app import dep dll name %s\n", TargetDllNameStr);
#endif
    if(TargetDllNameLen == 0) goto NO_MORE_LIBS;
    if(TargetDllNameLen == DllNameLen
        && strnicmp(TargetDllNameStr, DllNameStr, TargetDllNameLen) == 0
        && importDescriptor->OriginalFirstThunk
        && importDescriptor->FirstThunk
    ){
        PIMAGE_THUNK_DATA OriginalFirstThunk;
        void ** FirstThunk;
        STRLEN FunctionNameLen;
        char * FunctionNameStr;
        SvGETMAGIC(ImportFunctionName);
        if(SvPOK(ImportFunctionName)){
            FunctionNameStr = SvPV_nomg(ImportFunctionName, FunctionNameLen);
            if(IMAGE_SNAP_BY_ORDINAL_CAST(FunctionNameStr)) croak("IATPatch 3GB mode not supported");
        }
        else{ /*is an ordinal*/ 
            FunctionNameStr = (char *) (IMAGE_ORDINAL_FLAG | (DWORD_PTR)SvIV_nomg(ImportFunctionName));
        }/*XXX should we croak if not IOK but NOK or ROK?*/
        OriginalFirstThunk = (PIMAGE_THUNK_DATA)APPRVA2ABS(importDescriptor->OriginalFirstThunk);
        FirstThunk = (void**)APPRVA2ABS(importDescriptor->FirstThunk);
/*note only the first slice in the array is probed, they others should be valid if the 1st one is*/
        if(! IsBadReadPtr(OriginalFirstThunk, sizeof(IMAGE_THUNK_DATA))
           && ! IsBadReadPtr(FirstThunk, sizeof(void *))){
            while(OriginalFirstThunk->u1.ForwarderString != 0){
                /*ordinal status of want == ordinal status of have entry*/
                if(IMAGE_SNAP_BY_ORDINAL_CAST(FunctionNameStr) == IMAGE_SNAP_BY_ORDINAL(OriginalFirstThunk->u1.Ordinal)){
/*want ordinal*/    if(IMAGE_SNAP_BY_ORDINAL_CAST(FunctionNameStr)){
/*ordinals match*/      if(IMAGE_ORDINAL_CAST(FunctionNameStr)
                           == IMAGE_ORDINAL_CAST(OriginalFirstThunk->u1.Ordinal))
                            goto FOUND_IMPORT_ENTRY;
                    }/*end of want ordinal*/
/*want name*/       else{ 
PIMAGE_IMPORT_BY_NAME TargetImport = (PIMAGE_IMPORT_BY_NAME)APPRVA2ABS(OriginalFirstThunk->u1.AddressOfData);
char * TargetFunctionNameStr = TargetImport->Name;
int TargetFunctionNameLen = lstrlenA(TargetFunctionNameStr); /*lstrlenA has SEH, strlen doesn't*/
if(TargetFunctionNameLen == FunctionNameLen
   && memcmp(TargetFunctionNameStr, FunctionNameStr, TargetFunctionNameLen) == 0){
    FOUND_IMPORT_ENTRY:
    if(oldFunc) *oldFunc = *FirstThunk;
    if(IsBadWritePtr(FirstThunk, sizeof(void *))){ /*dont touch page flags unless mandatory*/
        DWORD newProtectFlag, oldProtectFlag;
        MEMORY_BASIC_INFORMATION mbi;    
        if(!VirtualQuery(FirstThunk, &mbi, sizeof(mbi) )) goto ERROR;
        newProtectFlag = mbi.Protect;
        newProtectFlag &= ~(PAGE_READONLY | PAGE_EXECUTE_READ);
        newProtectFlag |= PAGE_READWRITE;
        if (!VirtualProtect(FirstThunk, sizeof(void *), newProtectFlag, &oldProtectFlag)) goto ERROR;
        *FirstThunk = newFunc;    
        if (!VirtualProtect(FirstThunk, sizeof(void *), oldProtectFlag, &newProtectFlag)) goto ERROR;
        return TRUE;
    }
    *FirstThunk = newFunc;
    return TRUE;
}
                }/*end of want name*/
                }/*end of ordinal status test*/
#ifdef WIN32_API_DEBUG
/*this dont not print all import dll names and func names, only the ones seen
until the import we want to patch is found, if the import we want is not found,
then you see all of them
*/
                if(IMAGE_SNAP_BY_ORDINAL(OriginalFirstThunk->u1.Ordinal))
                    Perl_warn(aTHX_ "IATPatch::new saw app import dep ordinal %u\n",
                         IMAGE_ORDINAL_CAST(OriginalFirstThunk->u1.Ordinal));
                else{
                    PIMAGE_IMPORT_BY_NAME TargetImport = (PIMAGE_IMPORT_BY_NAME)APPRVA2ABS(OriginalFirstThunk->u1.AddressOfData);
                    char * TargetFunctionNameStr = TargetImport->Name;
                    int TargetFunctionNameLen = lstrlenA(TargetFunctionNameStr); /*lstrlenA has SEH, strlen doesn't*/
                    Perl_warn(aTHX_ "IATPatch::new saw app import dep func name %s\n"
                              , TargetFunctionNameLen? TargetFunctionNameStr : "is NULL" );
                }
#endif
                
                OriginalFirstThunk++;
                FirstThunk++;
            }
        }
        SetLastError(IMAGE_SNAP_BY_ORDINAL_CAST(FunctionNameStr) ? ERROR_INVALID_ORDINAL : ERROR_PROC_NOT_FOUND);
        goto ERROR;
    }
    importDescriptor++;
}
    NO_MORE_LIBS:
    SetLastError(ERROR_MOD_NOT_FOUND);
    goto ERROR;
}
}
}
    SetLastError(ERROR_BAD_EXE_FORMAT);
    ERROR:
    return FALSE;
#undef APPRVA2ABS
}

MODULE = Win32::API::Callback   PACKAGE = Win32::API::Callback

PROTOTYPES: DISABLE

BOOT:
{
    SV * PtrHolder = get_sv("Win32::API::Callback::Stage2FuncPtrPkd", 1);
#ifdef _WIN64
    void * p = (void *)Stage2CallbackX64;
    HV *stash;
#else
    void * p = (void *)PerlCallback;
#endif
    sv_setpvn(PtrHolder, (char *)&p, sizeof(void *)); //gen a packed value
#ifdef _WIN64
    stash = gv_stashpv("Win32::API::Callback", TRUE);
    newCONSTSUB(stash, "CONTEXT_XMM0", newSViv(offsetof(struct  _CONTEXT, Xmm0)));
    newCONSTSUB(stash, "CONTEXT_RAX", newSViv(offsetof(struct  _CONTEXT, Rax)));
#endif
}

void
PackedRVTarget(sv)
    SV * sv
PPCODE:
    mPUSHs(newSVpvn((char*)&(SvRV(sv)), sizeof(SV *)));

#if IVSIZE == 4

void
UseMI64(...)
PREINIT:
    SV * flag;
    HV * self;
    SV * old_flag;
PPCODE:
    if (items < 1 || items > 2)
       croak_xs_usage(cv,  "self [, FlagBool]");
    self = (HV*)ST(0);
	if (!(SvROK((SV*)self) && ((self = (HV*)SvRV((SV*)self)), SvTYPE((SV*)self) == SVt_PVHV)))
        Perl_croak(aTHX_ "%s: %s is not a hash reference",
			"Win32::API::Callback::UseMI64",
			"self");
    //dont create one if doesn't exist
    old_flag = (SV*)hv_fetch(self, "UseMI64", sizeof("UseMI64")-1, 0);
    if(old_flag) old_flag = *(SV **)old_flag;
    PUSHs(boolSV(sv_true(old_flag))); //old_flag might be NULL, ST(0) now gone
    
    if(items == 2){
        flag = boolSV(sv_true(ST(1)));
        hv_store(self, "UseMI64", sizeof("UseMI64")-1, flag, 0);
    }
    

#endif


# MakeParamArr is written without null checks or lvalue=true since
# the chance of crashing is zero unless someone messed with the PM file and
# broke it, this isn't a public sub, putting in null checking
# and croaking if null is a waste of resources, if someone is
# modifying ::Callback, the crash will
# alert them to their errors similar to an assert(), but without the cost of
# asserts or lack of them in non-debugging builds
#
# all parts of MakeParamArr must be croak safe, all SVs must be mortal where
# appropriate, the type letters are from the user, they are not sanitized,
# so group upper and lower together where 1 of the letters is meaningless
#
# arr is emptied out of elements/cleared/destroyed by this sub, so Dumper() it
# before this is called for debugging if you want but not after calling this
void
MakeParamArr( self, arr)
    HV * self
    AV * arr
PREINIT:
    AV * retarr = (AV*)sv_2mortal((SV*)newAV()); //croak possible
    int iTypes;
    AV * Types;
    I32 lenTypes;
#if (PERL_VERSION_LE(5, 8, 0))
    SV * unpacktypeSV = sv_newmortal();
#endif
PPCODE:
    //intypes array ref is always created in PM file
    Types = (AV*)SvRV(*hv_fetch(self, "intypes", sizeof("intypes")-1, 0));
    lenTypes = av_len(Types)+1;
    for(iTypes=0;iTypes < lenTypes;iTypes++){
        SV * typeSV = *av_fetch(Types, iTypes, 0);
        char type = *SvPVX(typeSV);
//both are never used on 64 bits
#ifdef T_QUAD
#define MK_PARAM_OP_8B 0x1
#endif
#ifdef USEMI64
#define MK_PARAM_OP_32BIT_QUAD 0x2
#endif
        char op = 0;
        SV * packedParamSV;
        char * packedParam;
        SV * unpackedParamSV;
        switch(type){
        case 's':
        case 'S':
            croak("Win32::API::Callback::MakeParamArr type letter \"S\" and"
                  " struct support not implemented");
            //in Perl this would be #push(@arr, MakeStruct($self, $i, $packedparam));
            //but ::Callback doesn't have C prototype type parsing
            //intypes arr is letters not C types
            break;
        case 'I': //type is already the correct unpack letter
        case 'i':
            break;
        case 'F':
            type = 'f';
        case 'f':
            break;
        case 'D':
            type = 'd';
        case 'd':
#if PTRSIZE == 4
                op = MK_PARAM_OP_8B;
#endif
            break;
        case 'N':
        case 'L':
#ifndef T_QUAD
        case 'Q':
#endif
#if PTRSIZE == 4
            type = 'L';
#else
            type = 'Q';
#endif
            break;
        case 'n':
        case 'l':
#ifndef T_QUAD
        case 'q':
#endif
#if PTRSIZE == 4
            type = 'l';
#else
            type = 'q';
#endif
            break;
#ifdef T_QUAD
        case 'q':
        case 'Q':
#ifdef USEMI64
            op = MK_PARAM_OP_32BIT_QUAD | MK_PARAM_OP_8B;
#else
            op = MK_PARAM_OP_8B;
#endif
            break;
#endif
        case 'P': //p/P are not documented and not implemented as a Callback ->
            type = 'p'; //return type, as "in" type probably works but this is 
        case 'p': //untested
            break;
        default:
            croak("Win32::API::Callback::MakeParamArr "
                  "\"in\" parameter %d type letter \"%c\" is unknown", iTypes+1, type);
        }
        
        packedParamSV = sv_2mortal(av_shift(arr));
#ifdef T_QUAD
        if(op & MK_PARAM_OP_8B)
            sv_catsv_nomg(packedParamSV, sv_2mortal(av_shift(arr)));
#endif
#ifdef USEMI64
        if((op & MK_PARAM_OP_32BIT_QUAD) == 0){
#endif
        packedParam = SvPVX(packedParamSV);
        if(type == 'p'){ //test if acc vio before a null is found, ret undef then
            if(IsBadStringPtr(packedParam, ~0)){
                unpackedParamSV = &PL_sv_undef;
            }
            else{
                unpackedParamSV = newSVpv(packedParam, 0);
            }
            goto HAVEUNPACKED;
        }
#if ! (PERL_VERSION_LE(5, 8, 0))
        PUTBACK;    
        unpackstring(&type, &type+1, packedParam, packedParam+SvCUR(packedParamSV), 0);
#else /* dont have unpackstring */
        PUSHMARK(SP);
        PUSHs(unpacktypeSV);
        PUSHs(packedParamSV);
        PUTBACK;
        sv_setpvn(unpacktypeSV,&type, 1);
        call_pv("Win32::API::Callback::_CallUnpack", G_SCALAR);
#endif
        SPAGAIN;
        unpackedParamSV = POPs;
#ifdef USEMI64
        }
        else{//have MK_PARAM_OP_32BIT_QUAD
            SV ** tmpsv = hv_fetch(self, "UseMI64", sizeof("UseMI64")-1, 0);
            if(tmpsv && sv_true(*tmpsv)){
                ENTER;
                PUSHMARK(SP); //stack extend not needed since we got 2 params
                //on the stack already from caller, so stack minimum 2 long
                PUSHs(packedParamSV); //currently mortal
                PUTBACK; //don't check return count, assume its 1
                call_pv(type == 'Q' ? "Math::Int64::native_to_uint64":
                        "Math::Int64::native_to_int64", G_SCALAR);
                SPAGAIN;
                unpackedParamSV = POPs; //this is also mortal
                LEAVE;
            }
            else{//pass through the 8 byte packed string
                unpackedParamSV = packedParamSV;
            }
        }
#endif //USEMI64
        SvREFCNT_inc_simple_NN(unpackedParamSV);//cancel the mortal
        HAVEUNPACKED: //used by 'p'/'P' for returning undef or a SVPV
        av_push(retarr, unpackedParamSV);
    }
    mPUSHs(newRV_inc((SV*)retarr)); //cancel the mortal, no X needed bc 2 in params
#ifdef T_QUAD
#undef MK_PARAM_OP_8B
#endif
#ifdef USEMI64
#undef MK_PARAM_OP_32BIT_QUAD
#endif

MODULE = Win32::API::Callback   PACKAGE = Win32::API::Callback::HeapBlock

void
new(classSV, size)
    SV * classSV
    UV size
PREINIT:
    SV * newSVUVVar;
    char * block;
#if defined(USE_ITHREADS)
    MAGIC * mg;
    int alignRemainder;
#endif
PPCODE:
    //Code here to make a inter thread refcount to deal with ithreads cloning
    //to prevent a double free
#if defined(USE_ITHREADS)
    alignRemainder = (size % sizeof(LONG)); //4%4 = 0, we are aligned
    size += sizeof(LONG) + (alignRemainder ? sizeof(LONG)-alignRemainder : 0);
#endif
    block = HeapAlloc(execHeap, 0, size);
    newSVUVVar = newSVuv((UV)block);
#if defined(USE_ITHREADS)
    mg = sv_magicext(newSVUVVar, NULL, PERL_MAGIC_ext,&vtbl_HeapBlock,NULL,0);
    mg->mg_flags |= MGf_DUP;
    mg->mg_ptr = block+size-sizeof(LONG);
    *((LONG *)mg->mg_ptr) = 1; //initial reference count
#endif
    mXPUSHs(sv_bless(newRV_noinc(newSVUVVar),
                    gv_stashsv(classSV,0)
                    )
           );

void
DESTROY( ptr_obj )
    SV * ptr_obj
PREINIT:
    SV * SVUVVar;
#if defined(USE_ITHREADS)
    LONG refcnt;
    MAGIC * mg;
#endif
PPCODE:
    //Code here to make a inter thread refcount to deal with ithreads cloning
    //to prevent a double free
    SVUVVar = SvRV(ptr_obj);
#if defined(USE_ITHREADS)
    mg = mg_findext(SVUVVar, PERL_MAGIC_ext,&vtbl_HeapBlock);    
    refcnt = InterlockedDecrement((LONG *) mg->mg_ptr);
    if(refcnt == 0 ){ //if -1 or -2, means another thread will free it
#endif
    HeapFree(execHeap, 0, (LPVOID)SvUV(SVUVVar));
#if defined(USE_ITHREADS)
    }
#endif

MODULE = Win32::API::Callback   PACKAGE = Win32::API::Callback::IATPatch

void
new(classSV, callback, HookDll, ImportDllName, ImportFunctionName)
    SV * classSV
    W32AC_T * callback
    SV * HookDll
    SV * ImportDllName
    SV * ImportFunctionName
PREINIT:
    PIMAGE_DOS_HEADER dosHeader;
    HV * returnHV;
    void * oldFunction;
    char * HookDllName;
PPCODE:
    SvGETMAGIC(HookDll);
    if(SvPOK(HookDll)){
        HookDllName = SvPV_nomg_nolen(HookDll);
        goto USE_GMH;
    }
    else if(SvIOK(HookDll)){
        dosHeader = (PIMAGE_DOS_HEADER) SvIV_nomg(HookDll);
        if(!dosHeader) goto BAD_USAGE;
    }
    else if(SvOK(HookDll)){ /*NVs RVs not valid*/
        BAD_USAGE:
        croak_xs_usage(cv,  "classSV, callback, HookDll, ImportDllName, ImportFunctionName");
    }
    else{ /* undef means patch the .exe that created the process*/
        HookDllName = NULL;
        USE_GMH:
        dosHeader = (PIMAGE_DOS_HEADER) GetModuleHandle(HookDllName);
        if(!dosHeader) goto ERROR;
    }
    if(!PatchIAT(aTHX_ dosHeader, ImportDllName, ImportFunctionName,
        &oldFunction, (void *)SvUVX(*hv_fetch(callback, "code", sizeof("code")-1, 0)))){
        ERROR:
        PUSHs(&PL_sv_undef);
        PUTBACK;
        return;    
    }
    returnHV = newHV();
    //save the hmod, not dll str name, other dlls with same name might have been
    //loaded in the meantime/sxs/etc
    hv_store(returnHV,  "HookDllHmod",          sizeof("HookDllHmod")-1,
                        newSVuv((UV)dosHeader), 0);
    hv_store(returnHV,  "OrigFunc",             sizeof("OrigFunc")-1,
                        newSVuv((UV)oldFunction) ,  0);
    hv_store(returnHV,  "ImportDllName",        sizeof("ImportDllName")-1,
                        newSVsv(ImportDllName), 0);
    hv_store(returnHV,  "ImportFunctionName",   sizeof("ImportFunctionName")-1,
                        newSVsv(ImportFunctionName), 0);
    hv_store(returnHV,  "callback",             sizeof("callback")-1,
                        newRV_inc((SV*)callback),    0);
    mPUSHs(sv_bless(newRV_noinc((SV*)returnHV),
                    gv_stashsv(classSV,0)
                    )
           );

void
Unpatch(...)
PREINIT:
    I32 flagvar = 1; /*no param default is to restore*/
    SV * OrigFuncSV;
    void * OrigFunc;
    HV * self;
CODE:
    if (items < 1 || items > 2)
       croak_xs_usage(cv, "self [, flag=true]");
    else if(items == 2){
        flagvar = sv_true(POPs);
    }
    {SV * TmpRV = POPs;
	if (SvROK(TmpRV) && sv_derived_from(TmpRV, "Win32::API::Callback::IATPatch")) {
	    self = (HV*)SvRV(TmpRV);
	}
	else
	    croak("%s: %s is not of type %s",
			"Win32::API::Callback::IATPatch::Unpatch",
            "self", "Win32::API::Callback::IATPatch");};
    OrigFuncSV = *hv_fetch(self, "OrigFunc", sizeof("OrigFunc")-1, 0);
    if(flagvar){
    if(OrigFunc = (void *)SvUVX(OrigFuncSV)){
        if(!PatchIAT(aTHX_
            (PIMAGE_DOS_HEADER)SvUVX(*hv_fetch(self, "HookDllHmod", sizeof("HookDllHmod")-1, 0)),
            *hv_fetch(self, "ImportDllName", sizeof("ImportDllName")-1, 0),
            *hv_fetch(self, "ImportFunctionName", sizeof("ImportFunctionName")-1, 0),
            NULL,       OrigFunc /*we don't collect the patch func ptr and
compare it to $self->{'callback'}->{'code'}, to see if something else patched
after us maybe we should????*/
        )){
            goto FAILED;
        }
        else goto SUCCESS_LABEL;
    }
    else SetLastError(ERROR_NO_MORE_ITEMS);
    }
    else{ //flag is false, never restore original function
    SUCCESS_LABEL:
        sv_setuv(OrigFuncSV, 0);
        PUSHs(&PL_sv_yes);
        PUTBACK;
        return;
    }
    FAILED:
    PUSHs(&PL_sv_undef);
    PUTBACK;
    return;

void
DESTROY(self)
    SV * self
PREINIT:
    SV * retsv;
    DWORD error;
    DWORD error2;
PPCODE:
    error = GetLastError(); //dont let DESTROY screw up a new
    PUSHMARK(SP);
    PUSHs(self);
    PUSHs(&PL_sv_yes);
    PUTBACK;
    XS_Win32__API__Callback__IATPatch_Unpatch(aTHX_ cv); /*the cv is wrong with this hack*/
    //call_pv("Win32::API::Callback::IATPatch::Unpatch", 0);
    retsv = POPs;
    if(!sv_true(retsv) /*ERROR_NO_MORE_ITEMS means it was already unpatched*/
       && (error2 = GetLastError()) != ERROR_NO_MORE_ITEMS){
        croak("%s: Failed to unpatch DLL, error number %u ",
              "Win32::API::Callback::IATPatch::DESTROY", error2);
    }
    SetLastError(error);

# GetOriginalFunction is reserved for future
# GetOriginalFunction should return a fully working Win32::API obj that calls
# the original function, the prototype should be obtained automatically from the
# Win32::API::Callback obj

void
GetOriginalFunctionPtr(self)
W32ACIATP_T * self
PPCODE:
    PUSHs(sv_mortalcopy(*hv_fetch(self, "OrigFunc", sizeof("OrigFunc")-1, 0)));


void
CLONE_SKIP(...)
PPCODE:
/* Prevent double unpatching from a fork. I dont think it makes sense to clone
  IATPatches, there is only one DLL per process. You can't have 2 different
  patches on it and have 2 different hooks expect to work based on the calling
  psuedo process. Well you could have a aTHX based dispatcher that will look up
  the correct weak ref ::Callback HV to use each time the PerlCallback() is
  called, but that is s alot of work for little gain. Currently the HV * of
  the ::Callback is hard coded into the ASM callback, and that HV * is interp
  specific.
*/
    PUSHs(&PL_sv_yes);
