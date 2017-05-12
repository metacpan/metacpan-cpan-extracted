/*
	##################################################################
	##################################################################
	##
	## Win32::DirSize
	## version 1.13
	##
	## by Adam Rich <arich@cpan.org>
	##
	## 05/02/2005
	##
	##################################################################
	##################################################################
*/

#define UNICODE
#define _UNICODE
#define VC_EXTRALEAN

#include <stdlib.h>
#include <windows.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "TConvert.h"

#define DS_RESULT_OK			0
#define DS_ERR_INVALID_DIR		1
#define DS_ERR_OUT_OF_MEM		2
#define DS_ERR_ACCESS_DENIED		3
#define DS_ERR_OTHER			4

BOOL debug		= FALSE;
BOOL isUNC		= FALSE;
BOOL permsdie		= FALSE;
BOOL otherdie		= FALSE;
DWORD clustersize	= 0;

typedef struct _DIR_SCAN_DATA {
	ULARGE_INTEGER dirsize;
	ULARGE_INTEGER dirsizeondisk;
	ULARGE_INTEGER dircount;
	ULARGE_INTEGER filecount;
	char strdirsize[34];
	char strdirsizeondisk[34];
} DIR_SCAN_DATA, *PDIR_SCAN_DATA;

BOOL detect_unc(char* dirname) {
	if ((dirname[0] == '\\') && (dirname[1] == '\\')) {
		if (debug) printf("UNC = True\n");
		return TRUE;
	}
	else {
		if (debug) printf("UNC = False\n");
		return FALSE;
	}
}

void determine_root(char* dirname, char* rootname) {
	char* tempname;
	int rootsize;

	if (isUNC) {
		tempname = dirname;
		tempname += 2;

		if (debug) printf("tempname1=[%s]\n", tempname);

		// Find the second backslash
		tempname = strchr(tempname, '\\');
		if (tempname != NULL) tempname = strchr(tempname + 1, '\\');

		if (debug) printf("tempname2=[%s]\n", tempname);

		if (tempname == NULL) {
			strcpy(rootname, dirname);
			strcat(rootname, "\\");
		}
		else {
			rootsize = (tempname - dirname + 1);
			strncpy(rootname, dirname, rootsize);
			rootname[rootsize] = '\0';
		}
	}
	else {
		rootname[0] = dirname[0]; // Drive letter
		rootname[1] = dirname[1]; // colon
		rootname[2] = '\\';
		rootname[3] = '\0';
	}
	if (debug) printf("Created rootname [%s]\n", rootname);
}

int process_dir(wchar_t* dirname, AV *averrs, PDIR_SCAN_DATA pscandata) {
	wchar_t*		wildcard = NULL;
	WIN32_FIND_DATA		finddata;
	HANDLE			hdl;

	// Remove trailing slash
	while (dirname[wcslen(dirname)-1] == L'\\')
		dirname[wcslen(dirname)-1] = L'\0';

	// Make sure it's not passed in empty
	if (wcslen(dirname) < 2) return DS_ERR_INVALID_DIR;

	// Allocate memory and fill wildcard var
	if (isUNC) wildcard = (wchar_t *)malloc((wcslen(dirname) + 9) * sizeof(wchar_t));
	else wildcard = (wchar_t *)malloc((wcslen(dirname) + 7) * sizeof(wchar_t));

	// Memory?  We don't need no stinkin memory
	if (wildcard == NULL) return DS_ERR_OUT_OF_MEM;

	// Build wildcard search string
	if (isUNC) {
		if (debug) wprintf(L"Building UNC wildcard.\n");

		wcscpy(wildcard, L"\\\\?\\");
		wcscat(wildcard, L"UNC\\");
		wcscat(wildcard, dirname + 2); // skip beginning double-backslash
		wcscat(wildcard, L"\\*");
	}
	else {
		if (debug) wprintf(L"Building standard wildcard.\n");

		wcscpy(wildcard, L"\\\\?\\");
		wcscat(wildcard, dirname);
		wcscat(wildcard, L"\\*");
	}

	if (debug) wprintf(L"Wildcard: %s\n", wildcard);

	// Begin search command
	hdl = FindFirstFile (wildcard, &finddata);

	if (hdl == INVALID_HANDLE_VALUE) {
		DWORD nErr = GetLastError();

		if (debug) wprintf(L"FindFirstFile failed.\n");
		free (wildcard);

		if (nErr == ERROR_NO_MORE_FILES) {
			// Normal result, no files found in this dir.
			return DS_RESULT_OK;
		}
		else {
			// Push Error onto Errs array
			HV *errhash = (HV *)sv_2mortal((SV *)newHV());
			hv_store(errhash, "ErrCode", 7, newSVnv(nErr), 0);
			hv_store(errhash, "Location", 8, newSVpv(_tochar(dirname),0), 0);
			av_push(averrs, newRV((SV *)errhash));

			if ( nErr == ERROR_ACCESS_DENIED ) {
				if (permsdie) return DS_ERR_ACCESS_DENIED;
				else return DS_RESULT_OK;
			} else {
				if (otherdie) return DS_ERR_OTHER;
				else return DS_RESULT_OK;
			}
		}
	}
	// Search is going OK

	while (1) {
		// Keep recursing until we're done
		wchar_t *fullpath = NULL;

		fullpath = (wchar_t *)malloc((wcslen(dirname) + wcslen(finddata.cFileName) + 2) * sizeof(wchar_t));

		// Who runs out of memory these days, anyway?
		if (fullpath == NULL) {
			if (debug) wprintf(L"Out of Memory creating fullpath.\n");

			free (wildcard);
			FindClose (hdl);
			return DS_ERR_OUT_OF_MEM;
		}

		wcscpy(fullpath, dirname);
		wcscat(fullpath, L"\\");
		wcscat(fullpath, finddata.cFileName);

		if (debug) wprintf(L"Fullpath = [%s].\n", fullpath);

		if (finddata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
			// We're in a directory

			// Ignore . and ..
			if (wcscmp(L".", finddata.cFileName) != 0 && wcscmp(L"..", finddata.cFileName) != 0) {
				int process_result = 0;

				// Increment dircount
				pscandata->dircount.QuadPart += 1;

				// Recursive call
				process_result = process_dir(fullpath, averrs, pscandata);

				if (process_result != DS_RESULT_OK) {
					free (wildcard);
					free (fullpath);
					FindClose (hdl);
					return process_result;
				}
			}
			else {
				if (debug) wprintf(L"Ignored directory [%s].\n", finddata.cFileName);
			}
		}
		else {
			// Found a file.
			ULARGE_INTEGER	filesize;
			ULARGE_INTEGER	sizeondisk;
			DWORD sizeondisklow;
			DWORD sizeondiskhigh;
			DWORD sizeondiskmod;

			filesize.QuadPart	= 0;
			sizeondisk.QuadPart	= 0;

			(pscandata->filecount).QuadPart	+= 1;

			filesize.HighPart		= finddata.nFileSizeHigh;
			filesize.LowPart		= finddata.nFileSizeLow;
			(pscandata->dirsize).QuadPart	+= filesize.QuadPart;

			sizeondisklow = GetCompressedFileSize(
				fullpath,
				&sizeondiskhigh
			);

			if (sizeondisklow == INVALID_FILE_SIZE) {
				DWORD nErr = GetLastError();

				if (debug) wprintf(L"Could not get comp disk size [%s] %i.\n", fullpath, GetLastError());

				// Push Error onto Errs array
				HV *errhash = (HV *)sv_2mortal((SV *)newHV());
				hv_store(errhash, "ErrCode", 7, newSVnv(nErr), 0);
				hv_store(errhash, "Location", 8, newSVpv(_tochar(fullpath),0), 0);
				av_push(averrs, newRV((SV *)errhash));

				if (( nErr == ERROR_ACCESS_DENIED ) && permsdie) {
					free (wildcard);
					free (fullpath);
					FindClose (hdl);
					return DS_ERR_ACCESS_DENIED;
				}
				if (otherdie) {
					free (wildcard);
					free (fullpath);
					FindClose (hdl);
					return DS_ERR_OTHER;
				}

				// We don't know compressed size, so fake it:

				sizeondisk.HighPart	= finddata.nFileSizeHigh;
				sizeondisk.LowPart	= finddata.nFileSizeLow;
			}
			else {
				sizeondisk.LowPart	= sizeondisklow;
				if (sizeondiskhigh != NULL) sizeondisk.HighPart = sizeondiskhigh;
			}

			// Use clustersize to determine proper size-on-disk
			sizeondiskmod = (DWORD)(sizeondisk.QuadPart % clustersize);

			if (sizeondiskmod == 0) {
				(pscandata->dirsizeondisk).QuadPart += sizeondisk.QuadPart;
			}
			else {
				(pscandata->dirsizeondisk).QuadPart += (sizeondisk.QuadPart - sizeondiskmod);
				(pscandata->dirsizeondisk).QuadPart += clustersize;
			}
		}

		free (fullpath);

		// Now we continue the search
		if (! FindNextFile (hdl, &finddata)) {
			// Error finding the next file

			DWORD nErr = GetLastError ();

			if (debug) wprintf(L"FindNextFile failed.\n");

			free (wildcard);
			FindClose (hdl);

			if (nErr == ERROR_NO_MORE_FILES) {
				// Normal result, no more files found in this dir.

				return DS_RESULT_OK;
			}
			else {
				// Push Error onto Errs array
				HV *errhash = (HV *)sv_2mortal((SV *)newHV());
				hv_store(errhash, "ErrCode", 7, newSVnv(nErr), 0);
				hv_store(errhash, "Location", 8, newSVpv(_tochar(dirname),0), 0);
				av_push(averrs, newRV((SV *)errhash));

				if ( nErr == ERROR_ACCESS_DENIED ) {
					if (permsdie) return DS_ERR_ACCESS_DENIED;
					else return DS_RESULT_OK;
				} else {
					if (otherdie) return DS_ERR_OTHER;
					else return DS_RESULT_OK;
				}
			}
		}
	}
}

double unit_convert (char unit, unsigned long hightotalsize, unsigned long lowtotalsize) {
	ULARGE_INTEGER nSize;
	double converted;

	nSize.HighPart	= hightotalsize;
	nSize.LowPart	= lowtotalsize;
	converted	= (double)(signed __int64)nSize.QuadPart;

	switch (unit) {
		case 'E':
		case 'e':
			converted /= 1024.0;
		case 'P':
		case 'p':
			converted /= 1024.0;
		case 'T':
		case 't':
			converted /= 1024.0;
		case 'G':
		case 'g':
			converted /= 1024.0;
		case 'M':
		case 'm':
			converted /= 1024.0;
		case 'K':
		case 'k':
			converted /= 1024.0;
			break;
		case 'B':
		case 'b':
			break;
		default :
			converted = -1.0; // means unknown unit
	}
	return converted;
}


MODULE = Win32::DirSize		PACKAGE = Win32::DirSize

PROTOTYPES: DISABLE

double
best_convert (SV* unit, unsigned long highsize, unsigned long lowsize)
	INIT:
		char cunit;
	CODE:
			if (highsize	>= 268435456)	cunit = 'E';
		else	if (highsize	>= 262144)	cunit = 'P';
		else	if (highsize	>= 256)		cunit = 'T';
		else	if (highsize	>= 1)		cunit = 'G';
		else	if (lowsize	>= 1073741824)	cunit = 'G';
		else	if (lowsize	>= 1048576)	cunit = 'M';
		else	if (lowsize	>= 1024)	cunit = 'K';
		else					cunit = 'B';

		sv_setpvn(unit, &cunit, 1);
		RETVAL = unit_convert(cunit, highsize, lowsize);
	OUTPUT:
		RETVAL
		unit

double
size_convert (char unit, unsigned long highsize, unsigned long lowsize)
	CODE:
		RETVAL = unit_convert(unit, highsize, lowsize);
	OUTPUT:
		RETVAL

int
disk_space(char* dirname, SV* dirinfo)
	INIT:
		HV *hvdirinfo = newHV();
		ULARGE_INTEGER i64QuotaBytes;
		ULARGE_INTEGER i64TotalBytes;
		ULARGE_INTEGER i64FreeBytes;
		char strQuotaBytes[34];
		char strTotalBytes[34];
		char strFreeBytes[34];

		i64QuotaBytes.QuadPart	= 0;
		i64TotalBytes.QuadPart	= 0;
		i64FreeBytes.QuadPart	= 0;

	CODE:
		if (GetDiskFreeSpaceEx(	_towchar(dirname), &i64QuotaBytes, &i64TotalBytes, &i64FreeBytes )) {
			RETVAL = DS_RESULT_OK;
		}
		else {
			if (debug) printf("Could not determine DiskFreeSpaceEx size [%i]\n", GetLastError());
			RETVAL = DS_ERR_OTHER;
		}

		// Convert to strings
		_ui64toa( i64QuotaBytes.QuadPart,	strQuotaBytes,	10);
		_ui64toa( i64TotalBytes.QuadPart,	strTotalBytes,	10);
		_ui64toa( i64FreeBytes.QuadPart,	strFreeBytes,	10);

		hv_store(hvdirinfo, "QuotaBytes",	10, newSVpv(strQuotaBytes, 0), 0);
		hv_store(hvdirinfo, "TotalBytes",	10, newSVpv(strTotalBytes, 0), 0);
		hv_store(hvdirinfo, "FreeBytes",	 9, newSVpv(strFreeBytes, 0), 0);
		hv_store(hvdirinfo, "HighQuotaBytes",	14, newSVuv(i64QuotaBytes.HighPart), 0);
		hv_store(hvdirinfo, "LowQuotaBytes",	13, newSVuv(i64QuotaBytes.LowPart), 0);
		hv_store(hvdirinfo, "HighTotalBytes",	14, newSVuv(i64TotalBytes.HighPart), 0);
		hv_store(hvdirinfo, "LowTotalBytes",	13, newSVuv(i64TotalBytes.LowPart), 0);
		hv_store(hvdirinfo, "HighFreeBytes",	13, newSVuv(i64FreeBytes.HighPart), 0);
		hv_store(hvdirinfo, "LowFreeBytes",	12, newSVuv(i64FreeBytes.LowPart), 0);

		sv_setsv(dirinfo, sv_2mortal(newRV_noinc((SV *)hvdirinfo)));
	OUTPUT:
		dirinfo
		RETVAL

int
dir_size(char* dirname, SV* dirinfo, int wantpermsdie=0, int wantotherdie=0)
	INIT:
		DIR_SCAN_DATA scandata;
		AV *averrs			= newAV();
		HV *hvdirinfo			= newHV();
		char *rootname;
		DWORD SectorsPerCluster		= 0;
		DWORD BytesPerSector		= 0;
		DWORD NumberOfFreeClusters	= 0;
		DWORD TotalNumberOfClusters	= 0;

		scandata.dirsize.QuadPart	= 0;
		scandata.dirsizeondisk.QuadPart	= 0;
		scandata.dircount.QuadPart	= 0;
		scandata.filecount.QuadPart	= 0;

	CODE:
		if (wantpermsdie == 0) permsdie = FALSE; else permsdie = TRUE;
		if (wantotherdie == 0) otherdie = FALSE; else otherdie = TRUE;
		isUNC = detect_unc(dirname);

		rootname = (char *)malloc(strlen(dirname) + 2);
		if (rootname == NULL) {
			RETVAL = DS_ERR_OUT_OF_MEM;
		}
		else {
			determine_root(dirname, rootname);
			if (GetDiskFreeSpace(
						_towchar(rootname),
						&SectorsPerCluster,
						&BytesPerSector,
						&NumberOfFreeClusters,
						&TotalNumberOfClusters  )) {

				free(rootname);
				clustersize = (BytesPerSector * SectorsPerCluster);

				if (debug) printf("cluster size = %i\n", clustersize);

				RETVAL = process_dir (_towchar(dirname), averrs, &scandata);
			}
			else {
				if (debug) printf("Could not determine cluster size [%i]\n", GetLastError());
				RETVAL = DS_ERR_OTHER;
			}
		}

		// Convert to strings
		_ui64toa( scandata.dirsize.QuadPart,		scandata.strdirsize,		10);
		_ui64toa( scandata.dirsizeondisk.QuadPart,	scandata.strdirsizeondisk,	10);

		hv_store(hvdirinfo, "Errors",		 6, newRV_noinc((SV *)averrs), 0);
		hv_store(hvdirinfo, "DirSize",		 7, newSVpv(scandata.strdirsize,0), 0);
		hv_store(hvdirinfo, "HighSize",		 8, newSVuv(scandata.dirsize.HighPart), 0);
		hv_store(hvdirinfo, "LowSize",		 7, newSVuv(scandata.dirsize.LowPart), 0);
		hv_store(hvdirinfo, "DirSizeOnDisk",	13, newSVpv(scandata.strdirsizeondisk,0), 0);
		hv_store(hvdirinfo, "HighSizeOnDisk",	14, newSVuv(scandata.dirsizeondisk.HighPart), 0);
		hv_store(hvdirinfo, "LowSizeOnDisk",	13, newSVuv(scandata.dirsizeondisk.LowPart), 0);
		hv_store(hvdirinfo, "FileCount",	 9, newSVuv(scandata.filecount.LowPart), 0);
		hv_store(hvdirinfo, "DirCount",		 8, newSVuv(scandata.dircount.LowPart), 0);

		sv_setsv(dirinfo, sv_2mortal(newRV_noinc((SV *)hvdirinfo)));
	OUTPUT:
		dirinfo
		RETVAL

