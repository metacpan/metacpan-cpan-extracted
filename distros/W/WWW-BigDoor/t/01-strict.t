use strict;
use warnings;

use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Strict";
plan skip_all => "Test::Strict is missing" if $@;
all_perl_files_ok('lib'); # Syntax ok and use strict;
