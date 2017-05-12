#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <string.h>
#include <wchar.h>
#include <Windows.h>//#include <Winbase.h>

typedef WCHAR * WFile;
typedef WIN32_FIND_DATAW pWFD; 
typedef FILETIME pWFT; 
typedef DWORD (*GetLongPathName_t)(
	   WCHAR* ,
	   WCHAR* ,
	   DWORD 
	);


void nil(){
    NULL;
}
bool
mywcsncpy_s( WCHAR *strDest, STRLEN buffer, const WCHAR *strSource, STRLEN count ){
    STRLEN i;
    STRLEN k;
    if ( buffer <= count){
	strDest[0] = 0;
	return 0;	
    };

    for( ; count && (*strDest++ = *strSource++); --count);
    *strDest = 0;    
    return 1;
}
void convert_towchar( WCHAR * buf,  U8 *utf8,  STRLEN chars){
    UV value;
    STRLEN offset;

    do {
	if ( *utf8 < 128 ){
	    *buf++ = *utf8++;
	    chars--;
	}
	else {
	    value = utf8_to_uvchr( utf8, &offset );
	    *buf++= (WCHAR)value;
	    utf8+=offset;
	    chars--;
	}
    } while( chars > 0 && value !=0 );
    *buf = 0;
    
};
void convert_towchar_01( WCHAR * buf,  U8 *utf8,  STRLEN chars){
    UV value;
    STRLEN offset;
    

    do {
        value = utf8_to_uvchr( utf8, &offset );
	*buf++= (WCHAR)value;
	utf8+=offset;
	chars--;
	
    } while( chars > 0 && value !=0 );
    *buf = 0;
    
};
bool convert_toutf8_00 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    do {
	U8 *old = utf8;
	utf8 = uvchr_to_utf8( utf8, *wstr );
	if (!*wstr ){
	    return 1;
	}
	bufsize-= utf8-old;
	++wstr;
	if (bufsize < UTF8_MAXBYTES + 1 )
	    return 0;
    }
    while( 1 );
};

bool convert_toutf8_02 ( U8 *, STRLEN, WCHAR *);
SV * mortal_utf8( WCHAR * X, int chars ){
    SV *sv;
    U8 *utf;
    STRLEN utf_len;
    STRLEN buffer;
    sv = sv_newmortal();
    sv_setpvn( sv, "", 0);

    SvGROW( sv, buffer = chars * (sizeof(WCHAR)) + 2);

    do {
	utf = (U8*) SvPVX( sv );
	utf_len = SvLEN( sv );
	if (convert_toutf8_02( utf, utf_len, X ) ){
	    SvCUR_set( sv, strlen( utf ));
	    return sv ;
	};
	buffer = utf_len + chars;
	SvGROW( sv , buffer );

    } while (1 );

}

bool convert_toutf8_01 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    do {
	U8 *old = utf8;
	WCHAR wchr = *wstr;
	STRLEN offset;
	if ( wchr < 128 ){
	    *utf8++ = (U8) wchr;
	    bufsize--;
	    offset = 1;
	}
	else if ( wchr <0x800 ){
	    *utf8++ = (U8 ) ( (wchr >> 6) + 0xC0 );
	    *utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
	    offset = 2;
	    bufsize-=2;
	}
	else {
	    croak( "Can't handle big Unicode Chars" );	    
	};

	if (!*wstr ){
	    return 1;
	}
	++wstr;
	if (bufsize < UTF8_MAXBYTES + 1 )
	    return 0;
    }
    while( 1 );
};

bool convert_toutf8_02 ( U8 *utf8, STRLEN bufsize, WCHAR * wstr ){
    do {
	U8 *old = utf8;
	WCHAR wchr = *wstr;
	STRLEN offset;
	if ( wchr < 128 ){
	    *utf8++ = (U8) wchr;
	    bufsize--;
	    offset = 1;
	}
	else if ( wchr <0x800 ){
	    *utf8++ = (U8 ) ( (wchr >> 6) + 0xC0 );
	    *utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
	    offset = 2;
	    bufsize-=2;
	}
	else {
	    if ( wchr < 0xD800 || wchr > 0xDFFF ){ 
		*utf8++ = (U8 ) ( (wchr >> 12) + 0xE0 );
		*utf8++ = (U8 ) ( ( (wchr >> 6) & 63) + 0x80 );
		*utf8++ = (U8 ) ( (wchr & 63) + 0x80 );
		offset = 3;
		bufsize-=3;
	    }
	    else {
		croak( "No support for unicode surrogates" );
	    }
	}

	if (!*wstr ){
	    return 1;
	}
	++wstr;
	if (bufsize < 3 )
	    return 0;
    }
    while( 1 );
};

SV *mortal_wchar(SV *utf8){

    SV *WCHAR_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wbuff;
    // Get pointer && data length
    str_u8 = SvPV( utf8, bytes );
    chars = utf8_length( str_u8, str_u8 + bytes );
    WCHAR_SV = newSVpvn( "", 0);
    sv_2mortal( WCHAR_SV );
    if (chars >= MAX_PATH ){
	 SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 + 4));
    }
    else {
	SvGROW(  WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1 ));
    }
    // It's no right ??? this is no support for surrogate so + zero byte at the end
    SvCUR_set( WCHAR_SV,  sizeof( WCHAR ) * ( chars  + 1));
    wbuff = ( WCHAR *) SvPVX( WCHAR_SV );
    convert_towchar_01( wbuff , str_u8, chars);
    return WCHAR_SV;
}

SV *normalize_path(SV *wpath ){
    STRLEN chars;
    STRLEN bytes;
    WCHAR *buffer;
    buffer = ( WCHAR * )SvPV( wpath, bytes );
    chars = (bytes >> 1) -1 ;
    if ( ( bytes & 1 ) || (buffer[ chars ])){
	PerlIO_stdoutf( "Not valid file come" );	
	chars = wcslen( buffer );
    };
    if (chars < MAX_PATH ){
	return wpath;
    }
    else {
	STRLEN k;
	if ( buffer[0] == '\\' && buffer[1] == '\\' && buffer[2] == '?' && buffer[3] == '\\' ){
	    return wpath;
	};
	// We need replace all '/' and make prefix \\?\
	//
	
	if (SvLEN(wpath) < (chars + 5) * sizeof(WCHAR) )
	    SvGROW( wpath, (chars + 5) * sizeof(WCHAR) );
	Move(  buffer, buffer +4 , chars +1, WCHAR);
	buffer[0] = '\\';
	buffer[1] = '\\';
	buffer[2] = '?';
	buffer[3] = '\\';
	for (k = 0; k < chars; ++k ){
	   if ( buffer[ k + 4 ] == '/' )
	       buffer[ k + 4 ] = '\\';

	};
	SvCUR_set(wpath, sizeof(WCHAR) * (chars + 5));
	return wpath;
    };
}

SV * WBool(bool obj){
    return obj ? &PL_sv_yes : &PL_sv_no ;
}





SV *
wfd_FileSize(pWFD *ptr){
    SV *sv;
    sv= newSV(0);
    if ( sizeof( UV ) > sizeof(DWORD)){
	sv_setuv( sv, (((UV)ptr->nFileSizeHigh) << 32 ) + ptr->nFileSizeLow);
    }
    else 
    {
	if ( ptr->nFileSizeHigh == 0 ){
	    sv_setuv( sv, ptr->nFileSizeLow );
	}
	else {
	    sv_setnv( sv, ptr->nFileSizeHigh * (  0x10000 * ((double) 0x10000 ) ));
	};
    }
    return sv;
}
double
wft_as_time( pWFT * ptr ){
    double x2;
    //SYSTEMTIME s;
    //   LONGLONG ll = 116444736000000000;
   //    ptr->dwLowDateTime = (DWORD) ll;
   //    ptr->dwHighDateTime = (DWORD) (ll >> 32);

   //   FileTimeToSystemTime( ptr, &s );
    x2 = ptr->dwHighDateTime * ( 4294967296.0) + ptr->dwLowDateTime; 
    x2 -=116444736000000000.0;
    x2 /= 10000000.0;
    // printf( "%d %d %d %d %d %d = %lf\n", s.wYear, s.wMonth, s.wDay, s.wHour, s.wMinute, s.wSecond, x2);
    return x2;
};

SV *
wft_from_wft( pWFT *ptr ){
    SV * sv;
    pWFT *nptr;
    sv = sv_newmortal();
    Newx( nptr, 1, pWFT);
    Copy( ptr, nptr, 1, pWFT);
    sv_setref_pv( sv, "Win32::FindFile::_WFT", (void *) nptr);
    return sv;
}
SV *
wft_from_time( double s ){
    FILETIME date;
    double s1 = ( s *10000000 +0.5  + 116444736000000000.0 )/ 4294967296.0 ;
    double int1;
    date.dwLowDateTime = (DWORD)(int)( 0.5 + 4294967296.0 * modf(  s1, &int1));
    date.dwHighDateTime= (DWORD)(int)( int1  + .5);
    return wft_from_wft( &date);
}



double wft_as_double( SV *arg ){
    double s=0;
    if (sv_isobject(arg) && SvTYPE( SvRV(arg)) == SVt_PVMG ) {
	if (! strcmp(HvNAME(SvSTASH(SvRV(arg))), "Win32::FindFile::_WFT")){
	    s = wft_as_time( INT2PTR(pWFT *, SvIV((SV*)SvRV( arg ))));
	}
	else {
	    s = SvNV(arg);
	}
    } 
    else {
	s=SvNV(arg);
    };
    return s;
}

int 
wft_cmp( SV * s1, SV *s2 ){
    double x1 = wft_as_double( s1);
    double x2 = wft_as_double( s2);
    if ( x1 < x2 )
	return -1;
    if ( x1 > x2 )
	return 1;
    return 0;
}

bool 
wfd_is_entry(pWFD *ptr){
    if ( ptr->cFileName[0] != '.' )
	return TRUE;
    if ( ptr->cFileName[1] == 0 )
	return FALSE; 
    if ( ptr->cFileName[1] != '.' )
	return TRUE;
    if ( ptr->cFileName[2] != 0   )
	return TRUE;
    return FALSE;
}

bool
wfd_is_empty(pWFD *ptr){
    return ! ( ptr->nFileSizeLow || ptr->nFileSizeHigh);
}
bool
wfd_is_ro(pWFD *ptr){
    return ! ( ptr->dwFileAttributes & ( FILE_ATTRIBUTE_READONLY || FILE_ATTRIBUTE_SYSTEM ));
}

bool
wfd_is_archive(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_ARCHIVE && 1;
}
    
bool
wfd_is_compressed(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_COMPRESSED && 1;
}
    
bool
wfd_is_device(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_DEVICE && 1;
}

bool
wfd_is_directory(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY && 1;
}

bool
wfd_is_file(pWFD *ptr){
    return !(ptr->dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY);
}

bool
wfd_is_dir(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY && 1;
}
    
bool
wfd_is_encrypted(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_ENCRYPTED && 1;
}
    
bool
wfd_is_hidden(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_HIDDEN && 1;
}

bool
wfd_is_normal(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_NORMAL && 1;
}
    
bool
wfd_is_not_indexed(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_NORMAL && 1;
}
    
bool
wfd_is_not_content_indexed(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_NOT_CONTENT_INDEXED && 1;
}
    
bool
wfd_is_offline(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_OFFLINE && 1;
}
    
bool
wfd_is_readonly(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_READONLY && 1;
}

bool
wfd_is_reparse_point(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT && 1;
}

bool
wfd_is_sparse(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_SPARSE_FILE && 1;
}

bool
wfd_is_system(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_SYSTEM && 1;
}

bool
wfd_is_temporary(pWFD *ptr){
    return ptr->dwFileAttributes & FILE_ATTRIBUTE_TEMPORARY && 1;
}

UV wfd_dwFileSizeLow(pWFD *ptr){
    return ptr->nFileSizeLow;
}
UV wfd_dwFileSizeHigh(pWFD *ptr){
    return ptr->nFileSizeHigh;
}
UV wfd_dwFileAttributes(pWFD *ptr){
    return ptr->dwFileAttributes;
}
UV wfd_dwReserved0(pWFD *ptr){
    return ptr->dwReserved0;
}
UV wfd_dwReserved1(pWFD *ptr){
    return ptr->dwReserved1;
}


SV *wfd_new(WIN32_FIND_DATAW *str){
    SV *RET;
    WIN32_FIND_DATAW *ptr;
    Newx( ptr, 1, WIN32_FIND_DATAW);
    Copy( str, ptr, 1, WIN32_FIND_DATAW );
    RET = sv_newmortal();
    sv_setref_pv( RET,  "Win32::FindFile::_WFD",(void *) ptr );
    return RET;
}


MODULE=  Win32::FindFile		  PACKAGE = Win32::FindFile		

void 
uchar2( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    SV *UTF8_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wstr_ptr;
    STRLEN bufsize;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    UTF8_SV = newSVpvn( "", 0);
    sv_2mortal( UTF8_SV );

    bufsize = chars * 2 + UTF8_MAXBYTES  + 1;
    do {
	SvGROW( UTF8_SV, bufsize );
	str_u8 = ( U8 *) SvPVX( UTF8_SV );
	if ( convert_toutf8_01( str_u8, SvLEN(UTF8_SV), wstr_ptr) )
    	    break;
	
	bufsize += chars *2;
    }
    while( 1) ;

    SvCUR_set( UTF8_SV,  strlen( str_u8 ));
    XPUSHs( UTF8_SV );

void 
uchar( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    STRLEN chars;
    STRLEN bytes;
    WCHAR *wstr_ptr;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    XPUSHs(mortal_utf8( wstr_ptr, chars ));

void
fromWCHAR( SV * wstr_sv )
    PROTOTYPE: $;
    INIT:
    SV *UTF8_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wstr_ptr;
    STRLEN bufsize;
    PPCODE:
    wstr_ptr = ( WCHAR *) SvPV( wstr_sv, bytes );
    chars = wcslen( wstr_ptr );
    UTF8_SV = newSVpvn( "", 0);
    sv_2mortal( UTF8_SV );

    bufsize = chars * 2 + UTF8_MAXBYTES  + 1;
    do {
	SvGROW( UTF8_SV, bufsize );
	str_u8 = ( U8 *) SvPVX( UTF8_SV );
	if ( convert_toutf8_02( str_u8, SvLEN(UTF8_SV), wstr_ptr) )
    	    break;
	
	bufsize += chars *2;
    }
    while( 1) ;

    SvCUR_set( UTF8_SV,  strlen( str_u8 ));
    XPUSHs( UTF8_SV );


void
wchar( SV * str )
    PPCODE:
    XPUSHs( mortal_wchar( str) );

void
toWCHAR( SV * str )
    PROTOTYPE: $;
    INIT:
    SV *WCHAR_SV;
    STRLEN chars;
    STRLEN bytes;
    U8 *str_u8;
    WCHAR *wbuff;
    PPCODE:
    str_u8 = SvPV( str, bytes );
    chars = utf8_length( str_u8, str_u8 + bytes );
    WCHAR_SV = newSVpvn( "", 0);
    sv_2mortal( WCHAR_SV );
    SvGROW( WCHAR_SV, sizeof( WCHAR ) * ( chars  + 1));
    SvCUR_set( WCHAR_SV,  sizeof( WCHAR ) * ( chars  + 1));
    wbuff = ( WCHAR *) SvPVX( WCHAR_SV );
    convert_towchar_01( wbuff , str_u8, chars);
    XPUSHs( WCHAR_SV );




void 
wfchar( SV * str)
    PPCODE:
    XPUSHs( normalize_path( mortal_wchar( str )));


# /* File functions */

void 
FindFile(WFile dir)
    PROTOTYPE: $
    INIT:
    WIN32_FIND_DATAW data;
    HANDLE hFile;
    PPCODE:
	
	hFile = FindFirstFileW( dir, &data);
	if ( hFile == INVALID_HANDLE_VALUE ){
	    NULL;	        
	}
	else {
	    XPUSHs( wfd_new( &data ));
	    while( FindNextFileW( hFile, &data) ){
		XPUSHs( wfd_new( &data ));
	    };
	    FindClose( hFile );
	}
	

void 
AreFileApisANSI()
    PPCODE:
	XPUSHs( WBool( AreFileApisANSI() ));

void
SetFileApisToOEM()
    PPCODE:
    SetFileApisToOEM();

void
SetFileApisToANSI()
    PPCODE:
    SetFileApisToANSI();


void 
DeleteFile(WFile file)
    PPCODE:
	XPUSHs( WBool(DeleteFileW( file )));


void 
GetBinaryType(WFile file)
    PREINIT:
    DWORD BinaryType;
    PPCODE:
    if ( GetBinaryTypeW( file, & BinaryType ) ){
	mXPUSHi( BinaryType );	
    }
    else {
	XPUSHs( &PL_sv_undef );
    }

void 
GetCompressedFileSize(WFile file)
    PREINIT:
    DWORD FileSize1;
    //DWORD FileSize2;
    PPCODE:
    if ( ( FileSize1 = GetCompressedFileSizeW( file, NULL )) != INVALID_FILE_SIZE ){
        mXPUSHi( FileSize1 );
    }
    else {
        XPUSHs( &PL_sv_undef );
    }

void
GetFileAttributes( WFile file)
    PREINIT:reFileApisANSI
    DWORD FileAttributes;
    PPCODE:
    if ( ( FileAttributes = GetFileAttributesW( file )) != INVALID_FILE_ATTRIBUTES ){
	mXPUSHi( FileAttributes );
    }
    else {
	XPUSHs( &PL_sv_undef );
    }

void 
RemoveDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( RemoveDirectoryW( file )));

void 
CreateDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( CreateDirectoryW( file, NULL )));

void 
SetCurrentDirectory( WFile file )
    PPCODE:
    XPUSHs(WBool( SetCurrentDirectoryW( file )));

void
SetFileAttributes( WFile file, int FileAttributes)
    PPCODE:
    XPUSHs( WBool( SetFileAttributesW( file, FileAttributes )));

void MoveFile( WFile file1, WFile file2 )
    PPCODE:
    mXPUSHs( WBool( MoveFileW( file1, file2 )));


void CopyFile( WFile file1, WFile file2, int FailIfExists )
    PPCODE:
    mXPUSHs( WBool( CopyFileW( file1, file2, FailIfExists )));



void GetCurrentDirectory( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    PPCODE:
	length = GetCurrentDirectoryW( 0 , NULL);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = GetCurrentDirectoryW( SvLEN(buffer)/2, (WCHAR *)SvPV_nolen( buffer ));	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}

void
GetFullPathName( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    PPCODE:
	length = GetFullPathNameW( file, 0 , NULL, NULL);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = GetFullPathNameW( file, SvLEN(buffer)/2, (WCHAR *)SvPV_nolen( buffer ), NULL);	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}


void GetLongPathName( WFile file )
    PREINIT:
    long length;
    SV *buffer;
    HMODULE Kernel;
    GetLongPathName_t Func;
    PPCODE:
	Kernel= LoadLibrary( "Kernel32.dll" );
	if ( Kernel == NULL )
	    croak( "Unable load Kernel32.dll" );
	Func = ( GetLongPathName_t )GetProcAddress( Kernel, "GetLongPathNameW" );
	if ( Func == NULL ){
	    FreeLibrary( Kernel );
	    croak( "Unable get function GetLongPathNameW" );
	};

	length = Func( file, NULL, 0);
	if ( length != 0){
	    buffer= sv_newmortal();
	    sv_setpvn( buffer, "", 0);
	    SvGROW( buffer, (sizeof( WCHAR) * length ));
	    
	    length = Func( file, (WCHAR *)SvPV_nolen( buffer ), SvLEN(buffer)/2);	    
	    if ( length != 0){
		XPUSHs( mortal_utf8( (WCHAR *)SvPVX(buffer), length ));
	    }
	    else {
		XPUSHs( &PL_sv_undef );
	    };
	} else {
	    XPUSHs( &PL_sv_undef );
	}
	FreeLibrary( Kernel );


PROTOTYPES: DISABLE;

void
Output( SV *sv )
    INIT:
    STRLEN size;
    U8    *ptr;
    PPCODE:	
	ptr = SvPV( sv, size );
	PerlIO_stdoutf( "%.*s", size, ptr);


MODULE = Win32::FindFile                PACKAGE = Win32::FindFile::_WFT PREFIX = wft_

void DESTROY(pWFT *s)
    PPCODE:
    Safefree(s);

void
nil()
    OVERLOAD: )
    PPCODE:

double
wft_as_double(SV * time)



double wft_as_time(pWFT *s, ... )
    OVERLOAD: 0+
    ALIAS:
	as_utc=1

int 
wft_cmp(SV *s1, SV*s2, ... ) 
    OVERLOAD: cmp <=> 

UV
wft_highWord(pWFT *s1)
    CODE:
    RETVAL = s1->dwHighDateTime;
    OUTPUT:
    RETVAL

UV
wft_lowWord(pWFT *s1)
    CODE:
    RETVAL = s1->dwLowDateTime;
    OUTPUT:
    RETVAL

	
void 
new( SV *, double x)
    PPCODE:
    XPUSHs(wft_from_time( x ));

void 
bytestr(pWFT *s)
    ALIAS:
	bytestring   = 1
	as_bytearray = 2
    PPCODE:
    mXPUSHp((U8 *)s, sizeof(*s)*2);



MODULE = Win32::FindFile                PACKAGE = Win32::FindFile::_WFD PREFIX = wfd_


void 
DESTROY(pWFD *s)
    PPCODE:
    Safefree(s);

pWFD * 
_new(SV*, SV *X)
PREINIT:
STRLEN x_len;
WCHAR *x_ptr;    
CODE:
    x_ptr = (WCHAR *) SvPV( X, x_len );
    x_len /=2;
    if (x_len >= MAX_PATH )
	croak("Too big filename");

    Newxz( RETVAL, 1, pWFD );
    mywcsncpy_s( RETVAL->cFileName, MAX_PATH, x_ptr, x_len);
OUTPUT:
    RETVAL
    

void
cFileName(pWFD *ptr, ...)
    OVERLOAD: \"\"
    ALIAS:
     FileName = 1
     fileName = 2
     name     = 3
    PREINIT:
    STRLEN chars;
    PPCODE:
    chars = wcslen( ptr->cFileName );
    XPUSHs(mortal_utf8( ptr->cFileName, chars ));

void
relName(pWFD *ptr, SV *directory = 0,  SV *delim = 0 )
    ALIAS:
	rel_name=1
    PREINIT:
    STRLEN chars;
    SV *prefix;
    SV *itemname;
    STRLEN prefix_len;
    char* prefix_str;
    int nopref;
    PPCODE:
    if (directory){
	prefix = sv_mortalcopy( directory );
    }
    else {
	prefix = newSVpvn("",0);
	sv_2mortal(prefix);
    };
    prefix_str = SvPV( prefix, prefix_len );
    
    if ( prefix_len !=0 ){
        nopref = 0;
	while(  prefix_str[prefix_len-1] == '/' || prefix_str[prefix_len -1] == '\\' ){
	    --prefix_len;
	    if ( !prefix_len ){
                nopref = 1;
	        prefix_len = 1;
		break;
	    }
	    else if ( prefix_str[prefix_len-1] == ':' ) {
                nopref = 1;
		prefix_len++;
		break;
	    }
	    if ( !prefix_len ){
		break;	
	    }
	}

	prefix_str[prefix_len] = 0;
	SvCUR_set(prefix,prefix_len);
        if ( ! nopref ){
	    if (delim)
		sv_catsv( prefix, delim );    
	    else {
		sv_catpvn( prefix, "/", 1 );    
	    }
	}
    }
    chars = wcslen( ptr->cFileName );
    itemname = mortal_utf8( ptr->cFileName, chars );
    sv_catsv( prefix, itemname );
    XPUSHs( prefix );


void dosName(pWFD *ptr)
    ALIAS:
        cAlternateFileName=1
    PPCODE:
    if (ptr->cAlternateFileName[0])
	XPUSHs(mortal_utf8( ptr->cAlternateFileName, wcslen(ptr->cAlternateFileName)));
    else
	XPUSHs(mortal_utf8( ptr->cFileName, wcslen(ptr->cFileName)));


UV 
interface_dw_p(pWFD *ptr)
    INTERFACE:
    wfd_dwFileSizeLow
    wfd_dwFileSizeHigh
    wfd_dwFileAttributes
    wfd_dwReserved0
    wfd_dwReserved1


bool interface_b_p(pWFD *ptr)
    INTERFACE:
    wfd_is_temporary
    wfd_is_entry
    wfd_is_ro
    wfd_is_empty
    wfd_is_archive
    wfd_is_compressed
    wfd_is_device
    wfd_is_directory
    wfd_is_dir
    wfd_is_file
    wfd_is_encrypted
    wfd_is_hidden
    wfd_is_normal
    wfd_is_not_indexed
    wfd_is_not_content_indexed
    wfd_is_offline
    wfd_is_readonly
    wfd_is_reparse_point
    wfd_is_sparse
    wfd_is_system


void
wfd_ftCreationTime(pWFD *ptr)
    PPCODE:
    XPUSHs( wft_from_wft(&ptr->ftCreationTime) );

void
ftLastAccessTime(pWFD *ptr)
    ALIAS:
	atime=1
    PPCODE:
    XPUSHs( wft_from_wft(&ptr->ftLastAccessTime) );

void
ftLastWriteTime(pWFD *ptr)    
    ALIAS:
	mtime=1
    PPCODE:
    XPUSHs( wft_from_wft(&ptr->ftLastWriteTime) );


SV *
wfd_FileSize(pWFD *ptr)
    ALIAS:
	size = 1
	filesize = 2
