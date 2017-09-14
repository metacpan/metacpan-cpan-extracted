#define PERL_NO_GET_CONTEXT

/* Windows Vista required */
#define _WIN32_WINNT 0x600

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "Winspool.h"
#include "Stringapiset.h"

#ifndef WC_ERR_INVALID_CHARS
#define WC_ERR_INVALID_CHARS 0x80
#endif

static SV*
newSVdual(pTHX_ IV iv, const char *str) {
    SV *sv = newSVpv(str, 0);
    SvUPGRADE(sv, SVt_PVIV);
    SvIOK_on(sv);
    SvIV_set(sv, iv);
    return sv;
}

/* Those definitions are missing from MinGW winspool.h */
#ifndef STRING_NONE
#define STRING_NONE     0x00000001L
#endif
#ifndef STRING_MUIDLL
#define STRING_MUIDLL   0x00000002L
#endif
#ifndef STRING_LANGPAIR
#define STRING_LANGPAIR 0x00000004L
#endif

/* #define DEBUG 1 */
#include "const-c.inc"

union printer_info_all {
    PRINTER_INFO_1W pi1;
    PRINTER_INFO_2W pi2;
//    PRINTER_INFO_3W pi3;
    PRINTER_INFO_4W pi4;
    PRINTER_INFO_5W pi5;
//    PRINTER_INFO_6W pi6;
    PRINTER_INFO_7W pi7;
    PRINTER_INFO_8W pi8;
    PRINTER_INFO_9W pi9;
};

#define DEFAULT_BUFFER_SIZE ((sizeof(union printer_info_all) * 20))

static SV *
wchar_to_sv(pTHX_ const wchar_t *str, size_t wlen) {
    if (str)  {
        size_t len;
        if (!wlen) wlen = wcslen(str);
        if (wlen) {
            len = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, str, wlen,
                                      NULL, 0, NULL, NULL);
            if (len) {
                SV *sv = newSV(len + 2);
                char *pv = SvPVX(sv);
                if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, str, wlen,
                                        pv, len + 1, NULL, NULL) == len) {
                    SvPOK_on(sv);
                    pv[len] = '\0';
                    SvCUR_set(sv, len);
                    SvUTF8_on(sv);
                    return sv;
                }
            }
            Perl_warn(aTHX_ "Unable to convert wide char string to UTF8: %d, str: %p, wlen: %d", GetLastError(), str, wlen);
        }
    }
    return &PL_sv_undef;
}

static wchar_t *
sv_to_wchar(pTHX_ SV *sv) {
    if (SvOK(sv)) {
        STRLEN len;
        char *pv = SvPVutf8(sv, len);
        if (len) {
            wchar_t *buffer = NULL;
            STRLEN wlen = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                              pv, len, NULL, 0);
            if (!wlen) {
                Perl_croak(aTHX_ "Unable to convert UTF8 string to wchar_t*");
                return NULL;
            }

            Newx(buffer, wlen + 1, wchar_t);
            SAVEFREEPV(buffer);
            if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                    pv, len, buffer, wlen) != wlen) {
                Perl_croak(aTHX_ "Unable to convert UTF8 string to wchar_t*");
                return NULL;
            }
            buffer[wlen] = L'\0';
            return buffer;
        }
        return L"";
    }
    return NULL;
}

static SV *
pi1_to_sv(pTHX_ PPRINTER_INFO_1W pi1) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "Flags", newSViv(pi1->Flags));
    hv_stores(hv, "Description", wchar_to_sv(aTHX_ pi1->pDescription, 0));
    hv_stores(hv, "Name", wchar_to_sv(aTHX_ pi1->pName, 0));
    hv_stores(hv, "Comment", wchar_to_sv(aTHX_ pi1->pComment, 0));
    return sv;
}

static SV *
pointl_to_sv(pTHX_ PPOINTL p) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "x", newSViv(p->x));
    hv_stores(hv, "y", newSViv(p->y));
    return sv;
}

static SV *
devmod_to_sv(pTHX_ LPDEVMODEW dm) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    DWORD fields = dm->dmFields;
    hv_stores(hv, "DeviceName", wchar_to_sv(aTHX_ dm->dmDeviceName, 0));
    hv_stores(hv, "SpecVersion", newSViv(dm->dmSpecVersion));
    hv_stores(hv, "DriverVersion", newSViv(dm->dmDriverVersion));
    hv_stores(hv, "Size", newSViv(dm->dmSize));
    hv_stores(hv, "DriverExtra", newSViv(dm->dmDriverExtra));
    hv_stores(hv, "Fields", newSViv(fields));
    if (fields & DM_ORIENTATION)
        hv_stores(hv, "Orientation", newSViv(dm->dmOrientation));
    if (fields & DM_PAPERSIZE)
        hv_stores(hv, "PaperSize", dmpaper_to_sv(aTHX_ dm->dmPaperSize));
    if (fields & DM_PAPERLENGTH)
	hv_stores(hv, "PaperLength", newSViv(dm->dmPaperLength));
    if (fields & DM_PAPERWIDTH)
	hv_stores(hv, "PaperWidth", newSViv(dm->dmPaperWidth));
    if (fields & DM_SCALE)
	hv_stores(hv, "Scale", newSViv(dm->dmScale));
    if (fields & DM_COPIES)
        hv_stores(hv, "Copies", newSViv(dm->dmCopies));
    if (fields & DM_DEFAULTSOURCE)
	hv_stores(hv, "DefaultSource", dmbin_to_sv(aTHX_ dm->dmDefaultSource));
    if (fields & DM_PRINTQUALITY)
	hv_stores(hv, "PrintQuality", dmres_to_sv(aTHX_ dm->dmPrintQuality));
    if (fields & DM_POSITION)
	hv_stores(hv, "Position", SvREFCNT_inc(pointl_to_sv(aTHX_ &dm->dmPosition)));
    if (fields & DM_DISPLAYORIENTATION)
	hv_stores(hv, "DisplayOrientation", dmdo_to_sv(aTHX_ dm->dmDisplayOrientation));
    if (fields & DM_DISPLAYFIXEDOUTPUT)
	hv_stores(hv, "DisplayFixedOutput", dmdfo_to_sv(aTHX_ dm->dmDisplayFixedOutput));
    if (fields & DM_COLOR)
	hv_stores(hv, "Color", dmcolor_to_sv(aTHX_ dm->dmColor));
    if (fields & DM_DUPLEX)
	hv_stores(hv, "Duplex", dmdup_to_sv(aTHX_ dm->dmDuplex));
    if (fields & DM_YRESOLUTION)
	hv_stores(hv, "YResolution", newSViv(dm->dmYResolution));
    if (fields & DM_TTOPTION)
	hv_stores(hv, "TTOption", dmtt_to_sv(aTHX_ dm->dmTTOption));
    if (fields & DM_COLLATE)
	hv_stores(hv, "Collate", dmcollate_to_sv(aTHX_ dm->dmCollate));
    if (fields & DM_FORMNAME)
	hv_stores(hv, "FormName", wchar_to_sv(aTHX_ dm->dmFormName, 0));
    if (fields & DM_LOGPIXELS)
	hv_stores(hv, "LogPixels", newSViv(dm->dmLogPixels));
    if (fields & DM_BITSPERPEL)
	hv_stores(hv, "BitsPerPel", newSViv(dm->dmBitsPerPel));
    if (fields & DM_PELSWIDTH)
	hv_stores(hv, "PelsWidth", newSViv(dm->dmPelsWidth));
    if (fields & DM_PELSHEIGHT)
	hv_stores(hv, "PelsHeight", newSViv(dm->dmPelsHeight));
    if (fields & DM_DISPLAYFLAGS)
	hv_stores(hv, "DisplayFlags", newSViv(dm->dmDisplayFlags));
    if (fields & DM_NUP)
	hv_stores(hv, "Nup", dmnup_to_sv(aTHX_ dm->dmNup));
    if (fields & DM_DISPLAYFREQUENCY)
	hv_stores(hv, "DisplayFrequency", newSViv(dm->dmDisplayFrequency));
#if (WINVER >= 0x0400)
    if (fields & DM_ICMMETHOD)
	hv_stores(hv, "ICMethod", dmicmethod_to_sv(aTHX_ dm->dmICMMethod));
    if (fields & DM_ICMINTENT)
	hv_stores(hv, "ICMIntent", dmicm_to_sv(aTHX_ dm->dmICMIntent));
    if (fields & DM_MEDIATYPE)
	hv_stores(hv, "MediaType", dmmedia_to_sv(aTHX_ dm->dmMediaType));
    if (fields & DM_DITHERTYPE)
	hv_stores(hv, "DitherType", dmdither_to_sv(aTHX_ dm->dmDitherType));
    hv_stores(hv, "Reserved1", newSViv(dm->dmReserved1));
    hv_stores(hv, "Reserved2", newSViv(dm->dmReserved2));
#if (WINVER >= 0x0500) || (_WIN32_WINNT >= 0x0400)
    if (fields & DM_PANNINGWIDTH)
	hv_stores(hv, "PanningWidth", newSViv(dm->dmPanningWidth));
    if (fields & DM_PANNINGHEIGHT)
	hv_stores(hv, "PanningHeight", newSViv(dm->dmPanningHeight));
#endif
#endif
    return sv;
}

static SV *
pi2_to_sv(pTHX_ PPRINTER_INFO_2W pi2) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "ServerName", wchar_to_sv(aTHX_ pi2->pServerName, 0));
    hv_stores(hv, "PrinterName", wchar_to_sv(aTHX_ pi2->pPrinterName, 0));
    hv_stores(hv, "ShareName", wchar_to_sv(aTHX_ pi2->pShareName, 0));
    hv_stores(hv, "PortName", wchar_to_sv(aTHX_ pi2->pPortName, 0));
    hv_stores(hv, "DriverName", wchar_to_sv(aTHX_ pi2->pDriverName, 0));
    hv_stores(hv, "Comment", wchar_to_sv(aTHX_ pi2->pComment, 0));
    hv_stores(hv, "Location", wchar_to_sv(aTHX_ pi2->pLocation, 0));
    hv_stores(hv, "DevMode", SvREFCNT_inc(devmod_to_sv(aTHX_ pi2->pDevMode)));
    hv_stores(hv, "SetFile", wchar_to_sv(aTHX_ pi2->pSepFile, 0));
    hv_stores(hv, "PrintProcessor", wchar_to_sv(aTHX_ pi2->pPrintProcessor, 0));
    hv_stores(hv, "Datatype", wchar_to_sv(aTHX_ pi2->pDatatype, 0));
    hv_stores(hv, "Parameters", wchar_to_sv(aTHX_ pi2->pParameters, 0));
    // PSECURITY_DESCRIPTOR pSecurityDescriptor;
    hv_stores(hv, "Attributes", newSViv(pi2->Attributes));
    hv_stores(hv, "Priority", newSViv(pi2->Priority));
    hv_stores(hv, "DefaultPriority", newSViv(pi2->DefaultPriority));
    hv_stores(hv, "StartTime", newSViv(pi2->StartTime));
    hv_stores(hv, "UntilTime", newSViv(pi2->UntilTime));
    hv_stores(hv, "Status", status_to_sv(aTHX_ pi2->Status));
    hv_stores(hv, "cJobs", newSViv(pi2->cJobs));
    hv_stores(hv, "AveragePPM", newSViv(pi2->AveragePPM));
    return sv;
}

/* TODO... */
// SV *pi3_to_sv(pTHX_ PPRINTER_INFO_3W pi3) { return &PL_sv_undef; }

static SV *
pi4_to_sv(pTHX_ PPRINTER_INFO_4W pi4) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "PrinterName", wchar_to_sv(aTHX_ pi4->pPrinterName, 0));
    hv_stores(hv, "ServerName", wchar_to_sv(aTHX_ pi4->pServerName, 0));
    hv_stores(hv, "Attributes", newSViv(pi4->Attributes));
    return sv;
}


static SV *
pi5_to_sv(pTHX_ PPRINTER_INFO_5W pi5) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "PrinterName", wchar_to_sv(aTHX_ pi5->pPrinterName, 0));
    hv_stores(hv, "PortName", wchar_to_sv(aTHX_ pi5->pPortName, 0));
    hv_stores(hv, "Attributes", newSViv(pi5->Attributes));
    hv_stores(hv, "DeviceNotSelectedTimeout", newSViv(pi5->DeviceNotSelectedTimeout));
    hv_stores(hv, "TransmissionRetryTimeout", newSViv(pi5->TransmissionRetryTimeout));
    return sv;
}

// SV *pi6_to_sv(pTHX_ PPRINTER_INFO_6W pi6) { return &PL_sv_undef; }
static SV *pi7_to_sv(pTHX_ PPRINTER_INFO_7W pi7) { return &PL_sv_undef; }
static SV *pi8_to_sv(pTHX_ PPRINTER_INFO_8W pi8) { return &PL_sv_undef; }
static SV *pi9_to_sv(pTHX_ PPRINTER_INFO_9W pi9) { return &PL_sv_undef; }

static SV *
sizel_to_sv(pTHX_ PSIZEL sl) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "cx", newSViv(sl->cx));
    hv_stores(hv, "cy", newSViv(sl->cy));
    return sv;
}

static SV *
rectl_to_sv(pTHX_ PRECTL r) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "left", newSViv(r->left));
    hv_stores(hv, "top", newSViv(r->top));
    hv_stores(hv, "right", newSViv(r->right));
    hv_stores(hv, "bottom", newSViv(r->bottom));
    return sv;
}

static SV *
fi1_to_sv(pTHX_ PFORM_INFO_1W fi1) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    hv_stores(hv, "Flags", formflag_to_sv(aTHX_ fi1->Flags));
    hv_stores(hv, "Name", wchar_to_sv(aTHX_ fi1->pName, 0));
    hv_stores(hv, "Size", SvREFCNT_inc(sizel_to_sv(aTHX_ &fi1->Size)));
    hv_stores(hv, "ImageableArea", SvREFCNT_inc(rectl_to_sv(aTHX_ &fi1->ImageableArea)));
    return sv;
}

static SV *
fi2_to_sv(pTHX_ PFORM_INFO_2W fi2) {
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV*)hv));
    DWORD st = fi2->StringType;
    hv_stores(hv, "Flags", formflag_to_sv(aTHX_ fi2->Flags));
    hv_stores(hv, "Name", wchar_to_sv(aTHX_ fi2->pName, 0));
    hv_stores(hv, "Size", SvREFCNT_inc(sizel_to_sv(aTHX_ &fi2->Size)));
    hv_stores(hv, "ImageableArea", SvREFCNT_inc(rectl_to_sv(aTHX_ &fi2->ImageableArea)));
    hv_stores(hv, "Keyword", newSVpv(fi2->pKeyword, 0));
    hv_stores(hv, "StringType", stringtype_to_sv(aTHX_ st));
    if (st & STRING_MUIDLL) {
        hv_stores(hv, "MuiDll", wchar_to_sv(aTHX_ fi2->pMuiDll, 0));
        hv_stores(hv, "ResourceId", newSViv(fi2->dwResourceId));
    }
    if (st & STRING_LANGPAIR) {
        hv_stores(hv, "DisplayName", wchar_to_sv(aTHX_ fi2->pDisplayName, 0));
        hv_stores(hv, "LangId", newSViv(fi2->wLangId));
    }
    return sv;
}

MODULE = Win32::EnumPrinters		PACKAGE = Win32::EnumPrinters

BOOT:
    boot_constants(aTHX);

void
EnumPrinters(SV *flags = &PL_sv_undef, SV *name = &PL_sv_undef, IV level = 2)
PREINIT:
    IV flags_iv;
    wchar_t *name_wchar;
    DWORD buffer_size = DEFAULT_BUFFER_SIZE;
PPCODE:
    flags_iv = (SvOK(flags) ? sv_to_enum(aTHX_ flags) : PRINTER_ENUM_LOCAL);
    name_wchar = (SvOK(name) ? sv_to_wchar(aTHX_ name) : NULL);
    while (1) {
        DWORD required = 0;
        DWORD items = 0;
        LPBYTE buffer = NULL;
        Newx(buffer, buffer_size, BYTE);
        SAVEFREEPV(buffer);
        if (EnumPrintersW(flags_iv, name_wchar, level,
                          buffer, buffer_size,
                          &required, &items)) {
            DWORD i;
            for (i = 0; i < items; i++) {
                SV *sv;
                switch (level) {
                case 1:
                    sv = pi1_to_sv(aTHX_ (PPRINTER_INFO_1W)buffer + i);
                    break;
                case 2:
                    sv = pi2_to_sv(aTHX_ (PPRINTER_INFO_2W)buffer + i);
                    break;
                    /* case 3:
                    sv = pi3_to_sv(aTHX_ (PPRINTER_INFO_3W)buffer + i);
                    break; */
                case 4:
                    sv = pi4_to_sv(aTHX_ (PPRINTER_INFO_4W)buffer + i);
                    break;
                case 5:
                    sv = pi5_to_sv(aTHX_ (PPRINTER_INFO_5W)buffer + i);
                    break;
                default:
                    Perl_warn(aTHX_ "level %d not supported", level);
                    sv = &PL_sv_undef;
                    break;
                }
                XPUSHs(sv);
            }
            XSRETURN(items);
        }
        else {
            if (required > buffer_size) {
                buffer_size = required;
                continue;
            }
            XSRETURN(0);
        }
    }

SV *
GetDefaultPrinter()
PREINIT:
    DWORD len = 0;
CODE:
    RETVAL = &PL_sv_undef;
    GetDefaultPrinterW(NULL, &len);
    if (len) {
        wchar_t *buffer;
        Newx(buffer, len + 2, wchar_t);
        if (GetDefaultPrinterW(buffer, &len))
            RETVAL = wchar_to_sv(aTHX_ buffer, 0);
    }
OUTPUT:
    RETVAL

void
EnumForms(SV *printer, int level = 2)
PREINIT:
    wchar_t *printer_wchar;
    HANDLE handle = 0;
    DWORD returned = 0;
PPCODE:
    printer_wchar = sv_to_wchar(aTHX_ printer);
    if (OpenPrinterW(printer_wchar, &handle, NULL)) {
        DWORD buffer_size = DEFAULT_BUFFER_SIZE;
        while(1) {
            DWORD required = 0;
            LPBYTE buffer = NULL;
            Newx(buffer, buffer_size, BYTE);
            SAVEFREEPV(buffer);
            if (EnumFormsW(handle, level, buffer, buffer_size, &required, &returned)) {
                int i;
                for (i = i; i < returned; i++) {
                    SV *sv;
                    switch(level) {
                    case 1:
                        sv = fi1_to_sv(aTHX_ (PFORM_INFO_1W)buffer + i);
                        break;
                    case 2:
                        sv = fi2_to_sv(aTHX_ (PFORM_INFO_2W)buffer + i);
                        break;
                    default:
                        Perl_warn(aTHX_ "level %d not supported", level);
                        sv = &PL_sv_undef;
                        break;
                    }
                    XPUSHs(sv);
                }
            }
            else {
                if (required > buffer_size) {
                    buffer_size = required;
                    continue;
                }
            }
            break;
        }
        ClosePrinter(handle);
    }
    XSRETURN(returned);
