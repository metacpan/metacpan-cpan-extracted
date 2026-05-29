package Zuzu::Web::PSGI;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001000';

use Encode ();
use Plack::MIME;
use Scalar::Util qw( blessed );
use Zuzu::Parser;
use Zuzu::Runtime;
use Zuzu::Value::Array;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Dict;
use Zuzu::Value::PairList;

sub app {
	my ( $class, @args ) = @_;
	die "Zuzu::Web::PSGI->app expects named arguments\n" if @args % 2;

	my %args = @args;
	my $script = $args{script};
	die "Zuzu::Web::PSGI->app requires a script argument\n"
		if !defined $script or $script eq '';

	if ( exists $args{debug_level} ) {
		$Zuzu::Runtime::DEBUG_LEVEL = $args{debug_level};
		$ENV{ZUZU_DEBUG_LEVEL} = $args{debug_level};
	}

	my $source = _slurp_utf8($script);
	my $runtime = _build_runtime(%args);
	my $ast = Zuzu::Parser->new->parse( $source, $script );
	$runtime->evaluate($ast);

	die "ZuzuScript PSGI application '$script' does not define __request__\n"
		if !$runtime->has_function('__request__');

	return sub {
		my ( $env ) = @_;
		my $response;
		my $ok = eval {
			my $request_env = _request_env_from_psgi($env);
			my $zuzu_response = $runtime->call( '__request__', $request_env );
			$response = _response_to_psgi($zuzu_response);
			1;
		};
		return $response if $ok;
		_handle_request_error( $runtime, $env, $@ );
		return _server_error_response();
	};
}

sub _handle_request_error {
	my ( $runtime, $psgi_env, $error ) = @_;

	_log_error( $psgi_env, _render_error( $runtime, $error ) );

	return;
}

sub _log_error {
	my ( $psgi_env, $message ) = @_;

	$message //= '';
	$message =~ s/\s+\z//;
	my $line = "Zuzu PSGI error: $message\n";
	my $errors = $psgi_env ? $psgi_env->{'psgi.errors'} : undef;

	if ( defined $errors ) {
		my $ok = eval {
			print {$errors} $line;
			1;
		};
		return if $ok;
	}

	eval {
		print STDERR $line;
		1;
	};

	return;
}

sub _render_error {
	my ( $runtime, $error ) = @_;

	if ( ref($error) eq 'HASH' and $error->{_zuzu_throw} ) {
		return _render_thrown_value( $runtime, $error->{value} );
	}

	return "$error";
}

sub _render_thrown_value {
	my ( $runtime, $value ) = @_;

	my $text = eval { $runtime->_to_String($value) };
	$text = defined $value ? "$value" : '' if !defined $text or $@ ne '';
	return $text if !blessed($value);
	return $text if !$value->isa('Zuzu::Value::Object');

	my $slots = $value->slots // {};
	my $file = $slots->{file};
	my $line = $slots->{line};
	return $text if !defined $file or !defined $line;

	return "$text at $file, line $line";
}

sub _response_to_psgi {
	my ( $value ) = @_;

	die "Zuzu PSGI response must be an Array\n"
		if !blessed($value) or !$value->isa('Zuzu::Value::Array');

	my @items = $value->resolved_items;
	die "Zuzu PSGI response Array must contain status, headers, and body\n"
		if @items != 3;

	my $status = _status_to_psgi( $items[0] );
	my $headers = _headers_to_psgi( $items[1] );

	return _response_parts_to_psgi( $status, $headers, $items[2] );
}

sub _response_parts_to_psgi {
	my ( $status, $headers, $body ) = @_;

	if ( _is_path_body($body) ) {
		return _path_response_to_psgi( $status, $headers, $body );
	}

	return [ $status, $headers, _body_to_psgi($body) ];
}

sub _status_to_psgi {
	my ( $value ) = @_;

	die "Zuzu PSGI response status must be an integer\n"
		if !defined $value
		or blessed($value)
		or $value !~ /\A[0-9]+\z/;

	my $status = 0 + $value;
	die "Zuzu PSGI response status must be in the range 100..599\n"
		if $status < 100 or $status > 599;

	return $status;
}

sub _headers_to_psgi {
	my ( $value ) = @_;

	if ( blessed($value) and $value->isa('Zuzu::Value::PairList') ) {
		my @headers;
		for ( my $i = 0; $i < @{ $value->list }; $i++ ) {
			push @headers, _header_pair_to_psgi(
				$value->list->[$i][0],
				$value->_value_at($i),
			);
		}
		return \@headers;
	}

	if ( blessed($value) and $value->isa('Zuzu::Value::Dict') ) {
		my @headers;
		for my $name ( sort keys %{ $value->map } ) {
			push @headers, _header_pair_to_psgi( $name, $value->get($name) );
		}
		return \@headers;
	}

	die "Zuzu PSGI response headers must be a PairList or Dict\n";
}

sub _header_pair_to_psgi {
	my ( $name, $value ) = @_;

	die "Zuzu PSGI response header names and values must be scalars\n"
		if !defined $name
		or !defined $value
		or blessed($name)
		or blessed($value);

	return ( "$name", "$value" );
}

sub _body_to_psgi {
	my ( $value ) = @_;

	return [] if !defined $value;

	if ( blessed($value) and $value->isa('Zuzu::Value::Array') ) {
		return [ map { _body_chunk_to_bytes($_) } $value->resolved_items ];
	}

	return [ _body_chunk_to_bytes($value) ];
}

sub _is_path_body {
	my ( $value ) = @_;

	return (
		blessed($value)
		and $value->isa('Zuzu::Value::Object')
		and exists $value->slots->{_path_tiny}
	) ? 1 : 0;
}

sub _path_response_to_psgi {
	my ( $status, $headers, $body ) = @_;
	my $path = $body->slots->{_path_tiny};

	if ( !$path->exists ) {
		return _plain_response( 404, "Not Found\n" );
	}
	if ( $path->is_dir ) {
		return _plain_response( 403, "Forbidden\n" );
	}

	open my $fh, '<:raw', "$path"
		or die "Could not open static response path '$path': $!\n";

	my @headers = @$headers;
	_add_inferred_content_type( \@headers, $path );

	return [ $status, \@headers, $fh ];
}

sub _add_inferred_content_type {
	my ( $headers, $path ) = @_;

	return if _headers_include_content_type($headers);

	my $content_type = Plack::MIME->mime_type("$path")
		// 'application/octet-stream';
	push @$headers, 'Content-Type', $content_type;

	return;
}

sub _headers_include_content_type {
	my ( $headers ) = @_;

	for ( my $i = 0; $i < @$headers; $i += 2 ) {
		return 1 if lc( $headers->[$i] ) eq 'content-type';
	}

	return 0;
}

sub _body_chunk_to_bytes {
	my ( $value ) = @_;

	die "Zuzu PSGI response body chunks may not be null\n"
		if !defined $value;

	if ( blessed($value) and $value->isa('Zuzu::Value::BinaryString') ) {
		return $value->bytes;
	}

	die "Unsupported Zuzu PSGI response body value\n" if blessed($value);

	return Encode::encode( 'UTF-8', "$value", Encode::FB_CROAK );
}

sub _server_error_response {
	return _plain_response( 500, "Internal Server Error\n" );
}

sub _plain_response {
	my ( $status, $body ) = @_;

	return [
		$status,
		[ 'Content-Type' => 'text/plain; charset=UTF-8' ],
		[ $body ],
	];
}

sub _request_env_from_psgi {
	my ( $psgi_env ) = @_;
	$psgi_env //= {};

	my $body = _read_psgi_body($psgi_env);
	my $request_uri = $psgi_env->{REQUEST_URI} // $psgi_env->{RAW_URI};
	my $raw_path = defined $request_uri
		? $request_uri =~ s/\?.*\z//r
		: ( ( $psgi_env->{SCRIPT_NAME} // '' ) . ( $psgi_env->{PATH_INFO} // '' ) );
	my $full_request_uri = defined $request_uri
		? $request_uri
		: $raw_path
			. (
				defined $psgi_env->{QUERY_STRING} && $psgi_env->{QUERY_STRING} ne ''
				? "?$psgi_env->{QUERY_STRING}"
				: ''
			);
	my $protocol = $psgi_env->{SERVER_PROTOCOL} // 'HTTP/1.1';

	return Zuzu::Value::Dict->new->add(
		[ method => $psgi_env->{REQUEST_METHOD} // '' ],
		[ protocol => $protocol ],
		[ server_protocol => $protocol ],
		[ scheme => _scheme_from_psgi($psgi_env) ],
		[ host => $psgi_env->{HTTP_HOST} // '' ],
		[ server_name => $psgi_env->{SERVER_NAME} // '' ],
		[ server_port => _server_port_from_psgi($psgi_env) ],
		[ remote_addr => $psgi_env->{REMOTE_ADDR} // '' ],
		[ remote_host => $psgi_env->{REMOTE_HOST} // '' ],
		[ remote_user => $psgi_env->{REMOTE_USER} ],
		[ script_name => $psgi_env->{SCRIPT_NAME} // '' ],
		[ path => $psgi_env->{PATH_INFO} // '' ],
		[ raw_path => $raw_path ],
		[ request_uri => $full_request_uri ],
		[ query_string => $psgi_env->{QUERY_STRING} // '' ],
		[ headers => _headers_from_psgi($psgi_env) ],
		[ body => Zuzu::Value::BinaryString->new( bytes => $body ) ],
		[ body_text => _body_text($body) ],
	);
}

sub _scheme_from_psgi {
	my ( $psgi_env ) = @_;

	return $psgi_env->{'psgi.url_scheme'}
		if defined $psgi_env->{'psgi.url_scheme'}
		and $psgi_env->{'psgi.url_scheme'} ne '';

	return 'https'
		if defined $psgi_env->{HTTPS}
		and $psgi_env->{HTTPS} =~ /\A(?:on|1)\z/i;

	return 'http';
}

sub _server_port_from_psgi {
	my ( $psgi_env ) = @_;
	my $port = $psgi_env->{SERVER_PORT};

	return undef if !defined $port or $port !~ /\A[0-9]+\z/;
	return 0 + $port;
}

sub _headers_from_psgi {
	my ( $psgi_env ) = @_;
	my $headers = Zuzu::Value::PairList->new;

	$headers->add( 'Content-Type', $psgi_env->{CONTENT_TYPE} )
		if defined $psgi_env->{CONTENT_TYPE};
	$headers->add( 'Content-Length', $psgi_env->{CONTENT_LENGTH} )
		if defined $psgi_env->{CONTENT_LENGTH};

	for my $key ( sort grep { /\AHTTP_/ } keys %$psgi_env ) {
		next if !defined $psgi_env->{$key};
		$headers->add( _header_name_from_psgi_key($key), $psgi_env->{$key} );
	}

	return $headers;
}

sub _header_name_from_psgi_key {
	my ( $key ) = @_;
	$key =~ s/\AHTTP_//;

	return join '-', map { ucfirst lc } split /_/, $key;
}

sub _read_psgi_body {
	my ( $psgi_env ) = @_;
	my $input = $psgi_env->{'psgi.input'};

	return '' if !defined $input;

	my $length = $psgi_env->{CONTENT_LENGTH};
	if ( defined $length and $length =~ /\A[0-9]+\z/ ) {
		return _read_exactly( $input, 0 + $length );
	}

	my $body = '';
	while ( 1 ) {
		my $chunk = '';
		my $read = read $input, $chunk, 8192;
		die "Could not read PSGI request body: $!\n" if !defined $read;
		last if $read == 0;
		$body .= $chunk;
	}

	return $body;
}

sub _read_exactly {
	my ( $input, $length ) = @_;
	my $body = '';

	while ( length($body) < $length ) {
		my $remaining = $length - length($body);
		my $chunk = '';
		my $read = read $input, $chunk, $remaining;
		die "Could not read PSGI request body: $!\n" if !defined $read;
		die "PSGI request body ended before CONTENT_LENGTH bytes were read\n"
			if $read == 0;
		$body .= $chunk;
	}

	return $body;
}

sub _body_text {
	my ( $bytes ) = @_;

	return eval { Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK ) };
}

sub _build_runtime {
	my ( %args ) = @_;

	my @lib = (
		@{ $args{lib} // [] },
		@Zuzu::Runtime::DEFAULT_LIB,
	);

	return Zuzu::Runtime->new(
		lib => \@lib,
		deny => $args{deny} // [],
		deny_modules => $args{deny_modules} // [],
	);
}

sub _slurp_utf8 {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Could not open '$path': $!\n";
	local $/;
	my $source = <$fh>;
	close $fh;

	return $source;
}

=pod

=head1 NAME

Zuzu::Web::PSGI - PSGI adapter for ZuzuScript web applications

=head1 DESCRIPTION

Loads a ZuzuScript application at PSGI application construction time and
returns a PSGI app coderef. The application must define C<__request__>.

Request headers are converted from the standard CGI-style PSGI
environment variables. PSGI normally does not preserve original header
order, original spelling, or duplicate request headers.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Web::PSGI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
