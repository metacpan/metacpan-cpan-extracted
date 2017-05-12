use strict;
use warnings;

use Test::More;
use UR::BoolExpr::Template::PropertyComparison::Like;

package Foo;

class Foo { 
    id_by => ['a'],
    has => [qw/a b c/],
}; 

package main;

for my $sc ('(', ')', '{', '}', '[', ']', '?', '.', '+', '|', '-') {
    my $value = "foo$sc";
    my $esc = quotemeta($sc);
    my $expected_escaped_value = qr|^foo$esc$|;
    my $escaped_value = UR::BoolExpr::Template::PropertyComparison::Like->comparison_value_and_escape_character_to_regex($value);
    is($escaped_value, $expected_escaped_value, "properly escaped $sc");
}
{
    my $value = "foo%";
    my $expected_escaped_value = qr|^foo.*$|;
    my $escaped_value = UR::BoolExpr::Template::PropertyComparison::Like->comparison_value_and_escape_character_to_regex($value);
    is($escaped_value, $expected_escaped_value, "properly changed '%' to wildcard");
}
{
    my $value = "foo_";
    my $expected_escaped_value = qr|^foo.$|;
    my $escaped_value = UR::BoolExpr::Template::PropertyComparison::Like->comparison_value_and_escape_character_to_regex($value);
    is($escaped_value, $expected_escaped_value, "properly changed '_' to wildcard");
}

my $create_object = Foo->create(a => '0', b => 'foo)bar');
is(ref $create_object, 'Foo', 'created a Foo');

my $get_object = Foo->get('b like' => 'foo)%');
is(ref $get_object, 'Foo', 'got object that was just created using like with special char');

done_testing();
