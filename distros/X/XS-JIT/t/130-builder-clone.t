#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder;

my $cache_dir = tempdir(CLEANUP => 1);

subtest 'clone_hash - basic clone preserves keys/values' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_hash('hash_clone');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'HashClone1',
        cache_dir => $cache_dir,
        functions => {
            'HashClone1::clone' => { source => 'hash_clone', is_xs_native => 1 },
        },
    );
    
    my $obj = bless { name => 'Alice', age => 30 }, 'HashClone1';
    my $copy = $obj->clone;
    
    is($copy->{name}, 'Alice', 'clone has same name');
    is($copy->{age}, 30, 'clone has same age');
    ok(ref($copy) eq 'HashClone1', 'clone is blessed into same class');
};

subtest 'clone_hash - clone is independent' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_hash('hash_clone2');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'HashClone2',
        cache_dir => $cache_dir,
        functions => {
            'HashClone2::clone' => { source => 'hash_clone2', is_xs_native => 1 },
        },
    );
    
    my $obj = bless { value => 100 }, 'HashClone2';
    my $copy = $obj->clone;
    
    $copy->{value} = 200;
    is($obj->{value}, 100, 'modifying clone does not affect original');
    is($copy->{value}, 200, 'clone has modified value');
};

subtest 'clone_hash - clone preserves blessing' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_hash('hash_clone3');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'HashClone3',
        cache_dir => $cache_dir,
        functions => {
            'HashClone3::clone' => { source => 'hash_clone3', is_xs_native => 1 },
        },
    );
    
    my $obj = bless { data => 'test' }, 'HashClone3';
    my $copy = $obj->clone;
    
    isa_ok($copy, 'HashClone3');
    isnt($obj, $copy, 'clone is a different reference');
};

subtest 'clone_hash - handles nested refs (shallow copy)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_hash('hash_clone4');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'HashClone4',
        cache_dir => $cache_dir,
        functions => {
            'HashClone4::clone' => { source => 'hash_clone4', is_xs_native => 1 },
        },
    );
    
    my $nested = { inner => 'data' };
    my $obj = bless { nested => $nested, items => [1, 2, 3] }, 'HashClone4';
    my $copy = $obj->clone;
    
    is($copy->{nested}, $obj->{nested}, 'nested ref is same reference (shallow)');
    is($copy->{items}, $obj->{items}, 'array ref is same reference (shallow)');
    
    # Modifying nested affects both
    $copy->{nested}{inner} = 'changed';
    is($obj->{nested}{inner}, 'changed', 'nested modification affects original (shallow clone)');
};

subtest 'clone_array - basic clone preserves elements' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_array('array_clone');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayClone1',
        cache_dir => $cache_dir,
        functions => {
            'ArrayClone1::clone' => { source => 'array_clone', is_xs_native => 1 },
        },
    );
    
    my $obj = bless ['Alice', 30, 'Engineer'], 'ArrayClone1';
    my $copy = $obj->clone;
    
    is($copy->[0], 'Alice', 'clone has same element 0');
    is($copy->[1], 30, 'clone has same element 1');
    is($copy->[2], 'Engineer', 'clone has same element 2');
    ok(ref($copy) eq 'ArrayClone1', 'clone is blessed into same class');
};

subtest 'clone_array - clone is independent' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_array('array_clone2');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayClone2',
        cache_dir => $cache_dir,
        functions => {
            'ArrayClone2::clone' => { source => 'array_clone2', is_xs_native => 1 },
        },
    );
    
    my $obj = bless [100, 200, 300], 'ArrayClone2';
    my $copy = $obj->clone;
    
    $copy->[0] = 999;
    is($obj->[0], 100, 'modifying clone does not affect original');
    is($copy->[0], 999, 'clone has modified value');
};

subtest 'clone_array - clone preserves blessing' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_array('array_clone3');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayClone3',
        cache_dir => $cache_dir,
        functions => {
            'ArrayClone3::clone' => { source => 'array_clone3', is_xs_native => 1 },
        },
    );
    
    my $obj = bless ['test', 'data'], 'ArrayClone3';
    my $copy = $obj->clone;
    
    isa_ok($copy, 'ArrayClone3');
    isnt($obj, $copy, 'clone is a different reference');
};

subtest 'clone_array - handles nested refs (shallow copy)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->clone_array('array_clone4');
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'ArrayClone4',
        cache_dir => $cache_dir,
        functions => {
            'ArrayClone4::clone' => { source => 'array_clone4', is_xs_native => 1 },
        },
    );
    
    my $nested = { inner => 'data' };
    my $obj = bless [$nested, [1, 2, 3]], 'ArrayClone4';
    my $copy = $obj->clone;
    
    is($copy->[0], $obj->[0], 'nested ref is same reference (shallow)');
    is($copy->[1], $obj->[1], 'array ref is same reference (shallow)');
    
    # Modifying nested affects both
    $copy->[0]{inner} = 'changed';
    is($obj->[0]{inner}, 'changed', 'nested modification affects original (shallow clone)');
};

done_testing;
