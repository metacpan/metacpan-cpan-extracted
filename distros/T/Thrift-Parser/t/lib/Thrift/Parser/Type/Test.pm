package Thrift::Parser::Type::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Exception;
use Thrift::Parser::TestCommon;

use Thrift::Parser;

sub string_value : Tests(4) {
	my $obj = new_type_ok string => "Hello world";

	is $obj->value, "Hello world", "String value";
	is "$obj", "Hello world", "Stringified string";

	ok(Thrift::Parser::Type::string->values_equal("Abc", "Abc"), "String values_equal()");
}

sub binary : Tests(2) {
	my $obj = new_type_ok binary => "Something something";
	isa_ok $obj, 'Thrift::Parser::Type::string', "Binary types are just string internally for now";
}

sub bool : Tests(9) {
	my $obj = new_type_ok bool => 1;
	ok $obj->is_true, "is_true";
	ok ! $obj->is_false, "is_false";

	$obj = new_type bool => JSON::XS::true;
	ok $obj->is_true, "JSON::XS is_true";
	ok ! $obj->is_false, "JSON::XS is_false";

	$obj = new_type bool => JSON::XS::false;
	ok ! $obj->is_true, "JSON::XS is_true";
	ok $obj->is_false, "JSON::XS is_false";

	is "$obj", "false", "Stringified boolean";
	is $obj->value_plain, 0, "Boolean plain";
}

sub void : Tests(2) {
	my $obj = new_type_ok void => "something";
	is $obj->value_plain, undef, "Void is undef";
}

1;
