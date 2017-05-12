use Test::More;

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

plan tests => 56;

ok( UR::Object::Type->define(
        class_name => 'URT::Related',
        id_by => ['rel_id_a', 'rel_id_b'],
        # purposefully make the complete definitions for the ID properties
        # in a different order.  The real order should be whatever was in id_by
        has => [
            rel_id_b => { is => 'Integer' },
            related_value => { is => 'String' },
            rel_id_a => { is => 'Integer' },
        ],
     ), 'Define related class');


ok( UR::Object::Type->define(
        class_name => 'URT::Parent',
        id_by => [ parent_id => { is => 'Integer' } ],
        has => [
            parent_value => { is => 'String' },
            related_object => { is => 'URT::Related', id_by => ['rel_id_a', 'rel_id_b']},
            related_value => { via => 'related_object', to => 'related_value' },
        ]
   ), 'Define parent class');

ok( UR::Object::Type->define(
        class_name => 'URT::Child',
        is => 'URT::Parent',
        id_by => [ child_id => { is => 'Integer' } ],
        has =>  [
           child_value => { is => 'String' },
        ],
   ), 'Define child class');


my $parent_meta = URT::Parent->__meta__;
ok($parent_meta, 'Parent class metadata');


my @props = $parent_meta->direct_id_property_metas();
is(scalar(@props), 1, 'Parent class has 1 ID property');
my @names = map { $_->property_name } @props;
my @expected = qw(parent_id);
is_deeply(\@names, \@expected, 'Property names match');


my $related_meta = URT::Related->__meta__;
ok($related_meta, 'Related class metadata');
@props = $related_meta->direct_id_property_metas();
is(scalar(@props), 2, 'Related class has 2 ID properties');
@names = map { $_->property_name } @props;
@expected = qw(rel_id_a rel_id_b);
is_deeply(\@names, \@expected, 'Property names match');

my $prop = $related_meta->property_meta_for_name('rel_id_a');
# is_id actually returns "0 but true" for the first one
is($prop->is_id + 0, 0, 'id position for Related property rel_id_a is 0');
$prop = $related_meta->property_meta_for_name('rel_id_b');
is($prop->is_id, 1, 'id position for Related property rel_id_b is 1');
$prop = $related_meta->property_meta_for_name('related_value');
is($prop->is_id, undef, 'id position for Related property rel_id_b is undef');



@props = $parent_meta->direct_property_metas();
is(scalar(@props), 6, 'Parent class has 6 direct properties with direct_property_metas');
@names = sort map { $_->property_name } @props;
@expected = qw(parent_id parent_value rel_id_a rel_id_b related_object related_value);
is_deeply(\@names, \@expected, 'Property names check out');
@names = sort $parent_meta->direct_property_names;
is_deeply(\@names, \@expected, 'Property names from direct_property_names are correct');

$prop = $parent_meta->direct_property_meta(property_name => 'related_value');
ok($prop, 'singular property accessor works');


my $child_meta = URT::Child->__meta__;
ok($child_meta, 'Child class metadata');

@props = $child_meta->direct_property_metas();
is(scalar(@props), 2, 'Child class has 2 direct properties');
@names = sort map { $_->property_name } @props;
@expected = qw(child_id child_value);
is_deeply(\@names, \@expected, 'Property names check out');
@names = sort $child_meta->direct_property_names;
is_deeply(\@names, \@expected, 'Property names from direct_property_names are correct');

@props = $child_meta->all_property_metas();
is(scalar(@props), 9, 'Child class has 9 properties through all_property_metas');
@names = sort map { $_->property_name } @props;
@expected = qw(child_id child_value id parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names,\@expected, 'Property names check out');

# properties() only returns properties with storage, not object accessors or the property named 'id'
@props = $child_meta->properties();
is(scalar(@props), 9, 'Child class has 9 properties through properties()') or diag join(", ",$child_meta->property_names);
@names = sort map { $_->property_name } @props;
@expected = qw(child_id child_value id parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names,\@expected, 'Property names check out') or diag "@names\n@expected\n";

$prop = $child_meta->direct_property_meta(property_name => 'related_value');
ok(! $prop, "getting a property defined on parent class through child's direct_property_meta finds nothing");
$prop = $child_meta->property_meta_for_name('related_value');
ok($prop, "getting a property defined on parent class through child's property_meta_for_name works");


ok(UR::Object::Property->create( class_name => 'URT::Child', property_name => 'extra_property', data_type => 'String'),
   'Created an extra property on Child class');

@props = $child_meta->properties();
is(scalar(@props), 10, 'Child class now has 10 properties()');
@names = map { $_->property_name } @props;
@expected = qw(child_id child_value extra_property id parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names, \@expected, 'Property names check out') or diag ("@names\n@expected\n");

@props = $child_meta->direct_property_metas();
is(scalar(@props), 3, 'Child class now has 3 direct_property_metas()');

@props = $child_meta->all_property_metas();
is(scalar(@props), 10, 'Child class now has 10 properties through all_property_names()');
@names = sort map { $_->property_name } @props;
@expected = qw(child_id child_value extra_property id parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names, \@expected, 'Property names check out');



ok(UR::Object::Property->create( class_name => 'URT::Parent', property_name => 'parent_extra', data_type => 'String'),
   'Created extra property on parent class');

@props = $parent_meta->direct_property_metas();
is(scalar(@props), 7, 'Parent class now has 7 direct properties with direct_property_metas');
@names = sort map { $_->property_name } @props;
@expected = qw(parent_extra parent_id parent_value rel_id_a rel_id_b related_object related_value);
is_deeply(\@names, \@expected, 'Property names check out');
@names = sort $parent_meta->direct_property_names;
is_deeply(\@names, \@expected, 'Property names from direct_property_names are correct');

@props = $child_meta->properties();
is(scalar(@props), 11, 'Child class now has 11 properties()');
@names = map { $_->property_name } @props;
@expected = qw(child_id child_value extra_property id parent_extra parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names, \@expected, 'Property names check out') or diag "@names\n@expected\n";

@props = $child_meta->all_property_metas();
is(scalar(@props), 11, 'Child class now has 11 properties through all_property_names()');
@names = sort map { $_->property_name } @props;
@expected = qw(child_id child_value extra_property id parent_extra parent_id parent_value rel_id_a rel_id_b related_object related_value),
is_deeply(\@names, \@expected, 'Property names check out');


@props = $parent_meta->property_meta_for_name('related_object');
is(scalar(@props), 1, 'Parent class has a property called related_object');
is($props[0]->property_name, 'related_object', 'Got the right property');

@props = $child_meta->property_meta_for_name('related_object');
is(scalar(@props), 1, 'Child class also has a property called related_object');
is($props[0]->property_name, 'related_object', 'Got the right property');

@props = $child_meta->property_meta_for_name('related_object.related_value');
is(scalar(@props), 2, 'Got 2 properties involved for related_object.related_value on the child class');
is($props[0]->class_name, 'URT::Parent', 'First property meta\'s class_name is correct');
is($props[0]->property_name, 'related_object', 'First property meta\'s property_name is correct');
is($props[1]->class_name, 'URT::Related', 'second class_name for that property is correct');
is($props[1]->property_name, 'related_value', 'second property_name is correct');


@props = $child_meta->property_meta_for_name('non_existent');
is(scalar(@props), 0, 'No property found for name \'non_existent\'');
@props = $child_meta->property_meta_for_name('non_existent.also_non_existent');
is(scalar(@props), 0, 'No property found for name \'non_existent.also_non_existent\'');
@props = $child_meta->property_meta_for_name('related_object.also_non_existent');
is(scalar(@props), 0, 'No property found for name \'related_object.also_non_existent\'');




my @classes = $child_meta->parent_class_metas();
is(scalar(@classes), 1, 'Child class has 1 parent class');
@names = map { $_->class_name } @classes;
@expected = qw( URT::Parent );
is_deeply(\@names, \@expected, 'parent class names check out');

@names = sort $child_meta->ancestry_class_names;
is(scalar(@names), 2, 'Child class has 2 ancestry classes');
@expected = qw( UR::Object URT::Parent );
is_deeply(\@names, \@expected, 'Class names check out');

