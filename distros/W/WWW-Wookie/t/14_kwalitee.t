use strict;
use warnings;
use utf8;

use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Set $ENV{AUTHOR_TESTING} to run author tests.';
    plan( skip_all => $msg );
}

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -has_meta_yml)] );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
