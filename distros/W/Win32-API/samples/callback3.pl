$| = 1;

use blib;
use Win32::API;
use Win32::API::Callback;

Win32::API::Struct->typedef(
    'LOGFONT', qw(
        LONG lfHeight;
        LONG lfWidth;
        LONG lfEscapement;
        LONG lfOrientation;
        LONG lfWeight;
        BYTE lfItalic;
        BYTE lfUnderline;
        BYTE lfStrikeOut;
        BYTE lfCharSet;
        BYTE lfOutPrecision;
        BYTE lfClipPrecision;
        BYTE lfQuality;
        BYTE lfPitchAndFamily;
        TCHAR lfFaceName[32];
        )
);

Win32::API::Struct->typedef(
    'NEWTEXTMETRIC', qw(
        LONG   tmHeight;
        LONG   tmAscent;
        LONG   tmDescent;
        LONG   tmInternalLeading;
        LONG   tmExternalLeading;
        LONG   tmAveCharWidth;
        LONG   tmMaxCharWidth;
        LONG   tmWeight;
        LONG   tmOverhang;
        LONG   tmDigitizedAspectX;
        LONG   tmDigitizedAspectY;
        TCHAR  tmFirstChar;
        TCHAR  tmLastChar;
        TCHAR  tmDefaultChar;
        TCHAR  tmBreakChar;
        BYTE   tmItalic;
        BYTE   tmUnderlined;
        BYTE   tmStruckOut;
        BYTE   tmPitchAndFamily;
        BYTE   tmCharSet;
        DWORD  ntmFlags;
        UINT   ntmSizeEM;
        UINT   ntmCellHeight;
        UINT   ntmAvgWidth;
        )
);

Win32::API::Struct->typedef(
    'ENUMLOGFONT', qw(
        LOGFONT  elfLogFont;
        BYTE     elfFullName[64];
        BYTE     elfStyle[32];
        )
);

my $sub = sub {

    my ($lpelf, $lpntm, $FontType, $lparam) = @_;

    print "LPELF.lfFaceName  = '$lpelf->{elfLogFont}->{lfFaceName}'\n";

    return 1;
};

my $EnumFontFamProc = Win32::API::Callback->new($sub, "SSNN", "N");

$EnumFontFamProc->{intypes} = [
    qw(
        ENUMLOGFONT
        NEWTEXTMETRIC
        DWORD
        DWORD
        )
];

Win32::API->Import("gdi32", "CreateDC",         "PPPP", "N");
Win32::API->Import("gdi32", "EnumFontFamilies", "NPKN", "N");

$hdc = CreateDC("DISPLAY", 0, 0, 0);

EnumFontFamilies($hdc, "Arial", $EnumFontFamProc, 42);
print "everything is fine.\n";
