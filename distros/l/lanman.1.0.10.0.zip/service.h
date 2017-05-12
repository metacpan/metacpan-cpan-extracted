#ifndef __SERVICE_H
#define __SERVICE_H


#include "plmisc.h"


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
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

XS(XS_NT__Lanman_StartService);


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

XS(XS_NT__Lanman_StopService);


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

XS(XS_NT__Lanman_PauseService);


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

XS(XS_NT__Lanman_ContinueService);


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

XS(XS_NT__Lanman_InterrogateService);


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

XS(XS_NT__Lanman_ControlService);


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

XS(XS_NT__Lanman_CreateService);


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

XS(XS_NT__Lanman_DeleteService);


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

XS(XS_NT__Lanman_EnumServicesStatus);


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

XS(XS_NT__Lanman_EnumDependentServices);


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

XS(XS_NT__Lanman_ChangeServiceConfig);


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

XS(XS_NT__Lanman_GetServiceDisplayName);


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

XS(XS_NT__Lanman_GetServiceKeyName);


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

XS(XS_NT__Lanman_LockServiceDatabase);


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

XS(XS_NT__Lanman_UnlockServiceDatabase);


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

XS(XS_NT__Lanman_QueryServiceConfig);


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

XS(XS_NT__Lanman_QueryServiceLockStatus);


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

XS(XS_NT__Lanman_QueryServiceStatus);


///////////////////////////////////////////////////////////////////////////////
//
// gets the service security descriptor
//
// param:  server		 - computer to continue the service
//				 servicedb - service database name (normally null)
//				 service	 - service name
//				 security	 - gets the service security descriptor
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_QueryServiceObjectSecurity);


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

XS(XS_NT__Lanman_SetServiceObjectSecurity);


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
XS(XS_NT__Lanman_ChangeServiceConfig2);


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

XS(XS_NT__Lanman_QueryServiceConfig2);


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

XS(XS_NT__Lanman_QueryServiceStatusEx);


///////////////////////////////////////////////////////////////////////////////
//
// enumerates w2k services status
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

XS(XS_NT__Lanman_EnumServicesStatusEx);


#endif //#ifndef __SERVICE_H

