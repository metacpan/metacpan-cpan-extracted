package Thrift::Parser::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Test::Exception;
use Thrift::Parser::TestCommon;

use Thrift::Parser;
use Thrift::IDL;

my ($idl, $parser);

sub create_idl : Test(startup) {

	$idl = Thrift::IDL->parse_thrift(<<"	ENDTHRIFT");
	namespace perl TPT

	typedef i32 number

	typedef list<number> numbers
	typedef map<number, string> number_to_string

	enum operation {
		Add, Subtract, Multiply, Divide
	}

	struct action {
		1: number num1,
		2: number num2,
		3: operation op,
		4: optional string comment
	}

	exception invalidArguments {
		1: string message,
		2: string argument
	}

	service Calculator {
		number compute (
			1: action action,
			2: string comment
		) throws (
			1: invalidArguments invalid
		)
	}
	ENDTHRIFT

	$parser = Thrift::Parser->new(
		idl     => $idl,
		service => 'Calculator',
	);
}	

sub class_resolution : Tests(4) {
	my $field_number_type = $idl->struct_named('action')->field_named('num1')->type;
	is $parser->idl_type_class($field_number_type), 'TPT::number', "idl_type_class() with custom type";
	isa_ok $parser->resolve_idl_type( $field_number_type ), 'Thrift::IDL::Type::Base', 'resolve_idl_type() isa';
	is $parser->resolve_idl_type( $field_number_type )->name, 'i32', 'resolve_idl_type() name';

	my $field_comment_type = $idl->struct_named('action')->field_named('comment')->type;
	is $parser->idl_type_class($field_comment_type), 'Thrift::Parser::Type::string';
}

sub built_classes : Tests(1) {
	my @built_classes = @{ $parser->built_classes };

	cmp_deeply \@built_classes, bag(
		superhashof({
			class => 'TPT::number',
			base  => 'Thrift::Parser::Type::i32',
		}),
		superhashof({
			class => 'TPT::numbers',
			base  => 'Thrift::Parser::Type::list',
		}),
		superhashof({
			class => 'TPT::number_to_string',
			base  => 'Thrift::Parser::Type::map',
		}),
		superhashof({
			class => 'TPT::operation',
			base  => 'Thrift::Parser::Type::Enum',
		}),
		superhashof({
			class => 'TPT::action',
			base  => 'Thrift::Parser::Type::Struct',
		}),
		superhashof({
			class => 'TPT::invalidArguments',
			base  => 'Thrift::Parser::Type::Exception',
		}),
		superhashof({
			class => 'TPT::Calculator::compute',
			base  => 'Thrift::Parser::Method',
			accessors => {
				return_class => 'TPT::number',
				throw_classes => {
					invalid => 'TPT::invalidArguments',
				},
			},
		}),
	), "Built classes as expected";
}

sub enum_type_idl : Tests(6) {
	# Enum->new_from_(id|name), ->value_name

	throws_ok { TPT::operation->new_from_id(4) } qr/No value found for enum index '4'/, "Invalid id";
	throws_ok { TPT::operation->new_from_name('Modulous') } qr/No value found for enum index 'Modulous'/, "Invalid name";
	
	is TPT::operation->new_from_id(3)->value_name, 'Divide', 'new_from_id() value_name';
	is TPT::operation->new_from_name('Add')->value, 0, 'new_from_name() value';

	is TPT::operation->compose('Subtract')->value, 1, 'compose() with name';
	is TPT::operation->compose('_2')->value_name, 'Multiply', 'compose() with number';
}

sub fieldset_idl : Tests(5) {
	# FieldSet->compose

	my %action = (
		num1 => 16,
		_2   => 18, # num2
		op   => 'Add',
	);

	throws_ok { Thrift::Parser::FieldSet->compose('TPT::number') } qr/Doesn't support field_id/, "Can't compose with non-struct/method type";
	throws_ok { Thrift::Parser::FieldSet->compose('TPT::action') } qr/Missing value for field/, "Missing valuee in compose";
	throws_ok { Thrift::Parser::FieldSet->compose('TPT::action', %action, num3 => 4) } qr/Failed to find referenced field/,
		"Compose with non-existant field name";

	my $fs = Thrift::Parser::FieldSet->compose('TPT::action', %action);
	isa_ok $fs, 'Thrift::Parser::FieldSet';

	is $fs->field_named('op')->value_name, 'Add', "Verify created field set";
}

sub container_idl : Tests(1) {
	is TPT::numbers->compose([ 1..5 ])->size, 5, "Compose auto-calls compose_with_idl";
}

sub read_protocol {
	# Test the read() method from each class
}

sub write_protocol {
	# Test the write() method from each class
}

1;
