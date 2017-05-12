package Thrift::Parser::FieldSet::Test;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use Test::Exception;
use Thrift::Parser::TestCommon;

use Thrift::Parser;

my $class = 'Thrift::Parser::FieldSet';

sub field_new : Tests(4) {
	my $field = new_field
		id    => 42,
		name  => 'field_one',
		value => new_type string => "Hello world";

	isa_ok $field, 'Thrift::Parser::Field';
	is $field->id, 42, "id()";
	is $field->name, 'field_one', "name()";
	isa_ok $field->value, 'Thrift::Parser::Type::string', "value()";
}

sub fieldset_basic : Tests(9) {
	my $set = $class->new({ fields => [
		new_field(
			id    => 1,
			name  => 'last_name',
			value => new_type string => 'Waters'
		),
		new_field(
			id    => 0,
			name  => 'first_name',
			value => new_type string => 'Eric'
		),
	] });
	isa_ok $set, $class, "Created field set";

	isa_ok $set->named('first_name'), 'Thrift::Parser::Type::string', 'named()';
	is $set->named('nonexistant'), undef, "named() not found";

	isa_ok $set->id(1), 'Thrift::Parser::Type::string', 'id()';
	is $set->id(2), undef, 'id() not found';

	is_deeply $set->ids, [ 0, 1 ], "ids()";

	cmp_deeply $set->field_values, [
		isa('Thrift::Parser::Type::string'),
		isa('Thrift::Parser::Type::string'),
	], 'field_values()';

	cmp_deeply $set->keyed_field_values, {
		first_name => isa('Thrift::Parser::Type::string'),
		last_name  => isa('Thrift::Parser::Type::string'),
	}, 'keyed_field_values()';

	cmp_deeply $set->keyed_field_values_plain, {
		first_name => 'Eric',
		last_name  => 'Waters',
	}, 'keyed_field_values()';
}

1;
