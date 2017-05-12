#define WIN32_LEAN_AND_MEAN


#ifndef __STAT_CPP
#define __STAT_CPP
#endif


#ifndef LM20_WORKSTATION_STATISTICS
#define LM20_WORKSTATION_STATISTICS
#endif


#include <windows.h>
#include <lm.h>


#include "stat.h"
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
// retrieves operating statistics for a service
//
// param:  server - computer to execute the command
//				 client - computer name of the client to disconnect
//				 user   - name of the user whose session is to be terminated
//
// return: success - 1 
//         failure - 0 
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Lanman_NetStatisticsGet)
{
	dXSARGS;

	ErrorAndResult;

	// reset last error
	LastError(0);

	HV *statInfo = NULL;

	if(items == 3  && CHK_ASSIGN_HREF(statInfo, ST(2)))
	{
		PWSTR server = NULL, service = NULL;
		PSTAT_WORKSTATION_0 workstInfo = NULL;

		__try
		{
			// change server and service to unicode
			server = ServerAsUnicode(SvPV(ST(0), PL_na));
			service = S2W(SvPV(ST(1), PL_na));

			// clean hash
			HV_CLEAR(statInfo);

			if(!LastError(NetStatisticsGet((PSTR)server, (PSTR)service, 0, 0, 
																		 (PBYTE*)&workstInfo)))
				if(!wcsicmp(service, L"WORKSTATION"))
				{
					H_STORE_INT(statInfo, "start", workstInfo->stw0_start);
					H_STORE_INT(statInfo, "numncb_r", workstInfo->stw0_numNCB_r);
					H_STORE_INT(statInfo, "numncb_s", workstInfo->stw0_numNCB_s);
					H_STORE_INT(statInfo, "numncb_a", workstInfo->stw0_numNCB_a);
					H_STORE_INT(statInfo, "fincb_r", workstInfo->stw0_fiNCB_r);
					H_STORE_INT(statInfo, "fincb_s", workstInfo->stw0_fiNCB_s);
					H_STORE_INT(statInfo, "fincb_a", workstInfo->stw0_fiNCB_a);
					H_STORE_INT(statInfo, "fcncb_r", workstInfo->stw0_fcNCB_r);
					H_STORE_INT(statInfo, "fcncb_s", workstInfo->stw0_fcNCB_s);
					H_STORE_INT(statInfo, "fcncb_a", workstInfo->stw0_fcNCB_a);
					H_STORE_INT(statInfo, "sesstart", workstInfo->stw0_sesstart);
					H_STORE_INT(statInfo, "sessfailcon", workstInfo->stw0_sessfailcon);
					H_STORE_INT(statInfo, "sessbroke", workstInfo->stw0_sessbroke);
					H_STORE_INT(statInfo, "uses", workstInfo->stw0_uses);
					H_STORE_INT(statInfo, "usefail", workstInfo->stw0_usefail);
					H_STORE_INT(statInfo, "autorec", workstInfo->stw0_autorec);
					H_STORE_INT(statInfo, "bytessent_r_lo", workstInfo->stw0_bytessent_r_lo);
					H_STORE_INT(statInfo, "bytessent_r_hi", workstInfo->stw0_bytessent_r_hi);
					H_STORE_INT(statInfo, "bytesrcvd_r_lo", workstInfo->stw0_bytesrcvd_r_lo);
					H_STORE_INT(statInfo, "bytesrcvd_r_hi", workstInfo->stw0_bytesrcvd_r_hi);
					H_STORE_INT(statInfo, "bytessent_s_lo", workstInfo->stw0_bytessent_s_lo);
					H_STORE_INT(statInfo, "bytessent_s_hi", workstInfo->stw0_bytessent_s_hi);
					H_STORE_INT(statInfo, "bytesrcvd_s_lo", workstInfo->stw0_bytesrcvd_s_lo);
					H_STORE_INT(statInfo, "bytesrcvd_s_hi", workstInfo->stw0_bytesrcvd_s_hi);
					H_STORE_INT(statInfo, "bytessent_a_lo", workstInfo->stw0_bytessent_a_lo);
					H_STORE_INT(statInfo, "bytessent_a_hi", workstInfo->stw0_bytessent_a_hi);
					H_STORE_INT(statInfo, "bytesrcvd_a_lo", workstInfo->stw0_bytesrcvd_a_lo);
					H_STORE_INT(statInfo, "bytesrcvd_a_hi", workstInfo->stw0_bytesrcvd_a_hi);
					H_STORE_INT(statInfo, "reqbufneed", workstInfo->stw0_reqbufneed);
					H_STORE_INT(statInfo, "reqbufneed", workstInfo->stw0_reqbufneed);
				}
				else
				{
					PSTAT_SERVER_0 serverInfo = (PSTAT_SERVER_0)workstInfo;

					H_STORE_INT(statInfo, "start", serverInfo->sts0_start);
					H_STORE_INT(statInfo, "fopens", serverInfo->sts0_fopens);
					H_STORE_INT(statInfo, "devopens", serverInfo->sts0_devopens);
					H_STORE_INT(statInfo, "jobsqueued", serverInfo->sts0_jobsqueued);
					H_STORE_INT(statInfo, "sopens", serverInfo->sts0_sopens);
					H_STORE_INT(statInfo, "stimedout", serverInfo->sts0_stimedout);
					H_STORE_INT(statInfo, "serrorout", serverInfo->sts0_serrorout);
					H_STORE_INT(statInfo, "pwerrors", serverInfo->sts0_pwerrors);
					H_STORE_INT(statInfo, "permerrors", serverInfo->sts0_permerrors);
					H_STORE_INT(statInfo, "syserrors", serverInfo->sts0_syserrors);
					H_STORE_INT(statInfo, "bytessent_low", serverInfo->sts0_bytessent_low);
					H_STORE_INT(statInfo, "bytessent_high", serverInfo->sts0_bytessent_high);
					H_STORE_INT(statInfo, "bytesrcvd_low", serverInfo->sts0_bytesrcvd_low);
					H_STORE_INT(statInfo, "bytesrcvd_high", serverInfo->sts0_bytesrcvd_high);
					H_STORE_INT(statInfo, "avresponse", serverInfo->sts0_avresponse);
					H_STORE_INT(statInfo, "reqbufneed", serverInfo->sts0_reqbufneed);
					H_STORE_INT(statInfo, "bigbufneed", serverInfo->sts0_bigbufneed);
				}
		}
		__except(SetExceptCode(excode))
		{
			// set last error 
			LastError(error ? error : excode);
		}

		// clean up
		FreeStr(server);
		FreeStr(service);
		CleanNetBuf(workstInfo);
	} // if(items == 3 && ...)
	else
		croak("Usage: Win32::Lanman::NetStatisticsGet($server, $service, \\%%info)\n");
	
	RETURNRESULT(LastError() == 0);
}


