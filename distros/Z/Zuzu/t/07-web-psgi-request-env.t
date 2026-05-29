use utf8;
use strict;
use warnings;

use Test2::V0;

use Encode ();
use Scalar::Util qw( blessed );

use Zuzu::Value::BinaryString;
use Zuzu::Value::Dict;
use Zuzu::Value::PairList;
use Zuzu::Web::PSGI;

sub input_from_bytes {
	my ( $bytes ) = @_;

	open my $fh, '<', \$bytes
		or die "Could not open scalar request body: $!";
	return $fh;
}

sub request_env {
	my ( %env ) = @_;

	return Zuzu::Web::PSGI::_request_env_from_psgi( \%env );
}

sub pairlist_pairs {
	my ( $pairlist ) = @_;

	return [
		map {
			[ $_->[0], $_->[1] ]
		} @{ $pairlist->list }
	];
}

{
	my $body = Encode::encode( 'UTF-8', "hello \x{2603}" );
	my $env = request_env(
		REQUEST_METHOD => 'POST',
		'psgi.url_scheme' => 'https',
		HTTP_HOST => 'example.test:8443',
		SERVER_NAME => 'example.test',
		SERVER_PORT => '8443',
		REMOTE_ADDR => '192.0.2.10',
		SCRIPT_NAME => '/app',
		PATH_INFO => '/submit',
		REQUEST_URI => '/app/submit?x=1',
		QUERY_STRING => 'x=1',
		CONTENT_TYPE => 'text/plain; charset=UTF-8',
		CONTENT_LENGTH => length($body),
		HTTP_ACCEPT_LANGUAGE => 'en-GB',
		HTTP_X_REQUEST_ID => 'abc123',
		'psgi.input' => input_from_bytes($body),
	);

	ok(
		blessed($env) && $env->isa('Zuzu::Value::Dict'),
		'request conversion returns a Zuzu Dict',
	);
	is( $env->get('method'), 'POST', 'method is populated' );
	is( $env->get('scheme'), 'https', 'scheme is populated' );
	is( $env->get('host'), 'example.test:8443', 'host is populated' );
	is( $env->get('server_name'), 'example.test', 'server_name is populated' );
	is( $env->get('server_port'), 8443, 'server_port is numeric' );
	is( $env->get('remote_addr'), '192.0.2.10', 'remote_addr is populated' );
	is( $env->get('path'), '/submit', 'path is populated' );
	is( $env->get('raw_path'), '/app/submit', 'raw_path strips query string' );
	is( $env->get('query_string'), 'x=1', 'query_string is populated' );

	my $headers = $env->get('headers');
	ok(
		blessed($headers) && $headers->isa('Zuzu::Value::PairList'),
		'headers are a PairList',
	);
	is(
		pairlist_pairs($headers),
		[
			[ 'Content-Type', 'text/plain; charset=UTF-8' ],
			[ 'Content-Length', length($body) ],
			[ 'Accept-Language', 'en-GB' ],
			[ 'Host', 'example.test:8443' ],
			[ 'X-Request-Id', 'abc123' ],
		],
		'headers are converted deterministically from PSGI variables',
	);

	my $binary_body = $env->get('body');
	ok(
		blessed($binary_body)
			&& $binary_body->isa('Zuzu::Value::BinaryString'),
		'body is a BinaryString',
	);
	is( $binary_body->bytes, $body, 'body preserves raw request bytes' );
	is( $env->get('body_text'), "hello \x{2603}", 'body_text decodes UTF-8' );
}

{
	my $body = "\xFF\xFE";
	my $env = request_env(
		REQUEST_METHOD => 'PUT',
		PATH_INFO => '/binary',
		CONTENT_LENGTH => length($body),
		'psgi.input' => input_from_bytes($body),
	);

	is( $env->get('body')->bytes, $body, 'invalid UTF-8 body bytes survive' );
	is( $env->get('body_text'), undef, 'invalid UTF-8 body_text is null' );
}

{
	my $env = request_env(
		REQUEST_METHOD => 'GET',
		HTTPS => 'on',
		SCRIPT_NAME => '/mounted',
		PATH_INFO => '/fallback',
		SERVER_PORT => 'not-a-port',
	);

	is( $env->get('scheme'), 'https', 'HTTPS provides scheme fallback' );
	is(
		$env->get('raw_path'),
		'/mounted/fallback',
		'raw_path falls back to SCRIPT_NAME plus PATH_INFO',
	);
	is( $env->get('server_port'), undef, 'non-numeric server_port is null' );
	is( $env->get('body')->bytes, '', 'missing psgi.input gives empty body' );
	is( $env->get('body_text'), '', 'empty body_text decodes to empty string' );
}

{
	my $body = 'abcdef';
	like(
		dies {
			request_env(
				CONTENT_LENGTH => 10,
				'psgi.input' => input_from_bytes($body),
			);
		},
		qr/CONTENT_LENGTH bytes/,
		'short explicit request body fails',
	);
}

done_testing;
