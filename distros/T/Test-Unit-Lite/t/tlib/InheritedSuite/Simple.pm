package InheritedSuite::Simple;

use strict;
use warnings;

use base qw(Test::Unit::TestSuite);

sub include_tests { 'SuccessTest'            }
sub name          { 'Simple inherited suite' }

1;
