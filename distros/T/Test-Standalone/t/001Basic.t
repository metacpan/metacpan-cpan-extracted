######################################################################
# Test suite for Test::Standalone
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Test::Standalone') };

=begin test
foo bar
=end test
=cut

is(Test::Standalone::test_code, "foo bar\n", "Extract Test Code");
