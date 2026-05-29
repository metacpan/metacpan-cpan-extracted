use Test2::V0;

use Zuzu::Marshal::CBOR qw( tag text_string );
use Zuzu::Module::Marshal;
use Zuzu::Runtime;

use constant KIND_PAIR => 1;
use constant KIND_ARRAY => 2;
use constant KIND_DICT => 3;
use constant KIND_OBJECT => 7;
use constant KIND_FUNCTION => 8;
use constant KIND_CLASS => 9;

use constant CODE_FUNCTION => 1;
use constant CODE_CLASS => 2;

sub _envelope {
	my ( $root, $objects, $code ) = @_;

	return tag(
		55799,
		[
			text_string('ZUZU-MARSHAL'),
			1,
			{},
			$root,
			$objects // [],
			$code // [],
		],
	);
}

sub _load_dies_like {
	my ( $name, $root, $objects, $code, $pattern ) = @_;

	my $runtime = Zuzu::Runtime->new;
	like(
		dies {
			Zuzu::Module::Marshal::_decode_envelope(
				$runtime,
				_envelope( $root, $objects, $code ),
			);
		},
		$pattern,
		$name,
	);
}

sub _load_value {
	my ( $root, $objects, $code ) = @_;

	my $runtime = Zuzu::Runtime->new;
	return Zuzu::Module::Marshal::_decode_envelope(
		$runtime,
		_envelope( $root, $objects, $code ),
	);
}

sub _function_record {
	my ( %overrides ) = @_;

	return [
		$overrides{kind} // CODE_FUNCTION,
		$overrides{name} // text_string('marshal_validation_fn'),
		$overrides{source} // text_string('function () { return 1; }'),
		$overrides{captures} // [],
		$overrides{dependencies} // [],
	];
}

sub _class_record {
	my ( %overrides ) = @_;

	return [
		$overrides{kind} // CODE_CLASS,
		$overrides{name} // text_string('MarshalValidationBox'),
		$overrides{source} // text_string(
			'class MarshalValidationBox { let x; '
			. 'method label () { return "ok"; } }',
		),
		$overrides{captures} // [],
		$overrides{dependencies} // [],
	];
}

_load_dies_like(
	'load rejects non-integer object kinds',
	[ 0, 0 ],
	[ [ 1.5, [] ] ],
	[],
	qr/Object table entry 0 kind must be an integer/,
);

_load_dies_like(
	'load rejects unsupported object kinds',
	[ 0, 0 ],
	[ [ 99, [] ] ],
	[],
	qr/Unsupported object kind 99/,
);

_load_dies_like(
	'load rejects non-integer code kinds',
	undef,
	[],
	[ _function_record( kind => 1.5 ) ],
	qr/Code table entry 0 kind must be an integer/,
);

_load_dies_like(
	'load rejects unsupported code kinds',
	undef,
	[],
	[ _function_record( kind => 99 ) ],
	qr/Unsupported code kind 99/,
);

_load_dies_like(
	'load rejects bad object payload arity',
	[ 0, 0 ],
	[ [ KIND_PAIR, [ undef ] ] ],
	[],
	qr/Pair object payload 0 must be a two-item array/,
);

_load_dies_like(
	'load rejects wrong object payload types',
	[ 0, 0 ],
	[ [ KIND_ARRAY, text_string('not-array') ] ],
	[],
	qr/Array object payload 0 must be an array/,
);

_load_dies_like(
	'load rejects references outside the object table',
	[ 0, 1 ],
	[ [ KIND_ARRAY, [] ] ],
	[],
	qr/Reference id 1 is outside the object table/,
);

_load_dies_like(
	'load rejects duplicate object slot names',
	[ 0, 0 ],
	[
		[
			KIND_OBJECT,
			[
				[ 0, 1 ],
				[
					[ text_string('x'), 1 ],
					[ text_string('x'), 2 ],
				],
			],
		],
		[ KIND_CLASS, [0] ],
	],
	[ _class_record() ],
	qr/Object payload 0 contains duplicate slot 'x'/,
);

_load_dies_like(
	'load rejects duplicate Dict payload keys',
	[ 0, 0 ],
	[
		[
			KIND_DICT,
			[
				[ text_string('dup'), 1 ],
				[ text_string('dup'), 2 ],
			],
		],
	],
	[],
	qr/Dict object payload 0 contains duplicate key 'dup'/,
);

_load_dies_like(
	'load rejects non-array dependency records',
	undef,
	[],
	[ _class_record( dependencies => [ text_string('bad') ] ) ],
	qr/Code dependency in record 0 must be an array/,
);

_load_dies_like(
	'load rejects internal dependencies outside the code table',
	undef,
	[],
	[ _class_record( dependencies => [ [ 0, 1 ] ] ) ],
	qr/Internal dependency in record 0 has invalid code id/,
);

_load_dies_like(
	'load rejects malformed external dependency records',
	undef,
	[],
	[ _class_record( dependencies => [ [ 1, text_string('X') ] ] ) ],
	qr/External dependency in record 0 must have four fields/,
);

_load_dies_like(
	'load rejects malformed capture records',
	[ 0, 0 ],
	[ [ KIND_FUNCTION, [0] ] ],
	[
		_function_record(
			captures => [ [ text_string('cap'), 1, 2 ] ],
		),
	],
	qr/Capture in code record 0 must be a two-item array/,
);

_load_dies_like(
	'load rejects duplicate capture records',
	[ 0, 0 ],
	[ [ KIND_FUNCTION, [0] ] ],
	[
		_function_record(
			captures => [
				[ text_string('cap'), 1 ],
				[ text_string('cap'), 2 ],
			],
		),
	],
	qr/Duplicate capture 'cap' in code record 0/,
);

_load_dies_like(
	'load rejects bad-arity weak storage records',
	[ 1 ],
	[],
	[],
	qr/Envelope root array must be \[0, id\] or \[1, value\]/,
);

_load_dies_like(
	'load rejects nested weak storage records',
	[ 1, [ 1, undef ] ],
	[],
	[],
	qr/Envelope root nested weak storage records are invalid/,
);

_load_dies_like(
	'load rejects weak storage records in forbidden positions',
	[ 0, 0 ],
	[ [ KIND_FUNCTION, [ [ 1, undef ] ] ] ],
	[],
	qr/Function object payload 0 code id weak storage record is not allowed here/,
);

my $weak_array = _load_value(
	[ 0, 0 ],
	[ [ KIND_ARRAY, [ [ 1, undef ] ] ] ],
	[],
);
isa_ok( $weak_array, ['Zuzu::Value::Array'], 'load accepts valid weak records' );
is( $weak_array->items->[0], undef, 'weak null item loads as null' );
is( $weak_array->weak->[0], 1, 'weak item metadata is preserved' );

done_testing;
