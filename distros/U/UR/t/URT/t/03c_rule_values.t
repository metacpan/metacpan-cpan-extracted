#!/usr/bin/env perl

# Test handling of rules and their values with different kinds
# params.

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 21;
use Data::Dumper;
use IO::Handle;

class URT::RelatedItem {
    id_by => 'ritem_id',
    has => [
        ritem_property => { is => 'String' },
    ],
};

class URT::Item {
    id_by => [qw/name group/],
    has => [
        name    => { is => "String" },
        parent  => { is => "URT::Item", is_optional => 1, id_by => ['parent_name','parent_group'] },
        foo     => { is => "String", is_optional => 1 },
        fh      => { is => "IO::Handle", is_optional => 1 },
        score   => { is => 'Integer' },
        ritem   => { is => 'URT::RelatedItem', id_by => 'ritem_id' },
    ]
};

my($r, @values, $n, $expected,$fh);

$r = URT::Item->define_boolexpr(name => ['Bob'], foo => undef, -hints => ['ritem']);
ok($r, 'Created boolexpr');

# These values are in the same order as the original rule definition
@values = $r->values();
is(scalar(@values), 2, 'Got back 2 values from rule');
$expected = [['Bob'], undef];
is_deeply(\@values, $expected, "Rule's values are correct");

$n = $r->normalize;
ok($n, 'Normalized rule');
# Normalized values come back alpha sorted by their param's name
# foo, name
@values = $n->values();
$expected = [undef, ['Bob']];
is_deeply(\@values, $expected, "Normalized rule's values are correct");



$fh = IO::Handle->new();
$r = URT::Item->define_boolexpr(name => ['Bob'], fh => $fh, foo => undef);

# These values are in the same order as the original rule definition
@values = $r->values();
is(scalar(@values), 3, 'Got back 3 values from rule');
$expected = [['Bob'], $fh, undef];
is_deeply(\@values, $expected, "Rule's values are correct");

$n = $r->normalize;
ok($n, 'Normalized rule');
# Normalized values come back alpha sorted by their param's name
# fh, foo, name
@values = $n->values();
$expected = [$fh, undef, ['Bob']];
is_deeply(\@values, $expected, "Normalized rule's values are correct");





$r = URT::Item->define_boolexpr(name => ['Bob'], fh => $fh, foo => undef, -hints => ['ritem']);

# These values are in the same order as the original rule definition
@values = $r->values();
is(scalar(@values), 3, 'Got back 3 values from rule');
$expected = [['Bob'], $fh, undef];
is_deeply(\@values, $expected, "Rule's values are correct");

$n = $r->normalize;
ok($n, 'Normalized rule');
# Normalized values come back alpha sorted by their param's name
# -hints, fh, foo, name
@values = $n->values();
$expected = [$fh, undef, ['Bob']];
is_deeply(\@values, $expected, "Normalized rule's values are correct");




my @p = (name => [$fh], score => 1, foo => undef, -hints => ['ritem']);
$r = URT::Item->define_boolexpr(@p);
my @p2 = $r->params_list();
#is("@p","@p2",'params return correctly with hint');
is_deeply(\@p,\@p2, "match deeply");

# These values are in the same order as the original rule definition
@values = $r->values();
is(scalar(@values), 3, 'Got back 3 values from rule');
$expected = [[$fh], 1, undef];
is_deeply(\@values, $expected, "Rule's values are correct");
is($values[0][0], $p[1][0], 'object is preserved within the arrayref of references');

$n = $r->normalize;
ok($n, 'Normalized rule');
# Normalized values come back alpha sorted by their param's name
# foo, name, score
@values = $n->values();
$expected = [undef, [$fh], 1];
is_deeply(\@values, $expected, "Normalized rule's values are correct");


# Check that duplicate values in an in-clause are handled correctly
my $rule = URT::Item->define_boolexpr(name => ['Bob', 'Bob', 'Rob', 'Rob', 'Joe', 'Foo']);
ok($rule, 'rule with duplicate values created');
my $values = $rule->value_for('name');
my @expected = ('Bob', 'Foo', 'Joe','Rob');
is_deeply($values, \@expected, 'duplicates were filtered out correctly');



