#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 32;

class URT::Item {
    id_by => [qw/name group/],
    has => [
        name    => { is => "String" },
        group   => { is => "String" },
        parent  => { is => "URT::Item", is_optional => 1, id_by => ['parent_name','parent_group'] },
        parant_name => { is => 'String', via => 'parent', to => 'name' },
        foo     => { is => "String", is_optional => 1 },
        bar     => { is => "String", is_optional => 1 },
        score   => { is => 'Integer' },
    ]
};

class URT::FancyItem {
    is  => 'URT::Item',
    has => [
        feet    => { is => "String" }
    ]
};

class URT::UnrelatedItem {
    has => [
        name    => { is => "String" },
        group   => { is => "String" },
        nicknames => { is_many => 1, is => "Integer" },
    ],
};

# First an easy one....
my $bx = URT::FancyItem->define_boolexpr(name => 'Fred', -order => [ 'bar' ]);
ok($bx, 'Made a simple rule with -order');
ok($bx->specifies_value_for('name'), 'Rule has value for name');
is($bx->value_for('name'), 'Fred', 'Rule has correct value for for name');
ok(! $bx->specifies_value_for('foo'), 'Rule correctly has no value for foo');
is_deeply($bx->value_for('-order'), ['bar'], 'Rule has correct value for -order');


# Try a compound rule

$bx = URT::FancyItem->define_boolexpr(-or => [ [ name => 'Fred' ], [foo => 'bar'] ], -order => [ 'bar' ]);
ok($bx, 'Make Or-type rule with -order');
my @underlying = $bx->underlying_rules();
is(scalar(@underlying), 2, 'There were 2 underlying rules');

ok($underlying[0]->specifies_value_for('name'), 'First underlying rule has value for name');
is($underlying[0]->value_for('name'), 'Fred', 'First underlying rule has correct value for for name');
ok(! $underlying[0]->specifies_value_for('foo'), 'First underlying rule correctly has no value for foo');
is_deeply($underlying[0]->value_for('-order'), ['bar'], 'First underlying rule has correct value for -order');

ok(! $underlying[1]->specifies_value_for('name'), 'Second underlying rule correctly has no value for name');
ok($underlying[1]->specifies_value_for('foo'), 'Second underlying rule has value for foo');
is($underlying[1]->value_for('foo'), 'bar', 'Second underlying rule has correct value for for name');
is_deeply($underlying[1]->value_for('-order'), ['bar'], 'Second underlying rule has correct value for -order');



# another compound rule with 3 parts

$bx = URT::FancyItem->define_boolexpr(-or => [ [ name => 'Fred' ], [foo => 'bar'], ['score >' => 3 ]],
                                            -hints => ['bar','parent_name']);
ok($bx, 'Make Or-type rule with -hints');
@underlying = $bx->underlying_rules();
is(scalar(@underlying), 3, 'There were 3 underlying rules');

ok($underlying[0]->specifies_value_for('name'), 'First underlying rule has value for name');
is($underlying[0]->value_for('name'), 'Fred', 'First underlying rule has correct value for for name');
ok(! $underlying[0]->specifies_value_for('foo'), 'First underlying rule correctly has no value for foo');
ok(! $underlying[0]->specifies_value_for('score'), 'First underlying rule correctly has no value for score');
is_deeply($underlying[0]->value_for('-hints'), ['bar','parent_name'], 'First underlying rule has correct value for -hints');

ok(! $underlying[1]->specifies_value_for('name'), 'Second underlying rule correctly has no value for name');
ok($underlying[1]->specifies_value_for('foo'), 'Second underlying rule has value for foo');
is($underlying[1]->value_for('foo'), 'bar', 'Second underlying rule has correct value for for name');
ok(! $underlying[1]->specifies_value_for('score'), 'Second underlying rule correctly has no value for score');
is_deeply($underlying[1]->value_for('-hints'), ['bar','parent_name'], 'Second underlying rule has correct value for -hints');

ok(! $underlying[2]->specifies_value_for('name'), 'Third underlying rule has value for name');
ok(! $underlying[2]->specifies_value_for('foo'), 'Third underlying rule correctly has no value for foo');
ok($underlying[2]->specifies_value_for('score'), 'Third underlying rule has value for score');
is($underlying[2]->value_for('score'), 3, 'Third underlying rule has correct value for for score');
is_deeply($underlying[2]->value_for('-hints'), ['bar','parent_name'], 'Third underlying rule has correct value for -hints');


