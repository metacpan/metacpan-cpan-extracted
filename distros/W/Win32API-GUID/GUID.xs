#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <objbase.h>
#include <string.h>

MODULE = Win32API::GUID		PACKAGE = Win32API::GUID		

char*
CreateGuid()
	CODE:
		GUID guid;
   		char buffer[13];
		char ret[37];
		int c;

		CoCreateGuid (&guid);

		sprintf (buffer, "%04X", (int) ((guid.Data1 & 0xFFFF0000) >> 16));
		strcpy (ret, buffer);
		sprintf (buffer, "%04X", (int) (guid.Data1 & 0xFFFF));	
		strcat (strcat (ret, buffer), "-");

		sprintf (buffer, "%04X", (int) guid.Data2);
		strcat (strcat (ret, buffer), "-");

		sprintf (buffer, "%04X", (int) guid.Data3);
		strcat (strcat (ret, buffer), "-");		
		
		for (c = 0; c != 2; c++){
			sprintf (buffer, "%02X", (int) guid.Data4[c]);
			strcat (ret, buffer);
		}
		strcat (ret, "-"); 
		for (c = 2; c != 8; c++){
			sprintf (buffer, "%02X", (int) guid.Data4[c]);
			strcat (ret, buffer);
		}

		RETVAL = ret;
	OUTPUT:
		RETVAL
