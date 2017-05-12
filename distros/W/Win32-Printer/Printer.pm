#------------------------------------------------------------------------------#
# Win32::Printer                                                               #
# V 0.9.1 (2008-04-28)                                                         #
# Copyright (C) 2003-2005 Edgars Binans                                        #
#------------------------------------------------------------------------------#

package Win32::Printer;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD $_debuglevel $_numcroaked );

$VERSION = '0.9.1';

@ISA = qw( Exporter );

@EXPORT = qw(

	EB_EMF EB_25MATRIX EB_25INTER EB_25IND EB_25IATA EB_27 EB_39STD EB_39EXT
	EB_39DUMB EB_93 EB_128SMART EB_128A EB_128B EB_128C EB_128SHFT EB_128EAN
	EB_EAN13 EB_UPCA EB_EAN8 EB_UPCE EB_ISBN EB_ISBN2 EB_ISSN EB_AD2 EB_AD5
	EB_CHK EB_TXT

	LETTER LETTERSMALL TABLOID LEDGER LEGAL STATEMENT EXECUTIVE A3 A4
	A4SMALL A5 B4 B5 FOLIO QUARTO IN_10X14 IN_11X17 NOTE ENV_9 ENV_10
	ENV_11 ENV_12 ENV_14 CSHEET DSHEET ESHEET ENV_DL ENV_C5 ENV_C3 ENV_C4
	ENV_C6 ENV_C65 ENV_B4 ENV_B5 ENV_B6 ENV_ITALY ENV_MONARCH ENV_PERSONAL
	FANFOLD_US FANFOLD_STD_GERMAN FANFOLD_LGL_GERMAN ISO_B4
	JAPANESE_POSTCARD IN_9X11 IN_10X11 IN_15X11 ENV_INVITE RESERVED_48
	RESERVED_49 LETTER_EXTRA LEGAL_EXTRA TABLOID_EXTRA A4_EXTRA
	LETTER_TRANSVERSE A4_TRANSVERSE LETTER_EXTRA_TRANSVERSE A_PLUS B_PLUS
	LETTER_PLUS A4_PLUS A5_TRANSVERSE B5_TRANSVERSE A3_EXTRA A5_EXTRA
	B5_EXTRA A2 A3_TRANSVERSE A3_EXTRA_TRANSVERSE

	PORTRAIT LANDSCAPE VERTICAL HORIZONTAL

	ALLPAGES SELECTION PAGENUMS NOSELECTION NOPAGENUMS PRINTTOFILE
	PRINTSETUP NOWARNING DISABLEPRINTTOFILE HIDEPRINTTOFILE NONETWORKBUTTON

	NOUPDATECP TOP LEFT UPDATECP RIGHT VCENTER BOTTOM WORDBREAK BASELINE
	SINGLELINE EXPANDTABS NOCLIP EXTERNALLEADING CALCRECT INTERNAL
	EDITCONTROL PATH_ELLIPSIS END_ELLIPSIS MODIFYSTRING RTLREADING
	WORD_ELLIPSIS CENTER JUSTIFY UTF8

	PS_SOLID PS_DASH PS_DOT PS_DASHDOT PS_DASHDOTDOT PS_NULL PS_INSIDEFRAME
	PS_JOIN_ROUND PS_ENDCAP_ROUND PS_ENDCAP_SQUARE PS_ENDCAP_FLAT
	PS_JOIN_BEVEL PS_JOIN_MITER

	HS_HORIZONTAL HS_VERTICAL HS_FDIAGONAL HS_BDIAGONAL HS_CROSS
	HS_DIAGCROSS

	ALTERNATE WINDING

	CR_OFF CR_AND CR_OR CR_XOR CR_DIFF CR_COPY

	ANSI DEFAULT SYMBOL SHIFTJIS HANGEUL GB2312 CHINESEBIG5 OEM JOHAB HEBREW
	ARABIC GREEK TURKISH VIETNAMESE THAI EASTEUROPE RUSSIAN MAC BALTIC

	BIN_ONLYONE BIN_LOWER BIN_MIDDLE BIN_MANUAL BIN_ENVELOPE BIN_ENVMANUAL
	BIN_AUTO BIN_TRACTOR BIN_SMALLFMT BIN_LARGEFMT BIN_LARGECAPACITY
	BIN_CASSETTE BIN_FORMSOURCE

	MONOCHROME COLOR

	DRIVERVERSION HORZSIZE VERTSIZE HORZRES VERTRES BITSPIXEL PLANES
	NUMBRUSHES NUMPENS NUMFONTS NUMCOLORS CURVECAPS LINECAPS POLYGONALCAPS
	TEXTCAPS CLIPCAPS RASTERCAPS ASPECTX ASPECTY ASPECTXY LOGPIXELSX
	LOGPIXELSY SIZEPALETTE NUMRESERVED COLORRES PHYSICALWIDTH
	PHYSICALHEIGHT PHYSICALOFFSETX PHYSICALOFFSETY SCALINGFACTORX
	SCALINGFACTORY

        PSI_BEGINSTREAM PSI_PSADOBE PSI_PAGESATEND PSI_PAGES PSI_DOCNEEDEDRES
        PSI_DOCSUPPLIEDRES PSI_PAGEORDER PSI_ORIENTATION PSI_BOUNDINGBOX
        PSI_PROCESSCOLORS PSI_COMMENTS PSI_BEGINDEFAULTS PSI_ENDDEFAULTS
        PSI_BEGINPROLOG PSI_ENDPROLOG PSI_BEGINSETUP PSI_ENDSETUP PSI_TRAILER
        PSI_EOF PSI_ENDSTREAM PSI_PROCESSCOLORSATEND PSI_PAGENUMBER
        PSI_BEGINPAGESETUP PSI_ENDPAGESETUP PSI_PAGETRAILER PSI_PLATECOLOR
        PSI_SHOWPAGE PSI_PAGEBBOX PSI_ENDPAGECOMMENTS PSI_VMSAVE PSI_VMRESTORE

	FIF_BMP FIF_ICO FIF_JPEG FIF_JNG FIF_KOALA FIF_LBM FIF_IFF FIF_MNG
	FIF_PBM FIF_PBMRAW FIF_PCD FIF_PCX FIF_PGM FIF_PGMRAW FIF_PNG FIF_PPM
	FIF_PPMRAW FIF_RAS FIF_TARGA FIF_TIFF FIF_WBMP FIF_PSD FIF_CUT FIF_XBM
	FIF_XPM FIF_DDS FIF_GIF

	BMP_DEFAULT BMP_SAVE_RLE JPEG_DEFAULT JPEG_QUALITYSUPERB
	JPEG_QUALITYGOOD JPEG_QUALITYNORMAL JPEG_QUALITYAVERAGE JPEG_QUALITYBAD
	PNM_DEFAULT PNM_SAVE_RAW PNM_SAVE_ASCII TIFF_DEFAULT TIFF_CMYK
	TIFF_PACKBITS TIFF_DEFLATE TIFF_ADOBE_DEFLATE TIFF_NONE TIFF_CCITTFAX3
	TIFF_CCITTFAX4TIFF_LZW

      );

@EXPORT_OK = qw( );

require XSLoader;
XSLoader::load('Win32::Printer', $VERSION);

#------------------------------------------------------------------------------#

sub _carp {
  if (!defined($_debuglevel)) { $_debuglevel = 0; }
  my $arg = shift;
  if ($_debuglevel == 1) {
    croak $arg, "(Died on warning!)";
  } else {
    carp $arg;
  }
}

sub _croak {
  if (!defined($_debuglevel)) { $_debuglevel = 0; }
  my $arg = shift;
  if ($_debuglevel == 2) {
    carp $arg, "(Warned on error!)";
  } else {
    croak $arg;
  }
}

#------------------------------------------------------------------------------#

sub AUTOLOAD {

  my $constname = $AUTOLOAD;
  $constname =~ s/.*:://;

  _croak "Unknown Win32::Printer macro $constname.\n";
  return undef;

}

#------------------------------------------------------------------------------#

# "ebbl" modes
sub EB_25MATRIX			{ 0x00000001; }
sub EB_25INTER			{ 0x00000002; }
sub EB_25IND			{ 0x00000004; }
sub EB_25IATA			{ 0x00000008; }
sub EB_27			{ 0x00000010; }
sub EB_39STD			{ 0x00000020; }
sub EB_39EXT			{ 0x00000040; }
sub EB_39DUMB			{ 0x00000080; }
sub EB_93			{ 0x00000100; }
sub EB_128SMART			{ 0x00000200; }
sub EB_128A			{ 0x00000400; }
sub EB_128B			{ 0x00000800; }
sub EB_128C			{ 0x00001000; }
sub EB_128SHFT			{ 0x00002000; }
sub EB_128EAN			{ 0x00004000; }
sub EB_EAN13			{ 0x00008000; }
sub EB_UPCA			{ 0x00010000; }
sub EB_EAN8			{ 0x00020000; }
sub EB_UPCE			{ 0x00040000; }
sub EB_ISBN			{ 0x00080000; }
sub EB_ISBN2			{ 0x00100000; }
sub EB_ISSN			{ 0x00200000; }
sub EB_AD2			{ 0x00400000; }
sub EB_AD5			{ 0x00800000; }
sub EB_CHK			{ 0x01000000; }
sub EB_TXT			{ 0x02000000; }

sub EB_EMF			{ 0x80000000; }

sub FIF_UNKNOWN			{ -1; }
sub FIF_BMP			{ 0; }
sub FIF_ICO			{ 1; }
sub FIF_JPEG			{ 2; }
sub FIF_JNG			{ 3; }
sub FIF_KOALA			{ 4; }
sub FIF_LBM			{ 5; }
sub FIF_IFF			{ FIF_LBM; }
sub FIF_MNG			{ 6; }
sub FIF_PBM			{ 7; }
sub FIF_PBMRAW			{ 8; }
sub FIF_PCD			{ 9; }
sub FIF_PCX			{ 10; }
sub FIF_PGM			{ 11; }
sub FIF_PGMRAW			{ 12; }
sub FIF_PNG			{ 13; }
sub FIF_PPM			{ 14; }
sub FIF_PPMRAW			{ 15; }
sub FIF_RAS			{ 16; }
sub FIF_TARGA			{ 17; }
sub FIF_TIFF			{ 18; }
sub FIF_WBMP			{ 19; }
sub FIF_PSD			{ 20; }
sub FIF_CUT			{ 21; }
sub FIF_XBM			{ 22; }
sub FIF_XPM			{ 23; }
sub FIF_DDS			{ 24; }
sub FIF_GIF			{ 25; }

sub BMP_DEFAULT			{ 0; }
sub BMP_SAVE_RLE		{ 1; }
sub CUT_DEFAULT			{ 0; }
sub DDS_DEFAULT			{ 0; }
sub GIF_DEFAULT			{ 0; }
sub ICO_DEFAULT			{ 0; }
sub ICO_MAKEALPHA		{ 1; }
sub IFF_DEFAULT			{ 0; }
sub JPEG_DEFAULT		{ 0; }
sub JPEG_FAST			{ 1; }
sub JPEG_ACCURATE		{ 2; }
sub JPEG_QUALITYSUPERB		{ 0x80; }
sub JPEG_QUALITYGOOD		{ 0x100; }
sub JPEG_QUALITYNORMAL		{ 0x200; }
sub JPEG_QUALITYAVERAGE		{ 0x400; }
sub JPEG_QUALITYBAD		{ 0x800; }
sub KOALA_DEFAULT		{ 0; }
sub LBM_DEFAULT			{ 0; }
sub MNG_DEFAULT			{ 0; }
sub PCD_DEFAULT			{ 0; }
sub PCD_BASE			{ 1; }
sub PCD_BASEDIV4		{ 2; }
sub PCD_BASEDIV16		{ 3; }
sub PCX_DEFAULT			{ 0; }
sub PNG_DEFAULT			{ 0; }
sub PNG_IGNOREGAMMA		{ 1; }
sub PNM_DEFAULT			{ 0; }
sub PNM_SAVE_RAW		{ 0; }
sub PNM_SAVE_ASCII		{ 1; }
sub PSD_DEFAULT			{ 0; }
sub RAS_DEFAULT			{ 0; }
sub TARGA_DEFAULT		{ 0; }
sub TARGA_LOAD_RGB888		{ 1; }
sub TIFF_DEFAULT		{ 0; }
sub TIFF_CMYK			{ 0x0001; }
sub TIFF_PACKBITS		{ 0x0100; }
sub TIFF_DEFLATE		{ 0x0200; }
sub TIFF_ADOBE_DEFLATE		{ 0x0400; }
sub TIFF_NONE			{ 0x0800; }
sub TIFF_CCITTFAX3		{ 0x1000; }
sub TIFF_CCITTFAX4		{ 0x2000; }
sub TIFF_LZW			{ 0x4000; }
sub WBMP_DEFAULT		{ 0; }
sub XBM_DEFAULT			{ 0; }
sub XPM_DEFAULT			{ 0; }

# Print dialog
sub ALLPAGES			{ 0x00000000; }
sub SELECTION			{ 0x00000001; }
sub PAGENUMS			{ 0x00000002; }
sub NOSELECTION			{ 0x00000004; }
sub NOPAGENUMS			{ 0x00000008; }
sub COLLATE			{ 0x00000010; }
sub PRINTTOFILE			{ 0x00000020; }
sub PRINTSETUP			{ 0x00000040; }
sub NOWARNING			{ 0x00000080; }
sub RETURNDC			{ 0x00000100; }
sub RETURNIC			{ 0x00000200; }
sub RETURNDEFAULT		{ 0x00000400; }
sub SHOWHELP			{ 0x00000800; }
sub ENABLEPRINTHOOK		{ 0x00001000; }
sub ENABLESETUPHOOK		{ 0x00002000; }
sub ENABLEPRINTTEMPLATE		{ 0x00004000; }
sub ENABLESETUPTEMPLATE		{ 0x00008000; }
sub ENABLEPRINTTEMPLATEHANDLE	{ 0x00010000; }
sub ENABLESETUPTEMPLATEHANDLE	{ 0x00020000; }
sub USEDEVMODECOPIES		{ 0x00040000; }
sub USEDEVMODECOPIESANDCOLLATE	{ 0x00040000; }
sub DISABLEPRINTTOFILE		{ 0x00080000; }
sub HIDEPRINTTOFILE		{ 0x00100000; }
sub NONETWORKBUTTON		{ 0x00200000; }

# Paper source bin
sub BIN_ONLYONE			{ 1; }
sub BIN_LOWER			{ 2; }
sub BIN_MIDDLE			{ 3; }
sub BIN_MANUAL			{ 4; }
sub BIN_ENVELOPE		{ 5; }
sub BIN_ENVMANUAL		{ 6; }
sub BIN_AUTO			{ 7; }
sub BIN_TRACTOR			{ 8; }
sub BIN_SMALLFMT		{ 9; }
sub BIN_LARGEFMT		{ 10; }
sub BIN_LARGECAPACITY		{ 11; }
sub BIN_CASSETTE		{ 14; }
sub BIN_FORMSOURCE		{ 15; }

# Printer output color setting
sub MONOCHROME 			{ 1; }
sub COLOR			{ 2; }

# Device caps
sub DRIVERVERSION		{ 0; }
sub TECHNOLOGY			{ 2; }
sub HORZSIZE			{ 4; }
sub VERTSIZE			{ 6; }
sub HORZRES			{ 8; }
sub VERTRES			{ 10; }
sub BITSPIXEL			{ 12; }
sub PLANES			{ 14; }
sub NUMBRUSHES			{ 16; }
sub NUMPENS			{ 18; }
sub NUMMARKERS			{ 20; }
sub NUMFONTS			{ 22; }
sub NUMCOLORS			{ 24; }
sub PDEVICESIZE			{ 26; }
sub CURVECAPS			{ 28; }
sub LINECAPS			{ 30; }
sub POLYGONALCAPS		{ 32; }
sub TEXTCAPS			{ 34; }
sub CLIPCAPS			{ 36; }
sub RASTERCAPS			{ 38; }
sub ASPECTX			{ 40; }
sub ASPECTY			{ 42; }
sub ASPECTXY			{ 44; }
sub LOGPIXELSX			{ 88; }
sub LOGPIXELSY			{ 90; }
sub SIZEPALETTE			{ 104; }
sub NUMRESERVED			{ 106; }
sub COLORRES			{ 108; }
sub PHYSICALWIDTH		{ 110; }
sub PHYSICALHEIGHT		{ 111; }
sub PHYSICALOFFSETX		{ 112; }
sub PHYSICALOFFSETY		{ 113; }
sub SCALINGFACTORX		{ 114; }
sub SCALINGFACTORY		{ 115; }

# Text output flags

sub NOUPDATECP			{ 0x00000000; }	#
sub TOP				{ 0x00000000; }	#
sub LEFT			{ 0x00000000; }	#
sub UPDATECP			{ 0x00000001; }	#
sub RIGHT			{ 0x00000002; }	#
sub VCENTER			{ 0x00000004; }
sub BOTTOM			{ 0x00000008; }	#
sub WORDBREAK			{ 0x00000010; }
sub BASELINE			{ 0x00000018; }	#
sub SINGLELINE			{ 0x00000020; }
sub EXPANDTABS			{ 0x00000040; }
sub TABSTOP			{ 0x00000080; }
sub NOCLIP			{ 0x00000100; }
sub EXTERNALLEADING		{ 0x00000200; }
sub CALCRECT			{ 0x00000400; }
sub INTERNAL			{ 0x00001000; }
sub EDITCONTROL			{ 0x00002000; }
sub PATH_ELLIPSIS		{ 0x00004000; }
sub END_ELLIPSIS		{ 0x00008000; }
sub MODIFYSTRING		{ 0x00010000; }
sub RTLREADING			{ 0x00020000; }	# Modify 1
sub WORD_ELLIPSIS		{ 0x00040000; }
sub CENTER			{ 0x00080000; }	# Modify 2

sub UTF8			{ 0x40000000; }
sub JUSTIFY			{ 0x80000000; }

# Pen styles
sub PS_DASH			{ 0x00000001; }
sub PS_DOT			{ 0x00000002; }
sub PS_DASHDOT			{ 0x00000003; }
sub PS_DASHDOTDOT		{ 0x00000004; }
sub PS_NULL			{ 0x00000005; }
sub PS_INSIDEFRAME		{ 0x00000006; }
sub PS_SOLID			{ 0x00010000; }
sub PS_JOIN_ROUND		{ 0x00010000; }
sub PS_ENDCAP_ROUND		{ 0x00010000; }
sub PS_ENDCAP_SQUARE		{ 0x00010100; }
sub PS_ENDCAP_FLAT		{ 0x00010200; }
sub PS_JOIN_BEVEL		{ 0x00011000; }
sub PS_JOIN_MITER		{ 0x00012000; }

# Brush styles
sub BS_SOLID			{ 0; }
sub BS_NULL			{ 1; }
sub BS_HOLLOW			{ 1; }
sub BS_HATCHED			{ 2; }
sub BS_PATTERN			{ 3; }
sub BS_DIBPATTERN		{ 5; }
sub BS_DIBPATTERNPT		{ 6; }
sub BS_PATTERN8X8		{ 7; }
sub BS_DIBPATTERN8X8		{ 8; }

# Brush hatches
sub HS_HORIZONTAL		{ 0; }
sub HS_VERTICAL			{ 1; }
sub HS_FDIAGONAL		{ 2; }
sub HS_BDIAGONAL		{ 3; }
sub HS_CROSS			{ 4; }
sub HS_DIAGCROSS		{ 5; }

# Path modes
sub CR_OFF			{ 0; }
sub CR_AND			{ 1; }
sub CR_OR			{ 2; }
sub CR_XOR			{ 3; }
sub CR_DIFF			{ 4; }
sub CR_COPY			{ 5; }

# Fill modes
sub ALTERNATE			{ 1; }
sub WINDING			{ 2; }

# Duplexing
sub SIMPLEX			{ 1; }
sub VERTICAL 			{ 2; }
sub HORIZONTAL			{ 3; }

# Paper sizes
sub LETTER			{ 1; }
sub LETTERSMALL			{ 2; }
sub TABLOID			{ 3; }
sub LEDGER			{ 4; }
sub LEGAL			{ 5; }
sub STATEMENT			{ 6; }
sub EXECUTIVE			{ 7; }
sub A3				{ 8; }
sub A4				{ 9; }
sub A4SMALL			{ 10; }
sub A5				{ 11; }
sub B4				{ 12; }
sub B5				{ 13; }
sub FOLIO			{ 14; }
sub QUARTO			{ 15; }
sub IN_10X14			{ 16; }
sub IN_11X17			{ 17; }
sub NOTE			{ 18; }
sub ENV_9			{ 19; }
sub ENV_10			{ 20; }
sub ENV_11			{ 21; }
sub ENV_12			{ 22; }
sub ENV_14			{ 23; }
sub CSHEET			{ 24; }
sub DSHEET			{ 25; }
sub ESHEET			{ 26; }
sub ENV_DL			{ 27; }
sub ENV_C5			{ 28; }
sub ENV_C3			{ 29; }
sub ENV_C4			{ 30; }
sub ENV_C6			{ 31; }
sub ENV_C65			{ 32; }
sub ENV_B4			{ 33; }
sub ENV_B5			{ 34; }
sub ENV_B6			{ 35; }
sub ENV_ITALY			{ 36; }
sub ENV_MONARCH			{ 37; }
sub ENV_PERSONAL		{ 38; }
sub FANFOLD_US			{ 39; }
sub FANFOLD_STD_GERMAN		{ 40; }
sub FANFOLD_LGL_GERMAN		{ 41; }
sub ISO_B4			{ 42; }
sub JAPANESE_POSTCARD		{ 43; }
sub IN_9X11			{ 44; }
sub IN_10X11			{ 45; }
sub IN_15X11			{ 46; }
sub ENV_INVITE			{ 47; }
sub RESERVED_48			{ 48; }
sub RESERVED_49			{ 49; }
sub LETTER_EXTRA		{ 50; }
sub LEGAL_EXTRA			{ 51; }
sub TABLOID_EXTRA		{ 52; }
sub A4_EXTRA			{ 53; }
sub LETTER_TRANSVERSE		{ 54; }
sub A4_TRANSVERSE		{ 55; }
sub LETTER_EXTRA_TRANSVERSE	{ 56; }
sub A_PLUS			{ 57; }
sub B_PLUS			{ 58; }
sub LETTER_PLUS			{ 59; }
sub A4_PLUS			{ 60; }
sub A5_TRANSVERSE		{ 61; }
sub B5_TRANSVERSE		{ 62; }
sub A3_EXTRA			{ 63; }
sub A5_EXTRA			{ 64; }
sub B5_EXTRA			{ 65; }
sub A2				{ 66; }
sub A3_TRANSVERSE		{ 67; }
sub A3_EXTRA_TRANSVERSE		{ 68; }

# Paper orientation
sub PORTRAIT			{ 1; }
sub LANDSCAPE			{ 2; }

# Character sets
sub ANSI			{ 0; }
sub DEFAULT			{ 1; }
sub SYMBOL			{ 2; }
sub SHIFTJIS			{ 128; }
sub HANGEUL			{ 129; }
sub GB2312			{ 134; }
sub CHINESEBIG5			{ 136; }
sub OEM				{ 255; }

sub JOHAB			{ 130; }
sub HEBREW			{ 177; }
sub ARABIC			{ 178; }
sub GREEK			{ 161; }
sub TURKISH			{ 162; }
sub VIETNAMESE			{ 163; }
sub THAI			{ 222; }
sub EASTEUROPE			{ 238; }
sub RUSSIAN			{ 204; }

sub MAC				{ 77; }
sub BALTIC			{ 186; }

sub FW_NORMAL			{ 400; }
sub FW_BOLD			{ 700; }

# Injection of PostScript

sub PSI_BEGINSTREAM		{ 1; }
sub PSI_PSADOBE			{ 2; }
sub PSI_PAGESATEND		{ 3; }
sub PSI_PAGES			{ 4; }
sub PSI_DOCNEEDEDRES		{ 5; }
sub PSI_DOCSUPPLIEDRES		{ 6; }
sub PSI_PAGEORDER		{ 7; }
sub PSI_ORIENTATION		{ 8; }
sub PSI_BOUNDINGBOX		{ 9; }
sub PSI_PROCESSCOLORS		{ 10; }
sub PSI_COMMENTS		{ 11; }
sub PSI_BEGINDEFAULTS		{ 12; }
sub PSI_ENDDEFAULTS		{ 13; }
sub PSI_BEGINPROLOG		{ 14; }
sub PSI_ENDPROLOG		{ 15; }
sub PSI_BEGINSETUP		{ 16; }
sub PSI_ENDSETUP		{ 17; }
sub PSI_TRAILER			{ 18; }
sub PSI_EOF			{ 19; }
sub PSI_ENDSTREAM		{ 20; }
sub PSI_PROCESSCOLORSATEND	{ 21; }

sub PSI_PAGENUMBER		{ 100; }
sub PSI_BEGINPAGESETUP		{ 101; }
sub PSI_ENDPAGESETUP		{ 102; }
sub PSI_PAGETRAILER		{ 103; }
sub PSI_PLATECOLOR		{ 104; }
sub PSI_SHOWPAGE		{ 105; }
sub PSI_PAGEBBOX		{ 106; }
sub PSI_ENDPAGECOMMENTS		{ 107; }
sub PSI_VMSAVE			{ 200; }
sub PSI_VMRESTORE		{ 201; }

#------------------------------------------------------------------------------#

sub new {

  my $class = shift;

  my $self = { };

  bless($self, $class);

  if ($self->_init(@_)) {
    return $self;
  } else {
    _croak qq^ERROR: Cannot initialise object!\n^;
    return undef;
  }

}

#------------------------------------------------------------------------------#

sub _init {

  my $self = shift;

  (%{$self->{params}}) = @_;

  for (keys %{$self->{params}}) {
    if ($_ !~ /^debug$|^dc$|^printer$|^dialog$|^file$|^pdf$|^prompt$|^copies$|^collate$|^minp$|^maxp$|^orientation$|^papersize$|^duplex$|^description$|^unit$|^source$|^color$|^height$|^width$/) {
      _carp qq^WARNING: Unknown attribute "$_"!\n^;
    }
  }

  $_numcroaked = 0;

  if ((!_num($self->{params}->{'debug'})) or ($self->{params}->{'debug'} > 2)) {
    $_debuglevel = 0;
  } else {
    $_debuglevel = $self->{params}->{'debug'};
  }

  my $dialog;
  if (_num($self->{params}->{'dialog'})) {
    $dialog = 1;
  } else {
    $dialog = 0;
    $self->{params}->{'dialog'} = 0;
  }

  if (defined($self->{params}->{'file'})) {
    $self->{params}->{'file'} =~ s/\//\\/g;
    my $file = $self->{params}->{'file'};
    $file =~ s/(.*\\)//g;
    my $dir = $1;
    unless ($dir) { $dir = '.\\'; }
    if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
      _croak "ERROR: Cannot create printer object! Invalid filename\n";
      return undef;
    }
  }

  unless (defined $self->{params}->{'printer'})	{ $self->{params}->{'printer'}	 = ""; } else { $self->{params}->{'printer'} =~ s/\//\\/g; }
  unless (_num($self->{params}->{'copies'}))	{ $self->{params}->{'copies'}	 = 1;  }
  unless (_num($self->{params}->{'collate'}))	{ $self->{params}->{'collate'}	 = 1;  }
  unless (_num($self->{params}->{'minp'}))	{ $self->{params}->{'minp'}	 = 0;  }
  unless (_num($self->{params}->{'maxp'}))	{ $self->{params}->{'maxp'}	 = 0;  }
  unless (_num($self->{params}->{'orientation'}))	{ $self->{params}->{'orientation'} = 0;  }
  unless (_num($self->{params}->{'papersize'}))	{ $self->{params}->{'papersize'}	 = 0;  }
  unless (_num($self->{params}->{'duplex'}))	{ $self->{params}->{'duplex'}	 = 0;  }
  unless (_num($self->{params}->{'source'}))	{ $self->{params}->{'source'}	 = 7;  }
  unless (_num($self->{params}->{'color'}))	{ $self->{params}->{'color'}	 = 2;  }
  unless (_num($self->{params}->{'height'}))	{ $self->{params}->{'height'}	 = 0;  }
  unless (_num($self->{params}->{'width'}))	{ $self->{params}->{'width'}	 = 0;  }
  unless (defined($self->{params}->{'unit'}))	{ $self->{params}->{'unit'}	 = 1;  }

  return undef if $_numcroaked;

  if (($self->{params}->{'width'}) and (!$self->{params}->{'height'})) {
    $self->{params}->{'width'} = 0;
    _carp qq^WARNING: width attribute used without height attribute - IGNORED!\n^;
  }
  if ((!$self->{params}->{'width'}) and ($self->{params}->{'height'})) {
    $self->{params}->{'height'} = 0;
    _carp qq^WARNING: height attribute used without width attribute - IGNORED!\n^;
  }

  if (($self->{params}->{'width'} > 0) and ($self->{params}->{'height'} > 0)) {
    if (defined($self->{params}->{'unit'})) {
      if ($self->{params}->{'unit'} eq "mm") {
        $self->{params}->{'width'} *= 10;
        $self->{params}->{'height'} *= 10;
      } elsif ($self->{params}->{'unit'} eq "cm") {
        $self->{params}->{'width'} *= 100;
        $self->{params}->{'height'} *= 100;
      } elsif ($self->{params}->{'unit'} eq "pt") {
        $self->{params}->{'width'} *= 254.09836 / 72;
        $self->{params}->{'height'} *= 254.09836 / 72;
      } elsif ($self->{params}->{'unit'} =~ /^\d+\.*\d*$/i) {
        $self->{params}->{'width'} *= 254.09836 / $self->{params}->{'unit'};
        $self->{params}->{'height'} *= 254.09836 / $self->{params}->{'unit'};
      } else {
        $self->{params}->{'width'} *= 254.09836;
        $self->{params}->{'height'} *= 254.09836;
      }
    } else {
      $self->{params}->{'width'} *= 254.09836;
      $self->{params}->{'height'} *= 254.09836;
    }
  } elsif (($self->{params}->{'width'} < 0) or ($self->{params}->{'height'} < 0)) {
    $self->{params}->{'width'} = 0;
    $self->{params}->{'height'} = 0;
    _carp qq^WARNING: height, width attributes may not have negative values - IGNORED!\n^;
  }

  if (($dialog) and ((defined($self->{params}->{'prompt'})) or (defined($self->{params}->{'file'})))) {
    $self->{params}->{'dialog'} = $self->{params}->{'dialog'} | PRINTTOFILE;
    undef $self->{params}->{'prompt'};
  }

  unless(_IsNT()) {
    _carp qq^WARNING: Windows 95/98/ME detected!\n^;
    _carp qq^WARNING: All "Space" tranformations will be ignored!\n^;
  }

  $self->{dc} = _CreatePrinter($self->{params}->{'printer'}, $dialog, $self->{params}->{'dialog'}, $self->{params}->{'copies'}, $self->{params}->{'collate'}, $self->{params}->{'minp'}, $self->{params}->{'maxp'}, $self->{params}->{'orientation'}, $self->{params}->{'papersize'}, $self->{params}->{'duplex'}, $self->{params}->{'source'}, $self->{params}->{'color'}, $self->{params}->{'height'}, $self->{params}->{'width'});
  unless ($self->{dc}) {
    _croak "ERROR: Cannot create printer object! ${\_GetLastError()}";
    return undef;
  }
  $self->{odc} = $self->{dc};

  unless (defined($self->Unit($self->{params}->{'unit'}))) {
    _croak "ERROR: Cannot set default units!\n";
    return undef;
  }

  $self->{xres} = $self->Caps(LOGPIXELSX);
  $self->{yres} = $self->Caps(LOGPIXELSY);

  $self->{xsize} = $self->_xp2un($self->Caps(PHYSICALWIDTH));
  $self->{ysize} = $self->_yp2un($self->Caps(PHYSICALHEIGHT));

  unless (($self->{xres} > 0) && ($self->{yres} > 0)) {
    _croak "ERROR: Cannot get printer resolution! ${\_GetLastError()}";
    return undef;
  }

  $self->{flags} = $self->{params}->{'dialog'};

  if (($self->{flags} & PRINTTOFILE) || (defined($self->{params}->{'prompt'}))) {
    my ($suggest, $indir) = ("", "");
    if (defined($self->{params}->{'file'})) {
      $suggest = $self->{params}->{'file'};
      $suggest =~ s/(.*\\)//g;
      $indir = $1 || "";
    } elsif ((defined($self->{params}->{'description'})) and ($self->{params}->{'description'} ne "")) {
      $suggest = $self->{params}->{'description'};
      $suggest =~ s/[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/-/g;
      $suggest = reverse $suggest;
      $suggest =~ s/^.*?\.//;
      $suggest = reverse $suggest;
      $suggest =~ s/\s\s//g;
    } else {
      $suggest = "Printer";
    }
    if (defined($self->{params}->{'pdf'})) {
      my $ext = $self->{params}->{'file'} ? "" : ".pdf";
      $self->{params}->{'file'} = _SaveAs(2, $suggest.$ext, $indir);
    } else {
      my $ext = $self->{params}->{'file'} ? "" : ".prn";
      $self->{params}->{'file'} = _SaveAs(1, $suggest.$ext, $indir);
    }
    if ($self->{params}->{'file'} eq "") {
      _croak "ERROR: Save to file failed! ${\_GetLastError()}";
      return undef;
    }
  }

  if ((defined($self->{params}->{'pdf'})) and (!defined($self->{params}->{'file'}))) {
    delete $self->{params}->{'pdf'};
    _carp qq^WARNING: pdf attribute used without file attribute - IGNORED!\n^;
  }

  $self->{copies}  = $self->{params}->{'copies'};
  $self->{collate} = $self->{params}->{'collate'};
  $self->{minp}    = $self->{params}->{'minp'};
  $self->{maxp}    = $self->{params}->{'maxp'};

  if (!defined($self->{params}->{'dc'})) {
    unless (defined($self->Start($self->{params}->{description}, $self->{params}->{'file'}))) {
      _croak "ERROR: Cannot start default document!\n";
      return undef;
    }
  }

  unless (defined($self->Pen(1, 0, 0, 0))) {
    _croak "ERROR: Cannot create default pen!\n";
    return undef;
  }
  unless (defined($self->Color(0, 0, 0))) {
    _croak "ERROR: Cannot set default color!\n";
    return undef;
  }
  unless (defined($self->Brush(128, 128, 128))) {
    _croak "ERROR: Cannot create default brush!\n";
    return undef;
  }
  unless (defined($self->Font())) {
    _croak "ERROR: Cannot create default font!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub _num {

  my $val = shift;

  if (defined($val)) {
    if ($val =~ /^\-*\d+\.*\d*$/) {
      return 1;
    } else {
      $_numcroaked = 1;
      _croak qq^ERROR: Argument "$val" isn't numeric!\n^;
      return undef;
    }
  } else {
    return 0;
  }

}

#------------------------------------------------------------------------------#

sub _xun2p {

  my $self = shift;
  my $uval = shift;

  return $uval if $self->{unit} == 0;

  my $pval = $uval * $self->{xres} / $self->{unit};
  return $pval;

}

sub _yun2p {

  my $self = shift;
  my $uval = shift;

  return $uval if $self->{unit} == 0;

  my $pval = $uval * $self->{yres} / $self->{unit};
  return $pval;

}

sub _xp2un {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $uval = ($self->{unit} * $pval) / $self->{xres};
  return $uval;

}

sub _yp2un {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $uval = ($self->{unit} * $pval) / $self->{yres};
  return $uval;

}

sub _pts2p {

  my $self = shift;
  my $ptsval = shift;

  return $ptsval if $self->{unit} == 0;

  my $pval = ($ptsval * $self->{xres}) / 72;
  return $pval;

}

sub _p2pts {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $ptsval = (72 * $pval) / $self->{xres};
  return $ptsval;

}

#------------------------------------------------------------------------------#

sub _pdf {

  my $self = shift;

  if ((defined($self->{params}->{'pdf'})) and (defined($self->{pdfend0}))) {

    if ($self->{params}->{'pdf'} == 0) {
      open OLDERR, ">&STDERR";
      open STDERR, ">nul" or die;
    }
    if ($self->{params}->{'pdf'} == 1) {
      open OLDERR, ">&STDERR" or die;
      open STDERR, ">$self->{pdfend1}.log";
    }

    unless (Win32::Printer::_GhostPDF($self->{pdfend0}, $self->{pdfend1})) {
      if (($self->{params}->{'pdf'} == 0) || ($self->{params}->{'pdf'} == 1)) {
        close STDERR;
        open STDERR, ">&OLDERR";
        close OLDERR;
      }
      return 0;
    }

    if (($self->{params}->{'pdf'} == 0) || ($self->{params}->{'pdf'} == 1)) {
      close STDERR;
      open STDERR, ">&OLDERR";
      close OLDERR;
    }

    unlink $self->{pdfend0};

    undef $self->{pdfend0};
    undef $self->{pdfend1};

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Unit {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  my $unit = shift;

  if (defined($unit)) {
    if ($unit eq "mm") {
      $self->{unit} = 25.409836;
    } elsif ($unit eq "cm") {
      $self->{unit} = 2.5409836;
    } elsif ($unit eq "in") {
      $self->{unit} = 1;
    } elsif ($unit eq "pt") {
      $self->{unit} = 72;
    } elsif ($unit =~ /^\d+\.*\d*$/i) {
      $self->{unit} = $unit;
    } else {
      _carp "WARNING: Invalid unit \"$unit\"! Units set to \"in\".\n";
      $self->{unit} = 1;
    }
  }

  return $self->{unit};

}

#------------------------------------------------------------------------------#

sub Debug {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($#_ == 0) {
    $_numcroaked = 0;
    _num($_[0]);
    return undef if $_numcroaked;
    if (($_[0] > -1) and ($_[0] < 3)) {
      $_debuglevel = shift;
    } else {
      _croak "ERROR: Invalid argument!\n";
    }
  }

  return $_debuglevel;

}

#------------------------------------------------------------------------------#

sub Next {

  my $self = shift;

  if ($self->{emfstate}) {

    if ($#_ > -1) { 
      $self->{emfname} = shift;
      $self->{emfw} = shift;
      $self->{emfh} = shift;
    }

    return ($self->MetaEnd, $self->Meta($self->{emfname}, $self->{emfw}, $self->{emfh}));

  } else {

    if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

    my $desc = shift;
    my $file = shift;

    my $ret = $self->End();

    unless (defined($ret)) {
      _croak "ERROR: Cannot end previous job!\n";
      return undef;
    }
    unless (defined($self->Start($desc, $file))) {
      _croak "ERROR: Cannot start next job!\n";
      return undef;
    }

    return $ret;
  }

}

#------------------------------------------------------------------------------#

sub Start {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Starting document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

  my $desc = shift;
  my $file = shift;

  if ((!defined($file)) and (!defined($self->{params}->{'file'}))) {
    $file = "";
  } else {
    if ((!defined($file)) and (defined($self->{params}->{'file'}))) {
      $file = $self->{params}->{'file'};
    }
    while (-f $file) { 
      if ($file !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
        $file =~ s/(.*\\*)(.*)\./$1$2(1)\./
      }
      $self->{params}->{'file'} = $file;
    }
  }

  if (($file ne "") and (defined($self->{params}->{'pdf'}))) {
    $self->{pdfend1} = $file;
    my $tmp = Win32::Printer::_GetTempPath();
    $file =~ s/.*\\//;
    my $seed = join('', (0..9, 'A'..'Z', 'a'..'z')[rand 62, rand 62, rand 62, rand 62, rand 62, rand 62, rand 62, rand 62]);
    $file = $tmp.$file.".".$seed;
    $self->{pdfend0} = $file;
  }

  unless (_StartDoc($self->{dc}, $desc || $self->{params}->{'description'} || 'Printer', $file) > 0) {
    _croak "ERROR: Cannot start the document! ${\_GetLastError()}";
    return undef;
  }

  unless (_StartPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot start the page! ${\_GetLastError()}";
    return undef;
  }

  unless (defined($self->Space(1, 0, 0, 1, 0, 0))) {
    _croak "ERROR: Cannot reset the document space!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub End {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Ending document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot end the page! ${\_GetLastError()}";
    return undef;
  }

  unless (_EndDoc($self->{dc})) {
    _croak "ERROR: Cannot end the document! ${\_GetLastError()}";
    return undef;
  }

  unless ($self->_pdf()) {
    _croak "ERROR: Cannot create PDF document! ${\_GetLastError()}";
    return undef;
  }

  if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }
  return 1;

}

#------------------------------------------------------------------------------#

sub Abort {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Aborting document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_AbortDoc($self->{dc})) {
    _croak "ERROR: Cannot abort the document! ${\_GetLastError()}";
    return undef;
  }

  if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }

  return 1;

}

#------------------------------------------------------------------------------#

sub Page {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Starting new page not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot end the page! ${\_GetLastError()}";
    return undef;
  }

  unless (_StartPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot start the page! ${\_GetLastError()}";
    return undef;
  }

  unless (defined($self->Space(1, 0, 0, 1, 0, 0))) {
    _croak "ERROR: Cannot reset the page space!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Space {

  my $self = shift;

  if (_IsNT()) {

    if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
    if ($#_ < 5) {
      _croak "ERROR: Not enough actual parameters!\n";
      return undef;
    }

    $_numcroaked = 0;
    for (@_) { _num($_); }
    return undef if $_numcroaked;

    my ($m11, $m12, $m21, $m22, $dx, $dy) = @_;

    my $xoff = $self->Caps(PHYSICALOFFSETX);
    my $yoff = $self->Caps(PHYSICALOFFSETY);

    unless (defined($xoff) && defined($yoff)) {
      _croak "ERROR: Cannot get the physical offset!\n";
      return undef;
    }

    if (_SetWorldTransform($self->{dc}, $m11, $m12, $m21, $m22, $self->_xun2p($dx) - $xoff, $self->_yun2p($dy) - $yoff) == 0) {
      _croak "ERROR: Cannot transform space! ${\_GetLastError()}";
      return undef;
    }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub FontSpace {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  my $space = shift;

  $_numcroaked = 0;
  $space = 0 unless _num($space);
  return undef if $_numcroaked;

  my $return = _SetTextCharacterExtra($self->{dc}, $self->_pts2p($space));
  if ($return == 0x80000000) {
    _croak "ERROR: Cannot change font spacing! ${\_GetLastError()}";
    return undef;
  }

  return $self->_p2pts($return);

}

#------------------------------------------------------------------------------#

sub Font {

  my $self = shift;

  if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }

  if (($#_ == 0) and _IsNo($_[0])) {

    my $prefont;
    unless ($prefont = _SelectObject($self->{dc}, $_[0])) {
      _croak "ERROR: Cannot select font! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($_[0], $prefont) : $_[0];

  } else {

    my ($face, $size, $angle, $charset) = @_;
    my ($escape, $orient);
    if (defined $angle) {
      if ($angle =~ /^ARRAY/) {
        $escape = $$angle[0];
        $orient = $$angle[1];
      } else {
        $escape = $angle;
        $orient = $angle;
      }
    }
    $_numcroaked = 0;
    $face = '' if !defined $face;
    $size = 10 unless _num($size);
    $escape = 0 unless _num($escape);
    $orient = 0 unless _num($orient);
    $charset = 1 unless _num($charset);
    return undef if $_numcroaked;

    my $fontid = "$face\_$size\_$escape\_$orient\_$charset";

    if (!$self->{obj}->{$fontid}) {

      $escape *= 10;
      $orient *= 10;
    
      my ($opt1, $opt2, $opt3, $opt4) = (FW_NORMAL, 0, 0, 0);
      if ($face =~ s/ bold//i ) {
        $opt1 = FW_BOLD;
      }
      if ( $face =~ s/ italic//i ){
        $opt2 = 1;
      }
      if ( $face =~ s/ underline//i ){
        $opt3 = 1;
      }
      if ( $face =~ s/ strike//i ){
        $opt4 = 1;
      }

      $face =~ s/^\s*//;
      $face =~ s/\s*$//;

      $self->{obj}->{$fontid} = _CreateFont($self->_pts2p($size), $escape, $orient, $opt1, $opt2, $opt3,
                                            $opt4, $charset, $face);

      if ($self->{obj}->{$fontid}) {

        my $prefont;
        unless ($prefont = _SelectObject($self->{dc}, $self->{obj}->{$fontid})) {
          _croak "ERROR: Cannot select font! ${\_GetLastError()}";
          return undef;
        }

        my $realface = _GetTextFace($self->{dc});
        if (($face) && ($realface !~ /^$face$/)) {
          _carp "WARNING: Cannot select desired font face - \"$realface\" selected!\n";
        }

        return wantarray ? ($self->{obj}->{$fontid}, $prefont) : $self->{obj}->{$fontid};

      } else {
        _croak "ERROR: Cannot create font! ${\_GetLastError()}";
        return undef;
      }

    } else {	# Fix by Sandor Patocs;

      my $prefont;
      unless ($prefont = _SelectObject($self->{dc}, $self->{obj}->{$fontid})) {
        _croak "ERROR: Cannot select font! ${\_GetLastError()}";
        return undef;
      }
      return wantarray ? ($self->{obj}->{$fontid}, $prefont) : $self->{obj}->{$fontid};

    }

  }

}

#------------------------------------------------------------------------------#

sub FontEnum {

  my $self = shift;

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

  my ($face, $charset) = @_;

  $face = '' if !defined $face;
  $charset = 1 unless _num($charset);

  my $return = _FontEnum($self->{dc}, $face, $charset);

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{Face},
        $return[$i]{Charset},
        $return[$i]{Style},
        $return[$i]{Type}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

#------------------------------------------------------------------------------#

sub Fit {

  my $self = shift;

  if ($#_ > 2) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $string = shift;
  my $ext = shift;
  my $vers = shift;

  $_numcroaked = 0;
  _num($ext);
  $vers = 0 unless _num($vers);
  return undef if $_numcroaked;

  if ($vers & 0x40000000) {
    $vers = 1;
  }

  $ext = $self->_xun2p($ext);
  my ($fit, $cx, $cy) = (0, 0, 0);

  unless (_GetTextExtentPoint($vers, $self->{dc}, $string, $ext, $fit, $cx, $cy)) {
    _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
    return undef;
  }

  return wantarray ? ($fit, $self->_xp2un($cx), $self->_yp2un($cy)) : $fit;

}

#------------------------------------------------------------------------------#

sub Write {

  my $self = shift;

  if ($#_ > 6) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 2) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  if (!defined($_[0]) || ($_[0] eq '')) {
    return wantarray ? (0, 0, 0, '') : 0;
  }

  if ((($#_ > 1) and ($#_ < 4)) or (($_[3] & 0x80000000) and ($#_ == 4))) {

    my ($string, $x, $y, $align) = @_;

    unless (defined($string)) { $string = ''; }

    $_numcroaked = 0;
    for ($x, $y, $align) {
      _num($_);
    }
    return undef if $_numcroaked;

    unless ($align) { $align = LEFT; }

    if ($align & 0x00020000) { $align = $align & ~0x00020000 | 0x00000100; }
    if ($align & 0x00080000) { $align = $align & ~0x00080000 | 0x00000006; }

    my $vers = 0;
    if ($align & 0x40000000) {
      $align &= ~0x40000000;
      $vers = 1;
    }

    if ($align & 0x80000000) {
      unless(_num($_[4])) {
        _croak "ERROR: Cannot set text justification! Wrong justification width\n";
        return undef;
      }
      my $width = $self->_xun2p($_[4]);

      unless (_SetJustify($vers, $self->{dc}, $string, $width)) {
        _croak "ERROR: Cannot set text justification! ${\_GetLastError()}";
        return undef;
      }
    }

    my ($retval, $retw, $reth);
    unless ($retval = _TextOut($vers, $self->{dc}, $self->_xun2p($x), $self->_yun2p($y), $string, $align & ~0x80000000)) {
      _croak "ERROR: Cannot write text! ${\_GetLastError()}";
      return undef;
    }
    $retw = 0x0000FFFF & $retval;
    $reth = (0xFFFF0000 & $retval) >> 16;

    if ($align & 0x80000000) {
      unless (_SetJustify($vers, $self->{dc}, "", -1)) {
        _croak "ERROR: Cannot unset text justification! ${\_GetLastError()}";
        return undef;
      }
    }

    return wantarray ? ($self->_xp2un($retw), $self->_yp2un($reth)) : $self->_yp2un($reth);

  } else {

    my ($string, $x, $y, $w, $h, $f, $tab) = @_;

    unless (defined($string)) { $string = ''; }

    $_numcroaked = 0;
    for ($x, $y, $w, $h, $f, $tab) {
      _num($_);
    }
    $f = 0 unless _num($f);
    $tab = 8 unless _num($tab);
    return undef if $_numcroaked;

    my $height;
    my $len = 0;
    my $width = $self->_xun2p($x + $w);

    if ($f & 0x00080000) { $f = $f & ~0x00080000 | 0x00000001; }

    my $vers = 0;
    if ($f & 0x40000000) {
      $f &= ~0x40000000;
      $vers = 1;
    }
    $height = _DrawText($vers, $self->{dc}, $string,
			$self->_xun2p($x), $self->_yun2p($y),
			$width, $self->_yun2p($y + $h),
			$f, $len, $tab);

    unless ($height) {
      _croak "ERROR: Cannot draw text! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->_xp2un($width), $self->_yp2un($height), $len, $string) : $self->_yp2un($height);

  }

}

#------------------------------------------------------------------------------#

sub Write2 {

  my $self = shift;

  if ($#_ > 8) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $text = shift;
  my ($x, $y, $w, $flags, $indento, $hspace, $vspace) = @_;

  unless (defined($text)) { $text = ''; }

  $_numcroaked = 0;
  for ($x, $y, $w) {
    _num($_);
  }
  $flags = 0 unless _num($flags);
  $indento = 0 unless _num($indento);
  $hspace = 0 unless _num($hspace);
  $vspace = 0 unless _num($vspace);
  return undef if $_numcroaked;

  my @rows = split(/\n/, $text);

  my ($lf, $proctext) = (0, '');

  my ($vers, $len, $wi, $he) = (0, 0, 0, 0);
  if ($flags & 0x40000000) {
    $flags &= ~0x40000000;
    $vers = 1;
  }
  unless (_GetTextExtentPoint($vers, $self->{dc}, 'W', 1, $len, $wi, $he)) {
    _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
    return undef;
  }

  my $return = _SetTextCharacterExtra($self->{dc}, $self->_pts2p($hspace));
  if ($return == 0x80000000) {
    _croak "ERROR: Cannot change font spacing! ${\_GetLastError()}";
    return undef;
  }

  if ($flags & 0x00080000) {
    $x += $w / 2;
    $indento = 0;
  } elsif ($flags & 0x00000002) {
    $x += $w;
    $indento = 0;
  }

  my $out_wi = 0;

  for my $row (@rows) {

    my $indent = $indento;

    if ($row eq '') {
      $lf += $he;
      $proctext .= "\n";
      next;
    }

    while (length($row)) {

      unless (_GetTextExtentPoint($vers, $self->{dc}, $row, $self->_xun2p($w - $indent), $len, $wi, $he)) {
        _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
        return undef;
      }

      if ($out_wi < $wi) {
        $out_wi = $wi;
      }

      my $corr = 0;

      my $rowenta = substr($row, 0, $len);
      if ($len < length($row)) {
        $rowenta =~ s/\s$//;
        $rowenta = reverse($rowenta);
        $rowenta =~ s/^\S+?([\s\-])/defi($1, \$corr)/e;
        $rowenta = reverse($rowenta);
        if ($flags & 0x80000000) {
          unless (_SetJustify($vers, $self->{dc}, $rowenta, $self->_xun2p($w))) {
            _croak "ERROR: Cannot set text justification! ${\_GetLastError()}";
            return undef;
          }
        }
      }

      unless (_TextOut($vers, $self->{dc}, $self->_xun2p($x + $indent), $self->_yun2p($y) + $lf, $rowenta, $flags & ~0x80000000)) {
        _croak "ERROR: Cannot write text! ${\_GetLastError()}";
        return undef;
      }
      $lf += $he + $self->_yun2p($vspace);

      if ($flags & 0x80000000) {
        unless (_SetJustify($vers, $self->{dc}, "", -1)) {
          _croak "ERROR: Cannot unset text justification! ${\_GetLastError()}";
          return undef;
        }
        $out_wi = $self->_xun2p($w);
      }

      $proctext .= $rowenta."\n";
      $row = substr($row, length($rowenta) + $corr);
      $indent = 0;
    }
  }

  return wantarray ? ($self->_xp2un($out_wi), $self->_yp2un($lf), $proctext) : $self->_yp2un($lf);

  #--------------------

  sub defi {
    if ($_[0] eq "-") {
      ${$_[1]} = 0;
      return "-";
    } else {
      ${$_[1]} = 1;
      return "";
    }
  }
  #--------------------
}

#------------------------------------------------------------------------------#

sub Pen {

  my $self = shift;

  if (($#_ == 0) and _IsNo($_[0])) {

    my $handle = shift;

    my $prepen = _SelectObject($self->{dc}, $handle);
    unless ($prepen) {
      _croak "ERROR: Cannot select pen! ${\_GetLastError()}";
      return undef;
    }

    return $prepen;

  } else {

    my $penid = "pen";

    if ($#_ == -1) {

      if (!$self->{obj}->{$penid}) {

        $self->{obj}->{$penid} = _CreatePen(PS_NULL, 0, 0, 0, 0);

        unless ($self->{obj}->{$penid}) {
          _croak "ERROR: Cannot create pen! ${\_GetLastError()}";
          return undef;
        }

      }

    } else {

      if ($#_ > 4) { _carp "WARNING: Too many actual parameters!\n"; }
      if ($#_ < 3) {
        _croak "ERROR: Not enough actual parameters!\n";
        return undef;
      }

      my ($w, $r, $g, $b, $s) = @_;

      $_numcroaked = 0;
      for ($w, $r, $g, $b, $s) {
        _num($_);
      }
      return undef if $_numcroaked;

      if (!defined($s)) { $s = PS_SOLID; }

      if (0x00010000 & $s) {
        $w = $self->_pts2p($w);
      } else {
        $w = 1;
      }

      $penid = "$w\_$r\_$g\_$b\_$s";

      if (!$self->{obj}->{$penid}) {

        $self->{obj}->{$penid} = _CreatePen($s, $w, $r, $g, $b);

        unless ($self->{obj}->{$penid}) {
          _croak "ERROR: Cannot create pen! ${\_GetLastError()}";
          return undef;
        }

      }

    }

    my $prepen = _SelectObject($self->{dc}, $self->{obj}->{$penid});
    unless ($prepen) {
      _croak "ERROR: Cannot select pen! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->{obj}->{$penid}, $prepen) : $self->{obj}->{$penid};

  }

}

#------------------------------------------------------------------------------#

sub Color {

  my $self = shift;

  if (($#_ != 0) && ($#_ != 2)) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my $thecolor;
  if ($#_ == 0) {
    $thecolor = shift;
  } else {
    my ($r, $g, $b) = @_;
    $thecolor = ((($b << 8) | $g) << 8) | $r;
  }
  my $coloref = _SetTextColor($self->{dc}, $thecolor);

  if ($coloref =~ /-/) {
    _croak "ERROR: Cannot select color! ${\_GetLastError()}";
    return undef;
  }

  return $coloref;

}

#------------------------------------------------------------------------------#

sub Brush {

  my $self = shift;

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  if (($#_ == 0) and _IsNo($_[0])) {

    my $handle = shift;

    my $prebrush = _SelectObject($self->{dc}, $handle);
    unless ($prebrush) {
      _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
      return undef;
    }

    return $prebrush;

  } else {

    my ($r, $g, $b, $hs) = @_;

    my ($bs, $brushid);

    $brushid = "brush";

    if (!defined($r)) {

      if (!$self->{obj}->{$brushid}) {

        $self->{obj}->{$brushid} = _CreateBrushIndirect(BS_NULL, 0, 255, 255, 255);

        unless ($self->{obj}->{$brushid}) {
          _croak "ERROR: Cannot create brush! ${\_GetLastError()}";
          return undef;
        }

      }

    } else {

      if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }
      if ($#_ < 2) {
        _croak "ERROR: Not enough actual parameters!\n";
        return undef;
      }

      if (defined($hs)) {
        $bs = BS_HATCHED;
      } else {
        $bs = BS_SOLID;
        $hs = 0;
      }

      $brushid = "$r\_$g\_$b\_$hs";

      if (!$self->{obj}->{$brushid}) {

        $self->{obj}->{$brushid} = _CreateBrushIndirect($bs, $hs, $r, $g, $b);

        unless ($self->{obj}->{$brushid}) {
          _croak "ERROR: Cannot create brush! ${\_GetLastError()}";
          return undef;
        }

      }

    }

    my $prebrush = _SelectObject($self->{dc}, $self->{obj}->{$brushid});
    unless ($prebrush) {
      _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->{obj}->{$brushid}, $prebrush) : $self->{obj}->{$brushid};

  }

}

#------------------------------------------------------------------------------#

sub Fill {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $fmode = shift;
  $_numcroaked = 0;
  _num($fmode);
  return undef if $_numcroaked;

  unless (_SetPolyFillMode($self->{dc}, $fmode)) {
    _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Rect {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $ew, $eh) = @_;

  if ($ew) {

    if (!$eh) { $eh = $ew; }

    unless (_RoundRect($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
			     $self->_xun2p($ew), $self->_yun2p($eh))) {
      _croak "ERROR: Cannot draw rectangular! ${\_GetLastError()}";
      return undef;
    }

  } else {

    unless (_Rectangle($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			     $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
      _croak "ERROR: Cannot draw rectangular! ${\_GetLastError()}";
      return undef;
    }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Ellipse {

  my $self = shift;

  if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h) = @_;

  unless (_Ellipse($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			 $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
    _croak "ERROR: Cannot draw ellipse! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Chord {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $r1 = $w / 2;
  my $r2 = $h / 2;
  my $xc = $x + $r1;
  my $yc = $y + $r2;

  my $pi = 3.1415926535;

  my $rm1 = sqrt(abs(($r1 * $r1 * $r2 * $r2) / ($r1 * $r1 * sin($a1 * $pi / 180) + $r2 * $r2 * cos($a1 * $pi / 180))));
  my $rm2 = sqrt(abs(($r1 * $r1 * $r2 * $r2) / ($r1 * $r1 * sin($a2 * $pi / 180) + $r2 * $r2 * cos($a2 * $pi / 180))));

  my $xr1 = $xc + cos($a1 * $pi / 180) * $rm1;
  my $yr1 = $yc - sin($a1 * $pi / 180) * $rm1;
  my $xr2 = $xc + cos($a2 * $pi / 180) * $rm2;
  my $yr2 = $yc - sin($a2 * $pi / 180) * $rm2;

  unless (_Chord($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		       $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		       $self->_xun2p($xr1), $self->_yun2p($yr1),
		       $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw chord! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Pie {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi=3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1 * $pi / 180));
  my $yr1 = $yc - int(100 * sin($a1 * $pi / 180));
  my $xr2 = $xc + int(100 * cos($a2 * $pi / 180));
  my $yr2 = $yc - int(100 * sin($a2 * $pi / 180));

  unless (_Pie($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw pie! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Move {

  my $self = shift;

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y) = @_;

  $x = $self->_xun2p($x);
  $y = $self->_yun2p($y);

  unless (_MoveTo($self->{dc}, $x, $y)) {
    _croak "ERROR: Cannot Move! ${\_GetLastError()}";
    return undef;
  }

  return ($self->_xp2un($x), $self->_yp2un($y));

}

#------------------------------------------------------------------------------#

sub Arc {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi = 3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1 * $pi / 180));
  my $yr1 = $yc - int(100 * sin($a1 * $pi / 180));
  my $xr2 = $xc + int(100 * cos($a2 * $pi / 180));
  my $yr2 = $yc - int(100 * sin($a2 * $pi / 180));

  unless (_Arc($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw arc! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub ArcTo {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi=3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1*$pi/180));
  my $yr1 = $yc - int(100 * sin($a1*$pi/180));
  my $xr2 = $xc + int(100 * cos($a2*$pi/180));
  my $yr2 = $yc - int(100 * sin($a2*$pi/180));

  unless (_ArcTo($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw arc! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Line {

  my $self = shift;

  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my $cnt = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_Polyline($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw line! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub LineTo {

  my $self = shift;

  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolylineTo($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw line! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Poly {

  my $self = shift;

  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_Polygon($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polygon! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Bezier {

  my $self = shift;

  if ($#_ < 7) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolyBezier($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polybezier! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub BezierTo {

  my $self = shift;

  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolyBezierTo($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polybezier! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PBegin {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_BeginPath($self->{dc})) {
    _croak "ERROR: Cannot begin path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PAbort {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_AbortPath($self->{dc})) {
    _croak "ERROR: Cannot abort path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}


#------------------------------------------------------------------------------#

sub PEnd {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPath($self->{dc})) {
    _croak "ERROR: Cannot end path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PDraw {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_StrokeAndFillPath($self->{dc})) {
    _croak "ERROR: Cannot draw path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PClip {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
  }

  my $mode = shift;
  $_numcroaked = 0;
  _num($mode);
  return undef if $_numcroaked;

  if ($mode == CR_OFF) {
    unless (_DeleteClipPath($self->{dc})) {
      _croak "ERROR: Cannot remove clip path! ${\_GetLastError()}";
      return undef;
    }
    return 1;
  }

  unless (_SelectClipPath($self->{dc}, $mode)) {
    _croak "ERROR: Cannot create clip path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub EBbl {

  my $self = shift;

  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  if ($#_ > 5) {
    _carp "WARNING: Too many actual parameters!\n"; 
  }

  my ($string, $x, $y, $flags, $baw, $bah) = @_;

  $_numcroaked = 0;
  unless(_num($x)) { $x = 0; }
  unless(_num($y)) { $y = 0; }
  unless(_num($flags)) { $flags = EB_128SMART | EB_TXT; }
  unless(_num($baw)) { $baw = 0.54; }
  unless(_num($bah)) { $bah = 20; }
  return undef if $_numcroaked;

  my $emf = ($flags & EB_EMF) ? 1 : 0;

  my $error = _EBbl($self->{dc}, $emf, $string, $self->_xun2p($x), $self->_yun2p($y), $flags & ~EB_EMF, $self->_pts2p($baw), $self->_pts2p($bah));
  unless ($error == 0) {
    my @errmessage;
    $errmessage[1]  = "Select barcode standard!\n";
    $errmessage[2]  = "Unsupported character in barcode string!\n";
    $errmessage[4]  = "Wrong barcode string size!\n";
    $errmessage[8]  = "GDI error!\n";
    $errmessage[16] = "Memory allocation error!\n";
    $errmessage[32] = "Unknown error!\n";
    $errmessage[64] = "Could not load ebbl!\n";
    _croak "ERROR: ".$errmessage[$error];
    return undef;
  }

  if ($flags & EB_EMF) {
    if ($emf == 0) {
      _croak "ERROR: Cannot draw barcode! ${\_GetLastError()}";
      return undef;
    }
    $self->{imager}->{$emf} = 0;
  }

  return $emf;

}

#------------------------------------------------------------------------------#

sub Image {

  my $self = shift;

  if (($#_ != 0) and ($#_ != 2) and ($#_ != 4)) {
    _croak "ERROR: Wrong number of parameters!\n";
    return undef;
  }

  my ($width, $height) = (0, 0);

  if (($#_ == 2) or ($#_ == 4)) {

    my ($fileorref, $x, $y, $w, $h) = @_;

    if (!_IsNo($fileorref)) {
      $fileorref = $self->Image($fileorref);
      unless (defined($fileorref)) { return undef; }
    }

    _GetEnhSize($self->{dc}, $fileorref, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);

    if ((!defined($w)) or ($w == 0)) { $w = $width; }
    if ((!defined($h)) or ($h == 0)) { $h = $height; }

    unless (_PlayEnhMetaFile($self->{dc}, $fileorref, $self->_xun2p($x), $self->_yun2p($y), $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
      _croak "ERROR: Cannot display metafile! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($fileorref, $width, $height) : $fileorref;

  } else {

    my $file = shift;

    if (_IsNo($file)) {
      _GetEnhSize($self->{dc}, $file, $width, $height, $self->{unit});
      $width = $self->_xp2un($width);
      $height = $self->_yp2un($height);
      return ($width, $height);
    }

    if (defined($self->{imagef}->{$file})) {
      _GetEnhSize($self->{dc}, $self->{imagef}->{$file}, $width, $height, $self->{unit});
      $width = $self->_xp2un($width);
      $height = $self->_yp2un($height);
      return wantarray ? ($self->{imagef}->{$file}, $width, $height) : $self->{imagef}->{$file};
    }

    my $fref;

    if ($file =~ /.emf$/) {
      $fref = _GetEnhMetaFile($file);
      unless ($fref) {
        _croak "ERROR: Cannot load metafile! ${\_GetLastError()}";
        return undef;
      }
    } elsif ($file =~ /.wmf$/) {
      $fref = _GetWinMetaFile($self->{dc}, $file);
      unless ($fref) {
        _croak "ERROR: Cannot load metafile! ${\_GetLastError()}";
        return undef;
      }
    } else {

      $fref = _LoadBitmap($self->{dc}, $file, -1, $self->{unit});

      unless ($fref) {
        _croak "ERROR: Cannot load bitmap! ${\_GetLastError()}";
        return undef;
      }

    }

    $self->{imager}->{$fref} = $file;
    $self->{imagef}->{$file} = $fref;

    _GetEnhSize($self->{dc}, $fref, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);
    return wantarray ? ($fref, $width, $height) : $fref;

  }

}

#------------------------------------------------------------------------------#

sub Meta {

  my $self = shift;

  if ($#_ > 2) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($self->{emfstate}) {
    _croak qq^ERROR: There is allready started EMF!\n^;
  }

  my $fname = shift;
  my $width = shift;
  my $height = shift;

  if ($fname) {
    my $prompt;
    if ($fname =~ s/^FILE://i) { $prompt = 1; }

    $fname =~ s/\//\\/g;
    while (-f $fname) { 
      if ($fname !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
        $fname =~ s/(.*\\*)(.*)\./$1$2(1)\./
      }
    }
    my $file = $fname;
    $file =~ s/(.*\\)//g;
    my $dir = $1;
    unless ($dir) { $dir = '.\\'; }
    if ($prompt) {
      $fname = _SaveAs(3, $file, $dir);
    }
    if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
      _croak "ERROR: Cannot create printer object! Invalid filename\n";
      return undef;
    }
  } else {
    $fname = "";
  }

  $_numcroaked = 0;
  _num($width);
  _num($height);
  return undef if $_numcroaked;

  if (!defined($width) or !defined($height)) {
    $width = 0;
    $height = 0;
  } else {
    $self->{emfw} = $width;
    $self->{emfh} = $height;
  }

  if (($width > 0) and ($height > 0)) {
    if (defined($self->{params}->{'unit'})) {
      if ($self->{params}->{'unit'} eq "mm") {
        $width *= 100;
        $height *= 100;
      } elsif ($self->{params}->{'unit'} eq "cm") {
        $width *= 1000;
        $height *= 1000;
      } elsif ($self->{params}->{'unit'} eq "pt") {
        $width *= 2540.9836 / 72;
        $height *= 2540.9836 / 72;
      } elsif ($self->{params}->{'unit'} =~ /^\d+\.*\d*$/i) {
        $width *= 2540.9836 / $self->{params}->{'unit'};
        $height *= 2540.9836 / $self->{params}->{'unit'};
      } else {
        $width *= 2540.9836;
        $height *= 2540.9836;
      }
    } else {
      $width *= 2540.9836;
      $height *= 2540.9836;
    }
  } elsif (($width < 0) and ($height < 0)) {
    _croak qq^ERROR: height, width must be positive values!\n^;
  }

  my $meta = _CreateMeta($self->{dc}, $fname, $width, $height);
  if ($meta) {
    $self->{emfstate} = 1;
    $self->{dc} = $meta;
  } else {
    _croak "ERROR: Cannot begin EMF! ${\_GetLastError()}";
    return undef;
  }

  if (_CopyTextColor($self->{odc}, $self->{dc}) =~ /-/) {
    _croak "ERROR: Cannot set default color!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 1)) {
    _croak "ERROR: Cannot select pen!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 2)) {
    _croak "ERROR: Cannot select brush!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 6)) {
    _croak "ERROR: Cannot select font!\n";
    return undef;
  }

  $self->{emfname} = $fname;
  return $fname;

}

#------------------------------------------------------------------------------#

sub MetaEnd {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  if (!$self->{emfstate}) {
    _croak qq^ERROR: There is no beginning of the EMF!\n^;
  }

  my $return = _CloseMeta($self->{dc});
  if ($return) {
    $self->{emfstate} = 0;
    $self->{dc} = $self->{odc};
    $self->{imager}->{$return} = 0;

    my ($width, $height) = (0, 0);
    _GetEnhSize($self->{dc}, $return, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);

    return wantarray ? ($return, $width, $height) : $return;

  } else {
    _croak "ERROR: Cannot end EMF! ${\_GetLastError()}";
    return undef;
  }

}

#------------------------------------------------------------------------------#

sub Caps {

  my $self = shift;

  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }
  if ($#_ > 0) {
    _carp "WARNING: Too many actual parameters!\n";
    return undef;
  }

  my $index = shift;
  $_numcroaked = 0;
  _num($index);
  return undef if $_numcroaked;

  return _GetDeviceCaps($self->{dc}, $index);

}

#------------------------------------------------------------------------------#

sub Close {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($#_ == 0) {
    if (_IsNo($_[0])) {
      if (_DeleteEnhMetaFile($_[0])) {
        delete $self->{imagef}->{$self->{imager}->{$_[0]}};
        delete $self->{imager}->{$_[0]};
      }
    } else {
      if (my $file = _DeleteEnhMetaFile($self->{imagef}->{$_[0]})) {
        delete $self->{imagef}->{$_[0]};
        delete $self->{imager}->{$file};
      }
    }
  } else {

    $self->MetaEnd() if $self->{emfstate};

    for (keys %{$self->{obj}}) {
     _DeleteObject($self->{obj}->{$_});
    } 

    for (keys %{$self->{imager}}) {
      _DeleteEnhMetaFile($_);
    }

    if ($self->{dc}) {
      _EndPage($self->{dc});
      if (_EndDoc($self->{dc}) > 0) {
        unless($self->_pdf()) {
          _croak "ERROR: Cannot create PDF document! ${\_GetLastError()}";
          return undef;
        }
      }
      _DeleteDC($self->{dc});
    }

    undef $self->{dc};
    if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Inject {

  my $self = shift;

  if ($#_ != 2) {
    _croak "ERROR: Wrong number of parameters!\n";
    return undef;
  }

  my ($point, $page, $data) = @_;

  $_numcroaked = 0;
  _num($point);
  _num($page);
  return undef if $_numcroaked;

  _Inject($self->{dc}, $point, $page, $data);

  return 1;

}

#------------------------------------------------------------------------------#

sub ImageSave {

  my $self = shift;

  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }
  if ($#_ > 6) {
    _carp "WARNING: Too many actual parameters!\n";
    return undef;
  }

  my ($handle, $fname, $bpp, $width, $height, $format, $flag) = @_;

  $_numcroaked = 0;
  _num($handle);
  _num($format);
  $bpp = 24 unless _num($bpp);
  $flag= 0 unless _num($flag);
  $format= -1 unless _num($format);

  if (!_num($width) || !_num($height) || ($width <= 0) || ($height <= 0)) {
    $width = 0;
    $height = 0;
    _GetEnhSize($self->{dc}, $handle, $width, $height, $self->{unit});
  }

  return undef if $_numcroaked;

  my $prompt;
  if ($fname =~ s/^FILE://i) { $prompt = 1; }

  $fname =~ s/\//\\/g;
  while (-f $fname) { 
    if ($fname !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
      $fname =~ s/(.*\\*)(.*)\./$1$2(1)\./
    }
  }
  my $file = $fname;
  $file =~ s/(.*\\)//g;
  my $dir = $1;
  unless ($dir) { $dir = '.\\'; }
  if ($prompt) {
    $fname = _SaveAs(4, $file, $dir);
  }
  if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
    _croak "ERROR: Cannot create printer object! Invalid filename\n";
    return undef;
  }

  my $rerr = _EmfH2BMP($self->{dc}, $handle, $fname, $width, $height, $format, $flag, $bpp);
  if ($rerr == 1) {
    return $fname;
  } elsif ($rerr ==  0) {
    _croak "ERROR: Cannot save image! ${\_GetLastError()}";
  } elsif ($rerr == -1) {
    _croak "ERROR: Cannot save image! (Unable to guess filetype)\n";
  } elsif ($rerr == -2) {
    _croak "ERROR: Cannot save image! (Bits not supported)\n";
  } elsif ($rerr == -3) {
    _croak "ERROR: Cannot save image! (Image format not supported)\n";
  }

  return undef;

}

#------------------------------------------------------------------------------#

sub DESTROY {

  my $self = shift;

  if ($self->{dc}) {
    _AbortDoc($self->{dc});
    $self->Close();
  }

  return 1;

}

#------------------------------------------------------------------------------#

1;

__END__

=head1 NAME

Win32::Printer - Perl extension for Win32 printing

=head1 SYNOPSIS

 use Win32::Printer;

 my $dc = new Win32::Printer(
				papersize	=> A4,
				dialog		=> NOSELECTION,
				description	=> 'Hello, Mars!',
				unit		=> 'mm'
			    );

 my $font = $dc->Font('Arial Bold', 24);
 $dc->Font($font);
 $dc->Color(0, 0, 255);
 $dc->Write("Hello, Mars!", 10, 10);

 $dc->Brush(128, 0, 0);
 $dc->Pen(4, 0, 0, 128);
 $dc->Ellipse(10, 25, 50, 50);

 $dc->Close();

=head1 ABSTRACT

DISCONTINUED!!! Win32 GDI graphical printing
If You are desperate to find me You can try to to do it through CPAN!

=head1 INSTALLATION

=head2 Source installation

B<1.> Make sure you have a C/C++ compiler and you're running Win32.

B<2.> For VC++ 6.0 or VC++ .NET do the following (others not tested):

  > perl Makefile.PL
  > nmake
  > nmake test
  > nmake install

B<3.> For bitmap support, copy I<FreeImage.dll> somewhere in your system path.
You may get this library form I<http://sourceforge.net>.

B<4.> For PDF support, install I<Ghostscript> and set path to it's B<\bin>
directory. You may get this PostScript interpreter form
I<http://sourceforge.net>.

B<5.> For Barcode support, install B<I<ebbl>>. DISCONTINUED!!!

B<6.> Enjoy it ;)

=head1 DESCRIPTION

B<All symbolic constants are exported by default!!!>

=head2 new

 new Win32::Printer ( [ parameter => value, ... ] );

The B<new> class method creates printer object, starts new document (a print
job), returns printer object and changes B<$dc-E<gt>{flags}> variable.
B<$dc-E<gt>{flags}> contains modified printer dialog flags. B<new> also sets
B<$dc-E<gt>{copies}>, B<$dc-E<gt>{collate}>, B<$dc-E<gt>{maxp}> and
B<$dc-E<gt>{minp}>, B<$dc-E<gt>{xres}>, B<$dc-E<gt>{yres}>, B<$dc-E<gt>{xsize}>,
B<$dc-E<gt>{ysize}> variables.

  $dc->{xres};	# X resolution
  $dc->{yres};	# Y resolution
  $dc->{xsize};	# X size in chosen units
  $dc->{ysize};	# Y size in chosen units

B<NOTE!> Print job is automatically aborted if print job is not ended by
B<L</End>> or B<L</Close>> methods or if an error occurs!

The B<new> class method sets the following optional printer object and document
parameters:

=head3 collate

Specifies whether collation should be used when printing multiple copies. This
member can be be one of the following values:

  0 - Do not collate when printing multiple copies. 
  1 - Collate when printing multiple copies (default).

Using B<collate> provides faster, more efficient output for collation, since
the data is sent to the device driver just once, no matter how many copies are
required. The printer is told to simply print the page again. If this flag is
set to 1 and print dialog is used, the B<Collate> check box is initially
checked.

B<$dc-E<gt>{collate}> variable shows if collation was required. You may use it
after print dialog to check user input.

If B<$dc-E<gt>{collate}> is set to 0 - You need to handle multiple copies by
yourself.

See also L</copies>.

=head3 color*

Switches between color and monochrome on color printers. Following are the
possible values: 

  MONOCHROME 			= 1
  COLOR				= 2

=head3 copies

Initial number of document copies to print. Used by dialog and/or printer
driver. B<$dc-E<gt>{collate}> variable shows how many copies were required.

See also L</collate>.

=head3 dc

If B<dc> defined- returns only device context without starting the document and
new page.

=head3 debug*

Set to:

  0 - default;
  1 - die on warnings;
  2 - warn on errors (not recomended);

If debug level set to 2- methods return undef value on error.

MAY INTERFERE WITH DIFFERENT PRINTER OBJECTS!

See also L</Debug>.

=head3 description

Document description. Default is "Printer". It is used as document name,
filename suggestion and/or PDF document title;

=head3 dialog

If both B<L</printer>> and B<dialog> attributes omitted- systems B<default 
printer> is used.

Printer dialog settings. You may use the combination of the following flags
(B<$dc-E<gt>{flags}> contains modified printer dialog flags):

  ALLPAGES			= 0x000000

The default flag that indicates that the B<All> radio button is initially
selected. This flag is used as a placeholder to indicate that the PAGENUMS and
SELECTION flags are not specified.

  SELECTION			= 0x000001

If this flag is set, the B<Selection> radio button is selected. 
If neither PAGENUMS nor SELECTION is set, the B<All> radio button is selected. 

  PAGENUMS			= 0x000002

If this flag is set, the Pages radio button is selected. 
If this flag is set when the B<new> method returns, the B<$dc-E<gt>{maxp}> and
B<$dc-E<gt>{minp}> variables indicate the starting and ending pages specified by
the user.

  NOSELECTION			= 0x000004

Disables the B<Selection> radio button.

  NOPAGENUMS			= 0x000008

Disables the B<Pages> radio button and the associated edit controls.

  PRINTTOFILE			= 0x000020

If this flag is set, the B<Print to File> check box is selected.

  PRINTSETUP			= 0x000040

Causes the system to display the B<Print Setup> dialog box rather than the
B<Print> dialog box.

  NOWARNING			= 0x000080

Prevents the warning message from being displayed when there is no default
printer.

  DISABLEPRINTTOFILE		= 0x080000

Disables the B<Print to File> check box.

  HIDEPRINTTOFILE		= 0x100000

Hides the B<Print to File> check box.

  NONETWORKBUTTON		= 0x200000

Hides and disables the B<Network> button.

=head3 duplex

Duplexing mode:

  SIMPLEX			= 1
  VERTICAL			= 2
  HORIZONTAL			= 3

=head3 file

Set B<file> attribute to save printer drivers output into the file specified by
value of attribute. B<Note:> Specified file will not be overwritten- it's name
will be changed to B<file_name(1)... file_name(n)> to avoid overwriting.

If the flag is set - End(), Abort() and Close() methods returns possibly
modified file name.

See also L</pdf>, L</prompt>, L</End>, L</Abort> and L</Close>.

It is used as suggestion if used with B<prompt> or B<dialog>'s PRINTTOFILE.

=head3 height

Set specific page height (must be greater than tenth of milimetre).

See also L</width>.

=head3 maxp

Major page number in printer dialog (maximal allowed value).

See also L</minp>.

=head3 minp

Minor page number in printer dialog (minimal allowed value).

See also L</maxp>.

=head3 orientation

Page orientation (portrait by default).

  PORTRAIT			= 1
  LANDSCAPE			= 2

=head3 papersize

Defined paper sizes:

  LETTER			= 1
  LETTERSMALL			= 2
  TABLOID			= 3
  LEDGER			= 4
  LEGAL				= 5
  STATEMENT			= 6
  EXECUTIVE			= 7
  A3				= 8
  A4				= 9
  A4SMALL			= 10
  A5				= 11
  B4				= 12
  B5				= 13
  FOLIO				= 14
  QUARTO			= 15
  IN_10X14			= 16
  IN_11X17			= 17
  NOTE				= 18
  ENV_9				= 19
  ENV_10			= 20
  ENV_11			= 21
  ENV_12			= 22
  ENV_14			= 23
  CSHEET			= 24
  DSHEET			= 25
  ESHEET			= 26
  ENV_DL			= 27
  ENV_C5			= 28
  ENV_C3			= 29
  ENV_C4			= 30
  ENV_C6			= 31
  ENV_C65			= 32
  ENV_B4			= 33
  ENV_B5			= 34
  ENV_B6			= 35
  ENV_ITALY			= 36
  ENV_MONARCH			= 37
  ENV_PERSONAL			= 38
  FANFOLD_US			= 39
  FANFOLD_STD_GERMAN		= 40
  FANFOLD_LGL_GERMAN		= 41
  ISO_B4			= 42
  JAPANESE_POSTCARD		= 43
  IN_9X11			= 44
  IN_10X11			= 45
  IN_15X11			= 46
  ENV_INVITE			= 47
  RESERVED_48			= 48
  RESERVED_49			= 49
  LETTER_EXTRA			= 50
  LEGAL_EXTRA			= 51
  TABLOID_EXTRA			= 52
  A4_EXTRA			= 53
  LETTER_TRANSVERSE		= 54
  A4_TRANSVERSE			= 55
  LETTER_EXTRA_TRANSVERSE	= 56
  A_PLUS			= 57
  B_PLUS			= 58
  LETTER_PLUS			= 59
  A4_PLUS			= 60
  A5_TRANSVERSE			= 61
  B5_TRANSVERSE			= 62
  A3_EXTRA			= 63
  A5_EXTRA			= 64
  B5_EXTRA			= 65
  A2				= 66
  A3_TRANSVERSE			= 67
  A3_EXTRA_TRANSVERSE		= 68

=head3 pdf

Set this attribute if You want to convert PostScript printer drivers output to
PDF format. B<WARNING:> This feature needs installed I<Ghostscript> and atleast
one PostScript printer driver. Use this attribute with B<L</file>> or
B<L</prompt>> attributes.

Set attribute value to:

   0	- ignore Ghostscript messages;
   1	- redirect Ghostscript messages to log file;
 other	- redirect Ghostscript messages to STDERR;

Use B<L</file>> attribute "-" to generate pdf to STDOUT.

See also L</file>, L</prompt>.

=head3 printer

If both B<printer> and B<L</dialog>> attributes omitted- systems
B<default printer> is used. Value of attribute is also used for B<L</dialog>>
initialisation.

Set printer's "friendly" name e.g. "HP LaserJet 8500" or network printer's UNC
e.g. "\\\\server\\printer" or "//server/printer".

=head3 prompt

If prompt attribute defined- prompts for print output filename and sets
B<L</file>> attribute. Behaves like B<L</file>> attribute. Also sets
B<L</dialog>>'s PRINTTOFILE flag.

See also L</file>, L</pdf>.

=head3 source

Specifies the paper source.

  BIN_ONLYONE			= 1
  BIN_LOWER			= 2
  BIN_MIDDLE			= 3
  BIN_MANUAL			= 4
  BIN_ENVELOPE			= 5
  BIN_ENVMANUAL			= 6
  BIN_AUTO			= 7
  BIN_TRACTOR			= 8
  BIN_SMALLFMT			= 9
  BIN_LARGEFMT			= 10
  BIN_LARGECAPACITY		= 11
  BIN_CASSETTE			= 14
  BIN_FORMSOURCE		= 15

=head3 unit*

Document units (inches by default).
Specified unit is used for all coordinates and sizes, except for
L<font sizes|/Font> and L<pen widths|/Pen>.

You may use strings:

  'in' - inches
  'mm' - millimeters
  'cm' - centimeters
  'pt' - points (in/72)

Or unit ratio according to:

  ratio = in / unit

  Example: 2.5409836 cm = 1 in

B<Set units to 0 to use device units.>

See also L</Unit>.

=head3 width

Set specific page width (must be greater than tenth of milimetre).

See also L</height>.

=head2 Abort

  $dc->Abort();

The B<Abort> method stops the current print job and erases everything drawn
since the last call to the B<L</Start>> method. Method returns possibly changed
file name if B<L</file>> attribute is set.

See also L</Start>, L</Next>, L</End> and L</file>.

=head2 Arc

  $dc->Arc($x, $y, $width, $height, $start_angle, $end_angle2);

The B<Arc> method draws an elliptical arc.
B<$x, $y> sets the upper-left corner coordinates of bounding rectangle.
B<$width, $height> sets the width and height of bounding rectangle.
B<$start_angle, $end_angle2> sets the starting and ending angle of the arc
according to the center of bounding rectangle. The current point is not updated.

See also L</ArcTo>, L</Ellipse>, L</Chord> and L</Pie>.

=head2 ArcTo

  $dc->ArcTo($x, $y, $width, $height, $start_angle, $end_angle2);

The B<ArcTo> method draws an elliptical arc.
B<$x, $y> sets the upper-left corner coordinates of bounding rectangle.
B<$width, $height> sets the width and height of bounding rectangle.
B<$start_angle, $end_angle2> sets the starting and ending angle of the arc
according to the center of bounding rectangle. The current point is updated.

See also L</Move>, L</Arc>, L</Ellipse>, L</Chord> and L</Pie>.

=head2 Bezier

  $dc->Bezier(@points);

The B<Polybezier> method draws cubic Bézier curves by using the endpoints and
control points specified by the B<@points> array. The first curve is drawn from
the first point to the fourth point by using the second and third points as
control points. Each subsequent curve in the sequence needs exactly three more
points: the ending point of the previous curve is used as the starting point,
the next two points in the sequence are control points, and the third is the
ending point. The current point is not updated.

See also L</BezierTo>.

=head2 BezierTo

  $dc->Bezier(@points);

The B<BezierTo> method draws one or more Bézier curves.
This method draws cubic Bézier curves by using the control points specified by
the B<@points> array. The first curve is drawn from the current position to the
third point by using the first two points as control points. For each subsequent
curve, the method needs exactly three more points, and uses the ending point
of the previous curve as the starting point for the next. The current point is
updated.

See also L</Bezier> and L</Move>.

=head2 Brush

  $handle = $dc->Brush([$r, $g, $b, [$hatch]]);
  ($handle, $previous_handle) = $dc->Brush([$r, $g, $b, [$hatch]]);
  $previous_handle = $dc->Brush($handle);


The B<Brush> method creates a logical brush that has the specified style
and optional hatch style.
If no parameters specified, creates transparent brush.

You may use the following brush hatch styles:

  HS_HORIZONTAL			= 0

Horizontal hatch.

  HS_VERTICAL			= 1

Vertical hatch.

  HS_FDIAGONAL			= 2

A 45-degree downward, left-to-right hatch.

  HS_BDIAGONAL			= 3

A 45-degree upward, left-to-right hatch.

  HS_CROSS			= 4

Horizontal and vertical cross-hatch 

  HS_DIAGCROSS			= 5

45-degree crosshatch.

See also L</Pen> and L</EBbl>.

=head2 Caps

  $dc->Caps($index);

The B<Caps> method retrieves device-specific information about a specified
device.

B<$index> specifies the item to return. This parameter can be one of the
following values:

  DRIVERVERSION			= 0

The device driver version.

  HORZSIZE			= 4

Width, in millimeters, of the physical screen.

  VERTSIZE			= 6

Height, in millimeters, of the physical screen.

  HORZRES			= 8

Width, in pixels, of the screen.

  VERTRES			= 10

Height, in raster lines, of the screen.

  BITSPIXEL			= 12

Number of adjacent color bits for each pixel.

  PLANES			= 14

Number of color planes.

  NUMBRUSHES			= 16

Number of device-specific brushes.

  NUMPENS			= 18

Number of device-specific pens.

  NUMFONTS			= 22

Number of device-specific fonts.

  NUMCOLORS			= 24

Number of entries in the device's color table, if the device has a color depth
of no more than 8 bits per pixel. For devices with greater color depths, -1 is
returned.

  CURVECAPS			= 28

Value that indicates the curve capabilities of the device, as shown in the
following table:

    0		Device does not support curves.
    1		Device can draw circles.
    2		Device can draw pie wedges.
    4		Device can draw chord arcs.
    8		Device can draw ellipses.
    16		Device can draw wide borders.
    32		Device can draw styled borders.
    64		Device can draw borders that are wide and styled.
    128		Device can draw interiors.
    256		Device can draw rounded rectangles.
-

  LINECAPS			= 30

Value that indicates the line capabilities of the device, as shown in the
following table:

    0		Device does not support lines.
    2		Device can draw a polyline.
    4		Device can draw a marker.
    8		Device can draw multiple markers.
    16		Device can draw wide lines.
    32		Device can draw styled lines.
    64		Device can draw lines that are wide and styled.
    128		Device can draw interiors.
_

  POLYGONALCAPS			= 32

Value that indicates the polygon capabilities of the device, as shown in the
following table:

    0		Device does not support polygons.
    1		Device can draw alternate-fill polygons.
    2		Device can draw rectangles.
    4		Device can draw winding-fill polygons.
    8		Device can draw a single scanline.
    16		Device can draw wide borders.
    32		Device can draw styled borders.
    64		Device can draw borders that are wide and styled.
    128		Device can draw interiors.
-

  TEXTCAPS			= 34

Value that indicates the text capabilities of the device, as shown in the
following table:

    0x0001	Device is capable of character output precision.
    0x0002	Device is capable of stroke output precision.
    0x0004	Device is capable of stroke clip precision.
    0x0008	Device is capable of 90-degree character rotation.
    0x0010	Device is capable of any character rotation.
    0x0020	Device can scale independently in the x- and y-directions.
    0x0040	Device is capable of doubled character for scaling.
    0x0080	Device uses integer multiples only for character scaling.
    0x0100	Device uses any multiples for exact character scaling.
    0x0200	Device can draw double-weight characters.
    0x0400	Device can italicize.
    0x0800	Device can underline.
    0x1000	Device can draw strikeouts.
    0x2000	Device can draw raster fonts.
    0x4000	Device can draw vector fonts.
_

  CLIPCAPS			= 36

Flag that indicates the clipping capabilities of the device. If the device can
clip to a rectangle, it is 1. Otherwise, it is 0.

  RASTERCAPS			= 38

Value that indicates the raster capabilities of the device, as shown in the
following table:

    0x0001	Capable of transferring bitmaps.
    0x0002	Requires banding support.
    0x0004	Capable of scaling.
    0x0008	Capable of supporting bitmaps larger than 64K.
    0x0010	Capable of supporting features of 16-bit Windows 2.0.
    0x0080	Capable of supporting the SetDIBits and GetDIBits functions
		(Win API).
    0x0100	Specifies a palette-based device.
    0x0200	Capable of supporting the SetDIBitsToDevice function (Win API).
    0x0800	Capable of performing the StretchBlt function (Win API).
    0x1000	Capable of performing flood fills.
    0x2000	Capable of performing the StretchDIBits function (Win API).
-

  ASPECTX			= 40

Relative width of a device pixel used for line drawing.

  ASPECTY			= 42

Relative height of a device pixel used for line drawing.

  ASPECTXY			= 44

Diagonal width of the device pixel used for line drawing.

  LOGPIXELSX			= 88

Number of pixels per logical inch along the screen width.

  LOGPIXELSY			= 90

Number of pixels per logical inch along the screen height.

  SIZEPALETTE			= 104

Number of entries in the system palette. This index is valid only if the device
driver sets the RC_PALETTE bit in the RASTERCAPS index and is available only if
the driver is compatible with 16-bit Windows.

  NUMRESERVED			= 106

Number of reserved entries in the system palette. This index is valid only if
the device driver sets the RC_PALETTE bit in the RASTERCAPS index and is
available only if the driver is compatible with 16-bit Windows.

  COLORRES			= 108

Actual color resolution of the device, in bits per pixel. This index is valid
only if the device driver sets the RC_PALETTE bit in the RASTERCAPS index and
is available only if the driver is compatible with 16-bit Windows.

  PHYSICALWIDTH			= 110

For printing devices: the width of the physical page, in device units. For
example, a printer set to print at 600 dpi on 8.5"x11" paper has a physical
width value of 5100 device units. Note that the physical page is almost always
greater than the printable area of the page, and never smaller.

  PHYSICALHEIGHT		= 111

For printing devices: the height of the physical page, in device units. For
example, a printer set to print at 600 dpi on 8.5"x11" paper has a physical
height value of 6600 device units. Note that the physical page is almost always
greater than the printable area of the page, and never smaller.

  PHYSICALOFFSETX		= 112

For printing devices: the distance from the left edge of the physical page to
the left edge of the printable area, in device units. For example, a printer
set to print at 600 dpi on 8.5"x11" paper, that cannot print on the leftmost
0.25" of paper, has a horizontal physical offset of 150 device units.

  PHYSICALOFFSETY		= 113

For printing devices: the distance from the top edge of the physical page to the
top edge of the printable area, in device units. For example, a printer set to
print at 600 dpi on 8.5"x11" paper, that cannot print on the topmost 0.5" of
paper, has a vertical physical offset of 300 device units.

  SCALINGFACTORX		= 114

Scaling factor for the x-axis of the printer.

  SCALINGFACTORY		= 115

Scaling factor for the y-axis of the printer. 

See also L</new>.

=head2 Chord

  $dc->Chord($x, $y, $width, $height, $start_angle, $end_angle2);

The B<Chord> method draws a chord (a region bounded by the intersection of an
ellipse and a line segment, called a "secant"). The chord is outlined by using
the current pen and filled by using the current brush. 
B<$x, $y> sets the upper-left corner coordinates of bounding rectangle.
B<$width, $height> sets the width and height of bounding rectangle.
B<$start_angle, $end_angle2> sets the starting and ending angle of the chord
according to the center of bounding rectangle.

See also L</Ellipse>, L</Pie>, L</Arc> and L</ArcTo>.

=head2 Close

  $dc->Close([$image_handle_or_path]);

The B<Close> method finishes current print job, closes all open handles and
frees memory. Method returns possibly changed file name if B<L</file>> attribute
is set.

If optional image handle or path is provided-  closes only that image!

See also L</new>, L</Image>, L</MetaEnd>, L</EBbl> and L</file>.

=head2 Color

  $previous_coloref = $dc->Color($b, $g, $b);
  $previous_coloref = $dc->Color($coloref);

The B<Color> method sets the text to the specified color.

See also L</Write>, L</Font> and L</EBbl>.

=head2 Debug

  $dc->Debug([$debuglevel]);

The B<Debug> method changes debug level from now on or gets current level.
Possible values:

  0 - default;
  1 - die on warnings;
  2 - warn on errors (not recomended);

If debug level set to 2- methods return undef value on error.

MAY INTERFERE WITH DIFFERENT PRINTER OBJECTS!

See also L</debug*>.

=head2 EBbl

  $dc->EBbl($string, $x, $y, $flags, $baw, $bah);

The B<EBbl> method draws barcode. Uses B<L</Brush>> to fill the bars,
current B<L</Font>> for the text and B<L</Color>> for the text color.
B<$string> string to encode, B<$x> drawing x origin, B<$y> drawing y origin,
B<$flags> barcode mode flags, B<$baw> narrowest bar width in pts, B<$bah> bar
height  in pts.

  Mode flags:

  EB_25MATRIX	- 2 of 5 Matrix
  EB_25INTER	- 2 of 5 Interleaved
  EB_25IND	- 2 of 5 Industrial
  EB_25IATA	- 2 of 5 IATA

  EB_27		- 2 of 7 (aka CODABAR)

  EB_39STD	- 3 of 9
  EB_39EXT	- 3 of 9 extended
  EB_39DUMB	- 3 of 9 "dumb" (allows to pass asterixes *)

  EB_93		- 9 of 3

  EB_128SMART	- Code 128 "Smart" (smallest possible with shifting and code changes)
  EB_128A	- Code 128 A
  EB_128B	- Code 128 B
  EB_128C	- Code 128 C
  EB_128SHFT	- Allow shifting (for 128A, 128B, 128C)
  EB_128EAN	- EAN fnc (for 128SMART, 128A, 128B, 128C)

  EB_EAN13	- EAN-13
  EB_UPCA	- UPC-A
  EB_EAN8	- EAN-8
  EB_UPCE	- UPC-E
  EB_ISBN	- ISBN
  EB_ISBN2	- ISBN (reserved)
  EB_ISSN	- ISSN

  EB_AD2	- 2 digit addon (for EAN13, EAN8, UPCA, UPCE, ISSN, ISBN, ISBN2 modes)
  EB_AD5	- 5 digit addon (for EAN13, EAN8, UPCA, UPCE, ISSN, ISBN, ISBN2 modes)

  EB_CHK	- With optional check character (for 25, 39 modes)

  EB_TXT	- Draw text (for all codes)

See also L</Brush>, L</Font> and L</Color>.

=head2 Ellipse

  $dc->Ellipse($x, $y, $width, $height);

The B<Ellipse> method draws an ellipse. The center of the ellipse is the
center of the specified bounding rectangle. The ellipse is outlined by using the
current pen and is filled by using the current brush. B<$x, $y> sets the
upper-left corner coordinates of bounding rectangle. B<$width, $height> sets the
width and height of bounding rectangle.

See also L</Pie>, L</Chord>, L</Arc> and L</ArcTo>.

=head2 End

  $dc->End();

The B<End> method finishes a current print job. Method returns possibly changed
file name if B<L</file>> attribute is set.

Not allowed in B<L</Meta>> brackets!

See also L</Start>, L</Next>, L</Abort>, L</Page> and L</file>.

=head2 Fill

  $dc->Fill($mode);

The B<Fill> method sets the polygon fill mode for methods that fill
polygons.

  ALTERNATE			= 1

Selects alternate mode (fills the area between odd-numbered and even-numbered
polygon sides on each scan line).

  WINDING			= 2

Selects winding mode (fills any region with a nonzero winding value).

See also L</PDraw> and L</Poly>.

=head2 Fit

  $char_num = $dc->Fit($text, $maxwidth, [UTF8]);
  ($char_num, $width, $height) = $dc->Fit($text, $maxwidth, [UTF8]);

The B<Fit> method retrieves the number of characters (B<$char_num>) in a
specified string (B<$text>) that will fit within a specified space
(B<$maxwidth>) and in array context also returns B<$width, $height> of string.
Use B<UTF8> for UTF-8 encoded strings;

See also L</Write> and L</Write2>.

=head2 Font

  $font_handle = $dc->Font([$face, [$size, [$angle, [$charset]]]]);
  ($font_handle, $previous_font) = $dc->Font([$face, [$size, [\[$escapement, [orientation]\], [$charset]]]]);

B<or>

  $dc->Font($font_handle);

The B<Font> method creates and selects a logical font that has specific
characteristics and returns handle to it B<or> selects given font by it's
handle. Fontsize is set in pts. In array context also returns previously selecte
font handle.

B<For UTF-8 support see L</Write>.>

B<IMPORTANT!!!> First font (e.g. "Arial") that matches desired attributes is
selected if desired font is not found. Reason of that may be raster font, wrong
font name, character set unsupported by font etc. B<Warning is issued!>

If B<$angle> is array reference then function looks for B<($escapement,
[orientation])>

Example:

  $fh = $dc->Font("Arial", 10, [-90, 0]); # Same as:
  $fh = $dc->Font("Arial", 10, [-90]);    # ...prints characters cascaded vertically

B<$escapement> - Specifies the angle in degrees, between the escapement vector
and the x-axis of the device. The escapement vector is parallel to the base
line of a row of text.

B<Windows NT/2k/XP/...>: You can specify the escapement angle of the string
independently of the orientation angle of the string's characters.

B<Windows 95/98/Me>: The B<$escapement> member specifies both the escapement and
orientation. You should set B<$escapement> and B<$orientation> to the same
value.

B<$orientation> - Specifies the angle, in degrees, between each character's base
line and the x-axis of the device.

Defaults to:

  $face = '';		# First font (e.g. "Arial") that matches desired attributes
  $size = 10;		# fontsize
  $angle = 0;		# text direction angle in degrees
  $charset = DEFAULT;	# character set code

B<$face> may include any combination of the following attributes: B<bold italic
underline strike>.

Defined character set constants:

  ANSI				= 0
  DEFAULT			= 1
  SYMBOL			= 2
  MAC				= 77
  SHIFTJIS			= 128
  HANGEUL			= 129
  JOHAB				= 130
  GB2312			= 134
  CHINESEBIG5			= 136
  GREEK				= 161
  TURKISH			= 162
  VIETNAMESE			= 163
  HEBREW			= 177
  ARABIC			= 178
  BALTIC			= 186
  RUSSIAN			= 204
  THAI				= 222
  EASTEUROPE			= 238
  OEM				= 255

See also L</FontEnum>, L</Write>, L</Color> and L</EBbl>.

=head2 FontEnum

  $font_table = $dc->FontEnum([$face, [$charset]]);
  @font_array = $dc->FontEnum([$face, [$charset]]);

The B<FontEnum> method enumerates all fonts in the system available for printer
that match the font characteristics specified. It returns tab-delimited table of
values in scalar context or array of hashes in array context. B<$font> - font
face of interest, B<$charset> - character set of interest.

Follown hash keys available:

  {Face}	- enumerated font face
  {Charset}	- enumerated character set (character set codes - see Font method)
  {Style}	- enumerated font style ('bold' and/or 'italic')
  {Type}	- type of enumerated font face (Raster = 1, Device = 2, TrueType = 4);

See also L</Font>.

=head2 FontSpace

  $old_space = $dc->FontSpace($space);

The B<FontSpace> function sets the intercharacter spacing (B<$space>) and
returns previous value. B<$space> is in pts. Intercharacter spacing is added to
each character, including break characters, when the system writes a line of
text.

See also L</Font> and L</Write2>.

=head2 Image

  $image_handle = $dc->Image($filename);
  ($image_handle, $original_width, $original_height) = $dc->Image($filename);

B<or>

  $image_handle = $dc->Image($filename, $x, $y, [$width, $height]);
  ($image_handle, $original_width, $original_height) = $dc->Image($filename, $x, $y, [$width, $height]);
  $dc->Image($image_handle, $x, $y, [$width, $height]);

B<or>

  ($width, $height) = $dc->Image($image_handle);

The B<Image> method loads an image file into memory and returns a handle
to it or draws it by it's filename or handle. B<$x, $y> specifies coordinates of
the image upper-left corner. B<$width, $height> specifies the width and height
of image on the paper (default is set by image header). Once loaded by image
path- image is cached in to memory and it may be referenced by it's path.

In second case if signed integer is given- method assumes it's a handle!

In array context also returns original image width an d height
B<$original_width, $original_height>.

Natively it supports B<EMF> and B<WMF> format files.
B<BMP, CUT, DDS, ICO, JPEG, JNG, KOALA, LBM, IFF, MNG, PBM, PBMRAW, PCD, PCX,
PGM, PGMRAW, PNG, PPM, PPMRAW, PSD, RAS, TARGA, TIFF, WBMP, XBM, XPM> bitmap
formats are handled via L<FreeImage library|/INSTALLATION>.

Image file formats are recognized by their extensions. On failure- method tries
to recognize it by file content (bitmaps only).

B<WARNING!> Metafiles may have objects outside the bounding box specified by
metafile header. These objects will be visible unless you specify clipping
region (See B<L</PClip>>).

After usage, you should use B<L</Close>> to unload image from memory and destroy
a handle.

See also L</Close>, L</MetaEnd> and L</EBbl>.

=head2 ImageSave

  $dc->ImageSave($handle, $filename, [$bpp, [$width, $height, [$format, [$flag]]]]);

The B<ImageSave> method saves image as bitmap by its B<$handle> aquired by
B<L</Image>>, B<L</MetaEnd>> or B<L</EBbl>> methods. B<$filename> represents the
file name and path string. B<$bpp> for setting target bit depth (currently only
24-bit & 8-bit images supported). B<$width, $height> target width of the image.

B<$format> is one of the following B<(Note, that not all formats are writable yet)>:

  FIF_BMP			= 0

Windows or OS/2 Bitmap File (*.BMP)

  FIF_ICO			= 1

Windows Icon (*.ICO)

  FIF_JPEG			= 2

Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)

  FIF_JNG			= 3

JPEG Network Graphics (*.JNG)

  FIF_KOALA			= 4

Commodore 64 Koala format (*.KOA)

  FIF_IFF			= 5

Amiga IFF (*.IFF, *.LBM)

  FIF_MNG			= 6

Multiple Network Graphics (*.MNG)

  FIF_PBM			= 7

Portable Bitmap (ASCII) (*.PBM)

  FIF_PBMRAW			= 8

Portable Bitmap (BINARY) (*.PBM)

  FIF_PCD			= 9

Kodak PhotoCD (*.PCD)

  FIF_PCX			= 10

Zsoft Paintbrush PCX bitmap format (*.PCX)

  FIF_PGM			= 11

Portable Graymap (ASCII) (*.PGM)

  FIF_PGMRAW			= 12

Portable Graymap (BINARY) (*.PGM)

  FIF_PNG			= 13

Portable Network Graphics (*.PNG)

  FIF_PPM			= 14

Portable Pixelmap (ASCII) (*.PPM)

  FIF_PPMRAW			= 15

Portable Pixelmap (BINARY) (*.PPM)

  FIF_RAS			= 16

Sun Rasterfile (*.RAS)

  FIF_TARGA			= 17

Truevision Targa files (*.TGA, *.TARGA)

  FIF_TIFF			= 18

Tagged Image File Format (*.TIF, *.TIFF)

  FIF_WBMP			= 19

Wireless Bitmap (*.WBMP)

  FIF_PSD			= 20

Adobe Photoshop (*.PSD)

  FIF_CUT			= 21

Dr. Halo (*.CUT)

  FIF_XBM			= 22

X11 Bitmap Format (*.XBM)

  FIF_XPM			= 23

X11 Pixmap Format (*.XPM)

  FIF_DDS			= 24

DirectDraw Surface (*.DDS)

  FIF_GIF			= 25

Graphics Interchange Format (*.GIF)

B<$flag> is one of the following:

B<BMP:>

  BMP_DEFAULT			= 0

Save without any compression

  BMP_SAVE_RLE			= 1

Compress the bitmap using RLE when saving

B<JPEG:>

  JPEG_DEFAULT			= 0

Saves with good quality (75:1)

  JPEG_QUALITYSUPERB		= 0x80

Saves with superb quality (100:1)

  JPEG_QUALITYGOOD		= 0x100

Saves with good quality (75:1)

  JPEG_QUALITYNORMAL		= 0x200

Saves with normal quality (50:1)

  JPEG_QUALITYAVERAGE		= 0x400

Saves with average quality (25:1)

  JPEG_QUALITYBAD		= 0x800

Saves with bad quality (10:1)

  Integer x in [0..100]

Save with quality x:100

B<PBM, PGM, PPM:>

  PNM_DEFAULT			= 0

Saves the bitmap as a binary file

  PNM_SAVE_RAW			= 0

Saves the bitmap as a binary file

  PNM_SAVE_ASCII		= 1

Saves the bitmap as an ASCII file

B<TIFF:>

  TIFF_DEFAULT			= 0

Save using CCITTFAX4 compression for 1-bit bitmaps and LZW compression for any other bitmaps

  TIFF_CMYK			= 0x0001

Stores tags for separated CMYK (use | to combine with TIFF compression flags)

  TIFF_PACKBITS			= 0x0100

Save using PACKBITS compression.

  TIFF_DEFLATE			= 0x0200

Save using DEFLATE compression (also known as ZLIB compression)

  TIFF_ADOBE_DEFLATE		= 0x0400

Save using ADOBE DEFLATE compression

  TIFF_NONE			= 0x0800

Save without any compression

  TIFF_CCITTFAX3		= 0x1000

Save using CCITT Group 3 fax encoding

  TIFF_CCITTFAX4		= 0x2000

Save using CCITT Group 4 fax encoding

  TIFF_LZW			= 0x4000

Save using LZW compression

See also L</Image>, L</MetaEnd> and L</EBbl>.

=head2 Inject

  $dc->Inject($point, $page, $data);

The B<Inject> method adds B<$data> to a specific B<$point> in specified B<$page>.

Where B<$point> specifies where to inject the raw data in the PostScript output.
This member can be one of the following values. B<$page> specifies the page
number (starting from 1) to which the injection data is applied. Specify zero to
apply the injection data to all pages. This member is meaningful only for page
level injection points starting from PSI_PAGENUMBER. For other injection points,
set PageNumber to zero.

The injection data for a specified injection point is cumulative. In other
words, B<Inject> method adds the new injection data to any injection data
previously specified for the same injection point.

If the job is in EMF data type, you must provide all injection data before
B<Start>.

If the job is in RAW data type, you must provide the following injection data
before the driver needs it:

1) Data for header sections (before first %%Page:) before calling the first
B<Page> method.

2) Data for page setup sections (when injecting data for one particular page)
before calling the B<Page> method for that particular page.

3) Data for page setup sections (when injecting data for all pages starting from
a certain page) before calling B<Page> for the starting page.

4) Data for page trailer sections before calling the next B<Page> method.

5) Data for document trailer sections before calling the B<Close> method.

B<The injection points are:>

  PSI_BEGINSTREAM		= 1

Before the first byte of job stream.

  PSI_PSADOBE			= 2

Before %!PS-Adobe.

  PSI_PAGESATEND		= 3

Replaces driver's B<%%Pages (atend)>.

  PSI_PAGES			= 4

Replaces driver's B<%%Pages nnn>.

  PSI_DOCNEEDEDRES		= 5

After B<%%DocumentNeededResources>.

  PSI_DOCSUPPLIEDRES		= 6

After B<%%DocumentSuppliedResources>.

  PSI_PAGEORDER			= 7

Replaces driver's B<%%PageOrder>.

  PSI_ORIENTATION		= 8

Replaces driver's B<%%Orientation>.

  PSI_BOUNDINGBOX		= 9

Replaces driver's B<%%BoundingBox>.

  PSI_PROCESSCOLORS		= 10

Replaces driver's B<%DocumentProcessColors <color>>.

  PSI_COMMENTS			= 11

Before B<%%EndComments>.

  PSI_BEGINDEFAULTS		= 12

After B<%%BeginDefaults>.

  PSI_ENDDEFAULTS		= 13

Before B<%%EndDefaults>.

  PSI_BEGINPROLOG		= 14

After B<%%BeginProlog>.

  PSI_ENDPROLOG			= 15

Before B<%%EndProlog>.

  PSI_BEGINSETUP		= 16

After B<%%BeginSetup>.

  PSI_ENDSETUP			= 17

Before B<%%EndSetup>.

  PSI_TRAILER			= 18

After B<%%Trailer>.

  PSI_EOF			= 19

After B<%%EOF>.

  PSI_ENDSTREAM			= 20

After the last byte of job stream.

  PSI_PROCESSCOLORSATEND	= 21

Replaces driver's B<%%DocumentProcessColors (atend)>.

B<Page level injection points>

  PSI_PAGENUMBER		= 100

Replaces driver's B<%%Page>.

  PSI_BEGINPAGESETUP		= 101

After B<%%BeginPageSetup>.

  PSI_ENDPAGESETUP		= 102

Before B<%%EndPageSetup>.

  PSI_PAGETRAILER		= 103

After B<%%PageTrailer>.

  PSI_PLATECOLOR		= 104

Replace driver's B<%%PlateColor: <color>>.

  PSI_SHOWPAGE			= 105

Before showpage operator.

  PSI_PAGEBBOX			= 106

Replaces driver's B<%%PageBoundingBox>.

  PSI_ENDPAGECOMMENTS		= 107

Before B<%%EndPageComments>.

  PSI_VMSAVE			= 200

Before save operator.

  PSI_VMRESTORE			= 201

After restore operator.

See also L</Start>, L</Page> and L</Close>.

=head2 Line

  $dc->Line(@endpoints);

The B<Line> method draws a series of line segments by connecting the
points in the specified array. The current point is not updated.

See also L</LineTo>.

=head2 LineTo

  $dc->LineTo(@endpoints);

The B<LineTo> method draws a series of line segments by connecting the
points in the specified array. The current point is updated.

See also L</Line>.

=head2 Meta

  $filename2 = $dc->Meta([$filename1], [$width, $height]);

The B<Meta> method opens an EMF bracket. This means that everything until
B<L</MetaEnd>> will be drawn in to the EMF file. Device context is based on
current Printer object device context, but only default objects and their
default values are selected into it.

B<$filename2> - name of the EMF file to create (if omited or empty -
creates only memory EMF file). B<$width, $height> - width and height of the
EMF file.

Function returns possibly changed filename.

Use "FILE:" or "FILE:C:/suggest.emf" as a file name to invoke 'Save as' dialog.

Function will not overwrite existing files but will change names like
B<L</file>>, except if set by dialog (this is different from B<L</file>>).

You may not use nested brackets!

See also L</MetaEnd>.

=head2 MetaEnd

  $image_handle = $dc->MetaEnd();
  ($image_handle, $width, $height) = $dc->MetaEnd();

The B<MetaEnd> method closes an EMF bracket and returns handle to a creted EMF
image and also B<$width, $height> in array context. After usage, you should use
B<L</Close>> to unload image from memory and destroy a handle.

See also L</Meta>, L</Image> and L</Close>.

=head2 Move

  ($old_x, $old_y) = $dc->Move($x, $y);

The B<Move> method updates the current position to the specified point.

See also L</ArcTo>, L</LineTo> and L</BezierTo>.

=head2 Next

  $dc->Next([$description]);

The B<Next> method ends and starts new print job. Equivalent for:

  $dc->End();
  $dc->Start([$description]);

Default description - "Printer".
Method returns possibly changed file name if B<L</file>> attribute is set.

Inside B<L</Meta>> brackets:

  ($image_handle ,$filename2) = $dc->Next(([$filename1], [$width, $height]);

In this context - closes previous and opens new B<L</Meta>> brackets. If
arguments omited - uses arguments from previous brackets.

See also L</Start>, L</End>, L</Abort>, L</Page>, L</Meta> and L</MetaEnd>.

=head2 Page

  $dc->Page();

The B<Page> method starts new page.

Not allowed in B<L</Meta>> brackets!

See also L</Start>, L</Next> and L</End>.

=head2 PAbort

  $dc->PAbort();

The B<PAbort> method closes and discards any paths.


=head2 PBegin

  $dc->PBegin();

The B<PBegin> method opens a path bracket.

See also L</PClip>, L</PDraw>, L</PEnd> and L</PAbort>.

=head2 PClip

  $dc->PClip($mode);

The B<PClip> method selects the current path as a clipping region,
combining the new region with any existing clipping region by using the
specified mode.

Where B<$mode> is one of the following:

  CR_OFF			= 0

Remove clipping region.

  CR_AND			= 1

The new clipping region includes the intersection (overlapping areas) of the
current clipping region and the current path.

  CR_OR				= 2

The new clipping region includes the union (combined areas) of the current
clipping region and the current path.

  CR_XOR			= 3

The new clipping region includes the union of the current clipping region and
the current path but without the overlapping areas.

  CR_DIFF			= 4

The new clipping region includes the areas of the current clipping region with
those of the current path excluded.

  CR_COPY			= 5

The new clipping region is the current path.

See also L</PBegin>, L</PDraw>, L</PEnd> and L</PAbort>.

=head2 PDraw

  $dc->PDraw();

The B<PDraw> method closes any open figures in a path, strokes the outline
of the path by using the current pen, and fills its interior by using the
current brush and fill mode.

See also L</PBegin>, L</PClip>, L</PEnd>, L</PAbort> and L</Fill>.

=head2 PEnd

  $dc->PEnd();

The B<PEnd> method closes a path bracket and selects the path defined by
the bracket.

See also L</PBegin>, L</PClip>, L</PDraw> and L</PAbort>.

=head2 Pen

  $handle = $dc->Pen([$width, $r, $g, $b, [$style]]);
  ($handle, $previous_handle) = $dc->Pen([$width, $r, $g, $b, [$style]]);
  $previous_handle = $dc->Pen($handle);

The B<Pen> method creates a logical pen that has the specified style,
width, and color. The pen can subsequently be used to draw lines and curves.
Pen width is set in pts regardless of B<L</unit*>> attribute in B<L</new>> constructor
or whatever is set by B<L</Unit>> method.
Using dashed or dotted styles will set the pen width to 1 px!
If no parameters specified, creates transparent pen.

You may use the following pen styles:

  PS_DASH			= 0x00000001

Pen is dashed.

  PS_DOT			= 0x00000002

Pen is dotted.

  PS_DASHDOT			= 0x00000003

Pen has alternating dashes and dots.

  PS_DASHDOTDOT			= 0x00000004

Pen has alternating dashes and double dots.

  PS_NULL			= 0x00000005

Pen is invisible. 

  PS_INSIDEFRAME		= 0x00000006

Pen is solid. When this pen is used in drawing method that takes a bounding
rectangle, the dimensions of the figure are shrunk so that it fits entirely in
the bounding rectangle, taking into account the width of the pen.

  PS_SOLID			= 0x00010000

Pen is solid (default).

  PS_JOIN_ROUND			= 0x00010000

Joins are round (default).

  PS_ENDCAP_ROUND		= 0x00010000

End caps are round (default).

  PS_ENDCAP_SQUARE		= 0x00010100

End caps are square.

  PS_ENDCAP_FLAT		= 0x00010200

End caps are flat.

  PS_JOIN_BEVEL			= 0x00011000

Joins are beveled.

  PS_JOIN_MITER			= 0x00012000

Joins are mitered.

See also L</Brush>.

=head2 Pie

  $dc->Pie($x, $y, $width, $height, $start_angle, $end_angle2);

The B<Pie> method draws a pie-shaped wedge bounded by the intersection of an
ellipse and two radials. The pie is outlined by using the current pen and filled
by using the current brush. 
B<$x, $y> sets the upper-left corner coordinates of bounding rectangle.
B<$width, $height> sets the width and height of bounding rectangle.
B<$start_angle, $end_angle2> sets the starting and ending angle of the pie
according to the center of bounding rectangle.

See also L</Ellipse>, L</Chord>, L</Arc> and L</ArcTo>.

=head2 Poly

  $dc->Poly(@vertices);

The B<Poly> method draws a polygon consisting of two or more vertices
connected by straight lines. The polygon is outlined by using the current pen
and filled by using the current brush and polygon fill mode. 

See also L</Rect> and L</Fill>.

=head2 Rect

  $dc->Rect($x, $y, $width, $height, [$ellipse_width, $ellipse_height]);

The B<Rect> method draws a rectangle or rounded rectangle. The rectangle
is outlined by using the current pen and filled by using the current brush.
B<$x, $y> sets the upper-left corner coordinates of rectangle. B<$width,
$height> sets the width and height of rectangle. Optional parameters
B<$ellipse_width, $ellipse_height> sets the width and height of ellipse used to
draw rounded corners.

See also L</Poly>.

=head2 Space

  $dc->Space($eM11, $eM12, $eM21, $eM22, $eDx, $eDy);

The B<Space> method sets a two-dimensional linear transformation
between world space and page space. This transformation can be used to scale,
rotate, shear, or translate graphics output. Transformation on the next page is
reset to default. Default page origin is upper-left corner, B<x> from left to
right and B<y> from top to bottom.

  0
  ------- x
  |
  |
  | y

For any coordinates B<(x, y)> in world space, the transformed coordinates in
page space B<(x', y')> can be determined by the following algorithm: 

  x' = x * eM11 + y * eM21 + eDx, 
  y' = x * eM12 + y * eM22 + eDy, 

where the transformation matrix is represented by the following: 

  | eM11 eM12 0 |
  | eM21 eM22 0 |
  | eDx  eDy  1 |

=head2 Start

  $dc->Start([$description]);

The B<Start> method starts a print job.
Default description - "Printer".

B<NOTE!> Print job is automatically aborted if print job is not ended by
B<L</End>> or B<L</Close>> methods or if an error occurs!

Not allowed in B<L</Meta>> brackets!

See also L</Next>, L</End>, L</Abort> and L</Page>.

=head2 Unit

  $dc->Unit([$unit]);

The B<Unit> method sets or gets current unit ratio.

Specified unit is used for all coordinates and sizes, except for
L<font sizes|/Font> and L<pen widths|/Pen>.

You may use strings:

  'in' - inches
  'mm' - millimeters
  'cm' - centimeters
  'pt' - points (in / 72)

Or unit ratio according to:

  ratio = in / unit

  Example: 2.5409836 cm = 1 in

B<Set units to 0 to use device units.>

See also L</unit*>.

=head2 Write

  # String mode (SM):
  $height = $dc->Write($text, $x, $y, [$format, [$just_width]]);
  ($width, $height) = $dc->Write($text, $x, $y, [$format, [$just_width]]);

  # Draw mode (DM):
  $height = $dc->Write($text, $x, $y, $width, $height, [$format, [$tab_stop]]);
  ($width, $height, $length, $text) = $dc->Write($text, $x, $y, $width, $height, [$format, [$tab_stop]]);

B<SM:>
The B<Write> method B<string mode> writes a character string at the specified
location, using the currently selected font, text color and alignment.

B<DM:>
The B<Write> method B<draw mode> draws formatted text in the specified rectangle.
In array context method returns array containing B<($width, $height, $length,
$text)>. B<$height> is returned in scalar context. B<$length> receives the
number of characters processed by B<Write>, including white-space characters.
See CALCRECT and MODIFYSTRING flags. Optional B<$tab_stop> parameter
specifies the number of average character widths per tab stop.

B<Warning!> - $widt must be less than 0x80000000 units.

Optional text format flags:

  UTF8				= 0x20000000 (SM & DM)

Treat B<$text> as B<UTF-8> encoded string. Note that selected font must support
desired unicode characters. Available for NT platforms and also supported by
Microsoft Layer for Unicode.

  NOUPDATECP			= 0x00000000 (SM)

The current position is not updated after each text output call. The reference
point is passed to the text output method.

  TOP				= 0x00000000 (SM & DM)

B<SM:> The reference point will be on the top edge of the bounding rectangle.

B<DM:> Top justifies text. This value must be combined with SINGLELINE.

  LEFT				= 0x00000000 (SM & DM)

B<SL:> The reference point will be on the left edge of the bounding rectangle.

B<ML:> Aligns text to the left.

  UPDATECP			= 0x00000001 (SM)

The current position is updated after each text output call. The current
position is used as the reference point.

  RIGHT				= 0x00000002 (SM & DM)

B<SL:> The reference point will be on the right edge of the bounding rectangle.

B<ML:> Aligns text to the right.

  VCENTER			= 0x00000004 (DM)

Centers text vertically (single line only).

  BOTTOM			= 0x00000008 (SM & DM)

B<SL:> The reference point will be on the bottom edge of the bounding rectangle.

B<ML:> Justifies the text to the bottom of the rectangle. This value must be
combined with SINGLELINE.

  WORDBREAK			= 0x00000010 (DM)

Breaks words. Lines are automatically broken between words if a word extends
past the edge of the specified rectangle. A carriage return-linefeed sequence
also breaks the line.

  BASELINE			= 0x00000018 (SM)

The reference point will be on the base line of the text.

  SINGLELINE			= 0x00000020 (DM)

Displays text on a single line only. Carriage returns and linefeeds do not break
the line.

  EXPANDTABS			= 0x00000040 (DM)

Expands tab characters. Number of characters per tab is eight.

  NOCLIP			= 0x00000100 (DM)

Draws without clipping. B<Write> is somewhat faster when NOCLIP is used.

  EXTERNALLEADING		= 0x00000200 (DM)

Includes the font external leading in line height. Normally, external leading is
not included in the height of a line of text.

  CALCRECT			= 0x00000400 (DM)

Determines the B<$width> and B<$height> of the rectangle. If there are multiple
lines of text, B<Write> uses the width of the given rectangle and extends the
base of the rectangle to bound the last line of text. If there is only one line
of text, B<Write> modifies the width of the rectangle so that it bounds the
last character in the line. In either case, B<Write> returns the height of the
formatted text, but does not draw the text.

  INTERNAL			= 0x00001000 (DM)

Uses the system font to calculate text metrics.

  EDITCONTROL			= 0x00002000 (DM)

Duplicates the text-displaying characteristics of a multiline edit control.
Specifically, the average character width is calculated in the same manner as
for an edit control, and the method does not display a partially visible last
line.

  PATH_ELLIPSIS			= 0x00004000 (DM)
  END_ELLIPSIS			= 0x00008000 (DM)

Replaces part of the given string with ellipses, if necessary, so that the
result fits in the specified rectangle. The B<$text> element of returning
array is not modified unless the MODIFYSTRING flag is specified.

You can specify END_ELLIPSIS to replace characters at the end of the string,
or PATH_ELLIPSIS to replace characters in the middle of the string. If the
string contains backslash (\) characters, PATH_ELLIPSIS preserves as much as
possible of the text after the last backslash.

  MODIFYSTRING			= 0x00010000 (DM)

Modifies the B<$text> element of returning array to match the displayed text.
This flag has no effect unless the END_ELLIPSIS, PATH_ELLIPSIS or WORD_ELLIPSIS
flag is specified.

  RTLREADING			= 0x00020000 (SM & DM)

Layout in right to left reading order for bi-directional text when the selected
font is a Hebrew or Arabic font. The default reading order for all text is left
to right.

  WORD_ELLIPSIS			= 0x00040000 (DM)

Truncates text that does not fit in the rectangle and adds ellipses.

  CENTER			= 0x00080000 (SM & DM)

B<SL:> The reference point will be aligned horizontally with the center of the
bounding rectangle.

B<ML:> Centers text horizontally in the rectangle.

  JUSTIFY			= 0x80000000 (SM)

Extends space characters to match given justification width (B<$just_width>).

B<Note:> Allways use B<$just_width> parameter with B<JUSTIFY> flag!

See also L</Font>, L</Fit>, L</Color>, L</FontSpace> and L</Write2>.

=head2 Write2

  $height = $dc->Write2($text, $x, $y, $w, [$flags, [$indento, [$hspace, [$vspace]]]]);
  ($width, $height, $proctext) = $dc->Write2($text, $x, $y, $w, [$flags, [$indent, [$hspace, [$vspace]]]]);

The B<Write2> method adds multiline justification, custom vertical and
horisontal spacing and left indent; Returns B<$height> in scalar context and
B<$width, $height, $proctext> where B<$proctext> is possibly modified text
(e.g. added line breaks).

Reasonable only when justification, left indent, custom vertical and/or
horizontal spacing is needed, othervise consider to use regular B<L</Write>>
method.

  LEFT				= 0x00000000

Aligns text to the left.

  RIGHT				= 0x00000002

Aligns text to the right.

  CENTER			= 0x00080000

Centers text horizontally in the rectangle.

  JUSTIFY			= 0x80000000 

Extends space characters to match given width.

  UTF8				= 0x20000000

Treat B<$text> as B<UTF-8> encoded string. Note that selected font must support
desired unicode characters. Available for NT platforms and also supported by
Microsoft Layer for Unicode.

See also L</Write>, L</Fit> and L</FontSpace>.

=head1 SEE ALSO

L<Win32::Printer::Enum>, L<Win32::Printer::Direct>, Win32 Platform SDK GDI
documentation.

=head1 AUTHOR

B<Edgars Binans>

=head1 COPYRIGHT AND LICENSE

This library may use I<FreeImage>, a free, open source image library
supporting all common bitmap formats. Get your free copy from 
L<http://sourceforge.net>. I<FreeImage> is licensed under the terms of
B<GNU GPL>.

This library may use I<Ghostscript> for PDF support. I<GNU Ghostscript> is
licensed under terms of B<GNU GPL>. I<AFPL Ghostscript> is licensed under the
terms of B<Aladdin Free Public License>. Download I<Ghostscript> from
L<http://sourceforge.net>.

B<Win32::Printer, Copyright (C) 2003-2005 Edgars Binans.>

B<THIS LIBRARY IS LICENSED UNDER THE TERMS OF GNU LESSER GENERAL PUBLIC LICENSE
V2.1>

=cut
