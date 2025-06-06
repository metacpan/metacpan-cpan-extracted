use Kelp::Base -strict;
use Test::More;
use Whelk::Schema;

################################################################################
# This tests creation and referencing of schemas
################################################################################

subtest 'should return undef if passed undef to build_if_defined' => sub {
	my $schema = Whelk::Schema->build_if_defined(undef);

	is $schema, undef, 'schema ok';
};

subtest 'should create a simple schema and reference it back' => sub {
	my $schema = Whelk::Schema->build(
		some_schema => {
			type => 'null',
		}
	);

	isa_ok $schema, 'Whelk::Schema::Definition::Null';

	my $ref_schema = Whelk::Schema->build(\'some_schema');

	is $schema, $ref_schema, 'schema referencing ok';
};

subtest 'should create a slightly complicated schema with references inside' => sub {
	my $ref_schema = Whelk::Schema->build(
		to_reference => {
			type => 'integer',
		}
	);

	my $schema = Whelk::Schema->build(
		{
			type => 'object',
			properties => {
				int => \'to_reference',
				bool => {
					type => 'boolean'
				},
			}
		}
	);

	isa_ok $schema, 'Whelk::Schema::Definition::Object';
	isa_ok $schema->properties->{int}, 'Whelk::Schema::Definition::Integer';
	is $schema->properties->{int}, $ref_schema, 'integer referenced ok';
	isa_ok $schema->properties->{bool}, 'Whelk::Schema::Definition::Boolean';
};

subtest 'should extend a schema with config merging' => sub {
	my $to_extend = Whelk::Schema->build(
		to_extend => {
			type => 'object',
			properties => {
				a => {
					type => 'integer',
					required => !!0,
				},
			},
		}
	);

	my $extended = Whelk::Schema->build(
		[
			\'to_extend',
			properties => {
				a => {
					required => !!1,
				},
				b => {
					type => 'string',
				},
			},
		]
	);

	isnt $to_extend, $extended, 'schema looks extended ok';
	is $extended->properties->{a}->required, !!1, 'required ok';
	isa_ok $extended->properties->{b}, 'Whelk::Schema::Definition::String';
};

subtest 'should be able to create a new schema by extending' => sub {
	my $to_extend = Whelk::Schema->build(
		base => {
			type => 'object',
			properties => {
				a => {
					type => 'integer',
				},
			},
		}
	);

	my $extended = Whelk::Schema->build(
		extension => [
			\'base',
			properties => {
				b => {
					type => 'string',
				},
			},
		]
	);

	isnt $to_extend, $extended, 'schema looks extended ok';
	is $to_extend->name, 'base', 'base name ok';
	is $extended->name, 'extension', 'extension name ok';

	my $extended_again = Whelk::Schema->get_by_name('extension');
	is $extended_again->name, $extended->name, 'get_by_name ok';
};

subtest 'build_if_defined should handle building ref schemas' => sub {
	my $to_extend = Whelk::Schema->build(
		first => {
			type => 'integer',
		}
	);

	my $extended = Whelk::Schema->build_if_defined(\'first');

	is $to_extend->name, 'first', 'name ok';
	is $extended, $to_extend, 'ref ok';
};

subtest 'should be able to reuse partial schema defined in a hash' => sub {
	my %partial = (
		one => {
			type => 'array',
			items => {
				type => 'null',
			},
		},
		two => {
			type => 'object',
			properties => {
				three => {
					type => 'string',
					required => !!0,
				},
			},
		},
	);

	my $p1 = Whelk::Schema->build(
		partial1 => {
			type => 'object',
			properties => {
				%partial,
				add => {
					type => 'null',
				},
			},
		}
	);

	my $p2 = Whelk::Schema->build(
		partial2 => {
			type => 'object',
			properties => {
				%partial,
				add => {
					type => 'null',
				},
			},
		}
	);

	isa_ok $p1, 'Whelk::Schema::Definition::Object';
	isa_ok $p2, 'Whelk::Schema::Definition::Object';
	isnt $p1->properties, $p2->properties, 'not same schema ok';
	is_deeply $p1->properties, $p2->properties, 'schemas ok';

};

subtest 'should correctly extend a scalar schema' => sub {
	my $to_extend = Whelk::Schema->build(
		scalar_unextended => {
			type => 'string',
		}
	);

	my $to_extend_wrapped = Whelk::Schema->build(
		object_unextended => {
			type => 'object',
			properties => {
				p1 => \'scalar_unextended',
			},
		},
	);

	# this triggers the error, as it spawns a default value in the object
	ok !$to_extend->has_default, 'no default before extending ok';

	my $extended = Whelk::Schema->build(
		[
			\'scalar_unextended',
			example => 'test',
		]
	);

	ok !$extended->has_default, 'default value not cloned ok';

	my $extended_wrapped = Whelk::Schema->build(
		[
			\'object_unextended',
			properties => {
				p2 => {
					type => 'null',
				},
			},
		]
	);

	ok !$extended_wrapped->properties->{p1}->has_default, 'default wrapped value not cloned ok';
};

done_testing;

