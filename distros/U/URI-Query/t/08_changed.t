# Test URI::Query has_changed()

use strict;
use vars q($count);

BEGIN { $count = 11 }
use Test::More tests => $count;

use_ok('URI::Query');

my $qq;

ok($qq = URI::Query->new('foo=1&foo=2&bar=3;bog=;bar=7;fluffy=3'), "constructor ok");
ok(! $qq->has_changed, 'has_changed is false after constructor');

# strip
$qq->strip(qw(bogus));
ok(! $qq->has_changed, 'has_changed is false after strip on missing variable');
$qq->strip(qw(foo fluffy));
ok($qq->has_changed > 0, 'has_changed is true after strip');

# revert
$qq->revert;
ok(! $qq->has_changed, 'has_changed is false after revert');

# strip except
$qq->strip_except(qw(foo bar bog bar fluffy));
ok(! $qq->has_changed, 'has_changed is false after strip_except on all variables');
$qq->strip_except(qw(foo));
ok($qq->has_changed > 0, 'has_changed is true after strip_except');

# revert
$qq->revert;
ok(! $qq->has_changed, 'has_changed is false after revert');

# strip_null
$qq->strip_null;
ok($qq->has_changed > 0, 'has_changed is true after strip_null');

# revert
$qq->revert;
ok(! $qq->has_changed, 'has_changed is false after revert');

