// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#define _UNICODE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

//
// There are 2 ways to compile this program: 
//    1/ using Win32ShellExt in a DLL (perlshellext.dll)
//    2/ building Win32ShellExt within this .cpp (for testing).
//
#ifdef Win32ShellExt_DLL
 #define WIN32SHELLEXTAPI_IMPORT
 #include "Win32ShellExt.h"
#else
 #define DllMain            dummyDllMain          
 #define DllCanUnloadNow	   dummyDllCanUnloadNow  
 #define DllGetClassObject  dummyDllGetClassObject

 static void debug_printf(void *f, char *fmt, ...);
 #define _DEBUG_H
 #define EXTDEBUG(x) { void *f=NULL; debug_printf x; }

 #include "../Win32ShellExt.cpp"
#endif

#pragma data_seg(".text")
#define INITGUID
#include <initguid.h>
#include <shlguid.h>

// {DF02ACD0-8458-453A-8541-699EE3FC676D}
DEFINE_GUID(CLSID_Win32_ShellExt_ColumnProvider_JpgSize, 0xDF02ACD0, 0x8458, 0x453A, 0x85, 0x41, 0x69, 0x9E, 0xE3, 0xFC, 0x67, 0x6D);

#pragma data_seg()

static void debug_printf(void *f, char *fmt, ...) {
  va_list ap;

  va_start(ap,fmt);
  win32_printf(fmt, ap);
  va_end(ap);
}

static void testCol(IColumnProvider *cp, DWORD index, SHCOLUMNDATA *coldata) {
  SHCOLUMNID colid;
  colid.fmtid = CLSID_Win32_ShellExt_ColumnProvider_JpgSize;
  colid.pid = 25+index;
  VARIANT v;
  VariantInit(&v);
  HRESULT rc = cp->GetItemData(&colid,coldata,&v);
  if(FAILED(rc)) {
    printf("failed\n");
  } else {
    WCHAR *w = v.bstrVal;
    printf("GetItemData=%S\n",w);
    VariantClear(&v);
  }
}

static void testCol3(IColumnProvider *cp, SHCOLUMNDATA *coldata) {
  testCol(cp,0,coldata);
  testCol(cp,1,coldata);
  testCol(cp,2,coldata); // invalid column.
}

static void test(IColumnProvider *cp) {
  SHCOLUMNINIT ci;
  memset(&ci,sizeof(SHCOLUMNINIT),0);
  lstrcpyW/*_wcscpy*/((WCHAR*)&ci.wszFolder[0],L"c:\\Temp");
  HRESULT rc = cp->Initialize(&ci);
  if(FAILED(rc)) {
    printf("failed\n");
    exit(EXIT_FAILURE);
  }
  DWORD index=0;
  rc = S_OK;
  while(rc==S_OK) {
    SHCOLUMNINFO colinfo;
    rc = cp->GetColumnInfo(index,&colinfo);
    if(FAILED(rc)) {
      printf("failed\n");
      exit(EXIT_FAILURE);
    }
    if(rc==S_OK)
      index++; // break on next while test..
  }
  
  SHCOLUMNDATA coldata0 = { 0, 0, 0, L".CBL", L"c:\\Temp\\CVTCOBOL.CBL" };
  testCol3(cp,&coldata0);
  SHCOLUMNDATA coldata3 = { 0, 0, 0, L".jpg", L"c:\\Temp\\vancouver06.jpg" };
  testCol3(cp,&coldata3);
  SHCOLUMNDATA coldata4 = { 0, 0, 0, L".jpg", L"c:\\Temp\\vancouver07.jpg" };
  testCol3(cp,&coldata4);
  SHCOLUMNDATA coldata1 = { 0, 0, 0, L"", L"c:\\Temp\\samples" };
  testCol3(cp,&coldata1);
  SHCOLUMNDATA coldata2 = { 0, 0, 0, L"", L"c:\\Temp\\test" };
  testCol3(cp,&coldata2);
}

int main(int argc, char **argv)
{
  PL_debug=64;
  /*
        1  p  Tokenizing and parsing
        2  s  Stack snapshots
        4  l  Context (loop) stack processing
        8  t  Trace execution
       16  o  Method and overloading resolution
       32  c  String/numeric conversions
       64  P  Print preprocessor command for -P, source file input state
      128  m  Memory allocation
      256  f  Format processing
      512  r  Regular expression parsing and execution
     1024  x  Syntax tree dump
     2048  u  Tainting checks
     4096  L  Memory leaks (needs -DLEAKTEST when compiling Perl)
     8192  H  Hash dump -- usurps values()
    16384  X  Scratchpad allocation
    32768  D  Cleaning up
    65536  S  Thread synchronization
   131072  T  Tokenising
  */
  PL_debug |= 0x80000000;

  printf("%s main begin\n",argv[0]);
  IClassFactory *factory=0;

#ifdef Win32ShellExt_DLL
  HRESULT (*DllGetClassObject)(REFCLSID rclsid, REFIID riid, LPVOID *ppvOut);
  HMODULE dll = LoadLibrary("perlshellext.dll");
  DllGetClassObject = (HRESULT (*)(REFCLSID , REFIID , LPVOID *))GetProcAddress(dll,"DllGetClassObject");
#endif
  DllGetClassObject(CLSID_Win32_ShellExt_ColumnProvider_JpgSize, IID_IClassFactory, (void**)&factory);
  
  if(factory==0) {
    printf("cannot get class factory\n");
    return EXIT_FAILURE;
  }
  
  IUnknown *ext=0;
  factory->CreateInstance(NULL,IID_IUnknown,(void**)&ext);

  IColumnProvider *cp=0;
  ext->QueryInterface(IID_IColumnProvider,(void**)&cp);
  if(cp==0) {
    printf("cannot get IColumnProvider interface\n");
    return EXIT_FAILURE;
  }
  ext->Release();

  test(cp);  
  
  cp->Release();
  factory->Release();
#ifdef Win32ShellExt_DLL
  FreeLibrary(dll);
#endif
  printf("%s main end\n",argv[0]);
  
  // This didn't work out. the program still core dumps in crt...
  //  extern int _nstream;
  //_nstream=0; // this keeps CRT from flushing all FILE objects, thereby preventing a core dump due to Perl's mingling with IOs.
  exit(EXIT_SUCCESS);
  return EXIT_SUCCESS;
}

