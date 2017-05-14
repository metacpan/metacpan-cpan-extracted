#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ao/ao.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "AO_ALSA"))
#ifdef AO_ALSA
	    return AO_ALSA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_BEOS"))
#ifdef AO_BEOS
	    return AO_BEOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_DRIVERS"))
#ifdef AO_DRIVERS
	    return AO_DRIVERS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_ESD"))
#ifdef AO_ESD
	    return AO_ESD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_IRIX"))
#ifdef AO_IRIX
	    return AO_IRIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_NULL"))
#ifdef AO_NULL
	    return AO_NULL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_OSS"))
#ifdef AO_OSS
	    return AO_OSS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_RAW"))
#ifdef AO_RAW
	    return AO_RAW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_SOLARIS"))
#ifdef AO_SOLARIS
	    return AO_SOLARIS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_WAV"))
#ifdef AO_WAV
	    return AO_WAV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "AO_WIN32"))
#ifdef AO_WIN32
	    return AO_WIN32;
#else
	    goto not_there;
#endif
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


MODULE = Ao		PACKAGE = Ao		PREFIX = ao_

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

int
ao_get_driver_id (short_name)
        const char* short_name
        CODE:
        if ((strcmp(short_name,"NULL") == 0) ||
            (strcmp(short_name,"") == 0)) {
                RETVAL = ao_get_driver_id(NULL);
        } else {
                RETVAL = ao_get_driver_id(short_name);
        }
        OUTPUT:
        RETVAL

ao_info_t *
ao_get_driver_info (driver_id)
        int driver_id
        INIT:
        ao_info_t *info;
        CODE:
        RETVAL = newHV();
        info = ao_get_driver_info(driver_id);
        hv_store(RETVAL, "name", 4, newSVpv(info->name,0), 0);
        hv_store(RETVAL, "short_name", 10, newSVpv(info->short_name,0), 0);
        hv_store(RETVAL, "author", 6, newSVpv(info->author,0), 0);
        hv_store(RETVAL, "comment", 7, newSVpv(info->comment,0), 0);
        OUTPUT:
        RETVAL


ao_device_t *
ao_open (driver_id, bits=16, rate=44100, channels=2, options=NULL)
        int driver_id
        uint_32 bits
        uint_32 rate
        uint_32 channels
        SV *options

        PREINIT:
        ao_option_t* ao_options = NULL;
        char *key;
        int len;
        SV *val, *opt;
        HV *opt_hash;

        PPCODE:
        if (options) {
           opt_hash = (HV*) SvRV(options);
        } else {
           opt_hash = sv_2mortal(newHV());
        }
        hv_iterinit(opt_hash);
        while (val = hv_iternextsv(opt_hash, &key, &len)) {
           /* opt = key:val; */
           opt = newSVpv(key, len);
           sv_catpvf(opt, ":%s", SvPV(val, PL_na));
           ao_append_option(&ao_options, SvPV(opt, PL_na));
        }
	RETVAL = ao_open(driver_id, bits, rate, channels, ao_options);
        ao_free_options(ao_options);
	ST(0) = sv_newmortal();
        sv_setref_pv((SV*)ST(0), "Ao", RETVAL);
        XSRETURN(1);

void
ao_play (device, output_samples, num_bytes)
        ao_device_t* device
        SV* output_samples
        uint_32 num_bytes
        CODE:
        /* If buffer is a string, play the string */
        if (SvPOKp(output_samples)) {
                ao_play(device, (char*)SvPV(output_samples, PL_na), num_bytes);
        } else {
        /* otherwise buffer is a reference, play it */
                ao_play(device, (void*)SvRV(output_samples), num_bytes);
        }

void
ao_close (device)
        ao_device_t* device

int
ao_is_big_endian()

