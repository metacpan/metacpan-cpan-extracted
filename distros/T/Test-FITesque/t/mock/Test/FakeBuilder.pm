package Test::FakeBuilder;

use strict;
use warnings;

sub new { return bless {}, $_[0]; }
sub exported_to {}
sub no_plan {}
sub expected_tests {}
sub diag {}

1;
