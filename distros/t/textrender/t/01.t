use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);

#use Smart::Comments '###';
$cwd = cwd();

use LEOCHARRE::FontFind 'find_ttf','find_ttfs';

LEOCHARRE::FontFind::_cache_reset();


my @ttfs = LEOCHARRE::FontFind::_abs_ttfs();

my $fontcount = scalar @ttfs;
ok( $fontcount, "got count of fonts: $fontcount"); 
warn("fontcount : $fontcount");

# was using 'vera' to find a font but that's not available everywhere
# so let's use a more common font name segment

my $font_name_substring='arial';

my @fonts = find_ttfs($font_name_substring);
ok( @fonts, "find_ttfs= $font_name_substring");

my $font = find_ttf($font_name_substring);
ok( $font, 'find_ttf');

#warn "got : $font\n";















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



