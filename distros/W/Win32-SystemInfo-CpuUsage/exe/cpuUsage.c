#include "stdafx.h"

#include <windows.h>
#include <stdio.h>

#define SystemBasicInformation		0
#define SystemPerformanceInformation	2
#define SystemTimeInformation			3

#define Li2Double(x) ((double)((x).HighPart) * 4.294967296E9 + (double)((x).LowPart))

typedef struct
{
	  DWORD   dwUnknown1;
	  ULONG   uKeMaximumIncrement;
	  ULONG   uPageSize;
	  ULONG   uMmNumberOfPhysicalPages;
	  ULONG   uMmLowestPhysicalPage;
	  ULONG   uMmHighestPhysicalPage;
	  ULONG   uAllocationGranularity;
	  PVOID   pLowestUserAddress;
	  PVOID   pMmHighestUserAddress;
	  ULONG   uKeActiveProcessors;
	  BYTE    bKeNumberProcessors;
	  BYTE    bUnknown2;
	  WORD    wUnknown3;
} SYSTEM_BASIC_INFORMATION;

typedef struct
{
	  LARGE_INTEGER		liIdleTime;
	  DWORD				dwSpare[76];
} SYSTEM_PERFORMANCE_INFORMATION;

typedef struct
{
	  LARGE_INTEGER liKeBootTime;
	  LARGE_INTEGER liKeSystemTime;
	  LARGE_INTEGER liExpTimeZoneBias;
	  ULONG			  uCurrentTimeZoneId;
	  DWORD     dwReserved;
} SYSTEM_TIME_INFORMATION;

// ntdll!NtQuerySystemInformation (NT specific!)
//
// The function copies the system information of the
// specified type into a buffer
//
// NTSYSAPI
// NTSTATUS
// NTAPI
// NtQuerySystemInformation(
//   IN   UINT   SystemInformationClass,   // information type
//   OUT  PVOID  SystemInformation,        // pointer to buffer
//   IN   ULONG  SystemInformationLength,  // buffer size in bytes
//   OUT  PULONG ReturnLength OPTIONAL     // pointer to a 32-bit
//										   // variable that receives
//										   // the number of bytes
//										   // written to the buffer
// );
typedef LONG (WINAPI *PROCNTQSI)(UINT,PVOID,ULONG,PULONG);

PROCNTQSI NtQuerySystemInformation;

int getCpuUsage(int interval)
{
	SYSTEM_PERFORMANCE_INFORMATION	SysPerfInfo;
	SYSTEM_TIME_INFORMATION			SysTimeInfo;
	SYSTEM_BASIC_INFORMATION		SysBaseInfo;
	double				dbIdleTime;
	double				dbSystemTime;
	LONG				status;
	LARGE_INTEGER		liOldIdleTime = {0,0};
	LARGE_INTEGER		liOldSystemTime = {0,0};

	int iCtl=0, percentage=0;

	NtQuerySystemInformation = (PROCNTQSI)GetProcAddress(
								GetModuleHandle("ntdll"),
								"NtQuerySystemInformation"
								);
	if(!NtQuerySystemInformation)
	return -1;

	// get number of processors in the system
	status = NtQuerySystemInformation(SystemBasicInformation,&SysBaseInfo,sizeof(SysBaseInfo),NULL);
	if(status != NO_ERROR)
	return -1;

	//printf("\n getting CPU Usage\n");
	//while(!_kbhit())

	while(1)
	{
		// get new system time
		status = NtQuerySystemInformation(SystemTimeInformation,&SysTimeInfo,sizeof(SysTimeInfo),0);
		if(status!=NO_ERROR)
		return -1;

		// get new CPU's idle time
		status = NtQuerySystemInformation(SystemPerformanceInformation,&SysPerfInfo,sizeof(SysPerfInfo),NULL);
		if(status != NO_ERROR)
		return -1;

		// if it's a first call - skip it
		if(liOldIdleTime.QuadPart != 0)
		{
			// CurrentValue = NewValue - OldValue
			dbIdleTime   = Li2Double(SysPerfInfo.liIdleTime)     - Li2Double(liOldIdleTime);
			dbSystemTime = Li2Double(SysTimeInfo.liKeSystemTime) - Li2Double(liOldSystemTime);

			// CurrentCpuIdle = IdleTime / SystemTime
			dbIdleTime = dbIdleTime / dbSystemTime;

			// CurrentCpuUsage% = 100 - (CurrentCpuIdle * 100) / NumberOfProcessors
			dbIdleTime = 100.0 - dbIdleTime * 100.0 / (double)SysBaseInfo.bKeNumberProcessors + 0.5;

			//+ 0.5, result is same in task manager
			percentage= (UINT)(dbIdleTime);

			//printf("\b\b\b\b%3d%%", percentage);
			if(iCtl > 0 ) return percentage;
		}

		// store new CPU's idle and system time
		liOldIdleTime   = SysPerfInfo.liIdleTime;
		liOldSystemTime = SysTimeInfo.liKeSystemTime;

		// wait one second
		Sleep(interval);
		iCtl++;
	}
	return 0;
}

void main(int argc, char** argv)
{
	while(1){
		printf("\b\b\b\b%3d%%", getCpuUsage(1000));
	}	
}