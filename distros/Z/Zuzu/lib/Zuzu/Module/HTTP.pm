package Zuzu::Module::HTTP;

use utf8;

our $VERSION = '0.006000';

use HTTP::Tiny ();
use JSON::PP ();
use File::Temp qw( tempfile );
use MIME::Base64 qw( encode_base64 );
use Scalar::Util qw( blessed );
use URI::Escape qw( uri_escape );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
	zuzu_bool
	zuzu_to_perl
);

my $HAS_HTTP_COOKIEJAR = eval {
	require HTTP::CookieJar;
	1;
};

{
	package Zuzu::Module::HTTP::SimpleCookieJar;

	sub new {
		my ( $class ) = @_;
		return bless {
			cookies => {},
		}, $class;
	}

	sub add {
		my ( $self, $url, $set_cookie ) = @_;
		my $key = defined $url ? "$url" : '';
		$self->{cookies}{$key} = defined $set_cookie ? "$set_cookie" : '';
		return;
	}

	sub cookie_header {
		my ( $self, $url ) = @_;
		my $key = defined $url ? "$url" : '';
		return $self->{cookies}{$key};
	}

	sub clear {
		my ( $self ) = @_;
		$self->{cookies} = {};
		return;
	}
}

sub _hash_from {
	my ( $value ) = @_;

	return {} if not defined $value;
	my $perl = zuzu_to_perl( $value );
	return {} if ref($perl) ne 'HASH';
	return $perl;
}

sub _extract_config {
	my ( $positional, $named ) = @_;

	my %config = %{ $named // {} };
	if ( @{ $positional // [] } ) {
		my $first = _hash_from( $positional->[0] );
		for my $key ( CORE::keys %{ $first } ) {
			$config{$key} = $first->{$key};
		}
	}

	return \%config;
}

sub _merge_query {
	my ( $url, $query ) = @_;

	return $url if ref($query) ne 'HASH' or not CORE::keys %{ $query };
	my @pairs;
	for my $key ( sort CORE::keys %{ $query } ) {
		my $value = defined $query->{$key} ? "$query->{$key}" : '';
		push @pairs, uri_escape($key) . '=' . uri_escape($value);
	}
	my $qs = join '&', @pairs;
	return $url . ( $url =~ /\?/ ? '&' : '?' ) . $qs;
}

sub _build_multipart {
	my ( $fields ) = @_;

	return ( undef, '' ) if ref($fields) ne 'HASH';
	my $boundary = 'zuzu-' . int(rand(1000000)) . '-' . time;
	my @chunks;
	for my $name ( sort CORE::keys %{ $fields } ) {
		my $value = defined $fields->{$name} ? "$fields->{$name}" : '';
		push @chunks,
			"--$boundary\r\n"
			. qq(Content-Disposition: form-data; name="$name"\r\n\r\n)
			. $value
			. "\r\n";
	}
	push @chunks, "--$boundary--\r\n";
	return ( "multipart/form-data; boundary=$boundary", join '', @chunks );
}

sub _build_request_options {
	my ( $spec, $tls_config, $client_config ) = @_;

	my %opts;
	if ( exists $spec->{headers} ) {
		$opts{headers} = _hash_from( $spec->{headers} );
	}
	$opts{headers} //= {};

	if ( exists $spec->{timeout} ) {
		my $timeout = 0 + $spec->{timeout};
		$opts{timeout} = $timeout if $timeout > 0;
		$client_config->{timeout} = $timeout
			if defined $client_config and $timeout > 0;
	}

	if ( exists $spec->{body} ) {
		$opts{content} = defined $spec->{body} ? "$spec->{body}" : '';
	}
	if ( exists $spec->{json} ) {
		$opts{content} = JSON::PP::encode_json( zuzu_to_perl( $spec->{json} ) );
		$opts{headers}{'content-type'} //= 'application/json';
	}
	if ( exists $spec->{upload_from} ) {
		my $file = defined $spec->{upload_from} ? "$spec->{upload_from}" : '';
		open my $fh, '<', $file or die "HTTP request upload_from open failed for '$file': $!";
		binmode $fh;
		local $/ = undef;
		$opts{content} = <$fh>;
		close $fh;
	}
	if ( exists $spec->{multipart} ) {
		my ( $content_type, $body ) = _build_multipart( _hash_from( $spec->{multipart} ) );
		$opts{content} = $body;
		$opts{headers}{'content-type'} = $content_type if defined $content_type;
	}
	if ( exists $spec->{download_to} ) {
		my $file = defined $spec->{download_to} ? "$spec->{download_to}" : '';
		open my $fh, '>', $file or die "HTTP request download_to open failed for '$file': $!";
		binmode $fh;
		$opts{data_callback} = sub {
			my ( $chunk, $response ) = @_;
			print {$fh} $chunk;
			return;
		};
		$opts{_download_handle} = $fh;
	}
	_apply_tls_options( $client_config, $tls_config // {} )
		if defined $client_config;

	return \%opts;
}

sub _is_native_object {
	my ( $value, $class ) = @_;

	return blessed($value)
		and $value->isa( 'Zuzu::Value::Object' )
		and $value->can('class')
		and $value->class->name eq $class;
}

sub _write_tls_tempfile {
	my ( $label, $content, $keepers ) = @_;

	my ( $fh, $path ) = tempfile( 'zuzu-http-tls-XXXXXX', TMPDIR => 1 );
	binmode $fh;
	print {$fh} $content;
	close $fh;
	push @{ $keepers }, $path;
	return $path;
}

sub _certificate_pem_from_value {
	my ( $value, $label ) = @_;

	if ( not defined $value ) {
		return '';
	}
	if ( not ref($value) ) {
		my $pem = "$value";
		die "$label expects PEM certificate text"
			if $pem !~ /-----BEGIN CERTIFICATE-----/;
		return $pem;
	}
	if ( _is_native_object( $value, 'Certificate' ) ) {
		my $der = $value->slots->{_der};
		my $encoded = encode_base64( $der, '' );
		$encoded =~ s/(.{1,64})/$1\n/g;
		return "-----BEGIN CERTIFICATE-----\n"
			. $encoded
			. "-----END CERTIFICATE-----\n";
	}
	die "TypeException: $label expects Certificate, String PEM, or Array";
}

sub _ca_pem_from_value {
	my ( $value, $label ) = @_;

	return '' if not defined $value;
	my $perl = zuzu_to_perl($value);
	if ( ref($perl) eq 'ARRAY' ) {
		return join '', map { _certificate_pem_from_value( $_, $label ) } @{ $perl };
	}
	return _certificate_pem_from_value( $value, $label );
}

sub _tls_identity_state {
	my ( $value, $label ) = @_;

	return undef if not defined $value;
	die "TypeException: $label expects TlsIdentity or null"
		if not _is_native_object( $value, 'TlsIdentity' );
	return $value->slots;
}

sub _tls_min_version {
	my ( $value, $label ) = @_;

	return undef if not defined $value;
	my $text = lc "$value";
	return 'TLSv12:!SSLv2:!SSLv3:!TLSv1:!TLSv11'
		if $text eq 'tls1.2';
	return 'TLSv13' if $text eq 'tls1.3';
	die "$label tls_min_version must be 'tls1.2' or 'tls1.3'";
}

sub _apply_tls_options {
	my ( $client_config, $tls ) = @_;

	my %ssl;
	my @keepers;
	my $label = 'std/net/http TLS configuration';

	if ( exists $tls->{tls_identity} and defined $tls->{tls_identity} ) {
		my $identity = _tls_identity_state( $tls->{tls_identity}, $label );
		$ssl{SSL_cert_file} = _write_tls_tempfile(
			'certificate',
			$identity->{_chain_pem} // $identity->{_cert_pem},
			\@keepers,
		);
		$ssl{SSL_key_file} = _write_tls_tempfile(
			'private key',
			$identity->{_key_pem},
			\@keepers,
		);
	}
	if ( exists $tls->{tls_ca} and defined $tls->{tls_ca} ) {
		my $pem = _ca_pem_from_value( $tls->{tls_ca}, $label );
		$ssl{SSL_ca_file} = _write_tls_tempfile( 'CA', $pem, \@keepers );
	}
	if ( exists $tls->{tls_verify} and not zuzu_bool( $tls->{tls_verify}, 1 ) ) {
		$client_config->{verify_SSL} = 0;
		if ( eval { require IO::Socket::SSL; 1 } ) {
			$ssl{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_NONE();
		}
	}
	elsif ( exists $tls->{tls_ca} and defined $tls->{tls_ca} ) {
		$client_config->{verify_SSL} = 1;
	}
	if ( exists $tls->{tls_server_name} and defined $tls->{tls_server_name} ) {
		my $name = "$tls->{tls_server_name}";
		$ssl{SSL_hostname} = $name;
		$ssl{SSL_verifycn_name} = $name;
	}
	if ( exists $tls->{tls_min_version} and defined $tls->{tls_min_version} ) {
		$ssl{SSL_version} = _tls_min_version( $tls->{tls_min_version}, $label );
	}
	if ( exists $tls->{tls_ciphers} and defined $tls->{tls_ciphers} ) {
		$ssl{SSL_cipher_list} = "$tls->{tls_ciphers}";
	}

	if ( CORE::keys %ssl ) {
		$client_config->{SSL_options} = {
			%{ $client_config->{SSL_options} // {} },
			%ssl,
		};
	}
	$client_config->{_tls_tempfiles} = \@keepers if @keepers;
	return;
}

sub _perform_request {
	my ( $ua, $method_name, $target, $opts, $retries, $tempfiles ) = @_;

	my $attempt = 0;
	my $response;
	while ( $attempt <= $retries ) {
		$response = $ua->request( $method_name, $target, $opts );
		last if $response->{success};
		last if ( $response->{status} // 0 ) < 500;
		$attempt++;
	}

	if ( exists $opts->{_download_handle} ) {
		close $opts->{_download_handle};
		delete $opts->{_download_handle};
	}
	if ( defined $tempfiles and @{$tempfiles} ) {
		unlink @{$tempfiles};
	}

	return $response;
}

sub _wrap_cookie_jar {
	my ( $cookiejar_class, $jar ) = @_;

	return native_object(
		class => $cookiejar_class,
		slots => {
			_jar => $jar,
		},
		const => {
			_jar => 1,
		},
	);
}

sub _wrap_response {
	my ( $response_class, $response ) = @_;

	return native_object(
		class => $response_class,
		slots => {
			_response => $response,
		},
		const => {
			_response => 1,
		},
	);
}

sub _async_task {
	my ( $runtime, $name, $work, $wrap ) = @_;

	my $worker = $runtime->_new_task(
		name => "$name.worker",
		start => 1,
		schedule => 1,
		thunk => $work,
	);
	return $runtime->_new_task(
		name => $name,
		schedule => 1,
		thunk => sub {
			my $value = $worker->await;
			return defined $wrap ? $wrap->($value) : $value;
		},
	);
}

sub _warn_blocking_operation {
	my ( $runtime, $operation ) = @_;

	$runtime->_warn_blocking_operation($operation)
		if $runtime->can('_warn_blocking_operation');

	return;
}

sub _cookie_jar_from_value {
	my ( $value ) = @_;

	return undef if not defined $value;
	if (
		blessed($value)
		and $value->isa( 'Zuzu::Value::Object' )
		and exists $value->slots->{_jar}
	) {
		return $value->slots->{_jar};
	}

	return $value;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $response_class = native_class(
		name => 'Response',
	);
	my $request_class = native_class(
		name => 'Request',
	);
	my $cookiejar_class = native_class(
		name => 'CookieJar',
	);
	my $useragent_class = native_class(
		name => 'UserAgent',
	);

	$cookiejar_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my %config = %{ _extract_config( $positional, $named ) };

		my $jar;
		if ( $HAS_HTTP_COOKIEJAR ) {
			$jar = HTTP::CookieJar->new( %config );
		}
		else {
			$jar = Zuzu::Module::HTTP::SimpleCookieJar->new();
		}

		return _wrap_cookie_jar( $klass, $jar );
	} );

	$cookiejar_class->methods->{add} = native_function(
		name => 'add',
		native => sub {
			my ( $self, $url, $set_cookie ) = @_;
			$self->slots->{_jar}->add( $url, $set_cookie );
			return $self;
		},
	);

	$cookiejar_class->methods->{cookie_header} = native_function(
		name => 'cookie_header',
		native => sub {
			my ( $self, $url ) = @_;
			return $self->slots->{_jar}->cookie_header( $url );
		},
	);

	$cookiejar_class->methods->{clear} = native_function(
		name => 'clear',
		native => sub {
			my ( $self ) = @_;
			if ( $self->slots->{_jar}->can( 'clear' ) ) {
				$self->slots->{_jar}->clear();
			}
			return $self;
		},
	);

	$response_class->methods->{status} = native_function(
		name => 'status',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{_response}{status};
		},
	);

	$response_class->methods->{reason} = native_function(
		name => 'reason',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{_response}{reason};
		},
	);

	$response_class->methods->{url} = native_function(
		name => 'url',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{_response}{url};
		},
	);

	$response_class->methods->{content} = native_function(
		name => 'content',
		native => sub {
			my ( $self ) = @_;
			return $self->slots->{_response}{content};
		},
	);

	$response_class->methods->{headers} = native_function(
		name => 'headers',
		native => sub {
			my ( $self ) = @_;
			my $headers = $self->slots->{_response}{headers} // {};
			return perl_to_zuzu( $headers );
		},
	);

	$response_class->methods->{header} = native_function(
		name => 'header',
		native => sub {
			my ( $self, $name ) = @_;
			my $headers = $self->slots->{_response}{headers} // {};
			my $key = defined $name ? lc "$name" : '';
			return $headers->{$key};
		},
	);

	$response_class->methods->{success} = native_function(
		name => 'success',
		native => sub {
			my ( $self ) = @_;
			return zuzu_bool( $self->slots->{_response}{success}, 0 ) ? 1 : 0;
		},
	);

	$response_class->methods->{to_Dict} = native_function(
		name => 'to_Dict',
		native => sub {
			my ( $self ) = @_;
			return perl_to_zuzu( $self->slots->{_response} );
		},
	);

	$response_class->methods->{json} = native_function(
		name => 'json',
		native => sub {
			my ( $self ) = @_;
			my $content = $self->slots->{_response}{content};
			return undef if not defined $content or $content eq '';
			return perl_to_zuzu( JSON::PP::decode_json($content) );
		},
	);

	$response_class->methods->{expect_success} = native_function(
		name => 'expect_success',
		native => sub {
			my ( $self, $message ) = @_;
			return $self if $self->slots->{_response}{success};
			my $status = $self->slots->{_response}{status} // 0;
			my $reason = $self->slots->{_response}{reason} // '';
			my $text = defined $message ? "$message" : 'HTTP request failed';
			die Zuzu::Error->new_runtime(
				message => "$text ($status $reason)",
				file => '<std/net/http>',
				line => 0,
			);
		},
	);

	$response_class->methods->{validate_json} = native_function(
		name => 'validate_json',
		native => sub {
			my ( $self, $validator ) = @_;
			my $json = $response_class->methods->{json}{_native}->( $self );
			if ( blessed($validator) and $validator->isa( 'Zuzu::Value::Function' ) ) {
				return $runtime->_call_function( $validator, [ $json ], '<std/net/http>', 0 );
			}
			return $json;
		},
	);

	$request_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my %spec = %{ _extract_config( $positional, $named ) };
		$spec{method} //= 'GET';
		$spec{headers} = _hash_from( $spec{headers} );
		$spec{query} = _hash_from( $spec{query} );
		return native_object(
			class => $klass,
			slots => {
				_spec => \%spec,
			},
			const => {
				_spec => 1,
			},
		);
	} );

	for my $field ( qw( method url body timeout retries download_to upload_from tls_identity ) ) {
		$request_class->methods->{$field} = native_function(
			name => $field,
			native => sub {
				my ( $self, $value ) = @_;
				$self->slots->{_spec}{$field} = $value;
				return $self;
			},
		);
	}

	$request_class->methods->{header} = native_function(
		name => 'header',
		native => sub {
			my ( $self, $name, $value ) = @_;
			my $key = defined $name ? lc "$name" : '';
			$self->slots->{_spec}{headers}{$key} = defined $value ? "$value" : '';
			return $self;
		},
	);

	$request_class->methods->{headers} = native_function(
		name => 'headers',
		native => sub {
			my ( $self, $headers ) = @_;
			my $next = _hash_from( $headers );
			for my $key ( CORE::keys %{ $next } ) {
				$self->slots->{_spec}{headers}{lc $key} = defined $next->{$key} ? "$next->{$key}" : '';
			}
			return $self;
		},
	);

	$request_class->methods->{query} = native_function(
		name => 'query',
		native => sub {
			my ( $self, $query ) = @_;
			my $next = _hash_from( $query );
			for my $key ( CORE::keys %{ $next } ) {
				$self->slots->{_spec}{query}{$key} = defined $next->{$key} ? "$next->{$key}" : '';
			}
			return $self;
		},
	);

	$request_class->methods->{json} = native_function(
		name => 'json',
		native => sub {
			my ( $self, $value ) = @_;
			$self->slots->{_spec}{json} = zuzu_to_perl($value);
			return $self;
		},
	);

	$request_class->methods->{multipart} = native_function(
		name => 'multipart',
		native => sub {
			my ( $self, $fields ) = @_;
			$self->slots->{_spec}{multipart} = _hash_from( $fields );
			return $self;
		},
	);

	$request_class->methods->{auth_bearer} = native_function(
		name => 'auth_bearer',
		native => sub {
			my ( $self, $token ) = @_;
			my $value = defined $token ? "$token" : '';
			$self->slots->{_spec}{headers}{authorization} = "Bearer $value";
			return $self;
		},
	);

	$request_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $ua_obj ) = @_;
			die 'Request.send expects a UserAgent' if not blessed($ua_obj)
				or not $ua_obj->isa( 'Zuzu::Value::Object' )
				or not exists $ua_obj->slots->{_ua};
			return $useragent_class->methods->{send}{_native}->( $ua_obj, $self );
		},
	);

	$request_class->methods->{send_async} = native_function(
		name => 'send_async',
		native => sub {
			my ( $self, $ua_obj ) = @_;
			die 'Request.send_async expects a UserAgent' if not blessed($ua_obj)
				or not $ua_obj->isa( 'Zuzu::Value::Object' )
				or not exists $ua_obj->slots->{_ua};
			return $useragent_class->methods->{send_async}{_native}->(
				$ua_obj,
				$self,
			);
		},
	);

	$useragent_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my %config = %{ _extract_config( $positional, $named ) };
		my $transport = delete $config{transport};
		my %tls_config;
		for my $key ( qw( tls_identity tls_ca tls_verify tls_server_name tls_min_version tls_ciphers ) ) {
			$tls_config{$key} = delete $config{$key} if exists $config{$key};
		}

		if ( exists $config{default_headers} ) {
			$config{default_headers} = _hash_from( $config{default_headers} );
		}
		if ( exists $config{cookie_jar} ) {
			$config{cookie_jar} = _cookie_jar_from_value( $config{cookie_jar} );
		}

		my $ua = $transport || HTTP::Tiny->new( %config );

		return native_object(
			class => $klass,
			slots => {
				_ua => $ua,
				_tls_config => \%tls_config,
				_ua_config => \%config,
				_response_class => $response_class,
				_request_class => $request_class,
			},
			const => {
				_ua => 1,
				_tls_config => 1,
				_ua_config => 1,
				_response_class => 1,
				_request_class => 1,
			},
		);
	} );

	$useragent_class->methods->{build_request} = native_function(
		name => 'build_request',
		native => sub {
			my ( $self, $method, $url ) = @_;
			my $spec = {
				method => defined $method ? "$method" : 'GET',
				url => defined $url ? "$url" : '',
				headers => {},
				query => {},
			};
			return native_object(
				class => $self->slots->{_request_class},
				slots => {
					_spec => $spec,
				},
				const => {
					_spec => 1,
				},
			);
		},
	);

	$useragent_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $request ) = @_;
			_warn_blocking_operation( $runtime, 'std/net/http UserAgent.send' );
			die 'UserAgent.send expects a Request' if not blessed($request)
				or not $request->isa( 'Zuzu::Value::Object' )
				or not exists $request->slots->{_spec};
			my $spec = $request->slots->{_spec};
			my $method_name = defined $spec->{method} ? uc "$spec->{method}" : 'GET';
			my $target = defined $spec->{url} ? "$spec->{url}" : '';
			$target = _merge_query( $target, _hash_from( $spec->{query} ) );
			my %tls_config = %{ $self->slots->{_tls_config} // {} };
			$tls_config{tls_identity} = $spec->{tls_identity}
				if exists $spec->{tls_identity};
			my %client_config = %{ $self->slots->{_ua_config} // {} };
			my $opts = _build_request_options(
				$spec,
				\%tls_config,
				\%client_config,
			);
			my $tempfiles = delete $client_config{_tls_tempfiles};
			my $ua = CORE::keys(%tls_config)
				? HTTP::Tiny->new(%client_config)
				: $self->slots->{_ua};
			my $retries = defined $spec->{retries} ? int( $spec->{retries} ) : 0;
			$retries = 0 if $retries < 0;
			my $response = _perform_request(
				$ua,
				$method_name,
				$target,
				$opts,
				$retries,
				$tempfiles,
			);
			return _wrap_response( $self->slots->{_response_class}, $response );
		},
	);

	$useragent_class->methods->{send_async} = native_function(
		name => 'send_async',
		native => sub {
			my ( $self, $request ) = @_;
			die 'UserAgent.send_async expects a Request' if not blessed($request)
				or not $request->isa( 'Zuzu::Value::Object' )
				or not exists $request->slots->{_spec};
			my $spec = $request->slots->{_spec};
			my $ua = $self->slots->{_ua};
			my $tls_config = { %{ $self->slots->{_tls_config} // {} } };
			$tls_config->{tls_identity} = $spec->{tls_identity}
				if exists $spec->{tls_identity};
			my $ua_config = { %{ $self->slots->{_ua_config} // {} } };
			my $response_class = $self->slots->{_response_class};
			return _async_task(
				$runtime,
				'http.send_async',
				sub {
					my $method_name = defined $spec->{method}
						? uc "$spec->{method}"
						: 'GET';
					my $target = defined $spec->{url} ? "$spec->{url}" : '';
					$target = _merge_query( $target, _hash_from( $spec->{query} ) );
					my $opts = _build_request_options(
						$spec,
						$tls_config,
						$ua_config,
					);
					my $tempfiles = delete $ua_config->{_tls_tempfiles};
					my $request_ua = CORE::keys( %{$tls_config} )
						? HTTP::Tiny->new( %{$ua_config} )
						: $ua;
					my $retries = defined $spec->{retries}
						? int( $spec->{retries} )
						: 0;
					$retries = 0 if $retries < 0;
					return _perform_request(
						$request_ua,
						$method_name,
						$target,
						$opts,
						$retries,
						$tempfiles,
					);
				},
				sub {
					my ( $response ) = @_;
					return _wrap_response( $response_class, $response );
				},
			);
		},
	);

	$useragent_class->methods->{request} = native_function(
		name => 'request',
		native => sub {
			my ( $self, $method, $url, $data, $headers ) = @_;
			my $req = $self->slots->{_request_class}->native_constructor->(
				$runtime,
				$self->slots->{_request_class},
				[],
				{
					method => $method,
					url => $url,
					body => $data,
					headers => $headers,
				},
			);
			return $useragent_class->methods->{send}{_native}->( $self, $req );
		},
	);

	$useragent_class->methods->{request_async} = native_function(
		name => 'request_async',
		native => sub {
			my ( $self, $method, $url, $data, $headers ) = @_;
			my $req = $self->slots->{_request_class}->native_constructor->(
				$runtime,
				$self->slots->{_request_class},
				[],
				{
					method => $method,
					url => $url,
					body => $data,
					headers => $headers,
				},
			);
			return $useragent_class->methods->{send_async}{_native}->(
				$self,
				$req,
			);
		},
	);

	for my $method ( qw( get head delete post put patch options ) ) {
		$useragent_class->methods->{$method} = native_function(
			name => $method,
			native => sub {
				my ( $self, $url, $data_or_headers, $headers ) = @_;
				my $data;
				my $extra_headers;
				if ( $method eq 'post' or $method eq 'put' or $method eq 'patch' ) {
					$data = $data_or_headers;
					$extra_headers = $headers;
				}
				else {
					$extra_headers = $data_or_headers if defined $data_or_headers;
				}
				return $useragent_class->methods->{request}{_native}->(
					$self,
					uc($method),
					$url,
					$data,
					$extra_headers,
				);
			},
		);
		$useragent_class->methods->{ $method . '_async' } = native_function(
			name => $method . '_async',
			native => sub {
				my ( $self, $url, $data_or_headers, $headers ) = @_;
				my $data;
				my $extra_headers;
				if ( $method eq 'post' or $method eq 'put' or $method eq 'patch' ) {
					$data = $data_or_headers;
					$extra_headers = $headers;
				}
				else {
					$extra_headers = $data_or_headers if defined $data_or_headers;
				}
				return $useragent_class->methods->{request_async}{_native}->(
					$self,
					uc($method),
					$url,
					$data,
					$extra_headers,
				);
			},
		);
	}

	return {
		CookieJar => $cookiejar_class,
		Request => $request_class,
		Response => $response_class,
		UserAgent => $useragent_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::HTTP - std/net/http bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/net/http> module and exports C<CookieJar>,
C<Request>, C<Response>, and C<UserAgent>.

=head1 CLASSES

=head2 CookieJar

Cookie storage abstraction used by C<UserAgent>. Uses
C<HTTP::CookieJar> when available, otherwise a basic in-memory fallback.

Methods:

=over

=item * C<add(url, set_cookie)>

=item * C<cookie_header(url)>

=item * C<clear()>

=back

=head2 Response

Wrapper around an HTTP response hash.

Methods include C<status>, C<reason>, C<url>, C<content>, C<headers>,
C<header(name)>, C<success>, C<json>, C<expect_success>,
C<validate_json>, and C<to_Dict>.

=head2 Request

Mutable request builder used by C<UserAgent>.

Methods include C<method>, C<url>, C<header>, C<headers>, C<query>,
C<body>, C<json>, C<auth_bearer>, C<timeout>, C<retries>,
C<download_to>, C<upload_from>, C<multipart>, and C<send(user_agent)>.

=head2 UserAgent

Wrapper around C<HTTP::Tiny>.

Methods include C<build_request(method, url)>, C<send(request)>,
C<request(method, url, data?, headers?)>, plus shorthand methods
C<get>, C<head>, C<delete>, C<post>, C<put>, C<patch>, and C<options>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::HTTP >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
