package Win32::Fonts::Info;

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);
our $CHARSETS= {
    		ANSI_CHARSET=>0,
		DEFAULT_CHARSET=>1,
		SYMBOL_CHARSET=>2,
		SHIFTJIS_CHARSET=>128,
		HANGEUL_CHARSET=>129,
		HANGUL_CHARSET=>129,
		GB2312_CHARSET=>134,
		CHINESEBIG5_CHARSET=>136,
		OEM_CHARSET=>255,
		JOHAB_CHARSET=>130,
		HEBREW_CHARSET=>177,
		ARABIC_CHARSET=>178,
		GREEK_CHARSET=>=>161,
		TURKISH_CHARSET=>162,
		VIETNAMESE_CHARSET=>163,
		THAI_CHARSET=>222,
		EASTEUROPE_CHARSET=>238,
		RUSSIAN_CHARSET=>204,
		MAC_CHARSET=>77,
		BALTIC_CHARSET=>186
};

our $FONTTYPES= {
	VECTORFONT=>1,
	TRUETYPEFONT=>2,
	RASTERFONT=>3
};

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Fonts::Info ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
	
#);
our $VERSION = '0.01';

#sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

#   my $constname;
#    our $AUTOLOAD;
#    ($constname = $AUTOLOAD) =~ s/.*:://;
#    croak "& not defined" if $constname eq 'constant';
#    local $! = 0;
#    my $val = constant($constname, @_ ? $_[0] : 0);
#    if ($! != 0) {
#	if ($! =~ /Invalid/ || $!{EINVAL}) {
#	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
#	    goto &AutoLoader::AUTOLOAD;
#	}
#	else {
#	    croak "Your vendor has not defined Win32::Fonts::Info macro $constname";
#	}
 #   }
#    {
#	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	}
#	else {
#	    *$AUTOLOAD = sub { $val };
#	}
 #   }
#    goto &$AUTOLOAD;
#}

bootstrap Win32::Fonts::Info $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new
{
	my $class = shift;
	my $self = {
		numberoffontfamilies=>undef,		# The char set to display
		TRUETYPE=>undef,
		RASTERFONTS=>undef,
		VECTORFONTS=>undef
	};
	bless $self, $class;
	return $self;
}

sub EnumFontFamilies
{
	my $self=shift;
	my $charset=shift || -1;
	my $type=shift||2;
	$self->{numberoffontfamilies} = _CalcNumFontFamilies($charset,$self->{ERROR});
	if(!$self->{numberoffontfamilies}) { return; }
	my $ret = _EnumFontFamilies($charset,$self->{numberoffontfamilies},$self->{ERROR});
	# if(!$ret) { return; }
	if(ref $ret eq "SCALAR") { return undef; }
	
	$self->{NTRUETYPEFONTS}=@$ret[0]->{NTRUETYPEFONTS};
	$self->{NVECTORFONTS}=@$ret[0]->{NVECTORFONTS};
	$self->{NRASTERFONTS}=@$ret[0]->{NRASTERFONTS};
	$self->{TRUETYPEFONT} =  @$ret[2];
	$self->{RASTERFONT} = @$ret[3];
	if(@$ret[0]->{NVECTORFONTS} != 0) { $self->{VECTORFONT} = @$ret[1]; }
	return 1;
}

sub GetError
{
	my $self=shift;
	return $self->{ERROR};
}


sub GetTrueTypeFonts
{
	my $self=shift;
	return $self->{TRUETYPEFONT} if $self->{TRUETYPEFONT};
	return undef;
}

sub GetRasterFonts
{
	my $self=shift;
	return $self->{RASTERFONT} if $self->{RASTERFONT};
	return undef;
}

sub GetVectorFonts
{
	my $self=shift;
	return $self->{VECTORFONT} if $self->{VECTORFONT};
	return undef;
}

sub GetFontInfoTTF
{
	my $self=shift;
	my $ret;
	if(@_) 
	{
		$ret= _GetFontInfo(shift,2,$self->{numberoffontfamilies},$self->{ERROR});
		if(ref $ret eq "SCALAR") { return undef; }
		return $ret;
	} else { return; }
}

sub GetFontInfoRaster
{
	my $self=shift;
	my $ret;
	if(@_) 
	{
		$ret= _GetFontInfo(shift,1,$self->{numberoffontfamilies},$self->{ERROR});
		if(ref $ret eq "SCALAR") { return undef; }
		return $ret;
	} else { return; }
}

sub GetFontInfoVector
{
	my $self=shift;
	my $ret;
	if(@_) 
	{
		$ret= _GetFontInfo(shift,3,$self->{numberoffontfamilies},$self->{ERROR});
		if(ref $ret eq "SCALAR") { return undef; }
		return $ret;
	} else { return; }
}

# Returns a hash with available character sets
sub CharSets
{
	my $self=shift;
	return $CHARSETS;
}


#sub GetFontTypes
#{
#	my $self=shift;
#	return $FONTTYPES;
#}


#### Functions to return Number of Fonts
# Number of installedt Truetype fonts
sub NumberOfTruetypeFonts
{
	my $self=shift;
	return $self->{NTRUETYPEFONTS};
}

# Number of installed Vector Fonts
sub NumberOfVectorFonts
{
	my $self=shift;
	return $self->{NVECTORFONTS};
}

# Number of installed Raster Fonts
sub NumberOfRasterFonts
{
	my $self=shift;
	return $self->{NRASTERFONTS};
}

# Number of all installed Fonts
sub NumberOfFontFamilies
{
	my $self=shift;
	return $self->{numberoffontfamilies};
}

sub DESTROY
{
	my $self=shift;
	_Cleanup();
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME 

Win32::Fonts::Info - Perl extension for get a list of installed fontfamilies on a Win32 Computer.


=head1 SYNOPSIS

  use Win32::Fonts::Info;
  my $F=Win32::Fonts::Info->new();
  my $CharSets = $F->Charsets(); # get key,value pairs of available charsets
  my %chs=%{$CharSets};
  my $ret = $F->EnumFontFamilies($chs{ANSI_CHARSET});
  
=head1 DESCRIPTION

  The Module Win32::Fonts::Info uses the GDI API EnumFontFamiliesEx() to retrive the 
  list of installed Fontfamilies.
  There are three types of fonts which can be found on a Windows system: Raster Fonts,
  Truetype Fonts and Vector Fonts. All informations about a font will be saved in two
  structures: a text metric structure (physical-font data) and a LOGFONT structure 
  (logical-font data). The Output of the functions GetFontInfo*() returns a hash 
  reference to a combination of text metrics and logical font data. Logical font data
  are begining with "elf" or "lf" and text metrics are with "tm" or "ntm".
  
  Below is an explanation of the members of the two structures.
  I use the same names for the name of the keys in the hash
  These are extracts of Platform SDK from Microsoft.

=head2 Explanation of the text metrics members

	tmHeight:		Specifies the height (ascent + descent) of characters.
	tmAscent:		Specifies the ascent (units above the base line) of characters. 
	tmDescent:		Specifies the descent (units below the base line) of characters. 
	tmInternalLeading:	Specifies the amount of leading (space) inside the bounds set by the tmHeight member. Accent marks and other diacritical characters may occur in this area. The designer may set this member to zero. 
	tmExternalLeading:	Specifies the amount of extra leading (space) that the application adds between rows. Since this area is outside the font, it contains no marks and is not altered by text output calls in either OPAQUE or TRANSPARENT mode. The designer may set this member to zero. 
	tmAveCharWidth:		Specifies the average width of characters in the font (generally defined as the width of the letter x). This value does not include overhang required for bold or italic characters. 
	tmMaxCharWidth:		Specifies the width of the widest character in the font. 
	tmWeight:		Specifies the weight of the font. 
	tmOverhang:		Specifies the extra width per string that may be added to some synthesized fonts. When synthesizing some attributes, such as bold or italic, graphics device interface (GDI) or a device may have to add width to a string on both a per-character and per-string basis. For example, GDI makes a string bold by expanding the spacing of each character and overstriking by an offset value; it italicizes a font by shearing the string. In either case, there is an overhang past the basic string. For bold strings, the overhang is the distance by which the overstrike is offset. For italic strings, the overhang is the amount the top of the font is sheared past the bottom of the font. 
            			The tmOverhang member enables the application to determine how much of the character width returned by a GetTextExtentPoint32 function call on a single character is the actual character width and how much is the per-string extra width. The actual width is the extent minus the overhang. 

	tmDigitizedAspectX:     Specifies the horizontal aspect of the device for which the font was designed. 
	tmDigitizedAspectY:     Specifies the vertical aspect of the device for which the font was designed. The ratio of the tmDigitizedAspectX and tmDigitizedAspectY members is the aspect ratio of the device for which the font was designed. 
	tmFirstChar:		Specifies the value of the first character defined in the font. 
	tmLastChar:		Specifies the value of the last character defined in the font. 
	tmDefaultChar:         	Specifies the value of the character to be substituted for characters that are not in the font. 
	tmBreakChar:         	Specifies the value of the character to be used to define word breaks for text justification. 
	tmItalic:         	Specifies an italic font if it is nonzero. 
	tmUnderlined:		Specifies an underlined font if it is nonzero. 
	tmStruckOut:		Specifies a strikeout font if it is nonzero. 
	tmPitchAndFamily:	Specifies the pitch and family of the selected font. The low-order bit (bit 0) specifies the pitch of the font. If it is 1, the font is variable pitch (or proportional). If it is 0, the font is fixed pitch (or monospace). Bits 1 and 2 specify the font type. If both bits are 0, the font is a raster font; if bit 1 is 1 and bit 2 is 0, the font is a vector font; if bit 1 is 0 and bit 2 is set, or if both bits are 1, the font is some other type. Bit 3 is 1 if the font is a device font; otherwise, it is 0. 
				The four high-order bits designate the font family. The tmPitchAndFamily member can be combined with the hexadecimal value 0xF0 by using the bitwise AND operator and can then be compared with the font family names for an identical match. For more information about the font families, see LOGFONT. 
  
	tmCharSet:         	Specifies the character set of the font. 
	ntmFlags:		Specifies whether the font is italic, underscored, outlined, bold, and so forth. May be any reasonable combination of the following values. Bit Name Meaning 
        	           	0 NTM_ITALIC italic 
                   		5 NTM_BOLD bold 
				8 NTM_REGULAR regular 
				16 NTM_NONNEGATIVE_AC Windows 2000/XP: no glyph in a font at any size has a negative A or C space. 
				17 NTM_PS_OPENTYPE Windows 2000/XP: PostScript OpenType font 
				18 NTM_TT_OPENTYPE Windows 2000/XP: TrueType OpenType font 
				19 NTM_MULTIPLEMASTER Windows 2000/XP: multiple master font 
				20 NTM_TYPE1 Windows 2000/XP: Type 1 font 
				21 NTM_DSIG Windows 2000/XP: font with a digital signature. This allows traceability and ensures that the font has been tested and is not corrupted 
  
	ntmSizeEM:		Specifies the size of the em square for the font. This value is in notional units (that is, the units for which the font was designed). 
	ntmCellHeight:		Specifies the height, in notional units, of the font. This value should be compared with the value of the ntmSizeEM member. 
	ntmAvgWidth:		Specifies the average width of characters in the font, in notional units. This value should be compared with the value of the ntmSizeEM member. 

=head2 Explanation of the log font members

	lfHeight:	Specifies the height, in logical units, of the font's character cell or character. The character height value (also known as the em height) is the character cell height value minus the internal-leading value. The font mapper interprets the value specified in lfHeight in the following manner. Value Meaning 
        		> 0 The font mapper transforms this value into device units and matches it against the cell height of the available fonts. 
			0 The font mapper uses a default height value when it searches for a match. 
			< 0 The font mapper transforms this value into device units and matches its absolute value against the character height of the available fonts. 

			For all height comparisons, the font mapper looks for the largest font that does not exceed the requested size. 
			This mapping occurs when the font is used for the first time. 
			For the MM_TEXT mapping mode, you can use the following formula to specify a height for a font with a specified point size: 
			lfHeight = -MulDiv(PointSize, GetDeviceCaps(hDC, LOGPIXELSY), 72);

	lfWidth     	Specifies the average width, in logical units, of characters in the font. If lfWidth is zero, the aspect ratio of the device is matched against the digitization aspect ratio of the available fonts to find the closest match, determined by the absolute value of the difference. 
	lfEscapement	Specifies the angle, in tenths of degrees, between the escapement vector and the x-axis of the device. The escapement vector is parallel to the base line of a row of text. 
			Windows NT/2000/XP: When the graphics mode is set to GM_ADVANCED, you can specify the escapement angle of the string independently of the orientation angle of the string's characters. 
			When the graphics mode is set to GM_COMPATIBLE, lfEscapement specifies both the escapement and orientation. You should set lfEscapement and lfOrientation to the same value. 
			Windows 95/98/Me: The lfEscapement member specifies both the escapement and orientation. You should set lfEscapement and lfOrientation to the same value. 

	lfOrientation	Specifies the angle, in tenths of degrees, between each character's base line and the x-axis of the device. 
	lfWeight     	Specifies the weight of the font in the range 0 through 1000. For example, 400 is normal and 700 is bold. If this value is zero, a default weight is used. 
			The following values are defined for convenience. Value Weight 
		        FW_DONTCARE 0
        		FW_THIN 100 
        		FW_EXTRALIGHT 200 
        		FW_ULTRALIGHT 200 
        		FW_LIGHT 300 
        		FW_NORMAL 400 
        		FW_REGULAR 400 
        		FW_MEDIUM 500 
        		FW_SEMIBOLD 600 
        		FW_DEMIBOLD 600 
        		FW_BOLD 700 
        		FW_EXTRABOLD 800 
        		FW_ULTRABOLD 800 
        		FW_HEAVY 900 
        		FW_BLACK 900 

	lfItalic     Specifies an italic font if set to TRUE. 
	lfUnderline     Specifies an underlined font if set to TRUE. 
	lfStrikeOut     Specifies a strikeout font if set to TRUE. 
	lfCharSet     Specifies the character set. The following values are predefined. 
	                ANSI_CHARSET
	        	BALTIC_CHARSET
	        	CHINESEBIG5_CHARSET
	        	DEFAULT_CHARSET
	        	EASTEUROPE_CHARSET
	        	GB2312_CHARSET
	        	GREEK_CHARSET
	        	HANGUL_CHARSET
	        	MAC_CHARSET
	        	OEM_CHARSET
	        	RUSSIAN_CHARSET
	        	SHIFTJIS_CHARSET
	        	SYMBOL_CHARSET
	        	TURKISH_CHARSET
	        	VIETNAMESE_CHARSET 
	        	
	        	Korean language edition of Windows: 
	        	JOHAB_CHARSET 
	        	
	        	Middle East language edition of Windows: 
	        	ARABIC_CHARSET
	        	HEBREW_CHARSET 
	        	
	        	Thai language edition of Windows: 
	        	THAI_CHARSET 
	        	The OEM_CHARSET value specifies a character set that is operating-system dependent. 
	        	Windows 95/98/Me: You can use the DEFAULT_CHARSET value to allow the name and size of a font to fully describe the logical font. If the specified font name does not exist, a font from any character set can be substituted for the specified font, so you should use DEFAULT_CHARSET sparingly to avoid unexpected results. 
	        	Windows NT/2000/XP: DEFAULT_CHARSET is set to a value based on the current system locale. For example, when the system locale is English (United States), it is set as ANSI_CHARSET. 
	        	Fonts with other character sets may exist in the operating system. If an application uses a font with an unknown character set, it should not attempt to translate or interpret strings that are rendered with that font. 
	        	This parameter is important in the font mapping process. To ensure consistent results, specify a specific character set. If you specify a typeface name in the lfFaceName member, make sure that the lfCharSet value matches the character set of the typeface specified in lfFaceName. 
	
	lfOutPrecision	Specifies the output precision. The output precision defines how closely the output must match the requested font's height, width, character orientation, escapement, pitch, and font type. It can be one of the following values. Value Meaning 
	        	OUT_CHARACTER_PRECIS Not used. 
        		OUT_DEFAULT_PRECIS Specifies the default font mapper behavior. 
        		OUT_DEVICE_PRECIS Instructs the font mapper to choose a Device font when the system contains multiple fonts with the same name. 
        		OUT_OUTLINE_PRECIS Windows NT/2000/XP: This value instructs the font mapper to choose from TrueType and other outline-based fonts. 
        		OUT_PS_ONLY_PRECIS Windows 2000/XP: Instructs the font mapper to choose from only PostScript fonts. If there are no PostScript fonts installed in the system, the font mapper returns to default behavior. 
        		OUT_RASTER_PRECIS Instructs the font mapper to choose a raster font when the system contains multiple fonts with the same name. 
        		OUT_STRING_PRECIS This value is not used by the font mapper, but it is returned when raster fonts are enumerated. 
        		OUT_STROKE_PRECIS Windows NT/2000/XP: This value is not used by the font mapper, but it is returned when TrueType, other outline-based fonts, and vector fonts are enumerated. 
        		Windows 95:This value is used to map vector fonts, and is returned when TrueType or vector fonts are enumerated. 
        		OUT_TT_ONLY_PRECIS Instructs the font mapper to choose from only TrueType fonts. If there are no TrueType fonts installed in the system, the font mapper returns to default behavior. 
        		OUT_TT_PRECIS Instructs the font mapper to choose a TrueType font when the system contains multiple fonts with the same name. 
        		
        		Applications can use the OUT_DEVICE_PRECIS, OUT_RASTER_PRECIS, OUT_TT_PRECIS, and OUT_PS_ONLY_PRECIS values to control how the font mapper chooses a font when the operating system contains more than one font with a specified name. For example, if an operating system contains a font named Symbol in raster and TrueType form, specifying OUT_TT_PRECIS forces the font mapper to choose the TrueType version. Specifying OUT_TT_ONLY_PRECIS forces the font mapper to choose a TrueType font, even if it must substitute a TrueType font of another name. 

	lfClipPrecision Specifies the clipping precision. The clipping precision defines how to clip characters that are partially outside the clipping region. It can be one or more of the following values. Value Meaning 
        		CLIP_CHARACTER_PRECIS Not used. 
        		CLIP_DEFAULT_PRECIS Specifies default clipping behavior. 
        		.htm  CLIP_DFA_DISABLE Windows XP SP1: Turns off font association for the font. Note that this flag is not guaranteed to have any effect on any platform after Windows Server 2003.  
        		CLIP_EMBEDDED You must specify this flag to use an embedded read-only font. 
        		CLIP_LH_ANGLES When this value is used, the rotation for all fonts depends on whether the orientation of the coordinate system is left-handed or right-handed. 
        		If not used, device fonts always rotate counterclockwise, but the rotation of other fonts is dependent on the orientation of the coordinate system. 
        		CLIP_MASK Not used. 
        		For more information about the orientation of coordinate systems, see the description of the nOrientation parameter
        		CLIP_DFA_OVERRIDE Windows 2000: Turns off font association for the font. This is identical to CLIP_DFA_DISABLE, but it can have problems in some situations; the recommended flag to use is CLIP_DFA_DISABLE.  
        		CLIP_STROKE_PRECIS Not used by the font mapper, but is returned when raster, vector, or TrueType fonts are enumerated. 
        		Windows NT/2000/XP: For compatibility, this value is always returned when enumerating fonts. 
        		CLIP_TT_ALWAYS Not used. 
	lfQuality     	Specifies the output quality. The output quality defines how carefully the graphics device interface (GDI) must attempt to match the logical-font attributes to those of an actual physical font. It can be one of the following values. Value Meaning 
        		ANTIALIASED_QUALITY Windows NT 4.0 and later: Font is always antialiased if the font supports it and the size of the font is not too small or too large. 
        		Windows 95 Plus!, Windows 98/Me: The display must greater than 8-bit color, it must be a single plane device, it cannot be a palette display, and it cannot be in a multiple display monitor setup. In addition, you must select a TrueType font into a screen DC prior to using it in a DIBSection, otherwise antialiasing does not occur.
        		CLEARTYPE_QUALITY Windows XP: If set, text is rendered (when possible) using ClearType antialiasing method. See Remarks for more information. 
        		DEFAULT_QUALITY Appearance of the font does not matter. 
        		DRAFT_QUALITY Appearance of the font is less important than when PROOF_QUALITY is used. For GDI raster fonts, scaling is enabled, which means that more font sizes are available, but the quality may be lower. Bold, italic, underline, and strikeout fonts are synthesized if necessary. 
        		NONANTIALIASED_QUALITY Windows 95/98/Me, Windows NT 4.0 and later: Font is never antialiased. 
        		PROOF_QUALITY Character quality of the font is more important than exact matching of the logical-font attributes. For GDI raster fonts, scaling is disabled and the font closest in size is chosen. Although the chosen font size may not be mapped exactly when PROOF_QUALITY is used, the quality of the font is high and there is no distortion of appearance. Bold, italic, underline, and strikeout fonts are synthesized if necessary. 
        		If neither ANTIALIASED_QUALITY nor NONANTIALIASED_QUALITY is selected, the font is antialiased only if the user chooses smooth screen fonts in Control Panel. 

	lfPitchAndFamily Specifies the pitch and family of the font. The two low-order bits specify the pitch of the font and can be one of the following values. 
        		DEFAULT_PITCH
        		FIXED_PITCH
        		VARIABLE_PITCH 
        		Bits 4 through 7 of the member specify the font family and can be one of the following values. 
        		
        		FF_DECORATIVE
        		FF_DONTCARE
        		FF_MODERN
        		FF_ROMAN
        		FF_SCRIPT
        		FF_SWISS 
        		The proper value can be obtained by using the Boolean OR operator to join one pitch constant with one family constant. 
        		Font families describe the look of a font in a general way. They are intended for specifying fonts when the exact typeface desired is not available. The values for font families are as follows. Value Meaning 
        		
        		FF_DECORATIVE Novelty fonts. Old English is an example. 
        		FF_DONTCARE Use default font. 
        		FF_MODERN Fonts with constant stroke width (monospace), with or without serifs. Monospace fonts are usually modern. Pica, Elite, and CourierNew are examples. 
        		FF_ROMAN Fonts with variable stroke width (proportional) and with serifs. MS Serif is an example. 
        		FF_SCRIPT Fonts designed to look like handwriting. Script and Cursive are examples. 
        		FF_SWISS Fonts with variable stroke width (proportional) and without serifs. MS Sans Serif is an example. 

	lfFaceName     A null-terminated string that specifies the typeface name of the font. The length of this string must not exceed 32 characters, including the terminating null character. The EnumFontFamiliesEx function can be used to enumerate the typeface names of all currently available fonts. If lfFaceName is an empty string, GDI uses the first font that matches the other specified attributes. 

=head1 FUNCTIONS

=head2 NOTE

=over 4

=item new()

 The constructor. No Parameters required
  
=item CharSets()

 This function returns a hashref to the available character sets. 
 This character sets are used to in the EnumFontfamilies() function to get the installed fonts for a given character set.
 my $charset = $F->CharSets();
 foreach (keys %{$charset})
 {
     print "$_=" . %{$charset}->{$_} . "\n";
 }
 How to use it: 
 my %chs=%{$charset};
 $F->EnumFontFamilies($chs{ANSI_CHARSET});
 to get only fontfamilies for the ANSI_CHARSET

=item EnumFontFamilies()

 This function is neccessary. He will load all font families into a structure.
 $F->EnumFontFamilies($charset);
 
 $charset is the character set which you want to use.
 The return value can be undef on error or 1 on success.

=back

=head1 FUNCTIONS to display information and get a short summary of the fonts.

=over 4

=item GetTrueTypeFonts(), GetRasterFonts(),GetVectorFonts()

  I divided them into 3 different functions to get only the font type the user want.
  Return value : These function are returning a hashref on success or undef on error.
  Use the GetError() function to see which error occured.
  Sample:
  my $truetypefonts = $F->GetTrueTypeFonts();
  foreach (keys %{$truetypefonts})
  {
    print $_ . "=" . %{$truetypefonts}->{$_} . "\n";
  } 

=item  NumberOfTruetypeFonts, NumberOfVectorFonts, NumberOfRasterFonts, NumberOfFontFamilies

 These functions are returning the number of installed font families for the specific type.
 NumberOfFontFamilies return the number of all installed font families (Vector, Raster and Truetype).

=item GetFontInfoTTF(), GetFontInfoRaster(), GetFontInfoRaster()

 With these function several informations about the given font will be returned.
 Example:
     my $fontinfo=$F->GetFontInfoTTF("Arial");
     # $fontinfo=$F->GetFontInfoTTF(%{$truetypefonts}->{$_});
    foreach (keys %{$fontinfo})
    {
        print $_ . " = " . %{$fontinfo}->{$_} . "\n";
    }
 To get a specific information use the structure member names described in \"Explanation of the log font members\" and \"Explanation of the text metrics members\".

=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Reinhard Pagitsch, E<lt>rpirpag@gmx.atE<gt>

=head1 SEE ALSO

L<perl>.

=cut
