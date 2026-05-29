use utf8;
use Test2::V0;

use Zuzu::Env;
use Zuzu::Parser;
use Zuzu::Runtime;
use Zuzu::Weak qw(
	is_weakable_value
	make_weak_value
	resolve_weak_value
);
use Zuzu::Value::Array;
use Zuzu::Value::Bag;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;
use Zuzu::Value::Class;
use Zuzu::Value::Dict;
use Zuzu::Value::Function;
use Zuzu::Value::Object;
use Zuzu::Value::PairList;
use Zuzu::Value::Regexp;
use Zuzu::Value::Set;
use Zuzu::Value::Trait;

my @scalars = (
	[ null => undef ],
	[ boolean => Zuzu::Value::Boolean->new( value => 1 ) ],
	[ number => 42 ],
	[ string => 'hello' ],
	[ binary_string => Zuzu::Value::BinaryString->new( bytes => 'hello' ) ],
	[ regexp_value => Zuzu::Value::Regexp->new( pattern => 'x', flags => 'i' ) ],
);

for my $case ( @scalars ) {
	my ( $name, $value ) = @$case;
	ok !is_weakable_value($value), "$name is not weakable";
	is make_weak_value($value), $value, "$name passes through make_weak_value";
	is resolve_weak_value($value), $value,
		"$name passes through resolve_weak_value";
}

my $function = Zuzu::Value::Function->new(
	name => 'f',
	params => [],
	body => undef,
	closure_env => Zuzu::Env->new,
);
my $trait = Zuzu::Value::Trait->new(
	name => 'T',
	methods => {},
	closure_env => Zuzu::Env->new,
);
my $class = Zuzu::Value::Class->new(
	name => 'C',
	parent => undef,
	traits => [],
	field_specs => [],
	methods => {},
	trait_methods => {},
	static_methods => {},
	nested_classes => {},
	closure_env => Zuzu::Env->new,
);
my $object = Zuzu::Value::Object->new(
	class => $class,
	slots => {},
	const => {},
	types => {},
);

my @weakable = (
	[ array => Zuzu::Value::Array->new( items => [] ) ],
	[ bag => Zuzu::Value::Bag->new( items => [] ) ],
	[ set => Zuzu::Value::Set->new( items => [] ) ],
	[ dict => Zuzu::Value::Dict->new( map => {} ) ],
	[ pairlist => Zuzu::Value::PairList->new( list => [] ) ],
	[ function => $function ],
	[ class => $class ],
	[ trait => $trait ],
	[ object => $object ],
	[ host_array_ref => [] ],
	[ host_hash_ref => {} ],
	[ host_code_ref => sub { } ],
);

for my $case ( @weakable ) {
	my ( $name, $value ) = @$case;
	ok is_weakable_value($value), "$name is weakable";
	is make_weak_value($value), $value,
		"$name value-level weak helper passes through";
	is resolve_weak_value($value), $value, "$name resolves unchanged";
}

my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
my $task = eval {
	my $parser = Zuzu::Parser->new;
	my $ast = $parser->parse(
		'async function f () { return 1; } f();',
		'<weak-classification-task>',
	);
	$runtime->evaluate($ast);
};
ok is_weakable_value($task), 'Task value is weakable'
	if defined $task;

done_testing;
