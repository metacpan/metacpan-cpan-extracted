#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 25;

class URT::Item {
    id_by => [qw/name group/],
    has => [
        name    => { is => "String" },
        group   => { is => "String" },
        parent  => { is => "URT::Item", is_optional => 1, id_by => ['parent_name','parent_group'] },
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
    ],
};


my($r1, $r2);


$r1 = URT::FancyItem->define_boolexpr();
ok($r1->is_subset_of($r1), 'boolexpr with no filters is a subset of itself');


$r1 = URT::FancyItem->define_boolexpr(name => 'Bob');
ok($r1->is_subset_of($r1), 'boolexpr with one filter is a subset of itself');


$r1 = URT::Item->define_boolexpr(name => 'Bob');
$r2 = URT::Item->define_boolexpr(name => 'Bob');
ok($r1->is_subset_of($r2), 'Two rules with the same filters are a subset');
ok($r2->is_subset_of($r1), 'Two rules with the same filters are a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob', group => 'home');
$r2 = URT::Item->define_boolexpr(name => 'Bob', group => 'home');
ok($r1->is_subset_of($r2), 'Two rules with the same filters are a subset');
ok($r2->is_subset_of($r1), 'Two rules with the same filters are a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob', group => 'home');
$r2 = URT::Item->define_boolexpr(group => 'home', name => 'Bob');
ok($r1->is_subset_of($r2), 'Two rules with the same filters in a different order are a subset');
ok($r2->is_subset_of($r1), 'Two rules with the same filters in a different order are a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob');
$r2 = URT::Item->define_boolexpr(name => 'Fred');
ok(! $r1->is_subset_of($r2), 'Rule with different value for same filter name is not a subset');
ok(! $r2->is_subset_of($r1), 'Rule with different value for same filter name is not a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob');
$r2 = URT::Item->define_boolexpr(group => 'Bob');
ok(! $r1->is_subset_of($r2), 'Rule with different param names and same value is not a subset');
ok(! $r2->is_subset_of($r1), 'Rule with different param names and same value is not a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob');
$r2 = URT::Item->define_boolexpr();
ok($r1->is_subset_of($r2), 'one filter is a subset of no filters');
ok(! $r2->is_subset_of($r1), 'converse is not a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob', group => 'home');
$r2 = URT::Item->define_boolexpr(name => 'Bob');
ok($r1->is_subset_of($r2), 'Rule with two filters is subset of rule with one filter');
ok(! $r2->is_subset_of($r1),' Rule with one filter is not a subset of rule with two filters');


$r1 = URT::FancyItem->define_boolexpr();
$r2 = URT::Item->define_boolexpr();
ok($r1->is_subset_of($r2), 'subset by inheritance with no filters');
ok(! $r2->is_subset_of($r1), 'ancestry is not a subset');


$r1 = URT::FancyItem->define_boolexpr(name => 'Bob');
$r2 = URT::Item->define_boolexpr(name => 'Bob');
ok($r1->is_subset_of($r2), 'inheritance and one filter is subset');
ok(! $r2->is_subset_of($r1), 'ancestry and one filter is not a subset');


$r1 = URT::FancyItem->define_boolexpr(name => 'Bob', group => 'home');
$r2 = URT::Item->define_boolexpr(group => 'home', name => 'Bob');
ok($r1->is_subset_of($r2), 'inheritance and two filters in different order is subset');
ok(! $r2->is_subset_of($r1), 'ancestry and two filters in different order is not a subset');


$r1 = URT::Item->define_boolexpr(name => 'Bob');
$r2 = URT::UnrelatedItem->define_boolexpr(name => 'Bob');
ok(! $r1->is_subset_of($r2), 'Rules on unrelated classes with same filters is not a subset');
ok(! $r2->is_subset_of($r1), 'Rules on unrelated classes with same filters is not a subset');


subtest 'limit and offset' => sub {
    plan tests => 23;

    my $r1 = URT::Item->define_boolexpr(-limit => 5);
    ok($r1->is_subset_of($r1), 'no filters with limit is subset of itself');
    my $r2 = URT::Item->define_boolexpr();
    ok($r1->is_subset_of($r2), 'no filters with limit is subset of no filters');
    ok(!$r2->is_subset_of($r1), 'no filters is not a subset of no filters with limit');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -limit => 5);
    ok($r1->is_subset_of($r1), 'filters with limit is subset of itself');
    $r2 = URT::Item->define_boolexpr(name => 'Bob');
    ok($r1->is_subset_of($r2), 'filters with limit is subset of same filters without limit');
    ok(!$r2->is_subset_of($r1), 'filters without limit is not a subset of filters with limit');


    $r1 = URT::Item->define_boolexpr(-offset => 5);
    ok($r1->is_subset_of($r1), 'no filters with offset is subset of itself');
    $r2 = URT::Item->define_boolexpr();
    ok($r1->is_subset_of($r2), 'no filters with offset is subset of no filters');
    ok(!$r2->is_subset_of($r1), 'no filters is not a subset of no filters with offset');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -offset => 5);
    ok($r1->is_subset_of($r1), 'filters with offset is subset of itself');
    $r2 = URT::Item->define_boolexpr(name => 'Bob');
    ok($r1->is_subset_of($r2), 'filters with offset is subset of same filters without offset');
    ok(!$r2->is_subset_of($r1), 'filters without offset is not a subset of filters with offset');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -offset => 5, -limit => 5);
    ok($r1->is_subset_of($r1), 'filters with limit and offset is subset of itself');
    $r2 = URT::Item->define_boolexpr(name => 'Bob');
    ok($r1->is_subset_of($r2), 'filters with offset and limit is subset of same filters without limit and offset');
    ok(!$r2->is_subset_of($r1), 'filters without offset and limit is not subset of same filters with limit and offset');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -offset => 5, -limit => 5);
    $r2 = URT::Item->define_boolexpr(name => 'Bob', -offset => 1, -limit => 10);
    ok($r1->is_subset_of($r2), 'bx with encompassed range is subset');
    ok(!$r2->is_subset_of($r1), 'bx with encompassing range is not subset');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -offset => 1, -limit => 5);
    $r2 = URT::Item->define_boolexpr(name => 'Bob', -offset => 2, -limit => 5);
    ok(!$r1->is_subset_of($r2), 'bx with overlapping but not encompassing range is not subset');
    ok(!$r2->is_subset_of($r1), 'bx with overlapping but not encompassing range is not subset');


    $r1 = URT::Item->define_boolexpr(name => 'Bob', -offset => 1, -limit => 5);
    $r2 = URT::Item->define_boolexpr(name => 'Bob', -offset => 10, -limit => 5);
    ok(!$r1->is_subset_of($r2), 'bx with disjoint ranges is not subset');
    ok(!$r2->is_subset_of($r1), 'bx with disjoint ranges is not subset');


    $r1 = URT::Item->define_boolexpr('score >' => 10, -limit => 5);
    $r2 = URT::Item->define_boolexpr(-limit => 5);
    ok(! $r1->is_subset_of($r2), 'bx with filter and limit is not subset of no filter with limit');
    ok(! $r2->is_subset_of($r1), 'bx with limit is not subset of filter and limit');
};
