use lib qw( ../lib ); # -*- cperl -*- 

use strict;
use warnings;

use Test::Text;
use Test::More; #for diag

my $dict_dir;

if ( -e "/usr/share/hunspell/en_US.aff" ) {
  $dict_dir =  "/usr/share/hunspell";
} elsif  ( -e "data/en_US.aff" ) {
  $dict_dir = "data";
} else {
  $dict_dir = "../data";
}

diag "Using $dict_dir for dictionnaries";

my $text_dir = 'text/en';
if ( !-e $text_dir ) {
  $text_dir =  "../text/en";
}

diag "Using $text_dir for text";

just_check( $text_dir, $dict_dir); # procedural interface, exported by default


