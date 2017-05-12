#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use strict;
use warnings;

use Value::Object::Identifier;

my @valid_identifiers = (
    [ 'a',        'minimum single lowercase letter' ],
    [ 'z',        'maximum single lowercase letter' ],
    [ 'A',        'minimum single lowercase letter' ],
    [ 'Z',        'maximum single lowercase letter' ],
    [ '_',        'single underscore' ],
    [ 'abcdef',   'multiple lowercase letters' ],
    [ 'ABCDEF',   'multiple uppercase letters' ],
    [ 'aBCdeF',   'multiple mixed case letters' ],
    [ '_abcdef',  'leading underscore and letters' ],
    [ '_123',     'leading underscore and digits' ],
    [ 'a123',     'leading letter and digits' ],
);

my @invalid_identifiers = (
    [ undef,      'Missing identifier',      qr/No identifier/ ],
    [ '',         'Empty identifier',        qr/Empty identifier/ ],
    [ '1',        'Digit first',             qr/Invalid initial/ ],
    [ '1aa',      'Digit first and others',  qr/Invalid initial/ ],
    [ 'a-a',      'Invalid character',       qr/Invalid character/ ],
);

plan tests => (@valid_identifiers + @invalid_identifiers);

foreach my $t (@valid_identifiers)
{
    lives_and { isa_ok( Value::Object::Identifier->new( $t->[0] ), 'Value::Object::Identifier' ) }
        "is_valid: $t->[1]";
}

foreach my $t (@invalid_identifiers)
{
    throws_ok { Value::Object::Identifier->new( $t->[0] ) } $t->[2], "!is_valid: $t->[1]";
}

