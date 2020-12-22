use strict;
use warnings;

use Test::More 'tests' => 5;
use Test::NoWarnings;
use Toolforge::MixNMatch::Struct::User;

# Test.
my $struct_hr = {
	'cnt' => 10,
	'uid' => 1,
	'username' => 'skim',
};
my $obj = Toolforge::MixNMatch::Struct::User::struct2obj($struct_hr);
isa_ok($obj, 'Toolforge::MixNMatch::Object::User');
is($obj->count, 10, 'Get count.');
is($obj->uid, 1, 'Get uid.');
is($obj->username, 'skim', 'Get username.');
