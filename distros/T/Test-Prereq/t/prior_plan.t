# declare a plan beforehand to ensure that loading Test::Prereq
# still works even through a test module might call plan() itself.
use Test::More tests => 1;

use Test::Prereq;

prereq_ok( undef, undef, [] );
