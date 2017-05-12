#define WIN32_LEAN_AND_MEAN


#ifndef __SERVICE_CPP
#define __SERVICE_CPP
#endif


#include <windows.h>
#include <lm.h>
#include <aclapi.h>


#include "addloader.h"
#include "service.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// starts a service
//
// param:  server    - computer to start the service
//				 servicedb - service database name (normally null)
//				 service   - service name to start
//				 arguments - arguments to pass to the service
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_StartService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *arguments = NULL;

	if(items == 3 || items == 4 && CHK_ASSIGN_AREF(arguments, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle
			if(hService = OpenService(hSCManager, service, SERVICE_START))
			{
				int argc = arguments ? av_len(arguments) + 1 : 0;
				PSTR *argv = argc ? (PSTR*)NewMem(sizeof(PSTR) * argc) : NULL;

				if(argv)
				{
					memset(argv, 0, sizeof(PSTR) * argc);

					for(int count = 0; count < argc; count++)
						argv[count] = A_FETCH_STR(arguments, count);
				}

				// start service now
				if(!StartService(hService, argc, (PCSTR*)argv))
					LastError(GetLastError());

				// clean up
				CleanPtr(argv);
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::StartService($server, $servicedb, $service, [\\@arguments])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// stops a service
//
// param:  server    - computer to stop the service
//				 servicedb - service database name (normally null)
//				 service   - service name to stop
//				 status		 - get the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_StopService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 3 || items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle, then stop the service
			if(hService = OpenService(hSCManager, service, SERVICE_STOP))
			{
				SERVICE_STATUS servStatus;

				if(ControlService(hService, SERVICE_CONTROL_STOP, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::StopService($server, $servicedb, $service, [\\%%status])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// pause a service
//
// param:  server    - computer to pause the service
//				 servicedb - service database name (normally null)
//				 service   - service name to pause
//				 status		 - get the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_PauseService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 3 || items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle, then pause the service
			if(hService = OpenService(hSCManager, service, SERVICE_PAUSE_CONTINUE))
			{
				SERVICE_STATUS servStatus;

				if(ControlService(hService, SERVICE_CONTROL_PAUSE, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::PauseService($server, $servicedb, $service, [\\%%status])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// continues a service
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service   - service name to continue
//				 status		 - get the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ContinueService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 3 || items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle, then continue the service
			if(hService = OpenService(hSCManager, service, SERVICE_PAUSE_CONTINUE))
			{
				SERVICE_STATUS servStatus;

				if(ControlService(hService, SERVICE_CONTROL_CONTINUE, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::ContinueService($server, $servicedb, $service, [\\%%status])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// interrogates a service
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service   - service name to interrogate
//				 status		 - get the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_InterrogateService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 3 || items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle, then interrogate the service
			if(hService = OpenService(hSCManager, service, SERVICE_INTERROGATE))
			{
				SERVICE_STATUS servStatus;

				if(ControlService(hService, SERVICE_CONTROL_INTERROGATE, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::InterrogateService($server, $servicedb, $service, [\\%%status])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// controls a service
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service   - service name to control
//				 control	 - control code to send
//				 status		 - get the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ControlService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 4 || items == 5 && CHK_ASSIGN_HREF(status, ST(4)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);
			int control = SvIV(ST(3));

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			DWORD access = 0;

			switch(control)
			{
				case SERVICE_CONTROL_STOP:
					access = SERVICE_STOP;
					break;

				case SERVICE_CONTROL_PAUSE:
				case SERVICE_CONTROL_CONTINUE:
					access = SERVICE_PAUSE_CONTINUE;
					break;

				case SERVICE_CONTROL_INTERROGATE:
					access = SERVICE_INTERROGATE;
					break;

				default:
					access = SERVICE_USER_DEFINED_CONTROL;
					break;
			}

			// did we got an handle, then send control code to the service
			if(hService = OpenService(hSCManager, service, access))
			{
				SERVICE_STATUS servStatus;

				if(ControlService(hService, control, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::ControlService($server, $servicedb, $service, $control, [\\%%status])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// creates a service
//
// param:  server				- computer to continue the service
//				 servicedb		- service database name (normally null)
//				 serviceparam - parameter to create service
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_CreateService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *param = NULL;
	AV *depend = NULL; 

	if(items == 3 && CHK_ASSIGN_HREF(param, ST(2)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR dependStr = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);

			// get parameter
			PSTR name = H_FETCH_STR(param, "name");
			PSTR display = H_FETCH_STR(param, "display");
			DWORD type = H_FETCH_INT(param, "type");
			DWORD start = H_FETCH_INT(param, "start");
			DWORD control = H_FETCH_INT(param, "control");
			PSTR fileName = H_FETCH_STR(param, "filename");
			PSTR group = H_FETCH_STR(param, "group");
			DWORD tagId = H_FETCH_INT(param, "tagid");
			PDWORD tagIdPtr = H_FETCH_STR(param, "tagid") ? &tagId : NULL;
			PSTR account = H_FETCH_STR(param, "account");
			PSTR password = H_FETCH_STR(param, "password");

			if(depend = H_FETCH_RARRAY(param, "dependencies"))
			{
				// calculate dependencies string
				DWORD dependStrLen = 1;

				for(int count = 0, numDepend = av_len(depend) + 1; count < numDepend; count++)
				{
					PSTR dependPtr = A_FETCH_STR(depend, count);

					if(dependPtr)
						dependStrLen += strlen(dependPtr) + 1;
				}

				// alloc memory
				dependStr = (PSTR)NewMem(dependStrLen);

				// copy strings
				count = 0;
				for(PSTR dependStrPtr = dependStr; count < numDepend; count++)
				{
					PSTR dependPtr = A_FETCH_STR(depend, count);

					if(dependPtr)
					{
						strcpy(dependStrPtr, dependPtr);
						dependStrPtr += strlen(dependStrPtr) + 1;
					}
				}
			}

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CREATE_SERVICE)))
				RaiseFalse();

			// did we got an handle, then create the service
			hService = CreateService(hSCManager, name, display, 0, type, start, control, 
															 fileName, group, tagIdPtr, dependStr, account, password);

			if(!hService)
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(dependStr);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::CreateService($server, $servicedb, \\%%param)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes a service
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service   - service name to start
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_DeleteService)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			// did we got an handle, then delete the service
			if(!(hService = OpenService(hSCManager, service, DELETE)) || 
				 !DeleteService(hService))
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::DeleteService($server, $servicedb, $service)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enumerates services
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 type			 - service type to enum
//				 state		 - service state to enum
//				 services  - services array
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_EnumServicesStatus)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *services = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(services, ST(4)))
	{
		SC_HANDLE hSCManager = NULL;
		ENUM_SERVICE_STATUS *servStatus = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database, type and state
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			int type = SvIV(ST(2));
			int state = SvIV(ST(3));

			// clear array
			AV_CLEAR(services);

			// open sc manager
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_ENUMERATE_SERVICE)))
				RaiseFalse();
			
			// did we got an handle, then enum services
			DWORD servStatusSize = 0, servStatusCount = 0, handle = 0;

			// calculate size needed
			EnumServicesStatus(hSCManager, type, state, servStatus, servStatusSize, &servStatusSize,
												 &servStatusCount, &handle);

			if(LastError(GetLastError()) == ERROR_MORE_DATA)
			{
				LastError(0);

				// alloc memory
				servStatus = (ENUM_SERVICE_STATUS*)NewMem(servStatusSize);

				// enum services
				if(EnumServicesStatus(hSCManager, type, state, servStatus, servStatusSize, 
															&servStatusSize,	&servStatusCount, &handle))
				{
					// copy result
					for(DWORD count = 0; count < servStatusCount; count++)
					{
						// store service properties
						HV *properties = NewHV;

						H_STORE_STR(properties, "name", servStatus[count].lpServiceName);
						H_STORE_STR(properties, "display", servStatus[count].lpDisplayName);
						H_STORE_INT(properties, "type", servStatus[count].ServiceStatus.dwServiceType);
						H_STORE_INT(properties, "state", servStatus[count].ServiceStatus.dwCurrentState);
						H_STORE_INT(properties, "accepted", servStatus[count].ServiceStatus.dwControlsAccepted);
						H_STORE_INT(properties, "win32exitcode", servStatus[count].ServiceStatus.dwWin32ExitCode);
						H_STORE_INT(properties, "specificexitcode", servStatus[count].ServiceStatus.dwServiceSpecificExitCode);
						H_STORE_INT(properties, "check", servStatus[count].ServiceStatus.dwCheckPoint);
						H_STORE_INT(properties, "hint", servStatus[count].ServiceStatus.dwWaitHint);

						A_STORE_REF(services, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}
				}
				else
					LastError(GetLastError());
			} // if(LastError(GetLastError()) == ERROR_MORE_DATA)
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(servStatus);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::EnumServicesStatus($server, $servicedb, $type, $state, \\@services)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enumerates dependent services
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - services name
//				 state		 - service state to enum
//				 services  - dependent services array
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_EnumDependentServices)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *services = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(services, ST(4)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		ENUM_SERVICE_STATUS *servStatus = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database, service and state
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);
			int state = SvIV(ST(3));

			// clear array
			AV_CLEAR(services);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			if(!(hService = OpenService(hSCManager, service, SERVICE_ENUMERATE_DEPENDENTS)))
				RaiseFalse();
			
			// did we got an handle, then enum services
			DWORD servStatusSize = 0, servStatusCount = 0;

			// calculate size needed
			EnumDependentServices(hService, state, servStatus, servStatusSize, &servStatusSize,
														&servStatusCount);

			if(LastError(GetLastError()) == ERROR_MORE_DATA)
			{
				// alloc memory
				servStatus = (ENUM_SERVICE_STATUS*)NewMem(servStatusSize);

				LastError(0);

				// enum dependent services
				if(EnumDependentServices(hService, state, servStatus, servStatusSize, 
																 &servStatusSize,	&servStatusCount))
				{
					// copy result
					for(DWORD count = 0; count < servStatusCount; count++)
					{
						// store service properties
						HV *properties = NewHV;

						H_STORE_STR(properties, "name", servStatus[count].lpServiceName);
						H_STORE_STR(properties, "display", servStatus[count].lpDisplayName);
						H_STORE_INT(properties, "type", servStatus[count].ServiceStatus.dwServiceType);
						H_STORE_INT(properties, "state", servStatus[count].ServiceStatus.dwCurrentState);
						H_STORE_INT(properties, "accepted", servStatus[count].ServiceStatus.dwControlsAccepted);
						H_STORE_INT(properties, "win32exitcode", servStatus[count].ServiceStatus.dwWin32ExitCode);
						H_STORE_INT(properties, "specificexitcode", servStatus[count].ServiceStatus.dwServiceSpecificExitCode);
						H_STORE_INT(properties, "check", servStatus[count].ServiceStatus.dwCheckPoint);
						H_STORE_INT(properties, "hint", servStatus[count].ServiceStatus.dwWaitHint);

						A_STORE_REF(services, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}
				}
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(servStatus);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::EnumDependentServices($server, $servicedb, $service, $state, \\@services)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// changes a service configuration
//
// param:  server				- computer to continue the service
//				 servicedb		- service database name (normally null)
//				 service			- service name
//				 serviceparam - parameter to change service config
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ChangeServiceConfig)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *param = NULL;
	AV *depend = NULL; 

	if(items == 4 && CHK_ASSIGN_HREF(param, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR dependStr = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// get parameter
			DWORD type = H_EXISTS_FETCH_INT(param, "type", SERVICE_NO_CHANGE);
			DWORD start =	H_EXISTS_FETCH_INT(param, "start", SERVICE_NO_CHANGE);
			DWORD control = H_EXISTS_FETCH_INT(param, "control", SERVICE_NO_CHANGE);
			PSTR fileName = H_FETCH_STR(param, "filename");
			PSTR group = H_FETCH_STR(param, "group");
			DWORD tagId = H_EXISTS_FETCH_INT(param, "tagid", 0);
			PSTR account = H_FETCH_STR(param, "account");
			PSTR password = H_FETCH_STR(param, "password");
			PSTR display = H_FETCH_STR(param, "display");
			PDWORD tagIdPtr = H_FETCH_STR(param, "tagid") ? &tagId : NULL;

			if(depend = H_FETCH_RARRAY(param, "dependencies"))
			{
				// calculate dependencies string
				DWORD dependStrLen = 1;

				for(int count = 0, numDepend = av_len(depend) + 1; count < numDepend; count++)
				{
					PSTR dependPtr = A_FETCH_STR(depend, count);

					if(dependPtr)
						dependStrLen += strlen(dependPtr) + 1;
				}

				// alloc memory
				dependStr = (PSTR)NewMem(dependStrLen);

				// copy strings
				count = 0;
				for(PSTR dependStrPtr = dependStr; count < numDepend; count++)
				{
					PSTR dependPtr = A_FETCH_STR(depend, count);

					if(dependPtr)
					{
						strcpy(dependStrPtr, dependPtr);
						dependStrPtr += strlen(dependStrPtr) + 1;
					}
				}
			}

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			if(hService = OpenService(hSCManager, service, SERVICE_CHANGE_CONFIG))
			{
				if(!ChangeServiceConfig(hService, type, start, control, fileName, group, tagIdPtr,
																dependStr, account, password, display))
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(dependStr);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::ChangeServiceConfig($server, $servicedb, $service, \\%%param)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the display name of a service
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 display	 - gets the display name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetServiceDisplayName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *display = NULL;

	if(items == 4 && CHK_ASSIGN_SREF(display, ST(3)))
	{
		SC_HANDLE hSCManager = NULL;
		PSTR displayName = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear string
			S_STORE_STR(display, "");

			// open sc manager
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			DWORD displayNameSize = 0;

			// calculate size needed
			GetServiceDisplayName(hSCManager, service, displayName, &displayNameSize);

			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				LastError(0);

				// alloc memory
				displayName = (PSTR)NewMem(++displayNameSize);

				// get display name
				if(GetServiceDisplayName(hSCManager, service, displayName, &displayNameSize))
					S_STORE_STR(display, displayName);
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(displayName);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::GetServiceDisplayName($server, $servicedb, $service, \\$display)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the key name of a service display name
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 display	 - service display name
//				 key			 - gets the key name
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_GetServiceKeyName)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *key = NULL;

	if(items == 4 && CHK_ASSIGN_SREF(key, ST(3)))
	{
		SC_HANDLE hSCManager = NULL;
		PSTR keyName = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR display = SvPV(ST(2), PL_na);

			// clear string
			S_STORE_STR(key, "");

			// open sc manager
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();
			
			DWORD keyNameSize = 0;

			// calculate size needed
			GetServiceKeyName(hSCManager, display, keyName, &keyNameSize);

			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				LastError(0);

				// alloc memory
				keyName = (PSTR)NewMem(++keyNameSize);

				// get key name
				if(GetServiceKeyName(hSCManager, display, keyName, &keyNameSize))
					S_STORE_STR(key, keyName);
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(keyName);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::GetServiceKeyName($server, $servicedb, $display, \\$key)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// locks a service database
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 lock			 - gets the lock handle to the service database
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_LockServiceDatabase)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *dbLock = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(dbLock, ST(2)))
	{
		SC_HANDLE hSCManager = NULL;
		PSTR server = NULL;

		__try
		{
			// get server and database
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);

			// clear lock
			S_STORE_STR(dbLock, "");

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_LOCK)))
				RaiseFalse();
			
			SC_LOCK lock = NULL;

			// lock database
			if(lock = LockServiceDatabase(hSCManager))
				S_STORE_INT(dbLock, (int)lock);
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hSCManager);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::LockServiceDatabase($server, $servicedb, \\$lock)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// unlocks a service database
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 lock			 - lock handle to unlock service database
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_UnlockServiceDatabase)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		SC_HANDLE hSCManager = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and lock
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			SC_LOCK lock = (SC_LOCK)SvIV(ST(2));

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_LOCK)))
				RaiseFalse();

			// unlock database
			if(!UnlockServiceDatabase(lock))
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hSCManager);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::UnlockServiceDatabase($server, $servicedb, $lock)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// queries the service database lock status
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 status		 - gets the lock status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceLockStatus)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 3 && CHK_ASSIGN_HREF(status, ST(2)))
	{
		SC_HANDLE hSCManager = NULL;
		QUERY_SERVICE_LOCK_STATUS *lockStatus = NULL;
		PSTR server = NULL;

		__try
		{
			// get server and database
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_QUERY_LOCK_STATUS)))
				RaiseFalse();

			DWORD lockStatusSize = 0;

			// calculate size needed
			QueryServiceLockStatus(hSCManager, lockStatus, lockStatusSize, &lockStatusSize);

			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				// alloc memory
				lockStatus = (QUERY_SERVICE_LOCK_STATUS*)NewMem(lockStatusSize);
				LastError(0);

				// enum dependent services
				if(QueryServiceLockStatus(hSCManager, lockStatus, lockStatusSize, &lockStatusSize))
				{
					// copy result
					H_STORE_INT(status, "locked", lockStatus->fIsLocked);
					H_STORE_STR(status, "owner", lockStatus->lpLockOwner);
					H_STORE_INT(status, "duration", lockStatus->dwLockDuration);
				}
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(lockStatus);
		CleanServiceHandle(hSCManager);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::QueryServiceLockStatus($server, $servicedb, \\%%status)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the configuration of a service
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 config		 - gets the service configuration
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceConfig)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *config = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(config, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		QUERY_SERVICE_CONFIG *serviceConfig = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(config);

			// open sc manager and service
			hSCManager = 
				OpenSCManager(server, database && *database ? database : NULL, SC_MANAGER_CONNECT);

			hService = 
				hSCManager ? OpenService(hSCManager, service, SERVICE_QUERY_CONFIG) : NULL; 

			DWORD serviceConfigSize = 0;

			// calculate size needed
			QueryServiceConfig(hService, serviceConfig, serviceConfigSize, &serviceConfigSize);

			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				// alloc memory
				serviceConfig = (QUERY_SERVICE_CONFIG*)NewMem(serviceConfigSize);

				LastError(0);

				// enum dependent services
				if(QueryServiceConfig(hService, serviceConfig, serviceConfigSize, &serviceConfigSize))
				{
					// copy result
					H_STORE_INT(config, "type", serviceConfig->dwServiceType);
					H_STORE_INT(config, "start", serviceConfig->dwStartType);
					H_STORE_INT(config, "control", serviceConfig->dwErrorControl);
					H_STORE_STR(config, "filename", serviceConfig->lpBinaryPathName);
					H_STORE_STR(config, "group", serviceConfig->lpLoadOrderGroup);
					H_STORE_INT(config, "tagid", serviceConfig->dwTagId);
					H_STORE_STR(config, "account", serviceConfig->lpServiceStartName);
					H_STORE_STR(config, "display", serviceConfig->lpDisplayName);

					if(serviceConfig->lpDependencies && *serviceConfig->lpDependencies)
					{
						// store dependencies
						AV *depend = NewAV;

						for(PSTR dependPtr = serviceConfig->lpDependencies; *dependPtr; 
								dependPtr += strlen(dependPtr) + 1)
							A_STORE_STR(depend, dependPtr);

						H_STORE_REF(config, "dependencies", depend);

						// decrement reference count
						SvREFCNT_dec(depend);
					}
				}
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(serviceConfig);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::QueryServiceConfig($server, $servicedb, $service, \\%%config)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the service status
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 status		 - gets the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceStatus)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			SERVICE_STATUS servStatus;

			if(hService = OpenService(hSCManager, service, SERVICE_QUERY_STATUS))
			{
				if(QueryServiceStatus(hService, &servStatus))
				{
					H_STORE_INT(status, "type", servStatus.dwServiceType);
					H_STORE_INT(status, "state", servStatus.dwCurrentState);
					H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
					H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
					H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
					H_STORE_INT(status, "check", servStatus.dwCheckPoint);
					H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				}
				else
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::QueryServiceStatus($server, $servicedb, $service, \\%%status)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the service security descriptor
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 secInfo	 - security information to get
//				 security	 - gets the service security descriptor
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceObjectSecurity)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *security = NULL;

	if(items == 5 && CHK_ASSIGN_SREF(security, ST(4)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSECURITY_DESCRIPTOR secDesc = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);
			SECURITY_INFORMATION secInfo = SvIV(ST(3));

			// clear security descriptor
			S_STORE_STR(security, "");

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			if(!(hService = OpenService(hSCManager, service, READ_CONTROL)))
				RaiseFalse();

			DWORD secDescSize = 0;

			// calculate size
			QueryServiceObjectSecurity(hService, secInfo, &secDesc, secDescSize, &secDescSize);
			
			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				// alloc memory
				secDesc = (PSECURITY_DESCRIPTOR)NewMem(secDescSize);

				LastError(0);

				// get security descriptor
				if(QueryServiceObjectSecurity(hService, secInfo, secDesc, secDescSize, &secDescSize))
					S_STORE_PTR(security, secDesc, secDescSize);
				else
					LastError(GetLastError());
			}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(secDesc);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::QueryServiceObjectSecurity($server, $servicedb, $service, $secinfo, \\$security)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the service security descriptor
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 secInfo	 - security information to set
//				 security	 - service security descriptor to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_SetServiceObjectSecurity)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 5)
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);
			SECURITY_INFORMATION secInfo = SvIV(ST(3));
			PSECURITY_DESCRIPTOR security = SvPV(ST(4), PL_na);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			DWORD serviceAccess = 
				(secInfo & (OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION) ? WRITE_OWNER : 0) |
				(secInfo & DACL_SECURITY_INFORMATION ? WRITE_DAC : 0) |
				(secInfo & SACL_SECURITY_INFORMATION ? ACCESS_SYSTEM_SECURITY : 0);

			if(!(hService = OpenService(hSCManager, service, serviceAccess)))
				RaiseFalse();

			// set security descriptor
			if(!SetServiceObjectSecurity(hService, secInfo, security))
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::SetServiceObjectSecurity($server, $servicedb, $service, $secinfo, $security)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// changes a service configuration properties for w2k services
//
// param:  server				- computer to continue the service
//				 servicedb		- service database name (normally null)
//				 service			- service name
//				 param				- parameter to change service config
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_ChangeServiceConfig2)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *param = NULL;
	AV *depend = NULL; 

	if(items == 4 && CHK_ASSIGN_HREF(param, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL, database = NULL, service = NULL;
		DWORD infoLevel = 0;
		SERVICE_DESCRIPTION description = { NULL };
		SERVICE_FAILURE_ACTIONS failActions = { 0, NULL, NULL, 0, NULL };

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			database = SvPV(ST(1), PL_na);
			service = SvPV(ST(2), PL_na);

			// get parameter
			if(H_EXISTS(param, "description"))
			{
				infoLevel |= SERVICE_CONFIG_DESCRIPTION;
				description.lpDescription = H_FETCH_STR(param, "description");
			}

			if(H_EXISTS(param, "resetperiod") || H_EXISTS(param, "rebootmsg") || 
				 H_EXISTS(param, "command") || H_EXISTS(param, "actions"))
			{
				infoLevel |= SERVICE_CONFIG_FAILURE_ACTIONS;
				failActions.dwResetPeriod = H_EXISTS_FETCH_INT(param, "resetperiod", 0);
				failActions.lpRebootMsg = H_EXISTS_FETCH_STR(param, "rebootmsg", NULL);
				failActions.lpCommand = H_EXISTS_FETCH_STR(param, "command", NULL);

				if(H_EXISTS(param, "actions"))
				{
					AV *actions = H_FETCH_RARRAY(param, "actions");

					failActions.cActions = AV_LEN(actions) + 1;
					failActions.lpsaActions = (SC_ACTION*)NewMem(failActions.cActions * sizeof(SC_ACTION));

					for(DWORD count = 0; count < failActions.cActions; count++)
					{
						HV *action = A_FETCH_RHASH(actions, count);

						failActions.lpsaActions[count].Type = (SC_ACTION_TYPE)H_FETCH_INT(action, "type");
						failActions.lpsaActions[count].Delay = H_FETCH_INT(action, "delay");
					}
				}
			}

			// return the library error if the library isn't loaded correctly
			if(!ChangeServiceConfig2Call)
				RaiseFalseError(AdvApi32LibError);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			if(hService = OpenService(hSCManager, service, SERVICE_CHANGE_CONFIG))
			{
				if(infoLevel & SERVICE_CONFIG_DESCRIPTION &&
					 !ChangeServiceConfig2Call(hService, SERVICE_CONFIG_DESCRIPTION, &description))
					LastError(GetLastError());

				if(infoLevel & SERVICE_CONFIG_FAILURE_ACTIONS &&
					 !ChangeServiceConfig2Call(hService, SERVICE_CONFIG_FAILURE_ACTIONS, &failActions))
					LastError(GetLastError());
			}
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
		CleanPtr(failActions.lpsaActions);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::ChangeServiceConfig2($server, $servicedb, $service, \\%%param)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the configuration properties for w2k services
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 config		 - gets the service configuration
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceConfig2)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *config = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(config, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		SERVICE_DESCRIPTION *serviceDesc = NULL;
		SERVICE_FAILURE_ACTIONS *serviceActions = NULL;
		PSTR server = NULL;
		DWORD serviceDescSize = 0, serviceActionsSize = 0;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(config);

			// return the library error if the library isn't loaded correctly
			if(!QueryServiceConfig2Call)
				RaiseFalseError(AdvApi32LibError);

			// open sc manager and service
			hSCManager = 
				OpenSCManager(server, database && *database ? database : NULL, SC_MANAGER_CONNECT);

			hService = 
				hSCManager ? OpenService(hSCManager, service, SERVICE_QUERY_CONFIG) : NULL; 

			DWORD serviceConfigSize = 0;

			// calculate size needed
			QueryServiceConfig2Call(hService, SERVICE_CONFIG_DESCRIPTION, (PBYTE)serviceDesc, 
															serviceDescSize, &serviceDescSize);

			if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
			{
				// alloc memory
				serviceDesc = (SERVICE_DESCRIPTION*)NewMem(serviceDescSize);

				LastError(0);

				if(QueryServiceConfig2Call(hService, SERVICE_CONFIG_DESCRIPTION, (PBYTE)serviceDesc,
																	 serviceDescSize, &serviceDescSize))
					// copy result
					H_STORE_STR(config, "description", serviceDesc->lpDescription);
				else
					LastError(GetLastError());
			} // if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER) 

			if(!LastError())
			{
				// calculate size needed
				QueryServiceConfig2Call(hService, SERVICE_CONFIG_FAILURE_ACTIONS, (PBYTE)serviceActions, 
																serviceActionsSize, &serviceActionsSize);

				if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER)
				{
					// alloc memory
					serviceActions = (SERVICE_FAILURE_ACTIONS*)NewMem(serviceActionsSize);

					LastError(0);

					if(QueryServiceConfig2Call(hService, SERVICE_CONFIG_FAILURE_ACTIONS, 
																		 (PBYTE)serviceActions, serviceActionsSize, 
																		 &serviceActionsSize))
					{
						// copy result
						H_STORE_INT(config, "resetperiod", serviceActions->dwResetPeriod);
						H_STORE_STR(config, "rebootmsg", serviceActions->lpRebootMsg);
						H_STORE_STR(config, "command", serviceActions->lpCommand);

						if(serviceActions->cActions)
						{
							AV *actions = NewAV;

							for(DWORD count = 0; count < serviceActions->cActions; count++)
							{
								HV *properties = NewHV;

								H_STORE_INT(properties, "type", serviceActions->lpsaActions[count].Type);
								H_STORE_INT(properties, "delay", serviceActions->lpsaActions[count].Delay);

								A_STORE_REF(actions, properties);

								// decrement reference count
								SvREFCNT_dec(properties);
							}

							H_STORE_REF(config, "actions", actions);

							// decrement reference count
							SvREFCNT_dec(actions);
						}
					}
					else
						LastError(GetLastError());
				} // if(LastError(GetLastError()) == ERROR_INSUFFICIENT_BUFFER) 
			} // if(!LastError())
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(serviceDesc);
		CleanPtr(serviceActions);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::QueryServiceConfig2($server, $servicedb, $service, \\%%config)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the service status for w2k services
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 status		 - gets the service status
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceStatusEx)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *status = NULL;

	if(items == 4 && CHK_ASSIGN_HREF(status, ST(3)))
	{
		SC_HANDLE hSCManager = NULL, hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);

			// clear hash
			HV_CLEAR(status);

			// return the library error if the library isn't loaded correctly
			if(!QueryServiceStatusExCall)
				RaiseFalseError(AdvApi32LibError);

			// open sc manager and service
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			SERVICE_STATUS_PROCESS servStatus;
			DWORD servStatusSize = sizeof(servStatus);

			if((hService = OpenService(hSCManager, service, SERVICE_QUERY_STATUS)) &&
				 QueryServiceStatusExCall(hService, SC_STATUS_PROCESS_INFO, (PBYTE)&servStatus,
																	servStatusSize, &servStatusSize))
			{
				H_STORE_INT(status, "type", servStatus.dwServiceType);
				H_STORE_INT(status, "state", servStatus.dwCurrentState);
				H_STORE_INT(status, "accepted", servStatus.dwControlsAccepted);
				H_STORE_INT(status, "win32exitcode", servStatus.dwWin32ExitCode);
				H_STORE_INT(status, "specificexitcode", servStatus.dwServiceSpecificExitCode);
				H_STORE_INT(status, "check", servStatus.dwCheckPoint);
				H_STORE_INT(status, "hint", servStatus.dwWaitHint);
				H_STORE_INT(status, "processid", servStatus.dwProcessId);
				H_STORE_INT(status, "serviceflags", servStatus.dwServiceFlags);
			} // if((hService = OpenService(...
			else
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 4 && ...)
	else
		croak("Usage: Win32::Lanman::QueryServiceStatusEx($server, $servicedb, $service, \\%%status)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// enumerates w2k services status
//
// param:  server    - computer to continue the service
//				 servicedb - service database name (normally null)
//				 type			 - service type to enum
//				 state		 - service state to enum
//				 services  - services array
//				 group		 - services group
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_EnumServicesStatusEx)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *services = NULL;

	if((items >= 5 || items <= 6) && CHK_ASSIGN_AREF(services, ST(4)))
	{
		SC_HANDLE hSCManager = NULL;
		ENUM_SERVICE_STATUS_PROCESS *servStatus = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database, type and state
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			int type = SvIV(ST(2));
			int state = SvIV(ST(3));
			PSTR group = items == 6 ? SvPV(ST(5), PL_na) : NULL;

			// clear array
			AV_CLEAR(services);

			// return the library error if the library isn't loaded correctly
			if(!EnumServicesStatusExCall)
				RaiseFalseError(AdvApi32LibError);

			// open sc manager
			if(!(hSCManager = OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_ENUMERATE_SERVICE)))
				RaiseFalse();
			
			// did we got an handle, then enum services
			DWORD servStatusSize = 0, servStatusCount = 0, handle = 0;

			// calculate size needed
			EnumServicesStatusExCall(hSCManager, SC_ENUM_PROCESS_INFO, type, state, (PBYTE)servStatus, 
															 servStatusSize, &servStatusSize, &servStatusCount, &handle,
															 group);

			if(LastError(GetLastError()) == ERROR_MORE_DATA)
			{
				LastError(0);

				// alloc memory
				servStatus = (ENUM_SERVICE_STATUS_PROCESS*)NewMem(servStatusSize);

				// enum services
				if(EnumServicesStatusExCall(hSCManager, SC_ENUM_PROCESS_INFO, type, state, 
																		(PBYTE)servStatus, servStatusSize, &servStatusSize,	
																		&servStatusCount, &handle, group))
				{
					// copy result
					for(DWORD count = 0; count < servStatusCount; count++)
					{
						// store service properties
						HV *properties = NewHV;

						H_STORE_STR(properties, "name", servStatus[count].lpServiceName);
						H_STORE_STR(properties, "display", servStatus[count].lpDisplayName);
						H_STORE_INT(properties, "type", 
												servStatus[count].ServiceStatusProcess.dwServiceType);
						H_STORE_INT(properties, "state", 
												servStatus[count].ServiceStatusProcess.dwCurrentState);
						H_STORE_INT(properties, "accepted", 
												servStatus[count].ServiceStatusProcess.dwControlsAccepted);
						H_STORE_INT(properties, "win32exitcode", 
												servStatus[count].ServiceStatusProcess.dwWin32ExitCode);
						H_STORE_INT(properties, "specificexitcode", 
												servStatus[count].ServiceStatusProcess.dwServiceSpecificExitCode);
						H_STORE_INT(properties, "check", 
												servStatus[count].ServiceStatusProcess.dwCheckPoint);
						H_STORE_INT(properties, "hint", servStatus[count].ServiceStatusProcess.dwWaitHint);
						H_STORE_INT(properties, "processid", 
												servStatus[count].ServiceStatusProcess.dwProcessId);
						H_STORE_INT(properties, "serviceflags", 
												servStatus[count].ServiceStatusProcess.dwServiceFlags);

						A_STORE_REF(services, properties);

						// decrement reference count
						SvREFCNT_dec(properties);
					}
				} // if(EnumServicesStatusExCall(hSCManager, ...
				else
					LastError(GetLastError());
			}
			else // if(LastError(GetLastError()) == ERROR_MORE_DATA)
				LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(servStatus);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::EnumServicesStatusEx($server, $servicedb, $type, $state, "
																											"\\@services [, $group])\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// 
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 secInfo	 - security information to set
//				 security	 - service security descriptor to set
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////
/*
XS(XS_NT__Lanman_EnumServiceGroup)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 5)
	{
		SC_HANDLE hSCManager = NULL;
		SC_HANDLE hService = NULL;
		PSTR server = NULL;

		__try
		{
			// get server, database and service
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			PSTR database = SvPV(ST(1), PL_na);
			PSTR service = SvPV(ST(2), PL_na);
			SECURITY_INFORMATION secInfo = SvIV(ST(3));
			PSECURITY_DESCRIPTOR security = SvPV(ST(4), PL_na);

			// open sc manager and service
			if(!(hSCManager =	OpenSCManager(server, database && *database ? database : NULL, 
																			SC_MANAGER_CONNECT)))
				RaiseFalse();

			if(!(hService = OpenService(hSCManager, service, SERVICE_ALL_ACCESS)))
				RaiseFalse();

			WCHAR group[2048];
			DWORD size = 2048;

			//if(!EnumServiceGroupW(hService, group, size, &size))
			//	LastError(GetLastError());
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanServiceHandle(hService);
		CleanServiceHandle(hSCManager);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::EnumServiceGroup($server, $servicedb, $service, $secinfo, $security)\n");
	
	RETURNRESULT(LastError() == 0);
}
*/
