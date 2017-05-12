#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 45;
use Data::Dumper;

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
        nicknames => { is_many => 1, is => "Integer" },
    ],
};


my $m = URT::FancyItem->__meta__;
ok($m, "got metadata for test class");

my @p = $m->id_property_names;
is("@p", "name group", "property names are correct");

my $b = URT::Item->create(name => 'Joe', group => 'shirts');
ok($b, 'made a base class object');

my $p = URT::FancyItem->create(name => 'Bob', group => 'shirts', score => 1, foo => 'foo');
ok($p, "made a parent object");

my $c = URT::FancyItem->create(parent => $p, name => 'Fred', group => 'skins', score => 2);
ok($c, "made a child object which references it");

my $u = URT::UnrelatedItem->create(name => 'Bob', group => 'shirts');
ok($u, 'made an unrelated item object');

my $bx1 = URT::Item->define_boolexpr(name => ['Bob','Joe']);
my @o = URT::Item->get($bx1);
is(scalar(@o), 2, "got 2 items with an in-clause");

## OR ##

my $bx2a = URT::Item->define_boolexpr(name => 'Bob');
my $bx2b = URT::Item->define_boolexpr(group => 'skins');

my $bx2t = UR::BoolExpr::Template::Or->get_by_subject_class_name_logic_type_and_logic_detail(
    $bx2a->subject_class_name,
    'Or', 
    $bx2a->logic_detail . '|' . $bx2b->logic_detail,
);
my $bx2c = $bx2t->get_rule_for_values('Bob','skins');
ok(defined($bx2c), "got OR rule: $bx2c");

my ($bx3a,$bx3b) = $bx2c->template->get_underlying_rule_templates();
is($bx3a,$bx2a->template, "first expression in composite matches");
is($bx3b,$bx2b->template, "second expression in composite matches");
my $bx3 = URT::Item->define_boolexpr(-or => [[name => 'Bob'], [group => 'skins']]);
ok(defined($bx3), "created OR rule in a single expression");

is_deeply( $bx3, $bx2c, "matches the one individually composed");

my %as_two = map { $_->id => $_ } (URT::Item->get($bx2a), URT::Item->get($bx2b));
my %as_one = map { $_->id => $_ } URT::Item->get($bx3);
my @as_two = sort keys %as_two;
my @as_one = sort keys %as_one;
is("@as_one","@as_two", "results using -or match queries done separately"); 

# COMPLEX

#my $r = URT::FancyItem->define_boolexpr(foo => 222, -recurse => [qw/parent_name name parent_group group/], bar => 555);

my $r = URT::Item->define_boolexpr(foo => '');   # '' is the same as undef
ok($r, "Created a rule to get URT::Items with null 'foo's");
ok($r->specifies_value_for('foo'), 'Rule specifies a falue for foo');
is($r->value_for('foo'), '', "rule's value for property foo is empty string");
ok(! $r->specifies_value_for('name'), 'rule does not specify a value for name');
my @results = URT::Item->get($r);
is(scalar(@results), 2, 'Got 2 URT::Items with the rule');
ok(scalar(grep { $_->name eq 'Joe' } @results), 'Joe was returned');
ok(scalar(grep { $_->name eq 'Fred' } @results), 'Fred was returned');
ok(! scalar(grep { $_->name eq 'Bob' } @results), 'Bob was not returned');


$r = URT::FancyItem->define_boolexpr(foo => 222, -recurse => [parent_name => 'name', parent_group => 'group'], bar => 555);
ok($r, "got a rule to get objects using -recurse");

is($r->template->value_position_for_property_name('foo'),0, "position is as expected for variable param 1");
is($r->template->value_position_for_property_name('bar'),1, "position is as expected for variable param 2");
is($r->template->value_position_for_property_name('-recurse'),0, "position is as expected for constant param 1");

my $expected = [foo => 222, -recurse => [qw/parent_name name parent_group group/], bar => 555];
is_deeply(
    [$r->params_list],
    $expected,
    "params list for the rule is as expected"
)
    or print Dumper([$r->params_list],$expected);
    
my $t = $r->template;
ok($t, "got a template for the rule");

is($t->value_position_for_property_name('foo'),0, "position is as expected for variable param 1");
is($t->value_position_for_property_name('bar'),1, "position is as expected for variable param 2");
is($t->value_position_for_property_name('-recurse'),0, "position is as expected for constant param 1");

my @names = $t->_property_names;
is("@names","foo bar", "rule template knows its property names");

my $r2 = $t->get_rule_for_values(333,666);
ok($r2, "got a new rule from the template with different values for the non-constant values");

is_deeply(
    [$r2->params_list],
    [foo => 333, -recurse => [qw/parent_name name parent_group group/], bar => 666],
    "the new rule has the expected structure"
)
    or print Dumper([$r->params_list]);

$r = URT::FancyItem->define_boolexpr(foo => { operator => "between", value => [10,30] }, bar => { operator => "like", value => 'x%y' });
$t = $r->template();
is($t->operator_for('foo'),'between', "operator for param 1 is correct");
is($t->operator_for('bar'),'like', "operator for param 2 is correct");

$r = URT::FancyItem->define_boolexpr(foo => 10, bar => { operator => "like", value => 'x%y' });
$t = $r->template();
is($t->operator_for('foo'),'=', "operator for param 1 is correct");
is($t->operator_for('bar'),'like', "operator for param 2 is correct");

$r = URT::FancyItem->define_boolexpr(foo => { operator => "between", value => [10,30] }, bar => 20);
$t = $r->template();
is($t->operator_for('foo'),'between', "operator for param 1 is correct");
is($t->operator_for('bar'),'=', "operator for param 2 is correct");


# Make a rule on the parent class
$r = URT::Item->define_boolexpr(name => 'Bob', group => 'shirts', score => '01');
ok($r->evaluate($p), 'Original parent object evaluated though rule');

ok(! $r->evaluate($c), 'Child object with different params evaluated through parent rule returns false');

$r = URT::Item->define_boolexpr(name => 'Fred', group => 'skins');
ok($r->evaluate($c), 'Child object with same params evaluated through parent rule returns true');

# Make a rule on the child class
$r = URT::FancyItem->define_boolexpr(name => 'Joe', group => 'shirts');
ok(! $r->evaluate($b), 'Base class object evaluated through rule on child class returns false');

# An item of a different class but with the same params 
$r = URT::UnrelatedItem->define_boolexpr(name => 'Bob', group => 'shirts');
ok(! $r->evaluate($p), 'Original parent object evaluated false through rule on unrelatd class');

my $j = URT::UnrelatedItem->create(name => 'James', group => 'shirts', nicknames => [12345, 12347, 34, 36, 37]);
$r = URT::UnrelatedItem->define_boolexpr(nicknames => [12347, 82]);
ok($r->evaluate($j), 'Many-to-many comparison finds the matching nickname');
