#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "Windows.h"


//HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
#define VECTOR_FONTTYPE 0x0
#define MALLOC_ERROR "The memory could not be allocated."
#define ENUM_ERROR "EnumFontFamilies failed."
#define NO_FONTFOUND "No Font families found."
#define NO_FONTINFO_FOUND "No information for specifyed font found."

#define RASTERFONTTYPE 1
#define TRUETYPEFONTTYPE 2
#define VECTORFONTTYPE 3


HV *numfonts;
HV *rasterFonts;
HV *vectorFonts;
HV *truetypeFonts;

int aFontCount[] = { 0, 0, 0 }; // 0=Rasterfonts, 1=Vektorfonts, 2=Truetypefonts
static int count=0;
char *fnt[3] = { "NRASTERFONTS", "NVECTORFONTS", "NTRUETYPEFONTS" };

typedef struct tagFONTINFO
{
	int  ifn_type;
	char fn_fullname[150];
	char fn_type[150];	//Rasterfonts, Vektorfonts, Truetypefonts
	char charset[90];
	char facename[150];
	char style[150];
	char script[150];
	LOGFONT logfnt;
	NEWTEXTMETRIC textmetric;
} FONTINFO, *PFONTINFO;
FONTINFO *fontinfo;


static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

void CleanMemory(void *x, SIZE_T len)
{
	ZeroMemory(x, len);
}

// 
void GetCharsetString(BYTE chSet, char *name)
{
	switch(chSet)
	{
		case ANSI_CHARSET:
		strcpy(name,"ANSI_CHARSET");
		break;
		case BALTIC_CHARSET:
		strcpy(name,"BALTIC_CHARSET");
		break;
		case CHINESEBIG5_CHARSET:
		strcpy(name,"CHINESEBIG5_CHARSET");
		break;
		case DEFAULT_CHARSET:
		strcpy(name,"DEFAULT_CHARSET");
		break;
		case EASTEUROPE_CHARSET:
		strcpy(name,"EASTEUROPE_CHARSET");
		break;
		case GB2312_CHARSET:
		strcpy(name,"GB2312_CHARSET");
		break;
		case GREEK_CHARSET:
		strcpy(name,"GREEK_CHARSET");
		break;
		case HANGUL_CHARSET:
		strcpy(name,"HANGUL_CHARSET");
		break;
		case MAC_CHARSET:
		strcpy(name,"MAC_CHARSET");
		break;
		case OEM_CHARSET:
		strcpy(name,"OEM_CHARSET");
		break;
		case RUSSIAN_CHARSET:
		strcpy(name,"RUSSIAN_CHARSET");
		break;
		case SHIFTJIS_CHARSET:
		strcpy(name,"SHIFTJIS_CHARSET");
		break;
		case SYMBOL_CHARSET:
		strcpy(name,"SYMBOL_CHARSET");
		break;
		case TURKISH_CHARSET:
		strcpy(name,"TURKISH_CHARSET");
		break;
		case VIETNAMESE_CHARSET:
		strcpy(name,"VIETNAMESE_CHARSET");
		break;
		case JOHAB_CHARSET:
		strcpy(name,"JOHAB_CHARSET");
		break;
		case ARABIC_CHARSET:
		strcpy(name,"ARABIC_CHARSET");
		break;
		case HEBREW_CHARSET:
		strcpy(name,"HEBREW_CHARSET");
		break;
		case THAI_CHARSET:
		strcpy(name,"THAI_CHARSET");
		break;
		default:
		strcpy(name,"Charset not defined");
		break;
	}
}


void store_hv(CONST ENUMLOGFONTEX *lplf, CONST NEWTEXTMETRICEX *tm, int Fonttype)
{
	char title[90];
	char name[5000];
	char val[512];
	//HV *tmp = newHV();
	CleanMemory(&fontinfo[count].logfnt, sizeof(LOGFONT));
	CleanMemory(&fontinfo[count].textmetric, sizeof(NEWTEXTMETRIC));
	switch(Fonttype)
	{
		case RASTER_FONTTYPE:
			fontinfo[count].ifn_type=1;
			sprintf(name,"%d",aFontCount[0]);
			GetCharsetString(lplf->elfLogFont.lfCharSet, title);
			strcpy(fontinfo[count].fn_fullname,lplf->elfFullName);
			strcpy(fontinfo[count].fn_type,"Rasterfont");
			strcpy(fontinfo[count].charset,title);
			strcpy(fontinfo[count].facename,lplf->elfLogFont.lfFaceName);
			strcpy(fontinfo[count].style,lplf->elfStyle);
			strcpy(fontinfo[count].script,lplf->elfScript);
			fontinfo[count].logfnt=lplf->elfLogFont;
			fontinfo[count].textmetric=tm->ntmTm;
			strcpy(val, lplf->elfLogFont.lfFaceName);
			//strcat(val, " (");
			//strcat(val, title);
			//strcat(val, ")");
			if(hv_store(rasterFonts,name, strlen(name),newSVpv(val, strlen(val)),0)==NULL)
				croak("rasterFonts: can not store in hash!\n");
			break;
		case TRUETYPE_FONTTYPE:
			fontinfo[count].ifn_type=2;
			GetCharsetString(lplf->elfLogFont.lfCharSet, title);
			strcpy(fontinfo[count].fn_fullname,lplf->elfFullName);
			strcpy(fontinfo[count].fn_type,"Rasterfont");
			strcpy(fontinfo[count].charset,title);
			strcpy(fontinfo[count].facename,lplf->elfLogFont.lfFaceName);
			strcpy(fontinfo[count].style,lplf->elfStyle);
			strcpy(fontinfo[count].script,lplf->elfScript);
			fontinfo[count].logfnt=lplf->elfLogFont;
			fontinfo[count].textmetric=tm->ntmTm;
			sprintf(name,"%d",aFontCount[2]);
			strcpy(val, lplf->elfLogFont.lfFaceName);
			//strcat(val, " (");
			//strcat(val, title);
			//strcat(val, ")");
		
		if(hv_store(truetypeFonts,name, strlen(name),newSVpv(val, strlen(val)),0)==NULL)
			croak("truetypeFonts: can not store in hash!\n");
			break;
		case DEVICE_FONTTYPE:
			printf("Storing Device font\n");
			fontinfo[count].ifn_type=4;
			break;
		
		case VECTOR_FONTTYPE:
			fontinfo[count].ifn_type=3;
			GetCharsetString(lplf->elfLogFont.lfCharSet, title);
			strcpy(fontinfo[count].fn_fullname,lplf->elfFullName);
			strcpy(fontinfo[count].fn_type,"Rasterfont");
			strcpy(fontinfo[count].charset,title);
			strcpy(fontinfo[count].facename,lplf->elfLogFont.lfFaceName);
			strcpy(fontinfo[count].style,lplf->elfStyle);
			strcpy(fontinfo[count].script,lplf->elfScript);
			fontinfo[count].logfnt=lplf->elfLogFont;
			fontinfo[count].textmetric=tm->ntmTm;
			sprintf(name,"%d",aFontCount[1]);
			strcpy(val, lplf->elfLogFont.lfFaceName);
			//strcat(val, " (");
			//strcat(val, title);
			//strcat(val, ")");
			//if(hv_store(vectorFonts,name, strlen(name),newSVpv(lplf->elfLogFont.lfFaceName, strlen(lplf->elfLogFont.lfFaceName)),0)==NULL)
			if(hv_store(vectorFonts,name, strlen(name),newSVpv(val, strlen(val)),0)==NULL)
				croak("vectorFonts: can not store in hash!\n");
			break;
		default:
			break;
	}
}

// Enum Fontfamilies
BOOL CALLBACK EnumFamCallBackEx(ENUMLOGFONTEX *lplf, NEWTEXTMETRICEX *lpntm, DWORD FontType, LPVOID aFontCount) 
{ 
    int far * aiFontCount = (int far *) aFontCount;
    
    //HV *tmp=newHV();
    //count++;

    if (FontType & RASTER_FONTTYPE) 
    {
        store_hv(lplf, lpntm, FontType);
        aiFontCount[0]++;
    	count++;
    }
    else if (FontType & TRUETYPE_FONTTYPE) 
    {
    	store_hv(lplf, lpntm, FontType);
        aiFontCount[2]++; 
        count++;
    }
    else {
    	store_hv(lplf, lpntm, FontType);
        aiFontCount[1]++;
        count++;
    }
 
    if (aiFontCount[0] || aiFontCount[1] || aiFontCount[2])
    {
        return TRUE; 
    }
    else 
        return FALSE; 
 
    UNREFERENCED_PARAMETER( lplf ); 
    UNREFERENCED_PARAMETER( lpntm ); 
} 

BOOL CALLBACK CalcEnumFamCallBackEx(ENUMLOGFONTEX *lplf, NEWTEXTMETRICEX *lpntm, DWORD FontType, LPVOID aFontCount) 
{ 
    int far * aiFontCount = (int far *) aFontCount;
    
    HV *tmp=newHV();
    //count++;

    if (FontType & RASTER_FONTTYPE) 
    {
        aiFontCount[0]++;
    	count++;
    }
    else if (FontType & TRUETYPE_FONTTYPE) 
    {
        aiFontCount[2]++; 
        count++;
    }
    else {
        aiFontCount[1]++;
        count++;
    }
 
    if (aiFontCount[0] || aiFontCount[1] || aiFontCount[2])
    {
        return TRUE; 
    }
    else 
        return FALSE; 
 
    UNREFERENCED_PARAMETER( lplf ); 
    UNREFERENCED_PARAMETER( lpntm ); 
} 


int _FEnumFontFamilies(int charset)
{
 	LOGFONT lgFnt;
 	int ret =0;
	//int aFontCount[] = { 0, 0, 0 }; // 0=Rasterfonts, 1=Vektorfonts, 2=Truetypefonts
	
 	HDC m_hdc = GetDC(NULL);
 	lgFnt.lfCharSet = charset; //OEM_CHARSET; //ANSI_CHARSET; //DEFAULT_CHARSET;
 	lgFnt.lfFaceName[0] = '\0';
	ret = EnumFontFamiliesEx(m_hdc, &lgFnt, (FONTENUMPROC) EnumFamCallBackEx, (LPARAM) aFontCount, 0);
	//printf("The count (end): %d\n", count);

 	hv_store(numfonts,fnt[0],strlen(fnt[0]),newSViv(aFontCount[0]),0);
	hv_store(numfonts,fnt[1],strlen(fnt[1]),newSViv(aFontCount[1]),0);
	hv_store(numfonts,fnt[2],strlen(fnt[2]),newSViv(aFontCount[2]),0);
	ReleaseDC(NULL, m_hdc);
 	return ret;
}


static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Win32::Fonts::Info		PACKAGE = Win32::Fonts::Info		

SV* 
_EnumFontFamilies(charset,anz,perror)
	int charset;
	int anz;
	SV* perror;
	PREINIT:
	int ret;
	AV* result;
	CODE:
	{
		if(charset == -1)
			charset=ANSI_CHARSET;
		result=(AV *)sv_2mortal((SV *)newAV());
		fontinfo=malloc((anz)*sizeof(FONTINFO));
		if(!fontinfo)
		{
			sv_setpvn(perror, MALLOC_ERROR, strlen(MALLOC_ERROR));
			SvPOK_on(perror);
			//XSRETURN_UNDEF;
			RETVAL=newRV(newSViv(-1));
			
		}	
		aFontCount[0] = 0, aFontCount[1] = 0,aFontCount[2] = 0;
		numfonts=newHV();
		rasterFonts=(HV *)sv_2mortal((SV *)newHV());
		vectorFonts=(HV *)sv_2mortal((SV *)newHV());
		truetypeFonts=(HV *)sv_2mortal((SV *)newHV());
		count=0;
		ret = _FEnumFontFamilies(charset);
		if(ret) {
			av_push(result, newRV((SV *)numfonts));
			av_push(result, newRV((SV *)vectorFonts));
			av_push(result, newRV((SV *)truetypeFonts));
			av_push(result, newRV((SV *)rasterFonts));
			RETVAL = newRV((SV *)result);
		} else
		{
			sv_setpvn(perror, NO_FONTFOUND, strlen(NO_FONTFOUND));
			SvPOK_on(perror);
			RETVAL=newRV(newSViv(-1));
		}
	}
	OUTPUT:
		RETVAL
		perror



int
_NumberofRasterFonts(void)
	CODE:
	{
		RETVAL=aFontCount[0];
	}
	OUTPUT:
		RETVAL

int
_NumberofVectorFonts(void)
	CODE:
	{
		RETVAL=aFontCount[1];
	}
	OUTPUT:
		RETVAL

int
_NumberofTrueTypeFonts(void)
	CODE:
	{
		RETVAL=aFontCount[2];
	}
	OUTPUT:
		RETVAL


int
_NumberofFontfamilies(void)
	CODE:
	{
		RETVAL = aFontCount[0]+aFontCount[1]+aFontCount[2];
	}
	OUTPUT:
		RETVAL



SV*
_GetFontInfo(facename,type,numfonts,perror)
	char *facename;
	int type;
	int numfonts;
	SV *perror;
	PREINIT:
		int zaehler;
		HV *rv;
		int found;
		char name[512];
	CODE:
	{
		
		//printf("The name: %s %d\n",facename,type);
		zaehler=0;
		found=0;
		rv=(HV *)sv_2mortal((SV *)newHV());
		while(zaehler < numfonts)
		{
			if(fontinfo[zaehler].ifn_type==type && strEQ(fontinfo[zaehler].facename,facename))
			{
				hv_store(rv, "Full Name", strlen("Full Name"),newSVpv(fontinfo[zaehler].fn_fullname,strlen(fontinfo[zaehler].fn_fullname)),0);
				hv_store(rv, "Type", strlen("Type"),newSVpv(fontinfo[zaehler].fn_type,strlen(fontinfo[zaehler].fn_type)),0);
				hv_store(rv, "Charset", strlen("Charset"),newSVpv(fontinfo[zaehler].charset,strlen(fontinfo[zaehler].charset)),0);
				hv_store(rv, "Facename", strlen("Facename"),newSVpv(fontinfo[zaehler].facename,strlen(fontinfo[zaehler].facename)),0);
				hv_store(rv, "Style", strlen("Style"),newSVpv(fontinfo[zaehler].style,strlen(fontinfo[zaehler].style)),0);
				hv_store(rv, "Script", strlen("Script"),newSVpv(fontinfo[zaehler].script,strlen(fontinfo[zaehler].script)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfHeight);
  				hv_store(rv, "lfHeight", strlen("lfHeight"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfWidth); 
  				hv_store(rv, "lfWidth", strlen("lfWidth"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfEscapement);
  				hv_store(rv, "lfEscapement", strlen("lfEscapement"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler]. logfnt.lfOrientation);
  				hv_store(rv, "lfOrientation", strlen("lfOrientation"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfWeight); 
  				hv_store(rv, "lfWeight", strlen("lfWeight"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfItalic); 
  				hv_store(rv, "lfItalic", strlen("lfItalic"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfUnderline); 
  				hv_store(rv, "lfUnderline", strlen("lfUnderline"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfStrikeOut); 
  				hv_store(rv, "lfStrikeOut", strlen("lfStrikeOut"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfCharSet); 
  				hv_store(rv, "lfCharSet", strlen("lfCharSet"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfOutPrecision); 
  				hv_store(rv, "lfOutPrecision", strlen("lfOutPrecision"),newSVpv(name,strlen(name)),0);
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfClipPrecision);
  				hv_store(rv, "lfClipPrecision", strlen("lfClipPrecision"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfQuality); 
  				hv_store(rv, "lfQuality", strlen("lfQuality"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].logfnt.lfPitchAndFamily); 
  				hv_store(rv, "lfPitchAndFamily", strlen("lfPitchAndFamily"),newSVpv(name,strlen(name)),0); 
  				hv_store(rv, "lfFaceName", strlen("lfFaceName"),newSVpv(fontinfo[zaehler].logfnt.lfFaceName,strlen(fontinfo[zaehler].logfnt.lfFaceName)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmHeight); 
  				hv_store(rv, "tmHeight", strlen("tmHeight"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmAscent); 
  				hv_store(rv, "tmAscent", strlen("tmAscent"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmDescent); 
  				hv_store(rv, "tmDescent", strlen("tmDescent"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmInternalLeading); 
  				hv_store(rv, "tmInternalLeading", strlen("tmInternalLeading"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmExternalLeading); 
  				hv_store(rv, "tmExternalLeading", strlen("tmExternalLeading"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmAveCharWidth); 
  				hv_store(rv, "tmAveCharWidth", strlen("tmAveCharWidth"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmMaxCharWidth); 
  				hv_store(rv, "tmMaxCharWidth", strlen("tmMaxCharWidth"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmWeight); 
  				hv_store(rv, "tmWeight", strlen("tmWeight"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmOverhang); 
  				hv_store(rv, "tmOverhang", strlen("tmOverhang"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmDigitizedAspectX); 
  				hv_store(rv, "tmDigitizedAspectX", strlen("tmDigitizedAspectX"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmDigitizedAspectY); 
  				hv_store(rv, "tmDigitizedAspectY", strlen("tmDigitizedAspectY"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%c",fontinfo[zaehler].textmetric.tmFirstChar); 
  				hv_store(rv, "tmFirstChar", strlen("tmFirstChar"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%c",fontinfo[zaehler].textmetric.tmLastChar); 
  				//printf("LastChar: %c\n",fontinfo[zaehler].textmetric.tmLastChar); 
  				hv_store(rv, "tmLastChar", strlen("tmLastChar"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%c",fontinfo[zaehler].textmetric.tmDefaultChar); 
  				hv_store(rv, "tmDefaultChar", strlen("tmDefaultChar"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%c",fontinfo[zaehler].textmetric.tmBreakChar); 
  				hv_store(rv, "tmBreakChar", strlen("tmBreakChar"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmItalic); 
  				hv_store(rv, "tmItalic", strlen("tmItalic"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmUnderlined); 
  				hv_store(rv, "tmUnderlined", strlen("tmUnderlined"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmStruckOut); 
  				hv_store(rv, "tmStruckOut", strlen("tmStruckOut"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmPitchAndFamily); 
  				hv_store(rv, "tmPitchAndFamily", strlen("tmPitchAndFamily"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.tmCharSet); 
  				hv_store(rv, "tmCharSet", strlen("tmCharSet"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.ntmFlags); 
  				hv_store(rv, "ntmFlags", strlen("ntmFlags"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.ntmSizeEM); 
  				hv_store(rv, "ntmSizeEM", strlen("ntmSizeEM"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.ntmCellHeight); 
  				hv_store(rv, "ntmCellHeight", strlen("ntmCellHeight"),newSVpv(name,strlen(name)),0); 
  				sprintf(name, "%d",fontinfo[zaehler].textmetric.ntmAvgWidth); 
  				hv_store(rv, "ntmAvgWidth", strlen("ntmAvgWidth"),newSVpv(name,strlen(name)),0); 
				found=1;
				break;
			}
			zaehler++;
		}
		if(found == 0)
		{
			sv_setpvn(perror, NO_FONTINFO_FOUND, strlen(NO_FONTINFO_FOUND));
			SvPOK_on(perror);
			RETVAL=newRV(newSViv(-1));
		}
		else
			RETVAL=newRV((SV *)rv);
	}
	OUTPUT:
		RETVAL
		perror


int
_CalcNumFontFamilies(charset,perror)
	int charset;
	SV* perror;
	PREINIT:
	HDC m_hdc;
	int ret;
	LOGFONT lgFnt;
	CODE:
	{
		count=0;
		if(charset == -1)
			charset=ANSI_CHARSET;
			
 		m_hdc = GetDC(NULL);
 		lgFnt.lfCharSet = charset; //OEM_CHARSET; //ANSI_CHARSET; //DEFAULT_CHARSET;
 		lgFnt.lfFaceName[0] = '\0';
		ret = EnumFontFamiliesEx(m_hdc, &lgFnt, (FONTENUMPROC) CalcEnumFamCallBackEx, (LPARAM) aFontCount, 0);
		if(ret) 
			RETVAL = count;
		else {
			sv_setpvn(perror, ENUM_ERROR, strlen(ENUM_ERROR));
			SvPOK_on(perror);
			//XSRETURN_UNDEF;
			RETVAL=-1;
		}
		
	}
	OUTPUT:
		RETVAL

void
_Cleanup()
	PPCODE:
	{
		if(fontinfo != NULL)
			Safefree(fontinfo);
	}

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

