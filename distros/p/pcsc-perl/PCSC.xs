/**************************************************************************
 *    Authors     : Lionel VICTOR <lionel.victor@unforgettable.com>
 *                                <lionel.victor@free.fr>
 *                  Ludovic ROUSSEAU <ludovic.rousseau@free.fr>
 *    Compiler    : gcc, Visual C++
 *    Target      : Unix, Windows
 *
 *    Description : Perl wrapper to the PCSC API
 *    
 *    Copyright (C) 2001 - Lionel VICTOR
 *    Copyright (c) 2003-2015 Ludovic ROUSSEAU
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 *    02111-1307 USA
 *
 **************************************************************************/

 /* $Id: PCSC.xs,v 1.30 2015/11/19 16:05:17 rousseau Exp $ */

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include "PCSCperl.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* The following hack helps importing variables from the PCSC library.
 * Those variables are dynamically imported...
 * TODO: see how we can use them anyway...
 */
#ifdef SCARD_PCI_T0
#  undef SCARD_PCI_T0
#  define SCARD_PCI_T0 (gpioSCardT0Pci)
#endif

#ifdef SCARD_PCI_T1
#  undef SCARD_PCI_T1
#  define SCARD_PCI_T1 (gpioSCardT1Pci)
#endif

#ifdef SCARD_PCI_RAW
#  undef SCARD_PCI_RAW
#  define SCARD_PCI_RAW (gpioSCardRawPci)
#endif

#ifdef __cplusplus
}
#endif

/* InitErrorCodes () initializes and creates a few variables describing
 * important values like error codes and constants. Those values are set
 * read-only so the user won't be able to eventually modify them.
 *  Those variables are set in the XS because their numerical value is
 *  platform dependent.
 */
void _InitErrorCodes () {
	SV * tmpSV;

	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_S_SUCCESS", TRUE);
	sv_setiv (tmpSV,      SCARD_S_SUCCESS); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_CANCELLED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_CANCELLED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_CANT_DISPOSE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_CANT_DISPOSE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INSUFFICIENT_BUFFER", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INSUFFICIENT_BUFFER); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INVALID_ATR", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INVALID_ATR); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INVALID_HANDLE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INVALID_HANDLE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INVALID_PARAMETER", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INVALID_PARAMETER); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INVALID_TARGET", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INVALID_TARGET); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_INVALID_VALUE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_INVALID_VALUE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_NO_MEMORY", TRUE);
	sv_setiv (tmpSV,      SCARD_E_NO_MEMORY); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_UNKNOWN_READER", TRUE);
	sv_setiv (tmpSV,      SCARD_E_UNKNOWN_READER); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_TIMEOUT", TRUE);
	sv_setiv (tmpSV,      SCARD_E_TIMEOUT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_SHARING_VIOLATION", TRUE);
	sv_setiv (tmpSV,      SCARD_E_SHARING_VIOLATION); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_NO_SMARTCARD", TRUE);
	sv_setiv (tmpSV,      SCARD_E_NO_SMARTCARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_UNKNOWN_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_E_UNKNOWN_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_PROTO_MISMATCH", TRUE);
	sv_setiv (tmpSV,      SCARD_E_PROTO_MISMATCH); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_NOT_READY", TRUE);
	sv_setiv (tmpSV,      SCARD_E_NOT_READY); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_SYSTEM_CANCELLED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_SYSTEM_CANCELLED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_NOT_TRANSACTED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_NOT_TRANSACTED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_READER_UNAVAILABLE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_READER_UNAVAILABLE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_PCI_TOO_SMALL", TRUE);
	sv_setiv (tmpSV,      SCARD_E_PCI_TOO_SMALL); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_READER_UNSUPPORTED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_READER_UNSUPPORTED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_DUPLICATE_READER", TRUE);
	sv_setiv (tmpSV,      SCARD_E_DUPLICATE_READER); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_CARD_UNSUPPORTED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_CARD_UNSUPPORTED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_NO_SERVICE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_NO_SERVICE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_SERVICE_STOPPED", TRUE);
	sv_setiv (tmpSV,      SCARD_E_SERVICE_STOPPED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_E_UNSUPPORTED_FEATURE", TRUE);
	sv_setiv (tmpSV,      SCARD_E_UNSUPPORTED_FEATURE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_W_UNSUPPORTED_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_W_UNSUPPORTED_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_W_UNRESPONSIVE_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_W_UNRESPONSIVE_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_W_UNPOWERED_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_W_UNPOWERED_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_W_RESET_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_W_RESET_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_W_REMOVED_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_W_REMOVED_CARD); SvREADONLY_on (tmpSV);

	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_F_COMM_ERROR", TRUE);
	sv_setiv (tmpSV,      SCARD_F_COMM_ERROR); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_F_INTERNAL_ERROR", TRUE);
	sv_setiv (tmpSV,      SCARD_F_INTERNAL_ERROR); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_F_UNKNOWN_ERROR", TRUE);
	sv_setiv (tmpSV,      SCARD_F_UNKNOWN_ERROR); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_F_WAITED_TOO_LONG", TRUE);
	sv_setiv (tmpSV,      SCARD_F_WAITED_TOO_LONG); SvREADONLY_on (tmpSV);

	/* PCSC - Perl wrapper specific error codes */
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_P_ALREADY_CONNECTED", TRUE);
	sv_setiv (tmpSV,      SCARD_P_ALREADY_CONNECTED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_P_NOT_CONNECTED", TRUE);
	sv_setiv (tmpSV,      SCARD_P_NOT_CONNECTED); SvREADONLY_on (tmpSV);

	/* PCSC standard constants */
	/*
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_CONVENTION_DIRECT", TRUE);
	sv_setiv (tmpSV,      SCARD_CONVENTION_DIRECT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_CONVENTION_INVERSE", TRUE);
	sv_setiv (tmpSV,      SCARD_CONVENTION_INVERSE); SvREADONLY_on (tmpSV);
	*/
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SCOPE_USER", TRUE);
	sv_setiv (tmpSV,      SCARD_SCOPE_USER); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SCOPE_TERMINAL", TRUE);
	sv_setiv (tmpSV,      SCARD_SCOPE_TERMINAL); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SCOPE_SYSTEM", TRUE);
	sv_setiv (tmpSV,      SCARD_SCOPE_SYSTEM); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_PROTOCOL_T0", TRUE);
	sv_setiv (tmpSV,      SCARD_PROTOCOL_T0); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_PROTOCOL_T1", TRUE);
	sv_setiv (tmpSV,      SCARD_PROTOCOL_T1); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_PROTOCOL_RAW", TRUE);
	sv_setiv (tmpSV,      SCARD_PROTOCOL_RAW); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SHARE_EXCLUSIVE", TRUE);
	sv_setiv (tmpSV,      SCARD_SHARE_EXCLUSIVE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SHARE_SHARED", TRUE);
	sv_setiv (tmpSV,      SCARD_SHARE_SHARED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SHARE_DIRECT", TRUE);
	sv_setiv (tmpSV,      SCARD_SHARE_DIRECT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_LEAVE_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_LEAVE_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_RESET_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_RESET_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_UNPOWER_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_UNPOWER_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_EJECT_CARD", TRUE);
	sv_setiv (tmpSV,      SCARD_EJECT_CARD); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_UNKNOWN", TRUE);
	sv_setiv (tmpSV,      SCARD_UNKNOWN); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_ABSENT", TRUE);
	sv_setiv (tmpSV,      SCARD_ABSENT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_PRESENT", TRUE);
	sv_setiv (tmpSV,      SCARD_PRESENT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SWALLOWED", TRUE);
	sv_setiv (tmpSV,      SCARD_SWALLOWED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_POWERED", TRUE);
	sv_setiv (tmpSV,      SCARD_POWERED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_NEGOTIABLE", TRUE);
	sv_setiv (tmpSV,      SCARD_NEGOTIABLE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_SPECIFIC", TRUE);
	sv_setiv (tmpSV,      SCARD_SPECIFIC); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_UNAWARE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_UNAWARE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_IGNORE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_IGNORE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_CHANGED", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_CHANGED); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_UNKNOWN", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_UNKNOWN); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_UNAVAILABLE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_UNAVAILABLE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_EMPTY", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_EMPTY); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_PRESENT", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_PRESENT); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_ATRMATCH", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_ATRMATCH); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_EXCLUSIVE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_EXCLUSIVE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_INUSE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_INUSE); SvREADONLY_on (tmpSV);
	tmpSV = perl_get_sv ("Chipcard::PCSC::SCARD_STATE_MUTE", TRUE);
	sv_setiv (tmpSV,      SCARD_STATE_MUTE); SvREADONLY_on (tmpSV);
}

/* _StringifyError is copied from pcsc_stringify_error() which is a
 * function taken from PCSClite
 * It has been modified because I added a few internal errors to the
 * wrapper (SCARD_P_NOT_CONNECTED for instance)
 * I also feel like using strong types like const char * const and
 * avoiding to use strcpy() is better from a security point of view.
 *
 * See file debuglog.c from your PCSClite distribution for extra
 * informations
 */
const char * _StringifyError (unsigned long Error) {
	switch ( (DWORD)Error ) {
	case SCARD_S_SUCCESS:             return "Command successful.";
	case SCARD_E_CANCELLED:           return "Command cancelled.";
	case SCARD_E_CANT_DISPOSE:        return "Cannot dispose handle.";
	case SCARD_E_CARD_UNSUPPORTED:    return "Card is unsupported.";
	case SCARD_E_DUPLICATE_READER:    return "Reader already exists.";
	case SCARD_E_INSUFFICIENT_BUFFER: return "Insufficient buffer.";
	case SCARD_E_INVALID_ATR:         return "Invalid ATR.";
	case SCARD_E_INVALID_HANDLE:      return "Invalid handle.";
	case SCARD_E_INVALID_PARAMETER:   return "Invalid parameter given.";
	case SCARD_E_INVALID_TARGET:      return "Invalid target given.";
	case SCARD_E_INVALID_VALUE:       return "Invalid value given.";
	case SCARD_E_NO_MEMORY:           return "Not enough memory.";
	case SCARD_E_NO_SERVICE:          return "Service not available.";
	case SCARD_E_NO_SMARTCARD:        return "No smartcard inserted.";
	case SCARD_E_NOT_READY:           return "Subsystem not ready.";
	case SCARD_E_NOT_TRANSACTED:      return "Transaction failed.";
	case SCARD_E_PCI_TOO_SMALL:       return "PCI struct too small.";
	case SCARD_E_PROTO_MISMATCH:      return "Card protocol mismatch.";
	case SCARD_E_READER_UNAVAILABLE:  return "Reader/s is unavailable.";
	case SCARD_E_READER_UNSUPPORTED:  return "Reader is unsupported.";
	case SCARD_E_SERVICE_STOPPED:     return "Service was stopped.";
	case SCARD_E_SHARING_VIOLATION:   return "Sharing violation.";
	case SCARD_E_SYSTEM_CANCELLED:    return "System cancelled.";
	case SCARD_E_TIMEOUT:             return "Command timeout.";
	case SCARD_E_UNKNOWN_CARD:        return "Unknown card.";
	case SCARD_E_UNKNOWN_READER:      return "Unknown reader specified.";
	case SCARD_E_UNSUPPORTED_FEATURE: return "Feature not supported.";
	case SCARD_F_COMM_ERROR:          return "RPC transport error.";
	case SCARD_F_INTERNAL_ERROR:      return "Unknown internal error.";
	case SCARD_F_UNKNOWN_ERROR:       return "Unknown internal error.";
	case SCARD_F_WAITED_TOO_LONG:     return "Waited too long.";
	case SCARD_W_REMOVED_CARD:        return "Card was removed.";
	case SCARD_W_RESET_CARD:          return "Card was reset.";
	case SCARD_W_UNPOWERED_CARD:      return "Card is unpowered.";
	case SCARD_W_UNRESPONSIVE_CARD:   return "Card is unresponsive.";
	case SCARD_W_UNSUPPORTED_CARD:    return "Card is not supported.";

	/* The following errors are specific to the Perl wrapper */
	case SCARD_P_ALREADY_CONNECTED:   return "Object is already connected";
	case SCARD_P_NOT_CONNECTED:       return "Object is not connected";

	/* We finally end with a generic error message */
	default: return "Unknown (reader specific ?) error...";
	};
}

/*************************************************************************/
/*************** Double Typed Magical variable PCSC::errno ***************/
/*************************************************************************/

/* This is an accessor to our internal double-typed magical variable */
I32 gnLastError_get (pTHX_ IV nID, SV *sv) {
	/* We have to set both int and double values */
	sv_setiv (sv, (IV)gnLastError);
	sv_setnv (sv, (double)gnLastError);

	/* Then we set the error message string */
	sv_setpv (sv, _StringifyError(gnLastError));

	/* Then, we eventually put corresponding bits of the SV flag */
	SvNOK_on (sv);
	SvIOK_on (sv);

	/* return value should be ignored (man samples use return 1) */
	return 1;
}

/* This is a modifier to our internal double-typed magical variable */
I32 gnLastError_set (pTHX_ IV nID, SV *sv) {
	/* just store the value in our global variable */
	gnLastError = SvIV (sv);

	/* return value should be ignored (man samples use return 1) */
	return 1;
}

/* Initialize the double-typed magical variable Chipcard::PCSC::errno */
void _InitMagic () {
	struct ufuncs uf_errno;
	SV    *sv;

	/* Build a new immortal scalar */
	sv = perl_get_sv ("Chipcard::PCSC::errno", TRUE);

	/* Construct the magic virtual table */
	uf_errno.uf_val = &gnLastError_get;
	uf_errno.uf_set = &gnLastError_set;
	uf_errno.uf_index = 0;

	/* Then apply magic to it (use uf_eerno as a callback list) */
	sv_magic (sv, 0, 'U', (char *)&uf_errno, sizeof(uf_errno));

	/* Let the scalar be enchanted ! */
	SvMAGICAL_on (sv);
}

MODULE = Chipcard::PCSC         PACKAGE = Chipcard::PCSC
PROTOTYPES: ENABLE

#///////////////////////////////////////////////////////////////////////////

bool
_LoadPCSCLibrary ()
	CODE:
	if (ghDll) {
		/* No need to load the library twice */
		RETVAL = TRUE;
	} else {
		/* Then loads the dynamic library */
		ghDll = LOAD_LIB();
		if (ghDll == NULL) {
			RETVAL = FALSE;
			croak ("Failed to load PCSC library");
		} else {
			hEstablishContext = (TSCardEstablishContext) GET_FCT (ghDll, "SCardEstablishContext");
			hReleaseContext   = (TSCardReleaseContext)   GET_FCT (ghDll, "SCardReleaseContext");
			hReconnect        = (TSCardReconnect)        GET_FCT (ghDll, "SCardReconnect");
			hDisconnect       = (TSCardDisconnect)       GET_FCT (ghDll, "SCardDisconnect");
			hBeginTransaction = (TSCardBeginTransaction) GET_FCT (ghDll, "SCardBeginTransaction");
			hEndTransaction   = (TSCardEndTransaction)   GET_FCT (ghDll, "SCardEndTransaction");
			hTransmit         = (TSCardTransmit)         GET_FCT (ghDll, "SCardTransmit");
			hControl          = (TSCardControl)          GET_FCT (ghDll, "SCardControl");
			hCancel           = (TSCardCancel)           GET_FCT (ghDll, "SCardCancel");
#ifdef WIN32
			hListReaders      = (TSCardListReaders)      GET_FCT (ghDll, "SCardListReadersA");
			hConnect          = (TSCardConnect)          GET_FCT (ghDll, "SCardConnectA");
			hStatus           = (TSCardStatus)           GET_FCT (ghDll, "SCardStatusA");
			hGetStatusChange  = (TSCardGetStatusChange)  GET_FCT (ghDll, "SCardGetStatusChangeA");
#else
			hListReaders      = (TSCardListReaders)      GET_FCT (ghDll, "SCardListReaders");
			hConnect          = (TSCardConnect)          GET_FCT (ghDll, "SCardConnect");
			hStatus           = (TSCardStatus)           GET_FCT (ghDll, "SCardStatus");
			hGetStatusChange  = (TSCardGetStatusChange)  GET_FCT (ghDll, "SCardGetStatusChange");
#endif
			if (
				!hEstablishContext || !hReleaseContext || !hListReaders || !hConnect ||
				!hReconnect || ! hDisconnect || !hBeginTransaction || !hEndTransaction ||
				!hTransmit || !hStatus || !hGetStatusChange || !hCancel || !hControl)
			{
				RETVAL = FALSE;
				croak ("PCSC library does not contain all the required symbols");
			} else {
				RETVAL = TRUE;
			}
		}
		/* Initialize the magical variable */
		_InitMagic ();
		_InitErrorCodes ();
	}
	OUTPUT:
		RETVAL

#///////////////////////////////////////////////////////////////////////////
#//   EstablishContext ()
#//
#// INPUT :
#// - $dwScope -> Scope of the establishment. This can be either a local
#// or remote connection.
#// - $pvReserved1
#// - $pwReserved2 -> as of this writting, bothe the above parameters
#// are not used by PCSC... they should be 0
#//
#// OUTPUT :
#// EstablishContext() returns the connection context or the 'undef'
#// value if something goes wrong.
SV*
_EstablishContext (dwScope, pvReserved1, pvReserved2)
	unsigned long  dwScope
	void*          pvReserved1
	void*          pvReserved2
	PREINIT:
		SCARDCONTEXT hContext = 0;
	CODE:
		ST(0) = sv_newmortal();
		gnLastError = hEstablishContext (dwScope, pvReserved1, pvReserved2, &hContext);

		/* Then we either return an explicit 'UNDEF' value or the handle */
		if (gnLastError != SCARD_S_SUCCESS) {
			ST(0) = &PL_sv_undef;
		} else {
			sv_setiv (ST(0), hContext);
		}

#///////////////////////////////////////////////////////////////////////////
#//   ReleaseContext ()
#//
#// INPUT :
#// - $hContext -> Connection context to be closed
#//
#// OUTPUT :
#// - ReleaseContext returns a true value on successful operation and a
#// false value otherwise.
bool
_ReleaseContext (hContext)
	unsigned long hContext
	CODE:
		gnLastError = hReleaseContext (hContext);

		/* Then returns true or false according to the return code */
		if (gnLastError != SCARD_S_SUCCESS) {
			RETVAL = FALSE;
		} else {
			RETVAL = TRUE;
		}
	OUTPUT:
		RETVAL
			
#///////////////////////////////////////////////////////////////////////////
#//   ListReaders ()
#//
#// INPUT :
#// - $hContext -> Connection context to the PC/SC resource manager.
#// - $mszGroups -> List of groups to list readers. (as of this writing,
#// this is not used and should be 0
#//
#// OUTPUT :
#// ListReaders returns the 'undef' value if an error occurs otherwise it
#// returns the list of available readers. Note that this can be an empty
#// list...
#//
SV *
_ListReaders(hContext, svGroups)
	unsigned long hContext
	SV*           svGroups
	PREINIT:
		DWORD nBufferSize = 0;
		char* szBuffer = NULL;
		char* szCurrentToken = NULL;
		char* mszGroups;
	PPCODE:
		/* Before doing anything, we check that we have a valid group. */
		if (SvPOK(svGroups)) {
			/* TODO : see how this works... multistring stuff with time
			 *svGroups may become a reference to an array of groups... or undef
			 */
			mszGroups = SvPV (svGroups, PL_na);
		} else {
			mszGroups = 0;
		}

		/*   The first call to SCardListReaders gives us the size of the
		 * buffer we must allocate for the list.
		 */
		gnLastError = hListReaders (hContext, mszGroups, 0, &nBufferSize);

		/* In case of any error we immediately return an explicit UNDEF value */
		if (gnLastError != SCARD_S_SUCCESS) {
			XSRETURN_UNDEF;
		}

		if (nBufferSize > 0) {
			/*   At this point, nBufferSize contains the size of the buffer to
		 	 * alloate. We use New as recomended by perlguts(3pm). The
		 	 * buffer will be freed with Safefree()...
		 	 */
			New (2018, szBuffer, nBufferSize, char);
			if (szBuffer == NULL) {
				gnLastError = SCARD_E_NO_MEMORY;
				warn ("Could not allocate buffer at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}

			/*   The buffer is ready, so we can now retrieve the whole list.  */
			gnLastError = hListReaders (hContext, mszGroups, szBuffer, &nBufferSize);

			/* Then check for any error */
			if (gnLastError != SCARD_S_SUCCESS) {
				Safefree (szBuffer);
				XSRETURN_UNDEF;
			}

			/*   The string must be NULL terminated
		 	 * May be just too much paranoid but...
		 	 */
			if (szBuffer[nBufferSize-1] != 0) {
				Safefree (szBuffer);
				gnLastError = SCARD_F_INTERNAL_ERROR;
				warn ("PCSC did not return a NULL terminated multistring at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}

			/*   Now we need to push each reader separately on the stack. If
		 	 * no readers are found, the stack is left empty...
		 	 */
			szCurrentToken = szBuffer;
			while (strlen(szCurrentToken)) {
				XPUSHs (sv_2mortal(newSVpv(szCurrentToken,0)));
				szCurrentToken = strchr (szCurrentToken, 0) + 1;
			}
			/* Free our buffer...
			 * DO NOT USE free() or delete() here ! Let Perl deal with this.
			 */
			Safefree (szBuffer);
		} else {
			gnLastError = SCARD_F_INTERNAL_ERROR;
			warn ("PCSC did not return a valid buffer length at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

#///////////////////////////////////////////////////////////////////////////
#//   Connect ()
#//
#// INPUT :
#// - $hContext -> Connection context to the PC/SC Resource Manager
#// - $szReader -> ReaderName to connect to
#// - dwShareMode -> Mode of connection : exclusive or shared
#// - dwPreferredProtocols -> Desired protocol use
#//
#// OUTPUT :
#// Connect returns an array with the handle to the connection and the
#// active protocol for this connection ($hCard, $dwActiveProtocol).
#// If a problem occurs, it just return the 'undef' value.
SV*
_Connect (hContext, szReader, dwShareMode, dwPreferredProtocols)
	unsigned long hContext
	const char*   szReader
	unsigned long dwShareMode
	unsigned long dwPreferredProtocols
	PREINIT:
		SCARDHANDLE hCard = 0;
		DWORD dwActiveProtocol = 0;
	PPCODE:
		gnLastError = hConnect (hContext, szReader, dwShareMode, dwPreferredProtocols, &hCard, &dwActiveProtocol);

		/* We return immediately in case of an error */
		if (gnLastError != SCARD_S_SUCCESS)
			XSRETURN_UNDEF;

		/* If anything was successful, push the two scalar values */
		XPUSHs (sv_2mortal(newSViv(hCard)));
		XPUSHs (sv_2mortal(newSViv(dwActiveProtocol)));

#///////////////////////////////////////////////////////////////////////////
#//   Reconnect ()
#//
#// INPUT :
#// - $hCard -> Handle to a previous call to connect
#// - dwShareMode -> Mode of connection : exclusive or shared
#// - dwPreferredProtocols -> Desired protocol use
#// - $dwInitialization -> Desired action taken on the card/reader
#//
#// OUTPUT :
#// Reconnect returns the new active protocol or the 'undef' value if an
#// error occurs
SV*
_Reconnect (hCard, dwShareMode, dwPreferredProtocols, dwInitialization)
	unsigned long hCard
	unsigned long dwShareMode
	unsigned long dwPreferredProtocols
	unsigned long dwInitialization
	PREINIT:
		DWORD dwActiveProtocol = 0;
	CODE:
		ST(0) = sv_newmortal();
		gnLastError = hReconnect (hCard, dwShareMode, dwPreferredProtocols, dwInitialization, &dwActiveProtocol);
		/* Return either an UNDEF value if an error occurs or the current
		 * active protocol as returned by PCSC
		 */
		if (gnLastError == SCARD_S_SUCCESS)
			sv_setiv (ST(0), dwActiveProtocol);
		else
			ST(0) = &PL_sv_undef;

#///////////////////////////////////////////////////////////////////////////
#//   Disconnect ()
#//
#// INPUT :
#// - $hCard -> Connection made from Connect
#// - $dwDisposition -> Desired action taken on the card/reader
#//
#// OUTPUT :
#// Disconnect returns TRUE upon successful result. Oppositely, it
#// returns FALSE if somthing went bang
bool
_Disconnect (hCard, dwDisposition)
	unsigned long hCard;
	unsigned long dwDisposition;
	CODE:
		gnLastError = hDisconnect (hCard, dwDisposition);

		/* Then check for an error */
		if (gnLastError != SCARD_S_SUCCESS)
			RETVAL = FALSE;
		else
			RETVAL = TRUE;
	OUTPUT:
		RETVAL

#///////////////////////////////////////////////////////////////////////////
#//   Status ()
#//
#// INPUT :
#// - $hCard -> Connection made from Connect
#//
#// OUTPUT :
#// Status returns a list holding different informations about the
#// reader : ($szReaderName, $dwState, $dwProtocol, \@bAttr). If an
#// error pops up, the 'undef' value is returned.
#//
#// Important note:
#//   We return the ATR in the form of a reference to an array of bytes.
#// When we build this reference, we start to build an array wich is
#// made mortal, then we fill it with non mortal items usin av_push().
#// These items need to be immortal at this point because av_push does
#// not increase the reference count of the scalar values it pushes into
#// the array. As our array dies when it passes out of scope, perl
#// would free its content and then any attempt to use them would result
#// in an 'Attempt to free unreferenced scalar' error...
SV*
_Status (hCard)
	long hCard
	PREINIT:
		int            nCount = 0;
#ifdef WIN32
		char           tmpReaderName[200];
		char*          szReaderName = tmpReaderName;
		unsigned long  cchReaderLen = sizeof(tmpReaderName);
		char           tmpAtr[MAX_ATR_SIZE];
		unsigned char* pbAtr = tmpAtr;
		unsigned long  cbAtrLen = sizeof(tmpAtr);
#else
		char*          szReaderName = NULL;
		DWORD cchReaderLen = 0;
		unsigned char* pbAtr = NULL;
		DWORD cbAtrLen = 0;
#endif
		DWORD dwState = 0;
		DWORD dwProtocol = 0;
		AV*            aATR = 0;
	PPCODE:
		/* We call the function with a null cchReaderLen : this should
		 * gives us the length of the buffer to allocate
		 */
		gnLastError = hStatus (hCard, szReaderName, &cchReaderLen,
		                       &dwState, &dwProtocol, (BYTE *)pbAtr, &cbAtrLen);
		
		/* Behaviour differs here from PCSC and PCSClite :
		 * PCSC returns SUCCESS while PCSClite returns an error
		 */
		if (gnLastError == SCARD_E_INSUFFICIENT_BUFFER || gnLastError == SCARD_S_SUCCESS) {
			/* The call was hopefuly successful, so we allocate the
			 * buffer for the ATR
			 */
#ifndef WIN32
			/* This hack should be temporary as PCSClite should eventually behave like PCSC */
			cbAtrLen = MAX_ATR_SIZE;
#endif
			if (cbAtrLen <= 0) {
				gnLastError = SCARD_F_INTERNAL_ERROR;
				warn ("PCSC did not return a valid buffer length at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}
			New (2018, pbAtr, cbAtrLen, unsigned char);
			if (pbAtr == NULL) {
				gnLastError = SCARD_E_NO_MEMORY;
				warn ("Could not allocate buffer at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}
			/* we then allocate the buffer for the reader name */
			if (cbAtrLen <= 0) {
				gnLastError = SCARD_F_INTERNAL_ERROR;
				warn ("PCSC did not return a valid buffer length at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}
			New (2018, szReaderName, cchReaderLen, char);
			if (szReaderName == NULL) {
				Safefree (pbAtr);
				gnLastError = SCARD_E_NO_MEMORY;
				warn ("Could not allocate buffer at %s line %d\n\t",
				      __FILE__, __LINE__);
				XSRETURN_UNDEF;
			}
			/* Now we perform the real call to SCardStatus */
			gnLastError = hStatus (hCard, szReaderName, &cchReaderLen,
			                       &dwState, &dwProtocol, (BYTE *)pbAtr, &cbAtrLen);
			if (gnLastError != SCARD_S_SUCCESS) {
				Safefree (szReaderName);
				Safefree (pbAtr);
				XSRETURN_UNDEF;
			}
		} else {
			/* As our first call should trigger the SCARD_E_INSUFFICIENT_BUFFER
			 * error or no error, we consider any other case as a failure...
			 */
			XSRETURN_UNDEF;
		}

		/* we fill this array with every byte from the ATR
		 * note that we do not make this data mortal because av_push()
		 * does not increment the reference count. See the note in the
		 * function header above
		 */
		if (cbAtrLen > 0) {
			/* We first create an array for the ATR */
			aATR = (AV*) sv_2mortal((SV*)newAV());

			/* Then we fill it with every byte from the ATR
			 * note that we do not make this data mortal because av_push()
			 * does not increment the reference count. See the note in the
			 * function header above
			 */
			for (nCount=0; nCount < cbAtrLen; nCount++) {
				av_push (aATR, newSViv(pbAtr[nCount]));
			}
		}
		/* In the event that no ATR is available, we used to fill aATR
		 * with '(AV*) &PL_sv_undef' However, pushing a reference to
		 * this seems is hard to handle I therefore prefer to do
		 * nothing and leave aATR with the default null value and
		 * the code below will not push the reference to the ATR array
		 */

		/* eventually, we end up pushing all the values */
		XPUSHs (sv_2mortal(newSVpv(szReaderName,0)));
		XPUSHs (sv_2mortal(newSViv(dwState)));
		XPUSHs (sv_2mortal(newSViv(dwProtocol)));
		/* as well as a reference to the ATR array if available */
		if (aATR) {
			XPUSHs (sv_2mortal(newRV((SV*)aATR)));
		}

		/* As a conclusion, we just free what we took */
		Safefree (szReaderName);
		Safefree (pbAtr);

#///////////////////////////////////////////////////////////////////////////
#//   Transmit ()
#//
#// INPUT :
#// - $hCard
#// - @inBuffer = ($Protocol, \@BytesToSend)
#// $Protocol contains the protocol (T0|T1)
#// @BytesToSend contains the bytes to transmit
#//   Note: please note that @inBuffer is actually appended to the
#// parameters list, therefore, the following calls are equivalent:
#// @inBuffer ($Protocol, [0x00, 0x12, 0x33]); = ;Transmit ($hCard, @inBuffer);
#// Transmit ($hCard, $Protocol, [0x00, 0x12, 0x33]);
#//
#// OUTPUT :
#// - @outBuffer = ($Protocol, \@BytesRead)
#//   - $Protocol may be undef
#//   - @BytesRead contains the returned bytes
#// Transmit can return the 'undef' value alone if an error occurs.
SV*
_Transmit (hCard, dwProtocol, psvSendData)
	unsigned long hCard;
	unsigned long dwProtocol;
	SV*           psvSendData;
	PREINIT:
		int                        nCount = 0;
		static char*               pbSendBuffer = NULL;
		static unsigned char       pbRecvBuffer [MAX_BUFFER_SIZE_EXTENDED];
		unsigned long              cbSendLength = 0;
		DWORD                      cbRecvLength = sizeof (pbRecvBuffer);
		SCARD_IO_REQUEST           ioSendPci, ioRecvPci;
		AV*                        aRecvBuffer = NULL;
	PPCODE:
		/* We make sure that the array is sane */
		if (psvSendData == NULL) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvSendData is a NULL pointer at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		/* Should the second parameter not be a reference, we return the
		 * SCARD_E_INVALID_PARAMETER error code.
		 */
		if ((!SvROK(psvSendData))||(SvTYPE(SvRV(psvSendData)) != SVt_PVAV)) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvSendData is not a RVAV at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}
		/* We have to build up our IO_REQUEST structures according to
		 * $dwProtocol
		 */
		switch (dwProtocol) {
		case SCARD_PROTOCOL_T0:
		case SCARD_PROTOCOL_T1:
		case SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1:
		case SCARD_PROTOCOL_RAW:
			ioSendPci.dwProtocol  = dwProtocol;
			ioSendPci.cbPciLength = sizeof(ioSendPci);
			ioRecvPci.dwProtocol  = dwProtocol;
			ioRecvPci.cbPciLength = sizeof(ioRecvPci);
			break;
		default:
			/* If $dwProtocol holds an invalid value, we exist reporting
			 * the error SCARD_E_INVALID_VALUE.
			 */
			gnLastError = SCARD_E_INVALID_VALUE;
			warn ("unknown protocol %ld given at %s line %d\n\t",
			      dwProtocol, __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		/* Let's allocate some space for the send buffer */
		cbSendLength = av_len((AV*)SvRV(psvSendData)) + 1;
		if (cbSendLength <= 0) {
			gnLastError = SCARD_E_INVALID_VALUE;
			warn ("empty array given at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}
 		New (2018, pbSendBuffer, cbSendLength, char);
		if (pbSendBuffer == NULL) {
			gnLastError = SCARD_E_NO_MEMORY;
			warn ("Could not allocate buffer at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		/* We have to extract data from the array referenced by psvSendData */
		for (nCount = 0; nCount < cbSendLength ; nCount++)
			pbSendBuffer[nCount] = (char)SvIV(*av_fetch((AV*)SvRV(psvSendData), nCount, 0));

		/* Everything is ready : call the real function... */
		gnLastError = hTransmit (hCard, &ioSendPci, (BYTE *)pbSendBuffer, cbSendLength, &ioRecvPci, pbRecvBuffer, &cbRecvLength);
		if (gnLastError != SCARD_S_SUCCESS) {
			/* Free the buffer if something went wrong */
			Safefree (pbSendBuffer);
			XSRETURN_UNDEF;
		}

		/* At this point, the command was successful. We still need to
		 * return all the values from our buffer...
		 * so we build an array for the ATR
		 */
		aRecvBuffer = (AV*) sv_2mortal((SV*)newAV());

		/* we fill this array with every byte from the Response
		 * note that we do not make this data mortal because av_push()
		 * does not increment the reference count. See the note in the
		 * function header above
		 */
		for (nCount = 0; nCount < cbRecvLength; nCount++)
 			av_push (aRecvBuffer, newSViv(pbRecvBuffer[nCount]));

		XPUSHs (sv_2mortal(newSViv(ioRecvPci.dwProtocol)));
		XPUSHs (sv_2mortal(newRV((SV*)aRecvBuffer)));

		/* Do not forget to free the dynamically allocated buffer */
		Safefree (pbSendBuffer);

#///////////////////////////////////////////////////////////////////////////
#//   Control ()
#//
#// INPUT :
#// - $hCard
#// - $dwControlCode
#// - @inBuffer = (\@BytesToSend)
#// @BytesToSend contains the bytes to transmit
#//
#// OUTPUT :
#// - @outBuffer = (\@BytesRead)
#// - @BytesRead contains the returned bytes
#// Control can return the 'undef' value alone if an error occurs.
SV*
_Control (hCard, dwControlCode, psvSendData)
	unsigned long hCard;
	unsigned long dwControlCode;
	SV*           psvSendData;
	PREINIT:
		int                        nCount = 0;
		static char*               pbSendBuffer = NULL;
		static unsigned char       pbRecvBuffer [MAX_BUFFER_SIZE];
		unsigned long              cbSendLength = 0;
		DWORD                      cbRecvLength = sizeof (pbRecvBuffer);
		AV*                        aRecvBuffer = NULL;
	PPCODE:
		/* We make sure that the array is sane */
		if (psvSendData == NULL) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvSendData is a NULL pointer at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		/* Should the second parameter not be a reference, we return the
		 * SCARD_E_INVALID_PARAMETER error code.
		 */
		if ((!SvROK(psvSendData))||(SvTYPE(SvRV(psvSendData)) != SVt_PVAV)) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvSendData is not a RVAV at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		/* Let's allocate some space for the send buffer, if needed */
		cbSendLength = av_len((AV*)SvRV(psvSendData)) + 1;
		if (cbSendLength <= 0) {
			gnLastError = SCARD_E_INVALID_VALUE;
			warn ("empty array given at %s line %d\n\t",
				  __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}
		New (2018, pbSendBuffer, cbSendLength, char);
		if (pbSendBuffer == NULL) {
			gnLastError = SCARD_E_NO_MEMORY;
			warn ("Could not allocate buffer at %s line %d\n\t",
				  __FILE__, __LINE__);
			XSRETURN_UNDEF;
		}

		for (nCount = 0; nCount < cbSendLength ; nCount++)
			pbSendBuffer[nCount] = (char)SvIV(*av_fetch((AV*)SvRV(psvSendData), nCount, 0));

		/* Everything is ready : call the real function... */
		gnLastError = hControl (hCard, dwControlCode,
			(cbSendLength > 0 ? (BYTE *)pbSendBuffer : NULL), cbSendLength, 
			pbRecvBuffer, sizeof(pbRecvBuffer), &cbRecvLength);

		if (gnLastError != SCARD_S_SUCCESS) {
			/* Free the buffer if something went wrong */
			Safefree (pbSendBuffer);
			XSRETURN_UNDEF;
		}

		/* At this point, the command was successful. We still need to
		 * return all the values from our buffer...
		 */
		aRecvBuffer = (AV*) sv_2mortal((SV*)newAV());

		/* we fill this array with every byte from the Response
		 * note that we do not make this data mortal because av_push()
		 * does not increment the reference count. See the note in the
		 * function header above
		 */
		for (nCount = 0; nCount < cbRecvLength; nCount++)
 			av_push (aRecvBuffer, newSViv(pbRecvBuffer[nCount]));

		// XPUSHs (sv_2mortal(newSViv(ioRecvPci.dwProtocol)));
		XPUSHs (sv_2mortal(newRV((SV*)aRecvBuffer)));

		/* Do not forget to free the dynamically allocated buffer */
		Safefree (pbSendBuffer);


#///////////////////////////////////////////////////////////////////////////
#//   BeginTransaction ()
#//
#// INPUT :
#// - $hCard -> connection made from Connect()
#//
#// OUTPUT :
#// BeginTransaction returns true or false depending on its successful
#// completion
unsigned long
_BeginTransaction (hCard)
	unsigned long hCard;
	CODE:
		gnLastError = hBeginTransaction (hCard);

		/* Then we check for an error */
		if (gnLastError != SCARD_S_SUCCESS)
			RETVAL = FALSE;
		else
			RETVAL = TRUE;
	OUTPUT:
		RETVAL

#///////////////////////////////////////////////////////////////////////////
#//   EndTransaction ()
#//
#// INPUT :
#// - $hCard -> connection made from Connect()
#// - $dwDisposition -> Desired action taken on the card/reader
#//
#// OUTPUT :
#// EndTransaction returns true or false depending on its successful
#// completion
unsigned long
_EndTransaction (hCard, dwDisposition)
	unsigned long hCard;
	unsigned long dwDisposition;
	CODE:
		gnLastError = hEndTransaction (hCard, dwDisposition);

		/* Then we check for an error */
		if (gnLastError != SCARD_S_SUCCESS)
			RETVAL = FALSE;
		else
			RETVAL = TRUE;
	OUTPUT:
		RETVAL

#///////////////////////////////////////////////////////////////////////////
#//   GetStatusChange ()
#//
#// This
#//
#// INPUT :
#// - $hContext -> Connection context to the PC/SC resource manager.
#// - $nTimeout -> Time to wait for a change (or SCARD_INFINITE)
#// - \@ReaderStates -> array of reader states
#//
#// OUTPUT :
bool
_GetStatusChange (hContext, dwTimeout, psvReaderStates)
	unsigned long hContext;
	unsigned long dwTimeout;
	SV*           psvReaderStates;
	PREINIT:
		static SCARD_READERSTATE *rgReaderStates_t = NULL;
		unsigned int               nCount = 0;
		unsigned int               nATRCount = 0;
		unsigned int               nReaders = 0;
		AV*                        aRecvBuffer = NULL;

	PPCODE:
		if (psvReaderStates == NULL) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvReaderStates is a NULL pointer at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_NO;
		}

		/* Should the second parameter not be a reference, we return the
		 * SCARD_E_INVALID_PARAMETER error code.
		 */
		if ((!SvROK(psvReaderStates))||(SvTYPE(SvRV(psvReaderStates)) != SVt_PVAV)) {
			gnLastError = SCARD_E_INVALID_PARAMETER;
			warn ("psvReaderStates is not a RVAV at %s line %d\n\t",
			      __FILE__, __LINE__);
			XSRETURN_NO;
		}

		/* Get the total number of elements in our array */
		nReaders = av_len((AV*)SvRV(psvReaderStates)) + 1;
		
		/* free the memory allocated during previous call to GetStatusChange */
		if (rgReaderStates_t)
			Safefree(rgReaderStates_t);

		/* allocate the Reader States table */
		Newz(2018, rgReaderStates_t, nReaders, SCARD_READERSTATE);
		if (rgReaderStates_t == NULL)
		{
			warn ("Could not allocate buffer at %s line %d\n\t",
				__FILE__, __LINE__);
			XSRETURN_NO;
		}

		for (nCount = 0; nCount < nReaders; nCount++) {
			/* As long as psvReaderStates is a reference to a PVAV we
			 * should be able to use av_fetch() without error
			 */
			SV *svCurrentToken = (*av_fetch((AV*)SvRV(psvReaderStates), nCount, 0));

			/* Now see if the elements in the array are reference to hasharrays */
			if ((!SvROK(svCurrentToken)) || (SvTYPE(SvRV(svCurrentToken)) != SVt_PVHV)) {
				gnLastError = SCARD_E_INVALID_PARAMETER;
				warn ("psvReaderStates[%d] is not a RVHV at %s line %d\n\t", nCount,
				      __FILE__, __LINE__);
				XSRETURN_NO;
			}

			/* Checkout if the 'name' argument has been passed */
			if (hv_exists((HV*)SvRV(svCurrentToken), "reader_name", 11)) {
				SV** psvName         = NULL;

				/* fetch the value of reader_name */
				psvName = hv_fetch((HV*)SvRV(svCurrentToken), "reader_name", 11, 0);

				/* Link the internal structure and the fetched pointer if appropriate */
				if ((psvName != NULL) && (SvTYPE(*psvName) == SVt_PV)) {
//					printf ("We got a name\n");
					rgReaderStates_t[nCount].szReader = SvPV (*psvName, PL_na);
//					printf ("which is : %s\n", rgReaderStates_t[nCount].szReader);
				} else {
					gnLastError = SCARD_E_INVALID_PARAMETER;
					warn ("reader_name is not valid (must be ASCII) at %s line %d\n\t",
					      __FILE__, __LINE__);
					XSRETURN_NO;
				}
			}

			/* Checkout if the 'current_state' argument has been passed */
			if (hv_exists((HV*)SvRV(svCurrentToken), "current_state", 13)) {
				SV** psvCurrentState = NULL;

				/* fetch the value of current_state */
				psvCurrentState = hv_fetch((HV*)SvRV(svCurrentToken), "current_state", 13, 0);

				/* Copy the current status into the struct */
				if (psvCurrentState != NULL) {
					if (SvTYPE(*psvCurrentState) == SVt_IV
						|| SvTYPE(*psvCurrentState) == SVt_PVIV) {
//						printf ("We got a current_state\n");
						rgReaderStates_t[nCount].dwCurrentState = SvIV (*psvCurrentState);
//						printf ("which is : 0x%lX\n", rgReaderStates_t[nCount].dwCurrentState);
					} else {
						gnLastError = SCARD_E_INVALID_PARAMETER;
						warn ("current_state is not valid (must be numeric) at %s line %d\n\t",
						      __FILE__, __LINE__);
						XSRETURN_NO;
					}
				}
			}

			/* Checkout if the 'event_state' argument has been passed */
			if (hv_exists((HV*)SvRV(svCurrentToken), "event_state", 11)) {
				SV** psvEventState   = NULL;

				/* fetch the value of current_state */
				psvEventState = hv_fetch((HV*)SvRV(svCurrentToken), "event_state", 11, 0);
			
				/* Copy the event status into the struct */
				if (psvEventState != NULL) {
					if (SvTYPE(*psvEventState) == SVt_IV
					|| SvTYPE(*psvEventState) == SVt_PVIV) {
						rgReaderStates_t[nCount].dwEventState = SvIV (*psvEventState);
					} else {
						gnLastError = SCARD_E_INVALID_PARAMETER;
						warn ("event_state is not valid (must be numeric) at %s line %d\n\t",
						      __FILE__, __LINE__);
						XSRETURN_NO;
					}
				}
			}


			/* Checkout if the 'ATR' argument has been passed */
			if (hv_exists((HV*)SvRV(svCurrentToken), "ATR", 3)) {
				SV** psvATR          = NULL;

				/* fetch the value of ATR */
				psvATR = hv_fetch((HV*)SvRV(svCurrentToken), "ATR", 3, 0);

				if (psvATR != NULL) {
					/* Make sure we have a reference to an array */
					if ((SvTYPE(*psvATR) == SVt_RV) && (SvTYPE(SvRV(*psvATR)) == SVt_PVAV)) {
						int nATR = 0;

						/* Fetch the ATR length */
						nATR = av_len((AV*)SvRV(*psvATR)) + 1;

						for (nATRCount=0; nATRCount< nATR; nATRCount++) {
							/* Fetch all bytes of th ATR one by one */
							SV *svCurrentATRToken = (*av_fetch((AV*)SvRV(*psvATR), nATRCount, 0));
							if (SvTYPE(svCurrentATRToken) != SVt_IV) {
								/* Return SCARD_E_INVALID_PARAMETER if
								 * the ATR is not made only of numbers
								 */
								gnLastError = SCARD_E_INVALID_PARAMETER;
								warn ("invalid ATR (not a reference to a numerical array) at %s line %d\n\t",
								      __FILE__, __LINE__);
								XSRETURN_NO;
							}
							rgReaderStates_t[nCount].rgbAtr[nATRCount] = (char)SvIV(svCurrentATRToken);
						}
					} else {
						/* ATR is invalid therefore we return SCARD_E_INVALID_PARAMETER */
						gnLastError = SCARD_E_INVALID_PARAMETER;
						warn ("invalid ATR (not a reference to an array) at %s line %d\n\t",
						      __FILE__, __LINE__);
						XSRETURN_NO;
					}
				}
			}
		}

		/* Eventually call the real PCSC function */
		gnLastError = hGetStatusChange (hContext, dwTimeout, rgReaderStates_t, nReaders);

		/* Stop here upon failure */
		if (gnLastError != SCARD_S_SUCCESS) {
			XSRETURN_NO;
		}

		/* Upon successful completion, we have to propagate changes from
		 * the internalm structs to the hash arays, creating entries if
		 * required
		 */
		for (nCount = 0; nCount < nReaders; nCount++) {
			/* As long as psvReaderStates is a reference to a PVAV we
			 * should be able to use av_fetch() without error
			 */
			SV *svCurrentToken = (*av_fetch((AV*)SvRV(psvReaderStates), nCount, 0));

			/* Propagates changes to the reader_name... */
			/* The name was mandatory so we should have it already
			 * linked to our value...
			 */

			/* Propagate changes to the current_state */
			if (hv_exists((HV*)SvRV(svCurrentToken), "current_state", 13)) {
				/* If the current_state was provided we modify its
				 * entry...
				 * Most checks were performed already so this is a
				 * simplified run...
				 */

				/* Copy the struct into current_state */
				sv_setiv (*hv_fetch((HV*)SvRV(svCurrentToken), "current_state", 13, 0),
				          rgReaderStates_t[nCount].dwCurrentState);
			} else {
				/* If the current_state wasn't provided we create its
				 * entry
				 */
				hv_store ((HV*)SvRV(svCurrentToken), "current_state", 13,
				          newSViv(rgReaderStates_t[nCount].dwCurrentState), 0);
			}

			/* Propagate changes to the event_state */
			if (hv_exists((HV*)SvRV(svCurrentToken), "event_state", 11)) {
				/* If the event_state was provided we modify its
				 * entry...
				 * Most checks were performed already so this is a
				 * simplified run...
				 */

				/* Copy the struct into event_state */
				sv_setiv (*hv_fetch((HV*)SvRV(svCurrentToken), "event_state", 11, 0),
				          rgReaderStates_t[nCount].dwEventState);
			} else {
				/* If the current_state wasn't provided we create its
				 * entry
				 */
				hv_store ((HV*)SvRV(svCurrentToken), "event_state", 11,
				          newSViv(rgReaderStates_t[nCount].dwEventState), 0);
			}

			/* Build the ATR if possible */
			if (rgReaderStates_t[nCount].cbAtr > 0) {
				/* Create an AV* with the ATR */
				aRecvBuffer = (AV*) sv_2mortal((SV*)newAV());

				for (nATRCount = 0; nATRCount <rgReaderStates_t[nCount].cbAtr; nATRCount++)
					av_push (aRecvBuffer, newSViv(rgReaderStates_t[nCount].rgbAtr[nATRCount]));

				/* Propagates changes to the ATR */
				if (hv_exists((HV*)SvRV(svCurrentToken), "ATR", 11)) {
					/* If the ATR was provided we modify its entry...
				 	* Most checks were performed already so this is a
				 	* simplified run...
				 	*/

					/* Copy the struct into the ATR */
					sv_setsv (*hv_fetch((HV*)SvRV(svCurrentToken), "ATR", 3, 0),
				          	sv_2mortal(newRV((SV*)aRecvBuffer)));
				} else {
					hv_store ((HV*)SvRV(svCurrentToken), "ATR", 3,
				          	newRV((SV*)aRecvBuffer), 0);
				}
			} else {
				/* Deletes the variable to make sure we do not keep some
				 * old outdated values
				 */
				hv_delete((HV*)SvRV(svCurrentToken), "ATR", 3, G_DISCARD);
			}
		}
		XSRETURN_YES;



#///////////////////////////////////////////////////////////////////////////
#//   Cancel ()
#//
#// This function cancels pending blocking requests from _GetStatusChange ()
#//
#// INPUT :
#// - $hContext -> Connection context to the PC/SC resource manager.
#//
#// OUTPUT :
#// Cancel returns true upon successful conmpletion or false otherwise
bool
_Cancel (hContext)
	unsigned long hContext
	CODE:
		gnLastError = hCancel (hContext);

		/* Then we check for an error */
		if (gnLastError != SCARD_S_SUCCESS)
			RETVAL = FALSE;
		else
			RETVAL = TRUE;
	OUTPUT:
		RETVAL

# End of File #
