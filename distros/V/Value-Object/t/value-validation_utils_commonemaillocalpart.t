#!perl

use Test::More;

use strict;
use warnings;

use Value::Object::ValidationUtils;

my @chars = (qw(a z A Z 0 9 !), '#', qw($ % & ' * + - / = ? ^ _ ` { | } ~));
my @valid_localpart = (
    ( map { [ $_, "Single character '$_' local part" ] } @chars),
    ( map { [ "ab${_}cd", qq(multicharacter local part with "$_") ] } @chars),
    ( map { [ "ab${_}cd.ef${_}gh", qq(two part local part with "$_") ] } @chars),
    [ 'abcdefghijklmnopqrstuvwxyz.ABCDEFGHIJKLMNOPQRSTUVWXYZ.0123456789', 'max 64 octet local part' ],
);

my @invalid_localpart = (
    [ undef,     'undefined', qr/No email .*supplied/ ],
    [ '',        'empty string', qr/not in the length range/ ],
    [ '.',       'no labels, just dot', qr/not correct form/ ],
    [ '.foo',    'dot at beginning', qr/not correct form/ ],
    [ 'a..foo',  'two dots in a row', qr/not correct form/ ],
    [ 'foo.',    'dot at end', qr/not correct form/ ],
    [ 'ab"cd',   'contains a double quote', qr/not correct form/ ],
    [ 'ab@cd',   'contains an "@" character', qr/not correct form/ ],
    [ 'ab(cd',   'contains an "(" character', qr/not correct form/ ],
    [ 'ab)cd',   'contains an ")" character', qr/not correct form/ ],
    [ 'ab\\cd',  'contains an "\\" character', qr/not correct form/ ],
    [ 'ab[cd',   'contains an "[" character', qr/not correct form/ ],
    [ 'ab]cd',   'contains an "]" character', qr/not correct form/ ],
    [ 'ab:cd',   'contains an ":" character', qr/not correct form/ ],
    [ 'ab;cd',   'contains an ";" character', qr/not correct form/ ],
    [ 'ab,cd',   'contains an "," character', qr/not correct form/ ],
    [ 'ab<cd',   'contains an "<" character', qr/not correct form/ ],
    [ 'ab>cd',   'contains an ">" character', qr/not correct form/ ],
    [ '!abcdefghijklmnopqrstuvwxyz.ABCDEFGHIJKLMNOPQRSTUVWXYZ.0123456789', 'over 64 octet local part', qr/not in the length range/ ],
    [ '"ab@cd"',   'quoted', qr/not correct form/ ],
);

plan tests => 2*(@valid_localpart+@invalid_localpart);

foreach my $t (@valid_localpart)
{
    ok( Value::Object::ValidationUtils::is_valid_common_email_local_part( $t->[0] ),
        "is_valid: $t->[1]: [$t->[0]]"
    );
    my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_common_email_local_part( $t->[0] );
    ok( !defined $why, "$t->[1]: invalidation reason" );
}

foreach my $t (@invalid_localpart)
{
    ok( !Value::Object::ValidationUtils::is_valid_common_email_local_part( $t->[0] ),
        "!is_valid: $t->[1]"
    );
    my ($why, $long, $data) = Value::Object::ValidationUtils::why_invalid_common_email_local_part( $t->[0] );
    like( $why, $t->[2], "$t->[1]: invalid for the right reason" );
}
