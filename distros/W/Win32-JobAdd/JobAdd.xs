/*
    Win32::JobAdd - written in response to
    perlmonks.org/index.pl?node_id=958489

    Copyright 2012, BrowserUk@cpan.org  All rights reserved;

*/

#define _WIN32_WINNT 0x0500

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    #define JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE          0x2000
#endif

int createJobObject( char *name ) {
    HANDLE job;
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli = { 0, };
    jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    job = CreateJobObjectA( NULL, name );
    SetInformationJobObject( job, 9, &jeli, sizeof(jeli) );
    return (int)job;
}


int assignProcessToJobObject( int job, int pid ) {
    HANDLE hProc = OpenProcess( PROCESS_SET_QUOTA |PROCESS_TERMINATE, 0, pid );
    return (int)AssignProcessToJobObject( (HANDLE)job, hProc );
}

int closeHandle( int handle ) {
    return (int)CloseHandle( (HANDLE)handle );
}


MODULE = Win32::JobAdd		PACKAGE = Win32::JobAdd


int
createJobObject (name)
	char *	name

int
assignProcessToJobObject (job, pid)
	int	job
	int	pid

int
closeHandle (handle)
	int	handle

