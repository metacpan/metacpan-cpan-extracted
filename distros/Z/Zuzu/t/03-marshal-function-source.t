use Test2::V0;

use Zuzu::Module::Marshal;
use Zuzu::Runtime;
use Zuzu::Value::Function;

my $runtime = Zuzu::Runtime->new;

my $declared = $runtime->eval_with_current_scope(
	q{function add_one (Number x) -> Number { return x + 1; }},
	'<marshal-source-test>',
);
ok $declared->source_node, 'function declaration retains source node';

my $declared_source = Zuzu::Module::Marshal::_function_expression_source(
	$runtime,
	$declared,
);
is(
	$declared_source,
	'function (Number x) -> Number { return x + 1; }',
	'function declaration emits canonical expression source',
);

my $roundtrip = $runtime->eval_with_current_scope(
	'let f := ' . $declared_source . '; f(41);',
	'<marshal-source-roundtrip>',
);
is $roundtrip, 42, 'emitted function source is parseable and executable';

my $anonymous = $runtime->eval_with_current_scope(
	q{let greet := function (name) { return "Hello, " _ name; }; greet;},
	'<marshal-source-test>',
);
ok $anonymous->source_node, 'function expression retains source node';

my $anonymous_source = Zuzu::Module::Marshal::_function_expression_source(
	$runtime,
	$anonymous,
);
is(
	$anonymous_source,
	'function (name) { return "Hello, " _ name; }',
	'function expression emits canonical expression source',
);

my $no_capture_runtime = Zuzu::Runtime->new;
my $no_capture_fn = $no_capture_runtime->eval_with_current_scope(
	q{function identity (x) { return x; }},
	'<marshal-capture-test>',
);
my $no_capture_analysis = Zuzu::Module::Marshal::_analyse_function_value(
	$no_capture_runtime,
	$no_capture_fn,
);
is $no_capture_analysis->{captures}, [], 'no-capture function has no captures';
is(
	$no_capture_analysis->{internal_dependencies},
	[],
	'no-capture function has no internal dependencies',
);

my $scalar_capture_runtime = Zuzu::Runtime->new;
my $scalar_capture_fn = $scalar_capture_runtime->eval_with_current_scope(
	q{const bonus := 10; let f := function (x) { return x + bonus; }; f;},
	'<marshal-capture-test>',
);
my $scalar_capture_analysis = Zuzu::Module::Marshal::_analyse_function_value(
	$scalar_capture_runtime,
	$scalar_capture_fn,
);
is(
	[ map { $_->{name} } @{ $scalar_capture_analysis->{captures} } ],
	[ 'bonus' ],
	'scalar const capture is accepted',
);
is $scalar_capture_analysis->{captures}[0]{value}, 10, 'captured value is kept';

my $mutable_capture_runtime = Zuzu::Runtime->new;
my $mutable_capture_fn = $mutable_capture_runtime->eval_with_current_scope(
	q{let bonus := 10; let f := function (x) { return x + bonus; }; f;},
	'<marshal-capture-test>',
);
like(
	dies {
		Zuzu::Module::Marshal::_analyse_function_value(
			$mutable_capture_runtime,
			$mutable_capture_fn,
		);
	},
	qr/not const/,
	'mutable capture is rejected',
);

my $non_scalar_runtime = Zuzu::Runtime->new;
my $non_scalar_fn = $non_scalar_runtime->eval_with_current_scope(
	q{const values := [ 1 ]; let f := function () { return values[0]; }; f;},
	'<marshal-capture-test>',
);
like(
	dies {
		Zuzu::Module::Marshal::_analyse_function_value(
			$non_scalar_runtime,
			$non_scalar_fn,
		);
	},
	qr/not a scalar value/,
	'non-scalar const capture is rejected',
);

my $dependency_runtime = Zuzu::Runtime->new;
my $dependency_fn = $dependency_runtime->eval_with_current_scope(
	q{
		function increment (x) { return x + 1; }
		let f := function (x) { return increment(x); };
		f;
	},
	'<marshal-capture-test>',
);
my $dependency_analysis = Zuzu::Module::Marshal::_analyse_function_value(
	$dependency_runtime,
	$dependency_fn,
);
is(
	$dependency_analysis->{captures},
	[],
	'function dependency is not treated as a capture',
);
is(
	[ map { $_->{name} } @{ $dependency_analysis->{internal_dependencies} } ],
	[ 'increment' ],
	'const function dependency is accepted as an internal dependency',
);

my $external_runtime = Zuzu::Runtime->new;
my $external_fn = $external_runtime->eval_with_current_scope(
	q{
		from std/time import Time;
		let f := function (epoch) { return new Time(epoch); };
		f;
	},
	'<marshal-capture-test>',
);
my $external_analysis = Zuzu::Module::Marshal::_analyse_function_value(
	$external_runtime,
	$external_fn,
);
is(
	$external_analysis->{external_dependencies},
	[
		{
			local_name => 'Time',
			module => 'std/time',
			export_name => 'Time',
		},
	],
	'external stdlib dependency is accepted',
);

done_testing;
