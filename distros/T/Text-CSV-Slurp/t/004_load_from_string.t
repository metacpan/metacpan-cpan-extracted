#!perl

use strict;
use warnings;

use lib 'lib';

use Test::Most tests => 1;
use Text::CSV::Slurp;

my $INPUT_CSV
    = "name,age\r\n"
    ."Johny,45\r\n"
    ."Jeremy,19\r\n";

is_deeply(
    Text::CSV::Slurp->load(string => $INPUT_CSV),
    [
        { name => 'Johny', age => 45 },
        { name => 'Jeremy', age => 19 },
    ],
    "CSV string is parsed correctly"
);
