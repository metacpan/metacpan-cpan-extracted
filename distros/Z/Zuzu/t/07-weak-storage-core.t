use utf8;
use Test2::V0;

use Scalar::Util qw( isweak );

use Zuzu::Env;
use Zuzu::Value::Array;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;
use Zuzu::Value::Class;
use Zuzu::Value::Object;
use Zuzu::Weak qw(
	slot_value
	store_value
);

sub object_value {
	my $class = Zuzu::Value::Class->new(
		name => 'Thing',
		parent => undef,
		traits => [],
		field_specs => [],
		methods => {},
		trait_methods => {},
		static_methods => {},
		nested_classes => {},
		closure_env => Zuzu::Env->new,
	);

	return Zuzu::Value::Object->new(
		class => $class,
		slots => {},
		const => {},
		types => {},
	);
}

{
	my $slot;
	store_value( \$slot, 42, 1 );
	is( slot_value(\$slot), 42, 'number stores normally with weak intent' );
	ok( !isweak($slot), 'number slot is not weakened' );

	my $bool = Zuzu::Value::Boolean->new( value => 1 );
	store_value( \$slot, $bool, 1 );
	is( slot_value(\$slot), $bool, 'Boolean object stores normally' );
	ok( !isweak($slot), 'Boolean object is not weakened' );

	my $binary = Zuzu::Value::BinaryString->new( bytes => 'abc' );
	store_value( \$slot, $binary, 1 );
	is( slot_value(\$slot), $binary, 'BinaryString object stores normally' );
	ok( !isweak($slot), 'BinaryString object is not weakened' );
}

{
	my $slot;
	my $object = object_value();
	store_value( \$slot, $object, 1 );
	is( slot_value(\$slot), $object, 'object stores into weak slot' );
	ok( isweak($slot), 'object slot is weakened' );

	undef $object;
	is( slot_value(\$slot), undef, 'dead weak object reads as undef' );
}

{
	my $slot;
	{
		my $array = Zuzu::Value::Array->new( items => [] );
		store_value( \$slot, $array, 1 );
		ok( isweak($slot), 'array slot is weakened' );
	}
	is( slot_value(\$slot), undef, 'dead weak array reads as undef' );

	store_value( \$slot, 'scalar', 1 );
	is( slot_value(\$slot), 'scalar', 'dead weak slot can be replaced by scalar' );
	ok( !isweak($slot), 'replacement scalar is not weak' );

	my $object = object_value();
	store_value( \$slot, $object, 1 );
	is( slot_value(\$slot), $object,
		'scalar slot can be replaced by weak object' );
	ok( isweak($slot), 'replacement object is weakened' );
}

{
	my $slot;
	my $object = object_value();
	store_value( \$slot, $object, 0 );
	is( slot_value(\$slot), $object,
		'object stores strongly without weak intent' );
	ok( !isweak($slot), 'strong object slot is not weakened' );

	undef $object;
	ok( defined slot_value(\$slot), 'strong object remains alive through slot' );
}

{
	my $env = Zuzu::Env->new;
	my $ref = $env->declare( parent => undef, 0, 'Any', 1 );
	is( $env->is_weak_here('parent'), 1, 'declare records weak metadata' );
	is( $env->is_weak_slot('parent'), 1,
		'weak metadata is visible through lookup' );

	my $object = object_value();
	store_value( $ref, $object, $env->is_weak_slot('parent') );
	ok( isweak($$ref), 'env weak metadata can drive weak storage' );

	my $child = Zuzu::Env->new( parent => $env );
	is( $child->is_weak_slot('parent'), 1,
		'weak metadata inherits through env chain' );
	$child->set_weak_slot( parent => 0 );
	is( $env->is_weak_slot('parent'), 0, 'set_weak_slot updates defining env' );
}

{
	my $env = Zuzu::Env->new;
	my $slot;
	my $ref = $env->alias_to_ref( field => \$slot, 0, 'Any', 1 );
	is( $ref, \$slot, 'alias_to_ref returns the aliased ref' );
	is( $env->is_weak_here('field'), 1, 'alias_to_ref records weak metadata' );
}

{
	my $object = object_value();
	$object->weak->{parent} = 1;
	is( $object->weak->{parent}, 1, 'object stores per-slot weak metadata' );

	my $parent = object_value();
	store_value( \$object->slots->{parent}, $parent, $object->weak->{parent} );
	ok( isweak( $object->slots->{parent} ),
		'object weak metadata can drive weak storage' );

	undef $parent;
	is( $object->slots->{parent}, undef, 'dead weak object slot reads as undef' );
}

done_testing;
