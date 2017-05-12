use lib qw( ../lib ); # -*- cperl -*- 

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Text;

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

my $tesxt = Test::Text->new($text_dir, $dict_dir);
isa_ok( $tesxt, "Test::Text");

$tesxt->check();

diag "Done English tests";

if  ( -e "data/Spanish.aff" ) {
  $dict_dir = "data";
} else {
  $dict_dir = "../data";
}

$text_dir = 'text/es';
if ( !-e $text_dir ) {
  $text_dir =  "../text/es";
}

$tesxt = Test::Text->new($text_dir, $dict_dir, 'Spanish');
isa_ok( $tesxt, "Test::Text");
$tesxt->check();

diag "Done Spanish tests";

done_testing();

