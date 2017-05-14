#define WIN32_LEAN_AND_MEAN


#ifndef __SCHEDULE_CPP
#define __SCHEDULE_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "schedule.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// globals
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

XS(XS_NT__Lanman_NetScheduleJobAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *jobInfo = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(jobInfo, ST(1)))
	{
		PWSTR server = NULL;
		AT_INFO info = {0, 0, 0, 0, NULL};

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			
			DWORD jobId = 0;

			info.JobTime = H_FETCH_INT(jobInfo, "jobtime");
			info.DaysOfMonth = H_FETCH_INT(jobInfo, "daysofmonth");
			info.DaysOfWeek = H_FETCH_INT(jobInfo, "daysofweek");
			info.Flags = H_FETCH_INT(jobInfo, "flags");
			info.Command = H_FETCH_WSTR(jobInfo, "command");

			if(!LastError(NetScheduleJobAdd(server, (PBYTE)&info, &jobId)))
				// store job id
				H_STORE_INT(jobInfo, "jobid", jobId);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(info.Command);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetScheduleJobAdd($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_NetScheduleJobDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PWSTR server = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			DWORD minJobId = SvIV(ST(1));
			DWORD maxJobId = items == 3 ? SvIV(ST(2)) : minJobId;

			LastError(NetScheduleJobDel(server, minJobId, maxJobId));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
	} // if(items == 2 || items == 3)
	else
		croak("Usage: Win32::Lanman::NetScheduleJobDel($server, $minjobid, $maxjobid)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_NetScheduleJobEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *jobInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(jobInfo, ST(1)))
	{
		PWSTR server = NULL;
		PAT_ENUM info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clean array
			AV_CLEAR(jobInfo);

			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			if(!LastError(NetScheduleJobEnum(server, (PBYTE*)&info, 0xffffffff, &entries, 
																			 &total, &handle)))
				for(DWORD count = 0; count < entries; count++)
				{
					// store job properties
					HV *properties = NewHV;

					H_STORE_INT(properties, "jobid", info[count].JobId);
					H_STORE_INT(properties, "jobtime", info[count].JobTime);
					H_STORE_INT(properties, "daysofmonth", info[count].DaysOfMonth);
					H_STORE_INT(properties, "daysofweek", info[count].DaysOfWeek);
					H_STORE_INT(properties, "flags", info[count].Flags);
					H_STORE_WSTR(properties, "command", info[count].Command);

					A_STORE_REF(jobInfo, properties);

					// decrement reference count
					SvREFCNT_dec(properties);
				}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(info);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetScheduleJobEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_NetScheduleJobGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *jobInfo = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(jobInfo, ST(2)))
	{
		PWSTR server = NULL;
		PAT_INFO info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			
			DWORD jobId = SvIV(ST(1));

			// clean array
			HV_CLEAR(jobInfo);

			if(!LastError(NetScheduleJobGetInfo(server, jobId, (PBYTE*)&info)))
			{
				// store job properties
				H_STORE_INT(jobInfo, "jobtime", info->JobTime);
				H_STORE_INT(jobInfo, "daysofmonth", info->DaysOfMonth);
				H_STORE_INT(jobInfo, "daysofweek", info->DaysOfWeek);
				H_STORE_INT(jobInfo, "flags", info->Flags);
				H_STORE_WSTR(jobInfo, "command", info->Command);
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		CleanNetBuf(info);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::NetScheduleJobEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


