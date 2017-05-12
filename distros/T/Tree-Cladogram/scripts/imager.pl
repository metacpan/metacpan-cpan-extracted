#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Pod::Usage;

use Tree::Cladogram::Imager;

# ----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'branch_color=s',
	'branch_width=i',
	'debug=i',
	'draw_frame=i',
	'final_x_step=i',
	'frame_color=s',
	'help',
	'input_file=s',
	'leaf_font_color=s',
	'leaf_font_file=s',
	'leaf_font_size=i',
	'left_margin=i',
	'output_file=s',
	'print_tree=i',
	'title=s',
	'title_font_color=s',
	'title_font_file=s',
	'title_font_size=i',
	'top_margin=i',
	'x_step=i',
	'y_step=i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Tree::Cladogram::Imager -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

imager.pl - Read input text file and write cladogram image file using Imager

=head1 DESCRIPTION

imager.pl plots a cladogram.

=head1 SYNOPSIS

imager.pl [options]

	Options:
	-branch_color  $string
	-branch_width  $integer
	-debug  $Boolean
	-draw_frame  $Boolean
	-final_x_step  $integer
	-frame_color  $string
	-help
	-input_file  $string
	-leaf_font_color  $string
	-leaf_font_file  $string
	-leaf_font_size  $integer
	-left_margin  $integer
	-output_file  $string
	-print_tree  $Boolean
	-title  $string
	-title_font_color  $string
	-title_font_file  $string
	-title_font_size  $integer
	-top_margin  $integer
	-x_step  $iteger
	-y_step  $iteger

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -branch_color $string

Specify the color of the branches in the tree.

Default: '#7e7e7e' (gray).

Specify the thickness of the branches.

Default: 3 (px).

=item o -branch_width $integer

Specify the thickness of the branches.

Default: 3 (px).

=item o -debug $Boolean

Reserved for the use of the author ;-).

=item o -draw_frame $Boolean

If set, include the frame in the output image.

Default: 0 (no frame).

=item o -final_x_step $integer

Specify the length of the final branch leading to the names of the leaves.

Default: 30 (px).

=item o -frame_color $string

Specify the color of the frame, if any.

Use a word - 'blue' or a HTML color specification - '#ff0000'.

Default: '#0000ff'.

See also C<draw_frame>.

=item o -help

Print help and exit.

=item o -input_file $in_file

The path of the input text file to read.

This option is mandatory.

For sample input files, see data/*.clad.

Default: ''.

=item o -leaf_font_color $string

The color of the font used for leaf names.

Default: '#0000ff' (blue).

=item o -leaf_font_file $path2font

The path to a font file to be used for leaf names.

Default: /usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf.

This file ships as data/VeraBd.ttf.

=item o -leaf_font_size $integer

The pointsize of the font used for leaf names.

Default: 16 (points).

=item o -left_margin $integer

Specify the distance from the left of the image to the left-most point at which something is drawn.

Default: 15 (px).

=item o -output_file $out_file

The path of the output image file to wite.

This option is mandatory.

For sample output files, see data/*.png.

Default: ''.

=item o -print_tree $Boolean

If set print the tree constructed by reading the input file.

Default: 0 (no output).

=item o -title $string

Add a title at the bottom of the image.

See scripts/plot.sh for how to protect strings-with-spaces from the shell.

Default: '' (no title).

=item o -title_font_color $string

The color of the font used for the title.

Default: '#000000' (black).

=item o -title_font_file $path2font

The path to a font file to be used for the title.

Default: /usr/share/fonts/truetype/freefont/FreeSansBold.ttf.

This file ships as data/FreeSansBold.ttf.

=item o -title_font_size $integer

The pointsize of the font used for the title.

Default: 16 (points).

=item o -top_margin $integer

Specify the distance from the top of the image to the top-most point at which something is drawn.

Default: 15 (px).

=item o -x_step $integer

The horizontal length of branches.

See also C<final_x_step> and C<y_step>.

Default: 50 (px).

=item o -y_step $integer

The vertical length of the branches.

Note: Some vertical branches will be shortened if the code detects overlapping when leaf names are
drawn.

See also C<x_step>.

Default: 36 (px).

=back

=cut
