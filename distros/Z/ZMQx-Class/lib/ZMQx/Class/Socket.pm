package ZMQx::Class::Socket;
use strict;
use warnings;
use 5.010;

# ABSTRACT: A ZMQ Socket

use Moose;
use Carp qw(croak carp confess);
use namespace::autoclean;
use Package::Stash;
use Encode qw//;

use ZMQ::FFI;
use ZMQ::Constants ':all';

use Log::Any qw($log);

use constant MAX_LAZY_PIRATE_TRIES => 4;

# TODO
# has 'bind_or_connect',
# has 'address',

has '_init_opts_for_cloning' =>
    ( is => 'ro', isa => "ArrayRef", default => sub { [] } );

has '_socket' => (
    is       => 'rw',
    isa      => 'ZMQ::FFI::SocketBase',
    required => 1,
);

has 'type' => (
    is       => 'ro',
    required => 1,
);

has '_connected' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has '_pid' => ( is => 'rw', isa => 'Int', required => 1 );


sub socket {
    my ($self) = @_;
    if ( $$ != $self->_pid ) {

        # TODO instead of init_opts_for_cloning get stuff required to re-initate via getsockopt etc
        my ( $class, @call ) = @{ $self->_init_opts_for_cloning };
        my $socket = $class->socket(@call);

        $self->_socket( $socket->socket );
        $self->_pid( $socket->_pid );
    }
    return $self->_socket;
}


sub bind {
    my ( $self, $address ) = @_;

    eval { $self->socket->bind($address); };
    if ($@) {
        croak "Cannot bind $@";
    }

    return $self->_connected(1);
}


sub connect {
    my ( $self, $address ) = @_;

    eval { $self->socket->connect($address); };
    if ($@) {
        croak "Cannot connect $@";
    }

    return $self->_connected(1);

}


sub setsockopt {
    my ( $self, $constval, @args ) = @_;

    my $sockopt_type = ZMQ::Constants::get_sockopt_type($constval);
    return $self->socket->set( $constval, $sockopt_type, @args );

}


sub getsockopt {
    my ( $self, $constval ) = @_;

    my $sockopt_type = ZMQ::Constants::get_sockopt_type($constval);
    return $self->socket->get( $constval, $sockopt_type );

}


# receive deals in strings, receive_bytes deals with bytes.
# therefore send deals with strings.
# TODO - can't we send in encodings other than UTF-8

sub _send_string_utf8 {
    my ( $self, undef, $flags ) = @_;

    # Explicitly avoiding copying the string we send, and these "conversions"
    # are in place and a NO-OP on a string that is already internally UTF-8.

    # ZMQ::FFI doesn't return anything useful from send(), so we need to fake
    # things to preserve our documented return value.
    # If ZMQ::FFI doesn't want to change send to return the value, then
    # probably we should simply deprecate returning the length, and return
    # a value that is truthful.

    my $length = utf8::upgrade( $_[1] );
    for my $cnt ( 1 .. MAX_LAZY_PIRATE_TRIES ) {
        my $ok = eval {

            # Convert to the UTF-8 representation of the Unicode characters.
            # It's actually just flipping a flag bit.
            utf8::encode( $_[1] );
            $self->socket->send( $_[1], $flags );

            # Flip it back:
            utf8::decode( $_[1] );
            1;
        } or do {
            if ( $cnt < 4 && $self->_lazy_pirate ) {
                next;
            }
            confess "Message: " . $@;
        };
        last if $ok;
    }
    return $length;
}

sub send {
    my ( $self, $parts, $flags ) = @_;
    my $length = 0;

    # ZMQ::FFI chooses to deal in bytes only:
    # https://github.com/calid/zmq-ffi/pull/5
    # so as we are talking strings we need to deal with the encoding ourselves.
    # As we have steps to do both before and after the call to the ZMQ send,
    # we would need *two* loops locally if we called send_multipart. So it's
    # actually less work for us to deal with all the looping ourselves.
    if ( ref $parts ) {
        $flags //= 0;
        foreach ( 0 .. $#{$parts} - 1 ) {
            $length +=
                $self->_send_string_utf8( $parts->[$_],
                $flags | ZMQ_SNDMORE );
        }
        $parts = $parts->[ $#{$parts} ];

        # Fall through to the simple case.
    }

    return $length + $self->_send_string_utf8( $parts, $flags );
}


sub send_bytes {
    my ( $self, $parts, $flags ) = @_;

    my $length = 0;

    if ( !ref($parts) ) {
        $parts = [$parts];
    }

    foreach ( 0 .. $#{$parts} ) {
        croak("send_bytes() message (part $_) is not bytes")
            unless utf8::downgrade( $parts->[$_], 1 );
        $length += length $parts->[$_];
    }
    for my $cnt ( 1 .. MAX_LAZY_PIRATE_TRIES ) {
        my $ok = eval {
            $self->socket->send_multipart( $parts, $flags );
            1;
        } or do {
            if ( $cnt < 4 && $self->_lazy_pirate ) {
                next;
            }
            confess "Message: " . $@;
        };
        last if $ok;
    }

    return $length;
}

sub _lazy_pirate {
    my $self = shift;
    return if $self->_can_send;

    $log->warnf(
        "Socket is in bad state, reconnect via Lazy Pirate [pid: %i, name: %s]",
        $$, $0
    );
    my ( $class, @call ) = @{ $self->_init_opts_for_cloning };
    my $socket = $class->socket(@call);
    $self->_socket( $socket->socket );
    return 1;
}

sub _can_send {
    my $self = shift;
    return $self->socket->has_pollout == 2 ? 1 : 0;
}

sub _message_available {
    my $self = shift;
    return $self->socket->has_pollin == 1 ? 1 : 0;
}

sub receive_multipart {
    my $rv = receive(@_);
    carp 'DEPRECATED! Use $socket->receive() instead';
    *{receive_multipart} = *{receive} unless $ENV{HARNESS_ACTIVE};
    return $rv;
}


sub receive {
    my ( $self, $blocking ) = @_;

    return $self->receive_string($blocking);
}


sub receive_bytes {
    my ( $self, $blocking ) = @_;

    my $flags = $blocking ? 0 : ZMQ_DONTWAIT;

    my @parts;
    eval { @parts = $self->socket->recv_multipart($flags); };
    if ($@) {
        return;
    }
    elsif (@parts) {
        return \@parts;
    }
    return;

}


sub receive_string {
    my ( $self, $blocking, $encoding ) = @_;

    $encoding ||= 'utf-8';

    my $bytes_multi = $self->receive_bytes($blocking);

    return unless $bytes_multi;

    my $str;
    if ( $encoding eq 'utf-8' ) {

        $str = $self->_receive_string_utf8($bytes_multi);

    }
    else {

        $str = $self->_receive_string_generic( $bytes_multi, $encoding );

    }

    if (@$str) {
        return $str;
    }

    return;

}

sub _receive_string_generic {
    my ( $self, $ref, $encoding ) = @_;

    my @parts;
    foreach ( 0 .. $#{$ref} ) {
        push( @parts, Encode::decode( $encoding, shift(@$ref) ) );
    }
    return \@parts;
}

sub _receive_string_utf8 {
    my ( $self, $ref ) = @_;

    if ( ref $ref eq 'ARRAY' ) {
        foreach ( 0 .. $#{$ref} ) {
            Encode::_utf8_on( $ref->[$_] );
        }
    }

    return $ref;
}

sub subscribe {
    my ( $self, $subscribe ) = @_;
    croak('$socket->subscribe only works on SUB sockets')
        unless $self->type =~ /^X?SUB$/;
    croak('required parameter $subscription missing')
        unless defined $subscribe;

    $self->socket->subscribe($subscribe);
}

sub get_fh {
    carp 'DEPRECATED! Use $socket->get_fd() instead';
    my $rv = get_fd(@_);
    *{get_fh} = *{get_fd};
    return $rv;
}

sub get_fd {
    my $self = shift;
    return $self->socket->get_fd();
}

{
    no strict 'refs';
    my @sockopts_before_connect = qw(
        ZMQ_AFFINITY
        ZMQ_BACKLOG
        ZMQ_EVENTS
        ZMQ_IDENTITY
        ZMQ_IPV4ONLY
        ZMQ_LAST_ENDPOINT
        ZMQ_MAXMSGSIZE
        ZMQ_MULTICAST_HOPS
        ZMQ_RATE
        ZMQ_RCVBUF
        ZMQ_RCVHWM
        ZMQ_RCVTIMEO
        ZMQ_RECONNECT_IVL
        ZMQ_RECONNECT_IVL_MAX
        ZMQ_RECOVERY_IVL
        ZMQ_SNDBUF
        ZMQ_SNDHWM
        ZMQ_SNDTIMEO
        ZMQ_TYPE
    );

    my @sockopts_after_connect = qw(

        ZMQ_LINGER
        ZMQ_PROBE_ROUTER
        ZMQ_REQ_CORRELATE
        ZMQ_REQ_RELAXED
        ZMQ_ROUTER_MANDATORY
        ZMQ_SUBSCRIBE
        ZMQ_UNSUBSCRIBE
        ZMQ_XPUB_VERBOSE

    );

    my $stash = Package::Stash->new(__PACKAGE__);
    foreach my $const (@sockopts_before_connect) {
        _setup_sockopt_helpers( $const, $stash, 1 );
    }
    foreach my $const (@sockopts_after_connect) {
        _setup_sockopt_helpers( $const, $stash, 0 );
    }

}

sub _setup_sockopt_helpers {
    my ( $const, $stash, $set_only_before_connect ) = @_;
    my $get = my $set = lc($const);
    $set =~ s/^zmq_/set_/;
    $get =~ s/^zmq_/get_/;

    no strict 'refs';

    if ( $stash->has_symbol( '&' . $const ) ) {

        my $constval     = &$const;
        my $sockopt_type = ZMQ::Constants::get_sockopt_type($constval)
            or die "$const sockopt type not found";

        #        warn "$get -> $sockopt_type for $const";
        #        use Data::Dumper;
        #        warn Data::Dumper::Dumper(\%ZMQ::Constants::SOCKOPT_MAP);

        if ($set_only_before_connect) {
            $stash->add_symbol(
                '&' . $set => sub {
                    my $self = shift;
                    if ( $self->_connected ) {
                        carp
                            "Setting '$const' only works before connect/bind. Value not stored!";
                    }
                    else {
                        $self->socket->set( $constval, $sockopt_type, @_ );
                    }
                    return $self;
                }
            );
        }
        else {
            $stash->add_symbol(
                '&' . $set => sub {
                    my $self = shift;
                    $self->socket->set( $constval, $sockopt_type, @_ );
                    return $self;
                }
            );
        }

        $stash->add_symbol(
            '&' . $get => sub {
                my $self = shift;
                return $self->socket->get( $constval, $sockopt_type );
            }
        );
    }
}


sub anyevent_watcher {
    my ( $socket, $callback ) = @_;
    my $fd      = $socket->get_fd;
    my $watcher = AnyEvent->io(
        fh   => $fd,
        poll => "r",
        cb   => $callback
    );
    return $watcher;
}

sub close {
    my $self = shift;

    # warn "$$ CLOSE SOCKET";
    unless ($self->socket->_socket == -1) {
        $self->socket->close();
    }
}

# Not needed here as the socket is closed in ZMQ::FFI::SocketBase::DEMOLISH
# sub DESTROY {
#     my $self = shift;
#     return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
#     warn "$$ IN SOCKET DESTROY";
#     $self->socket->close();
# }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::Class::Socket - A ZMQ Socket

=head1 VERSION

version 0.006

=head1 METHODS

=head2 socket

    $socket->socket;

Returns the underlying C<ZMQ::FFI::SocketBase> socket. You probably won't need
to call this method yourself.

When a process containg a socket is forked, a new instance of the socket will
be set up for the child process.

=head2

    $socket->bind( $address );

Bind a socket to an address. Use this for the "server" side, which usually is
the more stable part of your infrastructure.

C<bind> will C<die> if it cannot bind.

=head2 connect

    $socket->connect( $address );

Connect the socket to an address. Use this for the "client" side.

C<connect> will C<die> if it cannot connect.

=head2 setsockopt

    use ZMQ::Constants qw( ZMQ_LINGER );
    $socket->setsockopt( ZMQ_LINGER, 100 );

Set a socket options using a constant. You will need to load the constant from
C<ZMQ::Constants>.

=head2 getsockopt

    use ZMQ::Constants qw( ZMQ_LINGER );
    $socket->getsockopt( ZMQ_LINGER );

Get a socket option value using a constant. You will need to load the constant
from C<ZMQ::Constants>.

=head2 send

    my $rv = $socket->send( \@message );
    my $rv = $socket->send( \@message, ZMQ_DONTWAIT );
    my $rv = $socket->send( $message );

Send a message over the socket.

The message can either be a plain string or an ARRAYREF which will be
send as a multipart message (with one message per array element).
C<send> will automatically set C<ZMQ_SENDMORE> for multipart messages.

You can pass flags to C<send>. Currently the only flag is C<ZMQ_DONTWAIT>.

C<send> returns the number of bytes sent in the message, and throws an
exception on error.

=head2 send_bytes

    $socket->send_bytes( \@message );
    $socket->send_bytes( \@message, ZMQ_DONTWAIT );
    $socket->send_bytes( $message );

C<send_bytes> sends raw bytes over the socket. The message can be a plain
scalar or an array of scalars. All must hold bytes - ie code points between
0 and 255. If you want strings you should either encode from Unicode yourself
first, or use send() instead. You probably need to use C<send_bytes> if you
are sending multi-part messages with ZMQ routing information.

=head2 receive

    my $msg = $socket->receive;
    my $msg = $socket->receive('blocking;);

C<receive> will get the next message from the socket, if there is one.

You can use the blocking mode (by passing a true value to C<receive>) to block
the process until a message has been received (NOT a wise move if you are
connected to a lot of clients! Use AnyEvent in this case)

The message will always be a ARRAYREF containing one element per message part.

Returns C<undef> if no message can be received.

See t/30_anyevent.t for some examples

NOTE: If more than one message is waiting to be received you still only get one
AnyEvent notification, using receive in a while loop will get you all messages.

=head2 receive_bytes

    my $msg = $socket->receive_bytes;
    my $msg = $socket->receive_bytes('blocking;);

C<receive_bytes> will get the next message from the socket as bytes. If you
want to receive a String (unicode), then you want to use C<receive_string>.

=head2 receive_string

    my $msg = $socket->receive_string
    my $msg = $socket->receive_string('blocking');

    my $msg = $socket->receive_string($blocking, [ $encoding ]);

Receive a String message and decode it via L<Encode::decode('utf8', XX)> or an
optional encoding.  Sending data over a wire means sending bytes.  Bytes do
not know anything about encoding. If you want to send encoded strings, use
this L<receive_string> method to L<receive> them correctly.

If you want to use an explicit encoding you need to set the C<$blocking>
variable to true or false.

=head2 anyevent_watcher

  my $watcher = $socket->anyevent_watcher( sub {
      while (my $msg = $socket->receive) {
          # do something with msg
      }
  } );

Set up an AnyEvent watcher that will call the passed sub when a new
incoming message is received on the socket.

Note that the C<$socket> object isn't passed to the callback. You can only
access the C<$socket> thanks to closures.

Please note that you will have to load C<AnyEvent> in your code!

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
