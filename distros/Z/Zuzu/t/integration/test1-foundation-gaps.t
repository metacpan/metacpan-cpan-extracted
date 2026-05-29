use Test2::V0;

use JSON::PP qw( decode_json );
use File::Spec;
use Zuzu::Error;
use Zuzu::Parser;
use Zuzu::Runtime;
use Scalar::Util qw( blessed );

my $parser = Zuzu::Parser->new;

sub parse_ok {
	my ( $src, $file ) = @_;
	return $parser->parse( $src, $file );
}

sub eval_ok {
	my ( %args ) = @_;
	my $runtime = Zuzu::Runtime->new( %{ $args{runtime} // {} } );
	my $ast = parse_ok( $args{src}, $args{file} );
	$runtime->evaluate($ast);
	return $runtime;
}

sub slurp_utf8 {
	my ( $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or die "Cannot read $path: $!";
	local $/;
	my $text = <$fh>;
	close $fh;
	return $text;
}

my @parser_error_cases = (
	{
		name => 'dangling unary operator raises syntax compile error',
		src => "let bad := not;\n",
		file => 'parser-dangling-not.zzs',
		pattern => qr/Unexpected token in expression: OP ;/,
	},
	{
		name => 'unterminated function block reports compile syntax code',
		src => "function broken () {\n\treturn 1;\n",
		file => 'parser-unclosed-function.zzs',
		pattern => qr/Unterminated block/,
	},
);

for my $case ( @parser_error_cases ) {
	my $e = dies {
		parse_ok( $case->{src}, $case->{file} );
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Compile'), $case->{name} );
	is( $e->code, 'E_COMPILE_SYNTAX', 'parser edge case uses stable compile syntax code' );
	is( $e->file, $case->{file}, 'parser edge case preserves source filename' );
	like( $e->message, $case->{pattern}, 'parser edge case keeps specific failure message' );
}

{
	my $runtime = eval_ok(
		src => <<'SRC',
function call_non_callable () {
	let n := 9;
	n();
}
SRC
		file => 'runtime-non-callable.zzs',
	);

	my $e = dies {
		$runtime->call( 'call_non_callable' );
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Runtime'), 'non-callable invocation raises runtime exception' );
	is( $e->code, 'E_RUNTIME_GENERIC', 'runtime non-callable uses stable runtime code' );
	like( $e->message, qr/not a function/, 'runtime non-callable keeps actionable message' );
}

{
	my $runtime = eval_ok(
		src => <<'SRC',
function bad_union () {
	return 4 union 5;
}
SRC
		file => 'runtime-set-coercion.zzs',
	);

	my $e = dies {
		$runtime->call( 'bad_union' );
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Runtime'), 'set coercion edge case raises runtime exception' );
	like( $e->message, qr/Set operator expects Array, Dict, Set, or Bag/, 'set coercion failure keeps clear guidance' );
}

{
	my $runtime = Zuzu::Runtime->new(
		lib => [],
		builtin => {},
	);
	my $ast = parse_ok(
		"from nowhere/missing import nope;\n",
		'module-missing.zzs',
	);

	my $e = dies {
		$runtime->evaluate($ast);
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Compile'), 'missing module load raises compile error' );
	like( $e->message, qr/Cannot find module 'nowhere\/missing' in lib paths/, 'missing module error includes module name' );
}

{
	my $runtime = Zuzu::Runtime->new(
		builtin => {
			broken => 'Zuzu::Module::Does::Not::Exist',
		},
	);
	my $ast = parse_ok(
		"from broken import Foo;\n",
		'builtin-load-failure.zzs',
	);

	my $e = dies {
		$runtime->evaluate($ast);
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Compile'), 'broken builtin package raises compile error' );
	like( $e->message, qr/Failed loading builtin module 'broken'/, 'broken builtin reports package load failure' );
}

my $fixtures_file = File::Spec->catfile( 't', 'fixtures', 'semantics', 'language-core.json' );
my $fixtures = decode_json( slurp_utf8($fixtures_file) );

is( scalar @{$fixtures}, 4, 'deterministic language semantics fixture set contains expected high-value cases' );

for my $fixture ( sort { $a->{id} cmp $b->{id} } @{$fixtures} ) {
	my $runtime = eval_ok(
		src => $fixture->{source},
		file => $fixture->{file},
	);

	is(
		$runtime->call( '__fixture_result' ),
		$fixture->{expected},
		"fixture $fixture->{id} enforces deterministic semantics",
	);
}

done_testing;
