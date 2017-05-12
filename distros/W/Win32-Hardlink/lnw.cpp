// Public Domain Source: http://win32.mvps.org/ntfs/lnw.cpp

// to compile for ANSI:
// 		cl lnw.cpp
// to compile for Unicode:
//		cl -DUNICODE lnw.cpp

// make sure the C headers see the same Unicode mode as the Windows headers

#if defined( UNICODE ) && ! defined( _UNICODE )
#define _UNICODE
#endif

#if defined( _UNICODE ) && ! defined( UNICODE )
#define UNICODE
#endif



#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <string.h>

#pragma hdrstop
#pragma comment( lib, "advapi32.lib" )


extern "C" {
typedef BOOL (__stdcall *chl_t)( LPCTSTR toFile, LPCTSTR fromFile, LPSECURITY_ATTRIBUTES sa );
}
extern "C" {
    int create_hard_link ( TCHAR* oldpath, TCHAR* newpath );
}

// these must always be ANSI!
#ifdef UNICODE
#define CREATEHARDLINK "CreateHardLinkW"
#else
#define CREATEHARDLINK "CreateHardLinkA"
#endif

#define err doerr( _T( __FILE__ ), __LINE__ )



void doerr( const TCHAR *file, int line )
{
	DWORD e;

	e = GetLastError();
	if ( e == 0 )
		return;

	_tprintf( _T( "%s(%d): gle = %lu\n" ), file, line, e );
	exit( 2 );
}



void enableprivs()
{
	HANDLE hToken;
	byte buf[sizeof TOKEN_PRIVILEGES * 2];
	TOKEN_PRIVILEGES & tkp = *( (TOKEN_PRIVILEGES *) buf );

	if ( ! OpenProcessToken( GetCurrentProcess(),
		TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken ) )
		err;

	// enable SeBackupPrivilege, SeRestorePrivilege

	if ( !LookupPrivilegeValue( NULL, SE_BACKUP_NAME, &tkp.Privileges[0].Luid ) )
		err;

	if ( !LookupPrivilegeValue( NULL, SE_RESTORE_NAME, &tkp.Privileges[1].Luid ) )
		err;

	tkp.PrivilegeCount = 2;
	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
	tkp.Privileges[1].Attributes = SE_PRIVILEGE_ENABLED;

	if ( ! AdjustTokenPrivileges( hToken, FALSE, &tkp, sizeof tkp, NULL, NULL ) )
		err;
}



#define offsetof(t,m) ((size_t) &(((t *) 0)->m))

void CreateHardLinkNt4( const TCHAR *fromFile, const TCHAR *toFile )
{
	HANDLE fh;
	static TCHAR buf1[MAX_PATH];
	TCHAR *p;
	void *ctx = NULL;
	WIN32_STREAM_ID wsi;
	static wchar_t buf2[MAX_PATH * 2];
	DWORD numwritten;

	enableprivs(); // in case we aren't admin

	fh = CreateFile( toFile, 0, 0, 0, OPEN_EXISTING, 0, 0 );
	if ( fh != INVALID_HANDLE_VALUE )
	{
		CloseHandle( fh );
		_tprintf( _T( "%s already exists.\n" ), toFile );
		SetLastError( ERROR_ALREADY_EXISTS );
		return;
	}

	fh = CreateFile( fromFile, GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_POSIX_SEMANTICS, NULL );
	if ( fh == INVALID_HANDLE_VALUE )
		err;

	GetFullPathName( toFile, MAX_PATH, &buf1[0], &p );

	wsi.dwStreamId = BACKUP_LINK;
	wsi.dwStreamAttributes = 0;
	wsi.dwStreamNameSize = 0;
#ifndef UNICODE
	MultiByteToWideChar( CP_ACP, 0, buf1, strlen( buf1 ) + 1, buf2, MAX_PATH );
#else
	_tcscpy( buf2, buf1 );
#endif
	wsi.Size.QuadPart = ( wcslen( buf2 ) + 1 ) * sizeof( wchar_t );

	if ( ! BackupWrite( fh, (byte *) &wsi, offsetof( WIN32_STREAM_ID, cStreamName ), &numwritten, FALSE, FALSE, &ctx ) )
		err;
	if ( numwritten != offsetof( WIN32_STREAM_ID, cStreamName ) )
		err;

	if ( ! BackupWrite( fh, (byte *) buf2, wsi.Size.LowPart, &numwritten, FALSE, FALSE, &ctx ) )
		err;
	if ( numwritten != wsi.Size.LowPart )
		err;

	// make NT release the context
	BackupWrite( fh, (byte *) &buf1[0], 0, &numwritten, TRUE, FALSE, &ctx );

	CloseHandle( fh );
}



int CreateHardLinkNt5( const TCHAR *fromFile, const TCHAR *toFile )
{
	chl_t chl; // pointer to CreateHardLink()
	int tryOldMethod = 1; // assume we are not on NT5

	// first, try the easy (NT5) way
	HMODULE hmk32 = LoadLibrary( _T( "kernel32.dll" ) );
	if ( hmk32 > (HMODULE) 32 )
	{
		chl = (chl_t) GetProcAddress( hmk32, CREATEHARDLINK );
		if ( chl != NULL ) // seems to be NT5 or so
		{
			// we have found the API, no need for clumsy stuff
			tryOldMethod = 0;

			if ( ! chl( toFile, fromFile, NULL ) ) {
			    _tprintf( _T( "CreateHardLink( \"%s\", \"%s\" ) failed with error %lu.\n" ),
				    toFile, fromFile, GetLastError() );
			    tryOldMethod = -1;
			}
		}
		FreeLibrary( hmk32 );
	}

	return tryOldMethod;
}

int create_hard_link ( TCHAR* oldpath, TCHAR* newpath ) {
    int rv;
    rv = CreateHardLinkNt5( oldpath, newpath );
    if (rv == 1) {
	CreateHardLinkNt4( oldpath, newpath );
	rv = ( (GetFileAttributes(newpath) != (DWORD) -1) ? 0 : 1);
    }
    return rv;
}


/*
#ifdef UNICODE
int wmain( int argc, TCHAR *argv[] )
#else
int main( int argc, TCHAR *argv[] )
#endif
{
	if ( argc != 3 )
	{
		_tprintf( _T( "usage: lnw {file} {new_link_name}\n" ) );
		return 1;
	}

	if ( CreateHardLinkNt5( argv[1], argv[2] ) )
		CreateHardLinkNt4( argv[1], argv[2] );

	return 0;
}
*/
