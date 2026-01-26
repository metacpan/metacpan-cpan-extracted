#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test new_simple
# ============================================
subtest 'new_simple constructor' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_simple('new');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestSimple',
        cache_dir => $cache_dir,
        functions => {
            'TestSimple::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = TestSimple->new;
    isa_ok($obj, 'TestSimple');
    is(ref($obj), 'TestSimple', 'correctly blessed');
    is_deeply($obj, {}, 'empty hash');
};

# ============================================
# Test new_hash with flat args
# ============================================
subtest 'new_hash with flat args' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestHashFlat',
        cache_dir => $cache_dir,
        functions => {
            'TestHashFlat::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = TestHashFlat->new(name => 'Alice', age => 30);
    isa_ok($obj, 'TestHashFlat');
    is($obj->{name}, 'Alice', 'name set');
    is($obj->{age}, 30, 'age set');
};

# ============================================
# Test new_hash with hashref
# ============================================
subtest 'new_hash with hashref' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_hash('new');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestHashRef',
        cache_dir => $cache_dir,
        functions => {
            'TestHashRef::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = TestHashRef->new({ name => 'Bob', age => 25 });
    isa_ok($obj, 'TestHashRef');
    is($obj->{name}, 'Bob', 'name set from hashref');
    is($obj->{age}, 25, 'age set from hashref');
};

# ============================================
# Test new_array
# ============================================
subtest 'new_array constructor' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_array('new', 3);
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestArray',
        cache_dir => $cache_dir,
        functions => {
            'TestArray::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = TestArray->new;
    isa_ok($obj, 'TestArray');
    ok(ref($obj) eq 'TestArray', 'correctly blessed');
    is(scalar(@$obj), 3, 'has 3 slots');
    ok(!defined($obj->[0]), 'slot 0 is undef');
    ok(!defined($obj->[1]), 'slot 1 is undef');
    ok(!defined($obj->[2]), 'slot 2 is undef');
    
    # Can set slots
    $obj->[0] = 'first';
    $obj->[1] = 42;
    is($obj->[0], 'first', 'can set slot 0');
    is($obj->[1], 42, 'can set slot 1');
};

# ============================================
# Test new_with_build
# ============================================
subtest 'new_with_build constructor' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_build('new');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestBuild',
        cache_dir => $cache_dir,
        functions => {
            'TestBuild::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # Define BUILD in the package
    my $build_called = 0;
    my $build_args;
    no strict 'refs';
    *{'TestBuild::BUILD'} = sub {
        my ($self, $args) = @_;
        $build_called = 1;
        $build_args = $args;
        $self->{initialized} = 1;
    };
    use strict 'refs';
    
    my $obj = TestBuild->new(name => 'Charlie', age => 35);
    isa_ok($obj, 'TestBuild');
    is($obj->{name}, 'Charlie', 'name set');
    is($obj->{age}, 35, 'age set');
    ok($build_called, 'BUILD was called');
    is($build_args->{name}, 'Charlie', 'BUILD received args');
    is($obj->{initialized}, 1, 'BUILD modified object');
};

# ============================================
# Test new_with_build without BUILD method
# ============================================
subtest 'new_with_build without BUILD' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_with_build('new');
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestNoBuild',
        cache_dir => $cache_dir,
        functions => {
            'TestNoBuild::new' => { source => 'new', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # No BUILD defined in TestNoBuild
    my $obj = TestNoBuild->new(foo => 'bar');
    isa_ok($obj, 'TestNoBuild');
    is($obj->{foo}, 'bar', 'args still work without BUILD');
};

done_testing();
