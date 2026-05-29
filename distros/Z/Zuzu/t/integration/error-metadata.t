use Test2::V0;

use Zuzu::Error;
use Zuzu::Parser;
use Zuzu::Runtime;
use Scalar::Util qw( blessed );

my $parser = Zuzu::Parser->new;
my $runtime = Zuzu::Runtime->new;

{
	my $e = dies {
		$parser->parse( "let x := ;\n", 'error-metadata.zzs' );
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Compile'), 'syntax failures produce compile errors' );
	is( $e->code, 'E_COMPILE_SYNTAX', 'syntax failures expose stable compile code' );
	is( $e->file, 'error-metadata.zzs', 'compile errors include source file' );
	ok( $e->line >= 1, 'compile errors include source line metadata' );
	like( "$e", qr/CompileError\[E_COMPILE_SYNTAX\]/, 'string form includes kind + code' );
}

{
	my $ast = $parser->parse( "let y := 1;\ny();\n", 'runtime-error.zzs' );
	my $e = dies {
		$runtime->evaluate($ast);
	};

	ok( blessed($e) and $e->isa('Zuzu::Error::Runtime'), 'runtime failures produce runtime errors' );
	is( $e->code, 'E_RUNTIME_GENERIC', 'runtime failures expose default stable code' );
	is( $e->as_struct->{kind}, 'RuntimeError', 'as_struct includes kind' );
	ok( defined $e->as_struct->{line}, 'as_struct includes line metadata' );
}

{
	my $e = Zuzu::Error->new_compile(
		message => 'boom',
		file => 'demo.zzs',
		line => 4,
	);

	is( $e->code, 'E_COMPILE_GENERIC', 'new_compile applies default code' );
}

done_testing;
