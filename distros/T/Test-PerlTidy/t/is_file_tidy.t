#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use File::Spec     ();
use Test::PerlTidy ();

my $perltidyrc = File::Spec->catfile( 't', '_perltidyrc.txt' );

{
    local ${Test::PerlTidy::MUTE} = 1;
    ok Test::PerlTidy::is_file_tidy( 't/tidy_file.txt', $perltidyrc ),
      't/tidy_file.txt';
    ok !Test::PerlTidy::is_file_tidy( 't/messy_file.txt', $perltidyrc ),
      't/messy_file.txt';
}
