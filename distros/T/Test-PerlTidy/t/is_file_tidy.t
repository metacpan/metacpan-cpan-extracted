#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use File::Spec     ();
use Test::PerlTidy ();

my $perltidyrc = File::Spec->catfile( 't', '_perltidyrc.txt' );

{
    local ${Test::PerlTidy::MUTE} = 1;

    # TEST
    ok Test::PerlTidy::is_file_tidy( 't/tidy_file.txt', $perltidyrc ),
      't/tidy_file.txt';

    # TEST
    ok !Test::PerlTidy::is_file_tidy( 't/messy_file.txt', $perltidyrc ),
      't/messy_file.txt';

    # TEST
    ok Test::PerlTidy::is_file_tidy( 't/tidy_file.txt', "NOTEXIST",
        { perltidy_options => { perltidyrc => $perltidyrc, }, },
      ),
      'pass perltidy_options perltidyrc named param';
}
