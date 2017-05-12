use strict;
use warnings;

use Test::More tests => 3;

# Load the module.
use_ok 'Test::Fixme';

# Check the formating of results.
my $results = Test::Fixme::scan_file(
    file  => 't/dirs/normal/two.pl',
    match => 'TEST'
);
ok $results, "got results to work with";

my $expected = << 'STOP';
File: 't/dirs/normal/two.pl'
    8       # TEST - test 1 (line 8).
    10      # TEST - test 2 (line 10).
STOP

is Test::Fixme::format_file_results_original($results), $expected, "check formatting";
