#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Proto::Compare;
use Test::Proto::Compare::Numeric;
use Test::Proto::Base;
sub c {Test::Proto::Compare->new}
sub cNum {Test::Proto::Compare::Numeric->new}

is('a' cmp 'b', -1, 'Baseline: a cmp b is -1');

is(c->compare('a','b'), -1);
is(c->compare('a','a'),  0);
is(c->compare('b','a'),  1);

is(c->reverse->compare('a','b'),  1);
is(c->reverse->compare('a','a'),  0);
is(c->reverse->compare('b','a'), -1);

is(c->code(sub { lc shift cmp lc shift })->compare('a','A'),  0, 'Can override the default code');

is(c->summary, 'cmp');
is(c->summary('string cmp')->summary, 'string cmp', 'Can override the default summary');



is(cNum->compare(5,20), -1);
is(cNum->compare(5,5),  0);
is(cNum->compare(20,5),  1);

ok(cNum->lt(5,20));
ok(cNum->le(5,20));
ok(!cNum->lt(20,5));
ok(!cNum->le(20,5));
ok(!cNum->lt(5,5));
ok(cNum->le(5,5));

ok(cNum->gt(20,5),);
ok(cNum->ge(20,5),);
ok(!cNum->gt(5,20),);
ok(!cNum->ge(5,20),);
ok(!cNum->gt(5,5));
ok(cNum->ge(5,5));


is(cNum->reverse->compare(5,20),  1);
is(cNum->reverse->compare(5,5),  0);
is(cNum->reverse->compare(20,5), -1);

is(cNum->summary, '<=>');
is(cNum->summary('numeric cmp')->summary, 'numeric cmp', 'Can override the default summary');


done_testing();
