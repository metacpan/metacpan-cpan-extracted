package Zuzu::Module::DNS;

use utf8;

our $VERSION = '0.001003';
our $DEFAULT_TIMEOUT = 5;

use Net::DNS ();
use Socket qw(
	AF_INET
	AF_INET6
	AF_UNSPEC
	NI_NUMERICHOST
	SOCK_STREAM
	getaddrinfo
	getnameinfo
	inet_pton
);

use Zuzu::Util::NativeHelpers qw(
	native_function
	perl_to_zuzu
);

my %SUPPORTED = map { $_ => 1 } qw(
	A
	AAAA
	CNAME
	MX
	NS
	PTR
	SRV
	TXT
);

sub _str {
	my ( $value, $default ) = @_;

	return $default if not defined $value;
	return "$value";
}

sub _resolver {
	my $resolver = Net::DNS::Resolver->new;
	for my $method ( qw( retrans retry tcp_timeout udp_timeout ) ) {
		$resolver->$method($DEFAULT_TIMEOUT) if $resolver->can($method);
	}
	return $resolver;
}

sub _record_type {
	my ( $value ) = @_;

	my $type = uc _str( $value, 'A' );
	die "DNSException: unsupported DNS record type '$type'"
		if !$SUPPORTED{$type};
	return $type;
}

sub _expect_arity {
	my ( $name, $args, $min, $max ) = @_;

	my $count = scalar @{ $args };
	return if $count >= $min and $count <= $max;

	my $range = $min == $max ? $min : "$min or $max";
	die "DNSException: $name expects $range arguments";
}

sub _no_data_error {
	my ( $error ) = @_;

	return 1 if !defined $error or $error eq '';
	return $error =~ /\A(?:NOERROR|NXDOMAIN|NODATA|NO DATA)\z/i ? 1 : 0;
}

sub _txt_strings {
	my ( $rr ) = @_;

	my @strings = map {
		defined $_ ? "$_" : ''
	} $rr->txtdata;
	return @strings;
}

sub _record_value {
	my ( $type, $rr ) = @_;

	return $rr->address if $type eq 'A' or $type eq 'AAAA';
	return $rr->cname if $type eq 'CNAME';
	return $rr->nsdname if $type eq 'NS';
	return $rr->ptrdname if $type eq 'PTR';
	return $rr->exchange if $type eq 'MX';
	return $rr->target if $type eq 'SRV';
	if ( $type eq 'TXT' ) {
		my @strings = _txt_strings($rr);
		return join '', @strings;
	}
	return "$rr";
}

sub _record_dict {
	my ( $query_name, $type, $rr ) = @_;

	my $value = _record_value( $type, $rr );
	my %out = (
		type => $type,
		name => scalar( $rr->name // $query_name ),
		value => $value,
		ttl => 0 + ( $rr->ttl // 0 ),
	);

	if ( $type eq 'A' or $type eq 'AAAA' ) {
		$out{address} = $value;
	}
	elsif ( $type eq 'CNAME' or $type eq 'NS' or $type eq 'PTR' ) {
		$out{target} = $value;
	}
	elsif ( $type eq 'MX' ) {
		$out{exchange} = $value;
		$out{preference} = 0 + $rr->preference;
	}
	elsif ( $type eq 'TXT' ) {
		my @strings = _txt_strings($rr);
		$out{text} = $value;
		$out{strings} = \@strings;
	}
	elsif ( $type eq 'SRV' ) {
		$out{target} = $value;
		$out{port} = 0 + $rr->port;
		$out{priority} = 0 + $rr->priority;
		$out{weight} = 0 + $rr->weight;
	}

	return \%out;
}

sub _lookup_records {
	my ( $name, $type_value ) = @_;

	my $query_name = _str( $name, '' );
	my $type = _record_type($type_value);
	my $resolver = _resolver();
	my $packet = $resolver->query( $query_name, $type );
	if ( !$packet ) {
		my $error = $resolver->errorstring;
		return [] if _no_data_error($error);
		die "DNSException: $error";
	}

	my @records;
	for my $rr ( $packet->answer ) {
		next if uc( $rr->type // '' ) ne $type;
		push @records, _record_dict( $query_name, $type, $rr );
	}

	return \@records;
}

sub _addresses {
	my ( $name, $family_value ) = @_;

	my $query_name = _str( $name, '' );
	my $family = lc _str( $family_value, 'any' );
	my $socket_family;
	if ( $family eq 'any' ) {
		$socket_family = AF_UNSPEC;
	}
	elsif ( $family eq 'ipv4' ) {
		$socket_family = AF_INET;
	}
	elsif ( $family eq 'ipv6' ) {
		$socket_family = AF_INET6;
	}
	else {
		die "DNSException: unsupported address family '$family'";
	}

	my ( $err, @results ) = getaddrinfo(
		$query_name,
		undef,
		{
			family => $socket_family,
			socktype => SOCK_STREAM,
		},
	);
	if ($err) {
		return [] if $err =~ /(?:Name or service not known|nodename nor servname|no address)/i;
		die "DNSException: $err";
	}

	my %seen;
	my @addresses;
	for my $result ( @results ) {
		my ( $host_err, $host ) = getnameinfo( $result->{addr}, NI_NUMERICHOST );
		next if $host_err;
		next if $seen{$host}++;
		push @addresses, $host;
	}

	return \@addresses;
}

sub _reverse_name {
	my ( $address ) = @_;

	if ( $address =~ /\A([0-9]{1,3}(?:\.[0-9]{1,3}){3})\z/ ) {
		my @octets = split /\./, $1;
		die "DNSException: invalid IPv4 address '$address'"
			if grep { $_ > 255 } @octets;
		return join( '.', reverse @octets ) . '.in-addr.arpa';
	}

	my $packed = inet_pton( AF_INET6, $address );
	if ( defined $packed ) {
		my $hex = unpack 'H*', $packed;
		return join( '.', reverse split //, $hex ) . '.ip6.arpa';
	}

	die "DNSException: invalid IP address '$address'";
}

sub _reverse {
	my ( $address_value ) = @_;

	my $address = _str( $address_value, '' );
	my $records = _lookup_records( _reverse_name($address), 'PTR' );
	return [ map { $_->{target} } @{ $records } ];
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

	return {
		lookup => native_function(
			name => 'lookup',
			native => sub {
				my @args = @_;
				_expect_arity( 'lookup()', \@args, 1, 2 );
				my ( $name, $type ) = @args;
				_warn_blocking_operation( $runtime, 'std/net/dns lookup' );
				return perl_to_zuzu(
					_lookup_records( $name, $type ),
				);
			},
		),
		lookup_async => native_function(
			name => 'lookup_async',
			native => sub {
				my @args = @_;
				_expect_arity( 'lookup_async()', \@args, 1, 2 );
				my ( $name, $type ) = @args;
				return _async_task(
					$runtime,
					'dns.lookup_async',
					sub {
						return perl_to_zuzu(
							_lookup_records( $name, $type ),
						);
					},
				);
			},
		),
		addresses => native_function(
			name => 'addresses',
			native => sub {
				my @args = @_;
				_expect_arity( 'addresses()', \@args, 1, 2 );
				my ( $name, $family ) = @args;
				_warn_blocking_operation( $runtime, 'std/net/dns addresses' );
				return perl_to_zuzu(
					_addresses( $name, $family ),
				);
			},
		),
		addresses_async => native_function(
			name => 'addresses_async',
			native => sub {
				my @args = @_;
				_expect_arity( 'addresses_async()', \@args, 1, 2 );
				my ( $name, $family ) = @args;
				return _async_task(
					$runtime,
					'dns.addresses_async',
					sub {
						return perl_to_zuzu(
							_addresses( $name, $family ),
						);
					},
				);
			},
		),
		reverse => native_function(
			name => 'reverse',
			native => sub {
				my @args = @_;
				_expect_arity( 'reverse()', \@args, 1, 1 );
				my ( $address ) = @args;
				_warn_blocking_operation( $runtime, 'std/net/dns reverse' );
				return perl_to_zuzu( _reverse($address) );
			},
		),
		reverse_async => native_function(
			name => 'reverse_async',
			native => sub {
				my @args = @_;
				_expect_arity( 'reverse_async()', \@args, 1, 1 );
				my ( $address ) = @args;
				return _async_task(
					$runtime,
					'dns.reverse_async',
					sub {
						return perl_to_zuzu(
							_reverse($address),
						);
					},
				);
			},
		),
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::DNS - std/net/dns bindings for ZuzuScript.

=head1 DESCRIPTION

Implements the C<std/net/dns> runtime-supported module.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::DNS >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
