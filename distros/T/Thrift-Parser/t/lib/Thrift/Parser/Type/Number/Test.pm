package Thrift::Parser::Type::Number::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Exception;

use Thrift::Parser;

sub new_number ($;$) {
	my ($type, $value) = @_;
	my $class = "Thrift::Parser::Type::$type";
	return $class->compose($value);
}

sub number_valid : Tests(4) {
	my $obj = new_number i16 => 45;
	isa_ok $obj, 'Thrift::Parser::Type::Number';
	is $obj->value, 45;

	# Pass an object as a constructor
	my $new_obj = new_number i16 => $obj;
	is $obj->value, $new_obj->value, "Construct with another object of same class";

	# Test doubles
	lives_ok { new_number double => '0.5' }, "Double is a float";
}

sub number_invalid : Tests(8) {
	throws_ok { new_number i16 => 'e' } 'Thrift::Parser::InvalidTypedValue', "Must be a real number";
	throws_ok { new_number i16 => '2.5' } 'Thrift::Parser::InvalidTypedValue', "Non-double can't be double";

	throws_ok { new_number byte => (2 ** 7) + 1 } 'Thrift::Parser::InvalidTypedValue', "byte Exceed range";
	throws_ok { new_number byte => -1 * ((2 ** 7) + 1) } 'Thrift::Parser::InvalidTypedValue', "byte Exceed range, negative";
	throws_ok { new_number i16 => (2 ** 15) + 1 } 'Thrift::Parser::InvalidTypedValue', "i16 Exceed range";
	throws_ok { new_number i32 => (2 ** 31) + 1 } 'Thrift::Parser::InvalidTypedValue', "i32 Exceed range";
	throws_ok { new_number i64 => (2 ** 63) + 1 } 'Thrift::Parser::InvalidTypedValue', "i64 Exceed range";

	throws_ok { new_number double => (new_number i16 => 2) } 'Thrift::Parser::InvalidArgument',
		"Construct with object of different class fails";
}

sub value : Tests(3) {
	my $num = new_number i32 => '42';
	ok $num->value eq '42', "Value is string";
	ok $num->value_plain == 42, "Value plain is number";
	is "$num", 42, "Stringified value";
}

1;
