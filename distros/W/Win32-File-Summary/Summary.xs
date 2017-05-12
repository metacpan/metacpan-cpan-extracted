//#ifdef __cplusplus
//extern "C" {
//#endif
#include "windows.h"
#include "Objidl.h"
#include "Objbase.h"
#include "Tlhelp32.h"
#include "defines.h"
#include "zip.h"
#include "unzip.h"
#include "OOo.h"
#include "Summary.h"
#include "language.h"
#undef THIS 

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
//#ifdef __cplusplus
//}
//#endif
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0502 

/* constructor
*/
Summary::Summary(char *File)
{
    MultiByteToWideChar(CP_ACP, 0, File, -1, m_File, (sizeof(m_File)/sizeof(WCHAR)));
    char *path = NULL; // = NEWSV(0,0);
    m_hr = S_OK;
    char *lpBuffer = __FILE__;
    m_ipStg = NULL;
    m_hv = (HV* )newHV();    // return Hash
    m_av = newAV();        // return Array
    m_wFile=File;
    m_oemcp = 0;
    HMODULE hModule;
    MODULEENTRY32 me32;
    char szModule[MAX_PATH];
    char szFilename[MAX_PATH];
    DWORD dwPID = GetCurrentProcessId();
    HANDLE hModuleSnap = INVALID_HANDLE_VALUE;
    hModuleSnap = CreateToolhelp32Snapshot( TH32CS_SNAPMODULE, dwPID );
    if(hModuleSnap != INVALID_HANDLE_VALUE)
    {
        me32.dwSize = sizeof( MODULEENTRY32 );
        if( Module32First( hModuleSnap, &me32 ) )
        {
            do {
                if(!lstrcmpi("Summary.dll", me32.szModule))
                {
                    lstrcpy(szModule, me32.szModule);
                    hModule = me32.hModule;
                    break;
                }
            } while(Module32Next( hModuleSnap, &me32 ));
        }
    }
   
    if(hModule)
    {
        DWORD size = GetModuleFileName(hModule, szFilename, sizeof(szFilename));
        if(size > 0)
        {
            m_ModulePath = new char(lstrlen(szFilename)+1);
            m_ModulePath = substring(szFilename, 0, (lstrlen(szFilename) - lstrlen(szModule)));
            //printf("The Path is: %s\n", m_ModulePath);	//including 
        }
    }
    if(hModuleSnap)
        CloseHandle( hModuleSnap );

    CheckIfOOoFile(File);
}



/* destructor
*/
Summary::~Summary()
{ 
    if( m_ipStg ) m_ipStg->Release();
    if(m_ModulePath) delete m_ModulePath;
	if(m_wFile) delete m_wFile;
}


/**********************************
* Returns the titles as an Arrayref
*/
SV*
Summary::_GetTitles(void)
{
	return newRV((SV *)m_av);
}

/* returns 
*/
SV*
Summary::GetError(void)
{
	if(m_IsError == 1)
		return (newRV_noinc(newSVpvn(m_perror, strlen(m_perror))));
	else
		return (newRV_noinc(newSVpvn("there was no Error", strlen("there was no Error"))));
}


int
Summary::IsStgFile(void)
{
		m_hr = StgIsStorageFile(m_File);
		if( S_OK == m_hr )
			return(1);
		if(S_FALSE == m_hr )
			return(0);
		return (0);
}

int
Summary::IsWin2000OrNT(void)
{
	OSVERSIONINFO osvi;
	ZeroMemory(&osvi, sizeof(OSVERSIONINFO));
   	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
   	BOOL bOsVersionInfoEx;
   	if( !(bOsVersionInfoEx = GetVersionEx(&osvi)) )
	{
        	return(0);
   	}
	if(osvi.dwPlatformId == VER_PLATFORM_WIN32_NT)
		return(1);
	return(0);
}


int
Summary::IsNTFS(void)
{
	HANDLE hDevice;
	FILESYSTEM_STATISTICS OutBuffer;
	SYSTEM_INFO SystemInfo;
	int retcode = 0;
	GetSystemInfo(&SystemInfo);	// to get the number of processors
	int SizeFat = (sizeof(FILESYSTEM_STATISTICS)+sizeof(FAT_STATISTICS)*64*SystemInfo.dwNumberOfProcessors);
	int SizeNtfs = (sizeof(FILESYSTEM_STATISTICS)+sizeof(NTFS_STATISTICS)*64*SystemInfo.dwNumberOfProcessors);
	struct 
	{
		FILESYSTEM_STATISTICS FSysST;
		NTFS_STATISTICS ntfsST;
	} NtfsStat;
	struct 
	{
		FILESYSTEM_STATISTICS FSysST;
		FAT_STATISTICS FatST;
	} FatStat;
	BOOL b;
	DWORD BytesReturned = 0;
	hDevice = CreateFile(m_wFile,0,FILE_SHARE_READ|FILE_SHARE_WRITE ,NULL,OPEN_EXISTING,0,NULL);
	if(hDevice == INVALID_HANDLE_VALUE) { 
		SetErr("can not open file\n");
		return 0;
	}
	b= DeviceIoControl(
	hDevice,                 // handle to device
	FSCTL_FILESYSTEM_GET_STATISTICS,  // dwIoControlCode
	NULL,                       // lpInBuffer
	0,                          // nInBufferSize
	&OutBuffer,
	sizeof(FILESYSTEM_STATISTICS),
	&BytesReturned,  // number of bytes returned
	(LPOVERLAPPED)NULL // OVERLAPPED structure
	);
	//memcpy(OutBuffer,(FILESYSTEM_STATISTICS*)vOutBuffer,sizeof(vOutBuffer));
	//printf("The type: %d The size: %d\n",(FILESYSTEM_STATISTICS*)vOutBuffer->FileSystemType, sizeof(vOutBuffer));
	//printf("The size: %d Bytes returned :%d Size2: %d FsType: %d\n",sizeof(FILESYSTEM_STATISTICS), b, sizeof(NTFS_STATISTICS), OutBuffer.FileSystemType);
	if(OutBuffer.FileSystemType == FILESYSTEM_STATISTICS_TYPE_NTFS)
		retcode = 1;
	/*if(GetLastError() == ERROR_MORE_DATA && OutBuffer->FileSystemType == FILESYSTEM_STATISTICS_TYPE_NTFS)
	{
		printf("There are more data!\n");
		b= DeviceIoControl(hDevice, FSCTL_FILESYSTEM_GET_STATISTICS, NULL,0,&OutBuffer, SizeNtfs, &BytesReturned, NULL );
	printf("\n\nLasterror: %d BytesReturned: %d\n\n\n\n", GetLastError(), BytesReturned);
	} else if(GetLastError() == ERROR_MORE_DATA && OutBuffer->FileSystemType == FILESYSTEM_STATISTICS_TYPE_FAT)
	{
		b= DeviceIoControl(hDevice, FSCTL_FILESYSTEM_GET_STATISTICS, NULL,0,&FatStat, SizeFat, &BytesReturned, NULL );
	}
	
*/	

/*	if(b == 0) {
		printf("Could not get DeviceIoControl %d %d\n", GetLastError(), OutBuffer.FileSystemType);
		return 0;
	} */
	//if(NtfsOut.OutBuffer.FileSystemType == FILESYSTEM_STATISTICS_TYPE_NTFS) 
	//	return 1;
	
	CloseHandle(hDevice);
	return retcode;
}


SV* Summary::Read(void) {
		
	char err[2];
	strcpy(err, "0");
	m_ptResult = NEWSV(0,0);
	this->GetLang();
	if (m_IsOOo == 1)
	{
		
		this->ReadOOo();
	}
	m_hr = StgOpenStorageEx( m_File,
                          STGM_READ|STGM_SHARE_DENY_WRITE,
                          STGFMT_ANY,
                          0,
                          NULL,
                          NULL,
                           IID_IPropertySetStorage,
                           reinterpret_cast<void**>(&m_ipStg) );	// IPropertySetStorage *m_ipStg;
	if( FAILED(m_hr) ) 
	{
		SetErr("could not open storage for inputfile: ");
		return(newRV_noinc(newSVpvn(err, strlen(err))));
	} 
	if(ReadSummaryInformation()==0)
		return(newRV_noinc(newSVpvn(err, strlen(err))));
	ReadDocSummaryInformation();

	if( m_ipStg ) m_ipStg->Release();
	m_ptResult = newRV_noinc((SV *) m_hv);
	return (m_ptResult);
}

SV*
Summary::Write(SV *newinfo)
{
	HV* hv = (HV*)SvRV(newinfo);	// Hash of key/value pairs
	int numkeys = HvKEYS(hv);	// The number of keys
	int count = 0;
	SV** tmpsv;
	SV* m_ptResult = NEWSV(0,0);
	IPropertySetStorage *pPropSetStg = NULL;
	IPropertyStorage * ipStg = NULL;
	int i=numkeys-1;
	PROPSPEC prop[100];
	PROPVARIANT propvar[100];
       	PropVariantInit(propvar);
	wchar_t OleTitle[50];	//WCHAR
	wchar_t Oleval[2048];	//WCHAR
	int retcode = 0;
	if(m_IsOOo) return(newRV_noinc(newSVpvn("1", strlen("1"))));
	m_hr = StgOpenStorageEx( m_File,
                          STGM_READWRITE|STGM_SHARE_EXCLUSIVE,
                          STGFMT_ANY,
                          0,
                          NULL,
                          NULL,
                          IID_IPropertySetStorage,
                          reinterpret_cast<void**>(&pPropSetStg) );
	if( FAILED(m_hr) ) 
	{
		SetErr("could not open storage for inputfile: ");
		m_ptResult = newSVpvn("0", strlen("0"));
		return(m_ptResult);
	}
	m_hr = pPropSetStg->Open(FMTID_SummaryInformation, STGM_READWRITE|STGM_SHARE_EXCLUSIVE, &ipStg);
	if( FAILED(m_hr) ) 
	{
		SetErr("could not open storage: ");
		m_ptResult = newSVpvn("0", strlen("0"));
		return(m_ptResult);

	}
	
	for(i=0; i<numkeys;i++)
	{
		tmpsv = hv_fetch(hv, writeable[i].friendlyname_eng,strlen(writeable[i].friendlyname_eng),0);
		if(tmpsv != NULL)
		{
        		if(writeable[i].IsOOo == 0 || writeable[i].IsOOo == 2) 
        		{
        			
				char *val = SvPVX(*tmpsv);
				prop[count].ulKind = PRSPEC_LPWSTR;
				retcode = MultiByteToWideChar(CP_ACP, 0, writeable[i].friendlyname_eng, -1,OleTitle, (sizeof(OleTitle)/sizeof(WCHAR)));
			        prop[count].lpwstr = OleTitle;
	        		
			        propvar[count].vt = VT_LPWSTR;
			        retcode=MultiByteToWideChar(CP_ACP, 0, val, -1, Oleval, (sizeof(Oleval)/sizeof(WCHAR)));
        			propvar[count].pwszVal = Oleval;
        			count++;
        		}
        	}
        }
	m_hr = ipStg->WriteMultiple( count, prop, propvar, PID_FIRST_USABLE);
	if( FAILED(m_hr) ) 
	{
		SetErr("could not write into inputfile: ");
		printf(m_perror);
		printf("\n");
		m_ptResult = newSVpvn("0", strlen("0"));
		return(m_ptResult);
	} else {
		printf("wrote into inputfile!\n");
	}
	m_hr = ipStg->Commit(STGC_DEFAULT);
	if( FAILED(m_hr))
	{
		SetErr("could not commit the new values: ");
		printf(m_perror);
		m_ptResult = newSVpvn("0", strlen("0"));
		return(m_ptResult);
	}
	printf("befor return!\n");
	//return(newRV_noinc(newSVpvn("1", strlen("1"))));
	if(pPropSetStg)
		pPropSetStg->Release();
	if(ipStg)
		ipStg->Release();
	m_ptResult = newSVpvn("1", strlen("1"));
	return(m_ptResult);
}

//Private member functions
/*********************************
* Check if german or an other language
*/
int Summary::GetLang(void)
{
	LANGID langID = GetUserDefaultLangID();
	if(langID == 0x0407 || langID==0x0807 || langID==0x0c07 || langID==0x1007 || langID==0x1407) return 0; // German
	return 1;	// all other
	
};

void 
Summary::SetErr(char *msg)
{
	char tmp[1000] = { '\0' };
	m_IsError=1;
	HrToString(m_hr, tmp);
	strcpy(m_perror, msg);
	strcat(m_perror, tmp);
	

}


void
Summary::HrToString(HRESULT hr, char *string) {
			if(hr == S_OK)
				strcpy(string,"S_OK");
			else if(hr == E_ACCESSDENIED)
				strcpy(string,"E_ACCESSDENIED");
			else if(hr == E_FAIL)
				strcpy(string,"E_FAIL");
			else if(hr == E_HANDLE)
				strcpy(string,"E_HANDLE");
			else if(hr == E_INVALIDARG)
				strcpy(string,"E_INVALIDARG");
			else if(hr == E_NOTIMPL)
				strcpy(string,"E_NOTIMPL");
			else if(hr == E_OUTOFMEMORY)
				strcpy(string,"E_OUTOFMEMORY");
			else if(hr == E_PENDING)
				strcpy(string,"E_PENDING");
			else if(hr == E_POINTER)
				strcpy(string,"E_POINTER");
			else if(hr == E_UNEXPECTED)
				strcpy(string,"E_UNEXPECTED");
			else if(hr == S_FALSE)
				strcpy(string,"S_FALSE");
			else if(hr == STG_E_INVALIDPOINTER)
				strcpy(string,"STG_E_INVALIDPOINTER");
			else if(hr == STG_E_INVALIDPARAMETER)
				strcpy(string,"STG_E_INVALIDPARAMETER");
			else if(hr == E_NOINTERFACE )
				strcpy(string,"E_NOINTERFACE");
			else if(hr == STG_E_INVALIDFLAG )
				strcpy(string,"STG_E_INVALIDFLAG");
			else if(hr == STG_E_INVALIDNAME )
				strcpy(string,"STG_E_INVALIDNAME");
			else if(hr == STG_E_INVALIDFUNCTION )
				strcpy(string,"STG_E_INVALIDFUNCTION");
			else if(hr == STG_E_LOCKVIOLATION )
				strcpy(string,"STG_E_LOCKVIOLATION");
			else if(hr == STG_E_SHAREVIOLATION )
				strcpy(string,"STG_E_SHAREVIOLATION");
			else if(hr == STG_E_UNIMPLEMENTEDFUNCTION )
				strcpy(string,"STG_E_UNIMPLEMENTEDFUNCTION");
			else if(hr == STG_E_INCOMPLETE )
				strcpy(string,"STG_E_INCOMPLETE");
			else if(hr == STG_E_ACCESSDENIED) 
				strcpy(string,"STG_E_ACCESSDENIED");
			else if(hr == STG_E_FILENOTFOUND)
				strcpy(string,"The requested storage does not exist (STG_E_FILENOTFOUND).");
			else
				strcpy(string,"Unknown error (STG_E_UNKNOWN).");
}

void
Summary::PropertyPIDToCaption(PROPSPEC propspec, char *title, bool DocSum)
{
	int numelems = NUMELEM(SummaryInformation);
	int lang = this->GetLang();
	//printf("propspec.ulKind : %i propspec.propid %0x\n", propspec.ulKind, propspec.propid );
	if(propspec.ulKind == 1 && DocSum == 0) {
     		for(int i=0; i<numelems;i++)
     		{
     			if(SummaryInformation[i].id == propspec.propid && SummaryInformation[i].docsummary == 0)
     			{
     				if(lang == 0)	// German
	     				strcpy(title, SummaryInformation[i].friendlyname_ger);
	     			else
	     				strcpy(title, SummaryInformation[i].friendlyname_eng);
     				break;
     			}
     		}
     	} else {
     		for(int i=0; i<numelems;i++)
     		{
     			if(SummaryInformation[i].id == propspec.propid && SummaryInformation[i].docsummary == 1)
     			{
     				if(lang == 0)	// German
     					strcpy(title, SummaryInformation[i].friendlyname_ger);
     				else
	     				strcpy(title, SummaryInformation[i].friendlyname_eng);
     				break;
     			}
     		}
     	}
     	
}

int Summary::ReadDocSummaryInformation(void)
{
	IPropertyStorage *pPropStg = NULL;
	char tmp1[1024];
	char tmp[1000] = { '\0' };
	PROPVARIANT propvar;
	IEnumSTATPROPSTG *penum;
	STATPROPSTG PropStat;
        PROPSPEC propspec;
        SYSTEMTIME SystemTime;
	//m_hr = m_ipStg->Open(FMTID_SummaryInformation, STGM_READ|STGM_SHARE_EXCLUSIVE, &pPropStg);
	m_hr = m_ipStg->Open(FMTID_DocSummaryInformation, STGM_READ|STGM_SHARE_EXCLUSIVE, &pPropStg);
	if(FAILED(m_hr) )
	{
		if(m_IsOOo == 0) {
			SetErr("m_ipStg->Open failed: ");
			return(0);
		} else
		{
			m_ptResult = newRV_noinc((SV *) m_hv);
			return (1);
		}
	} 

	m_hr = pPropStg->Enum(&penum);
	if(FAILED(m_hr) )
	{
		if(m_IsOOo == 0) {
			SetErr("PropStg->Enum failed: ");
			return(0);
		} else
		{
			m_ptResult = newRV_noinc((SV *) m_hv);
			return (1);
		}
	} 
	m_hr = penum->Next(1, &PropStat, NULL);
	while(m_hr == S_OK)
	{
		//printf("The vartype=%d PropID: %d\n", PropStat.vt, PropStat.propid);
		propspec.ulKind = PRSPEC_PROPID;
		propspec.propid = PropStat.propid;
		//printf("Type: %d\n", PropStat.propid);
		PropVariantInit( &propvar );
		m_hr = pPropStg->ReadMultiple( 1, &propspec, &propvar );
		if( FAILED(m_hr) )
		{
			SetErr("pPropStg->ReadMultiple failed: ");
			return(0);
		}
		PropertyPIDToCaption(propspec, tmp1, 1);
		AnsiToOem(tmp1);
		if(strlen(tmp1) > 0)
			av_push(m_av, newSVpvn(tmp1, strlen(tmp1)));
		
		//if(VT_I4  == propvar.vt) propspec.propid = 19
			//printf("propvar.vt %d !!!!!!!!!!!!! %s\n", propvar.vt, tmp1);
		
		if(propvar.vt == VT_LPSTR)
		{
			if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(propvar.pszVal, 0),0) == NULL)
				croak("Can not store in Hash!\n");
			AnsiToOem(propvar.pszVal);
		} else if( propvar.vt == VT_FILETIME )
		{
			
			FileTimeToSystemTime(&propvar.filetime, &SystemTime);
			wsprintf(tmp, TEXT("%02d/%02d/%d  %02d:%02d:%02d"),
       					SystemTime.wMonth, SystemTime.wDay, SystemTime.wYear, SystemTime.wHour, SystemTime.wMinute, SystemTime.wSecond );
			if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(tmp, 0),0) == NULL)
				croak("Can not store in Hash!\n");
			
		} else if( propvar.vt == VT_I4)
		{
			if(strlen(tmp1) > 0) {
				wsprintf(tmp, TEXT("%d"), propvar.lVal);
				//printf("tmp1: %s val: %x\n", tmp1, propvar.lVal);
				if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(tmp, 0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
		} else if(propvar.vt == VT_BOOL)
		{
			if(strlen(tmp1) > 0) {
				wsprintf(tmp, TEXT("%d"), propvar.lVal);
				if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(tmp, 0),0) == NULL)
					croak("Can not store in Hash!\n");
			}
			//printf("%s: ", tmp1);
			//printf("Value: %d VT: %d\n",propvar.lVal,  propvar.vt);

		} 
		tmp1[0] = '\0';
		if(PropStat.lpwstrName) {
			 CoTaskMemFree(PropStat.lpwstrName);
		}
		m_hr = penum->Next(1, &PropStat, NULL);
	} // end while m_hr == S_OK
	return(1);
}

int Summary::ReadSummaryInformation(void)
{
	IPropertyStorage *pPropStg = NULL;
	char tmp1[1024];
	char tmp[1000] = { '\0' };
	PROPVARIANT propvar;
	IEnumSTATPROPSTG *penum;
	STATPROPSTG PropStat;
        PROPSPEC propspec;
        SYSTEMTIME SystemTime;

	m_hr = m_ipStg->Open(FMTID_SummaryInformation, STGM_READ|STGM_SHARE_EXCLUSIVE, &pPropStg);
	if(FAILED(m_hr) )
	{
		if(m_IsOOo == 0) {
			SetErr("m_ipStg->Open failed: ");
			return(0);
		} else
		{
			m_ptResult = newRV_noinc((SV *) m_hv);
			return (1);
		}
	} 

	m_hr = pPropStg->Enum(&penum);
	if(FAILED(m_hr) )
	{
		if(m_IsOOo == 0) {
			SetErr("PropStg->Enum failed: ");
			return(0);
		} else
		{
			m_ptResult = newRV_noinc((SV *) m_hv);
			return (1);
		}
	} 
	m_hr = penum->Next(1, &PropStat, NULL);
	while(m_hr == S_OK)
	{
		//printf("The vartype=%d PropID: %d\n", PropStat.vt, PropStat.propid);
		propspec.ulKind = PRSPEC_PROPID;
		propspec.propid = PropStat.propid;
		//printf("Type: %d\n", PropStat.propid);
		PropVariantInit( &propvar );
		m_hr = pPropStg->ReadMultiple( 1, &propspec, &propvar );
		if( FAILED(m_hr) )
		{
			SetErr("pPropStg->ReadMultiple failed: ");
			return(0);
		}
		PropertyPIDToCaption(propspec, tmp1, 0);
		AnsiToOem(tmp1);
		av_push(m_av, newSVpvn(tmp1, strlen(tmp1)));
		
		//if(VT_I4  == propvar.vt) propspec.propid = 19
			//printf("propvar.vt %d !!!!!!!!!!!!! %s\n", propvar.vt, tmp1);
		
		if(propvar.vt == VT_LPSTR)
		{
			
			if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(propvar.pszVal, 0),0) == NULL)
				croak("Can not store in Hash!\n");
			AnsiToOem(propvar.pszVal);
		} else if( propvar.vt == VT_FILETIME )
		{
			
			FileTimeToSystemTime(&propvar.filetime, &SystemTime);
			wsprintf(tmp, TEXT("%02d/%02d/%d  %02d:%02d:%02d"),
       					SystemTime.wMonth, SystemTime.wDay, SystemTime.wYear, SystemTime.wHour, SystemTime.wMinute, SystemTime.wSecond );
			if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(tmp, 0),0) == NULL)
				croak("Can not store in Hash!\n");
			
		} else if( propvar.vt == VT_I4)
		{
			wsprintf(tmp, TEXT("%d"), propvar.lVal);
			if(hv_store(m_hv, tmp1, (U32) strlen(tmp1), newSVpv(tmp, 0),0) == NULL)
				croak("Can not store in Hash!\n");
		} else
		{
			printf("%s: ", tmp1);
			printf("Value: %d VT: %d\n",propvar.lVal,  propvar.vt);

		}

		if(PropStat.lpwstrName) {
			 CoTaskMemFree(PropStat.lpwstrName);
		}
		m_hr = penum->Next(1, &PropStat, NULL);
	} // end while m_hr == S_OK
	return(1);
}

/**********************************
* reads an OpenOffice file, stores 
* the meta infomation in m_hv and 
* the titles in m_av
*/	
int
Summary::ReadOOo(void)
{
	unzFile uzFile;
	unz_global_info pglobal_info;
	uInt size_buff = 10000;
	char *buff = (char *)malloc(size_buff+1);
	uzFile = unzOpen(m_wFile);
	if(uzFile != NULL)
	{
		if(unzGetGlobalInfo(uzFile, &pglobal_info) != UNZ_OK)
			croak("Error in unzGetGlobalInfo!\n");

		if(unzLocateFile(uzFile,"meta.xml", 2) != UNZ_OK)
			croak("can not locate meta.xml!\n");

		if(unzOpenCurrentFile(uzFile) != UNZ_OK)
			croak("can not open meta.xml!\n");

		if(unzReadCurrentFile(uzFile, buff, size_buff) < 0)
			croak("can not read meta.xml!\n");
		
		OOo *OOo_data = new OOo;	// initializeing 
		
		OOo_data->SetBuffer(buff,m_oemcp);	// setting the buffer
		
		if(OOo_data->ParseBuffer(m_hv,m_av) == false)
		{
			SetErr("Error parsing XML - buffer!\n");
			return 0;
		}
		free(buff);	// Freeing temp. buffer
		unzCloseCurrentFile(uzFile);
		unzClose(uzFile);
	} else
	{
		SetErr("Could not open OpenOffice/StarOffice Document!\n");
		return 0;
	}
	return 1;
}

/* converts to DOS
*/
bool Summary::ConvertToAnsi(char *szUTF8, char *ansistr)
{
   // Convert to UNICODE:
   char *str;
//   int size;
   int size = MultiByteToWideChar(CP_OEMCP, 0, szUTF8, -1, NULL, 0);
   if (size <= 0) return false;
   WCHAR *unicodeString = new WCHAR[size+1];
   size = MultiByteToWideChar(CP_OEMCP, 0, szUTF8, -1, unicodeString, size+1);
   if (size <= 0) return false; // mem-leak!

   // Convert to ANSI:
 
   if(m_oemcp == 0) 
   {
	size = WideCharToMultiByte(CP_ACP, 0, unicodeString, -1, NULL, 0,NULL, NULL);
   	if (size <= 0) return false;
   	str = new char[size+1];
   
   	size = WideCharToMultiByte(CP_ACP, 0, unicodeString, -1, str,size+1, NULL, NULL);
   	if (size <= 0) return false; // mem-leak! 

   } else if(m_oemcp == 1)
   {
   	
	size = WideCharToMultiByte(CP_OEMCP, 0, unicodeString, -1, NULL, 0,NULL, NULL);
   	if (size <= 0) return false;
   	str = new char[size+1];
   
   	size = WideCharToMultiByte(CP_OEMCP, 0, unicodeString, -1, str,size+1, NULL, NULL);
   	if (size <= 0) return false; // mem-leak! 

   } else
    	return false;

	if(ansistr == NULL)
	{
		printf("Error ansistr == NULL\n");
		return false;
	}
    strcpy(ansistr,str);
    
	return true;
}

BOOL Summary::AnsiToOem(char *text)
{
    char *temp;
    BOOL ret;
    if(m_oemcp == 1)
    {
        temp = new char(strlen(text)+1);
        ret = ::CharToOem(text, temp);
        strcpy(text, temp);
        delete temp;
    }
    return ret;
}


// End private functions



MODULE = Win32::File::Summary		PACKAGE = Win32::File::Summary		


void 
init(File, Path)
	char *File
	char *Path
	PPCODE:
	{
    dXSARGS;
	Summary *	RETVAL;
	File = (char *)SvPV(ST(2),PL_na);
	File = (char *)SvPV(ST(1),PL_na);
	char *	CLASS = (char *)SvPV(ST(0),PL_na);

	RETVAL = new Summary(File);
	ST(0) = sv_newmortal();
	sv_setref_pv( ST(0), CLASS, (void*)RETVAL );
    XSRETURN(1);
		
	}

Summary* 
Summary::new(File)
	char * File



SV*
Summary::_GetTitles()

	
SV*
Summary::Read()

void 
Summary::SetOEMCP(oemcp)
		int oemcp

SV*
Summary::Write(newinfo)
	SV *newinfo

SV*
Summary::GetError();

					
int
Summary::IsWin2000OrNT()

int
Summary::IsStgFile()

int
Summary::IsNTFS()

void
Summary::DESTROY()

int
Summary::IsOOoFile()

