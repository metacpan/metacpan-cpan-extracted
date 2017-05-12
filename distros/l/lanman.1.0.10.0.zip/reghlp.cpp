#define WIN32_LEAN_AND_MEAN


#ifndef __REGHLP_CPP
#define __REGHLP_CPP
#endif


#include <windows.h>
#include <assert.h>


#include "reghlp.h"
#include "misc.h"


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
// functions
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// reads a value from the registry
//
// param:  hKey			 - key opened by RegOpenKeyEx
//				 value		 - value name
//				 type			 - gets the value type (can be null)
//				 data			 - data gets the value
//				 dataSize  - gets the data size
//				 lastError - gets the last error
//
// return: success - 1 
//         failure - 0 
//
// note:   on success, the caller has to free the memory in data
//
///////////////////////////////////////////////////////////////////////////////

BOOL RegGetValue(HKEY hKey, PSTR value, PDWORD type, PSTR *data, PDWORD dataSize,
								 PDWORD lastError)
{
	assert(data);
	assert(dataSize);

	ErrorAndResult;

	__try
	{
		DWORD size = *dataSize;

		// try to get value
		error = RegQueryValueEx(hKey, value, 0, type, (PBYTE)*data, dataSize);

		// do we need more memory
		if(size < *dataSize || error == ERROR_MORE_DATA)
		{
			// free allocated data
			CleanPtr(*data);

			// alloc memory
			*data = (PSTR)NewMem(*dataSize);

			// try to read value again
			if(error = RegQueryValueEx(hKey, value, 0, type, (PBYTE)*data, dataSize))
				RaiseFalseError(error);
		}
		else
			// is an error occured
			if(error)
				RaiseFalseError(error);
	}
	__except(SetExceptCode(excode))
	{
		// clean up on error
		CleanPtr(*data);
		*dataSize = 0;

		SetErrorVar();
		result = FALSE;
	}

	return result;
}

