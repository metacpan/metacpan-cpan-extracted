package Thrift::SASL::Transport;
$Thrift::SASL::Transport::VERSION = '0.006';
use strict;
use warnings;
use Data::Dumper;

# Nasty hack to make the Thrift libs handle the extra 4-bytes
# header put by GSSAPI in front of unencoded (auth only) replies

use Thrift::BinaryProtocol;
my $real_readMessageBegin = \&Thrift::BinaryProtocol::readMessageBegin;
{
    no warnings 'redefine';
    *Thrift::BinaryProtocol::readMessageBegin = \&BinaryProtocolOverride_readMessageBegin;
}

sub BinaryProtocolOverride_readMessageBegin {
    my $self = shift;
    if ( $self->{trans}{_sasl_client} && !$self->{trans}{_sasl_encode} ) {
        $self->readI32( \my $foo );    # discard GSSAPI auth header (message length)
    }
    return $real_readMessageBegin->( $self, @_ );
}

# end of nasty hack, phew.

use constant {
    SASL_START    => 1,
    SASL_OK       => 2,
    SASL_BAD      => 3,
    SASL_ERROR    => 4,
    SASL_COMPLETE => 5,
};

sub new {
    my ( $class, $transport, $sasl, $debug ) = @_;
    return bless {
        _transport => $transport,
        _sasl      => $sasl,
        _debug     => $debug || 0,
    }, $class;
}

sub _sasl_write {
    my ( $self, $code, $payload ) = @_;
    $payload //= '';
    print STDERR "<< code $code + payload (@{[bytes::length($payload)]} bytes)\n"
        if $self->{_debug};
    $self->{_transport}->write( pack "CN", $code, bytes::length($payload) );
    $self->{_transport}->write($payload);
    $self->{_transport}->flush;
}

sub _sasl_read {
    my ($self) = @_;
    my $data = $self->read(5);
    die "No data from server" unless defined $data;
    my ( $code, $length ) = unpack "CN", $data;
    if ($length) {
        $data = $self->read($length);
    }
    else {
        $data = undef;
    }
    print STDERR ">> code $code + response ($length bytes)\n"
        if $self->{_debug};
    return ( $code, $data );
}

sub open {
    my ($self) = @_;
    $self->{_transport}->open if !( $self->{_transport} && $self->isOpen );
    die "Could not open transport" if !$self->isOpen;
    return $self->{_sasl_client} || $self->_sasl_handshake;
}

sub close {
    my ($self) = @_;
    $self->{_transport}->close if $self->{_transport} && $self->isOpen;
    return 1;
}

sub _sasl_handshake {
    my ($self) = @_;

    print STDERR "SASL start: "
        if $self->{_debug};
    $self->_sasl_write( SASL_START, $self->{_sasl}->mechanism );

    # The socket passed to BufferedTransport was put in that object's
    # "transport" property, this is a bit confusing imho
    my $client = $self->{_sasl}->client_new( 'hive', $self->{_transport}{transport}{host} );
    my $resp = $client->client_start();

    my $step;
    while ( ++$step ) {
        print STDERR "SASL step $step: "
            if $self->{_debug};

        #print STDERR Dumper{map {$_ => [$client->$_()]} qw(error code mechanism need_step)};
        $self->_sasl_write( SASL_OK, $resp );
        my ( $code, $data ) = $self->_sasl_read();

        if ( $code == SASL_COMPLETE ) {
            print STDERR "Authentication OK\n"
                if $self->{_debug};

            #$client->client_step($data // '') if $client->need_step;
            last;
        }

        my $extra_msg = $self->__probe_env_and_xs_sasl_bug( $client );

        if ( $code == SASL_BAD || $code == SASL_ERROR ) {
            die sprintf "Authentication failed: %s > %s%s",
                            $code,
                            $data,
                            $extra_msg ? '. ' . $extra_msg : '',
            ;
        }

        $resp = $client->client_step($data);
        if ( ! defined $data ) {
            die sprintf 'Client rejected authentication%s',
                            $extra_msg ? '. ' . $extra_msg : '',
            ;
        }
    }

    $self->{_sasl_encode_check} = 1;
    $self->{_sasl_client}       = $client;

    return $self->{_sasl_client};
}

sub __probe_env_and_xs_sasl_bug {
    # See: https://github.com/Perl-Hadoop/Thrift-SASL/issues/1
    #
    my($self, $client) = @_;
    return if      ! $client->isa('Authen::SASL::XS')
                && ! $client->isa('Authen::SASL::Cyrus')
    ;

    return if exists $ENV{USER} || exists $ENV{USERNAME};

    my $sasl_class = ref $client;

    return join ' ',
        "cyrus-sasl and in turn $sasl_class needs either USER or USERNAME",
        'environment variable to be present and they seem to be missing',
        'in your environment.',
        'The error you have received might be caused by that.',
    ;
}

sub write {
    my $self   = shift;
    my $buffer = shift;
    print STDERR "<< writing " . bytes::length($buffer) . " bytes\n"
        if $self->{_debug} > 1;
    $self->{_out_buffer} .= $buffer;
    return 1;
}

sub read {
    my $self          = shift;
    my @passthru_args = @_;
    print STDERR ">> reading\n"
        if $self->{_debug};
    my $buf = $self->{_transport}->read(@passthru_args);
    return $buf if bytes::length($buf) > 0;

    # not sure about this, it is copied over from the python version
    $self->_read_frame();
    return $self->{_transport}->read(@passthru_args);
}

# completely unsure about this, taken from the python version when trying to
# make the whole thing work, turned out my problem was with the BinaryProtocol
# needing a 4-byte offset on readMessageBegin as kerberos auth adds a 4 bytes
# header to replies, which was mistakenly used as the expected thrift header.
# leaving this in place in case it is actually needed (probably not working
# in the current state though)
sub _read_frame {
    my $self   = shift;
    my $header = $self->{_transport}->readAll(4);
    my $length = unpack( "N", $header );
    my $decoded;
    if ( $self->{_sasl_encode} ) {
        my $encoded = $header . $self->{_transport}->readAll($length);
        my $decoded = $self->{_sasl_client}->decode($encoded)
            or die 'SASL decode returned nothing';

        # TODO throw a real per TTransportException like the python version
        #die "SASL decode error: " .
        #  raise TTransportException(type=TTransportException.UNKNOWN,
        #                            message=self.sasl.getError())
    }
    else {
        $decoded = $self->{_transport}->readAll($length);
    }
    $self->{_transport}{rBuf} = $decoded;
}

sub flush {
    my $self = shift;

    print STDERR "<<< flush " . bytes::length( $self->{_out_buffer} ) . " bytes \n"
        if $self->{_debug};

    if ( $self->{_sasl_encode_check} ) {
        my $encoded = $self->{_sasl_client}->encode( $self->{_out_buffer} );
        if (   bytes::length($encoded)
            && bytes::length($encoded) != bytes::length( $self->{_out_buffer} ) )
        {
            $self->{_sasl_encode} = 1;
            print STDERR "GSSAPI Will encode from now on\n" if $self->{_debug};
        }
        else {
            $self->{_sasl_encode} = 0;
            print STDERR "GSSAPI Will *not* encode from now on\n" if $self->{_debug};
        }
        $self->{_sasl_encode_check} = undef;
    }
    if ( $self->{_sasl_encode} ) {
        $self->{_out_buffer} = $self->{_sasl_client}->encode( $self->{_out_buffer} );
    }
    else {
        $self->{_out_buffer}
            = pack( "N", bytes::length( $self->{_out_buffer} ) ) . $self->{_out_buffer};
    }
    $self->{_transport}->write( $self->{_out_buffer} );
    $self->{_transport}->flush();
    $self->{_out_buffer} = '';

    #print STDERR Dumper $self;
}

sub isOpen {
    shift->{_transport}->isOpen(@_);
}

sub readAll {
    my $self = shift;
    print STDERR ">>> readAll $_[0] bytes\n"
        if $self->{_debug} > 1;
    my $ret = $self->{_transport}->readAll(@_);
    return $ret;
}

1;

#ABSTRACT: Thrift Transport allowing Kerberos auth/encryption through GSSAPI

__END__

=pod

=encoding UTF-8

=head1 NAME

Thrift::SASL::Transport - Thrift Transport allowing Kerberos auth/encryption through GSSAPI

=head1 VERSION

version 0.006

=head1 SYNOPSIS

run kinit first for getting your credentials cache in order, then (example for
communicating with a secure HiveServer2 instance):

    use Authen::SASL qw(XS);
    my $sasl = Authen::SASL->new( mechanism => 'GSSAPI');

    use Thrift::Socket;
    use Thrift::BufferedTransport;
    use Thrift::SASL::Transport;
    use Thrift::API::HiveClient2;

    my $socket = Thrift::Socket->new( $srv_host, 10000 );
    my $strans = Thrift::SASL::Transport->new(
        Thrift::BufferedTransport->new($socket),
        $sasl,
        $debuglevel
    );

    my $hive = Thrift::API::HiveClient2->new(
        _socket    => $socket,
        _transport => $strans,
    );

=head1 DESCRIPTION

Add SASL support to Apache's Thrift, in order to support Kerberos auth, among
others. Highly experimental and hack-ish. Ideally this should be part of the
Thrift distribution, once proven to work reliably.

=head1 ACKNOWLEDGEMENTS

Based on the pyhs2 python module by Brad Ruderman L<https://github.com/BradRuderman/pyhs2>

Initial version with simple SASL authentication (LDAP) developped by Vikentiy Fesunov at Booking.com

Thanks to my employer Booking.com to allow me to release this module for public use

=for Pod::Coverage BinaryProtocolOverride_readMessageBegin

=for Pod::Coverage close

=for Pod::Coverage flush

=for Pod::Coverage isOpen

=for Pod::Coverage new

=for Pod::Coverage open

=for Pod::Coverage read

=for Pod::Coverage readAll

=for Pod::Coverage write

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
