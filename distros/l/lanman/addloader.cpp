#define WIN32_LEAN_AND_MEAN


#ifndef __ADDLOADER_CPP
#define __ADDLOADER_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "addloader.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "plmisc.h"
#include "usererror.h"


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#define NETAPI32_DLL	"netapi32.dll"

// set the loaded function pointers to null
#define	ZERO_NETAPI32_LIB_POINTERS													\
	{	NetJoinDomainCall = NULL;																\
		NetUnjoinDomainCall = NULL;															\
		NetRenameMachineInDomainCall = NULL;										\
		NetValidateNameCall = NULL;															\
		NetGetJoinInformationCall = NULL;												\
		NetGetJoinableOUsCall = NULL;														\
		NetRegisterDomainNameChangeNotificationCall = NULL;			\
		NetUnregisterDomainNameChangeNotificationCall = NULL;		\
		NetDfsAddFtRootCall = NULL;															\
		NetDfsAddStdRootCall = NULL;														\
		NetDfsAddStdRootForcedCall = NULL;											\
		NetDfsGetClientInfoCall = NULL;													\
		NetDfsManagerInitializeCall = NULL;											\
		NetDfsRemoveFtRootCall = NULL;													\
		NetDfsRemoveFtRootForcedCall = NULL;										\
		NetDfsRemoveStdRootCall = NULL;													\
		NetDfsSetClientInfoCall = NULL;													\
		NetDfsGetDcAddressCall = NULL;													\
}

// stores a function pointer
#define LOAD_NETAPI32_FUNC(func, ansistr) \
	(func##Call = (func##Func)GetProcAddress(hNetApi32Library, #func##ansistr))

#define ADVAPI32_DLL	"advapi32.dll"

// set the loaded function pointers to null
#define	ZERO_ADVAPI32_LIB_POINTERS													\
	{	ChangeServiceConfig2Call = NULL;												\
		EnumServicesStatusExCall = NULL;												\
		QueryServiceConfig2Call = NULL;													\
		QueryServiceStatusExCall = NULL;												\
}

// stores a function pointer
#define LOAD_ADVAPI32_FUNC(func, ansistr) \
	(func##Call = (func##Func)GetProcAddress(hAdvApi32Library, #func##ansistr))


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// library handle and error
HINSTANCE hNetApi32Library = NULL;
DWORD NetApi32LibError = 0;
HINSTANCE hAdvApi32Library = NULL;
DWORD AdvApi32LibError = 0;

// function pointers exported by netapi32.dll
NetJoinDomainFunc NetJoinDomainCall = NULL;
NetUnjoinDomainFunc NetUnjoinDomainCall = NULL;
NetRenameMachineInDomainFunc NetRenameMachineInDomainCall = NULL;
NetValidateNameFunc NetValidateNameCall = NULL;
NetGetJoinInformationFunc NetGetJoinInformationCall = NULL;
NetGetJoinableOUsFunc NetGetJoinableOUsCall = NULL;
NetRegisterDomainNameChangeNotificationFunc 
	NetRegisterDomainNameChangeNotificationCall = NULL;
NetUnregisterDomainNameChangeNotificationFunc 
	NetUnregisterDomainNameChangeNotificationCall = NULL;

NetDfsAddFtRootFunc NetDfsAddFtRootCall = NULL;
NetDfsAddStdRootFunc NetDfsAddStdRootCall = NULL;
NetDfsAddStdRootForcedFunc NetDfsAddStdRootForcedCall = NULL;
NetDfsGetClientInfoFunc NetDfsGetClientInfoCall = NULL;
NetDfsManagerInitializeFunc NetDfsManagerInitializeCall = NULL;
NetDfsRemoveFtRootFunc NetDfsRemoveFtRootCall = NULL;
NetDfsRemoveFtRootForcedFunc NetDfsRemoveFtRootForcedCall = NULL;
NetDfsRemoveStdRootFunc NetDfsRemoveStdRootCall = NULL;
NetDfsSetClientInfoFunc NetDfsSetClientInfoCall = NULL;
NetDfsGetDcAddressFunc NetDfsGetDcAddressCall = NULL;

// function pointers exported by advapi32.dll
ChangeServiceConfig2Func ChangeServiceConfig2Call = NULL;
EnumServicesStatusExFunc EnumServicesStatusExCall = NULL;
QueryServiceConfig2Func QueryServiceConfig2Call = NULL;
QueryServiceStatusExFunc QueryServiceStatusExCall = NULL;


///////////////////////////////////////////////////////////////////////////////
//
// initializes the netapi32 dll (netapi32.dll)
//
// param:  
//
// return: success - 1 
//         failure - 0 
//
// note:   if the dll isn't loaded successfully or if a function could not be
//				 resolved, all other function pointers will be set to null and the
//				 result is a 0; call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

int InitNetApi32Dll()
{
	ErrorAndResult;

	__try
	{
		// try to load library
		if(!(hNetApi32Library = LoadLibrary(NETAPI32_DLL)))
			RaiseFalse();

#pragma warning(disable : 4003)
		// get function pointers
		if(!LOAD_NETAPI32_FUNC(NetJoinDomain))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetUnjoinDomain))
			RaiseFalse();
		
		if(!LOAD_NETAPI32_FUNC(NetRenameMachineInDomain))
			RaiseFalse();
		
		if(!LOAD_NETAPI32_FUNC(NetValidateName))
			RaiseFalse();
		
		if(!LOAD_NETAPI32_FUNC(NetGetJoinInformation))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetGetJoinableOUs))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetRegisterDomainNameChangeNotification))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetUnregisterDomainNameChangeNotification))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsAddFtRoot))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsAddStdRoot))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsAddStdRootForced))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsGetClientInfo))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsManagerInitialize))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsRemoveFtRoot))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsRemoveFtRootForced))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsRemoveStdRoot))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsSetClientInfo))
			RaiseFalse();

		if(!LOAD_NETAPI32_FUNC(NetDfsGetDcAddress))
			RaiseFalse();

#pragma warning(default : 4003)
	}
	__except(SetExceptCode(excode))
	{
		// set last error 
		LastError(error ? error : excode);

		// set library error
		NetApi32LibError = error ? error : excode;

		// unload library if an error occured
		CleanLibrary(hNetApi32Library);

		// reset function pointers
		ZERO_NETAPI32_LIB_POINTERS;
	}

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// unloads the net api dll (netapi32.dll)
//
// param:  
//
// return: success - 1 (returns always 1)
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

int ReleaseNetApi32Dll()
{
	ErrorAndResult;

	// reset function pointers
	ZERO_NETAPI32_LIB_POINTERS;

	// unload library
	CleanLibrary(hNetApi32Library);

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// initializes the advanced api32 dll (advapi32.dll)
//
// param:  
//
// return: success - 1 
//         failure - 0 
//
// note:   if the dll isn't loaded successfully or if a function could not be
//				 resolved, all other function pointers will be set to null and the
//				 result is a 0; call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

int InitAdvApi32Dll()
{
	ErrorAndResult;

	__try
	{
		// try to load library
		if(!(hAdvApi32Library = LoadLibrary(ADVAPI32_DLL)))
			RaiseFalse();

#pragma warning(disable : 4003)
		// get function pointers
		if(!LOAD_ADVAPI32_FUNC(ChangeServiceConfig2, "A"))
			RaiseFalse();

		if(!LOAD_ADVAPI32_FUNC(EnumServicesStatusEx, "A"))
			RaiseFalse();

		if(!LOAD_ADVAPI32_FUNC(QueryServiceStatusEx))
			RaiseFalse();

		if(!LOAD_ADVAPI32_FUNC(QueryServiceConfig2, "A"))
			RaiseFalse();

#pragma warning(default : 4003)
	}
	__except(SetExceptCode(excode))
	{
		// set last error 
		LastError(error ? error : excode);

		// set library error
		AdvApi32LibError = error ? error : excode;

		// unload library if an error occured
		CleanLibrary(hAdvApi32Library);

		// reset function pointers
		ZERO_ADVAPI32_LIB_POINTERS;
	}

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// unloads the advanced api dll (advapi32.dll)
//
// param:  
//
// return: success - 1 (returns always 1)
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

int ReleaseAdvApi32Dll()
{
	ErrorAndResult;

	// reset function pointers
	ZERO_ADVAPI32_LIB_POINTERS;

	// unload library
	CleanLibrary(hAdvApi32Library);

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// initializes the additional dlls
//
// param:  
//
// return: 
//
///////////////////////////////////////////////////////////////////////////////

void InitAddDlls()
{
	// initialize the additional dlls
	InitNetApi32Dll();
	InitAdvApi32Dll();
}


///////////////////////////////////////////////////////////////////////////////
//
// unloads the additional dlls
//
// param:  
//
// return: 
//
///////////////////////////////////////////////////////////////////////////////

void ReleaseAddDlls()
{
	// release the additional dlls
	ReleaseNetApi32Dll();
	ReleaseAdvApi32Dll();
}


