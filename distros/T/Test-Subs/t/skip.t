use strict;
use warnings;
use Test::Subs debug => 1, pod_warn => 2;
use t::data::Test::Subs::A;

skip 'Does not have foo' unless 0;

our $t = 1;
END { $t = 2 }

test { 1 == 1 } 'first test';
test { 42 } 'tested and got %s';

test { $t::data::Test::Subs::A::v == 1 };
test { $t == 1 };

todo { print "some comment\n"; 1 == 2 } 'not yet implemented...';

comment { 'some other comment' };

not_ok { 0 };

match { 'test' } '.{4}';

debug { 1 };

fail { die "fail" } 'throwing "%s"';

failwith { test {1} } 'cannot call';

test_pod('Test::Subs');

__DATA__

nothing here...

