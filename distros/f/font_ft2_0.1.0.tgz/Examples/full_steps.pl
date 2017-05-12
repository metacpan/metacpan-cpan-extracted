#!/usr/bin/perl

=head2 full_steps.pl

=item Written: 20020522

=back

=item Creator: Andrew Robertson

=back

=item License: GPL 2

=back


Description:

  full_steps.pl is a demo using the lower level FT2 subroutines to render a glyph.

=cut

use FONT::FT2 ':all';

my $retval, $width, $height, $glyph_index;

#$retval = FONT::FT2::init("/usr/share/fonts/ttf/gkai00mp.ttf"); #italic
#$retval = FT2::init("/usr/share/fonts/ttf/bsmi00lp.ttf"); #print
#$retval = FT2::init("/usr/share/fonts/ttf/gbsn00lp.ttf"); #print
#$retval = FT2::init("/usr/share/fonts/ttf/bkai00mp.ttf"); #italic
$retval = FONT::FT2::init("/usr/share/fonts/ja/TrueType/kochi-mincho.ttf"); #japanese italic
#$retval = init("/usr/share/fonts/default/TrueType/timi____.ttf"); #italic

$glyph_index = FONT::FT2::get_glyph_index(65);			# character A
$retval = FONT::FT2::set_transform(0, 0x10000, 0x10000);	# No rotation
$retval = FONT::FT2::render($glyph_index);			# render
$width = FONT::FT2::width($glyph_index);
$height = FONT::FT2::height($glyph_index);
print "Width in perl: $width\n";
print "Height in perl: $height\n";

my $rh_bitmap = get_bitmap($glyph_index);
if (!defined($$rh_bitmap{bitmap}->[0])) {
	print "FAILURE!\n";
} else {
	print "SUCCESS!\n";
}


