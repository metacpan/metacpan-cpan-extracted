#ifndef __SCHEDULE_H
#define __SCHEDULE_H


#include <lmat.h>


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// submits a job to run at a specified future time and date
//
// param:  server - computer to execute the command
//				 info		- hash to set information (job id will be returned in 'jobid')
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////
 
XS(XS_NT__Lanman_NetScheduleJobAdd);


///////////////////////////////////////////////////////////////////////////////
//
// deletes a range of jobs queued to run at a computer
//
// param:  server   - computer to execute the command
//				 minjobid - first job id to delete
//				 maxjobid - last job id (optional)
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetScheduleJobDel);


///////////////////////////////////////////////////////////////////////////////
//
// lists the jobs queued on a specified computer
//
// param:  server - computer to execute the command
//				 info		- array to store job information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetScheduleJobEnum);


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a particular job queued on a specified computer
//
// param:  server - computer to execute the command
//				 info		- hash to store job information
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetScheduleJobGetInfo);


#endif //#ifndef __SCHEDULE_H
