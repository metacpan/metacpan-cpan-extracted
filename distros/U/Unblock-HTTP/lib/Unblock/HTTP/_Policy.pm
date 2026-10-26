package Unblock::HTTP::_Policy;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(refaddr);

my %NAME = ('http/1.1' => 'http1', h2 => 'http2', h3 => 'http3');
my @PROTOCOLS = ('http/1.1', 'h2', 'h3');

sub new {
    my ($class, %options) = @_;
    my $websocket_role = delete $options{_websocket_role};
    croak 'invalid internal WebSocket policy role'
        if defined($websocket_role)
            && $websocket_role ne 'server' && $websocket_role ne 'client';
    my (%engines, %websocket);
    for my $protocol (@PROTOCOLS) {
        my $name = $NAME{$protocol};
        next unless exists $options{$name};
        my $config = delete $options{$name};
        croak "$name must be a hash reference; omit it to disable the protocol"
            unless ref($config) eq 'HASH';
        $config = _copy($config);
        my $websocket = exists($config->{websocket})
            ? delete $config->{websocket} : 0;
        croak "$name websocket must be 0 or 1"
            unless defined($websocket) && !ref($websocket)
                && "$websocket" =~ /\A[01]\z/;
        if ($websocket) {
            croak "$name WebSocket attachment is not implemented yet; see docs/IMPLEMENTATION.md"
                unless defined($websocket_role)
                    && ($protocol eq 'http/1.1'
                        || $protocol eq 'h2'
                        || $protocol eq 'h3');
            $websocket{$protocol} = 1;
        }
        for my $key (keys %$config) {
            croak "$name option '$key' is managed by Unblock::HTTP"
                if $key =~ /\Aon_/ || $key =~ /\A(?:transport|quic|protocol|alpn|receive_body)\z/;
        }
        $config->{receive_body} = 'buffered';
        $config->{max_buffered_body_bytes} = 1_048_576
            unless exists $config->{max_buffered_body_bytes};
        croak "$name max_buffered_body_bytes must be a positive integer"
            unless defined($config->{max_buffered_body_bytes})
                && !ref($config->{max_buffered_body_bytes})
                && $config->{max_buffered_body_bytes} =~ /\A[0-9]+\z/
                && $config->{max_buffered_body_bytes} > 0
                && $config->{max_buffered_body_bytes} <= (~0);
        if ($protocol eq 'h2') {
            if (exists $config->{settings}) {
                croak 'http2 settings must be a hash reference'
                    unless ref($config->{settings}) eq 'HASH';
            }
            if ($websocket) {
                croak 'http2 WebSocket requires enable_connect_protocol => 1'
                    if exists($config->{enable_connect_protocol})
                        && !$config->{enable_connect_protocol};
                croak 'http2 WebSocket conflicts with settings 8 => 0'
                    if exists($config->{settings}) && exists($config->{settings}{8})
                        && !$config->{settings}{8};
                $config->{enable_connect_protocol} = 1;
            } else {
                # Generic Extended CONNECT is valid without WebSocket.
                # Caller must opt into SETTINGS_ENABLE_CONNECT_PROTOCOL.
                $config->{enable_connect_protocol} = 0
                    unless exists $config->{enable_connect_protocol};
            }
        }
        if ($protocol eq 'h3') {
            if ($websocket) {
                croak 'http3 WebSocket requires enable_extended_connect => 1'
                    if exists($config->{enable_extended_connect})
                        && !$config->{enable_extended_connect};
                $config->{enable_extended_connect} = 1;
            } else {
                # RFC 9220 WebSocket is only one Extended CONNECT use.
                $config->{enable_extended_connect} = 0
                    unless exists $config->{enable_extended_connect};
            }
        }
        $engines{$protocol} = $config;
    }
    croak 'unknown protocol option: ' . join(', ', sort keys %options) if %options;
    croak 'enable at least one of http1, http2, or http3' unless keys %engines;
    return bless { engines => \%engines, websocket => \%websocket }, $class;
}

sub protocols {
    my ($self) = @_;
    return grep { exists $self->{engines}{$_} } @PROTOCOLS;
}

sub alpn_protocols {
    my ($self) = @_;
    return grep { exists $self->{engines}{$_} } ('h2', 'http/1.1');
}

sub enabled {
    my ($self, $protocol) = @_;
    return defined($protocol) && !ref($protocol)
        && exists($self->{engines}{$protocol}) ? 1 : 0;
}

sub websocket_enabled {
    my ($self, $protocol) = @_;
    return defined($protocol) && !ref($protocol)
        && $self->{websocket}{$protocol} ? 1 : 0;
}

sub options {
    my ($self, $protocol) = @_;
    croak "HTTP protocol '$protocol' is disabled" unless $self->enabled($protocol);
    return _copy($self->{engines}{$protocol});
}

# Copy configuration containers at construction and attachment. Host objects
# and callbacks retain their identity; no copying happens on the byte path.
sub _copy {
    my ($value, $active) = @_;
    return $value unless ref($value) eq 'HASH' || ref($value) eq 'ARRAY';
    $active ||= {};
    my $id = refaddr($value);
    croak 'protocol configuration must not contain circular containers'
        if $active->{$id};
    local $active->{$id} = 1;
    return { map { $_ => _copy($value->{$_}, $active) } keys %$value }
        if ref($value) eq 'HASH';
    return [ map { _copy($_, $active) } @$value ];
}

1;
