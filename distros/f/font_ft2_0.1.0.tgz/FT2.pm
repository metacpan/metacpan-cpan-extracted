package FONT::FT2;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FT2 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

	render_table
	get_bitmap	
	bitmap_width
	render_list
	bitmap_as_text
	bitmap_as_xpm
	init

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.1.0';

our @error_messages;

# @debug_messages = ([debug_level, subroutine, message]);
# debug_level 1 = stop/start of procedures.
# debug_level 2 = stop/start of procedure sections
# debug_level 3 = procedure wide variables
our @debug_messages;
our @messages;
our $debug = undef;

sub bitmap_as_xpm {

	my ($rh_bitmap) = @_;
	my $retval;
	my ($i, $bit);
	my %color_hash;
	my $i_num_colors = 3;
	my @unused_colors = (0..9, 'a'..'z', 'A'..'W', 'Y', 'Z');
	$i = 1;

	if (!defined($rh_bitmap->{'ok'})) {
		push(@error_messages, 'Invalid or errored bitmap sent to bitmap_as_xpm');
		return undef;
	}
	
	if (($rh_bitmap->{'width'} < 1) or ($rh_bitmap->{'height'} < 1)) {
		push(@error_messages, 'Bitmap is initialized, but has no content');
		return undef;
	}

	$retval = "/* XPM */\n";
	$retval .= "static char * act_fold_xpm[] = {\n";
	$retval .= "/* width height num_colors chars_per_pixel */\n";
	my $colors = '/* colors */' . "\n";
	$colors .= '"       s None  c None",' . "\n";
	$colors .= '".      c white",' . "\n";
	$colors .= '"X      c black",' . "\n";
	my $pixmap = '/* pixels */' . "\n";

	# Change 1/0's to set characters, then append to retval.  
	# Append comma's and quotes.  Append \n if appropriate
	foreach $bit(@{$$rh_bitmap{'bitmap'}}) {
		if ($i == 1) {$pixmap .= '"';}
		if (!defined($bit) or ($bit eq '0')) {$bit = ' ';}
		elsif ($bit =~ /^0x[0-9a-f]{6}$/) {
			if (defined($color_hash{$bit})) {
				$bit = $color_hash{$bit};
			} else {
				my $color_char = pop(@unused_colors);
				if (!defined($color_char)) {
					push(@error_messages, "No more colors!  bitmap_as_xpm failed!");
					return (undef);
				}
				$color_hash{$bit} = $color_char;
				$bit =~ s/0x([0-9a-f]{6})/\#$1/;
				$colors .= "\"$color_char" . ' 'x6 . "c $bit\",\n";
				$bit = $color_char;
				$i_num_colors++;
			}
		} else {$bit = 'X';}
	  $pixmap .= "$bit";
	  if ($i == $rh_bitmap->{'width'}) {$pixmap .= "\",\n"; $i = 0;}
	  $i++;
	}

	# Clean off , and \n from last line
	chomp($pixmap);
	chop($pixmap);

	# Add }; and \n to last line
	$pixmap .= '};' . "\n";

	$retval .= "\"$$rh_bitmap{'width'} $$rh_bitmap{'height'} $i_num_colors 1\"\n";
	$retval .= $colors . $pixmap;

	return $retval;

}

sub bitmap_as_text {

	my ($rh_bitmap, $set_bit, $not_set_bit) = @_;

	if (!defined($rh_bitmap->{'ok'})) {
		push(@error_messages, 'Invalid or errored bitmap sent to bitmap_as_text');
		return undef;
	}
	
	if (($rh_bitmap->{'width'} < 1) or ($rh_bitmap->{'height'} < 1)) {
		push(@error_messages, 'Bitmap is initialized, but has no content');
		return undef;
	}

	if (!defined($set_bit) or !defined($not_set_bit) or ($not_set_bit =~ /^(.{0}|.{2,})$/) or ($set_bit =~ /^(.{0}|.{2,})$/)){
		push(@error_messages, 'Invalid characters sent to bitmap_as_text');
		return undef;
	}

	my $retval;
	my ($i, $bit);
	$i = 1;
	foreach $bit(@{$$rh_bitmap{'bitmap'}}) {
		if (!defined($bit) or ($bit eq '0')) {$bit = $not_set_bit;}
		else {$bit = $set_bit;}
	  $retval .= "$bit";
	  if ($i == $rh_bitmap->{'width'}) {$retval .= "\n"; $i = 0;}
	  $i++;
	}

	return $retval;

}

sub render_table {

	my ($column_width, $row_height, $rows, $columns, $chars, $colors, $char_height, $char_width) = @_;

	my (@bitmap, $pen_x, $pen_y, $row, $column, $i_cell, %retval);
	$bitmap[$rows*$columns*$column_width*$row_height-1] = 0;				# Set last bit to declare array
	($pen_x, $pen_y, $row, $column) = (0, 0, 0, 0);

	$retval{'width'} = ($column_width*$columns);
	$retval{'height'} = ($row_height*$rows);
	$retval{'bitmap'} = \@bitmap;
	$retval{'error'} = undef;
	$retval{'ok'} = 1;

	for ($i_cell = 0; $i_cell < ($rows*$columns); $i_cell++) {
#		print "$i_cell\n";
		my $i_temp = $$chars[$i_cell];
		my $glyph_index = get_glyph_index($i_temp);
		my $retval = set_transform(0, $char_height, $char_width);
		my $sub_retval = render($glyph_index);
		my $width  = width($glyph_index);
		my $height = height($glyph_index);
		my $rh_bitmap = get_bitmap($glyph_index);
		my $column = $i_cell % $columns;
		my $row = int(($i_cell - $column)/$columns);
		$pen_x = ($column)*$column_width;
#		$pen_x = ($column)*$column_width + ($column_width/2) - ($width/2);
		my $char_bitmap_pen;
#		print "Pen X is $pen_x\n";
#		print "Column is $column\n";
#		print "Row is $row\n";

		for ($char_bitmap_pen = 0; $char_bitmap_pen < (bitmap_width($width)*$height); $char_bitmap_pen++) {
#			my $pen = (($char_bitmap_pen % $width) + (($i_cell-1 % $columns)*$column_width*($columns-1)) + (($i_cell-1 % ($row*$columns)) *$column_width*$columns));
			my $cell_column = int ($char_bitmap_pen % bitmap_width($width));
			my $cell_row = int ($char_bitmap_pen-($cell_column))/bitmap_width($width) + int($row_height/2) - int($height/2);
#			my $cell_row = ($char_bitmap_pen-($cell_column))/$width + ($row_height/2) - ($height/2);
			my $pen = (
					($row * $columns * $column_width * $row_height) +	# Add XY from above cells
					$cell_row * ($columns*$column_width) +			# Add cell pixels above pen 
					($column*$column_width) + 				# add X from left cells
					($cell_column) + int($column_width/2) - int($width/2)	# Set cell start x
				);
#			print "cell_row = $cell_row\n";
#			print "cell_column = $cell_column\n";
#			print " '$pen' ";
			if (!defined($$colors[$i_cell])) {
				$bitmap[$pen] = $$rh_bitmap{'bitmap'}[$char_bitmap_pen];
			} else {
				if (defined($$rh_bitmap{'bitmap'}[$char_bitmap_pen]) and ($$rh_bitmap{'bitmap'}[$char_bitmap_pen] eq '1')){
					$bitmap[$pen] = $$colors[$i_cell];
				}
			}
#			print $$rh_bitmap{'bitmap'}[$char_bitmap_pen];
		}
	}
	return (\%retval);

}

sub render_list {

	my %retval;

	my ($angle, $height, $width, @chars) = @_;

	my @sub_bitmaps;
	my $i=0;
	my $i_char;
	my $r_char;

	$retval{'width'} = 0;
	$retval{'height'} = 0;
	$retval{'error'} = undef;
	$retval{'ok'} = 1;
	my @bitmap;
	if (!defined($chars[0])) {
		$retval{'error'} = 1;
		$retval{'error_message'} = 'No arguments';
		return \%retval;
	}

	foreach $i_char(@chars) {
		my $glyph_index = get_glyph_index($i_char);
		my $retval = set_transform(0, $height, $width);
		$retval = render($glyph_index);
		$sub_bitmaps[$i]->{'width'} = width($glyph_index);
		$sub_bitmaps[$i]->{'height'} = height($glyph_index);
		my $rh_bitmap = get_bitmap($glyph_index);
		$sub_bitmaps[$i]->{'bitmap'} = $$rh_bitmap{'bitmap'};
		$i++;
	}

	foreach $r_char(@sub_bitmaps) {
		if ($r_char->{'height'} > $retval{'height'}) {
			$retval{'height'} = $r_char->{'height'};
		}
		$retval{'width'} += $r_char->{'width'};
	}

	my $j;
	for ($i = 0; $i<$retval{'height'}; $i++) {
		my $pen_x = 0;
		foreach $r_char(@sub_bitmaps) {
			for ($j = 0; $j < $r_char->{'width'}; $j++) {
				$bitmap[($i*$retval{'width'}) + $pen_x + $j] = $r_char->{'bitmap'}->[($i*bitmap_width($r_char->{'width'}))+$j];
			}
			$pen_x += $j;
		}
	}

	$retval{'bitmap'} = \@bitmap;

	return \%retval;
}

sub bitmap_width {

	my $width = shift;

	if (!defined($width)) { return undef; }

	my $bitmap_width = ($width-($width%8));
	if (($width%8) != 0) { $bitmap_width += 8; }

	return ($bitmap_width);

}

sub get_bitmap {

	my $glyph_index = shift;

	my %retval;
	my @bitmap;

	$retval{'width'} = width($glyph_index);
	$retval{'height'} = height($glyph_index);
	$retval{'error'} = undef;
	$retval{'ok'} = 1;
	my $bitmap_width = bitmap_width($retval{'width'});
	my $i;
	for ($i=0; $i<$retval{'height'}*$bitmap_width/8; $i++) {
		my $char = get_byte($i);
		push(@bitmap, split(' *', (unpack('B8',$char))));
	}
	$retval{'bitmap'} = \@bitmap;
	return(\%retval);

}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined FT2 macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap FONT::FT2 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

FONT::FT2 - Perl extension for FreeType 2

=head1 SYNOPSIS

	use FONT::FT2 ':all';
	my $retval = init("/usr/share/fonts/ttf/gkai00mp.ttf"); #italic

	$retval = render_table (40, 56, 2, 2, [65, 66, 0x4eba, 0x4ebb], ['0xff0000', '0x00ff00', '0x0000ff', undef], 0x20000, 0x20000);

	open(OUTPUT, '> temp.xpm');
	print OUTPUT bitmap_as_xpm($retval);
	close(OUTPUT);

=head1 DESCRIPTION

  This is a set of subroutine for using Freetype 2 from Perl.  For now, this is mostly a functional
  implimentation, and is not yet intended to be perfect subroutine to subroutine remap of Freetype 2.
  Although, that is a goal.

=head2 EXPORT

None by default.

=head2 Global Variables

  @error_messages	= Messages explaining a failure.
  @messages		= Normal messages.
  $debug		= undef when no debugging is wished.  A debugging level when
  				debugging is enabled.  Note, debug messages are stored in
  				@debug_messages regardless.  Not normally used in a library.
  @debug_messages	= Debugging messages
  				# @debug_messages = ([debug_level, $subroutine_name, $message], etc);
  				# debug_level 1 = stop/start of procedures.
  				# debug_level 2 = stop/start of procedure sections
  				# debug_level 3 = procedure wide variables
  				# debug_level 4 = looping

=cut

=head2 bitmap format

  Generally, the bitmaps passed around internally by FONT::FT2 are a
  reference to a hash.  The hash contains (at least) the keys 'ok', 'error',
  'width','height','bitmap'.  'width' and 'height' are the size of the
  bitmap in pixels.  'bitmap' is a reference to a one dimentional array representing
  the pixels of the bitmap.  The pixels for now are just 1's, 0's, and undef's.  Soon,
  you will have grayscale images representated as values from 0->255.  And, you will
  have colors represented by an eight byte string, representing the hex RGB value for
  colors such as '0xFF00FF' for purple.
  
  When OK is not defined, the bitmap is not valid.  Often, OK will be defined, but
  error will be as well.  If error is defined, it will contain an error message.
  
  Bitmaps are left to right, then down.  So, the first row of pixels in the bitmap will
  be the first set of data.

=cut

=head2 sub render_table

Description:

  subroutine render table returns a string containing a xpm pixmap representation of the string of
  characters in table format.  Upon failure, a message is appended to error messages and undef is returned.

  See 

Syntax:

  my $retval = render_table ($column_width, $row_height, $rows, $columns, $chars, $colors, $char_height, $char_width);
	Where:
		$retval		= A standard FONT::FT2 bitmap (see section "bitmap format").  Undef on
			failure.
		$column_width	= the width of each column to produce in pixels
		$row_height	= the height of each row to produce (ie, cell height) in pixels
		$rows		= the number of rows
		$columns	= the number of columns
		$chars		= a reference to a one dimentional array of char codes to produce.  Only
			valid numbers are accepted.  Strings of numbers fail.  So, 0x30b9 works but '0x30b9' doesn't.
			use int() and hex() to convert string to number.
		$colors		= a reference to a one dimentional array of colors to use for those characters, undef for no color
		$char_height    = the height of the characters to produce (in freetype units, 0x10000 is safe)
		$char_width	= the width of the characters to produce (in freetype units, 0x10000 is safe)

=cut

=head2 sub render_list

Description:

  subroutine render_list is a simple renderer.

Syntax:

  my $retval = render_list ( $angle, $char_height, $char_width, @chars );
	Where:
		$retval		= A standard FONT::FT2 bitmap (see section "bitmap format").  Undef on
			failure.
		$angle		= the angle in radians to use to rotate the characters.
		$char_height    = the height of the characters to produce (in freetype units, 0x10000 is safe)
		$char_width	= the width of the characters to produce (in freetype units, 0x10000 is safe)
		@chars		= an of char codes to produce.  Only valid numbers are accepted.
			Strings of numbers fail.  So, 0x30b9 works but '0x30b9' doesn't.
			Use int() and hex() to convert string to number.
	
=cut

=head2 sub get_bitmap

Description:

 	subroutine get_bitmap returns the bitmap representing the character.

Syntax:

	my @bitmap = get_bitmap( $glyph_index );
		Where:
			$glyph_index	= the index of the glyph in the font record
			@bitmap		= An array of integers representing the bitmap.
			ones and zeros in the case of a non-grayscale bitmap.  0-255 in
			the case of a 256 shade grayscale bitmap.  Warning, the width
			of the bitmap and the width of the character may not match.  The
			width of the bitmap is the first multiple of eight equal or
			greater than the width of the character.

=cut

=head2 sub bitmap_as_xpm

Description:

  subroutine bitmap_as_xpm returns a set of text lines representing the bitmap,
  in the format of an X windows X Pix Map, or XPM.

  Upon failure, undef is returned.

Syntax:

  my $text = bitmap_as_xpm( $rh_bitmap );
	Where:
		$text = the text representation of the bitmap
		$rh_bitmap = a reference to a hash representing the FONT::FT2 internal
			bitmap format.

Caveats:

  bitmap_as_xpm only supports about 62 colors for now.

Example:

  my $text = bitmap_as_xpm( $rh_bitmap );

=cut 


=head2 sub bitmap_as_text

Description:

  subroutine bitmap_as_text returns a set of text lines representing the bitmap,
  including line feeds.

Syntax:

  my $text = bitmap_as_text( $rh_bitmap, $set_bit, $not_set_bit );
	Where:
		$text = the text representation of the bitmap
		$rh_bitmap = a reference to a hash representing the FONT::FT2 internal
			bitmap format.
		$set_bit = the character to use for bits in the bitmap that are set
		$not_set_bit = the character to use for bits in the bitmap that are not set

Example:

  my $text = bitmap_as_text( $rh_bitmap, 'X', '.' );

=cut 

=head2 sub bitmap_width

Description:

  subroutine bitmap_width returns the width of a characters bitmap.  This may be larger than the
  width of the character.  Because, bitmaps returns by Freetype 2 are multiples of 8 in width.

Syntax:

  my $bitmap_width = bitmap_width( $width );
	Where:
		$bitmap_width = undef on failure, the width of the bitmap on success.
		$width = the width of the actual character in the bitmap.

=cut

=head2 sub init

Description:

  subroutine init initializes Freetype 2 and loads the font file.

Syntax:

  $retval = FT2::init ( $font_file );
	Where:
		$retval = undef on failure.  true on success.
		$font_file = the name of the font to be loaded.

=cut

=head2 sub get_glyph_index

Description:

  subroutine get_glyph_index returns the font's internal index for a character.

Syntax:

  $glyph_index = get_glyph_index ( $character_code );
	Where:
		$glyph_index = undef on failure, an integer for the index of the character
			on success.
		$character_code = the standard integer identifier for the character, normally
			the ASCII/Unicode value.

=cut

=head2 sub set_transform

Description:

  subroutine set_transform set's the angle, height, and width of the character to be returns.  If
  someone could send me examples of other transforms (non size/rotate transforms) in Freetype 2
  I would appreciate it.

Syntax:

  $retval = set_transform ( $angle, $height, $width );
	Where:
		$angle = the angle to rotate the character in Radians (0 for no rotation)
		$height = the height to generate the character in.  Apparently a value of about 5000
			here represents about 1 pixel.  A safe value is 0x10000.
		$width = the width to generate the character in.  A safe value is 0x10000.

=cut

=head2 sub render

Description:

  subroutine render renders the bitmap in RAM following the prespecified parameters.

Syntax:

  $retval = FONT::FT2::render ( $glyph_index );
	Where:
		$glyph_index = the font file's index for this character as specified by the
			get_glyph_index function.

=cut

=head2 sub height

Description:

  subroutine height returns the height of a rendered character in pixels.

Syntax:

  $height = FONT::FT2::height ( $glyph_index );
	Where:
		$height		= undef on failure, the height of the character in pixels on success.
		$glyph_index	= the font file's index for this character as specified by the
			get_glyph_index function.

=cut

=head2 sub width

Description:

  subroutine width returns the width of a rendered character in pixels.

Syntax:

  $width = FONT::FT2::width ( $glyph_index );
	Where:
		$width		= undef on failure, the width of the character in pixels on success.
		$glyph_index	= the font file's index for this character as specified by the
			get_glyph_index function.

=cut

=head2 sub get_byte

Description:

  subroutine get_byte returns any byte in the internal freetype bitmap.  This subroutine was creates because
  any get_bitmap function would need to return an array.  But, the only supported array time I understoon
  was char *, which ends the string at a null character (of which there are many in a character bitmap).

  This subroutine is not intended for the end user.

  Calling get_byte with an index larger than the bitmap will only return characters within the bitmap.

Syntax:

  my $byte = FONT::FT2::get_byte ( $index );
	Where
		$byte	= A byte (could be considered a char) representing one byte of the bitmap.
		$index	= The offset of the byte to be returned

=cut

=head1 AUTHOR

Andrew Robertson <tuxthepenquin@yahoo.com>

=head1 Liscense

GPL 2.  

=head1 SEE ALSO

perl(1).

=cut
