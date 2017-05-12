/* *********************************************************************
 * test_llu.c: Example for test the %llu behaviour of printf
 * *********************************************************************
 * Authors: Roman Plessl
 *
 * Copyright (c) 2008 by OETIKER+PARTNER AG. All rights reserved.
 * 
 * Win32::Monitoring::DllInject is free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.
 *
 * $Id: test_llu.c 203 2009-07-23 09:09:58Z rplessl $ 
 *
 * **********************************************************************
 */

#define __MSVCRT_VERSION__ 0x601
#define WINVER 0x0500 

#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <stdlib.h>
#include <shlobj.h>
#include <imagehlp.h>

#include <sys/types.h>
#include <sys/timeb.h>
#include <time.h>

typedef unsigned long long   longtime_t;

longtime_t timems (void){
     struct __timeb64 timebuffer;
     _ftime64( &timebuffer );
     return ((longtime_t)timebuffer.time * 1000 + (longtime_t)timebuffer.millitm);
}

int main(void) {
  longtime_t now;
  now = timems(); 
  printf( "print unsigned long long I64u: %I64u\n", now ); 
  printf( "print unsigned long long llu: %llu\n", now );
}
