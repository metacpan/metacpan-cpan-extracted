package Thrift::IDL::Document::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Test::Exception;

use Thrift::Parser;
use Thrift::IDL;

my $idl;

sub create_idl : Test(startup => 1) {
	$idl = Thrift::IDL->parse_thrift(<<"	ENDTHRIFT");
	namespace perl TPT

	// I am a single line comment

	/* Hey there, multiline! */

	# Perl?  What what?

	/*
		I am a much longer comment block.
		There are two lines here.
	*/

	const i32 MEANINGOFLIFE = 42

	typedef i32 number

	enum operation {
		Add, Subtract, Multiply, Divide
	}

	struct action {
		// comment before num1
		1: number num1,

		2: number num2, # comment on num2

		/* comment on op */
		// another on op
		3: optional operation op
	}

	struct type_tests {
		1: number num,
		2: i32    int,
		3: list<i32> list,
		4: set<string> set,
		5: map<i32, string> map
	}

	exception invalidArguments {
		1: string message,
		2: string argument
	}

	service Calculator extends Something {
		number compute (
			1: action action,
			2: string comment
		) throws (
			1: invalidArguments invalid
		)
	}
	ENDTHRIFT

	isa_ok $idl, 'Thrift::IDL::Document';
}	

sub base_methods : Tests(4) {
	my $services = $idl->children_of_type('Thrift::IDL::Service');
	is int(@$services), 1, "children_of_type() count";
	isa_ok $services->[0], 'Thrift::IDL::Service', 'children_of_type() type';

	my $service = $idl->array_search('Calculator', 'services', 'name');
	ok $service, "array_search() returned result";
	is $service->name, 'Calculator', "array_search() found matching result";
}

sub comments : Tests(10) {
	my $comments = $idl->comments;
	is int(@$comments), 4, "Found four comments";

	is $comments->[0]->value, "// I am a single line comment", "value()";

	is $comments->[0]->style, 'c_single', "Single";
	is $comments->[0]->escaped_value, 'I am a single line comment', "Single value";

	is $comments->[1]->style, 'c_multiline', "Multiline";
	is $comments->[1]->escaped_value, 'Hey there, multiline!', "Multiline value";

	is $comments->[2]->style, 'perl_single', "Perl";
	is $comments->[2]->escaped_value, 'Perl?  What what?', "Perl value";

	is $comments->[3]->style, 'c_multiline', "Multiline";
	is $comments->[3]->escaped_value, "I am a much longer comment block.\n\t\tThere are two lines here.", "True multiline test";
}

sub definition : Tests(2) {
	my $service = $idl->service_named('Calculator');
	# There is no basename since the thrift IDL was from a buffer
	is $service->full_name, '.Calculator', 'full_name()';
	is $service->local_name, 'Calculator', 'local_name()';
}

sub constant : Tests(4) {
	my $constants = $idl->children_of_type('Thrift::IDL::Constant');
	is int(@$constants), 1, "Found one constant";
	
	is $constants->[0]->type, 'i32', "type()";
	is $constants->[0]->name, 'MEANINGOFLIFE', 'name()';
	is $constants->[0]->value, 42, 'value()';
}

sub header : Tests(2) {
	my $headers = $idl->headers();
	is int(@$headers), 1, "Found a header";
	is $headers->[0]->namespace('perl'), 'TPT', "namespace()";
}

sub enum : Tests(8) {
	my $enums = $idl->enums();
	is int(@$enums), 1, "Found one enum";
	my $enum = $enums->[0];

	is $enum->name, 'operation', "name()";
	cmp_deeply $enum->values, [
		[ 'Add', undef ],
		[ 'Subtract', undef ],
		[ 'Multiply', undef ],
		[ 'Divide', undef ],
	], "values()";

	# Call in void context
	$enum->numbered_values;

	cmp_deeply $enum->values, [
		[ 'Add', 0 ],
		[ 'Subtract', 1 ],
		[ 'Multiply', 2 ],
		[ 'Divide', 3 ],
	], "values() after a numbered_values() call adds numbers";

	is $enum->value_named('Add'), 0, "value_named()";
	is $enum->value_named('MadeUp'), undef, "value_named() with non-existant name";
	is $enum->value_id_name(2), 'Multiply', 'value_id_name()';
	is $enum->value_id_name(4), undef, 'value_id_name() with non-existant id';
}

sub struct_and_fields : Tests(9) {
	my $struct = $idl->struct_named('action');

	is $struct->name, 'action', 'name()';

	my @fields = @{ $struct->fields };
	is int(@fields), 3, "Found 3 fields";

	is $fields[0]->id, 1, 'id()';
	is $fields[0]->name, 'num1', 'name()';
	is $fields[0]->type, 'number', 'type()';
	is "$fields[0]", 'num1 (id: 1, type: "number")', 'to_str()';

	# This should be a no-op, as it's already setup, but we need to ensure that
	# we can call it twice and not have it break
	$struct->setup();

	is int(@{ $fields[0]->{comments} }), 1, "Comment on field 1";
	is int(@{ $fields[1]->{comments} }), 1, "Comment on field 2";
	is int(@{ $fields[2]->{comments} }), 2, "Comments on field 3";
}

sub service_and_method : Tests(6) {
	my $service = $idl->service_named('Calculator');
	is $service->name, 'Calculator', 'service name()';
	is $service->extends, 'Something', 'service extends()';

	my $method = $service->method_named('compute');
	is $method->name, 'compute', 'method name()';

	my @arguments = @{ $method->arguments };
	is int(@arguments), 2, 'method arguments()';

	isa_ok $method->argument_named('action'), 'Thrift::IDL::Field', 'argument_named()';
	isa_ok $method->argument_id(2), 'Thrift::IDL::Field', 'argument_id()';
}

sub typedefs : Tests(3) {
	my $typedef = $idl->typedef_named('number');
	is $typedef->name, 'number', 'name()';
	is $typedef->type, 'i32', 'type()';
	is "$typedef", 'typedef "number" isa i32', 'to_str()';
}

sub types : Tests(17) {
	my $struct = $idl->struct_named('type_tests');
	my %types  = map { $_->name => $_->type } @{ $struct->fields };

	isa_ok $types{num}, 'Thrift::IDL::Type::Custom';
	is $types{num}->name, 'number', 'custom name()';

	isa_ok $types{int}, 'Thrift::IDL::Type::Base';
	is $types{int}->name, 'i32', 'base name()';

	isa_ok $types{list}, 'Thrift::IDL::Type::List';
	is $types{list}->name, 'list', 'list name()';
	isa_ok $types{list}->val_type, 'Thrift::IDL::Type::Base', 'list val_type()';
	is "$types{list}", "list (i32)", 'list to_str()';

	isa_ok $types{set}, 'Thrift::IDL::Type::Set';
	is $types{set}->name, 'set', 'set name()';
	isa_ok $types{set}->val_type, 'Thrift::IDL::Type::Base', 'set val_type()';
	is "$types{set}", "set (string)", 'set to_str()';

	isa_ok $types{map}, 'Thrift::IDL::Type::Map';
	is $types{map}->name, 'map', 'map name()';
	isa_ok $types{map}->key_type, 'Thrift::IDL::Type::Base', 'map key_type()';
	isa_ok $types{map}->val_type, 'Thrift::IDL::Type::Base', 'map val_type()';
	is "$types{map}", "map (i32 => string)", 'map to_str()';
}

1;
