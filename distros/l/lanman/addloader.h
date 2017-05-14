#ifndef __ADDLOADER_H
#define __ADDLOADER_H


#include <windows.h>
#include <lm.h>


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

// additional function prototypes exported by netapi32.dll
typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetJoinDomainFunc)(PCWSTR server, PCWSTR domain, 
																				PCWSTR accountOU, PCWSTR account, 
																				PCWSTR password, DWORD options);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetUnjoinDomainFunc)(PCWSTR server, PCWSTR account, 
																					PCWSTR password, DWORD options);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetRenameMachineInDomainFunc)(PCWSTR server, 
																									 PCWSTR newMachineName,
																									 PCWSTR account, PCWSTR password,
																									 DWORD options);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetValidateNameFunc)(PCWSTR server, PCWSTR name, PCWSTR account,
																					PCWSTR password, NETSETUP_NAME_TYPE nameType);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetGetJoinInformationFunc)(PCWSTR server, PWSTR *nameBuffer,
																								PNETSETUP_JOIN_STATUS bufferType);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetGetJoinableOUsFunc)(PCWSTR server, PCWSTR domain, 
																						PCWSTR account, PCWSTR password,
																						PDWORD oUsCount, PWSTR **oUs);

typedef NET_API_STATUS 
	(NET_API_FUNCTION 
		*NetRegisterDomainNameChangeNotificationFunc)(PHANDLE NotificationEventHandle);

typedef NET_API_STATUS 
	(NET_API_FUNCTION 
		*NetUnregisterDomainNameChangeNotificationFunc)(HANDLE NotificationEventHandle);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsAddFtRootFunc)(PWSTR server, PWSTR root, PWSTR ftDfs,
																					PWSTR comment, DWORD flags);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsAddStdRootFunc)(PWSTR server, PWSTR root, PWSTR comment, 
																					 DWORD flags);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsAddStdRootForcedFunc)(PWSTR server, PWSTR root, 
																								 PWSTR comment, PWSTR store);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsGetClientInfoFunc)(PWSTR dfsEntry, PWSTR  server, PWSTR share,
																						  DWORD level, PBYTE *buffer);

typedef NET_API_STATUS
	(NET_API_FUNCTION *NetDfsManagerInitializeFunc)(PWSTR server, DWORD flags);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsRemoveFtRootFunc)(PWSTR server, PWSTR root, PWSTR ftDfs,
																						 DWORD flags);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsRemoveFtRootForcedFunc)(PWSTR domain, PWSTR server, PWSTR root, 
																									 PWSTR ftDfs, DWORD flags);

typedef NET_API_STATUS 
	(NET_API_FUNCTION *NetDfsRemoveStdRootFunc)(PWSTR server, PWSTR root, DWORD flags);

typedef NET_API_STATUS
	(NET_API_FUNCTION *NetDfsSetClientInfoFunc)(PWSTR dfsEntry, PWSTR  server, PWSTR share,
																						  DWORD level, PBYTE buffer);

typedef NET_API_STATUS
	(NET_API_FUNCTION *NetDfsGetDcAddressFunc)(PWSTR server, PWSTR *dcIpAddr, 
																						 BOOLEAN *isRoot, ULONG *timeout);

// additional function prototypes exported by netapi32.dll
typedef WINADVAPI BOOL 
	(WINAPI *ChangeServiceConfig2Func)(SC_HANDLE hService, DWORD infoLevel, PVOID info);

typedef WINADVAPI BOOL 
	(WINAPI *EnumServicesStatusExFunc)(SC_HANDLE hSCManager, SC_ENUM_TYPE infoLevel, 
																		 DWORD serviceType, DWORD serviceState, PBYTE services, 
																		 DWORD bufSize, PDWORD bytesNeeded, PDWORD servicesReturned,
																		 PDWORD resumeHandle, PCSTR groupName);

typedef WINADVAPI BOOL 
	(WINAPI *QueryServiceConfig2Func)(SC_HANDLE hService, DWORD infoLevel, PBYTE buffer, 
																		DWORD bufSize, PDWORD bytesNeeded);

typedef WINADVAPI BOOL 
	(WINAPI *QueryServiceStatusExFunc)(SC_HANDLE hService, SC_STATUS_TYPE infoLevel, PBYTE buffer,
																		 DWORD bufSize, PDWORD bytesNeeded);


///////////////////////////////////////////////////////////////////////////////
//
// globals
//
///////////////////////////////////////////////////////////////////////////////

// library handle and error
extern HINSTANCE hNetApi32Library;
extern DWORD NetApi32LibError;
extern HINSTANCE hAdvApi32Library;
extern DWORD AdvApi32LibError;

// function pointers exported by netapi32.dll
extern NetJoinDomainFunc NetJoinDomainCall;
extern NetUnjoinDomainFunc NetUnjoinDomainCall;
extern NetRenameMachineInDomainFunc NetRenameMachineInDomainCall;
extern NetValidateNameFunc NetValidateNameCall;
extern NetGetJoinInformationFunc NetGetJoinInformationCall;
extern NetGetJoinableOUsFunc NetGetJoinableOUsCall;
extern NetRegisterDomainNameChangeNotificationFunc 
	NetRegisterDomainNameChangeNotificationCall;
extern NetUnregisterDomainNameChangeNotificationFunc 
	NetUnregisterDomainNameChangeNotificationCall;
extern NetDfsAddFtRootFunc NetDfsAddFtRootCall;
extern NetDfsAddStdRootFunc NetDfsAddStdRootCall;
extern NetDfsAddStdRootForcedFunc NetDfsAddStdRootForcedCall;
extern NetDfsGetClientInfoFunc NetDfsGetClientInfoCall;
extern NetDfsManagerInitializeFunc NetDfsManagerInitializeCall;
extern NetDfsRemoveFtRootFunc NetDfsRemoveFtRootCall;
extern NetDfsRemoveFtRootForcedFunc NetDfsRemoveFtRootForcedCall;
extern NetDfsRemoveStdRootFunc NetDfsRemoveStdRootCall;
extern NetDfsSetClientInfoFunc NetDfsSetClientInfoCall;
extern NetDfsGetDcAddressFunc NetDfsGetDcAddressCall;

// function pointers exported by advapi32.dll
extern ChangeServiceConfig2Func ChangeServiceConfig2Call;
extern EnumServicesStatusExFunc EnumServicesStatusExCall;
extern QueryServiceConfig2Func QueryServiceConfig2Call;
extern QueryServiceStatusExFunc QueryServiceStatusExCall;


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// initializes the additional dlls
//
// param:  
//
// return: 
//
///////////////////////////////////////////////////////////////////////////////

void InitAddDlls();


///////////////////////////////////////////////////////////////////////////////
//
// unloads the additional dlls
//
// param:  
//
// return: 
//
///////////////////////////////////////////////////////////////////////////////

void ReleaseAddDlls();



#endif //#ifndef __ADDLOADER_H
