/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/handleattributes.h 3     19-07-08 22:34 Sommar $

  Routines for getting and (in one case) deleting handle attributes from
  the Win32::SqlServer hash. Many of them are format options.

  Copyright (c) 2004-2019   Erland Sommarskog

  $History: handleattributes.h $
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 19-07-08   Time: 22:34
 * Updated in $/Perl/OlleDB
 * Move SQL_version to be in internaldata intstead. Added support for the
 * codepages hash.
 * 
 * *****************  Version 2  *****************
 * User: Sommar       Date: 11-08-07   Time: 23:25
 * Updated in $/Perl/OlleDB
 * Suppress warnings about data truncation on x64.
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


// Maps to the DatetimeOption property.
typedef enum dt_options {
   dto_hash, dto_iso, dto_regional, dto_float, dto_strfmt
} dt_options;

// Maps to the BinaryAsStr property.
typedef enum bin_options {
   bin_binary, bin_string, bin_string0x
} bin_options;

// This struct describes the TZoffset property.
typedef struct {
    BOOL    inuse;
    int     sign;
    int     hour;
    int     minute;
} tzinfo;

// Options that affect data processing, extracted to a local struct in
// some routines.
typedef struct {
    int         DecimalAsStr;
    bin_options BinaryAsStr;
    dt_options  DatetimeOption;
    tzinfo      TZOffset;
    char       *DateFormat;
    char       *MsecFormat;
} formatoptions;


// Routines to retrieve various properties.
extern BOOL OptAutoConnect (SV * olle_ptr);

extern BOOL OptPropsDebug(SV * olle_ptr);

extern IV OptRowsAtATime(SV * olle_ptr);

extern BOOL OptDecimalAsStr(SV * olle_ptr);

extern dt_options OptDatetimeOption(SV * olle_ptr);

extern tzinfo OptTZOffset(SV * olle_ptr);

extern bin_options OptBinaryAsStr(SV * olle_ptr);

extern char * OptDateFormat(SV * olle_ptr);

extern char * OptMsecFormat(SV * olle_ptr);

extern SV * OptMsgCallback(SV * olle_ptr);

extern IV OptCommandTimeout(SV * olle_ptr);

extern HV* OptQueryNotification(SV * olle_ptr);

extern formatoptions getformatoptions(SV * olle_ptr);

extern UINT OptCurrentCodepage(SV * olle_ptr);

extern void * OptInternalData(SV *olle_ptr);

extern void ClearCodepages (SV * olle_ptr);

