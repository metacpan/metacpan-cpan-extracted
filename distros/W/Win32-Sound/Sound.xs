/*
#######################################################################
#
# Win32::Sound - An extension to play with Windows sounds
# 
# Author: Aldo Calpini <dada@perl.it>
# Version: 0.52
# Info:
#       http://dada.perl.it/
#       https://github.com/dada/win32-sound
#
#######################################################################
*/

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mmsystem.h>

#define __TEMP_WORD  WORD   /* perl defines a WORD, yikes! */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// Section for the constant definitions.
#define CROAK croak

#undef WORD
#define WORD __TEMP_WORD

#define DEV_WAVEOUT 1
#define DEV_WAVEIN  2
#define DEV_MIDIOUT 3
#define DEV_MIDIIN  4
#define DEV_AUX     5 
#define DEV_MIXER   6

DWORD constant(char *name, int arg) {
    errno = 0;
    switch (*name) {
    case 'A':
        break;
    case 'B':
        break;
    case 'C':
        break;
    case 'D':
        break;
    case 'E':
        break;
    case 'F':
        break;
    case 'G':
        break;
    case 'H':
        break;
    case 'I':
        break;
    case 'J':
        break;
    case 'K':
        break;
    case 'L':
        break;
    case 'M':
        break;
    case 'N':
        break;
    case 'O':
        break;
    case 'P':
        break;
    case 'Q':
        break;
    case 'R':
        break;
    case 'S':
        if (strEQ(name, "SND_SYNC"))
            #ifdef SND_SYNC
                return SND_SYNC;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ASYNC"))
            #ifdef SND_ASYNC
                return SND_ASYNC;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_NODEFAULT"))
            #ifdef SND_NODEFAULT
                return SND_NODEFAULT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_MEMORY"))
            #ifdef SND_MEMORY
                return SND_MEMORY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_LOOP"))
            #ifdef SND_LOOP
                return SND_LOOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_NOSTOP"))
            #ifdef SND_NOSTOP
                return SND_NOSTOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_NOWAIT"))
            #ifdef SND_NOWAIT
                return SND_NOWAIT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS"))
            #ifdef SND_ALIAS
                return SND_ALIAS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_ID"))
            #ifdef SND_ALIAS_ID
                return SND_ALIAS_ID;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_FILENAME"))
            #ifdef SND_FILENAME
                return SND_FILENAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_RESOURCE"))
            #ifdef SND_RESOURCE
                return SND_RESOURCE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_PURGE"))
            #ifdef SND_PURGE
                return SND_PURGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_APPLICATION"))
            #ifdef SND_APPLICATION
                return SND_APPLICATION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_START"))
            #ifdef SND_ALIAS_START
                return SND_ALIAS_START;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMASTERISK"))
            #ifdef SND_ALIAS_SYSTEMASTERISK
                return SND_ALIAS_SYSTEMASTERISK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMQUESTION"))
            #ifdef SND_ALIAS_SYSTEMQUESTION
                return SND_ALIAS_SYSTEMQUESTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMHAND"))
            #ifdef SND_ALIAS_SYSTEMHAND
                return SND_ALIAS_SYSTEMHAND;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMEXIT"))
            #ifdef SND_ALIAS_SYSTEMEXIT
                return SND_ALIAS_SYSTEMEXIT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMSTART"))
            #ifdef SND_ALIAS_SYSTEMSTART
                return SND_ALIAS_SYSTEMSTART;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMWELCOME"))
            #ifdef SND_ALIAS_SYSTEMWELCOME
                return SND_ALIAS_SYSTEMWELCOME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMEXCLAMATION"))
            #ifdef SND_ALIAS_SYSTEMEXCLAMATION
                return SND_ALIAS_SYSTEMEXCLAMATION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SND_ALIAS_SYSTEMDEFAULT"))
            #ifdef SND_ALIAS_SYSTEMDEFAULT
                return SND_ALIAS_SYSTEMDEFAULT;
            #else
                goto not_there;
            #endif
        break;
    case 'T':
        break;
    case 'U':
        break;
    case 'V':
        break;
    case 'W':
        break;
    case 'X':
        break;
    case 'Y':
        break;
    case 'Z':
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

BOOL TranslateDevice(char * name, LPUINT type, LPUINT id) {
    if(0 == strnicmp(name, "AUX", 3)) {
        *type = DEV_AUX;
        *id = atoi((char *) name+3);
        return TRUE;
    }
    if(0 == strnicmp(name, "MIXER", 5)) {
        *type = DEV_MIXER;
        *id = atoi((char *) name+5);
        return TRUE;
    }
    if(0 == strnicmp(name, "WAVEIN", 6)) {
        *type = DEV_WAVEIN;
        *id = atoi((char *) name+6);
        return TRUE;
    }
    if(0 == strnicmp(name, "MIDIIN", 6)) {
        *type = DEV_MIDIIN;
        *id = atoi((char *) name+6);
        return TRUE;
    }
    if(0 == strnicmp(name, "WAVEOUT", 7)) {
        *type = DEV_WAVEOUT;
        *id = atoi((char *) name+7);
        return TRUE;
    }
    if(0 == strnicmp(name, "MIDIOUT", 7)) {
        *type = DEV_MIDIOUT;
        *id = atoi((char *) name+7);
        return TRUE;
    }
    if(0 == stricmp(name, "WAVE_MAPPER")) {
        *type = DEV_WAVEOUT;
        *id = WAVE_MAPPER;
        return TRUE;
    }
    if(0 == stricmp(name, "MIDI_MAPPER")) {
        *type = DEV_MIDIOUT;
        *id = MIDI_MAPPER;
        return TRUE;
    }
    return FALSE;
}

void WaveOutCheckError(MMRESULT mmr) {
    SV* perlerr;
    char errmsg[MAXERRORLENGTH];    
    if(mmr != MMSYSERR_NOERROR) {
        perlerr = perl_get_sv("!", FALSE);
        sv_setiv(perlerr, mmr);
        waveOutGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
        sv_setpv(perlerr, errmsg);
        SvIOK_on(perlerr);
    }           
}

void PerlSetError(int code, char *errmsg) {
    SV* perlerr;
    perlerr = perl_get_sv("!", FALSE);
    sv_setiv(perlerr, code);
    sv_setpv(perlerr, errmsg);
    SvIOK_on(perlerr);
}


MODULE = Win32::Sound       PACKAGE = Win32::Sound

PROTOTYPES: DISABLE

long
_constant(name,arg)
    char *name
    int arg
CODE:
    RETVAL = constant(name, arg);
OUTPUT:
    RETVAL


void
Play(...)
PPCODE:
    UINT flag=0; 
    LPCSTR name = NULL;
    STRLEN n_a;

    if (items > 0)
        name = (LPCSTR)SvPV(ST(0),n_a);
    if (items > 1)
	flag = (UINT)SvIV(ST(1));

    if (sndPlaySoundA(name, flag))
	XSRETURN_YES;
    else
        XSRETURN_NO;

void
Stop(...)
PPCODE:
    if(sndPlaySound(NULL, 0))
        XSRETURN_YES;
    else
        XSRETURN_NO;

void
_Volume(...)
PPCODE:
    DWORD volume;
    MMRESULT mmr;   
    switch(items) {
    case 0:
        mmr = waveOutGetVolume((HWAVEOUT) WAVE_MAPPER, &volume);
        if(mmr == MMSYSERR_NOERROR) {
            if(GIMME == G_ARRAY) {
                EXTEND(SP, 2);
                XST_mIV(0, (long) volume & 0x0000FFFF);
                XST_mIV(1, (long) (volume >> 16) & 0x0000FFFF);
                XSRETURN(2);
            } else {
                XSRETURN_IV(volume);
            }
        } else {
            WaveOutCheckError(mmr);
            XSRETURN_NO;
        }
        break;
    case 1:
        volume = SvIV(ST(0)) | SvIV(ST(0)) << 16;
        mmr = waveOutSetVolume((HWAVEOUT) WAVE_MAPPER, volume);
        if(mmr == MMSYSERR_NOERROR) {
            XSRETURN_YES;
        } else {
            WaveOutCheckError(mmr);
            XSRETURN_NO;
        }
        break;
    default:
        volume = SvIV(ST(0)) | SvIV(ST(1)) << 16;
        mmr = waveOutSetVolume((HWAVEOUT) WAVE_MAPPER, volume);
        if(mmr == MMSYSERR_NOERROR) {
            XSRETURN_YES;
        } else {
            WaveOutCheckError(mmr);
            XSRETURN_NO;
        }
        break;
    }

void
Format(filename)
    char * filename
PPCODE:
    HMMIO mmio;
    MMCKINFO mmchunk; 
    MMCKINFO mmsubchunk; 
    WAVEFORMATEX wavfmt;
    mmio = mmioOpen((LPSTR) filename, NULL, MMIO_READ);
    mmchunk.fccType = mmioFOURCC('W', 'A', 'V', 'E'); 
    if (mmioDescend(mmio, &mmchunk, NULL, MMIO_FINDRIFF)) {
        PerlSetError(-1, "File is not a valid waveform audio file");
        mmioClose(mmio, 0);
        XSRETURN_NO;
    } else {
        mmsubchunk.ckid = mmioFOURCC('f', 'm', 't', ' '); 
        if(mmioDescend(mmio, &mmsubchunk, &mmchunk, MMIO_FINDCHUNK)) {
            PerlSetError(-1, "File is not a valid waveform audio file (can't find format)");
            mmioClose(mmio, 0);
            XSRETURN_NO;
        } else {
            mmioRead(mmio, (HPSTR) &wavfmt, sizeof(wavfmt));
            XST_mIV(0, wavfmt.nSamplesPerSec);
            XST_mIV(1, wavfmt.wBitsPerSample);
            XST_mIV(2, wavfmt.nChannels);
            mmioClose(mmio, 0);
            XSRETURN(3);
        }
    }
    mmioClose(mmio, 0);
    XSRETURN_NO;

void
Devices()
PPCODE:
    UINT i;
    int c;
    char temp[32];
    c = 0;
    XST_mPV(c, "WAVE_MAPPER");
    c++;
    for(i=0;i<waveOutGetNumDevs();i++) {
        sprintf(temp, "WAVEOUT%d", i);
        XST_mPV(c, temp);
        c++;
    }
    for(i=0;i<waveInGetNumDevs();i++) {
        sprintf(temp, "WAVEIN%d", i);
        XST_mPV(c, temp);
        c++;
    }
    XST_mPV(c, "MIDI_MAPPER");
    c++;
    for(i=0;i<midiOutGetNumDevs();i++) {
        sprintf(temp, "MIDIOUT%d", i);
        XST_mPV(c, temp);
        c++;
    }
    for(i=0;i<midiInGetNumDevs();i++) {
        sprintf(temp, "MIDIIN%d", i);
        XST_mPV(c, temp);
        c++;
    }
    for(i=0;i<auxGetNumDevs();i++) {
        sprintf(temp, "AUX%d", i);
        XST_mPV(c, temp);
        c++;
    }
    for(i=0;i<mixerGetNumDevs();i++) {
        sprintf(temp, "MIXER%d", i);
        XST_mPV(c, temp);
        c++;
    }
    XSRETURN(c-1);    

void
DeviceInfo(name)
    char * name
PREINIT:
    UINT type;
    UINT id;
    int hi;
    int lo;
    char temp[10];
    MMRESULT mmr;
    WAVEINCAPS wicap;
    WAVEOUTCAPS wocap;
    MIDIINCAPS micap;
    MIDIOUTCAPS mocap;
    AUXCAPS acap;
    MIXERCAPS mcap;
    SV* perlerr;
    char errmsg[MAXERRORLENGTH];
PPCODE:
    if(TranslateDevice(name, &type, &id)) {
        switch(type) {
        case DEV_WAVEIN:
            mmr = waveInGetDevCaps(id, &wicap, sizeof(WAVEINCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (wicap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = wicap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, wicap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, wicap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, wicap.szPname);
                XST_mPV( 8, "formats");
                XST_mIV( 9, wicap.dwFormats);
                XST_mPV(10, "channels");
                XST_mIV(11, wicap.wChannels);
                XSRETURN(12);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                waveInGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;
        case DEV_WAVEOUT:
            mmr = waveOutGetDevCaps(id, &wocap, sizeof(WAVEOUTCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (wocap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = wocap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, wocap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, wocap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, wocap.szPname);
                XST_mPV( 8, "formats");
                XST_mIV( 9, wocap.dwFormats);
                XST_mPV(10, "channels");
                XST_mIV(11, wocap.wChannels);
                XST_mPV(12, "support");
                XST_mIV(13, wocap.dwSupport);
                XSRETURN(14);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                waveOutGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;
        case DEV_MIDIIN:
            mmr = midiInGetDevCaps(id, &micap, sizeof(MIDIINCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (micap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = micap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, micap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, micap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, micap.szPname);
                XSRETURN(8);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                midiInGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;
        case DEV_MIDIOUT:
            mmr = midiOutGetDevCaps(id, &mocap, sizeof(MIDIOUTCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (mocap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = mocap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, mocap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, mocap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, mocap.szPname);
                XST_mPV( 8, "technology");
                XST_mIV( 9, mocap.wTechnology);
                XST_mPV(10, "voices");
                XST_mIV(11, mocap.wVoices);
                XST_mPV(12, "notes");
                XST_mIV(13, mocap.wNotes);
                XST_mPV(14, "channels");
                XST_mIV(15, mocap.wChannelMask);
                XST_mPV(16, "support");
                XST_mIV(17, mocap.dwSupport);
                XSRETURN(18);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                midiOutGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;
        case DEV_AUX:
            mmr = auxGetDevCaps(id, &acap, sizeof(AUXCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (acap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = acap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, acap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, acap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, acap.szPname);
                XST_mPV( 8, "technology");
                XST_mIV( 9, acap.wTechnology);
                XST_mPV(10, "voices");
                XST_mIV(11, acap.dwSupport);
                XSRETURN(12);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                waveOutGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;
        case DEV_MIXER:
            mmr = mixerGetDevCaps(id, &mcap, sizeof(MIXERCAPS));
            if(mmr == MMSYSERR_NOERROR) {
                hi = (mcap.vDriverVersion & 0xFF00 ) >> 8; 
                lo = mcap.vDriverVersion & 0x00FF; 
                sprintf(temp, "%d.%d", hi, lo);
                XST_mPV( 0, "manufacturer_id");
                XST_mIV( 1, mcap.wMid);
                XST_mPV( 2, "product_id");
                XST_mIV( 3, mcap.wPid);
                XST_mPV( 4, "driver_version");
                XST_mPV( 5, temp);
                XST_mPV( 6, "name");
                XST_mPV( 7, mcap.szPname);
                XST_mPV( 8, "destinations");
                XST_mIV( 9, mcap.cDestinations);
                XST_mPV(10, "voices");
                XST_mIV(11, mcap.fdwSupport);
                XSRETURN(12);
            } else {
                perlerr = perl_get_sv("!", FALSE);
                sv_setiv(perlerr, mmr);
                waveOutGetErrorText(mmr, (LPSTR) errmsg, MAXERRORLENGTH);
                sv_setpv(perlerr, errmsg);
                SvIOK_on(perlerr);
                XSRETURN_NO;
            }
            break;            
        default:
            XSRETURN_NO;
            break;
        }
    } else {
        PerlSetError(-1, "Win32::Sound::DeviceInfo: invalid device name");
        XSRETURN_NO;
    }


MODULE = Win32::Sound       PACKAGE = Win32::Sound::WaveOut

int
OpenDevice(self, id=0)
    SV* self
    int id
PREINIT:
    HV* hself;
    SV** tmpsv;
    WAVEFORMATEX wavfmt;
    HWAVEOUT wo;
CODE:
    hself = (HV*) SvRV(self);
    wavfmt.wFormatTag = WAVE_FORMAT_PCM;        
    tmpsv = hv_fetch(hself, "channels", 8, 0);
    if(tmpsv != NULL) {
        wavfmt.nChannels = (WORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("Win32::Sound::WaveOut::OpenDevice: invalid format (channels)");
    }    
    tmpsv = hv_fetch(hself, "samplerate", 10, 0);
    if(tmpsv != NULL) {
        wavfmt.nSamplesPerSec = (DWORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("Win32::Sound::WaveOut::OpenDevice: invalid format (samplerate)");
    }    
    tmpsv = hv_fetch(hself, "bits", 4, 0);
    if(tmpsv != NULL) {
        wavfmt.wBitsPerSample = (WORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("Win32::Sound::WaveOut::OpenDevice: invalid format (bits)\n");
    }    
    tmpsv = hv_fetch(hself, "blockalign", 10, 0);
    if(tmpsv != NULL) {
        wavfmt.nBlockAlign = (WORD) SvIV(*tmpsv);
    } else {
        wavfmt.nBlockAlign = wavfmt.nChannels * wavfmt.wBitsPerSample / 8;
    }
    tmpsv = hv_fetch(hself, "avgbytes", 7, 0);
    if(tmpsv != NULL) {
        wavfmt.nAvgBytesPerSec = (DWORD) SvIV(*tmpsv);
    } else {
        wavfmt.nAvgBytesPerSec = wavfmt.nSamplesPerSec * wavfmt.nBlockAlign;
    }
    wavfmt.cbSize = 0;
    RETVAL = waveOutOpen(
        &wo,
        (UINT) id,
        &wavfmt,
        0,
        0,
        CALLBACK_NULL
    );
    if(RETVAL == MMSYSERR_NOERROR) {
        hv_store(hself, "handle", 6, newSViv((long) wo), 0);
    } else {
        WaveOutCheckError(RETVAL);
    }    
OUTPUT:
    RETVAL

int
CloseDevice(self)
    SV* self
PREINIT:
    HV* hself;
    SV** tmpsv;
    HWAVEOUT wo;
CODE:
    hself = (HV*) SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        RETVAL = waveOutClose(wo);
        WaveOutCheckError(RETVAL);
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

int
Load(self, data)
    SV* self
    SV* data
PREINIT:
    HV* hself;
    SV** tmpsv;
    LPWAVEHDR wh;
    HWAVEOUT wo;
    LPSTR wavdata;
    DWORD wavlength;
    HGLOBAL hgdata;
    HGLOBAL hghead;
CODE:
    hself = (HV*) SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        wavlength = SvLEN(data);
        hgdata = GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE, wavlength);
        hv_store(hself, "wavdata", 7, newSViv((long) hgdata), 0);
        wavdata = (LPSTR) GlobalLock(hgdata);
        hv_store(hself, "wavdatalock", 11, newSViv((long) wavdata), 0);
        memcpy((void*)wavdata, (void*)SvPV(data, PL_na), (size_t)wavlength);
        hghead = GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE, sizeof(WAVEHDR));
        hv_store(hself, "wavhead", 7, newSViv((long) hghead), 0);
        wh = (LPWAVEHDR) GlobalLock(hghead);
        hv_store(hself, "wavheadlock", 11, newSViv((long) wh), 0);
        wh->lpData = wavdata;
        wh->dwBufferLength = wavlength;
        wh->dwFlags = 0;
        RETVAL = waveOutPrepareHeader(wo, wh, sizeof(WAVEHDR));
        WaveOutCheckError(RETVAL);
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

int
Write(self)
    SV* self
PREINIT:
    HV* hself;
    SV** tmpsv;
    HWAVEOUT wo;
    LPWAVEHDR wh;
CODE:
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        tmpsv = hv_fetch(hself, "wavheadlock", 11, 0);
        if(tmpsv != NULL) {
            wh = INT2PTR(LPWAVEHDR, SvIV(*tmpsv));
            RETVAL = waveOutWrite(wo, wh, sizeof(WAVEHDR));
            WaveOutCheckError(RETVAL);          
        } else {
            PerlSetError(-1, "No data loaded");
            RETVAL = -1;
        }
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

long
Save(self, file, data=&PL_sv_undef)
    SV* self
    char * file
    SV* data
PREINIT:
    HV* hself;
    SV** tmpsv;
    HMMIO mmio;
    WAVEFORMATEX wavfmt;
    MMCKINFO mmchunk; 
    MMCKINFO mmsubchunk; 
    MMRESULT mmr;
    char _huge* buffer;
    LONG bufferlen;
CODE:
    hself = (HV*)SvRV(self);
    #
    # prepare the format header
    #
    wavfmt.wFormatTag = WAVE_FORMAT_PCM;    
    tmpsv = hv_fetch(hself, "channels", 8, 0);
    if(tmpsv != NULL) {
        wavfmt.nChannels = (WORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("WaveOut::Save: invalid format (channels)");
    }
    tmpsv = hv_fetch(hself, "samplerate", 10, 0);
    if(tmpsv != NULL) {
        wavfmt.nSamplesPerSec = (DWORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("WaveOut::Save: invalid format (samplerate)");
    }
    tmpsv = hv_fetch(hself, "bits", 4, 0);
    if(tmpsv != NULL) {
        wavfmt.wBitsPerSample = (WORD) SvIV(*tmpsv);
    } else {
        if(PL_dowarn) warn("WaveOut::Save: invalid format (bits)");
    }
    tmpsv = hv_fetch(hself, "blockalign", 10, 0);
    if(tmpsv != NULL) {
        wavfmt.nBlockAlign = (WORD) SvIV(*tmpsv);
    } else {
        wavfmt.nBlockAlign = wavfmt.nChannels * wavfmt.wBitsPerSample / 8;
    }
    tmpsv = hv_fetch(hself, "avgbytes", 7, 0);
    if(tmpsv != NULL) {
        wavfmt.nAvgBytesPerSec = (DWORD) SvIV(*tmpsv);
    } else {
        wavfmt.nAvgBytesPerSec = wavfmt.nSamplesPerSec * wavfmt.nBlockAlign;
    }
    wavfmt.cbSize = 0;
    #
    # prepare data to be written
    #
    buffer = NULL;
    if(SvOK(data)) {
        buffer = (char _huge*)SvPV(data, PL_na);
        bufferlen = SvLEN(data);
    } else {
        tmpsv = hv_fetch(hself, "wavdatalock", 11, 0);
        if(tmpsv != NULL) {
            buffer = INT2PTR(char _huge*, SvIV(*tmpsv));
            bufferlen = (LONG) GlobalSize((HGLOBAL) buffer);
            # printf("XS(WaveOut::Save): loaded bufferlen=%ld\n", bufferlen);
        } else {
            PerlSetError(-1, "No data loaded");
            RETVAL = -1;
        }
    }
    #
    # write all
    #
    if(buffer != NULL) {
        mmio = mmioOpen((LPSTR)file, NULL, MMIO_CREATE | MMIO_WRITE);
        #
        # first chunk (RIFF->WAVE)    
        #
        mmchunk.fccType = mmioFOURCC('W', 'A', 'V', 'E'); 
        mmchunk.cksize = 0;
        mmr = mmioCreateChunk(mmio, &mmchunk, MMIO_CREATERIFF); 
        #
        # first subchunk (fmt )    
        #
        mmsubchunk.ckid = mmioFOURCC('f', 'm', 't', ' '); 
        mmsubchunk.cksize = 0;
        mmr = mmioCreateChunk(mmio, &mmsubchunk, 0);
        mmr = mmioWrite(mmio, (char _huge*)&wavfmt, sizeof(wavfmt));
        mmr = mmioAscend(mmio, &mmsubchunk, 0);
        #
        # second subchunk (data)
        #
        mmsubchunk.ckid = mmioFOURCC('d', 'a', 't', 'a'); 
        mmsubchunk.cksize = 0;
        mmr = mmioCreateChunk(mmio, &mmsubchunk, 0);
        RETVAL = mmioWrite(mmio, buffer, bufferlen);
        mmr = mmioAscend(mmio, &mmsubchunk, 0);
        mmr = mmioAscend(mmio, &mmchunk, 0);
        mmioClose(mmio, 0);
    }
OUTPUT:
    RETVAL

int
Unload(self)
    SV* self
PREINIT:
    HV* hself;
    SV** tmpsv;
    HGLOBAL hg;
    HWAVEOUT wo;
    LPWAVEHDR wh;
CODE:
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        tmpsv = hv_fetch(hself, "wavheadlock", 11, 0);
        if(tmpsv != NULL) {
            wh = INT2PTR(LPWAVEHDR, SvIV(*tmpsv));
            if(wh->dwFlags & WHDR_PREPARED) {
                RETVAL = waveOutUnprepareHeader(wo, wh, sizeof(wh));
            }
            GlobalUnlock((HGLOBAL) wh);
            hv_delete(hself, "wavheadlock", 11, 0);
        }
        tmpsv = hv_fetch(hself, "wavhead", 7, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalFree(hg);
            hv_delete(hself, "wavhead", 7, 0);
        }
        tmpsv = hv_fetch(hself, "wavdatalock", 11, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalUnlock(hg);
            hv_delete(hself, "wavdatalock", 11, 0);
        }
        tmpsv = hv_fetch(hself, "wavdata", 7, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalFree(hg);
            hv_delete(hself, "wavdata", 7, 0);
        }        
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

void
Open(self, id=0, filename)
    SV* self
    int id
    char * filename
PREINIT:
    HV* hself;
    SV** tmpsv;
    HMMIO mmio;
    MMCKINFO mmchunk; 
    MMCKINFO mmsubchunk; 
    WAVEFORMATEX wavfmt;
    HWAVEOUT wo;
    MMRESULT mmr;
PPCODE:
    hself = (HV*) SvRV(self);
    tmpsv = hv_fetch(hself, "mmio", 4, 0);
    if(tmpsv != NULL) {
        mmio = INT2PTR(HMMIO, SvIV(*tmpsv));
        mmioClose(mmio, 0);
    }
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        waveOutClose(wo);
    }   
    mmio = mmioOpen((LPSTR) filename, NULL, MMIO_READ);
    if(mmio == NULL) {
        PerlSetError(-1, "Can't open file");
        XSRETURN_NO;
    } else {
        mmchunk.fccType = mmioFOURCC('W', 'A', 'V', 'E'); 
        if (mmioDescend(mmio, &mmchunk, NULL, MMIO_FINDRIFF)) {
            PerlSetError(-1, "File is not a valid waveform audio file");
            mmioClose(mmio, 0);
            XSRETURN_NO;
        } else {
            mmsubchunk.ckid = mmioFOURCC('f', 'm', 't', ' '); 
            if(mmioDescend(mmio, &mmsubchunk, &mmchunk, MMIO_FINDCHUNK)) {
                PerlSetError(-1, "File is not a valid waveform audio file (can't find format)");
                mmioClose(mmio, 0);
                XSRETURN_NO;
            } else {
                mmioRead(mmio, (HPSTR) &wavfmt, sizeof(wavfmt));
                mmr = waveOutOpen(
                    &wo, 
                    (UINT) id, 
                    &wavfmt, 
                    0, 
                    0, 
                    CALLBACK_NULL /* | WAVE_ALLOWSYNC | WAVE_FORMAT_DIRECT */
                );
                if(mmr == MMSYSERR_NOERROR) {
                    hv_store(hself, "handle", 6, newSViv((long) wo), 0);
                    hv_store(hself, "mmio", 4, newSViv((long) mmio), 0);
                    XSRETURN_IV((long) mmio);
                } else {
                    WaveOutCheckError(mmr);
                    mmioClose(mmio, 0);
                    XSRETURN_NO;
                }
            }
        }
    }


void
Play(self, from=-1, to=-1)
    SV* self
    long from
    long to
PREINIT:
    HV* hself;
    SV** hmmio;
    HMMIO mmio;
    SV** hwo;
    HWAVEOUT wo;
    LPSTR wavdata;
    DWORD wavlength;
    MMCKINFO mmchunk; 
    MMCKINFO mmsubchunk; 
    LPWAVEHDR wh;
    HGLOBAL hgdata;
    HGLOBAL hghead;
    MMRESULT mmr;
PPCODE:   
    hself = (HV*)SvRV(self);
    hmmio = hv_fetch(hself, "mmio", 4, 0);
    if(hmmio != NULL) {
        mmio = INT2PTR(HMMIO, SvIV(*hmmio));
        mmioSeek(mmio, 0, SEEK_SET);
        mmchunk.fccType = mmioFOURCC('W', 'A', 'V', 'E'); 
        if (mmioDescend(mmio, &mmchunk, NULL, MMIO_FINDRIFF)) {
            PerlSetError(-1, "File is not a valid waveform audio file");
            XSRETURN_NO;
        } else {
            mmsubchunk.ckid = mmioFOURCC('d', 'a', 't', 'a'); 
            if(mmioDescend(mmio, &mmsubchunk, &mmchunk, MMIO_FINDCHUNK)) {
                PerlSetError(-1, "File is not a valid waveform audio file");
                XSRETURN_NO;
            } else {
                wavlength = mmsubchunk.cksize;
                if(from != -1) {
                    if(mmioSeek(mmio, from, SEEK_CUR) == -1) {
                        PerlSetError(-1, "Error reading from file");
                        XSRETURN_NO;
                    }
                    wavlength -= from;
                }
                if(to != -1) wavlength = to;
                hgdata = GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE, wavlength);
                hv_store(hself, "wavdata", 7, newSViv((long) hgdata), 0);
                wavdata = (LPSTR) GlobalLock(hgdata);
                hv_store(hself, "wavdatalock", 11, newSViv((long) wavdata), 0);
                if(mmioRead(mmio, (HPSTR) wavdata, wavlength) == 1) {
                    PerlSetError(-1, "Error reading from file");
                    XSRETURN_NO;
                }
                hghead = GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE, sizeof(WAVEHDR));
                hv_store(hself, "wavhead", 7, newSViv((long) hghead), 0);
                wh = (LPWAVEHDR) GlobalLock(hghead);
                hv_store(hself, "wavheadlock", 11, newSViv((long) wh), 0);
                wh->lpData = wavdata;
                wh->dwBufferLength = wavlength;
                wh->dwFlags = 0;
                hwo = hv_fetch(hself, "handle", 6, 0);
                if(hwo != NULL) {
                    wo = INT2PTR(HWAVEOUT, SvIV(*hwo));
                    mmr = waveOutPrepareHeader(wo, wh, sizeof(WAVEHDR));
                    if(mmr == MMSYSERR_NOERROR) {
                        mmr = waveOutWrite(wo, wh, sizeof(WAVEHDR));
                        if(mmr == MMSYSERR_NOERROR) {
                            XSRETURN_YES;
                        } else {
                            WaveOutCheckError(mmr);
                            XSRETURN_NO;
                        }
                    } else {
                        WaveOutCheckError(mmr);
                        XSRETURN_NO;
                    }
                } else {
                    PerlSetError(-1, "Device is not opened");
                    XSRETURN_NO;
                }
            }
        }
    } else {
        PerlSetError(-1, "No file opened");
        XSRETURN_NO;
    }

void
Status(self)
    SV* self
PPCODE:
    HV* hself;
    SV** wavhead;
    LPWAVEHDR wh;
    hself = (HV*)SvRV(self);
    wavhead = hv_fetch(hself, "wavheadlock", 11, 0);
    if(wavhead != NULL) {
        wh = INT2PTR(LPWAVEHDR, SvIV(*wavhead));
        if(wh->dwFlags & WHDR_DONE) {
            XSRETURN_IV(1);
        } else {
            XSRETURN_IV(0);
        }
    } else {
        PerlSetError(-1, "No data loaded");
        XSRETURN_NO;
    }

void
Position(self)
    SV* self
PPCODE:
    HV* hself;
    SV** handle;
    HWAVEOUT wo;
    MMTIME mmt;
    MMRESULT mmr;
    int ttype;
    ttype = TIME_SAMPLES;
    hself = (HV*)SvRV(self);
    handle = hv_fetch(hself, "handle", 6, 0);
    if(handle != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*handle));
        mmt.wType = (UINT) ttype;
        mmr = waveOutGetPosition(wo, &mmt, sizeof(MMTIME));
        if(mmr == MMSYSERR_NOERROR) {
            switch(mmt.wType) {
            case TIME_SAMPLES:
                XSRETURN_IV((long) mmt.u.sample);
            case TIME_TICKS:
                XSRETURN_IV((long) mmt.u.ticks);
            case TIME_MS:
                XSRETURN_IV((long) mmt.u.ms);
            default:
                XSRETURN_NO;
            }
        } else {
            WaveOutCheckError(mmr);
            XSRETURN_NO;
        }
    } else {
        PerlSetError(-1, "Device is not opened");
        XSRETURN_NO;
    }

int
Pause(self)
    SV* self
PREINIT:
    HV* hself;
    SV** handle;
CODE:   
    hself = (HV*)SvRV(self);
    handle = hv_fetch(hself, "handle", 6, 0);
    if(handle != NULL) {
        RETVAL = waveOutPause(INT2PTR(HWAVEOUT, SvIV(*handle)));
        WaveOutCheckError(RETVAL);
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

int
Restart(self)
    SV* self
PREINIT:
    HV* hself;
    SV** handle;
CODE:
    hself = (HV*)SvRV(self);
    handle = hv_fetch(hself, "handle", 6, 0);
    if(handle != NULL) {
        RETVAL = waveOutRestart(INT2PTR(HWAVEOUT, SvIV(*handle)));
        WaveOutCheckError(RETVAL);
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

int
Reset(self)
    SV* self
PREINIT:
    HV* hself;
    SV** handle;
CODE:
    hself = (HV*)SvRV(self);
    handle = hv_fetch(hself, "handle", 6, 0);
    if(handle != NULL) {
        RETVAL = waveOutReset(INT2PTR(HWAVEOUT, SvIV(*handle)));
        WaveOutCheckError(RETVAL);
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

void
_Volume(self, ...)
    SV* self
PPCODE:
    DWORD volume;
    HV* hself;
    SV** handle;
    HWAVEOUT wo;
    MMRESULT mmr;
    hself = (HV*)SvRV(self);
    handle = hv_fetch(hself, "handle", 6, 0);    
    if(handle != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*handle));
        switch(items) {
        case 0:
            mmr = waveOutGetVolume(wo, &volume);
            if(mmr == MMSYSERR_NOERROR) {
                if(GIMME == G_ARRAY) {
                    EXTEND(SP, 2);
                    XST_mIV(0, (long) volume & 0x00FF);
                    XST_mIV(1, (long) (volume & 0xFF00) >> 8);
                    XSRETURN(2);
                } else {
                    XSRETURN_IV(volume);
                }
            } else {
                WaveOutCheckError(mmr);
                XSRETURN_NO;
            }
            break;
        case 1:
            volume = SvIV(ST(0)) | SvIV(ST(0)) << 8;
            mmr = waveOutSetVolume(wo, volume);
            if(mmr == MMSYSERR_NOERROR) {
                XSRETURN_YES;
            } else {
                WaveOutCheckError(mmr);
                XSRETURN_NO;
            }
            break;
        default:
            volume = SvIV(ST(0)) | SvIV(ST(1)) << 8;
            mmr = waveOutSetVolume(wo, volume);
            if(mmr == MMSYSERR_NOERROR) {
                XSRETURN_YES;
            } else {
                WaveOutCheckError(mmr);
                XSRETURN_NO;
            }
            break;
        }
    } else {
        PerlSetError(-1, "Device is not opened");
        XSRETURN_IV(-1);
    }

int
Close(self)
    SV* self
CODE:
    HV* hself;
    SV** tmpsv;
    HMMIO mmio;
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "mmio", 4, 0);
    if(tmpsv != NULL) {
        mmio = INT2PTR(HMMIO, SvIV(*tmpsv));
        RETVAL = mmioClose(mmio, 0);
        hv_delete(hself, "mmio", 4, 0);
    } else {
        PerlSetError(-1, "No file opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

long
_Pitch(self, pitch=0)
    SV* self
    long pitch
PREINIT:
    HV* hself;
    SV** tmpsv;
    HWAVEOUT wo;
    DWORD dwPitch;
    MMRESULT mmr;
CODE:
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        if(items == 1) {
            mmr = waveOutGetPitch(wo, &dwPitch);
            WaveOutCheckError(mmr);
            RETVAL = dwPitch;
        } else {
            RETVAL = waveOutSetPitch(wo, pitch);
            WaveOutCheckError(RETVAL);
        }
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

long
_PlaybackRate(self, rate=0)
    SV* self
    long rate
PREINIT:
    HV* hself;
    SV** tmpsv;
    HWAVEOUT wo;
    DWORD dwRate;
    MMRESULT mmr;
CODE:
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        if(items == 1) {
            mmr = waveOutGetPlaybackRate(wo, &dwRate);
            WaveOutCheckError(mmr);
            RETVAL = dwRate;
        } else {
            RETVAL = waveOutSetPitch(wo, rate);
            WaveOutCheckError(RETVAL);
        }
    } else {
        PerlSetError(-1, "Device is not opened");
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

void
GetErrorText(self=0, errcode)
    SV* self
    int errcode
PREINIT:
    char errmsg[MAXERRORLENGTH];
CODE:
    if(waveOutGetErrorText(
        errcode, 
        (LPSTR) errmsg, 
        MAXERRORLENGTH
    ) == MMSYSERR_NOERROR) {
        XSRETURN_PV((char *) errmsg);
    } else {
        XSRETURN_NO;
    }

void
DESTROY(self)
    SV* self
PPCODE:
    HV* hself;
    SV** tmpsv;
    HGLOBAL hg;
    HMMIO mmio;
    HWAVEOUT wo;
    LPWAVEHDR wh;
    MMRESULT mmr;
    hself = (HV*)SvRV(self);
    tmpsv = hv_fetch(hself, "handle", 6, 0);
    if(tmpsv != NULL) {
        wo = INT2PTR(HWAVEOUT, SvIV(*tmpsv));
        tmpsv = hv_fetch(hself, "wavheadlock", 11, 0);
        if(tmpsv != NULL) {
            wh = INT2PTR(LPWAVEHDR, SvIV(*tmpsv));
            if(wh->dwFlags & WHDR_PREPARED) {
                mmr = waveOutUnprepareHeader(wo, wh, sizeof(wh));
            }
            GlobalUnlock((HGLOBAL) wh);
        }
        tmpsv = hv_fetch(hself, "wavhead", 7, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalFree(hg);
        }
        tmpsv = hv_fetch(hself, "wavdatalock", 11, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalUnlock(hg);
        }
        tmpsv = hv_fetch(hself, "wavdata", 7, 0);
        if(tmpsv != NULL) {
            hg = INT2PTR(HGLOBAL, SvIV(*tmpsv));
            GlobalFree(hg);
        }        
	tmpsv = hv_fetch(hself, "mmio", 4, 0);
	if(tmpsv != NULL) {
	    mmio = INT2PTR(HMMIO, SvIV(*tmpsv));
	    mmioClose(mmio, 0);
	}
        waveOutClose(wo);
    } else {
	XSRETURN_NO;
    }
    XSRETURN_YES;
