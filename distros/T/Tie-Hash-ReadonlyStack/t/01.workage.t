use Test::More tests => 52;

BEGIN {
   use_ok( 'Tie::Hash::ReadonlyStack' );
}

diag( "Testing Tie::Hash::ReadonlyStack $Tie::Hash::ReadonlyStack::VERSION" );

my %mydata = (
    'a' => 1,
    'b' => 2,
);

my %before = ('a' => 2);
my %after = ('c' => 3);

my $tie_obj = tie my %hash, 'Tie::Hash::ReadonlyStack', \%mydata;

ok(!exists $hash{"new"}, "new key does not exist");
ok($hash{"new"} = 1, "new value for new key works");
ok(exists $hash{"new"}, "new key does exist");
is_deeply([$tie_obj->get_keys_not_in_stack()], ['new'], 'get_keys_not_in_stack() returns only what it should');
is_deeply([sort keys %hash], [qw(new)], "keys() returns only cached keys");
 
ok($hash{"new"} == 1, "new value stuck");
ok(delete $hash{"new"} == 1, 'delete returns the value');
ok(!exists $hash{"new"}, "delete() restores new key to non existant state");
ok($hash{'a'} == 1, 'sanity: key "a" has "main" value');

ok($hash{"a"} = 2, 'new value for "a" works');
ok($hash{"a"} == 2, 'new value for "a" stuck');
ok(delete $hash{"a"} == 2, 'delete returns the cached value');
ok($hash{'a'} == 1, 'delete() restores key "a" to "main" value');

ok($hash{'a'} == 1, 'sanity: key "a" has "main" value');
ok($hash{'b'} == 2, 'sanity: key "b" has "main" value');

is_deeply([sort keys %hash], [qw(a b)], "keys() returns only cached keys 2");
is_deeply([$tie_obj->get_keys_not_in_stack()], [], 'get_keys_not_in_stack() returns only what it should 2');

ok(!exists $hash{'c'}, 'sanity: key "c" does not exist');

ok($tie_obj->add_lookup_override_hash_without_clearing_cache('before', \%before), 'add_lookup_override_hash_without_clearing_cache() returns true');
ok($hash{'a'} == 1, 'key "a" has "main" value');
ok($hash{'b'} == 2, 'sanity: key "b" still has "main" value');

ok(!$tie_obj->add_lookup_override_hash_without_clearing_cache('before', {'a'=>3}), "add_lookup_override_hash_without_clearing_cache() adding existing hash returns false");
ok($hash{'a'} == 1, 'key "a" still has "main" value');

ok(!$tie_obj->add_lookup_override_hash('readonly_hash', {}), 'returns false for main hash override');

ok($tie_obj->add_lookup_fallback_hash('after', \%after), 'add_lookup_override_hash() returns true');
ok($hash{'c'} == 3, 'key "c" has "fallback" value');
ok($hash{'b'} == 2, 'sanity: key "b" still has "main" value');

ok(!$tie_obj->add_lookup_fallback_hash('after', {'c'=>4}), "adding existing hash returns false");
ok($hash{'c'} == 3, 'key "c" still has "fallback" value');

ok(!$tie_obj->add_lookup_fallback_hash('readonly_hash', {}), 'returns false for main hash fallback');
ok($hash{'b'} == 2, 'sanity: key "b" still has "main" value');

ok($tie_obj->del_lookup_hash('before'), 'returns true override');
ok($tie_obj->del_lookup_hash('after'), 'returns true fallback');
ok($tie_obj->del_lookup_hash('nonexist'), 'returns true non existant (should clean up any dangling bits)');
ok(!$tie_obj->del_lookup_hash('nonexist',1), 'returns false non existant w/ second true arg');

ok($hash{'b'} == 2, 'sanity: key "b" still has "main" value');

ok(!$tie_obj->del_lookup_hash('readonly_hash'), 'returns false for main hash delete');
ok($hash{'a'} == 1, 'key "a" has "main" value again');
ok($hash{'b'} == 2, 'sanity: key "b" still has "main" value');
ok(!exists $hash{'c'}, 'key "c" does not exist again');

ok($tie_obj->add_lookup_override_hash('before', \%before), 'add_lookup_override_hash() returns true');
ok($hash{'a'} == 2, 'key "a" has new override value');
ok(!$tie_obj->add_lookup_override_hash('before', {'a'=>3}), "adding existing hash returns false");
ok($hash{'a'} == 2, 'key "a" still has new override value');

is_deeply(\%mydata, {'a' => 1, 'b' => 2}, 'main hash unmodified');
is_deeply(\%before, {'a' => 2}, 'override hash unmodified');
is_deeply(\%after, {'c' => 3}, 'fallback hash unmodified');

$hash{'newkey'} = 1;
$hash{'newkey2'} = 2;
ok($tie_obj->clear_compiled_cache(qw(newkey newkey2 noexisty)) == 2, 'clear_compiled_cache() w/ key list including non existant returns count of actually deleted');
ok(!$tie_obj->clear_compiled_cache(qw(noexisty noexisty)), 'clear_compiled_cache() w/ key list including only non existants returns false');
ok($tie_obj->clear_compiled_cache() == 1, 'clear_compiled_cache() w/ no key returns true (1)');
ok(keys %{$tie_obj->{'compiled'}} == 0, 'clear_compiled_cache() w/ no key empties compiled cache hash');