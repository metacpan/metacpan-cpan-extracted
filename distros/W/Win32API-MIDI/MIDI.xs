/*
 *	MIDI.xs --- Windows 32bit MIDI API Wrapper Module
 *
 *	$Id: MIDI.xs,v 1.10 2003-03-18 01:05:51-05 hiroo Exp $
 *
 *	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
 *
 *	This program is free software; you can redistribute it and/or
 *	modify it under the same terms as Perl itself.
 *
 *	For more detail of Windows 32bit MIDI API, visit
 *		http://msdn.microsoft.com/library/
 *			Graphics and Multimedia
 *			-> Windows Multimedia
 *			  -> SDK Documentation
 *			    -> Windows Multimedia
 *			      -> Multimedia Audio
 *			        -> Musical Instrument Digital Interface (MIDI)
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <windows.h>
#include <mmsystem.h>

static MMRESULT mmsyserr = MMSYSERR_NOERROR;

static SV *midiInProc = NULL;

static void CALLBACK /* without CALLBACK we have segfault */
midiInProc_wrapper(hMidiIn, wMsg, dwInstance, dwParam1, dwParam2)
     HMIDIIN hMidiIn;
     UINT wMsg;
     DWORD dwInstance;
     DWORD dwParam1;
     DWORD dwParam2;
{
  dSP;
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
#if 0
  warn("midiInProc_wrapper: %p at %p, %x, %x, %x, %x\n",
       hMidiIn, &hMidiIn, wMsg, dwInstance, dwParam1, dwParam2);
  if (dwParam1) {
    MIDIHDR *p = (MIDIHDR *)dwParam1;
    printf("%p, %lx, %lx, %lx, %lx, %p, %p, %lx\n",
	   p->lpData,
	   p->dwBufferLength, p->dwBytesRecorded, p->dwUser, p->dwFlags,
	   p->lpNext, p->reserved,
	   p->dwOffset);
  }
  if (dwParam1) {
    MIDIHDR *p = (MIDIHDR *)dwParam1;
    printf("%p, %lx\n", p->lpData, p->dwBufferLength);
  }
#endif
  if (hMidiIn) {
    SV* rv = sv_newmortal();
    sv_setref_pv(rv, "Win32API::MIDI::In", hMidiIn);
    XPUSHs(rv);
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(wMsg)));
  XPUSHs(sv_2mortal(newSViv(dwInstance)));
  XPUSHs(sv_2mortal(newSViv(dwParam1)));
  XPUSHs(sv_2mortal(newSViv(dwParam2)));
  PUTBACK;

  call_sv(midiInProc, G_DISCARD);

  FREETMPS;
  LEAVE;
}

/* define constants in mmsystem.h */
#include "mmsystem.xs"


/*MODULE = Win32::MIDI	PACKAGE = Win32::MIDI	PREFIX = midi*/
MODULE = Win32API::MIDI	PACKAGE = Win32API::MIDI

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

int
midisyserr()
    PROTOTYPE:
    CODE:
	RETVAL = mmsyserr;
    OUTPUT:
	RETVAL

 # MIDI Services
 # Quering MIDI Devices

UINT
midiInGetNumDevs()
	PROTOTYPE:

UINT
midiOutGetNumDevs()
	PROTOTYPE:

=pod
MMRESULT midiOutGetDevCaps(
  UINT          uDeviceID,
  LPMIDIOUTCAPS lpMidiOutCaps,  <- return value
  UINT          cbMidiOutCaps
);

typedef struct {
    WORD      wMid;
    WORD      wPid;
    MMVERSION vDriverVersion;
    CHAR      szPname[MAXPNAMELEN];
    WORD      wTechnology;
    WORD      wVoices;
    WORD      wNotes;
    WORD      wChannelMask;
    DWORD     dwSupport;
} MIDIOUTCAPS;
=cut

 # midiOutGetDevCaps returns hash reference
HV *
midiOutGetDevCaps(uDeviceID = MIDI_MAPPER)
	unsigned int	uDeviceID
    PROTOTYPE: ;$
    PREINIT:
	  MIDIOUTCAPS	moc;
	  HV * rh;
    CODE:
	{
	  mmsyserr = midiOutGetDevCaps(uDeviceID, &moc, sizeof(MIDIOUTCAPS));
	  rh = (HV *)sv_2mortal((SV *)newHV());
	  if (mmsyserr == MMSYSERR_NOERROR) {
	    hv_store(rh, "wMid",	    4, newSVnv(moc.wMid),	    0);
	    hv_store(rh, "wPid",	    4, newSVnv(moc.wPid),	    0);
	    hv_store(rh, "vDriverVersion", 14, newSVnv(moc.vDriverVersion), 0);
	    hv_store(rh, "szPname",	    7, newSVpv(moc.szPname, 0),	    0);
	    hv_store(rh, "wTechnology",	    4, newSVnv(moc.wTechnology),    0);
	    hv_store(rh, "wVoices",	    7, newSVnv(moc.wVoices),	    0);
	    hv_store(rh, "wNotes",	    6, newSVnv(moc.wNotes),	    0);
	    hv_store(rh, "wChannelMask",   12, newSVnv(moc.wChannelMask),   0);
	    hv_store(rh, "dwSupport",	    9, newSVnv(moc.dwSupport),	    0);
	  } else {
	    /* return undef */
	  }
	  RETVAL = rh;
	}
    OUTPUT:
	RETVAL

=pod
MMRESULT midiInGetDevCaps(
  UINT_PTR     uDeviceID,
  LPMIDIINCAPS lpMidiInCaps,
  UINT         cbMidiInCaps
);

typedef struct {
    WORD      wMid;
    WORD      wPid;
    MMVERSION vDriverVersion;
    CHAR      szPname[MAXPNAMELEN];
    DWORD     dwSupport;
} MIDIINCAPS;
=cut

 # midiInGetDevCaps returns hash reference
HV *
midiInGetDevCaps(uDeviceID)
	unsigned int	uDeviceID
    PROTOTYPE: $
    INIT:
	  MIDIINCAPS	mic;
	  HV * rh;
    CODE:
	{
	  mmsyserr = midiInGetDevCaps(uDeviceID, &mic, sizeof(MIDIINCAPS));
	  rh = (HV *)sv_2mortal((SV *)newHV());
	  if (mmsyserr == MMSYSERR_NOERROR) {
	    hv_store(rh, "wMid",	    4, newSVnv(mic.wMid),	    0);
	    hv_store(rh, "wPid",	    4, newSVnv(mic.wPid),	    0);
	    hv_store(rh, "vDriverVersion", 14, newSVnv(mic.vDriverVersion), 0);
	    hv_store(rh, "szPname",	    7, newSVpv(mic.szPname, 0),	    0);
	    hv_store(rh, "dwSupport",	    9, newSVnv(mic.dwSupport),	    0);
	  } else {
	    /* return undef */
	  }
	  RETVAL = rh;
	}
    OUTPUT:
	RETVAL

=pod
MMRESULT midiConnect(
  HMIDI hMidi,
  HMIDIOUT hmo,
  LPVOID pReserved
);

MMRESULT midiDisconnect(
  HMIDI hMidi,
  HMIDIOUT hmo,
  LPVOID pReserved
);
=cut

MMRESULT
midiConnect(HMIDI hMidi, HMIDIOUT hmo)
    C_ARGS:
	hMidi, hmo, NULL

MMRESULT
midiDisconnect(HMIDI hMidi, HMIDIOUT hmo)
    C_ARGS:
	hMidi, hmo, NULL


########################################################################
MODULE = Win32API::MIDI	PACKAGE = Win32API::MIDI::In	PREFIX = midiIn
=pod
 # Opening and Closing Device Drivers
MMRESULT midiInOpen(
  LPHMIDIIN lphMidiIn,
  UINT      uDeviceID,
  DWORD_PTR dwCallback,
  DWORD_PTR dwCallbackInstance,
  DWORD     dwFlags
);

MMRESULT midiInClose(
  HMIDIIN hMidiIn
);
=cut

HMIDIIN
midiInOpen(unsigned int uDeviceID, \
	   SV * dwCallback, \
	   DWORD dwCallbackInstance = (DWORD)NULL, \
	   DWORD dwFlags = CALLBACK_FUNCTION)
    PROTOTYPE: $$;$$
    PREINIT:
	HMIDIIN		h;
    CODE:
	{
	  switch (dwFlags) {
	  case CALLBACK_NULL:	/* For what this is? */
	    mmsyserr = midiInOpen(&h, uDeviceID,
				  (DWORD_PTR)NULL, (DWORD_PTR)NULL, dwFlags);
	    RETVAL = mmsyserr == MMSYSERR_NOERROR ? h : NULL;
	    break;
	  case CALLBACK_FUNCTION:
	    if (SvTRUE(dwCallback)) {
	      if (midiInProc) {
		SvSetSV(midiInProc, dwCallback);
	      } else {
		midiInProc = newSVsv(dwCallback);
	      }
	    } else {
	      if (midiInProc) {
		SvSetSV(midiInProc, &PL_sv_undef);
	      }
	    }
#if 0
	    warn("2: %p at %p, %x, %p, %x, %x\n",
		 h, &h, uDeviceID,
		 (DWORD_PTR)midiInProc_wrapper,
		 dwCallbackInstance, dwFlags);
#endif
	    mmsyserr = midiInOpen(&h, uDeviceID,
				  (DWORD_PTR)midiInProc_wrapper,
				  (DWORD_PTR)dwCallbackInstance, dwFlags);
	    RETVAL = mmsyserr == MMSYSERR_NOERROR ? h : NULL;
	    break;
	  default:
	    warn("Gnu.xs:midiInOpen[%d]: only CALLBACK_FUNCTION is supported for dwFlags.\n", dwFlags);
	    RETVAL = NULL;
	  }
	}
    OUTPUT:
	RETVAL

MMRESULT
midiInClose(HMIDIIN hmi)
    PROTOTYPE: $

=pod
Managing MIDI Data Blocks

MMRESULT midiInPrepareHeader(
  HMIDIIN hmi,
  LPMIDIHDR lpMidiInHdr,
  UINT cbMidiInHdr
);

MMRESULT midiInUnprepareHeader(
  HMIDIIN hmi,
  LPMIDIHDR lpMidiInHdr,
  UINT cbMidiInHdr
);

typedef struct {
    LPSTR      lpData;
    DWORD      dwBufferLength;
    DWORD      dwBytesRecorded;
    DWORD_PTR  dwUser;
    DWORD      dwFlags;
    struct midihdr_tag far * lpNext;
    DWORD_PTR  reserved;
    DWORD      dwOffset;
    DWORD_PTR  dwReserved[4];
} MIDIHDR;
=cut

MMRESULT
midiInPrepareHeader(HMIDIIN hmi, LPMIDIHDR lpMidiInHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmi, lpMidiInHdr, sizeof(MIDIHDR)

=pod
MMRESULT
midiInPrepareHeader(HMIDIIN hmi, LPMIDIHDR lpMidiInHdr)
    PROTOTYPE: $$
    CODE:
	{
	  LPMIDIHDR p = lpMidiInHdr;
	  printf("midiInPrepareHeader: %p,%p,%4s,%x,%x,%x\n",
		 p, p->lpData, p->lpData,
		 p->dwBufferLength, p->dwBytesRecorded,
		 p->dwUser);
	  RETVAL = midiInPrepareHeader(hmi, lpMidiInHdr, sizeof(MIDIHDR));
	}
=cut

MMRESULT
midiInUnprepareHeader(HMIDIIN hmi, LPMIDIHDR lpMidiInHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmi, lpMidiInHdr, sizeof(MIDIHDR)

MMRESULT
midiInAddBuffer(HMIDIIN hmi, LPMIDIHDR lpMidiInHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmi, lpMidiInHdr, sizeof(MIDIHDR)

MMRESULT
midiInReset(HMIDIIN hmi)
    PROTOTYPE: $

MMRESULT
midiInStart(HMIDIIN hmi)
    PROTOTYPE: $

MMRESULT
midiInStop(HMIDIIN hmi)
    PROTOTYPE: $

=pod
Handling Errors with MIDI Functions

MMRESULT midiInGetErrorText(
  MMRESULT wError,
  LPSTR lpText,
  UINT cchText
);
=cut

SV *
midiInGetErrorText(SV *stub, MMRESULT wError = mmsyserr)
    PROTOTYPE: $;$
    PREINIT:
	char	text[MAXERRORLENGTH];
    CODE:
	ST(0) = sv_newmortal();
	mmsyserr = midiInGetErrorText(wError, text, MAXERRORLENGTH);
	if (mmsyserr == MMSYSERR_NOERROR) {
	  sv_setpv(ST(0), text);
	}

SV *
midiInGetID(HMIDIIN hmi)
    PROTOTYPE: $
    PREINIT:
	UINT id;
    CODE:
	ST(0) = sv_newmortal();
	mmsyserr = midiInGetID(hmi, &id);
	if (mmsyserr == MMSYSERR_NOERROR) {
	  sv_setuv(ST(0), id);
	}


########################################################################
MODULE = Win32API::MIDI	PACKAGE = Win32API::MIDI::Out	PREFIX = midiOut
=pod
# Opening and Closing Device Drivers
MMRESULT midiOutOpen(
  LPHMIDIOUT lphmo,              <- return value
  UINT       uDeviceID,
  DWORD_PTR  dwCallback,
  DWORD_PTR  dwCallbackInstance,
  DWORD      dwFlags
);

MMRESULT midiOutClose(
  HMIDIOUT hmo
);
=cut

HMIDIOUT
midiOutOpen(unsigned int uDeviceID = MIDI_MAPPER, \
	    DWORD dwCallback = (DWORD)NULL, \
	    DWORD dwCallbackInstance = (DWORD)NULL, \
	    DWORD dwFlags = CALLBACK_NULL)
    PROTOTYPE: ;$$$$
    PREINIT:
	HMIDIOUT	h;
    CODE:
	{
	  switch (dwFlags) {
	  case CALLBACK_NULL:
	    mmsyserr = midiOutOpen(&h, uDeviceID,
				   dwCallback, dwCallbackInstance, dwFlags);
	    RETVAL = (mmsyserr == MMSYSERR_NOERROR) ? h : NULL;
	    break;
	  default:
	    warn("Gnu.xs:midiOutOpen[%d]: only CALLBACK_NULL is supported for dwFlags.\n", dwFlags);
	    RETVAL = NULL;
	  }
	}
    OUTPUT:
	RETVAL

MMRESULT
midiOutClose(HMIDIOUT hmo)
    PROTOTYPE: $

=pod
Sending Individual MIDI Messages

MMRESULT midiOutLongMsg(
  HMIDIOUT hmo,
  LPMIDIHDR lpMidiOutHdr,
  UINT cbMidiOutHdr
);

MMRESULT midiOutReset(
  HMIDIOUT hmo
);

MMRESULT midiOutShortMsg(
  HMIDIOUT hmo,
  DWORD dwMsg
);
=cut

MMRESULT
midiOutLongMsg(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmo, lpMidiOutHdr, sizeof(MIDIHDR)

MMRESULT
midiOutReset(HMIDIOUT hmo)
    PROTOTYPE: $

MMRESULT
midiOutShortMsg(HMIDIOUT hmo, DWORD dwMsg)
    PROTOTYPE: $$

=pod
Managing MIDI Data Blocks

MMRESULT midiOutPrepareHeader(
  HMIDIOUT hmo,
  LPMIDIHDR lpMidiOutHdr,
  UINT cbMidiOutHdr
);

MMRESULT midiOutUnprepareHeader(
  HMIDIOUT hmo,
  LPMIDIHDR lpMidiOutHdr,
  UINT cbMidiOutHdr
);

typedef struct {
    LPSTR      lpData; 		!!!
    DWORD      dwBufferLength; 	!!!
    DWORD      dwBytesRecorded;
    DWORD_PTR  dwUser;
    DWORD      dwFlags; 	!!!zero
    struct midihdr_tag far * lpNext;
    DWORD_PTR  reserved;
    DWORD      dwOffset;
    DWORD_PTR  dwReserved[4]; # [8]?
} MIDIHDR;
=cut

MMRESULT
midiOutPrepareHeader(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmo, lpMidiOutHdr, sizeof(MIDIHDR)

MMRESULT
midiOutUnprepareHeader(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr)
    PROTOTYPE: $$
    C_ARGS:
	hmo, lpMidiOutHdr, sizeof(MIDIHDR)

=pod
Handling Errors with MIDI Functions

UINT midiOutGetErrorText(
  MMRESULT mmrError,
  LPSTR lpText,
  UINT cchText
);
=cut

SV *
midiOutGetErrorText(SV *stub, MMRESULT wError = mmsyserr)
    PROTOTYPE: $;$
    PREINIT:
    char	text[MAXERRORLENGTH];
    CODE:
	{
	  ST(0) = sv_newmortal();
	  mmsyserr = midiOutGetErrorText(wError, text, MAXERRORLENGTH);
	  if (mmsyserr == MMSYSERR_NOERROR) {
	    sv_setpv(ST(0), text);
	  }
	}

=pod
MMRESULT midiOutGetID(
  HMIDIOUT hmo,
  LPUINT puDeviceID
);
=cut

UINT
midiOutGetID(HMIDIOUT hmo)
    PROTOTYPE: $
    PREINIT:
	UINT id;
    CODE:
	mmsyserr = midiOutGetID(hmo, &id);
	ST(0) = sv_newmortal();
	if (mmsyserr == MMSYSERR_NOERROR) {
	  sv_setuv(ST(0), id);
	}


########################################################################
MODULE = Win32API::MIDI	PACKAGE = Win32API::MIDI::Stream	PREFIX = midiStream
=pod
midiStreamOpen
MMRESULT midiStreamOpen(
  LPHMIDISTRM lphStream,
  LPUINT      puDeviceID,
  DWORD       cMidi,
  DWORD_PTR   dwCallback,
  DWORD_PTR   dwInstance,
  DWORD      fdwOpen
);

MMRESULT midiStreamClose(
  HMIDISTRM hStream
);

MMRESULT midiStreamOut(
  HMIDISTRM hMidiStream,
  LPMIDIHDR lpMidiHdr,
  UINT cbMidiHdr
);

MMRESULT midiStreamRestart(
  HMIDISTRM hms
);

MMRESULT midiStreamPause(
  HMIDISTRM hms
);

MMRESULT midiStreamStop(
  HMIDISTRM hms
);

MMRESULT midiStreamPosition(
  HMIDISTRM hms,
  LPMMTIME pmmt,
  UINT cbmmt
);

MMRESULT midiStreamProperty(
  HMIDISTRM hms,
  LPBYTE lppropdata,
  DWORD dwProperty
);
=cut

HMIDISTRM
midiStreamOpen(unsigned int uDeviceID = MIDI_MAPPER, \
	       DWORD dwCallback = (DWORD)NULL, \
	       DWORD dwInstance = (DWORD)NULL, \
	       DWORD fdwOpen = CALLBACK_NULL)
    PROTOTYPE: ;$$$$
    PREINIT:
	HMIDISTRM	h;
    CODE:
	{
	  switch (fdwOpen) {
	  case CALLBACK_NULL:
	    mmsyserr = midiStreamOpen(&h, &uDeviceID, 1,
				      dwCallback, dwInstance, fdwOpen);
	    RETVAL = (mmsyserr == MMSYSERR_NOERROR) ? h : NULL;
	    break;
	  default:
	    warn("Gnu.xs:midiStreamOpen[%d]: only CALLBACK_NULL is supported for fdwOpen.\n", fdwOpen);
	    RETVAL = NULL;
	  }
	}
    OUTPUT:
	RETVAL

MMRESULT
midiStreamClose(HMIDISTRM hStream)
    PROTOTYPE: $

MMRESULT
midiStreamOut(HMIDISTRM hMidiStream, LPMIDIHDR lpMidiHdr)
    PROTOTYPE: $$
    C_ARGS:
	hMidiStream, lpMidiHdr, sizeof(MIDIHDR)

MMRESULT
midiStreamRestart(HMIDISTRM hms);
    PROTOTYPE: $

MMRESULT
midiStreamPause(HMIDISTRM hms);
    PROTOTYPE: $

MMRESULT
midiStreamStop(HMIDISTRM hms);
    PROTOTYPE: $

MMRESULT
midiStreamPosition(HMIDISTRM hms, LPMMTIME pmmt);
    PROTOTYPE: $$$
    C_ARGS:
	hms, pmmt, sizeof(MMTIME)

MMRESULT
midiStreamProperty(HMIDISTRM hms, LPBYTE lppropdata, int dwProperty);
    PROTOTYPE: $$$


########################################################################
=pod
- : ignore
?midiOutGetVolume (for internal MIDI synthesizer?)
?midiOutSetVolume (for internal MIDI synthesizer?)
-midiOutCacheDrumPatches (for internal MIDI synthesizer)
-midiOutCachePatches (for internal MIDI synthesizer)
-midiOutMessage (send message to device driver)
-midiInMessage (send message to device driver)

/*
 * Local Variables:
 * c-default-style: "gnu"
 * End:
 */
=cut
