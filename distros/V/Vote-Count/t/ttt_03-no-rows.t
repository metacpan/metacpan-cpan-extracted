#! perl
#
use strict;
use warnings;

use Test::More        tests => 1;
use Vote::Count::TextTableTiny qw/ generate_table /;
use Test::Fatal       qw/ exception /;

like( exception { generate_table() },
    qr/you must pass the 'rows' argument/,
    "croak if the rows argument isn't passed"
);

