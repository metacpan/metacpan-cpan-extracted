#define WIN32_LEAN_AND_MEAN


#ifndef __MESSAGE_CPP
#define __MESSAGE_CPP
#endif


#include <windows.h>
#include <lm.h>


#include "message.h"
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
// sends a message
//
// param:  server	 - computer to execute the command
//				 to			 - name to send the message
//				 from		 - name where the message is from
//				 message - message text
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageBufferSend)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 4)
	{
		PWSTR server = NULL, from =  NULL, to = NULL, message = NULL;

		__try
		{
			// change server, to, from and message to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			to = S2W(SvPV(ST(1), PL_na));
			from = S2W(SvPV(ST(2), PL_na));
			
			unsigned messageLen = 0;
			message = S2W(SvPV(ST(3), messageLen));

			// send message
			LastError(NetMessageBufferSend(server, to, from, (PBYTE)message, 
																		 messageLen * sizeof(WCHAR)));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(to);
		FreeStr(from);
		FreeStr(message);
	} // if(items == 4)
	else
		croak("Usage: Win32::Lanman::NetMessageBufferSend($server, $to, $from, $message)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// registers a message alias in the message name table
//
// param:  server			 - computer to execute the command
//				 messagename - message name to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameAdd)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, messageName = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			messageName = S2W(SvPV(ST(1), PL_na));

			// add message name
			LastError(NetMessageNameAdd(server, messageName));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(messageName);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetMessageNameAdd($server, $messagename)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// deletes a message alias from the table of message aliases
//
// param:  server			 - computer to execute the command
//				 messagename - message name to delete
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameDel)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	if(items == 2)
	{
		PWSTR server = NULL, messageName = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			messageName = S2W(SvPV(ST(1), PL_na));

			// delete message name
			LastError(NetMessageNameDel(server, messageName));
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(messageName);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetMessageNameDel($server, $messagename)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// lists the message aliases that will receive messages
//
// param:  server	- computer to execute the command
//				 info		- message info to enum
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameEnum)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	AV *messageInfo = NULL;

	if(items == 2 && CHK_ASSIGN_AREF(messageInfo, ST(1)))
	{
		PWSTR server = NULL;
		PMSG_INFO_0 info = NULL;

		__try
		{
			// change server to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));

			// clear array
			AV_CLEAR(messageInfo);

			DWORD buflen = 0x10000;
			DWORD entries = 0;
			DWORD total = 0;
			DWORD handle = 0;

			// sometimes our buffer is to small to hold the info all together, so we have
			// to do it in more than one steps
			for( ; ; )
			{
				// clean buffer if already allocated
				CleanNetBuf(info);

				// get all messages; if buflen is too small, increment it
				while((error = NetMessageNameEnum(server, 0, (PBYTE*)&info, buflen, &entries, 
																					&total, &handle)) == NERR_BufTooSmall &&
																				  (!entries || entries != total))
				{
					buflen += 0x1000;

					continue;
				}

				if(!error || error == ERROR_MORE_DATA)
				{
					for(DWORD count = 0; count < entries; count++)
						A_STORE_WSTR(messageInfo, info[count].msgi0_name);

					// did we got all?
					if(!error || entries == total)
						break;
				}
				else
					RaiseFalseError(error);
			} // for( ; ; )
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(info);
		FreeStr(server);
	} // if(items == 2)
	else
		croak("Usage: Win32::Lanman::NetMessageNameEnum($server, \\@info)\n");
	
	RETURNRESULT(LastError() == 0);
}


///////////////////////////////////////////////////////////////////////////////
//
// retrieves information about a message alias in the message name table
//
// param:  server			 - computer to execute the command
//				 messagename - message name to add
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetMessageNameGetInfo)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	SV *messageInfo = NULL;

	if(items == 3 && SvROK(messageInfo = ST(2)))
	{
		PWSTR server = NULL, messageName = NULL;
		PMSG_INFO_0 info = NULL;

		__try
		{
			// change server and message name to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			messageName = S2W(SvPV(ST(1), PL_na));

			messageInfo = SvRV(messageInfo);

			// delete message name
			if(!LastError(NetMessageNameGetInfo(server, messageName, 0, (PBYTE*)&info)))
				S_STORE_WSTR(messageInfo, info->msgi0_name);
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		CleanNetBuf(info);
		FreeStr(server);
		FreeStr(messageName);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetMessageNameGetInfo($server, $messagename, \\$info)\n");
	
	RETURNRESULT(LastError() == 0);	
}



