/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/handleattributes.h 2     11-08-07 23:25 Sommar $

  Routines for getting and (in one case) deleting handle attributes from
  the Win32::SqlServer hash. Many of them are format options.

  Copyright (c) 2004-2011   Erland Sommarskog

  $History: handleattributes.h $
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


// The SQL_version property.
extern double OptSqlVersion(SV * olle_ptr);

// Drop this property, to force re-reading from SQL Server later.
extern void drop_SQLversion(SV * olle_ptr);

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

extern void * OptInternalData(SV *olle_ptr);
