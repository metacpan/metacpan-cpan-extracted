#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <windows.h>
#include <winver.h>

MODULE = Win32::File::VersionInfo PACKAGE = Win32::File::VersionInfo

SV *
GetFileVersionInfo ( file )
char * file
	PROTOTYPE: $
	PREINIT:

	unsigned long *dw,langs,foo;
	unsigned int size;
	void *chunk, *base;
	char temp[128], temp2[16], *temp3;
	HV *h, *r, *l, *th;
	SV *ts;

	CODE:

	h = (HV *) sv_2mortal( (SV *) newHV() );
	r = newHV();
	ts = newRV_noinc ( (SV *) r );
	if ( ! hv_store ( h, "Raw", 3, ts, 0 ) ) SvREFCNT_dec ( ts );


	size = GetFileVersionInfoSize ( file, &foo );
	if ( ! size ) XSRETURN_UNDEF;
	chunk = malloc ( size );
	if ( ! chunk ) XSRETURN_UNDEF;
	if ( ! GetFileVersionInfo ( file, foo, size, chunk ) ) { free ( chunk ); XSRETURN_UNDEF; }
	if ( ! VerQueryValue ( chunk, "\\", &base, &size ) ) { free ( chunk ); XSRETURN_UNDEF; }
	dw = (unsigned long *)base;

	/* File Version */
	sprintf ( temp, "%u.%u.%u.%u", (dw[2]>>16), (dw[2]&0xffff), (dw[3]>> 16), (dw[3]&0xffff) );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( h, "FileVersion", 11, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X%08X", dw[2], dw[3] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "FileVersion", 11, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* Product Version */
	sprintf ( temp, "%u.%u.%u.%u", (dw[4]>>16), (dw[4]&0xffff), (dw[5]>> 16), (dw[5]&0xffff) );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( h, "ProductVersion", 14, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X%08X", dw[4], dw[5] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "ProductVersion", 14, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* Flags */
	th = newHV();
	/* Brace thyselves */
	if ( ( dw[6] & VS_FF_DEBUG ) &&
		( !hv_store(th, "Debug", 5, ts = newSVuv( dw[7] & VS_FF_DEBUG ), 0) ) ) SvREFCNT_dec (ts);
	if ( ( dw[6] & VS_FF_PRERELEASE ) &&
		( !hv_store(th, "Prerelease", 10, ts = newSVuv( dw[7] & VS_FF_PRERELEASE ), 0) ) ) SvREFCNT_dec(ts);
	if ( ( dw[6] & VS_FF_PATCHED ) &&
		( !hv_store(th, "Patched", 7, ts = newSVuv( dw[7] & VS_FF_PATCHED ), 0) ) ) SvREFCNT_dec(ts);
	if ( ( dw[6] & VS_FF_PRIVATEBUILD ) &&
		( !hv_store(th, "PrivateBuild", 12, ts = newSVuv( dw[7] & VS_FF_PRIVATEBUILD ), 0) ) ) SvREFCNT_dec(ts);
	if ( ( dw[6] & VS_FF_INFOINFERRED ) &&
		( !hv_store(th, "InfoInferred", 12, ts = newSVuv( dw[7] & VS_FF_INFOINFERRED ), 0) ) ) SvREFCNT_dec(ts);
	if ( ( dw[6] & VS_FF_SPECIALBUILD ) &&
		( !hv_store(th, "SpecialBuild", 12, ts = newSVuv( dw[7] & VS_FF_SPECIALBUILD ), 0) ) ) SvREFCNT_dec(ts);
	ts = newRV_noinc ( (SV *) th );
	if ( ! hv_store ( h, "Flags", 5, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X", dw[6] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "FlagMask", 8, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X", dw[7] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "Flags", 5, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* OS */
	switch ( dw[8] & 0xffff0000 ) {
		case VOS_DOS: strcpy ( temp2, "DOS" ); break;
		case VOS_OS216: strcpy ( temp2, "OS/2 16" ); break;
		case VOS_OS232: strcpy ( temp2, "OS/2 32" ); break;
		case VOS_NT: strcpy ( temp2, "NT" ); break;
#ifdef VOS_WINCE /* not in all versions of winver.h */
		case VOS_WINCE: strcpy ( temp2, "WINCE" ); break;
#endif
		default:
		case VOS_UNKNOWN: strcpy ( temp2, "Unknown" ); break;
	}
	switch ( dw[8] & 0xffff ) {
		case VOS__WINDOWS16: sprintf ( temp, "%s/Win16", temp2 ); break;
		case VOS__PM16: sprintf ( temp, "%s/PM16", temp2 ); break;
		case VOS__PM32: sprintf ( temp, "%s/PM32", temp2 ); break;
		case VOS__WINDOWS32: sprintf ( temp, "%s/Win32", temp2 ); break;
		default:
		case VOS__BASE: sprintf ( temp, "%s/Unknown", temp2 ); break;
	}
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( h, "OS", 2, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X", dw[8] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "OS", 2, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* Type */
	switch ( dw[9] ) {
		case VFT_APP: strcpy ( temp, "Application" ); break;
		case VFT_DLL: strcpy ( temp, "DLL" ); break;
		case VFT_DRV: switch ( dw[10] ) {
			case VFT2_DRV_PRINTER: strcpy ( temp, "Printer Driver" ); break;
			case VFT2_DRV_KEYBOARD: strcpy ( temp, "Keyboard Driver" ); break;
			case VFT2_DRV_LANGUAGE: strcpy ( temp, "Language Driver" ); break;
			case VFT2_DRV_DISPLAY: strcpy ( temp, "Display Driver" ); break;
			case VFT2_DRV_MOUSE: strcpy ( temp, "Mouse Driver" ); break;
			case VFT2_DRV_NETWORK: strcpy ( temp, "Network Driver" ); break;
			case VFT2_DRV_SYSTEM: strcpy ( temp, "System Driver" ); break;
			case VFT2_DRV_INSTALLABLE: strcpy ( temp, "Installable Driver" ); break;
			case VFT2_DRV_SOUND: strcpy ( temp, "Sound Driver" ); break;
			case VFT2_DRV_COMM: strcpy ( temp, "Communications Driver" ); break;
			case VFT2_DRV_INPUTMETHOD: strcpy ( temp, "Input Method Driver" ); break;
#ifdef VFT2_DRV_VERSIONED_PRINTER /* not in all versions of winver.h */
			case VFT2_DRV_VERSIONED_PRINTER: strcpy ( temp, "Versioned Printer Driver" ); break;
#endif
			default:
			case VFT2_UNKNOWN: strcpy ( temp, "Unknown Driver" ); break;
		} break;
		case VFT_FONT: switch ( dw[10] ) {
			case VFT2_FONT_RASTER: strcpy ( temp, "Raster Font" ); break;
			case VFT2_FONT_VECTOR: strcpy ( temp, "Vector Font" ); break;
			case VFT2_FONT_TRUETYPE: strcpy ( temp, "TrueType Font" ); break;
			default:
			case VFT2_UNKNOWN: strcpy ( temp, "Unknown Font" ); break;
		} break;
		case VFT_VXD: strcpy ( temp, "Virtual Device Driver" ); break;
		case VFT_STATIC_LIB: strcpy ( temp, "Static Library" ); break;
		default:
		case VFT_UNKNOWN: strcpy ( temp, "Unknown" ); break;
	}
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( h, "Type", 4, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X", dw[9] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "Type", 4, ts, 0 ) ) SvREFCNT_dec ( ts );
	sprintf ( temp, "%08X", dw[10] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "SubType", 7, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* Date */
	sprintf ( temp, "%08X%08X", dw[11], dw[12] );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( h, "Date", 4, ts, 0 ) ) SvREFCNT_dec ( ts );
	ts = newSVpv ( temp, 0 );
	if ( ! hv_store ( r, "Date", 4, ts, 0 ) ) SvREFCNT_dec ( ts );

	/* Variable Part */
	if ( VerQueryValue ( chunk, "\\VarFileInfo\\Translation", &base, &size ) ) {
		dw = (unsigned long *)base;
		langs = size / sizeof ( DWORD );
	} else {
		langs = 0;
	}

	if ( langs ) {
		l = newHV();
		ts = newRV_noinc ( (SV *) l );
		if ( ! hv_store ( h, "Lang", 4, ts, 0 ) ) SvREFCNT_dec ( ts );
	}
	/* iterate over langage codings */
	for ( foo = 0; foo < langs; foo++ ) { 
		th = newHV();

		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\Comments", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "Comments", 8, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\CompanyName", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "CompanyName", 11, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\FileDescription", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "FileDescription", 15, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\FileVersion", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "FileVersion", 11, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\InternalName", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "InternalName", 12, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\LegalCopyright", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "LegalCopyright", 14, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\LegalTrademarks", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "LegalTrademarks", 15, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\OriginalFilename", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "OriginalFilename", 16, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\ProductName", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "ProductName", 11, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\ProductVersion", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "ProductVersion", 14, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\PrivateBuild", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "PrivateBuild", 12, ts, 0 ) ) SvREFCNT_dec ( ts );
		}
		sprintf ( temp, "\\StringFileInfo\\%04x%04x\\SpecialBuild", dw[foo] & 0xffff, dw[foo] >> 16 );
		if ( VerQueryValue ( chunk, temp, &base, &size ) && size && ( temp3 = malloc ( size + 1 ) ) ) {
			sprintf ( temp3, "%.*s", size, base );
			ts = newSVpv ( temp3, 0 );
			free ( temp3 );
			if ( ! hv_store ( th, "SpecialBuild", 12, ts, 0 ) ) SvREFCNT_dec ( ts );
		}

		VerLanguageName ( dw[foo], temp, 127 );
		ts = newRV_noinc ( (SV *) th );
		if ( ! hv_store ( l, temp, strlen ( temp ), ts, 0 ) ) SvREFCNT_dec ( ts );		
	}
	free ( chunk );

	RETVAL = newRV_inc ( (SV *) h );

	OUTPUT:
	RETVAL
