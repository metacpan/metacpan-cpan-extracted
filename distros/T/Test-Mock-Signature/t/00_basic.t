use strict;
use warnings;

use Test::More;

my $pkg = 'Test::Mock::Signature';

require_ok($pkg);

my $obj = new_ok($pkg, [ 'Test::Mock::Signature' ]);

can_ok($obj, qw| method clear dispatcher |);

done_testing;
