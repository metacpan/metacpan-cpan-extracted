use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );

use Zuzu::Web::PSGI;

sub write_script {
	my ( $dir, $name, $source ) = @_;

	my $path = File::Spec->catfile( $dir, $name );
	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not create $path: $!";
	print {$fh} $source;
	close $fh;

	return $path;
}

my $tmpdir = tempdir( CLEANUP => 1 );

{
	my $script = write_script(
		$tmpdir,
		'valid.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [
		200,
		{{ "Content-Type": "text/plain" }},
		[ "ok\n" ],
	];
}
ZUZU
	);

	my $app = Zuzu::Web::PSGI->app( script => $script );
	ok( ref($app) eq 'CODE', 'app constructs a PSGI coderef' );

	my $response = $app->( {} );
	is( $response->[0], 200, 'app returns Zuzu response status' );
	is( $response->[1], [ 'Content-Type', 'text/plain' ], 'app returns headers' );
	is( $response->[2], [ "ok\n" ], 'app returns body' );
}

{
	my $script = write_script(
		$tmpdir,
		'missing-request.zzs',
		"let answer := 42;\n",
	);

	like(
		dies { Zuzu::Web::PSGI->app( script => $script ) },
		qr/does not define __request__/,
		'missing __request__ fails at construction time',
	);
}

{
	my $script = write_script(
		$tmpdir,
		'main-not-called.zzs',
		<<'ZUZU',
function __main__ ( argv ) {
	die "main should not run";
}

function __request__ ( env ) {
	return [
		200,
		{{ "Content-Type": "text/plain" }},
		[ "ok\n" ],
	];
}
ZUZU
	);

	my $app = Zuzu::Web::PSGI->app( script => $script );
	ok( ref($app) eq 'CODE', '__main__ is not called during construction' );
}

like(
	dies { Zuzu::Web::PSGI->app() },
	qr/requires a script argument/,
	'missing script argument fails',
);

done_testing;
