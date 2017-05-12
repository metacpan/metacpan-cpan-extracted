package Thrift::Parser::Type::Container::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Exception;

use Thrift::Parser;

sub define_errors : Tests(5) {
	my $class = 'Thrift::Parser::Type::list';

	throws_ok { $class->define() } qr/requires type for 'val_type'/, "Pass no value to define";
	throws_ok { $class->define([]) } qr/invalid type/, "Invalid type";
	throws_ok { $class->define('::MadeUp') } 'Thrift::Parser::InvalidArgument', "Invalid class name";

	$class = 'Thrift::Parser::Type::map';

	throws_ok { $class->define(undef, '::string') } qr/requires type for 'key_type'/, "Pass no value for key of map";
	throws_ok { $class->define('::i32', '::string', '::i32') } qr/number of args/, "Too many args for map";
}

sub define_list : Tests(3) {
	my $class = 'Thrift::Parser::Type::list';
	my $obj = $class->define('::string');
	isa_ok $obj, $class;
	ok $obj->val_type, "Value type is set";

	$obj = $class->define('::map' => [ '::i32', '::string' ]);
	ok $obj, "Chained define for list of maps";
}

sub compose_list_error : Tests(5) {
	my $class = 'Thrift::Parser::Type::list';
	throws_ok { $class->compose() } qr/Must call define/, "Compose before define";
	throws_ok { $class->define('::string')->compose({ a => 'b' }) } qr/requires an ARRAYREF/, "List with a hashref";
	throws_ok { $class->define('::i16')->compose([ 'a', 'b' ]) } 'Thrift::Parser::InvalidTypedValue', "Values don't match type of list";

	my $obj = $class->define('::string')->compose([ "Hello", "Goodbye" ]);
	throws_ok { $class->define('::i16')->compose($obj) } qr/invalid typed object passed/, "String list != i16 list";

	$obj = $class->define('::map' => ['::i32' => '::string'])->compose([ { 1 => 'a' }, { 2 => 'b' } ]);
	throws_ok { $class->define('::map' => ['::i16' => '::string'])->compose($obj) } 'Thrift::Parser::InvalidArgument';
}

sub compose_list : Tests(6) {
	my $class = 'Thrift::Parser::Type::list';

	my $obj = $class->define('::string')->compose([ "Hello", "Goodbye", "Greetings" ]);
	isa_ok $obj, $class, "Simple compose of arrayref";

	my $new_obj = $obj->compose([ "One", "Two" ]);
	isa_ok $obj, $class, "Use one object to compose another with same signature";

	is $obj->size, 3, "First object has 3 items";
	is $new_obj->size, 2, "Second object has 2 items";

	$obj = $class->define('::map' => ['::i32' => '::string'])->compose([ { 1 => 'a' }, { 2 => 'b' } ]);
	isa_ok $obj, $class, "Compose list of maps";
	lives_ok { $class->define('::map' => ['::i32' => '::string'])->compose($obj) }, "Deep type checking";
}

sub more_list_tests : Tests(9) {
	my @staff_names = qw(John Mayes);
	my @other_names = qw(Kerron Michael Angelo);
	my $list = Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([ \@staff_names, \@other_names ]);
	isa_ok $list, 'Thrift::Parser::Type::list';
	is $list->size, 2, "list size";
	is $list->index(0)->size, int(@staff_names), "list index 0 size";
	is $list->index(1)->size, int(@other_names), "list index 1 size";

	throws_ok {
		Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([
			Thrift::Parser::Type::list->define('::i32')->compose([ 1, 2, 3 ]),
			Thrift::Parser::Type::list->define('::string')->compose(\@other_names),
		])
	} 'Thrift::Parser::InvalidArgument', "Failed list<list<string>> compose where parent list<>'s child isn't list<string>";

	$list = Thrift::Parser::Type::list->define('::list' => [ '::string' ])->compose([
		Thrift::Parser::Type::list->define('::string')->compose(\@staff_names),
		Thrift::Parser::Type::list->define('::string')->compose(\@other_names),
	]);
	isa_ok $list, 'Thrift::Parser::Type::list';
	is $list->size, 2, "list size";
	is $list->index(0)->size, int(@staff_names), "list index 0 size";
	is $list->index(1)->size, int(@other_names), "list index 1 size";
}

sub compose_map_errors : Tests(3) {
	my $class = 'Thrift::Parser::Type::map';
	throws_ok { $class->define('::i32', '::string')->compose(1 => "Hello") } qr/requires a HASHREF or ARRAYREF/, "Map without a ref";
	throws_ok { $class->define('::i32', '::string')->compose({ 'a' => "Hello" }) } 'Thrift::Parser::InvalidTypedValue', "Key type mismatch";
	throws_ok { $class->define('::i32', '::string')->compose([ 1 => 'Hello', 2 ]) } qr/odd number of pairs/, "Map requires balanced pairs";
}

sub list_methods : Tests(8) {
	my $list = Thrift::Parser::Type::list->define('::byte')->compose([ 1..5 ]);

	is $list->size, 5, "size()";
	is_deeply [ $list->values ], [ 1..5 ], "values()";
	isa_ok $list->index(0), 'Thrift::Parser::Type::byte', "Item in list is a byte";
	is_deeply $list->value_plain, [ 1..5 ], "value_plain()";

	is $list->each, 1, "Each";
	is $list->each, 2, "Each, call two";
	$list->each_reset();
	is $list->each, 1, "Each after a reset";

	is $list->index(6), undef, "Index past length of list";
}

sub map_methods : Tests(5) {
	my $map = Thrift::Parser::Type::map->define('::i32', '::string')->compose([ 1 => 'a', 2 => 'b' ]);
	
	is $map->size, 2, "size()";
	is_deeply [ $map->keys ], [ 1, 2 ], "keys()";
	is_deeply [ $map->values ], [ 'a', 'b' ], "values()";
	is_deeply $map->value_plain, { 1 => 'a', 2 => 'b' }, "value_plain()";
	is_deeply [ $map->index(0) ], [ 1 => 'a' ], "index()";
}

sub set_methods : Tests(4) {
	my $set = Thrift::Parser::Type::set->define('::string')->compose([qw(UT TX AZ NY HI)]);
	is $set->is_set('UT'), 1, "UT is in the set";
	is $set->is_set('CA'), 0, "CA is not in the set";

	$set = Thrift::Parser::Type::set->define('::i32')->compose([ 1..5 ]);
	is $set->is_set(4), 1, "4 is in the set";
	throws_ok { $set->is_set('UT') } 'Thrift::Parser::InvalidTypedValue', "Can't call is_set() with a string for a i32 set";
}

sub enum_errors : Test {
	my $class = 'Thrift::Parser::Type::Enum';
	throws_ok { $class->compose(undef) } 'Thrift::Parser::InvalidArgument', "Enum doesn't take undef";
	# Can't do further tests without IDL providing specification
}

# Won't test Struct here as it's a FieldSet

# Won't test Exception here as it's a Struct
1;
