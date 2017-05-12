/*
 VMS::Time is copyright (C) 2013 Thomas Pfau tfpfau@gmail.com

 This module is free software.  You can redistribute it and/or modify
 it under the terms of the Artistic License 2.0.

 This module is distributed in the hope that it will be useful but it
 is provided "as is"and without any express or implied warranties.
*/

#include <string.h>
#include <starlet.h>
#include <descrip.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* return formats */
#define VMSTIME_PACK		0
#define VMSTIME_LONGINT		1
#define VMSTIME_FLOAT		2
#define VMSTIME_HEX		3
#define VMSTIME_BIGINT		4

#include "const-c.inc"

#ifdef __VAX
#include <lib$routines.h>

typedef struct {
    int i[2];
} VMSTIME;

static const int mult = 10000000,
    addend[2] = { 0x4beb4000, 0x07c9567 },
    x_len = 2,
    zero = 0;

#else
typedef union {
    long long q;
    int i[2];
} VMSTIME;
#endif

/*
 determine how to return a time value
*/
SV *return_time(VMSTIME *timbin, int retmode)
{
    SV *retsv;
    switch ( retmode )
    {
      case VMSTIME_PACK:
	retsv = newSVpv((char *)timbin,8);
	break;
      case VMSTIME_LONGINT:
#ifdef USE_64_BIT_INT
	retsv = newSViv(timbin->q);
#else
	croak("VMS::Time: 64 bit integers are not supported by this perl");
#endif
	break;
      case VMSTIME_FLOAT:
#ifdef __VAX
	croak("VMS::Time: FLOAT format not supported on VAX");
#else
	retsv = newSVnv( (double) timbin->q );
#endif
	break;
      case VMSTIME_BIGINT:
      case VMSTIME_HEX:
	{
	    char buf[32];
	    int count;
	    sprintf(buf,"0x%08x%08x",timbin->i[1],timbin->i[0]);
	    if ( retmode == VMSTIME_HEX )
		retsv = newSVpv( buf, 0 );
	    else
	    {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSVpv("Math::BigInt",0)));
		XPUSHs(sv_2mortal(newSVpv(buf,0)));
		PUTBACK;
		count = call_method("new",G_SCALAR);
		SPAGAIN;
		if ( count != 1 )
		    croak("VMS::Time: Unexpected return"
			  " from Math::BigInt::new\n");
		retsv = SvREFCNT_inc(POPs);
		PUTBACK;
		FREETMPS;
		LEAVE;
	    }
	}
	break;
      default:
	croak("VMS:Time: Unknown return format requested");
    }
    return retsv;
}

void get_time(SV *bin,VMSTIME *timbin)
{
    /* if integer value is set, use it */
    if ( SvIOK(bin) )
    {
#ifdef __VAX
	croak("VMS::Time: LONGINT format not supported on VAX");
#else
	timbin->q = SvIV(bin);
#endif
    }
    /* if float value is set, use it */
    else if ( SvNOK(bin) )
    {
#ifdef __VAX
	croak("VMS::Time: FLOAT format not supported on VAX");
#else
	timbin->q = SvNV(bin);
#endif
    }
    /* if it's a string, use it if it starts with '0x' (hex) or
       is 8 bytes long (pack) */
    else if ( SvPOK(bin) )
    {
	char buf[32];
	char *p;
	unsigned int l;
	p = SvPV(bin,l);
	if ( strncmp( p, "0x", 2 ) == 0 )
	{
	    p += 2;
	    l -= 2;
	    memset( buf, '0', 16-l );
	    strcpy( buf + 16 - l, p );
	    timbin->i[0] = strtoul( buf+8, &p, 16 );
	    buf[8] = 0;
	    timbin->i[1] = strtoul( buf, &p, 16 );
	}
	else if ( l == 8 )
	    memcpy( timbin, p, 8 );
	else
	    croak("VMS::Time: Invalid input time");
    }
    /* need to parse bigint data */
    else if ( sv_isa( bin, "Math::BigInt" ) )
    {
	char buf[32];
	char *p;
	unsigned int l=0, count;
	SV *hex;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(bin);
	PUTBACK;
	count = call_method("as_hex",G_SCALAR);
	SPAGAIN;
	if ( count != 1 )
	    croak("VMS::Time: Unexpected return from Math::BigInt::as_hex\n");
	hex = POPs;
	p = SvPV(hex,l);
	p += 2;
	l -= 2;
	memset( buf, '0', 16-l );
	strcpy( buf + 16 - l, p );
	timbin->i[0] = strtoul( buf+8, &p, 16 );
	buf[8] = 0;
	timbin->i[1] = strtoul( buf, &p, 16 );
	PUTBACK;
	FREETMPS;
	LEAVE;
    }
    else
    {
	croak("VMS::Time: unable to determine input time format");
    }
}

MODULE = VMS::Time		PACKAGE = VMS::Time		

INCLUDE: const-xs.inc

# convert an ascii time string to a vms time
SV *
bintim(SV *asc, ...)
  INIT:
    struct dsc$descriptor timdsc;
    VMSTIME timbin;
    unsigned int l = 0;
    int sts, retmode = VMSTIME_PACK;
    SV *retsv;
  PPCODE:
    if ( items > 1 )
    {
	retmode = SvIV(ST(1));
    }
    timdsc.dsc$a_pointer = SvPV(asc,l);
    timdsc.dsc$w_length = l;
    timdsc.dsc$b_dtype = DSC$K_DTYPE_T;
    timdsc.dsc$b_class = DSC$K_CLASS_S;
    sts = sys$bintim(&timdsc, &timbin);
    if ( sts & 1 )
    {
	retsv = return_time(&timbin,retmode);
	PUSHs(sv_2mortal(retsv));
    }
    else
	croak("VMS::Time: Invalid time string");

# convert a vms time (or current time) to an ascii string
SV *
asctim(...)
  INIT:
    VMSTIME timbin;
    void *timadr = NULL;
    char timasc[32];
    struct dsc$descriptor timdsc;
    unsigned short l = 0, flag = 0;
  CODE:
    if ( items > 0 )
    {
	SV *bin;
	bin = ST(0);
	get_time(bin,&timbin);
	timadr = &timbin;
    }
    if ( items > 1 )
	flag = SvTRUE(ST(1));
    timdsc.dsc$a_pointer = timasc;
    timdsc.dsc$w_length = sizeof(timasc);
    timdsc.dsc$b_dtype = DSC$K_DTYPE_T;
    timdsc.dsc$b_class = DSC$K_CLASS_S;
    sys$asctim( &l, &timdsc, timadr, flag );
    timasc[l] = 0;
    RETVAL = newSVpv( timasc, l );
  OUTPUT:
    RETVAL

# return the current time as a vms time value
SV *
gettim(...)
  INIT:
    VMSTIME timbin;
    int retmode = VMSTIME_PACK;
  PPCODE:
    if ( items > 0 )
    {
	retmode = SvIV(ST(0));
    }
    sys$gettim(&timbin);
    PUSHs(sv_2mortal(return_time(&timbin,retmode)));

# convert a vms time value (or the current time) to an array
# of values representing the components of the time (year, month,
# day, hour, minute, second, hundredth)
SV *
numtim(...)
  INIT:
    unsigned short vec[7];
    VMSTIME timbin;
    void *timadr = NULL;
    int i;
  PPCODE:
    if ( items > 0 )
    {
	SV *bin = ST(0);
	get_time(bin,&timbin);
	timadr = &timbin;
    }
    sys$numtim( vec, timadr );
    EXTEND(SP,7);
    for ( i=0; i<7; i++ )  
        PUSHs(sv_2mortal(newSViv(vec[i])));

# convert a unix epoch time to VMS time format
SV *
epoch_to_vms(int epoch,...)
  INIT:
    VMSTIME timbin;
    int retmode = 0;
  CODE:
    if ( items > 1 )
	retmode = SvIV(ST(0));
#ifdef __VAX
    lib$emul(&epoch,&mult,&zero,&timbin);
    lib$addx(addend,&timbin,&timbin,&x_len);
#else
    timbin.q = epoch * 10000000ull + 0x07c95674beb4000ull;
#endif
    RETVAL = return_time(&timbin,retmode);
  OUTPUT:
    RETVAL

# convert a vms time value to a unix epoch time
int
vms_to_epoch(SV *vmst)
  INIT:
    VMSTIME timbin;
#ifdef __VAX
    int quo,rem;
#endif
  CODE:
    get_time(vmst,&timbin);
#ifdef __VAX
    lib$subx(&timbin,&addend,&timbin,&x_len);
    lib$ediv(&mult,&timbin,&quo,&rem);
    RETVAL = quo;
#else
    RETVAL = ( timbin.q - 0x07c95674beb4000ull ) / 10000000;
#endif
  OUTPUT:
    RETVAL
