use strict;
use warnings;
use Test::More;


use Test::Version qw( version_ok ), {
    has_version => 1,
};

version_ok( 'lib/Win32/Console/PatchForRT33513.pm' );

done_testing;
