#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;

use Image::Magick;

# ----------------

my($image)		= Image::Magick -> new;
my(@fonts)		= $image -> QueryFont;
my(@formats)	= $image -> QueryFormat;

# Semi-random numbers depend on the default list of fonts
#  installed /on my laptop/ under Debian stable V 8.2.

my(%symbolic_font) =
(
	 55 => 1,
	 56 => 1,
	 57 => 1,
	 58 => 1,
	 84 => 1,
	 85 => 1,
	 86 => 1,
	 87 => 1,
	 88 => 1,
	 91 => 1,
	 92 => 1,
	 94 => 1,
	 95 => 1,
	 97 => 1,
	 98 => 1,
	 99 => 1,
	100 => 1,
	106 => 1,
	107 => 1,
	149 => 1,
	150 => 1,
	167 => 1,
	168 => 1,
	169 => 1,
	178 => 1,
	179 => 1,
	180 => 1,
	181 => 1,
	182 => 1,
	183 => 1,
	184 => 1,
	185 => 1,
	186 => 1,
	187 => 1,
	188 => 1,
	189 => 1,
	190 => 1,
	191 => 1,
	192 => 1,
	193 => 1,
	194 => 1,
	195 => 1,
	196 => 1,
	197 => 1,
	198 => 1,
	199 => 1,
	200 => 1,
	201 => 1,
	202 => 1,
	203 => 1,
	204 => 1,
	205 => 1,
	219 => 1,
);

say "Font count:   @{[$#fonts + 1]}";
say "Format count: @{[$#formats + 1]}";

my($font_count)	= $#fonts;
my($font_size)	= 40;
my($x)			= 20;
my($y)			= 0;
my($y_step)		= $font_size + 5;
my(@size)		= (1100, $y_step * ($font_count + 2) );

say "Image size:   ($size[0] x $size[1])";

my($image)	= Image::Magick -> new(size => "$size[0]x$size[1]");
my($result) = $image -> Read('canvas:white');

die $result if $result;

$result = $image -> Frame(fill => 'red', geometry => '2x2');

die $result if $result;

my($font);

for my $font_index (0 .. $#fonts)
{
	$font	= $fonts[$font_index];
	$y		+= $y_step;

	$image->Annotate
	(
		fill		=> 'green',
		font		=> $symbolic_font{$font_index + 1} ? 'Courier' : $font,
		Gravity		=> 'North',
		pointsize	=> $font_size,
		text		=> "@{[$font_index + 1]}: $font" . ($symbolic_font{$font_index + 1} ? ' (symbolic)' : ''),
		x			=> $x,
		y			=> $y,
	);
}

# Output to my web server's doc root, which is in Debian's RAM disk.

my($out_file_name)	= "$ENV{DR}/misc/Debian.font.list.png";
my($count)			= $image -> Write($out_file_name);

say "Wrote $out_file_name";
