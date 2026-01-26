#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:types);

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test 1: registry_add - code generation
# ============================================
subtest 'registry_add - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->registry_add('register', '_registry');
    
    my $code = $b->code;
    like($code, qr/hv_fetch\s*\(\s*obj,\s*"_registry"/, 'fetches registry attribute');
    like($code, qr/hv_store\s*\(\s*obj,\s*"_registry"/, 'stores registry if missing');
    like($code, qr/hv_store\s*\(\s*registry,\s*kstr,\s*klen/, 'stores value in registry');
    like($code, qr/newHV.*newRV_noinc/s, 'creates new hash if needed');
};

# ============================================
# Test 2: registry_get - code generation
# ============================================
subtest 'registry_get - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->registry_get('get_item', '_items');
    
    my $code = $b->code;
    like($code, qr/hv_fetch\s*\(\s*obj,\s*"_items"/, 'fetches items attribute');
    like($code, qr/hv_fetch\s*\(\s*registry,\s*kstr,\s*klen/, 'fetches from registry');
    like($code, qr/XSRETURN_UNDEF/, 'returns undef for missing keys');
};

# ============================================
# Test 3: registry_remove - code generation
# ============================================
subtest 'registry_remove - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->registry_remove('delete_item', '_cache');
    
    my $code = $b->code;
    like($code, qr/hv_delete\s*\(\s*registry,\s*kstr,\s*klen/, 'uses hv_delete');
    like($code, qr/XSRETURN_UNDEF/, 'returns undef for missing keys');
};

# ============================================
# Test 4: registry_all - code generation
# ============================================
subtest 'registry_all - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->registry_all('all_items', '_data');
    
    my $code = $b->code;
    like($code, qr/GIMME_V\s*==\s*G_ARRAY/, 'checks context');
    like($code, qr/hv_iterinit/, 'iterates over hash');
    like($code, qr/hv_iternext/, 'uses hv_iternext');
    like($code, qr/hv_iterkeysv/, 'gets keys');
    like($code, qr/hv_iterval/, 'gets values');
};

# ============================================
# Test 5: registry integration - basic operations
# ============================================
subtest 'registry integration - basic operations' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('reg_add', '_reg');
    $b->registry_get('reg_get', '_reg');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryBasic',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryBasic::new'     => { source => 'new',     is_xs_native => 1 },
            'Test::RegistryBasic::reg_add' => { source => 'reg_add', is_xs_native => 1 },
            'Test::RegistryBasic::reg_get' => { source => 'reg_get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryBasic->new;
    ok($obj, 'created object');
    
    my $ret = $obj->reg_add(foo => 'bar');
    is($ret, $obj, 'registry_add returns self');
    
    is($obj->reg_get('foo'), 'bar', 'registry_get retrieves value');
    is($obj->reg_get('missing'), undef, 'registry_get returns undef for missing');
};

# ============================================
# Test 6: registry integration - chaining
# ============================================
subtest 'registry integration - chaining' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('set', '_config');
    $b->registry_get('get', '_config');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryChain',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryChain::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryChain::set' => { source => 'set', is_xs_native => 1 },
            'Test::RegistryChain::get' => { source => 'get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryChain->new;
    $obj->set(a => 1)->set(b => 2)->set(c => 3);
    
    is($obj->get('a'), 1, 'get a');
    is($obj->get('b'), 2, 'get b');
    is($obj->get('c'), 3, 'get c');
};

# ============================================
# Test 7: registry integration - remove
# ============================================
subtest 'registry integration - remove' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('add', '_items');
    $b->registry_get('get', '_items');
    $b->registry_remove('del', '_items');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryRemove',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryRemove::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryRemove::add' => { source => 'add', is_xs_native => 1 },
            'Test::RegistryRemove::get' => { source => 'get', is_xs_native => 1 },
            'Test::RegistryRemove::del' => { source => 'del', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryRemove->new;
    $obj->add(x => 10)->add(y => 20);
    
    my $removed = $obj->del('x');
    is($removed, 10, 'remove returns removed value');
    is($obj->get('x'), undef, 'removed item no longer exists');
    is($obj->get('y'), 20, 'other items unaffected');
    is($obj->del('nonexistent'), undef, 'remove returns undef for missing');
};

# ============================================
# Test 8: registry integration - all in list context
# ============================================
subtest 'registry integration - all list context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('set', '_map');
    $b->registry_all('all', '_map');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryAllList',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryAllList::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryAllList::set' => { source => 'set', is_xs_native => 1 },
            'Test::RegistryAllList::all' => { source => 'all', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryAllList->new;
    $obj->set(a => 1)->set(b => 2)->set(c => 3);
    
    my %all = $obj->all;
    is(scalar keys %all, 3, 'list context returns 3 pairs');
    is($all{a}, 1, 'key a has value 1');
    is($all{b}, 2, 'key b has value 2');
    is($all{c}, 3, 'key c has value 3');
};

# ============================================
# Test 9: registry integration - all in scalar context
# ============================================
subtest 'registry integration - all scalar context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('set', '_data');
    $b->registry_all('all', '_data');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryAllScalar',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryAllScalar::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryAllScalar::set' => { source => 'set', is_xs_native => 1 },
            'Test::RegistryAllScalar::all' => { source => 'all', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryAllScalar->new;
    $obj->set(x => 100)->set(y => 200);
    
    my $hashref = $obj->all;
    is(ref $hashref, 'HASH', 'scalar context returns hashref');
    is($hashref->{x}, 100, 'hashref has correct value for x');
    is($hashref->{y}, 200, 'hashref has correct value for y');
    
    # Verify it's a copy
    $hashref->{x} = 999;
    is($obj->{_data}{x}, 100, 'hashref is a shallow copy');
};

# ============================================
# Test 10: registry integration - empty registry
# ============================================
subtest 'registry integration - empty registry' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_get('get', '_empty');
    $b->registry_remove('del', '_empty');
    $b->registry_all('all', '_empty');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryEmpty',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryEmpty::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryEmpty::get' => { source => 'get', is_xs_native => 1 },
            'Test::RegistryEmpty::del' => { source => 'del', is_xs_native => 1 },
            'Test::RegistryEmpty::all' => { source => 'all', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryEmpty->new;
    is($obj->get('anything'), undef, 'get returns undef for empty registry');
    is($obj->del('anything'), undef, 'remove returns undef for empty registry');
    
    my @list = $obj->all;
    is(scalar @list, 0, 'all returns empty list in list context');
    
    my $hashref = $obj->all;
    is_deeply($hashref, {}, 'all returns empty hashref in scalar context');
};

# ============================================
# Test 11: registry with code refs
# ============================================
subtest 'registry - stores code refs' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('on', '_handlers');
    $b->registry_get('handler', '_handlers');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryCodeRef',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryCodeRef::new'     => { source => 'new',     is_xs_native => 1 },
            'Test::RegistryCodeRef::on'      => { source => 'on',      is_xs_native => 1 },
            'Test::RegistryCodeRef::handler' => { source => 'handler', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryCodeRef->new;
    my $handler = sub { return 'clicked!' };
    $obj->on(click => $handler);
    
    my $retrieved = $obj->handler('click');
    is(ref $retrieved, 'CODE', 'retrieved a coderef');
    is($retrieved->(), 'clicked!', 'coderef works correctly');
};

# ============================================
# Test 12: multiple registries
# ============================================
subtest 'registry - multiple registries' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('add_user', '_users');
    $b->registry_add('add_role', '_roles');
    $b->registry_get('get_user', '_users');
    $b->registry_get('get_role', '_roles');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryMultiple',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryMultiple::new'      => { source => 'new',      is_xs_native => 1 },
            'Test::RegistryMultiple::add_user' => { source => 'add_user', is_xs_native => 1 },
            'Test::RegistryMultiple::add_role' => { source => 'add_role', is_xs_native => 1 },
            'Test::RegistryMultiple::get_user' => { source => 'get_user', is_xs_native => 1 },
            'Test::RegistryMultiple::get_role' => { source => 'get_role', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryMultiple->new;
    $obj->add_user(alice => { id => 1, name => 'Alice' });
    $obj->add_role(admin => ['read', 'write', 'delete']);
    
    is_deeply($obj->get_user('alice'), { id => 1, name => 'Alice' }, 'user registry works');
    is_deeply($obj->get_role('admin'), ['read', 'write', 'delete'], 'role registry works');
    is($obj->get_user('admin'), undef, 'registries are separate');
    is($obj->get_role('alice'), undef, 'registries are separate');
};

# ============================================
# Test 13: registry overwrites existing keys
# ============================================
subtest 'registry - overwrites existing keys' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('set', '_kv');
    $b->registry_get('get', '_kv');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryOverwrite',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryOverwrite::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryOverwrite::set' => { source => 'set', is_xs_native => 1 },
            'Test::RegistryOverwrite::get' => { source => 'get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryOverwrite->new;
    $obj->set(key => 'first');
    is($obj->get('key'), 'first', 'initial value');
    
    $obj->set(key => 'second');
    is($obj->get('key'), 'second', 'value overwritten');
};

# ============================================
# Test 14: registry with existing hash attribute
# ============================================
subtest 'registry - uses existing hash attribute' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('add', '_existing');
    $b->registry_get('get', '_existing');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryExisting',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryExisting::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryExisting::add' => { source => 'add', is_xs_native => 1 },
            'Test::RegistryExisting::get' => { source => 'get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryExisting->new(_existing => { pre => 'existing' });
    is($obj->get('pre'), 'existing', 'can read pre-existing value');
    
    $obj->add(new => 'added');
    is($obj->get('new'), 'added', 'can add to pre-existing hash');
};

# ============================================
# Test 15: registry with complex keys
# ============================================
subtest 'registry - complex keys' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('set', '_data');
    $b->registry_get('get', '_data');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryComplexKeys',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryComplexKeys::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryComplexKeys::set' => { source => 'set', is_xs_native => 1 },
            'Test::RegistryComplexKeys::get' => { source => 'get', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryComplexKeys->new;
    $obj->set('key with spaces' => 1);
    $obj->set('key:with:colons' => 2);
    $obj->set('key/with/slashes' => 3);
    
    is($obj->get('key with spaces'), 1, 'key with spaces works');
    is($obj->get('key:with:colons'), 2, 'key with colons works');
    is($obj->get('key/with/slashes'), 3, 'key with slashes works');
};

# ============================================
# Test 16: registry all returns correct count
# ============================================
subtest 'registry_all - correct pair count' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    $b->registry_add('add', '_items');
    $b->registry_all('all', '_items');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::RegistryAllCount',
        cache_dir => $cache_dir,
        functions => {
            'Test::RegistryAllCount::new' => { source => 'new', is_xs_native => 1 },
            'Test::RegistryAllCount::add' => { source => 'add', is_xs_native => 1 },
            'Test::RegistryAllCount::all' => { source => 'all', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = Test::RegistryAllCount->new;
    $obj->add("key$_" => $_) for 1..5;
    
    my @pairs = $obj->all;
    is(scalar @pairs, 10, 'list context returns 10 elements (5 pairs)');
    
    my $hash = $obj->all;
    is(scalar keys %$hash, 5, 'scalar context hashref has 5 keys');
};

done_testing();
