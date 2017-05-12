#!perl -T
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Proto::HashRef;
use Test::Proto::ArrayRef;

ok (1, 'ok is ok');

sub is_a_good_pass {
	# Todo: test this more
	ok($_[0]?1:0, , $_[1]) or diag Dumper $_[0];
}

sub is_a_good_fail {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]) or diag Dumper $_[0];
	ok(!$_[0]->is_exception, '... and not be an exception') or diag Dumper $_[0];
}

sub is_a_good_exception {
	# Todo: test this more
	ok($_[0]?0:1, $_[1]);
	ok($_[0]->is_exception, '... and be an exception');
}


sub pHr { Test::Proto::HashRef->new(); }

# key_has_value
is_a_good_pass(pHr->key_has_value('a','b')->validate({'a'=>'b'}), "key_has_value should pass when expected matches");
is_a_good_fail(pHr->key_has_value('a','b')->validate({'a'=>'c'}), "key_has_value should fail when expected does not match");
is_a_good_fail(pHr->key_has_value('a','b')->validate({}), "key_has_value should fail when the key does not exist");

# key_exists
is_a_good_pass(pHr->key_exists('a')->validate({'a'=>'b'}), "key_exists should pass when the key does exist");
is_a_good_pass(pHr->key_exists('a')->validate({'a'=>undef}), "key_exists should pass when the key does exist, even if value is undef");
is_a_good_fail(pHr->key_exists('a')->validate({}), "key_exists should fail when the key does not exist");

# count_keys
is_a_good_pass(pHr->count_keys(1)->validate({'a'=>'b'}), "count_keys should pass when the number matches");
is_a_good_pass(pHr->count_keys(0)->validate({}), "count_keys should pass when the number is 0 and the hash is empty");
is_a_good_fail(pHr->count_keys(5)->validate({'a'=>'b'}), "count_keys should fail when the number does not match");

# keys
is_a_good_pass(pHr->keys(['a'])->validate({'a'=>'b'}), "keys should pass when there is one key");
is_a_good_pass(pHr->keys([])->validate({}), "keys should pass with [] when the hash is empty");
is_a_good_pass(pHr->keys(Test::Proto::ArrayRef->new->bag_of(['a','c']))->validate({a=>'b',c=>'d'}), "keys should pass there is more than one key, using bag_of");
is_a_good_fail(pHr->keys(['b'])->validate({'a'=>'b'}), "keys should fail when appropriate");

# values
is_a_good_pass(pHr->values(['b'])->validate({'a'=>'b'}), "values should pass when there is one value");
is_a_good_pass(pHr->values([])->validate({}), "values should pass with [] when the hash is empty");
is_a_good_pass(pHr->values(Test::Proto::ArrayRef->new->bag_of(['b','d']))->validate({a=>'b',c=>'d'}), "values should pass there is more than one value, using bag_of");
is_a_good_fail(pHr->values(['a'])->validate({'a'=>'b'}), "values should fail when appropriate");

# enumerated
is_a_good_pass(pHr->enumerated([[a=>'b']])->validate({'a'=>'b'}), "enumerated should pass when there is one value");
is_a_good_pass(pHr->enumerated([])->validate({}), "enumerated should pass with [] when the hash is empty");
is_a_good_pass(pHr->enumerated(Test::Proto::ArrayRef->new->bag_of([[a=>'b'],[c=>'d']]))->validate({a=>'b',c=>'d'}), "enumerated should pass there is more than one value, using bag_of");
is_a_good_fail(pHr->enumerated([['a'=>'c']])->validate({'a'=>'b'}), "enumerated should fail when appropriate");


# superhash_of
is_a_good_pass(pHr->superhash_of({'a'=>'b'})->validate({'a'=>'b'}), "superhash_of should pass when expected matches");
is_a_good_pass(pHr->superhash_of({})->validate({'a'=>'b'}), "superhash_of should pass when expected is empty");
is_a_good_pass(pHr->superhash_of({'a'=>qr/a|b/})->validate({'a'=>'b'}), "superhash_of should pass when expected matches but needs upgrading");
is_a_good_fail(pHr->superhash_of({'a'=>'b'})->validate({'a'=>'c'}), "superhash_of should fail when expected does not match");
is_a_good_fail(pHr->superhash_of({'a'=>'b'})->validate({}), "superhash_of should fail when the key does not exist");


done_testing;

