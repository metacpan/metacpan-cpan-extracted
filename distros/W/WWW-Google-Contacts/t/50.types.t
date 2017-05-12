#!perl

use strict;
use warnings;
use Data::Dumper;
use Try::Tiny;
use Test::More;

use WWW::Google::Contacts::Types qw(
  PhoneNumber ArrayRefOfPhoneNumber
  UserDefined ArrayRefOfUserDefined
);

# phone_number
my $phone_number;
my $num = "+123456";
$phone_number = to_PhoneNumber($num);
ok( defined $phone_number, "Valid phone number type" );
is( $phone_number->value,      $num,     "...right value" );
is( $phone_number->type->name, "mobile", "...got default type [mobile]" );

$phone_number = to_PhoneNumber( { type => "mobile", value => $num } );
ok( defined $phone_number, "Valid phone number type" );
is( $phone_number->value, $num, "...right value" );
is( $phone_number->type->name, "mobile",
    "...got explicitly set type [mobile]" );

my $res = to_ArrayRefOfPhoneNumber($num);
is( ref $res, "ARRAY", "Got an array of phone numbers" );
$phone_number = shift @{$res};
ok( defined $phone_number, "Valid phone number type" );
is( $phone_number->value,      $num,     "...right value" );
is( $phone_number->type->name, "mobile", "...got default type [mobile]" );

$res = to_ArrayRefOfPhoneNumber( [ 1, 2, 3 ] );
ok( defined $res, "Got array ref" );
is( scalar @{$res},   3,   "...with 3 entries" );
is( $res->[0]->value, "1", "Entry 1 is correct" );
is( $res->[1]->value, "2", "Entry 2 is correct" );
is( $res->[2]->value, "3", "Entry 3 is correct" );

# user defined
my $user_def;
my $def = { key => "Foo", value => "Bar" };
$user_def = to_UserDefined($def);
ok( defined $user_def, "Valid user defined type" );
is( $user_def->key,   $def->{key},   "...right key" );
is( $user_def->value, $def->{value}, "...right value" );

$def = [
    { key => "First",  value => "Something" },
    { key => "Second", value => "Good stuff" }
];
$res = to_ArrayRefOfUserDefined($def);
ok( defined $res, "Got array ref" );
is( scalar @{$res},   2,            "...with 2 entries" );
is( $res->[0]->value, "Something",  "Entry 1 is correct" );
is( $res->[1]->value, "Good stuff", "Entry 2 is correct" );

$def = {
    "First"  => { value => "Something" },
    "Second" => { value => "Good stuff" }
};
$res = to_ArrayRefOfUserDefined($def);
ok( defined $res, "Got array ref" );
is( scalar @{$res},           2, "...with 2 entries" );
is( defined $res->[0]->key,   1, "Entry 1 got key" );
is( defined $res->[0]->value, 1, "..and value" );
is( defined $res->[1]->key,   1, "Entry 2 got key" );
is( defined $res->[1]->value, 1, "..and value" );

done_testing;
