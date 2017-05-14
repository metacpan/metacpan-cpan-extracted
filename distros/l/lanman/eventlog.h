#ifndef __EVENTLOG_H
#define __EVENTLOG_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// reads records from the eventlog
//
// param:  server - computer to execute the command
//				 source	- which part of the eventlog (system, security, application
//									or an eventlog backup file)
//         first  - read from the first record ...
//				 last   - ... til the last record
//				 events	- array to store information
//
// return: success - 1 
//         failure - 0 
//
// note:   the first record begins with index 1; to read all records, set first
//				 to 1 and last to 0xffffffff; if you want to read backwards, first
//				 must be bigger than last; call GetLastError() to get the error code 
//				 on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ReadEventLog);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves the description of an event
//
// param:  server - computer to execute the command
//				 event	- event to get the description for
//
// return: success - 1 
//         failure - 0 
//
// note:   event must be retrieved previous by a calling 
//				 XS_NT__Lanman_ReadEventLog
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetEventDescription);


///////////////////////////////////////////////////////////////////////////////
//
// makes a backup from the eventlog
//
// param:  server		- computer to execute the command
//				 source		- which part of the eventlog (system, security or 
//										application)
//				 fileName - backup file name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_BackupEventLog);


///////////////////////////////////////////////////////////////////////////////
//
// clears an eventlog and makes an optionally backup before clearing
//
// param:  server		- computer to execute the command
//				 source		- which part of the eventlog (system, security or 
//										application)
//				 fileName - backup file name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ClearEventLog);


///////////////////////////////////////////////////////////////////////////////
//
// writes an event to the event log
//
// param:  server		- computer to execute the command
//				 source		- which part of the eventlog (system, security or 
//										application)
//				 type			- event type (error, warning, information, audit)
//				 category	- event category
//				 id				- event id
//				 sid			- account sid to log in the event
//				 strings	- array with event strings
//				 data			- pointer to the binary data
//
// return: success - 1 
//         failure - 0 
//
// note:   you should specify the complete event id; the event viewer shows only
//				 the lowest 16 bit of the id; to get the complete id fo a specific 
//				 event, use the ReadEventLog function from this module; 
//				 call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ReportEvent);


///////////////////////////////////////////////////////////////////////////////
//
// gets the number of records in an event log
//
// param:  server			- computer to execute the command
//				 source			- which part of the eventlog (system, security or 
//											application)
//				 numrecords - gets the number of records
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetNumberOfEventLogRecords);


///////////////////////////////////////////////////////////////////////////////
//
// gets the oldest record number in an event log
//
// param:  server				- computer to execute the command
//				 source				- which part of the eventlog (system, security or 
//												application)
//				 oldestrecord - gets the oldest record number
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetOldestEventLogRecord);

///////////////////////////////////////////////////////////////////////////////
//
// waits until an event is written to the event log or the timeout elapses
//
// param:  server				- computer to execute the command (remote computers are
//												currently not allowed  - GetLastError returns 
//												ERROR_INVALID_HANDLE)
//				 source				- which part of the eventlog (system, security or 
//												application)
//				 timeout			- optional parameter how long to wait for the event,
//												default: infinite
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NotifyChangeEventLog);


#endif //#ifndef __EVENTLOG_H
