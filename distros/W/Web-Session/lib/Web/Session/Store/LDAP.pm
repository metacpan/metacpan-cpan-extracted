package Web::Session::Store::LDAP;

use strict;
use Net::LDAP;

our $VERSION = '1.0.0';

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {}, $class;
    $self->{args} = $args if ( ref($args) eq 'HASH' );
    return $self;
}

sub insert {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};
    $self->{args}->{ldapObjectClass}      ||= 'applicationProcess';
    $self->{args}->{ldapAttributeId}      ||= 'cn';
    $self->{args}->{ldapAttributeContent} ||= 'description';
    $self->{args}->{ldapAttributeIndex}   ||= 'ou';

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];
    my $id = $session->{data}->{_session_id};

    my $attrIndex;
    foreach my $i (@$index) {
        my $t;
        next unless ( $t = $session->{data}->{$i} );
        push @$attrIndex, "${i}_$t";
    }
    my $attrs = [
        objectClass                      => $self->{args}->{ldapObjectClass},
        $self->{args}->{ldapAttributeId} => $session->{data}->{_session_id},
        $self->{args}->{ldapAttributeContent} => $session->{serialized},
    ];
    push @$attrs, ( $self->{args}->{ldapAttributeIndex} => $attrIndex )
      if ($attrIndex);

    my $msg = $self->ldap->add(
        $self->{args}->{ldapAttributeId} . "=$id,"
          . $self->{args}->{ldapConfBase},
        attrs => $attrs,
    );

    $self->ldap->unbind() && delete $self->{ldap};
    $self->logError($msg) if ( $msg->code );
}

sub update {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};
    $self->{args}->{ldapObjectClass}      ||= 'applicationProcess';
    $self->{args}->{ldapAttributeId}      ||= 'cn';
    $self->{args}->{ldapAttributeContent} ||= 'description';
    $self->{args}->{ldapAttributeIndex}   ||= 'ou';

    my $index =
      ref( $session->{args}->{Index} )
      ? $session->{args}->{Index}
      : [ split /\s+/, $session->{args}->{Index} ];
    my $id = $session->{data}->{_session_id};

    my $attrIndex;
    foreach my $i (@$index) {
        my $t;
        next unless ( $t = $session->{data}->{$i} );
        push @$attrIndex, "${i}_$t";
    }

    my $attrs =
      { $self->{args}->{ldapAttributeContent} => $session->{serialized} };
    $attrs->{ $self->{args}->{ldapAttributeIndex} } = $attrIndex
      if ($attrIndex);

    my $msg = $self->ldap->modify(
        $self->{args}->{ldapAttributeId} . "="
          . $session->{data}->{_session_id} . ","
          . $self->{args}->{ldapConfBase},
        replace => $attrs,
    );

    $self->ldap->unbind() && delete $self->{ldap};
    $self->logError($msg) if ( $msg->code );
}

sub materialize {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};
    $self->{args}->{ldapObjectClass}      ||= 'applicationProcess';
    $self->{args}->{ldapAttributeId}      ||= 'cn';
    $self->{args}->{ldapAttributeContent} ||= 'description';
    $self->{args}->{ldapAttributeIndex}   ||= 'ou';

    my $msg = $self->ldap->search(
        base => $self->{args}->{ldapAttributeId} . "="
          . $session->{data}->{_session_id} . ","
          . $self->{args}->{ldapConfBase},
        filter => '(objectClass=' . $self->{args}->{ldapObjectClass} . ')',
        scope  => 'base',
        attrs  => [ $self->{args}->{ldapAttributeContent} ],
    );

    $self->ldap->unbind() && delete $self->{ldap};
    $self->logError($msg) if ( $msg->code );

    eval {
        $session->{serialized} = $msg->shift_entry()
          ->get_value( $self->{args}->{ldapAttributeContent} );
    };

    if ( !defined $session->{serialized} ) {
        die "Object does not exist in data store";
    }
}

sub remove {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};
    $self->{args}->{ldapObjectClass}      ||= 'applicationProcess';
    $self->{args}->{ldapAttributeId}      ||= 'cn';
    $self->{args}->{ldapAttributeContent} ||= 'description';
    $self->{args}->{ldapAttributeIndex}   ||= 'ou';

    $self->ldap->delete( $self->{args}->{ldapAttributeId} . "="
          . $session->{data}->{_session_id} . ","
          . $self->{args}->{ldapConfBase} );

    $self->ldap->unbind() && delete $self->{ldap};
}

sub ldap {
    my $self = shift;
    return $self->{ldap} if $self->{ldap};

    my @servers = $self->_parseServers;

    # Connect: first reachable server wins
    my ( $ldap, $srv, @errors );
    foreach my $s (@servers) {
        $ldap = Net::LDAP->new(
            $s->{server},
            onerror   => undef,
            keepalive => 1,
            %{ $s->{tlsParams} },
            (
                $self->{args}->{ldapRaw} ? ( raw => $self->{args}->{ldapRaw} )
                : ()
            ),
            (
                $self->{args}->{ldapPort}
                ? ( port => $self->{args}->{ldapPort} )
                : ()
            ),
            (
                $self->{args}->{ldapTimeout}
                ? ( timeout => $self->{args}->{ldapTimeout} )
                : ()
            ),
        );
        if ($ldap) {
            $srv = $s;
            last;
        }
        push @errors, "$s->{server}: " . ( $@ || 'unknown error' );
    }
    die(    'Unable to connect to '
          . join( ' ', map { $_->{server} } @servers ) . ": "
          . join( ', ', @errors ) )
      unless $ldap;

    # Check SSL error for old Net::LDAP versions
    if ( $Net::LDAP::VERSION < '0.64' ) {

        # CentOS7 has a bug in which IO::Socket::SSL will return a broken
        # socket when certificate validation fails. Net::LDAP does not catch
        # it, and the process ends up crashing.
        # As a precaution, make sure the underlying socket is doing fine.
        #
        # Note: IO::Socket::SSL may retain a stale or unrelated error message
        # (for example, "SSL wants a read first"), which can cause this check
        # to fail even when the socket is healthy. This workaround is only
        # required for older Net::LDAP versions (< 0.64).
        if (    $ldap->socket->isa('IO::Socket::SSL')
            and $ldap->socket->errstr )
        {
            die "SSL connection error: " . $ldap->socket->errstr;
        }
    }

    # Start TLS if needed
    if ( $srv->{startTls} ) {
        my $mesg = $ldap->start_tls( %{ $srv->{tlsParams} } );
        if ( $mesg->code ) {
            $self->logError($mesg);
        }
    }

    # I/O timeouts (set on the final socket, after StartTLS)
    if ( my $timeout = $self->{args}->{ldapIOTimeout} ) {
        eval { require IO::Socket::Timeout; };
        if ($@) {
            die( 'IO::Socket::Timeout is required for ldapIOTimeout: ' . $@ );
        }
        my $socket = $ldap->socket;
        IO::Socket::Timeout->enable_timeouts_on($socket);
        $socket->read_timeout($timeout);
        $socket->write_timeout($timeout);
    }

    # Bind
    my $bind = $self->_bind( $ldap, $srv->{tlsParams} );
    if ( $bind->code ) {
        $self->logError($bind);
    }

    $self->{ldap} = $ldap;
    return $ldap;
}

my @tlsKeys = qw(verify sslversion ciphers clientcert clientkey keydecrypt
  capath cafile checkcrl sslserver);

sub _parseServers {
    my $self = shift;
    my $args = $self->{args};

    # Global defaults (compatibility: caFile/caPath)
    my %defaults = (
        cafile     => $args->{ldapCAFile} || $args->{caFile},
        capath     => $args->{ldapCAPath} || $args->{caPath},
        verify     => $args->{ldapVerify} || 'require',
        clientcert => $args->{ldapClientCert},
        clientkey  => $args->{ldapClientKey},
    );

    my @servers;
    foreach my $server ( split /[\s,]+/, $args->{ldapServer} ) {
        next unless length $server;
        my ( $startTls, $query ) = ( 0, '' );
        if ( $server =~ m{^ldap\+tls://([^/?]+)/?\??(.*)$} ) {
            ( $server, $query, $startTls ) = ( $1, $2, 1 );
        }
        elsif ( $server =~ m{^(ldaps://[^/?]+)/?\??(.*)$} ) {
            ( $server, $query ) = ( $1, $2 );
        }

        my %urlParams;
        foreach ( split /&/, $query ) {
            my ( $k, $v ) = split /=/, $_, 2;
            $urlParams{$k} = $v if defined $k;
        }

        my %tlsParams;
        foreach my $k (@tlsKeys) {
            my $v =
              ( defined $urlParams{$k} and length $urlParams{$k} )
              ? $urlParams{$k}
              : $defaults{$k};
            $tlsParams{$k} = $v if defined $v and length $v;
        }
        push @servers,
          {
            server    => $server,
            startTls  => $startTls,
            tlsParams => \%tlsParams,
          };
    }
    return @servers;
}

sub _bind {
    my ( $self, $ldap, $tlsParams ) = @_;
    my $dn = $self->{args}->{ldapBindDN};

    # Simple bind
    if ( defined $dn and length $dn ) {
        return $ldap->bind( $dn,
            password => $self->{args}->{ldapBindPassword} );
    }

    # mTLS: SASL EXTERNAL
    elsif ( $ldap->socket->isa('IO::Socket::SSL') and $tlsParams->{clientcert} )
    {
        eval { require Authen::SASL; };
        if ($@) {
            die( 'Authen::SASL is required for EXTERNAL binding: ' . $@ );
        }
        my $sasl = Authen::SASL->new(
            mechanism => 'EXTERNAL',
            callback  => { user => '' }
        );
        return $ldap->bind( undef, sasl => $sasl );
    }

    # Anonymous
    else {
        return $ldap->bind();
    }
}

sub logError {
    my $self           = shift;
    my $ldap_operation = shift;
    die "LDAP error " . $ldap_operation->code . ": " . $ldap_operation->error;
}

1;

=pod

=encoding utf8

=head1 NAME

Web::Session::Store::LDAP - Use LDAP to store persistent objects

=head1 SYNOPSIS

 use Web::Session::Store::LDAP;

 my $store = new Web::Session::Store::LDAP;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of Apache::Session.  The serialized
objects are stored in an LDAP directory file using the Net::LDAP Perl module.

=head1 OPTIONS

Required: B<ldapServer> and B<ldapConfBase>. All others are optional.

Example:

 tie %s, 'Web::Session::LDAP', undef,
    {
        ldapServer           => 'ldaps://ldap.example.com/?verify=require',
        ldapConfBase         => 'ou=sessions,dc=example,dc=com',
        ldapBindDN           => 'cn=admin,dc=example,dc=com',
        ldapBindPassword     => 'pass',
        Index                => 'uid ipAddr',
    };

=over

=item ldapServer

Space or comma separated list of servers, tried in order (failover). Each
entry is one of:

 host[:port] | ldap://host[:port]
 ldaps://host[:port][/?params]
 ldap+tls://host[:port][/?params]      (StartTLS)

C<params> is a C<key=value&...> list of TLS options overriding the global ones
for this server. Allowed keys: verify, sslversion, ciphers, clientcert,
clientkey, keydecrypt, capath, cafile, checkcrl, sslserver. Other keys are
ignored.

=item ldapConfBase

DN under which sessions are stored.

=item ldapBindDN, ldapBindPassword

Credentials for a simple bind. Without ldapBindDN, the connection binds with
SASL EXTERNAL if it uses TLS with a client certificate, anonymously otherwise.

=item ldapVerify

Server certificate verification: C<none>, C<optional> or C<require> (default).

=item ldapCAFile, ldapCAPath

CA file/directory used to verify the server certificate.

=item ldapClientCert, ldapClientKey

Client certificate and key (PEM) for mutual TLS. The key may be omitted if
included in the certificate file. SASL EXTERNAL requires L<Authen::SASL>.

=item ldapTimeout

Connection timeout (seconds).

=item ldapIOTimeout

Read/write timeout (seconds). Requires L<IO::Socket::Timeout>.

=item ldapPort

Default port.

=item ldapRaw

Regex of attributes returned as raw binary (see L<Net::LDAP>).

=item ldapObjectClass, ldapAttributeId, ldapAttributeContent, ldapAttributeIndex

Object class (default C<applicationProcess>) and attributes used for the
session id (C<cn>), serialized content (C<description>) and indexes (C<ou>).

=back

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=item 2026 by Christophe Maudoux

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Apache::Session>

=cut
