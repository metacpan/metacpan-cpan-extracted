package Unblock::HTTP::QUIC;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(refaddr blessed);

our $VERSION = '0.02';

sub client { return shift->_new('Client', @_); }
sub server { return shift->_new('Server', @_); }

sub _new {
    my ($class, $role, @args) = @_;
    croak 'client()/server(): expected named arguments' if @args % 2;
    my %option = @args;

    my $on_ready = delete $option{on_ready};
    croak 'on_ready must be a coderef'
        if defined($on_ready) && ref($on_ready) ne 'CODE';

    my ($server, $http3);
    if ($role eq 'Server') {
        $server = delete $option{server};
        croak 'server(): server must be a reusable Unblock::HTTP::Server'
            unless blessed($server) && $server->isa('Unblock::HTTP::Server');
        croak 'server(): HTTP/3 is disabled on the Server definition'
            unless $server->supports('h3');
        for my $reserved (qw(http3 on_headers on_request on_body on_request_end on_error)) {
            croak "server(): configure $reserved on the Server definition"
                if exists $option{$reserved};
        }
        $http3 = {};
    } else {
        croak 'client(): server is not a client option' if exists $option{server};
        $http3 = exists($option{http3}) ? delete $option{http3} : {};
        croak 'http3 must be a hash reference' unless ref($http3) eq 'HASH';
        $http3 = { %$http3 };
        for my $reserved (qw(quic transport protocol alpn)) {
            croak "http3 option '$reserved' is managed by Unblock::HTTP::QUIC"
                if exists $http3->{$reserved};
        }
    }

    my $alpn = delete $option{alpn};
    croak "Only the h3 ALPN is supported by Unblock::HTTP::QUIC"
        if defined($alpn) && $alpn ne 'h3';
    $option{alpn} = 'h3';

    require Net::QUIC::Driver;
    my $driver = $role eq 'Client'
        ? Net::QUIC::Driver->client(%option)
        : Net::QUIC::Driver->server(%option);

    return bless {
        role     => $role,
        driver   => $driver,
        http3    => $http3,
        server   => $server,
        on_ready => $on_ready,
        sessions => {},
        client_id => undef,
    }, $class;
}

sub driver { return $_[0]{driver}; }

sub start {
    my ($self) = @_;
    $self->{driver}->start;
    $self->_progress;
    return $self;
}

sub receive {
    my ($self, @arg) = @_;
    $self->{driver}->receive(@arg);
    $self->_progress;
    return;
}

sub timeout {
    my ($self) = @_;
    $self->{driver}->timeout;
    $self->_progress;
    return;
}

sub writable {
    my ($self) = @_;
    $self->{driver}->writable;
    $self->_progress;
    return;
}

sub session {
    my ($self) = @_;
    croak 'session(): only valid for a client QUIC manager'
        unless $self->{role} eq 'Client';
    my $id = $self->{client_id};
    return defined($id) && exists($self->{sessions}{$id})
        ? $self->{sessions}{$id}{http} : undef;
}

sub sessions {
    my ($self) = @_;
    return grep { defined $_ } map { $_->{http} } values %{ $self->{sessions} };
}

sub _remember {
    my ($self, $quic) = @_;
    return unless defined $quic;
    my $id = refaddr($quic);
    $self->{sessions}{$id} ||= { quic => $quic, http => undef };
    $self->{client_id} = $id if $self->{role} eq 'Client';
    return;
}

sub _progress {
    my ($self) = @_;
    my $driver = $self->{driver};

    if ($self->{role} eq 'Client') {
        $self->_remember($driver->connection);
    } else {
        while (my $quic = $driver->next_connection) {
            $self->_remember($quic);
        }
    }

    for my $id (keys %{ $self->{sessions} }) {
        my $record = $self->{sessions}{$id};
        my $quic = $record->{quic};
        if ($quic->closed) {
            delete $self->{sessions}{$id};
            next;
        }
        next if $record->{http} || $record->{attaching} || !$quic->ready;
        local $record->{attaching} = 1;

        my $http;
        if ($self->{role} eq 'Server') {
            $http = $self->{server}->attach_quic(connection => $quic);
        } else {
            require Unblock::HTTP::_EngineFactory;
            $http = Unblock::HTTP::_EngineFactory->create(
                'Client', 'h3', quic => $quic, %{ $self->{http3} },
            );
            $http->start;
        }
        if ($quic->closed) {
            delete $self->{sessions}{$id};
            next;
        }
        $record->{http} = $http;
        $self->{on_ready}->($http, $self) if $self->{on_ready};
    }
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP::QUIC - Manage HTTP/3 connections above Net::QUIC::Driver

=head1 DESCRIPTION

This is the small, event-loop-neutral HTTP/3 connection manager. It uses
Net::QUIC::Driver for packet processing and timer management. The host
still owns one UDP socket and one replaceable timer. The manager attaches
ready server connections to one reusable Server definition and starts client
sessions when QUIC is ready. It retains each HTTP/3 session until its QUIC
connection closes.

It does not create a UDP socket, negotiate transport addresses, or provide
a general user agent. It does not run an extra packet pump.

=head1 SERVER

    use Unblock::HTTP::QUIC;
    use Unblock::HTTP::Server;

    my $server = Unblock::HTTP::Server->new(
        http3 => {},
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "hello\n");
        },
    );

    my $http = Unblock::HTTP::QUIC->server(
        certificate_file => $cert,
        private_key_file => $key,
        server => $server,
        send => sub { my ($datagram) = @_; ... },
        set_timeout => sub { my ($seconds) = @_; ... },
    );

    $http->start;

Forward UDP and timer events:

    $http->receive($bytes, $packed_local, $packed_peer);
    $http->timeout;
    $http->writable;

No code is required to pull new QUIC connections, check handshake readiness,
or create per-connection HTTP/3 Servers.

=head1 CLIENT

    my $http = Unblock::HTTP::QUIC->client(
        local => $packed_local,
        peer => $packed_peer,
        server_name => 'example.test',
        send => sub { ... },
        set_timeout => sub { ... },
        on_ready => sub {
            my ($client, $manager) = @_;
            $client->request(
                method => 'GET', target => '/', scheme => 'https',
                authority => 'example.test', on_response => sub { ... },
            );
        },
    );

    $http->start;

C<on_ready> fires once per ready QUIC connection. On a server manager it
receives the actual HTTP3 Server engine and the manager. On a client manager
it receives the actual HTTP3 Client engine and manager. The shared
multi-origin Client uses connect_quic instead; this helper remains a low-level
Net::QUIC::Driver convenience.

=head1 METHODS

=head2 start, receive, timeout, writable

Forwarded to Net::QUIC::Driver. C<receive> takes one UDP payload plus
its concrete packed local and remote addresses and optionally ECN.
C<timeout> is called on expiration of the single timer specified by
C<set_timeout>. C<writable> is for recovery after UDP send congestion.

=head2 session, sessions

C<session> returns the ready HTTP client on a client manager, or undef
until its handshake finishes. C<sessions> returns active ready HTTP
engines on the server side and unified sessions on the client side.

=head2 driver

Returns the underlying Net::QUIC::Driver for advanced transport control.

=head1 OPTIONS

Normal Net::QUIC::Driver client or server options are accepted, including
C<send> and C<set_timeout>. ALPN is fixed to C<h3>. A server manager requires
C<server =E<gt> $server_definition> with HTTP/3 enabled. Configure HTTP engine
options and callbacks on that definition; the manager never overrides them.
A client manager still accepts extra engine options in C<http3>.

This checkpoint retains the scan of all connections after Driver events.
It does not yet claim constant-cost lifecycle coordination at high concurrency.

=head1 LICENSE

MIT License.

=cut
