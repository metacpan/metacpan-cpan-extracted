use utf8;
use strict;
use warnings;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );
use HTTP::Request::Common qw( GET POST );
use Plack::Builder;
use Plack::Test;

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
		'inspect.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	let headers := env.get( "headers" );
	return [
		200,
		{
			"Content-Type": "text/plain; charset=UTF-8",
			"X-Method": env.get( "method" ),
			"X-Request-URI": env.get( "request_uri" ),
		},
		[
			env.get( "method" ), "\n",
			env.get( "path" ), "\n",
			env.get( "query_string" ), "\n",
			headers.get( "X-Echo", "" ), "\n",
			env.get( "body_text" ),
		],
	];
}
ZUZU
	);

	my $app = Zuzu::Web::PSGI->app( script => $script );

	test_psgi app => $app, client => sub {
		my ( $cb ) = @_;
		my $res = $cb->(
			GET '/inspect?x=1',
			'X-Echo' => 'header-value',
		);

		is( $res->code, 200, 'GET returns expected status through Plack' );
		is(
			$res->header('Content-Type'),
			'text/plain; charset=UTF-8',
			'GET returns expected header through Plack',
		);
		is( $res->header('X-Method'), 'GET', 'response sees method' );
		is( $res->header('X-Request-URI'), '/inspect?x=1', 'response sees request URI' );
		is(
			$res->content,
			"GET\n/inspect\nx=1\nheader-value\n",
			'GET request metadata reaches ZuzuScript',
		);

		$res = $cb->(
			POST '/inspect',
			'X-Echo' => 'post-header',
			Content_Type => 'text/plain; charset=UTF-8',
			Content => 'payload',
		);

		is( $res->code, 200, 'POST returns expected status through Plack' );
		is(
			$res->content,
			"POST\n/inspect\n\npost-header\npayload",
			'POST body reaches ZuzuScript',
		);
	};
}

{
	my $script = write_script(
		$tmpdir,
		'cookies.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [
		200,
		{{
			"Set-Cookie": "a=1",
			"Set-Cookie": "b=2",
		}},
		[ "cookies" ],
	];
}
ZUZU
	);

	my $app = Zuzu::Web::PSGI->app( script => $script );

	test_psgi app => $app, client => sub {
		my ( $cb ) = @_;
		my $res = $cb->( GET '/cookies' );
		my @cookies = $res->headers->header('Set-Cookie');

		is( \@cookies, [ 'a=1', 'b=2' ], 'duplicate response headers survive' );
		is( $res->content, 'cookies', 'duplicate-header app returns body' );
	};
}

{
	my $script = write_script(
		$tmpdir,
		'middleware.zzs',
		<<'ZUZU',
function __request__ ( env ) {
	return [
		200,
		{ "Content-Type": "text/plain" },
		[ "hello" ],
	];
}
ZUZU
	);

	my $app = builder {
		enable 'ContentLength';
		Zuzu::Web::PSGI->app( script => $script );
	};

	test_psgi app => $app, client => sub {
		my ( $cb ) = @_;
		my $res = $cb->( GET '/middleware' );

		is( $res->code, 200, 'middleware-wrapped app returns status' );
		is( $res->header('Content-Length'), 5, 'Plack middleware wraps app' );
		is( $res->content, 'hello', 'middleware-wrapped app returns body' );
	};
}

done_testing;
