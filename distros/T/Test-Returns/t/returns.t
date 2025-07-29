use strict;
use warnings;

use Test::Most;
use Test::Returns;

returns_is(5, { type => 'integer' }, 'Integer ok');
returns_ok([], { type => 'arrayref' }, 'Arrayref ok');
returns_ok({ foo => 1 }, { type => 'hashref' }, 'Hashref ok');
returns_isnt("nope", { type => 'hashref' }, 'Fails: not a hashref');

returns_ok(42, { type => 'integer' }, 'Integer is valid');
returns_not_ok("forty", { type => 'integer' }, 'String is not integer');

returns_is([1,2], { type => 'arrayref' }, 'Arrayref matches');
returns_isnt("nope", { type => 'hashref' }, 'String is not hashref');

returns_isnt('abc', { type => 'integer' }, 'String should not match integer');

done_testing();
