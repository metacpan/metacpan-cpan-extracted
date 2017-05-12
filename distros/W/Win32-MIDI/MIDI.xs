#include <windows.h>
#include <mmsystem.h>

#define __TEMP_WORD  WORD   /* perl defines a WORD, yikes! */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
// Section for the constant definitions.
#define CROAK croak

#undef WORD
#define WORD __TEMP_WORD

MODULE = Win32::MIDI		PACKAGE = Win32::MIDI



int
openDevice(self,device)
	SV* self
	int device
PREINIT:
	HV* hself;
	SV** tmpsv;
	HMIDIOUT thisHandle; 
CODE:
	hself = (HV*) SvRV(self);
	RETVAL = midiOutOpen(&thisHandle,device,NULL,NULL,CALLBACK_NULL);

	if(RETVAL == MMSYSERR_NOERROR) {
		hv_store(hself, "handle", 6, newSViv((long) thisHandle), 0);
		} else {
			warn("Win32::MIDI::openDevice: Unable to open device!\n");
			}
OUTPUT:
	RETVAL
	
	
int
getDeviceID(self)
	SV* self
PREINIT:
	HV* hself;
	SV** tmpsv;
	int id;
	HMIDIOUT thisHandle;
CODE:
	hself = (HV*) SvRV(self);
	tmpsv = hv_fetch(hself, "handle", 6, 0);
	if(tmpsv != NULL) {
		thisHandle = (HMIDIOUT) SvIV(*tmpsv);
		} else {
			warn("Win32::MIDI::getDeviceID: HANDLE not yet created!\n");
			}

	RETVAL = midiOutGetID(thisHandle,&id);

	if(RETVAL != MMSYSERR_NOERROR) {
		warn("Win32::MIDI::getDeviceID: Failed\n");
		} else {
			RETVAL = id;
			}
OUTPUT:
	RETVAL

int
writeMIDI(self, message)
	SV* self
	long message
PREINIT:
	HV* hself;
	SV** tmpsv;
	STRLEN len;
	HMIDIOUT thisHandle;
CODE:
	hself = (HV*) SvRV(self);
	tmpsv = hv_fetch(hself, "handle",6, 0);
	if(tmpsv != NULL) {
		thisHandle = (HMIDIOUT) SvIV(*tmpsv);
		} else {
			warn("Win32::MIDI::writeMIDI: HANDLE not yet created!\n");
			}
	
	RETVAL = midiOutShortMsg(thisHandle,message);

	if(RETVAL != MMSYSERR_NOERROR) {
		warn("Win32::MIDI::writeMIDI: Failed\n");
		}
OUTPUT:
	RETVAL

void
closeDevice(self)
	SV* self
PREINIT:
	HV* hself;
	SV** tmpsv;
	int throwaway;
	HMIDIOUT thisHandle;
CODE:
	hself = (HV*) SvRV(self);
	tmpsv = hv_fetch(hself, "handle",6, 0);
	if(tmpsv != NULL) {
		thisHandle = (HMIDIOUT) SvIV(*tmpsv);
		} else {
			warn("Win32::MIDI::closeDevice: HANDLE not yet created!\n");
			}
	throwaway = midiOutClose(thisHandle);
	if(throwaway == MMSYSERR_NOERROR) {
		hv_store(hself, "handle", 6, newSViv((long) NULL), 0);
		}

int
numDevices()
CODE:
	RETVAL = midiOutGetNumDevs();
OUTPUT:
	RETVAL

	