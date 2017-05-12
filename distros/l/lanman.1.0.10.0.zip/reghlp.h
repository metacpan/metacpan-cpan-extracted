#ifndef __REGHLP_H
#define __REGHLP_H


///////////////////////////////////////////////////////////////////////////////
//
// prototypes
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
								 PDWORD lastError = NULL);


#endif //#ifndef __REGHLP_H
