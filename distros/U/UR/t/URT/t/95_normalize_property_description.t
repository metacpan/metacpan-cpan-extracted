#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use above 'UR';
use Test::More;

my @desc = (
    class_name => 'Foo',
    has_abstract_constant => [
        subject_class_name      => { is_abstract => 1, is_constant => 1 },
        perspective             => { is_abstract => 1, is_constant => 1 },
        toolkit                 => { is_abstract => 1, is_constant => 1 },
    ],
    has_optional => [
        parent_view => {
            is => 'UR::Object::View',
            id_by => 'parent_view_id',
            doc => 'when nested inside another view, this references that view',
        },
        subject => { 
            is => 'UR::Object',  
            id_class_by => 'subject_class_name', id_by => 'subject_id', 
            doc => 'the object being observed' 
        },
        aspects => { 
            is => 'UR::Object::View::Aspect', 
            reverse_as => 'parent_view',
            is_many => 1, 
            specify_by => 'name',
            order_by => 'number',
            doc => 'the aspects of the subject this view renders' 
        },
        default_aspects => {
            is => 'ARRAY',
            is_abstract => 1,
            is_constant => 1,
            is_many => 1, # technically this is one "ARRAY"
            default_value => undef,
            doc => 'a tree of default aspect descriptions' },
    ],
    has_optional_transient => [
        _widget  => { 
            doc => 'the object native to the specified toolkit which does the actual visualization' 
        },
        _observer_data => {
            is => 'HASH',
            is_transient => 1,
            value => undef, # hashref set at construction time
            doc => '  hooks around the subject which monitor it for changes'
        },
    ],
    has_many_optional => [
        aspect_names    => { via => 'aspects', to => 'name' },
    ]
);

my $class_name = "UR::Object::View";
my $new_desc = UR::Object::Type->_normalize_class_description(@desc);
ok($new_desc, 'normalized class object');
my $new_desc2 = UR::Object::Type->_normalize_class_description(%$new_desc);
ok($new_desc2, 'normalized class object again');
is_deeply($new_desc, $new_desc2, '2x normalization produces consistent answer') or diag Data::Dumper::Dumper($new_desc, $new_desc2);

# Test that an illegal property name throws an exception
foreach my $property_name ( ('has a space', 'HASH=(0x1234)', 'has.a.dot', '/path/name', '$var_name') ) {
    my $new_desc = eval { UR::Object::Type->_normalize_class_description(
                        class_name => 'Foo',
                        has => [
                            $property_name => { is => 'Number' },
                        ],
                    ) };
    my $escaped_property_name = quotemeta($property_name);
    like($@, qr/Invalid property name in class Foo: '$escaped_property_name' /, "Got exception for invalid property name '$property_name'");
    is($new_desc, undef, '_normalize_class_description() returns undef');
}

done_testing();
