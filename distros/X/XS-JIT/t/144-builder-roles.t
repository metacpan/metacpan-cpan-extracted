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

subtest 'Comparable role - basic' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Comparable');

    my $pkg = 'TestComparable' . ++$test_num;
    my $code = $b->code;

    ok(XS::JIT->compile(
        code      => $code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::compare" => { source => 'compare', is_xs_native => 1 },
            "${pkg}::equals"  => { source => 'equals', is_xs_native => 1 },
            "${pkg}::lt"      => { source => 'lt', is_xs_native => 1 },
            "${pkg}::gt"      => { source => 'gt', is_xs_native => 1 },
            "${pkg}::le"      => { source => 'le', is_xs_native => 1 },
            "${pkg}::ge"      => { source => 'ge', is_xs_native => 1 },
        },
    ), 'compile Comparable role');

    my $obj1 = bless { id => 'alice' }, $pkg;
    my $obj2 = bless { id => 'bob' }, $pkg;
    my $obj3 = bless { id => 'alice' }, $pkg;

    # compare
    is($obj1->compare($obj2), -1, 'alice < bob');
    is($obj2->compare($obj1), 1, 'bob > alice');
    is($obj1->compare($obj3), 0, 'alice == alice');

    # equals
    ok($obj1->equals($obj3), 'obj1 equals obj3');
    ok(!$obj1->equals($obj2), 'obj1 not equals obj2');

    # lt, gt
    ok($obj1->lt($obj2), 'alice lt bob');
    ok(!$obj2->lt($obj1), 'bob not lt alice');
    ok($obj2->gt($obj1), 'bob gt alice');
    ok(!$obj1->gt($obj2), 'alice not gt bob');

    # le, ge
    ok($obj1->le($obj2), 'alice le bob');
    ok($obj1->le($obj3), 'alice le alice');
    ok($obj2->ge($obj1), 'bob ge alice');
    ok($obj1->ge($obj3), 'alice ge alice');
};

subtest 'Comparable role - custom compare_key' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Comparable', { compare_key => 'name' });

    my $pkg = 'TestComparableName' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::compare" => { source => 'compare', is_xs_native => 1 },
            "${pkg}::equals"  => { source => 'equals', is_xs_native => 1 },
        },
    ), 'compile Comparable with custom key');

    my $obj1 = bless { name => 'Alice', id => 999 }, $pkg;
    my $obj2 = bless { name => 'Bob', id => 1 }, $pkg;

    is($obj1->compare($obj2), -1, 'compares by name, not id');
    ok(!$obj1->equals($obj2), 'not equals by name');
};

subtest 'Cloneable role' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Cloneable');

    my $pkg = 'TestCloneable' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::clone" => { source => 'clone', is_xs_native => 1 },
        },
    ), 'compile Cloneable role');

    my $obj = bless { name => 'Alice', age => 30 }, $pkg;
    my $clone = $obj->clone;

    isnt($clone, $obj, 'clone is different reference');
    is(ref($clone), $pkg, 'clone has same class');
    is($clone->{name}, 'Alice', 'clone has same name');
    is($clone->{age}, 30, 'clone has same age');

    # Modify clone doesn't affect original
    $clone->{name} = 'Bob';
    is($obj->{name}, 'Alice', 'original unchanged after modifying clone');
};

subtest 'Serializable role' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Serializable');

    my $pkg = 'TestSerializable' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::TO_JSON" => { source => 'TO_JSON', is_xs_native => 1 },
            "${pkg}::TO_HASH" => { source => 'TO_HASH', is_xs_native => 1 },
        },
    ), 'compile Serializable role');

    my $obj = bless { name => 'Alice', age => 30, _private => 'secret' }, $pkg;

    my $json = $obj->TO_JSON;
    isa_ok($json, 'HASH', 'TO_JSON returns hashref');
    is($json->{name}, 'Alice', 'TO_JSON includes name');
    is($json->{age}, 30, 'TO_JSON includes age');
    ok(!exists $json->{_private}, 'TO_JSON excludes private attrs (starting with _)');
    isnt($json, $obj, 'TO_JSON returns copy, not same ref');

    my $hash = $obj->TO_HASH;
    isa_ok($hash, 'HASH', 'TO_HASH returns hashref');
    is($hash->{_private}, 'secret', 'TO_HASH includes private attrs');
    ok(exists $hash->{name} && exists $hash->{age}, 'TO_HASH includes all keys');
};

subtest 'Observable role - basic' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Observable');

    my $pkg = 'TestObservable' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::add_observer"     => { source => 'add_observer', is_xs_native => 1 },
            "${pkg}::remove_observer"  => { source => 'remove_observer', is_xs_native => 1 },
            "${pkg}::notify_observers" => { source => 'notify_observers', is_xs_native => 1 },
        },
    ), 'compile Observable role');

    my $obj = bless { _observers => [] }, $pkg;
    my @received;

    my $observer = sub { push @received, [@_] };
    $obj->add_observer($observer);

    $obj->notify_observers('event1', 'arg1');
    is(scalar @received, 1, 'observer called once');
    is_deeply($received[0], ['event1', 'arg1'], 'observer received args');

    @received = ();
    $obj->notify_observers('event2');
    is(scalar @received, 1, 'observer called again');
    is_deeply($received[0], ['event2'], 'observer received new args');

    $obj->remove_observer($observer);
    @received = ();
    $obj->notify_observers('event3');
    is(scalar @received, 0, 'observer not called after removal');
};

subtest 'Observable role - multiple observers' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Observable');

    my $pkg = 'TestObservableMulti' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::add_observer"     => { source => 'add_observer', is_xs_native => 1 },
            "${pkg}::notify_observers" => { source => 'notify_observers', is_xs_native => 1 },
        },
    ), 'compile Observable for multi test');

    my $obj = bless { _observers => [] }, $pkg;
    my @log1;
    my @log2;

    $obj->add_observer(sub { push @log1, 'obs1' });
    $obj->add_observer(sub { push @log2, 'obs2' });

    $obj->notify_observers();
    is(scalar @log1, 1, 'first observer called');
    is(scalar @log2, 1, 'second observer called');
};

subtest 'Observable role - custom observers_attr' => sub {
    my $b = XS::JIT::Builder->new;
    $b->role('Observable', { observers_attr => '_watchers' });

    my $pkg = 'TestObservableCustom' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::add_observer"     => { source => 'add_observer', is_xs_native => 1 },
            "${pkg}::notify_observers" => { source => 'notify_observers', is_xs_native => 1 },
        },
    ), 'compile Observable with custom attr');

    my $obj = bless { _watchers => [] }, $pkg;
    my $called = 0;

    $obj->add_observer(sub { $called++ });
    $obj->notify_observers();
    is($called, 1, 'observer in _watchers called');
};

subtest 'with_roles - multiple roles' => sub {
    my $b = XS::JIT::Builder->new;
    $b->with_roles(['Comparable', 'Cloneable', 'Serializable']);

    my $pkg = 'TestMultiRole' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::compare"  => { source => 'compare', is_xs_native => 1 },
            "${pkg}::equals"   => { source => 'equals', is_xs_native => 1 },
            "${pkg}::lt"       => { source => 'lt', is_xs_native => 1 },
            "${pkg}::gt"       => { source => 'gt', is_xs_native => 1 },
            "${pkg}::le"       => { source => 'le', is_xs_native => 1 },
            "${pkg}::ge"       => { source => 'ge', is_xs_native => 1 },
            "${pkg}::clone"    => { source => 'clone', is_xs_native => 1 },
            "${pkg}::TO_JSON"  => { source => 'TO_JSON', is_xs_native => 1 },
            "${pkg}::TO_HASH"  => { source => 'TO_HASH', is_xs_native => 1 },
        },
    ), 'compile multiple roles');

    my $obj1 = bless { id => 'alice', name => 'Alice' }, $pkg;
    my $obj2 = bless { id => 'bob', name => 'Bob' }, $pkg;

    # Test Comparable
    ok($obj1->lt($obj2), 'alice lt bob (Comparable)');

    # Test Cloneable
    my $clone = $obj1->clone;
    is($clone->{name}, 'Alice', 'clone works (Cloneable)');
    isnt($clone, $obj1, 'clone is different ref');

    # Test Serializable
    my $hash = $obj1->TO_HASH;
    is($hash->{id}, 'alice', 'TO_HASH works (Serializable)');
};

subtest 'with_roles - with options' => sub {
    my $b = XS::JIT::Builder->new;
    $b->with_roles(['Comparable', 'Observable'], {
        compare_key    => 'priority',
        observers_attr => '_listeners',
    });

    my $pkg = 'TestRolesOpts' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => {
            "${pkg}::compare"          => { source => 'compare', is_xs_native => 1 },
            "${pkg}::add_observer"     => { source => 'add_observer', is_xs_native => 1 },
            "${pkg}::notify_observers" => { source => 'notify_observers', is_xs_native => 1 },
        },
    ), 'compile roles with options');

    # Test Comparable uses priority
    my $low  = bless { priority => 1, _listeners => [] }, $pkg;
    my $high = bless { priority => 9, _listeners => [] }, $pkg;
    is($low->compare($high), -1, 'compares by priority');

    # Test Observable uses _listeners
    my $called = 0;
    $low->add_observer(sub { $called++ });
    $low->notify_observers();
    is($called, 1, 'observer in _listeners called');
};

subtest 'error handling - unknown role' => sub {
    my $b = XS::JIT::Builder->new;

    eval { $b->role('UnknownRole') };
    like($@, qr/Unknown role.*UnknownRole/, 'dies on unknown role');

    eval { $b->with_roles(['Comparable', 'BadRole']) };
    like($@, qr/Unknown role.*BadRole/, 'dies on unknown role in array');
};

subtest 'error handling - missing name' => sub {
    my $b = XS::JIT::Builder->new;

    eval { $b->role(undef) };
    like($@, qr/role requires a role name/, 'dies on undef role name');

    eval { $b->role('') };
    like($@, qr/role requires a role name/, 'dies on empty role name');
};

subtest 'error handling - with_roles requires arrayref' => sub {
    my $b = XS::JIT::Builder->new;

    eval { $b->with_roles('Comparable') };
    like($@, qr/with_roles requires an arrayref/, 'dies on string instead of arrayref');

    eval { $b->with_roles({ role => 'Comparable' }) };
    like($@, qr/with_roles requires an arrayref/, 'dies on hashref instead of arrayref');
};

subtest 'role chaining' => sub {
    my $b = XS::JIT::Builder->new;

    my $result = $b->role('Comparable')
                   ->role('Cloneable');

    is($result, $b, 'role returns $self for chaining');
};

subtest 'with_roles chaining' => sub {
    my $b = XS::JIT::Builder->new;

    my $result = $b->with_roles(['Comparable'])
                   ->with_roles(['Cloneable']);

    is($result, $b, 'with_roles returns $self for chaining');
};

done_testing;
