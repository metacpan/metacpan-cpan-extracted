use utf8;
use strict;
use warnings;

use Test2::V0;

use Encode ();
use File::Spec;
use File::Temp qw( tempdir );

use Zuzu::Value::Array;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Dict;
use Zuzu::Value::PairList;
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

	return $fh;
}

sub zarray {
	return Zuzu::Value::Array->new( items => [ @_ ] );
}

sub response {
	my ( @items ) = @_;

	return Zuzu::Web::PSGI::_response_to_psgi( zarray(@items) );
}

{
	my $headers = Zuzu::Value::PairList->new
		->add( 'Set-Cookie', 'a=1' )
		->add( 'Set-Cookie', 'b=2' );
	my $got = response( 200, $headers, zarray( 'hello', "\n" ) );

	is(
		$got,
		[
			200,
			[ 'Set-Cookie', 'a=1', 'Set-Cookie', 'b=2' ],
			[ 'hello', "\n" ],
		],
		'PairList headers and string-array body convert to PSGI',
	);
}

{
	my $headers = Zuzu::Value::Dict->new
		->add( [ 'X-Beta', '2' ] )
		->add( [ 'X-Alpha', '1' ] );
	my $got = response( 201, $headers, "snow \x{2603}" );

	is(
		$got,
		[
			201,
			[ 'X-Alpha', '1', 'X-Beta', '2' ],
			[ Encode::encode( 'UTF-8', "snow \x{2603}" ) ],
		],
		'Dict headers and single string body convert to PSGI',
	);
}

{
	my $binary = Zuzu::Value::BinaryString->new( bytes => "\xFF\x00" );
	my $got = response(
		202,
		Zuzu::Value::PairList->new,
		zarray( 'a', $binary ),
	);

	is( $got->[2], [ 'a', "\xFF\x00" ], 'mixed string and binary body works' );
}

{
	my $got = response( 204, Zuzu::Value::PairList->new, undef );

	is( $got->[2], [], 'null body becomes an empty PSGI body' );
}

like(
	dies { Zuzu::Web::PSGI::_response_to_psgi('not an array') },
	qr/must be an Array/,
	'non-array response is rejected',
);

like(
	dies { Zuzu::Web::PSGI::_response_to_psgi( zarray( 200, {} ) ) },
	qr/status, headers, and body/,
	'wrong response array length is rejected',
);

like(
	dies { response( 99, Zuzu::Value::PairList->new, undef ) },
	qr/range 100\.\.599/,
	'status outside HTTP range is rejected',
);

like(
	dies { response( 200, zarray(), undef ) },
	qr/headers must be a PairList or Dict/,
	'invalid response headers are rejected',
);

like(
	dies { response( 200, Zuzu::Value::PairList->new, Zuzu::Value::Dict->new ) },
	qr/Unsupported Zuzu PSGI response body value/,
	'unsupported response body is rejected',
);

my $tmpdir = tempdir( CLEANUP => 1 );

{
	my $script = write_script(
		$tmpdir,
		'env-response.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [
		200,
		{{ "X-Path": env.get( "path" ) }},
		[ env.get( "method" ), " ", env.get( "body_text" ) ],
	];
}
ZUZU
	);
	my $body = 'payload';
	my $app = Zuzu::Web::PSGI->app( script => $script );
	my $got = $app->({
		REQUEST_METHOD => 'POST',
		PATH_INFO => '/submit',
		CONTENT_LENGTH => length($body),
		'psgi.input' => input_from_bytes($body),
	});

	is(
		$got,
		[ 200, [ 'X-Path', '/submit' ], [ 'POST', ' ', 'payload' ] ],
		'PSGI request env reaches __request__',
	);
}

{
	my $script = write_script(
		$tmpdir,
		'async-response.zzs',
		<<'ZUZU',
async function __request__ ( env ) {
	return [
		200,
		{{ "Content-Type": "text/plain" }},
		[ "async\n" ],
	];
}
ZUZU
	);
	my $app = Zuzu::Web::PSGI->app( script => $script );

	is(
		$app->({}),
		[ 200, [ 'Content-Type', 'text/plain' ], [ "async\n" ] ],
		'async __request__ is awaited',
	);
}

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

	is(
		$app->({ 'psgi.errors' => error_stream() })->[0],
		500,
		'thrown __request__ becomes generic 500',
	);
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

	is(
		$app->({ 'psgi.errors' => error_stream() })->[0],
		500,
		'invalid app response becomes generic 500',
	);
}

done_testing;
