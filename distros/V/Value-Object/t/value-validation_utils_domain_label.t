#!/usr/bin/env perl

use Test::More;

use strict;
use warnings;

use Value::Object::ValidationUtils;

my @valid_labels = (
    [ 'a',  'single character label' ],
    [ 'A',  'Single upper character label' ],
    [ '1',  'single digit label' ],
    [ 'a-b', 'label containing a hyphen' ],
    [ 'a--b', 'label containing consecutive hyphens' ],
    [ 'a2b', 'label containing a digit' ],
    [ '2a',  'label starting with a digit' ],
    [ 'a2',  'label ending in a digit' ],
    [ '21',  'label consisting of just digits' ],
    [ 'abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
        'Longest legal label' ],
);

my @invalid_labels = (
    [ undef,     'undefined', qr/No domain/ ],
    [ '',        'empty string', qr/Label is not .* length/ ],
    [ '-',       'label is just hyphen', qr/Label is not the correct form/ ],
    [ '-aa',     'label starts with a hyphen', qr/Label is not the correct form/ ],
    [ 'aa-',     'label ends with a hyphen', qr/Label is not the correct form/ ],
    [ 'abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJKLMNOPQRSTUVWXYZ-0123456789',
        'label > 63 octets',  qr/Label is not .* length/ ],
);

plan tests => 2*(@valid_labels+@invalid_labels);

foreach my $t (@valid_labels)
{
    ok( Value::Object::ValidationUtils::is_valid_domain_label( $t->[0] ),
        "is_valid: $t->[1]"
    );
    my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_domain_label( $t->[0] );
    ok( !defined $why, "$t->[1]: invalidation reason" );
}

foreach my $t (@invalid_labels)
{
    ok( !Value::Object::ValidationUtils::is_valid_domain_label( $t->[0] ),
        "!is_valid: $t->[1]"
    );
    my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_domain_label( $t->[0] );
    like( $why, $t->[2], "$t->[1]: invalid for the right reason" );
}
