
use strict;

use Test::More 'no_plan';

use Test::FormValidator;

my $tfv = Test::FormValidator->new;

# test results - we shouldn't be able to call it without calling check first

eval {
   $tfv->results;
};
like($@, qr/need.*before/, "prevented from calling results before a check");


# test check() - we shouldn't be able to call it without a profile

eval {
    $tfv->check('foo' => 'bar');
};
ok($@, "prevented from calling check without a profile (input as hash)");
eval {
    $tfv->check({'foo' => 'bar'});
};
ok($@, "prevented from calling check without a profile (input as hashref)");


# test profile() - we should be able to switch profiles
$tfv->profile({ required => ['foo'] });
ok($tfv->check('foo' => 1), "start with profile 1");

$tfv->profile({ required => ['bar'] });
ok(!$tfv->check('foo' => 1),  "switch to profile 2");
ok($tfv->check('bar' => 1),   "switch to profile 2 (correct input as hash)");
ok($tfv->check({'bar' => 1}), "switch to profile 2 (correct input as hashref)");

# test check() with profile() - it should not permanently set the profile
$tfv->profile({ required => ['foo'] });
ok(!$tfv->check({ 'foo' => 1 }, { required => ['bubba'] }), 'temporary new profile via check');
ok($tfv->check({ 'foo' => 1 }), 'after check, old profile is restored');


# test new() - can we do the same stuff here as we can do with DFV?
# here we test with and without the 'trim' filter

my %input = (
   'foo' => ' test ',
);
my %profile = (
   'required' => ['foo'],
);

my $tfv_normal = Test::FormValidator->new;

my $results = $tfv_normal->check(\%input, \%profile);
is($results->valid->{'foo'}, $input{'foo'}, "tfv_normal (value is unchanged)");

my $tfv_trim = Test::FormValidator->new({}, {
    'filters' => 'trim',
});

$results = $tfv_trim->check(\%input, \%profile);
isa_ok($results, 'Data::FormValidator::Results', 'Results object returned from check');
is($results->valid->{'foo'}, 'test', "tfv_trim (value has whitespace removed)");


# test results
isa_ok($tfv_trim->results, 'Data::FormValidator::Results', 'tfv->results object is valid after check');

is($tfv_trim->results->valid->{'foo'}, 'test', "tfv_trim (value has whitespace removed)");



# Test prefix

ok(!$tfv->prefix, "no prefix set");
is($tfv->_format_description('desc'), "desc", "prefix not added to description");

$tfv->prefix('something');

is($tfv->prefix('something'), 'something', "prefix set to something");
is($tfv->_format_description('desc'), "somethingdesc", "prefix added to description");

$tfv->prefix(undef);

ok(!$tfv->prefix, "prefix unset");
is($tfv->_format_description('desc'), "desc", "prefix no longer added to description");


$tfv->prefix(0);

ok(defined $tfv->prefix, "prefix set to zero");
is($tfv->_format_description('desc'), "0desc", "false but substantial prefix (zero) added to description");


