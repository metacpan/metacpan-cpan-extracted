#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder;

my $cache_dir = tempdir(CLEANUP => 1);

# Test counter for unique package names
my $test_num = 0;

subtest 'basic memoization' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('compute');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('compute', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile basic memoize');

    no strict 'refs';

    # Define the original method
    my $call_count = 0;
    *{"${pkg}::_orig_compute"} = sub {
        my ($self, $x, $y) = @_;
        $call_count++;
        return $x * $y;
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    # First call - should call original
    is($obj->compute(6, 7), 42, 'first call returns correct result');
    is($call_count, 1, 'original called once');

    # Second call with same args - should be cached
    is($obj->compute(6, 7), 42, 'second call returns cached result');
    is($call_count, 1, 'original not called again (cached)');

    # Third call with different args - should call original
    is($obj->compute(3, 4), 12, 'different args returns correct result');
    is($call_count, 2, 'original called for new args');

    # Fourth call with first args again - still cached
    is($obj->compute(6, 7), 42, 'first args still cached');
    is($call_count, 2, 'still only 2 calls to original');
};

subtest 'cache clear' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('fetch');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('fetch', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile memoize with clear');

    no strict 'refs';

    my $call_count = 0;
    *{"${pkg}::_orig_fetch"} = sub {
        my ($self, $key) = @_;
        $call_count++;
        return "value_$key";
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    # Call and cache
    is($obj->fetch('a'), 'value_a', 'fetch a');
    is($obj->fetch('b'), 'value_b', 'fetch b');
    is($call_count, 2, 'two calls to original');

    # Cached
    is($obj->fetch('a'), 'value_a', 'fetch a cached');
    is($obj->fetch('b'), 'value_b', 'fetch b cached');
    is($call_count, 2, 'still two calls');

    # Clear cache
    my $result = $obj->clear_fetch_cache;
    is($result, $obj, 'clear_cache returns self');

    # After clear, should call original again
    is($obj->fetch('a'), 'value_a', 'fetch a after clear');
    is($call_count, 3, 'original called after cache clear');
};

subtest 'custom cache attribute' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('lookup', { cache => '_my_custom_cache' });

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('lookup', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile with custom cache attr');

    no strict 'refs';

    my $call_count = 0;
    *{"${pkg}::_orig_lookup"} = sub {
        my ($self, $id) = @_;
        $call_count++;
        return "item_$id";
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    is($obj->lookup(123), 'item_123', 'first lookup');
    is($call_count, 1, 'original called');

    is($obj->lookup(123), 'item_123', 'cached lookup');
    is($call_count, 1, 'still one call');

    # Verify cache is in custom attribute
    ok(exists $obj->{_my_custom_cache}, 'custom cache attribute exists');
    isa_ok($obj->{_my_custom_cache}, 'HASH', 'cache is a hashref');
};

subtest 'TTL expiration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('quick', { ttl => 1 });  # 1 second TTL

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('quick', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile with TTL');

    no strict 'refs';

    my $call_count = 0;
    my $value = 1;
    *{"${pkg}::_orig_quick"} = sub {
        my ($self) = @_;
        $call_count++;
        return $value++;
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    # First call
    is($obj->quick, 1, 'first quick call');
    is($call_count, 1, 'original called once');

    # Immediate second call - cached
    is($obj->quick, 1, 'cached result');
    is($call_count, 1, 'still one call');

    # Wait for TTL to expire
    sleep 2;

    # After TTL - should call original again
    is($obj->quick, 2, 'after TTL expiration');
    is($call_count, 2, 'original called again');
};

subtest 'multiple arguments' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('concat');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('concat', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile multi-arg memoize');

    no strict 'refs';

    my $call_count = 0;
    *{"${pkg}::_orig_concat"} = sub {
        my ($self, @args) = @_;
        $call_count++;
        return join('-', @args);
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    is($obj->concat('a', 'b', 'c'), 'a-b-c', 'concat a,b,c');
    is($call_count, 1, 'called once');

    is($obj->concat('a', 'b', 'c'), 'a-b-c', 'cached');
    is($call_count, 1, 'still one call');

    # Different args
    is($obj->concat('x', 'y'), 'x-y', 'concat x,y');
    is($call_count, 2, 'two calls');

    # Back to first args - still cached
    is($obj->concat('a', 'b', 'c'), 'a-b-c', 'original args still cached');
    is($call_count, 2, 'still two calls');
};

subtest 'no arguments (except self)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('get_time');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('get_time', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile no-arg memoize');

    no strict 'refs';

    my $call_count = 0;
    my $time_val = 1000;
    *{"${pkg}::_orig_get_time"} = sub {
        my ($self) = @_;
        $call_count++;
        return $time_val++;
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    is($obj->get_time, 1000, 'first call');
    is($call_count, 1, 'called once');

    is($obj->get_time, 1000, 'cached (same value)');
    is($call_count, 1, 'still one call');
};

subtest 'undef return value' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('maybe_null');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('maybe_null', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile memoize with undef');

    no strict 'refs';

    my $call_count = 0;
    *{"${pkg}::_orig_maybe_null"} = sub {
        my ($self, $key) = @_;
        $call_count++;
        return $key eq 'exists' ? 'found' : undef;
    };

    *{"${pkg}::new"} = sub { bless {}, shift };

    my $obj = $pkg->new;

    is($obj->maybe_null('exists'), 'found', 'existing key');
    is($call_count, 1, 'one call');

    is($obj->maybe_null('missing'), undef, 'missing key returns undef');
    is($call_count, 2, 'two calls');

    # Both should be cached now
    is($obj->maybe_null('exists'), 'found', 'cached exists');
    is($obj->maybe_null('missing'), undef, 'cached undef');
    is($call_count, 2, 'still two calls');
};

subtest 'multiple objects have separate caches' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('get_value');

    my $pkg = 'TestMemo' . ++$test_num;
    my $functions = $b->memoize_functions('get_value', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile for multi-object test');

    no strict 'refs';

    my %object_values;
    *{"${pkg}::_orig_get_value"} = sub {
        my ($self, $key) = @_;
        return $object_values{$self}{$key} // 'default';
    };

    *{"${pkg}::new"} = sub { bless {}, shift };
    *{"${pkg}::set_value"} = sub {
        my ($self, $key, $val) = @_;
        $object_values{$self}{$key} = $val;
    };

    my $obj1 = $pkg->new;
    my $obj2 = $pkg->new;

    $obj1->set_value('x', 'value1');
    $obj2->set_value('x', 'value2');

    is($obj1->get_value('x'), 'value1', 'obj1 gets value1');
    is($obj2->get_value('x'), 'value2', 'obj2 gets value2');

    # Each object has its own cache
    is($obj1->get_value('x'), 'value1', 'obj1 cached');
    is($obj2->get_value('x'), 'value2', 'obj2 cached');
};

subtest 'memoize_functions helper' => sub {
    my $b = XS::JIT::Builder->new;
    $b->memoize('process');

    my $functions = $b->memoize_functions('process', 'My::Package');

    is_deeply([sort keys %$functions], [
        'My::Package::clear_process_cache',
        'My::Package::process',
    ], 'memoize_functions returns correct keys');

    is($functions->{'My::Package::process'}{source}, 'process_memoized',
       'main function source');
    is($functions->{'My::Package::clear_process_cache'}{source}, 'clear_process_cache',
       'clear function source');
};

subtest 'error on unknown memoized function' => sub {
    my $b = XS::JIT::Builder->new;

    eval { $b->memoize_functions('nonexistent', 'Pkg') };
    like($@, qr/No memoized function named 'nonexistent' found/,
         'dies on unknown function');
};

subtest 'error on missing function name' => sub {
    my $b = XS::JIT::Builder->new;

    eval { $b->memoize(undef) };
    like($@, qr/memoize requires a function name/, 'dies on undef name');

    eval { $b->memoize('') };
    like($@, qr/memoize requires a function name/, 'dies on empty string');
};

done_testing;
