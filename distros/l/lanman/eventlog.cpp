#define WIN32_LEAN_AND_MEAN


#ifndef __EVENTLOG_CPP
#define __EVENTLOG_CPP
#endif


#include <windows.h>


#include "eventlog.h"
#include "wstring.h"
#include "strhlp.h"
#include "misc.h"
#include "reghlp.h"
#include "usererror.h"


//
// note: NetAudit* and NetErrorLog* functions are not supported by NT, you can call 
// them, but they return always error 50; in this file, you'll find the core 
// eventlog calls from windows nt
//


///////////////////////////////////////////////////////////////////////////////
//
// defines
//
///////////////////////////////////////////////////////////////////////////////

#define DEFAULT_EVENTLOG_READ_BUFFER	4096
#define DEFAULT_EXPAND_STR_SIZE				128

#define EVENT_LOG_KEY									"System\\CurrentControlSet\\Services\\EventLog"
#define ENVIRONMENT_KEY								"System\\CurrentControlSet\\Control\\Session Manager\\" \
																			"Environment"
#define SYSTEMROOT_KEY								"Software\\Microsoft\\Windows NT\\CurrentVersion"

#define FORMAT_MSG_FLAG								FORMAT_MESSAGE_ALLOCATE_BUFFER | \
																			FORMAT_MESSAGE_ARGUMENT_ARRAY | \
																			FORMAT_MESSAGE_FROM_HMODULE


///////////////////////////////////////////////////////////////////////////////
//
// globals
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

XS(XS_NT__Lanman_ReadEventLog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *events = NULL;

	if(items == 5 && CHK_ASSIGN_AREF(events, ST(4)))
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);
		DWORD first = SvIV(ST(2));
		DWORD last = SvIV(ST(3));
		HANDLE hEventLog = NULL;
		PEVENTLOGRECORD record = NULL;

		int c = 0;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));
			
			// clear array
			AV_CLEAR(events);

			// as first try to open the source as a eventlog backup ...
			if(!(hEventLog = OpenBackupEventLog(server, source)))
				// ... if this fails, open it normaly
				hEventLog = OpenEventLog(server, source);
			
			DWORD firstRecord = 0, lastRecord = 0;

			// get maximum record count
			if(hEventLog && GetOldestEventLogRecord(hEventLog, &firstRecord) &&
				 GetNumberOfEventLogRecords(hEventLog, &lastRecord))
			{
				DWORD recordSize = 0;
				DWORD readSize = 0;
				DWORD nextSize = DEFAULT_EVENTLOG_READ_BUFFER;
				DWORD direction = 
					first <= last ? EVENTLOG_FORWARDS_READ : EVENTLOG_BACKWARDS_READ;

				lastRecord += firstRecord - 1;

				// assign the first and last records
				first = first <= last ? __max(first, firstRecord) : __min(first, lastRecord);
				last = first <= last ? __min(last, lastRecord) : __max(last, firstRecord);

				while(1)
				{
					// alloc memory if needed
					if(nextSize > recordSize)
					{
						CleanPtr(record);

						record = (PEVENTLOGRECORD)NewMem(record, recordSize = nextSize, 0);
					}

					// read next records
					if(ReadEventLog(hEventLog, direction | EVENTLOG_SEEK_READ, first,
													record, recordSize, &(readSize = 0), &(nextSize = 0)))
					{
						PEVENTLOGRECORD recordPtr = record;

						// store event logs
						while(recordPtr->Length)
						{
							HV *event = NewHV;

							H_STORE_STR(event, "source", source);
							H_STORE_INT(event, "recordnumber", recordPtr->RecordNumber);
							H_STORE_INT(event, "timegenerated", recordPtr->TimeGenerated);
							H_STORE_INT(event, "timewritten", recordPtr->TimeWritten);
							H_STORE_INT(event, "eventid", recordPtr->EventID);
							H_STORE_INT(event, "eventtype", recordPtr->EventType);

							// strings
							if(recordPtr->NumStrings && recordPtr->StringOffset)
							{
								AV *strings = NewAV;
								PSTR stringPtr = (PSTR)recordPtr + recordPtr->StringOffset;

								for(DWORD count = 0; count < recordPtr->NumStrings; count++)
								{
									A_STORE_STR(strings, stringPtr);
									stringPtr += strlen(stringPtr) + 1;
								}

								H_STORE_REF(event, "strings", strings);

								// decrement reference count
								SvREFCNT_dec(strings);
							}

							H_STORE_INT(event, "eventcategory", recordPtr->EventCategory);
							H_STORE_INT(event, "reservedflags", recordPtr->ReservedFlags);
							H_STORE_INT(event, "closingrecordnumber", recordPtr->ClosingRecordNumber);

							// sid
							if(recordPtr->UserSidLength && recordPtr->UserSidOffset)
								H_STORE_PTR(event, "usersid", (PSTR)recordPtr + recordPtr->UserSidOffset,
														recordPtr->UserSidLength);

							// data
							if(recordPtr->DataLength && recordPtr->DataOffset)
								H_STORE_PTR(event, "data", (PSTR)recordPtr + recordPtr->DataOffset,
														recordPtr->DataLength);

							PSTR nextItem = (PSTR)&recordPtr->DataOffset + sizeof(recordPtr->DataOffset);

							H_STORE_STR(event, "sourcename", nextItem);
							H_STORE_STR(event, "computername", nextItem + strlen(nextItem) + 1);

							A_STORE_REF(events, event);

							// decrement reference count
							SvREFCNT_dec(event);

							if(direction == EVENTLOG_FORWARDS_READ ? ++first > last : --first < last)
								break;

							// check maximum allowed buffer length
							if((PSTR)recordPtr + recordPtr->Length >= (PSTR)record + readSize)
								break;

							// seek to the next record
							recordPtr = (PEVENTLOGRECORD)((PSTR)recordPtr + recordPtr->Length);
						} // while(recordPtr->Length)

						// reset the nextSize
						nextSize = 0;

						// did we got all records requested, then break
						if(direction == EVENTLOG_FORWARDS_READ ? first > last : first < last)
							break;
					} // if(ReadEventLog(...))
					else
					{
						if((error = GetLastError()) == ERROR_INSUFFICIENT_BUFFER && nextSize)
								continue;
						
						LastError(error);

						break;
					}
				} // while(1)
			} // if(hEventLog)
			else
				LastError(GetLastError());
		} // __try
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
		CleanPtr(record);
	} // if(items == 5 && ...)
	else
		croak("Usage: Win32::Lanman::ReadEventLog($server, $source, $first, $last, \\@events)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// splits an environment string in its parts
//
// param:  srcString		 - environment string
//				 numDstStrings - gets the number of strings in dstString
//				 dstStrings		 - gets the string parts
//				 lastError		 - gets the error value
//
// return: success - 1 
//         failure - 0 
//
// note:	 on success, the caller has to free the strings in dstString and
//				 dstString itself
//
///////////////////////////////////////////////////////////////////////////////

BOOL SplitEnvironmentString(PSTR srcString, PDWORD numDstStrings, PSTR **dstString, 
														PDWORD lastError)
{
	assert(dstString);
	assert(numDstStrings);

	ErrorAndResult;

	PSTR *dst = NULL;

	__try
	{
		*dstString = NULL;
		*numDstStrings = 0;

		// count the string parts
		for(PSTR src = srcString; src && *src; )
		{
			PSTR envStr1 = strchr(src, '%');
			PSTR envStr2 = envStr1 ? strchr(envStr1 + 1, '%') : NULL;

			if(envStr1 != src && (!envStr1 || envStr1 - src > 1))
				(*numDstStrings)++;

			if(envStr1)
				(*numDstStrings)++;

			src = envStr2 ? envStr2 + 1 : NULL;
		}

		// alloc memory
		dst = (PSTR*)NewMem(*numDstStrings * sizeof(PSTR));

		*numDstStrings = 0;

		// copy strings
		for(src = srcString; src && *src; )
		{
			PSTR envStr1 = strchr(src, '%');
			PSTR envStr2 = envStr1 ? strchr(envStr1 + 1, '%') : NULL;

			// copy the part til the percent sign
			if(envStr1 != src && (!envStr1 || envStr1 - src > 1))
			{
				DWORD size = (envStr1 ? envStr1 - src : strlen(src)) + 1;

				dst[*numDstStrings] = (PSTR)NewMem(size);
				
				if(envStr1)
					strncpy((dst)[*numDstStrings], src, envStr1 - src);
				else
					strcpy((dst)[*numDstStrings], src);

				(*numDstStrings)++;
			}

			// copy the part from the percent sign
			if(envStr1)
			{
				DWORD size = (envStr2 ? envStr2 - envStr1 + 1 : strlen(envStr1)) + 1;

				dst[*numDstStrings] = (PSTR)NewMem(size);

				if(envStr2)
					strncpy((dst)[*numDstStrings], envStr1, envStr2 - envStr1 + 1);
				else
					strcpy((dst)[*numDstStrings], envStr1);

				(*numDstStrings)++;
			}

			// go to the next part
			src = envStr2 ? envStr2 + 1 : NULL;
		}

		// save the pointer
		*dstString = dst;
	}
	__except(SetExceptCode(excode))
	{
		// clean up on error
		while(*numDstStrings)
			CleanPtr(dst[--(*numDstStrings)]);
		CleanPtr(dst);

		SetErrorVar();
		result = FALSE;
	}

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// replaces environment strings
//
// param:  hKey				- key to the environment
//				 systemRoot - %SystemRoot%-value
//				 server		  - remote machine name
//				 param		  - strings to replace
//				 lastError  - gets the error value
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

BOOL ReplaceEnvString(HKEY hKey, PSTR systemRoot, PSTR *param, PDWORD lastError)
{
	assert(param);

	ErrorAndResult;

	PSTR value = NULL, data = NULL, loData = NULL, newParam = NULL;
	DWORD valueSize = 0, dataSize = 0, newParamSize = 0;

	__try
	{
		if(*param && strlen(*param) > 2 && strcmp(*param, "%%"))
		{
			// alloc memory for value
			value = (PSTR)NewMem(valueSize = strlen(*param) - 1);

			strncpy(value, *param + 1, valueSize - 1);

			// get data size
			if(!RegGetValue(hKey, value, NULL, &data, &dataSize, &error))
				RaiseFalseError(error);

			loData = (PSTR)NewMem(dataSize);

			// convert data to lower case
			strcpy(loData, data);
			strlwr(loData);

			// free previous allocated memory
			CleanPtr(*param);

			// save the result
			*param = data;
			data = NULL;

			// now look if we have to replace the extra SystemRoot value

			// count the %systemroot% parameters
			DWORD systemRootCount = 0;
			
			for(PSTR paramPtr = loData; paramPtr && *paramPtr; )
				if(paramPtr = strstr(paramPtr, "%systemroot%"))
				{
					paramPtr += strlen("%systemroot%");
					systemRootCount++;
				}

			// calculate the new size needed
			if(systemRootCount)
			{
				newParamSize = 
					dataSize + (strlen(systemRoot) - strlen("%systemroot%")) * systemRootCount;

				newParam = (PSTR)NewMem(newParamSize);

				// copy strings
				for(PSTR paramPtr = loData; paramPtr && *paramPtr; )
				{
					PSTR systemRootPtr = strstr(paramPtr, "%systemroot%");

					if(systemRootPtr)
					{
						strncat(newParam, *param + (paramPtr - loData), systemRootPtr - paramPtr);
						strcat(newParam, systemRoot);
					}
					else
						strcat(newParam, *param + (paramPtr - loData));

					paramPtr = systemRootPtr ? systemRootPtr + strlen("%systemroot%") : NULL;
				}

				// set the new data value
				CleanPtr(*param);
				*param = newParam;
				newParam = NULL;
			} // if(systemRootCount)
		} // if(*param && strlen(*param) > 2 && strcmp(*param, "%%"))
	}
	__except(SetExceptCode(excode))
	{
		// clean up on error
		SetErrorVar();
		result = FALSE;
	}

	CleanPtr(value);
	CleanPtr(data);
	CleanPtr(loData);
	CleanPtr(newParam);

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// expands environment strings from a remote machine
//
// param:  hRemoteLM - HKEY to HKLM on the remote machine
//				 server		 - remote machine name
//				 srcString - string to expand
//				 dstString - gets the expanded string
//				 lastError - gets the error value
//
// return: success - 1 
//         failure - 0 
//
// note:	 on success, the caller has to free the pointer in dstString
//
///////////////////////////////////////////////////////////////////////////////

BOOL RemoteExpandEnvironmentStrings(HKEY hRemoteLM, PSTR server, PSTR srcString, 
																		PSTR *dstString, PDWORD lastError)
{
	assert(dstString);

	ErrorAndResult;

	HKEY hKey = NULL;
	PSTR systemRoot = NULL;
	DWORD systemRootSize = 0;
	PSTR *splitStrings = NULL;
	DWORD numSplitStrings = 0;

	__try
	{
		// open system root key
		if(error = RegOpenKeyEx(hRemoteLM, SYSTEMROOT_KEY, 0, KEY_READ, &hKey))
			RaiseFalseError(error);

		// get system root on remote machine
		if(!RegGetValue(hKey, "SystemRoot", NULL, &systemRoot, &systemRootSize, &error))
			RaiseFalseError(error);

		CleanKey(hKey);

		// open session manager key
		if(error = RegOpenKeyEx(hRemoteLM, ENVIRONMENT_KEY, 0, KEY_READ, &hKey))
			RaiseFalseError(error);

		// split the source string
		if(!SplitEnvironmentString(srcString, &numSplitStrings, &splitStrings, &error))
			RaiseFalseError(error);

		// replace string parts
		for(DWORD count = 0; count < numSplitStrings; count++)
		{
			// check if we have to replace the string
			PSTR currentString = splitStrings[count];

			if(!currentString || strlen(currentString) < 3 || *currentString != '%' || 
				 currentString[strlen(currentString) - 1] != '%')
				continue;

			// look for the special value %SystemRoot%
			if(!stricmp(currentString, "%SystemRoot%"))
			{
				splitStrings[count] = 
					(PSTR)NewMem(splitStrings[count], systemRootSize, 1);

				strcpy(splitStrings[count], systemRoot);
				continue;
			}

			// now take the others
			if(!ReplaceEnvString(hKey, systemRoot, &splitStrings[count], &error))
				RaiseFalseError(error);
		}

		// calc size for dstString
		DWORD dstStringSize;

		for(count = 0, dstStringSize = 1; count < numSplitStrings; count++)
			dstStringSize += splitStrings[count] ? strlen(splitStrings[count]) : 0;

		// alloc memory
		*dstString = (PSTR)NewMem(dstStringSize += strlen(server) + 1);

		// set dstString
		wsprintf(*dstString, "%s\\", server);
		for(count = 0; count < numSplitStrings; count++)
			if(splitStrings[count])
				strcat(*dstString, splitStrings[count]);

		PSTR colonPtr = strchr(*dstString, ':');
		
		if(colonPtr)
			*colonPtr = '$';
	}
	__except(SetExceptCode(excode))
	{
		// clean up on error
		CleanPtr(*dstString);
		SetErrorVar();
		result = FALSE;
	}

	// clean up
	CleanKey(hKey);
	CleanPtr(systemRoot);

	while(numSplitStrings--)
		CleanPtr(splitStrings[numSplitStrings]);
	CleanPtr(splitStrings);

	return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the file names of an event log source
//
// param:  server    - computer to execute the command
//				 source    - system, security or application
//				 name			 - source created the event
//				 event		 - gets the event file name
//				 category	 - gets the category file name
//				 parameter - gets the parameter file name
//				 lastError - gets the error value
//
// return: success - 1 
//         failure - 0 
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetEventlogFileNames(PSTR server, PSTR source, PSTR name, PSTR *event,
													PSTR *category, PSTR *parameter, PDWORD lastError)
{
	assert(event);
	assert(category);
	assert(parameter);

	ErrorAndResult;

	HKEY hServerKey = NULL, hKey = NULL;
	PSTR path = NULL, eventValue = NULL, categoryValue = NULL, parameterValue = NULL;
	DWORD eventValueSize = 0, categoryValueSize = 0, parameterValueSize = 0;

	__try
	{
		*event = NULL;
		*category = NULL;
		*parameter = NULL;

		// alloc memory to build the eventlog key name
		path = (PSTR)NewMem(strlen(EVENT_LOG_KEY) + strlen(source) + strlen(name) + 3);
		wsprintf(path, "%s\\%s\\%s", EVENT_LOG_KEY, source, name);
		
		// if we need the name from a remote server, connect to the registry
		if(server && *server)
			if(error = RegConnectRegistry(server, HKEY_LOCAL_MACHINE, &hServerKey))
				RaiseFalseError(error);

		// open the eventlog key
		if(error = RegOpenKeyEx(hServerKey ? hServerKey : HKEY_LOCAL_MACHINE, path, 
														0, KEY_READ, &hKey))
			RaiseFalseError(error);

		// get the event message file
		if(!RegGetValue(hKey, "EventMessageFile", NULL, &eventValue, &eventValueSize, 
										&error))
			RaiseFalseError(error);

		// get the category message file
		if(!RegGetValue(hKey, "CategoryMessageFile", NULL, &categoryValue, 
										&categoryValueSize, &error) && error != ERROR_FILE_NOT_FOUND)
			RaiseFalseError(error);

		// get the parameter message file
		if(!RegGetValue(hKey, "ParameterMessageFile", NULL, &parameterValue, 
										&parameterValueSize, &error) && error != ERROR_FILE_NOT_FOUND)
			RaiseFalseError(error);

		// expand environment strings
		if(server && *server)
		{
			// expand environment strings on remote machine
			if(!RemoteExpandEnvironmentStrings(hServerKey, server, eventValue, event, &error))
				RaiseFalseError(error);

			if(categoryValue && !RemoteExpandEnvironmentStrings(hServerKey, server, 
																													categoryValue, category, 
																													&error))
				RaiseFalseError(error);
			
			if(parameterValue && !RemoteExpandEnvironmentStrings(hServerKey, server, 
																													 parameterValue, parameter, 
																													 &error))
				RaiseFalseError(error);
		}
		else
		{
			// expand environment strings local
			DWORD size = ExpandEnvironmentStrings(eventValue, *event, 0);

			// alloc memory and expand string
			if(!ExpandEnvironmentStrings(eventValue, *event = (PSTR)NewMem(size), size))
				RaiseFalse();

			if(categoryValue)
			{
				// alloc memory
				*category = 
					(PSTR)NewMem(size = ExpandEnvironmentStrings(categoryValue, 
																											 *category, 0));

				// expand string
				if(!ExpandEnvironmentStrings(categoryValue, *category, size))
					RaiseFalse();
			}

			if(parameterValue)
			{
				// alloc memory
				*parameter = 
					(PSTR)NewMem(size = ExpandEnvironmentStrings(parameterValue, 
																											 *parameter, 0));

				// expand string
				if(!ExpandEnvironmentStrings(parameterValue, *parameter, size))
					RaiseFalse();
			}
		}
	}
	__except(SetExceptCode(excode))
	{
		// clean up on error
		CleanPtr(*event);
		CleanPtr(*category);
		CleanPtr(*parameter);

		SetErrorVar();
		result = FALSE;
	}

	// clean up
	CleanKey(hServerKey);
	CleanKey(hKey);
	CleanPtr(path);
	CleanPtr(eventValue);
	CleanPtr(categoryValue);
	CleanPtr(parameterValue);

	return result;
}


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

XS(XS_NT__Lanman_GetEventDescription)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *event = NULL;

	if(items == 2 && CHK_ASSIGN_HREF(event, ST(1)))
	{
		PSTR server = NULL;
		PSTR source = H_FETCH_STR(event, "source");
		PSTR name = H_FETCH_STR(event, "sourcename");
		DWORD id = H_FETCH_INT(event, "eventid");

		PSTR eventName = NULL, categoryName = NULL, parameterName = NULL;
		HMODULE hModule = NULL;
		PSTR desc = NULL;

		AV *strings = H_FETCH_RARRAY(event, "strings");
		PSTR *arguments = NULL, *argumentsToDel = NULL;
		DWORD argumentsToDelCount = 0;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// get module names and try to load module
			if(GetEventlogFileNames(server, source, name, &eventName, &categoryName, 
															&parameterName, &error))
			{
				// separate parameter strings
				if(arguments = 
						strings ? (PSTR*)NewMem(sizeof(PSTR) * (AV_LEN(strings) + 2)) : NULL)
				{
					for(DWORD count = 0, numArgs = AV_LEN(strings) + 1; count < numArgs; count++)
						arguments[count] = A_FETCH_STR(strings, count);
				
					arguments[count] = NULL;
				}

				// try to load parameters from file
				if(parameterName)
				{
					// determine how many pointers we need
					for(DWORD count = 0, numArgs = AV_LEN(strings) + 1; count < numArgs; count++)
					{
						int integer;

						// we have to load it if the argument looks like %%5
						if(arguments[count] && arguments[count][0] == '%' && 
							 arguments[count][1] == '%' &&
							 sscanf(arguments[count] + 2, "%d", &integer))
							argumentsToDelCount++;
					}

					if(argumentsToDelCount)
					{
						// alloc memory
						argumentsToDel = (PSTR*)NewMem(sizeof(PSTR) * argumentsToDelCount);

						// load the dll
						if(!(hModule = LoadLibraryEx(parameterName, NULL, LOAD_LIBRARY_AS_DATAFILE)))
							RaiseFalse();

						for(DWORD count = 0, index = 0, numArgs = AV_LEN(strings) + 1; 
								count < numArgs; count++)
						{
							int integer;

							// we have to load it if the argument looks like %%5
							if(arguments[count] && arguments[count][0] == '%' && 
								 arguments[count][1] == '%' &&
								 sscanf(arguments[count] + 2, "%d", &integer))
							{
								FormatMessage(FORMAT_MSG_FLAG, hModule, integer, 0, 
															(PSTR)&argumentsToDel[index], -1, NULL);
								arguments[count] = argumentsToDel[index++];
							}
						}

						CleanLibrary(hModule);
					} // if(argumentsToDelCount)
				} // if(parameterName)

				// dll names may be separated by colons; try each dll name
				for(PSTR eventNamePtr = eventName, nextEventNamePtr = NULL; ; )
				{
					// separate dll name
					if(nextEventNamePtr = eventNamePtr ? strchr(eventNamePtr, ';') : NULL)
						*nextEventNamePtr++ = 0;

					// load the dll
					if(!(hModule = LoadLibraryEx(eventNamePtr, NULL, LOAD_LIBRARY_AS_DATAFILE)))
						RaiseFalse();

					// get description
					if(FormatMessage(FORMAT_MSG_FLAG, hModule, id, 0, (PSTR)&desc, -1, arguments))
						break;

					// if FormatMessage failed and there're no more dll's, raise an exception
					if(!nextEventNamePtr)
						RaiseFalse();

					// close library handle
					CleanLibrary(hModule);

					// go to the next dll
					eventNamePtr = nextEventNamePtr;
				}

				H_STORE_STR(event, "eventdescription", desc);
			} // if(GetEventlogSourceFileName(...)
			else
				LastError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(eventName);
		CleanPtr(categoryName);
		CleanPtr(parameterName);
		CleanPtr(arguments);
		FreeArray((PVOID*)argumentsToDel, argumentsToDelCount);
		CleanLibrary(hModule);
		if(desc)
			LocalFree(desc);
	} // if(items == 2 && ...)
	else
		croak("Usage: Win32::Lanman::GetEventDescription($server, \\%%event)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_BackupEventLog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 3)
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);
		PSTR fileName = SvPV(ST(2), PL_na);

		HANDLE hEventLog = NULL;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = OpenEventLog(server, source)))
				RaiseFalse();

			// make backup to a file
			if(!BackupEventLog(hEventLog, fileName))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::BackupEventLog($server, $source, $filename)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_ClearEventLog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2 || items == 3)
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);
		PSTR fileName = items == 3 ? SvPV(ST(2), PL_na) : NULL;

		HANDLE hEventLog = NULL;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = OpenEventLog(server, source)))
				RaiseFalse();

			if(fileName && !*fileName)
				fileName = NULL;

			// clear eventlog and make an optionally backup to a file
			if(!ClearEventLog(hEventLog, fileName))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::ClearEventLog($server, $source [, $filename])\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_ReportEvent)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *strings = NULL;

	if(items == 8 && CHK_ASSIGN_AREF(strings, ST(6)))
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);
		DWORD type = SvIV(ST(2));
		DWORD category = SvIV(ST(3));
		DWORD id = SvIV(ST(4));
		UINT sidSize = 0;
		PSID sid = SvPV(ST(5), sidSize);
		UINT dataSize = 0;
		PVOID data = SvPV(ST(7), dataSize);

		HANDLE hEventLog = NULL;
		PSTR *stringPtr = NULL;
		USHORT numStringPtr = 0;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = RegisterEventSource(server, source)))
				RaiseFalse();

			// validate sid pointer
			if(!sidSize)
				sid = NULL;

			// get string number
			if(numStringPtr = AV_LEN(strings) + 1)
			{
				// alloc pointer
				stringPtr = (PSTR*)NewMem(sizeof(PSTR) * numStringPtr);

				// set string pointer
				for(USHORT count = 0; count < numStringPtr; count++)
					stringPtr[count] = A_FETCH_STR(strings, count);
			}

			// validate data pointer
			if(!dataSize)
				data = NULL;

			// report event
			if(!ReportEvent(hEventLog, (USHORT)type, (USHORT)category, id, sid, numStringPtr, dataSize, 
											(PCSTR*)stringPtr, data))
				RaiseFalse();
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		CleanPtr(stringPtr);
		if(hEventLog)
			DeregisterEventSource(hEventLog);
	} // if(items == 8 && ...)
	else
		croak("Usage: Win32::Lanman::ReportEvent($server, $source, $type, $category, $id, "
					"$sid, \\@strings, $data)\n");
	
	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_GetNumberOfEventLogRecords)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *records = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(records, ST(2)))
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);

		HANDLE hEventLog = NULL;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = OpenEventLog(server, source)))
				RaiseFalse();

			DWORD numRecords = 0;

			// get recors numbers
			if(!GetNumberOfEventLogRecords(hEventLog, &numRecords))
				RaiseFalse();

			// save the result
			S_STORE_INT(records, numRecords);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::GetNumberOfEventLogRecords($server, $source, \\$numrecords)\n");
	
	RETURNRESULT(LastError() == 0);
}


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

XS(XS_NT__Lanman_GetOldestEventLogRecord)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *records = NULL;

	if(items == 3 && CHK_ASSIGN_SREF(records, ST(2)))
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);

		HANDLE hEventLog = NULL;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = OpenEventLog(server, source)))
				RaiseFalse();

			DWORD oldestRecord = 0;

			// get recors numbers
			if(!GetOldestEventLogRecord(hEventLog, &oldestRecord))
				RaiseFalse();

			// save the result
			S_STORE_INT(records, oldestRecord);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::GetOldestEventLogRecord($server, $source, \\$oldestrecord)\n");
	
	RETURNRESULT(LastError() == 0);
}

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

XS(XS_NT__Lanman_NotifyChangeEventLog)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	//SV *records = NULL;

	if(items == 2 || items == 3)
	{
		PSTR server = NULL;
		PSTR source = SvPV(ST(1), PL_na);

		HANDLE hEventLog = NULL, hNotify = NULL;
		DWORD timeout = items == 3 ? SvIV(ST(2)) : INFINITE;

		__try
		{
			server = ServerAsAnsi(SvPV(ST(0), PL_na));

			// open event log
			if(!(hEventLog = OpenEventLog(server, source)))
				RaiseFalse();

			// create event
			if(!(hNotify = CreateEvent(NULL, TRUE, FALSE, NULL)))
				RaiseFalse();
			
			// set up event notification
			if(!NotifyChangeEventLog(hEventLog, hNotify))
				RaiseFalse();
			
			// wait for the event
			if((error = WaitForSingleObject(hNotify, timeout)) != WAIT_OBJECT_0)
				RaiseFalseError(error);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanPtr(server);
		if(hEventLog)
			CloseEventLog(hEventLog);
		CleanHandle(hNotify);
	} // if(items == 3)
	else
		croak("Usage: Win32::Lanman::NotifyChangeEventLog($server, $source [, $timeout])\n");
	
	RETURNRESULT(LastError() == 0);
}


