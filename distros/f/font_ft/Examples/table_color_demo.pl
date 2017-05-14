#!/usr/bin/perl -w

=head2 table_color_demo.pl

=item Written: 20020522

=back

=item Creator: Andrew Robertson

=back

=item License: GPL 2

=back

table_color_demo.pl is a simple demo of table character rendering with color.

=cut

use FONT::FT2 ':all';

my $retval = init("/usr/share/fonts/ttf/gkai00mp.ttf"); #italic

$retval = render_table (40, 56, 2, 2, [65, 66, 0x4eba, 0x4ebb], ['0xff0000', '0x00ff00', '0x0000ff', undef], 0x20000, 0x20000);

open(OUTPUT, '> temp.xpm');
print OUTPUT bitmap_as_xpm($retval);
close(OUTPUT);

