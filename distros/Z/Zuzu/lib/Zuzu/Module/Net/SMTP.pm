package Zuzu::Module::Net::SMTP;

use utf8;

our $VERSION = '0.007000';

use B ();
use IO::Socket::INET ();
use IO::Socket::SSL qw( SSL_VERIFY_NONE SSL_VERIFY_PEER );
use IPC::Run qw( run );
use MIME::Base64 qw( encode_base64 );
use Scalar::Util qw( blessed );
use Sys::Hostname qw( hostname );

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	zuzu_bool
	zuzu_to_perl
);
use Zuzu::Error;
use Zuzu::Value::Array;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;
use Zuzu::Value::Dict;
use Zuzu::Value::PairList;

my @SENDMAIL_PATHS = qw(
	/usr/sbin/sendmail
	/usr/lib/sendmail
	/sbin/sendmail
	/usr/bin/sendmail
);

sub _true {
	return Zuzu::Value::Boolean->new( value => 1 );
}

sub _false {
	return Zuzu::Value::Boolean->new( value => 0 );
}

sub _bool {
	my ( $value ) = @_;

	return $value ? _true() : _false();
}

sub _array {
	return Zuzu::Value::Array->new( items => [ @_ ] );
}

sub _type_name {
	my ( $value ) = @_;

	return 'Null' if not defined $value;
	if ( blessed($value) ) {
		return 'BinaryString' if $value->isa('Zuzu::Value::BinaryString');
		return 'PairList' if $value->isa('Zuzu::Value::PairList');
		return 'Dict' if $value->isa('Zuzu::Value::Dict');
		return 'Array' if $value->isa('Zuzu::Value::Array');
		return 'Boolean' if $value->isa('Zuzu::Value::Boolean');
		return $value->can('class') ? $value->class->name : ref($value);
	}
	return _is_string_scalar($value) ? 'String' : 'Number';
}

sub _is_string_scalar {
	my ( $value ) = @_;

	return B::svref_2object( \$value )->FLAGS & B::SVf_POK() ? 1 : 0;
}

sub _scalar_bytes {
	my ( $value ) = @_;

	my $text = defined $value ? "$value" : '';
	utf8::encode($text) if utf8::is_utf8($text);
	return $text;
}

sub _error {
	my ( $category, $message ) = @_;

	die Zuzu::Error->new_runtime(
		message => "$category: $message",
		file => '<std/net/smtp>',
		line => 0,
	);
}

sub _sendmail_available_path {
	for my $path ( @SENDMAIL_PATHS ) {
		return $path if -x $path;
	}
	return undef;
}

sub _capabilities {
	return Zuzu::Value::Dict->new(
		map => {
			smtp => _true(),
			sendmail => _bool( defined _sendmail_available_path() ),
			tls => _true(),
			starttls => _true(),
			auth => _array( qw( plain login xoauth2 ) ),
			async => _true(),
		},
	);
}

sub _hash_from {
	my ( $value ) = @_;

	return {} if not defined $value;
	my $perl = zuzu_to_perl($value);
	return {} if ref($perl) ne 'HASH';
	return $perl;
}

sub _extract_config {
	my ( $positional, $named ) = @_;

	my %config = %{ $named // {} };
	if ( @{ $positional // [] } ) {
		my $first = _hash_from( $positional->[0] );
		for my $key ( keys %{$first} ) {
			$config{$key} = $first->{$key};
		}
	}

	return \%config;
}

sub _normalise_config {
	my ( $raw ) = @_;

	my %config = %{ $raw // {} };
	$config{transport} = defined $config{transport}
		? lc "$config{transport}"
		: 'smtp';
	_error( 'mail.unsupported', "transport must be 'smtp' or 'sendmail'" )
		if $config{transport} ne 'smtp'
		and $config{transport} ne 'sendmail';

	my $submission = zuzu_bool( $config{submission}, 0 );
	$config{host} = defined $config{host} ? "$config{host}" : 'localhost';
	$config{port} = defined $config{port}
		? int( $config{port} )
		: ( $submission ? 587 : 25 );
	$config{timeout} = defined $config{timeout}
		? 0 + $config{timeout}
		: 30;
	$config{timeout} = 30 if $config{timeout} <= 0;
	$config{tls} = zuzu_bool( $config{tls}, 0 ) ? 1 : 0;
	$config{starttls} = exists $config{starttls}
		? ( zuzu_bool( $config{starttls}, 0 ) ? 1 : 0 )
		: ( $submission ? 1 : 0 );
	$config{tls_verify} = zuzu_bool( $config{tls_verify}, 1 ) ? 1 : 0;
	$config{smtputf8} = zuzu_bool( $config{smtputf8}, 0 ) ? 1 : 0;
	$config{allow_insecure_auth} = zuzu_bool(
		$config{allow_insecure_auth},
		0,
	) ? 1 : 0;
	$config{reject_partial} = zuzu_bool( $config{reject_partial}, 0 ) ? 1 : 0;
	$config{sendmail_path} = defined $config{sendmail_path}
		? "$config{sendmail_path}"
		: undef;
	$config{sendmail_args} = _validate_sendmail_args(
		_string_array( $config{sendmail_args}, 'sendmail_args' ),
	);

	for my $key ( qw( username password auth tls_server_name ) ) {
		$config{$key} = "$config{$key}" if defined $config{$key};
	}

	return \%config;
}

sub _merge_config {
	my ( $base, $overrides ) = @_;

	my %merged = %{ $base // {} };
	my $extra = _hash_from($overrides);
	for my $key ( keys %{$extra} ) {
		$merged{$key} = $extra->{$key};
	}
	return _normalise_config( \%merged );
}

sub _string_array {
	my ( $value, $label ) = @_;

	return [] if not defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::Array') ) {
		return [ map { defined $_ ? "$_" : '' } $value->resolved_items ];
	}
	if ( ref($value) eq 'ARRAY' ) {
		return [ map { defined $_ ? "$_" : '' } @{$value} ];
	}
	_error(
		'mail.invalid_address',
		"$label expects Array, got " . _type_name($value),
	);
}

sub _validate_sendmail_args {
	my ( $args ) = @_;

	for my $arg ( @{ $args // [] } ) {
		_error(
			'mail.unsupported',
			"sendmail_args must not enable header-derived recipients",
		) if $arg eq '--read-recipients';
		next if $arg !~ /\A-[^-]/;
		_error(
			'mail.unsupported',
			"sendmail_args must not enable header-derived recipients",
		) if $arg =~ /\A-[A-Za-z]*t[A-Za-z]*\z/;
	}
	return $args;
}

sub _reject_unsupported_security_options {
	my ( $config ) = @_;

	my $auth = lc( $config->{auth} // '' );
	if ( $auth ne '' and $auth !~ /\A(?:plain|login|xoauth2)\z/ ) {
		_error( 'mail.auth', "unsupported SMTP auth mechanism '$auth'" );
	}
	if ( ( $config->{username} or $config->{password} or $auth ne '' )
		and !$config->{tls}
		and !$config->{starttls}
		and !$config->{allow_insecure_auth} ) {
		_error(
			'mail.auth',
			'SMTP authentication without TLS requires allow_insecure_auth: true',
		);
	}
	return;
}

sub _recipient_list {
	my ( $value ) = @_;

	my @recipients;
	if ( blessed($value) and $value->isa('Zuzu::Value::Array') ) {
		@recipients = $value->resolved_items;
	}
	elsif ( ref($value) eq 'ARRAY' ) {
		@recipients = @{$value};
	}
	else {
		@recipients = ($value);
	}

	@recipients = map { defined $_ ? "$_" : '' } @recipients;
	_error( 'mail.invalid_address', 'at least one envelope recipient is required' )
		if !@recipients;
	for my $recipient ( @recipients ) {
		_validate_address($recipient);
	}
	return \@recipients;
}

sub _validate_address {
	my ( $address ) = @_;

	$address = defined $address ? "$address" : '';
	_error( 'mail.invalid_address', 'envelope address must not be empty' )
		if $address eq '';
	_error( 'mail.invalid_address', 'envelope address contains a control character' )
		if $address =~ /[\x00-\x1F\x7F]/;
	_error( 'mail.invalid_address', 'envelope address must not contain angle brackets' )
		if $address =~ /[<>]/;
	return $address;
}

sub _validate_envelope_ascii {
	my ( $config, @addresses ) = @_;

	return if $config->{smtputf8};
	for my $address ( @addresses ) {
		_error(
			'mail.invalid_address',
			'non-ASCII envelope addresses require smtputf8: true',
		) if $address =~ /[^\x00-\x7F]/;
	}
	return;
}

sub _header_value_bytes {
	my ( $value, $name ) = @_;

	my $bytes;
	if ( not defined $value ) {
		_error(
			'mail.invalid_headers',
			"header '$name' expects String or BinaryString, got Null",
		);
	}
	elsif ( blessed($value) and $value->isa('Zuzu::Value::BinaryString') ) {
		$bytes = $value->bytes // '';
	}
	elsif ( !ref($value) and _is_string_scalar($value) ) {
		$bytes = _scalar_bytes($value);
	}
	else {
		_error(
			'mail.invalid_headers',
			"header '$name' expects String or BinaryString, got "
				. _type_name($value),
		);
	}
	_error(
		'mail.invalid_headers',
		"header '$name' value must not contain CR or LF",
	) if $bytes =~ /[\r\n]/;
	return $bytes;
}

sub _validate_header_name {
	my ( $name ) = @_;

	$name = defined $name ? "$name" : '';
	_error( 'mail.invalid_headers', 'header name must not be empty' )
		if $name eq '';
	_error( 'mail.invalid_headers', "invalid header name '$name'" )
		if $name !~ /\A[!-9;-~]+\z/;
	return $name;
}

sub _serialise_message {
	my ( $headers, $body ) = @_;

	_error(
		'mail.invalid_headers',
		'headers expects PairList, got ' . _type_name($headers),
	) if not blessed($headers) or not $headers->isa('Zuzu::Value::PairList');

	_error(
		'TypeException',
		'Mailer.send body expects BinaryString, got ' . _type_name($body),
	) if not blessed($body) or not $body->isa('Zuzu::Value::BinaryString');

	my $message = '';
	my $message_id;
	for ( my $i = 0; $i < @{ $headers->list }; $i++ ) {
		my $pair = $headers->list->[$i];
		my $name = _validate_header_name( $pair->[0] );
		my $value = $headers->can('_value_at')
			? $headers->_value_at($i)
			: $pair->[1];
		my $bytes = _header_value_bytes( $value, $name );
		$message .= $name . ': ' . $bytes . "\r\n";
		$message_id = $bytes
			if not defined $message_id
			and lc($name) eq 'message-id';
	}
	$message .= "\r\n";
	$message .= $body->bytes // '';

	return ( $message, $message_id );
}

sub _dot_stuff {
	my ( $bytes ) = @_;

	$bytes =~ s/\A\./../;
	$bytes =~ s/(\r\n)\./$1../g;
	return $bytes;
}

sub _wrap_result {
	my ( $class_obj, $result ) = @_;

	return native_object(
		class => $class_obj,
		slots => {
			transport => $result->{transport},
			accepted => Zuzu::Value::Array->new(
				items => [ @{ $result->{accepted} // [] } ],
			),
			rejected => Zuzu::Value::Array->new(
				items => [ @{ $result->{rejected} // [] } ],
			),
			message_id => $result->{message_id},
			response => $result->{response},
		},
		const => {
			transport => 1,
			accepted => 1,
			rejected => 1,
			message_id => 1,
			response => 1,
		},
	);
}

sub _run_sendmail {
	my ( $config, $from, $recipients, $message, $message_id ) = @_;

	my $path = $config->{sendmail_path} // _sendmail_available_path();
	_error(
		'mail.unsupported',
		'sendmail transport is unavailable; configure sendmail_path',
	) if not defined $path or $path eq '';

	my @cmd = (
		$path,
		@{ $config->{sendmail_args} // [] },
		'-i',
		'-f',
		$from,
		@{$recipients},
	);
	my ( $stdout, $stderr ) = ( '', '' );
	my $ok = eval {
		run( \@cmd, '<', \$message, '>', \$stdout, '2>', \$stderr );
		1;
	};
	if ( !$ok ) {
		my $err = defined $@ ? "$@" : 'process launch failed';
		_error( 'mail.process', "sendmail failed to start: $err" );
	}

	my $status = $?;
	if ( $status != 0 ) {
		my $exit = $status >> 8;
		my $diag = defined $stderr ? $stderr : '';
		$diag = substr( $diag, 0, 4096 );
		_error(
			'mail.process',
			"sendmail exited with status $exit"
				. ( $diag ne '' ? ": $diag" : '' ),
		);
	}

	return {
		transport => 'sendmail',
		accepted => [ @{$recipients} ],
		rejected => [],
		message_id => $message_id,
		response => 'sendmail exit 0',
	};
}

sub _smtp_read_response {
	my ( $sock ) = @_;

	my @lines;
	while ( defined( my $line = <$sock> ) ) {
		$line =~ s/\r?\n\z//;
		push @lines, $line;
		last if $line =~ /^\d{3}\s/;
		last if $line !~ /^\d{3}-/;
	}
	_error( 'mail.connection', 'SMTP server closed the connection' )
		if !@lines;

	my ( $code ) = $lines[0] =~ /^(\d{3})/;
	_error( 'mail.connection', 'SMTP server returned an invalid response' )
		if not defined $code;

	return ( 0 + $code, \@lines );
}

sub _smtp_write {
	my ( $sock, $bytes ) = @_;

	my $offset = 0;
	my $length = length($bytes);
	while ( $offset < $length ) {
		my $written = syswrite $sock, $bytes, $length - $offset, $offset;
		_error( 'mail.connection', "SMTP write failed: $!" )
			if not defined $written;
		_error( 'mail.connection', 'SMTP write made no progress' )
			if $written == 0;
		$offset += $written;
	}
	return;
}

sub _smtp_command {
	my ( $sock, $command ) = @_;

	_smtp_write( $sock, $command . "\r\n" );
	return _smtp_read_response($sock);
}

sub _smtp_text {
	my ( $lines ) = @_;

	return join "\n", @{ $lines // [] };
}

sub _smtp_expect {
	my ( $category, $expected, $code, $lines, $context ) = @_;

	return if grep { $code == $_ } @{$expected};
	_error( $category, "$context failed: " . _smtp_text($lines) );
}

sub _smtp_extensions {
	my ( $lines ) = @_;

	my %extensions;
	for my $line ( @{ $lines // [] } ) {
		next if $line !~ /^\d{3}[- ](.+)\z/;
		my $text = $1;
		$text =~ s/^\s+//;
		my ( $name ) = split /\s+/, $text, 2;
		next if not defined $name or $name eq '';
		$extensions{ uc $name } = 1;
	}
	return \%extensions;
}

sub _smtp_auth_mechanisms {
	my ( $lines ) = @_;

	my %mechanisms;
	for my $line ( @{ $lines // [] } ) {
		next if $line !~ /^\d{3}[- ]AUTH(?:\s+(.+))?\z/i;
		my $rest = $1 // '';
		for my $mechanism ( split /\s+/, $rest ) {
			next if $mechanism eq '';
			$mechanisms{ lc $mechanism } = 1;
		}
	}
	return \%mechanisms;
}

sub _tls_options {
	my ( $config ) = @_;

	my $verify = $config->{tls_verify} ? SSL_VERIFY_PEER : SSL_VERIFY_NONE;
	my $name = $config->{tls_server_name} // $config->{host};
	return (
		SSL_verify_mode => $verify,
		SSL_hostname => $name,
	);
}

sub _smtp_start_tls {
	my ( $sock, $config ) = @_;

	my @tls_options = _tls_options($config);
	IO::Socket::SSL->start_SSL( $sock, @tls_options )
		or _error(
			'mail.tls',
			'STARTTLS handshake failed: ' . IO::Socket::SSL::errstr(),
		);
	binmode $sock;
	$sock->autoflush(1);
	return $sock;
}

sub _smtp_auth_command {
	my ( $sock, $line ) = @_;

	return _smtp_command( $sock, $line );
}

sub _smtp_auth {
	my ( $sock, $config, $lines ) = @_;

	return if not defined $config->{username}
		and not defined $config->{password}
		and not defined $config->{auth};

	my $username = $config->{username} // '';
	my $password = $config->{password} // '';
	my $mechanisms = _smtp_auth_mechanisms($lines);
	my $mechanism = lc( $config->{auth} // '' );
	if ( $mechanism eq '' ) {
		for my $candidate ( qw( plain login xoauth2 ) ) {
			if ( $mechanisms->{$candidate} ) {
				$mechanism = $candidate;
				last;
			}
		}
		$mechanism = 'plain' if $mechanism eq '';
	}
	_error( 'mail.auth', "unsupported SMTP auth mechanism '$mechanism'" )
		if $mechanism !~ /\A(?:plain|login|xoauth2)\z/;
	_error( 'mail.auth', "SMTP server did not advertise AUTH $mechanism" )
		if %{$mechanisms} and !$mechanisms->{$mechanism};

	my ( $code, $auth_lines );
	if ( $mechanism eq 'plain' ) {
		my $token = encode_base64( "\0$username\0$password", '' );
		( $code, $auth_lines ) = _smtp_auth_command(
			$sock,
			"AUTH PLAIN $token",
		);
		_smtp_expect( 'mail.auth', [ 235 ], $code, $auth_lines, 'AUTH PLAIN' );
		return;
	}
	if ( $mechanism eq 'login' ) {
		( $code, $auth_lines ) = _smtp_auth_command( $sock, 'AUTH LOGIN' );
		_smtp_expect( 'mail.auth', [ 334 ], $code, $auth_lines, 'AUTH LOGIN' );
		( $code, $auth_lines ) = _smtp_auth_command(
			$sock,
			encode_base64( $username, '' ),
		);
		_smtp_expect( 'mail.auth', [ 334 ], $code, $auth_lines, 'AUTH username' );
		( $code, $auth_lines ) = _smtp_auth_command(
			$sock,
			encode_base64( $password, '' ),
		);
		_smtp_expect( 'mail.auth', [ 235 ], $code, $auth_lines, 'AUTH password' );
		return;
	}
	my $xoauth2 = "user=$username\001auth=Bearer $password\001\001";
	( $code, $auth_lines ) = _smtp_auth_command(
		$sock,
		'AUTH XOAUTH2 ' . encode_base64( $xoauth2, '' ),
	);
	_smtp_expect( 'mail.auth', [ 235 ], $code, $auth_lines, 'AUTH XOAUTH2' );
	return;
}

sub _run_smtp {
	my ( $config, $from, $recipients, $message, $message_id ) = @_;

	my $sock;
	if ( $config->{tls} ) {
		$sock = IO::Socket::SSL->new(
			PeerHost => $config->{host},
			PeerPort => $config->{port},
			Proto => 'tcp',
			Timeout => $config->{timeout},
			_tls_options($config),
		) or _error(
			'mail.tls',
			"could not connect to $config->{host}:$config->{port}: "
				. IO::Socket::SSL::errstr(),
		);
	}
	else {
		$sock = IO::Socket::INET->new(
			PeerHost => $config->{host},
			PeerPort => $config->{port},
			Proto => 'tcp',
			Timeout => $config->{timeout},
		) or _error(
			'mail.connection',
			"could not connect to $config->{host}:$config->{port}: $!",
		);
	}
	binmode $sock;
	$sock->autoflush(1);
	$sock->timeout( $config->{timeout} ) if $sock->can('timeout');

	my ( $code, $lines ) = _smtp_read_response($sock);
	_smtp_expect( 'mail.connection', [ 220 ], $code, $lines, 'SMTP greeting' );

	my $ehlo_name = hostname() || 'localhost';
	( $code, $lines ) = _smtp_command( $sock, "EHLO $ehlo_name" );
	my $extensions = {};
	if ( $code >= 500 ) {
		( $code, $lines ) = _smtp_command( $sock, "HELO $ehlo_name" );
		_smtp_expect( 'mail.connection', [ 250 ], $code, $lines, 'HELO' );
	}
	else {
		_smtp_expect( 'mail.connection', [ 250 ], $code, $lines, 'EHLO' );
		$extensions = _smtp_extensions($lines);
	}

	if ( $config->{starttls} ) {
		_error( 'mail.tls', 'SMTP server did not advertise STARTTLS' )
			if !$extensions->{STARTTLS};
		( $code, $lines ) = _smtp_command( $sock, 'STARTTLS' );
		_smtp_expect( 'mail.tls', [ 220 ], $code, $lines, 'STARTTLS' );
		$sock = _smtp_start_tls( $sock, $config );
		( $code, $lines ) = _smtp_command( $sock, "EHLO $ehlo_name" );
		_smtp_expect( 'mail.connection', [ 250 ], $code, $lines, 'EHLO after STARTTLS' );
		$extensions = _smtp_extensions($lines);
	}

	_smtp_auth( $sock, $config, $lines );

	if ( $config->{smtputf8} and !$extensions->{SMTPUTF8} ) {
		_error( 'mail.unsupported', 'SMTPUTF8 was requested but not advertised' );
	}

	my $mail_command = "MAIL FROM:<$from>";
	$mail_command .= ' SMTPUTF8' if $config->{smtputf8};
	( $code, $lines ) = _smtp_command( $sock, $mail_command );
	_smtp_expect( 'mail.recipient', [ 250 ], $code, $lines, 'MAIL FROM' );

	my @accepted;
	my @rejected;
	for my $recipient ( @{$recipients} ) {
		( $code, $lines ) = _smtp_command( $sock, "RCPT TO:<$recipient>" );
		if ( $code == 250 or $code == 251 or $code == 252 ) {
			push @accepted, $recipient;
		}
		else {
			push @rejected, $recipient;
		}
	}

	if ( !@accepted ) {
		eval { _smtp_command( $sock, 'QUIT' ); 1 };
		_error( 'mail.recipient', 'all recipients were rejected' );
	}
	if ( @rejected and $config->{reject_partial} ) {
		eval { _smtp_command( $sock, 'QUIT' ); 1 };
		_error( 'mail.recipient', 'one or more recipients were rejected' );
	}

	( $code, $lines ) = _smtp_command( $sock, 'DATA' );
	_smtp_expect( 'mail.data', [ 354 ], $code, $lines, 'DATA' );
	_smtp_write( $sock, _dot_stuff($message) );
	_smtp_write( $sock, "\r\n" ) if $message !~ /\r\n\z/;
	_smtp_write( $sock, ".\r\n" );
	( $code, $lines ) = _smtp_read_response($sock);
	_smtp_expect( 'mail.data', [ 250 ], $code, $lines, 'message DATA' );
	my $response = _smtp_text($lines);

	eval { _smtp_command( $sock, 'QUIT' ); 1 };
	close $sock;

	return {
		transport => 'smtp',
		accepted => \@accepted,
		rejected => \@rejected,
		message_id => $message_id,
		response => $response,
	};
}

sub _send {
	my ( $config, $from_value, $to_value, $headers, $body, $options ) = @_;

	my $send_config = _merge_config( $config, $options );
	_reject_unsupported_security_options($send_config);
	my $from = _validate_address($from_value);
	my $recipients = _recipient_list($to_value);
	_validate_envelope_ascii( $send_config, $from, @{$recipients} );
	my ( $message, $message_id ) = _serialise_message( $headers, $body );

	if ( $send_config->{transport} eq 'sendmail' ) {
		return _run_sendmail(
			$send_config,
			$from,
			$recipients,
			$message,
			$message_id,
		);
	}

	return _run_smtp(
		$send_config,
		$from,
		$recipients,
		$message,
		$message_id,
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

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $result_class = native_class(
		name => 'MailResult',
	);
	my $mailer_class = native_class(
		name => 'Mailer',
		static_methods => {
			capabilities => native_function(
				name => 'capabilities',
				native => sub {
					return _capabilities();
				},
			),
		},
	);

	$result_class->methods->{to_Dict} = native_function(
		name => 'to_Dict',
		native => sub {
			my ( $self ) = @_;
			return Zuzu::Value::Dict->new(
				map => {
					transport => $self->slots->{transport},
					accepted => $self->slots->{accepted},
					rejected => $self->slots->{rejected},
					message_id => $self->slots->{message_id},
					response => $self->slots->{response},
				},
			);
		},
	);

	$mailer_class->native_constructor( sub {
		my ( $rt, $klass, $positional, $named ) = @_;
		my $config = _normalise_config(
			_extract_config( $positional, $named ),
		);
		return native_object(
			class => $klass,
			slots => {
				_config => $config,
			},
			const => {
				_config => 1,
			},
		);
	} );

	$mailer_class->methods->{send} = native_function(
		name => 'send',
		native => sub {
			my ( $self, $from, $to, $headers, $body, $options ) = @_;
			_warn_blocking_operation( $runtime, 'std/net/smtp Mailer.send' );
			my $result = _send(
				$self->slots->{_config},
				$from,
				$to,
				$headers,
				$body,
				$options,
			);
			return _wrap_result( $result_class, $result );
		},
	);

	$mailer_class->methods->{send_async} = native_function(
		name => 'send_async',
		native => sub {
			my ( $self, $from, $to, $headers, $body, $options ) = @_;
			my $config = { %{ $self->slots->{_config} // {} } };
			return _async_task(
				$runtime,
				'smtp.send_async',
				sub {
					return _send(
						$config,
						$from,
						$to,
						$headers,
						$body,
						$options,
					);
				},
				sub {
					my ( $result ) = @_;
					return _wrap_result( $result_class, $result );
				},
			);
		},
	);

	return {
		Mailer => $mailer_class,
		MailResult => $result_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Net::SMTP - std/net/smtp bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/net/smtp> runtime-supported module. This backend
supports safe sendmail-compatible process delivery and basic plaintext
SMTP relay/submission to a configured host and port. TLS, STARTTLS, and
authentication are reported as unsupported in this implementation.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Net::SMTP >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
