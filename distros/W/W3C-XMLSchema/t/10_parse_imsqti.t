#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 54;

BEGIN {
    use_ok( 'W3C::XMLSchema' );
}

my $qti = W3C::XMLSchema->new( file => 't/data/imsqti_v2p1.xsd' );
isa_ok($qti, 'W3C::XMLSchema');

can_ok($qti, 'target_namespace');
is($qti->target_namespace, 'http://www.imsglobal.org/xsd/imsqti_v2p1');

# Class: a
can_ok($qti, 'attribute_groups');
my $attr_groups = $qti->attribute_groups;
is( scalar @{ $attr_groups }, 188, 'attribute_groups count mismatch');

my $attr_group0 = $qti->attribute_groups->[0];
isa_ok($attr_group0, 'W3C::XMLSchema::AttributeGroup');
can_ok($attr_group0, 'name');
is($attr_group0->name, 'a.AttrGroup', "First attribute_group name mismatch");
is($attr_group0->ref, '', 'First attribute_group ref should be empty');

can_ok($attr_group0, 'attribute_groups');
my $attr_group0_children = $attr_group0->attribute_groups;
is( scalar @{ $attr_group0_children }, 1, 'First attribute_group group children count mismatch');
isa_ok($attr_group0_children->[0], 'W3C::XMLSchema::AttributeGroup');
is($attr_group0_children->[0]->ref, 'simpleInline.AttrGroup', "First attribute_group child group ref mismatch");

can_ok($attr_group0,'attributes');
my $attributes0 = $attr_group0->attributes;
is( scalar @{ $attributes0 }, 2, 'First attribute_group attribute count mismatch');
my $attribute0_0 = $attributes0->[0];
isa_ok($attribute0_0, 'W3C::XMLSchema::Attribute');
is($attribute0_0->name, 'href', 'Attribute0_0 name mismatch');
is($attribute0_0->type, 'uri.Type', 'Attribute0_0 type mismatch');
is($attribute0_0->use, 'required', 'Attribute0_0 use mismatch');

my $attr_group1 = $qti->attribute_groups->[1];
can_ok($attr_group1, 'name');
is($attr_group1->name, 'abbr.AttrGroup', "Second attribute_group name mismatch");

my $attr_group12 = $qti->attribute_groups->[12];
isa_ok($attr_group12, 'W3C::XMLSchema::AttributeGroup');
my $attr_group12_children = $attr_group12->attribute_groups;
is( scalar @{ $attr_group12_children }, 2, '13th attribute_group group children count mismatch');

can_ok($qti, 'groups');
my $groups = $qti->groups;
is( scalar @{ $groups }, 221, 'groups count mismatch');
my $group0 = $groups->[0];
isa_ok($group0, 'W3C::XMLSchema::Group');
is($group0->name, 'a.ContentGroup', 'First group name mismatch');

can_ok($group0, 'sequence');
my $group0_seq = $group0->sequence;
isa_ok($group0_seq, 'W3C::XMLSchema::Sequence');
can_ok($group0_seq, 'items');
my $group0_seq_groups = $group0_seq->items;
is( scalar @{ $group0_seq_groups }, 1, 'First group sequence items count mismatch');
isa_ok( $group0_seq_groups->[0], 'W3C::XMLSchema::Group');
is( $group0_seq_groups->[0]->ref, 'simpleInline.ContentGroup', 'First group sequence item 0 ref mismatch');

my $group6 = $qti->groups->[6];
isa_ok( $group6, 'W3C::XMLSchema::Group' );
is( $group6->name, 'areaMapping.ContentGroup', '6th group name mismatch');
my $group6_seq_items = $group6->sequence->items;
isa_ok( $group6_seq_items->[0], 'W3C::XMLSchema::Element');
is( $group6_seq_items->[0]->ref, 'areaMapEntry', '6th group item 0 ref mismatch');

can_ok($qti, 'complex_types');
my $complex_type0 = $qti->complex_types->[0];
isa_ok( $complex_type0, 'W3C::XMLSchema::ComplexType' );
can_ok( $complex_type0, 'name');
is( $complex_type0->name, 'a.Type', '1st complex type name mismatch');
can_ok( $complex_type0, 'mixed');
is( $complex_type0->mixed, 'true', '1st complex type mixed mismatch');
can_ok( $complex_type0, 'items');
isa_ok( $complex_type0->items->[0], 'W3C::XMLSchema::Group');
is( $complex_type0->items->[0]->ref, 'a.ContentGroup', '1st complex type item 0 ref mismatch');

can_ok( $qti, 'elements' );
is( scalar @{ $qti->elements }, 254, 'elements count mismatch' );
my $element0 = $qti->elements->[0];
isa_ok( $element0, 'W3C::XMLSchema::Element' );
can_ok( $element0, 'name');
can_ok( $element0, 'type');
is( $element0->name, 'a', '1st element name mismatch' );
is( $element0->type, 'a.Type', '1st element type mismatch' );

# Class: abbr

1;
