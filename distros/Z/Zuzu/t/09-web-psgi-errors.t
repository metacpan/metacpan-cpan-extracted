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

sub input_from_bytes {
	my ( $bytes ) = @_;

	open my $fh, '<', \$bytes
		or die "Could not open scalar request body: $!";
	return $fh;
}

sub error_stream {
	my $log = '';
	open my $fh, '>', \$log
		or die "Could not open scalar error stream: $!";

	return ( $fh, \$log );
}

my $tmpdir = tempdir( CLEANUP => 1 );

{
	my $script = write_script(
		$tmpdir,
		'throws.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	die "boom";
}
ZUZU
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my ( $errors, $log_ref ) = error_stream();
	my $response = $app->({ 'psgi.errors' => $errors });

	is( $response->[0], 500, 'thrown handler returns generic 500' );
	is( $response->[2], [ "Internal Server Error\n" ], 'client body is generic' );
	unlike( join( '', @{ $response->[2] } ), qr/boom/, 'client body hides error' );
	like( $$log_ref, qr/Zuzu PSGI error:/, 'log includes diagnostic prefix' );
	like( $$log_ref, qr/boom/, 'log includes thrown value text' );
}

{
	my $script = write_script(
		$tmpdir,
		'invalid-response.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [ 99, {}, null ];
}
ZUZU
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my ( $errors, $log_ref ) = error_stream();
	my $response = $app->({ 'psgi.errors' => $errors });

	is( $response->[0], 500, 'invalid response returns generic 500' );
	like( $$log_ref, qr/range 100\.\.599/, 'log includes status diagnostic' );
}

{
	my $script = write_script(
		$tmpdir,
		'short-body.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [ 200, {}, [ "ok" ] ];
}
ZUZU
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my ( $errors, $log_ref ) = error_stream();
	my $response = $app->({
		CONTENT_LENGTH => 10,
		'psgi.input' => input_from_bytes('abc'),
		'psgi.errors' => $errors,
	});

	is( $response->[0], 500, 'request conversion failure returns 500' );
	like(
		$$log_ref,
		qr/CONTENT_LENGTH bytes/,
		'log includes request body read diagnostic',
	);
}

{
	my $script = write_script(
		$tmpdir,
		'stderr-fallback.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	die "stderr fallback";
}
ZUZU
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my $stderr = '';
	open my $stderr_fh, '>', \$stderr
		or die "Could not open scalar STDERR: $!";

	{
		local *STDERR = $stderr_fh;
		is( $app->({})->[0], 500, 'missing psgi.errors still returns 500' );
	}

	like( $stderr, qr/Zuzu PSGI error:/, 'fallback writes diagnostic to STDERR' );
	like( $stderr, qr/stderr fallback/, 'fallback STDERR includes error text' );
}

done_testing;
