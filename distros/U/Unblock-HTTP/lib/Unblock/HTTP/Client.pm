package Unblock::HTTP::Client;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed refaddr weaken);
use URI;
use Uniform::HTTP::Request;
use Unblock::HTTP::_Policy;
use Unblock::HTTP::_EngineFactory;
use Unblock::HTTP::_ClientOperation;
use Unblock::HTTP::_AltSvc;

our $VERSION = '0.02';

sub new {
    my ($class, @args) = @_;
    croak 'new(): expected named arguments' if @args % 2;
    my %option = @args;
    my %protocols;
    for my $name (qw(http1 http2 http3)) {
        $protocols{$name} = delete $option{$name} if exists $option{$name};
    }
    my $policy = Unblock::HTTP::_Policy->new(%protocols, _websocket_role => 'client');
    my %factory;
    for my $name (qw(connect_stream connect_quic defer schedule_timer release_connection)) {
        $factory{$name} = delete $option{$name} if exists $option{$name};
        croak "new(): $name must be a coderef"
            if exists($factory{$name}) && ref($factory{$name}) ne 'CODE';
    }
    croak 'new(): defer callback is required' unless $factory{defer};
    croak 'new(): connect_stream is required for HTTP/1 or HTTP/2'
        if ($policy->enabled('http/1.1') || $policy->enabled('h2'))
            && !$factory{connect_stream};
    croak 'new(): connect_quic is required for HTTP/3'
        if $policy->enabled('h3') && !$factory{connect_quic};

    my $clock = delete $option{alt_svc_clock};
    croak 'new(): alt_svc_clock must be a coderef'
        if defined($clock) && ref($clock) ne 'CODE';
    my $alt_svc = Unblock::HTTP::_AltSvc->new(
        (defined($clock) ? (clock => $clock) : ()),
    );

    my $idle_timeout = delete $option{idle_timeout};
    if (defined $idle_timeout) {
        croak 'new(): idle_timeout must be a positive number of seconds'
            if ref($idle_timeout)
                || $idle_timeout !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/
                || $idle_timeout <= 0;
        croak 'new(): idle_timeout requires schedule_timer callback'
            unless $factory{schedule_timer};
        $idle_timeout += 0;
    }

    my %limit;
    for my $key (qw(max_pending_requests max_connections_per_origin max_streams_per_connection)) {
        my $default = $key eq 'max_pending_requests' ? 128
            : $key eq 'max_connections_per_origin' ? 4 : 32;
        my $value = exists($option{$key}) ? delete($option{$key}) : $default;
        croak "new(): $key must be a positive integer"
            unless defined($value) && !ref($value)
                && $value =~ /\A[0-9]+\z/ && $value > 0;
        $limit{$key} = $value;
    }
    croak 'new(): unknown option: ' . join(', ', sort keys %option) if %option;
    return bless {
        policy => $policy,
        factory => \%factory,
        limit => \%limit,
        pending_count => 0,
        active_operations => {},
        shutdown => 0,
        pools => {},
        alt_svc => $alt_svc,
        idle_timeout => $idle_timeout,
    }, $class;
}

sub protocols { $_[0]{policy}->protocols }
sub alpn_protocols { $_[0]{policy}->alpn_protocols }
sub supports { $_[0]{policy}->enabled($_[1]) }
sub pending_count { $_[0]{pending_count} }
sub is_shutdown { $_[0]{shutdown} ? 1 : 0 }

# A copied, observational-only snapshot. No transport or engine objects
# escape, and taking a snapshot never runs scheduler or timer callbacks.
sub pool_stats {
    my ($self) = @_;
    my $total = {
        origins => 0, connections => 0, active => 0, idle => 0,
        retiring => 0, credit_blocked => 0, connecting => 0,
        pending => $self->{pending_count},
        by_origin => [],
    };
    for my $key (sort keys %{ $self->{pools} }) {
        my $pool = $self->{pools}{$key};
        my $one = {
            scheme => $pool->{info}{scheme},
            host => $pool->{info}{host},
            port => $pool->{info}{port},
            connections => 0, active => 0, idle => 0,
            retiring => 0, credit_blocked => 0,
            connecting => $pool->{connecting} ? 1 : 0,
            pending => scalar @{ $pool->{pending} },
        };
        for my $conn (@{ $pool->{connections} }) {
            $one->{connections}++;
            $one->{active} += $conn->{active};
            $one->{retiring}++ if $conn->{stale} || _retired($conn);
            $one->{credit_blocked}++ if $conn->{credit_blocked};
            $one->{idle}++ if !$conn->{active} && !$conn->{credit_blocked}
                && !$conn->{released} && !_closed($conn)
                && !_retired($conn);
        }
        for my $count (qw(connections active idle retiring credit_blocked connecting)) {
            $total->{$count} += $one->{$count};
        }
        push @{ $total->{by_origin} }, $one;
        $total->{origins}++;
    }
    return $total;
}

# A framework explicitly invokes this when its network identity changes.
# No active transaction is replayed, cancelled or moved between engines.
# Stop new admission, cancel unsent work, and retire live connections.
# Accepted transactions finish normally; idle transports are released now.
sub shutdown {
    my ($self) = @_;
    return $self if $self->{shutdown};
    $self->{shutdown} = 1;
    $self->{alt_svc}->clear;
    for my $pool (values %{ $self->{pools} }) {
        local $pool->{callback_depth} =
            ($pool->{callback_depth} || 0) + 1;
        for my $op (@{ [ @{ $pool->{pending} } ] }) {
            $op->cancel unless $op->is_terminal;
        }
        my @live;
        for my $conn (@{ $pool->{connections} }) {
            next if $conn->{released};
            $conn->{stale} = 1;
            $self->_cancel_idle($conn) if $conn->{idle_cancel};
            if ($conn->{active}) {
                push @live, $conn;
            } else {
                $self->_release_connection($conn, 'shutdown');
            }
        }
        $pool->{connections} = \@live;
        $self->_delete_empty_pool($pool);
    }
    return $self;
}

sub network_changed {
    my ($self) = @_;
    return if $self->{shutdown};
    $self->{alt_svc}->clear;
    for my $pool (values %{ $self->{pools} }) {
        # Suppress synchronous reentry from user-owned release hooks.
        local $pool->{callback_depth} = ($pool->{callback_depth} || 0) + 1;
        if (my $attempt = $pool->{attempt}) {
            my $op = $attempt->{op};
            $self->_abandon_connect($pool, $op);
            $op->{state} = 'queued' unless $op->is_terminal;
        }
        for my $op (@{ $pool->{pending} }) {
            next if $op->is_terminal || !$op->{alt_svc};
            delete $op->{alt_svc};
            $op->{version} = 'tcp';
            $op->{state} = 'queued';
        }
        my (@keep, @release);
        for my $conn (@{ $pool->{connections} }) {
            $conn->{stale} = 1;
            $self->_cancel_idle($conn) if $conn->{idle_cancel};
            if ($conn->{active}) {
                push @keep, $conn;
            } else {
                push @release, $conn;
            }
        }
        $pool->{connections} = \@keep;
        $self->_release_connection($_, 'network_changed') for @release;
        $self->_schedule($pool) if @{ $pool->{pending} };
        $self->_delete_empty_pool($pool);
    }
    return;
}

# HTTP1 upgrades transfer the socket out of the pool. HTTP2 and HTTP3
# CONNECT use independent streams on a multiplexed pooled connection.
sub connect_websocket {
    my ($self, @args) = @_;
    croak 'connect_websocket(): expected named arguments' if @args % 2;
    my %option = @args;
    my $http_version = delete $option{http_version};
    $http_version = $self->{policy}->websocket_enabled('http/1.1') ? '1.1'
        : $self->{policy}->websocket_enabled('h2') ? '2' : '3'
        unless defined $http_version;
    croak 'connect_websocket(): http_version must be 1.1, 2 or 3'
        if ref($http_version) || $http_version !~ /\A(?:1\.1|2|3)\z/;
    my $ws_protocol = $http_version eq '3' ? 'h3'
        : $http_version eq '2' ? 'h2' : 'http/1.1';
    croak "connect_websocket(): $ws_protocol websocket support is disabled"
        unless $self->{policy}->websocket_enabled($ws_protocol);
    my $url = delete $option{url};
    croak 'connect_websocket(): url is required'
        unless defined($url) && !ref($url) && length($url);
    my %handshake_option;
    for my $name (qw(headers origin subprotocols permessage_deflate)) {
        $handshake_option{$name} = delete $option{$name}
            if exists $option{$name};
    }
    my %session_option;
    for my $name (qw(
        backend max_message_size high_water low_water random_bytes
        on_message on_ping on_pong on_close on_drain
    )) {
        $session_option{$name} = delete $option{$name}
            if exists $option{$name};
    }
    my $on_open = delete $option{on_open};
    croak 'connect_websocket(): on_open must be a coderef'
        if defined($on_open) && ref($on_open) ne 'CODE';
    my $on_error = delete $option{on_error};
    croak 'connect_websocket(): on_error must be a coderef'
        if defined($on_error) && ref($on_error) ne 'CODE';
    my $on_finish = delete $option{on_finish};
    croak 'connect_websocket(): on_finish must be a coderef'
        if defined($on_finish) && ref($on_finish) ne 'CODE';
    my $timeout = delete $option{timeout};
    croak 'connect_websocket(): unknown option: ' . join(', ', sort keys %option)
        if %option;

    require Unblock::WebSocket::Handshake;
    my ($handshake, $request) =
        Unblock::WebSocket::Handshake->client_request(
            $url, http_version => $http_version, %handshake_option,
        );
    my $http_url = "$url";
    $http_url =~ s/\Aws:/http:/i;
    $http_url =~ s/\Awss:/https:/i;
    my $spec = {
        handshake => $handshake,
        options => \%session_option,
        on_open => $on_open,
    };
    return $self->request(
        url => $http_url,
        http_version => $http_version,
        _websocket_request => $request,
        _websocket_connect => $spec,
        (defined($on_error) ? (on_error => $on_error) : ()),
        (defined($on_finish) ? (on_finish => $on_finish) : ()),
        (defined($timeout) ? (timeout => $timeout) : ()),
    );
}

sub request {
    my ($self, @args) = @_;
    croak 'request(): Client is shut down' if $self->{shutdown};
    croak 'request(): expected named arguments' if @args % 2;
    my %field = @args;
    my $ws_spec = delete $field{_websocket_connect};
    my $ws_request = delete $field{_websocket_request};
    croak 'request(): internal WebSocket options must occur together'
        if (!!$ws_spec) != (!!$ws_request);
    croak 'request(): WebSocket option is disabled'
        if $ws_spec && !$self->{policy}->websocket_enabled(
            $ws_request->version eq '3' ? 'h3'
                : $ws_request->version eq '2' ? 'h2' : 'http/1.1'
        );
    my $url = delete $field{url};
    croak 'request(): url is required' unless defined($url) && !ref($url) && length($url);
    my ($scheme, $host, $port, $authority, $target);
    # Common canonical ASCII URLs need no URI object. Keep this match
    # intentionally restrictive: noncanonical schemes/hosts, IPv6,
    # escaping, fragments and exotic targets still use URI below.
    # No URL cache, shared parser state or persistent allocation.
    if ($url =~ m{
        \A (https?)://
        ([a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?
            (?:\.[a-z0-9]+(?:[a-z0-9-]*[a-z0-9])?)*)
        (?::([1-9][0-9]{0,4}))?
        ([/?][A-Za-z0-9._~/?&=+\-]*)?
        \z
    }x && (!defined($3) || $3 <= 65535)) {
        my $given_port = $3;
        ($scheme, $host) = ($1, $2);
        $port = defined($given_port) ? $given_port
            : $scheme eq 'https' ? 443 : 80;
        $authority = $host;
        $authority .= ":$given_port" if defined $given_port;
        $target = defined($4) ? $4 : '/';
        $target = '/' . $target if substr($target, 0, 1) eq '?';
    } else {
        my $uri = URI->new($url);
        $scheme = lc($uri->scheme || '');
        croak 'request(): URL scheme must be http or https'
            unless $scheme eq 'http' || $scheme eq 'https';
        croak 'request(): URL must not contain userinfo or a fragment'
            if defined($uri->userinfo) || defined($uri->fragment);
        $host = $uri->host;
        croak 'request(): URL must include a host'
            unless defined($host) && length($host);
        $port = $uri->port;
        croak 'request(): invalid URL port'
            unless defined($port) && $port =~ /\A[0-9]+\z/
                && $port > 0 && $port <= 65535;
        $authority = $uri->authority;
        $target = $uri->path_query;
        $target = '/' unless defined($target) && length($target);
        $target = '/' . $target if substr($target, 0, 1) eq '?';
    }

    my $version = delete $field{http_version};
    my $strict_version = defined($version) ? 1 : 0;
    if (defined $version) {
        croak 'request(): http_version must be 1.1, 2 or 3'
            if ref($version) || $version !~ /\A(?:1\.1|2|3)\z/;
        $version = { '1.1' => 'http/1.1', '2' => 'h2', '3' => 'h3' }->{$version};
        croak "request(): required protocol '$version' is disabled"
            unless $self->{policy}->enabled($version);
        croak 'request(): HTTP/3 requires https'
            if $version eq 'h3' && $scheme ne 'https';
    } else {
        $version = ($self->{policy}->enabled('h2')
            || $self->{policy}->enabled('http/1.1')) ? 'tcp' : 'h3';
        croak 'request(): HTTP/3 requires https'
            if $version eq 'h3' && $scheme ne 'https';
    }

    my %callbacks;
    for my $name (qw(
        on_response on_data on_end on_error on_finish on_informational on_drain
    )) {
        next unless exists $field{$name};
        my $cb = delete $field{$name};
        croak "request(): $name must be a coderef" unless ref($cb) eq 'CODE';
        $callbacks{$name} = $cb;
    }
    my $timeout = delete $field{timeout};
    if (defined $timeout) {
        croak 'request(): timeout must be a positive number of seconds'
            if ref($timeout) || $timeout !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/
                || $timeout <= 0;
        croak 'request(): timeout requires schedule_timer callback'
            unless $self->{factory}{schedule_timer};
    }
    my $stream_body = delete($field{stream_body}) ? 1 : 0;
    croak 'request(): on_drain requires stream_body'
        if $callbacks{on_drain} && !$stream_body;
    croak 'request(): pending queue is full'
        if $self->{pending_count} >= $self->{limit}{max_pending_requests};
    croak 'request(): do not pass scheme, authority or target with url'
        if grep { exists($field{$_}) } qw(scheme authority target);
    $field{method} = 'GET' unless exists $field{method};
    croak 'request(): internal WebSocket request cannot override HTTP fields'
        if $ws_request && keys %field > 1;
    my $request = $ws_request || Uniform::HTTP::Request->new(
        %field, scheme => $scheme, authority => $authority, target => $target,
    );
    if ($ws_request) {
        croak 'request(): WebSocket protocol and handshake version disagree'
            unless ($version eq 'http/1.1' && $request->version eq '1.1')
                || ($version eq 'h2' && $request->version eq '2')
                || ($version eq 'h3' && $request->version eq '3');
        croak 'request(): WebSocket URL and handshake request disagree'
            unless $request->scheme eq $scheme
                && $request->authority eq $authority
                && $request->target eq $target;
    }
    my $key = join('|', $scheme, lc($host), $port);
    my $origin = $self->{pools}{$key} ||= {
        info => {
            scheme => $scheme, host => $host, port => 0 + $port,
            authority => $authority,
            key => $key,
        },
        pending => [],
        connections => [],
        connecting => 0,
        pumping => 0,
        scheduled => 0,
    };
    my $op = Unblock::HTTP::_ClientOperation->new(
        $self, $request, \%callbacks, $version, $origin,
    );
    $op->{stream_body} = $ws_spec
        && ($version eq 'h2' || $version eq 'h3') ? 1 : $stream_body;
    $op->{websocket_connect} = $ws_spec if $ws_spec;
    if (!$strict_version && $scheme eq 'https'
        && $version eq 'tcp' && $self->{policy}->enabled('h3')) {
        my $advertised = $self->{alt_svc}->lookup($key);
        if ($advertised) {
            $op->{alt_svc} = $advertised;
            $op->{version} = 'h3';
        }
    }
    if (defined $timeout) {
        my $cancel = $self->{factory}{schedule_timer}->(
            0 + $timeout, sub { $self->_request_timeout($op, $timeout) },
        );
        croak 'request(): schedule_timer must return a cancellation coderef'
            unless ref($cancel) eq 'CODE';
        $op->{timer_cancel} = $cancel;
    }
    # A healthy, immediately admissible pooled connection needs no
    # queue insertion, full pool scan or scheduler allocation. This is
    # strictly an application-request path, never the per-byte path.
    # Keep the general pump for pending work, reentrant callbacks,
    # connecting factories and idle-expiration lifecycle management.
    if (!defined($self->{idle_timeout})
        && !@{ $origin->{pending} }
        && !$origin->{connecting}
        && !$origin->{pumping}
        && !$origin->{callback_depth}
        && !$origin->{scheduled}
        && @{ $origin->{connections} } == 1) {
        my $conn = $origin->{connections}[0];
        if ($self->_usable($conn, $op->{version}, $op)) {
            $self->_dispatch($origin, $conn, $op);
            return $op;
        }
    }
    push @{ $origin->{pending} }, $op;
    $self->{pending_count}++;
    $self->_pump($origin);
    return $op;
}

sub _compatible {
    my ($version, $protocol) = @_;
    return $protocol eq $version if $version ne 'tcp';
    return $protocol eq 'h2' || $protocol eq 'http/1.1';
}

# Connection retirement and temporary peer stream exhaustion are different.
# A SETTINGS limit of zero can later increase; do not close an idle H2
# connection merely because it cannot currently open a request.
sub _retired {
    my ($conn) = @_;
    my $engine = $conn->{engine};
    return 1 if $conn->{stale};
    return 1 if $conn->{protocol} eq 'http/1.1'
        && $engine->can('is_switched') && $engine->is_switched;
    if ($conn->{protocol} eq 'h2') {
        return $engine->can('draining') && $engine->draining ? 1 : 0;
    }
    if ($conn->{protocol} eq 'h3') {
        return 1 if $engine->can('shutdown_started') && $engine->shutdown_started;
        return 1 if $engine->can('remote_shutdown_id')
            && defined $engine->remote_shutdown_id;
    }
    return 0;
}

sub _closed {
    my ($conn) = @_;
    return $conn->{protocol} eq 'h3'
        ? ($conn->{engine}->failed || $conn->{host}->closed)
        : $conn->{engine}->is_closed;
}

sub _usable {
    my ($self, $conn, $version, $op) = @_;
    return 0 unless _compatible($version, $conn->{protocol});
    return 0 if $conn->{released} || _closed($conn) || _retired($conn)
        || $conn->{credit_blocked};
    if ($op && $op->{websocket_connect}) {
        return 0 if $version eq 'h2'
            && (!$conn->{h2_settings_seen}
                || $conn->{engine}->peer_setting('enable_connect_protocol') != 1);
        return 0 if $version eq 'h3'
            && (!$conn->{engine}->peer_settings_received
                || !$conn->{engine}->peer_extended_connect_enabled);
    }
    my $capacity = $conn->{protocol} eq 'http/1.1'
        ? 1 : $self->{limit}{max_streams_per_connection};
    return 0 if $conn->{active} >= $capacity;
    return 0 if $conn->{protocol} eq 'h2'
        && $conn->{engine}->can('can_open_transaction')
        && !$conn->{engine}->can_open_transaction;
    return 1;
}

# A pooled transport is released once. The framework may own the socket
# and its close semantics, so allow its adapter to perform final cleanup.
sub _cancel_idle {
    my ($self, $conn) = @_;
    $conn->{idle_generation}++;
    my $cancel = delete $conn->{idle_cancel} or return;
    eval { $cancel->(); 1 } or warn "idle timer cancellation failed: $@";
    return;
}

sub _release_connection {
    my ($self, $conn, $reason) = @_;
    return if $conn->{released};
    $conn->{released} = 1;
    $self->_cancel_idle($conn);
    my $release = $self->{factory}{release_connection};
    my $ok = eval {
        if ($release) {
            $release->($conn->{host}, $conn->{engine}, $conn->{protocol}, $reason);
        } elsif ($conn->{engine}->can('close')) {
            $conn->{engine}->close;
        } elsif ($conn->{host}->can('close')) {
            # Current HTTP/3 Client has no close(), but Net::QUIC does.
            $conn->{host}->close;
        }
        1;
    };
    warn "connection release failed: $@" unless $ok;
    return;
}

sub _drop_connection {
    my ($self, $pool, $conn, $reason) = @_;
    return if $conn->{active};
    $pool->{connections} = [
        grep { $_ != $conn } @{ $pool->{connections} }
    ];
    $self->_release_connection($conn, $reason);
    $self->_delete_empty_pool($pool);
    return;
}

sub _delete_empty_pool {
    my ($self, $pool) = @_;
    return if $pool->{connecting}
        || @{ $pool->{pending} } || @{ $pool->{connections} };
    my $key = $pool->{info}{key};
    delete $self->{pools}{$key}
        if exists $self->{pools}{$key}
            && $self->{pools}{$key} == $pool;
    return;
}

sub _sync_idle {
    my ($self, $pool) = @_;
    my $idle_timeout = $self->{idle_timeout};
    return unless defined $idle_timeout;
    my $waiting = $pool->{connecting} || @{ $pool->{pending} };
    for my $conn (@{ $pool->{connections} }) {
        if ($waiting || $conn->{active} || $conn->{released}) {
            $self->_cancel_idle($conn) if $conn->{idle_cancel};
            next;
        }
        next if $conn->{idle_cancel};
        my $generation = ++$conn->{idle_generation};
        my $weak_self = $self;
        my $weak_pool = $pool;
        my $weak_conn = $conn;
        weaken($weak_self);
        weaken($weak_pool);
        weaken($weak_conn);
        my $ok = eval {
            my $cancel = $self->{factory}{schedule_timer}->(
                $idle_timeout,
                sub {
                    return unless $weak_self && $weak_pool && $weak_conn;
                    return unless $weak_conn->{idle_generation} == $generation;
                    delete $weak_conn->{idle_cancel};
                    return if $weak_conn->{released}
                        || $weak_conn->{active}
                        || $weak_pool->{connecting}
                        || @{ $weak_pool->{pending} };
                    $weak_self->_drop_connection(
                        $weak_pool, $weak_conn, 'idle_timeout',
                    );
                },
            );
            die "schedule_timer must return cancellation coderef\n"
                unless ref($cancel) eq 'CODE';
            $conn->{idle_cancel} = $cancel;
            1;
        };
        warn "idle timer setup failed: $@" unless $ok;
    }
    return;
}

sub _pump {
    my ($self, $pool) = @_;
    return if $self->{shutdown};
    # Application on_finish can synchronously enqueue another request.
    # Wait for the engine terminal callback to unwind before reusing H1.
    return if $pool->{pumping} || $pool->{callback_depth};
    local $pool->{pumping} = 1;
    my $attempt_budget = $self->{limit}{max_connections_per_origin};
    my @kept;
    for my $conn (@{ $pool->{connections} }) {
        if ($conn->{active} || (!_closed($conn) && !_retired($conn))) {
            push @kept, $conn;
        } else {
            $self->_release_connection($conn,
                _closed($conn) ? 'closed'
                : $conn->{stale} ? 'network_changed' : 'draining');
        }
    }
    $pool->{connections} = \@kept;
    # Pending demand is not idle, even if the peer temporarily offers no
    # H2/H3 request stream credit.
    $self->_sync_idle($pool);
    while (@{ $pool->{pending} }) {
        my $op = $pool->{pending}[0];
        if ($op->is_terminal) {
            shift @{ $pool->{pending} };
            $self->{pending_count}--;
            next;
        }
        # Extended CONNECT is only legal after current peer SETTINGS.
        # Wait on an existing protocol connection without opening more
        # sockets. If its peer explicitly disables Extended CONNECT,
        # reject this unsent operation rather than downgrading/replaying.
        if ($op->{websocket_connect}
            && ($op->{version} eq 'h2' || $op->{version} eq 'h3')) {
            my $version = $op->{version};
            my @existing = grep {
                $_->{protocol} eq $version && !$_->{released}
                    && !_closed($_) && !_retired($_)
            } @{ $pool->{connections} };
            my $ready = sub {
                my ($conn) = @_;
                return $version eq 'h2'
                    ? ($conn->{h2_settings_seen}
                        && $conn->{engine}->peer_setting(
                            'enable_connect_protocol') == 1)
                    : ($conn->{engine}->peer_settings_received
                        && $conn->{engine}->peer_extended_connect_enabled);
            };
            if (@existing && !grep { $ready->($_) } @existing) {
                last if grep {
                    $version eq 'h2' ? !$_->{h2_settings_seen}
                        : !$_->{engine}->peer_settings_received
                } @existing;
                shift @{ $pool->{pending} };
                $self->{pending_count}--;
                $self->_fail_pending(
                    $pool, $op, 'peer has not enabled HTTP/'
                        . ($version eq 'h2' ? '2' : '3')
                        . ' WebSocket Extended CONNECT',
                );
                next;
            }
        }
        my ($conn) = grep { $self->_usable($_, $op->{version}, $op) }
            @{ $pool->{connections} };
        if ($conn) {
            shift @{ $pool->{pending} };
            $self->{pending_count}--;
            last unless $self->_dispatch($pool, $conn, $op);
            next;
        }
        last if $pool->{connecting};
        if (@{ $pool->{connections} } >= $self->{limit}{max_connections_per_origin}) {
            # Never strand a strict request behind an idle, unusable engine.
            for (my $i = 0; $i < @{ $pool->{connections} }; $i++) {
                my $idle = $pool->{connections}[$i];
                next if $idle->{active};
                my $unusable = !_compatible($op->{version}, $idle->{protocol})
                    || _closed($idle) || _retired($idle);
                next unless $unusable;
                splice @{ $pool->{connections} }, $i, 1;
                $self->_release_connection($idle, 'evicted');
                last;
            }
        }
        last if @{ $pool->{connections} } >= $self->{limit}{max_connections_per_origin};
        # A synchronous factory can produce a connection that immediately
        # refuses streams. Never spin forever creating/replacing engines.
        last unless $attempt_budget--;
        $self->_connect($pool, $op);
        last if $pool->{connecting};
    }
    $self->_sync_idle($pool);
    $self->_delete_empty_pool($pool);
}

sub _connect {
    my ($self, $pool, $op) = @_;
    my $version = $op->{version};
    my $quic = $version eq 'h3';
    my $alt = $op->{alt_svc};
    my $factory = $self->{factory}{ $quic ? 'connect_quic' : 'connect_stream' };
    my $attempt = { op => $op, cancelled => 0, completed => 0 };
    $pool->{connecting} = 1;
    $pool->{attempt} = $attempt;
    $op->{state} = 'connecting';
    my $called = 0;
    my $ready = sub {
        return if $called++;
        # A cancelled/timed-out factory must not attach its late transport.
        return unless $pool->{attempt} && $pool->{attempt} == $attempt;
        $attempt->{completed} = 1;
        delete $pool->{attempt};
        $pool->{connecting} = 0;
        my %result = @_;
        my $engine;
        my $ok = eval { $engine = $self->_connected($pool, $op, $version, \%result); 1 };
        if (!$ok) {
            my $error = "$@";
            if (!$self->_fallback_alternative($pool, $op, $error)) {
                $self->_fail_pending($pool, $op, $error);
            }
        } elsif (!$op->is_terminal && !$op->{transaction}) {
            # Connection establishment is complete. Waiting for peer stream
            # credit is queued work, not another connection in progress.
            $op->{state} = 'queued';
        }
        $self->_pump($pool);
        return $engine;
    };
    my @alpn = $version eq 'tcp'
        ? $self->alpn_protocols : ($version eq 'h3' ? ('h3') : ($version));
    my $cancel;
    my $ok = eval {
        if ($quic) {
            my $info = $pool->{info};
            if ($alt) {
                # The HTTP origin is unchanged. Only the UDP target differs.
                $info = { %$info,
                    alternative_host => $info->{host},
                    alternative_port => $alt->{port},
                };
            }
            $cancel = $factory->($info, $ready);
        } else {
            $cancel = $factory->($pool->{info}, \@alpn, $ready);
        }
        1;
    };
    if (ref($cancel) eq 'CODE' && !$attempt->{completed}) {
        if ($attempt->{cancelled}) {
            eval { $cancel->(); 1 } or warn "connection cancellation failed: $@";
        } else {
            $attempt->{cancel} = $cancel;
        }
    }
    $ready->(error => "$@") unless $ok || $called || $attempt->{cancelled};
}

# A pending request may abandon its own factory without holding the origin
# hostage. The framework may return a cancellation callback from the factory.
sub _abandon_connect {
    my ($self, $pool, $op) = @_;
    my $attempt = $pool->{attempt} or return;
    return unless $attempt->{op} == $op;
    delete $pool->{attempt};
    $pool->{connecting} = 0;
    $attempt->{cancelled} = 1;
    if (my $cancel = delete $attempt->{cancel}) {
        eval { $cancel->(); 1 } or warn "connection cancellation failed: $@";
    }
    return;
}

sub _request_timeout {
    my ($self, $op, $seconds) = @_;
    return if $op->is_terminal;
    my $error = "request timed out after $seconds seconds";
    if (my $tx = $op->{transaction}) {
        # Engine cancellation preserves protocol-specific stream isolation.
        # The operation separately reports expiration as a timeout error.
        $op->{timeout_error} = $error;
        $tx->cancel;
        return;
    }
    $self->_fail_pending($op->{origin}, $op, $error);
    $self->_schedule($op->{origin});
    return;
}

sub _connected {
    my ($self, $pool, $op, $version, $result) = @_;
    die "$result->{error}" if defined($result->{error}) && length($result->{error});
    my ($protocol, $host, %arg);
    if ($version eq 'h3') {
        $protocol = 'h3';
        $host = $result->{connection};
        die "connect_quic: expected a ready QUIC connection\n"
            unless blessed($host) && $host->can('ready') && $host->can('closed')
                && $host->ready && !$host->closed;
        die "connect_quic: alternative must authenticate the original HTTPS origin\n"
            if $op->{alt_svc}
                && !(defined($result->{verified_origin})
                     && !ref($result->{verified_origin})
                     && $result->{verified_origin} eq '1');
        %arg = (quic => $host);
    } else {
        $protocol = defined($result->{alpn}) && length($result->{alpn})
            ? $result->{alpn} : 'http/1.1';
        die "connect_stream: negotiated unsupported or disabled protocol\n"
            unless ($protocol eq 'h2' || $protocol eq 'http/1.1')
                && $self->{policy}->enabled($protocol)
                && _compatible($version, $protocol);
        $host = $result->{transport};
        die "connect_stream: transport must implement unblock_send, unblock_finish and unblock_abort\n"
            unless blessed($host)
                && $host->can('unblock_send')
                && $host->can('unblock_finish')
                && $host->can('unblock_abort');
        %arg = (transport => $host);
    }
    my $options = $self->{policy}->options($protocol);
    # These advertise Server capabilities; Client constructors reject them.
    delete $options->{enable_connect_protocol} if $protocol eq 'h2';
    delete $options->{enable_extended_connect} if $protocol eq 'h3';
    my $conn = {
        host => $host, protocol => $protocol, active => 0,
        credit_blocked => 0,
        verified_origin =>
            (defined($result->{verified_origin})
              && !ref($result->{verified_origin})
              && $result->{verified_origin} eq '1') ? 1 : 0,
    };
    my $weak_self = $self;
    my $weak_pool = $pool;
    my $weak_conn = $conn;
    weaken($weak_self);
    weaken($weak_pool);
    weaken($weak_conn);
    if ($protocol eq 'h2') {
        # A peer may raise its advertised stream limit later.
        $options->{on_settings} = sub {
            return unless $weak_self && $weak_pool && $weak_conn;
            $weak_conn->{h2_settings_seen} = 1;
            $weak_self->_schedule($weak_pool);
        };
    } elsif ($protocol eq 'h3') {
        # The H3 engine exclusively owns Net::QUIC's availability callback.
        # A failed-to-open bidi stream causes this one-shot notification.
        $options->{on_request_available} = sub {
            return unless $weak_self && $weak_pool && $weak_conn;
            $weak_conn->{credit_blocked} = 0;
            $weak_self->_schedule($weak_pool);
        };
        if ($self->{policy}->websocket_enabled('h3')) {
            # This hook fires after the CURRENT H3 peer SETTINGS frame,
            # including when it contains no extension settings. Never
            # submit CONNECT inline from the native receive callback.
            $options->{on_extension_settings} = sub {
                return unless $weak_self && $weak_pool && $weak_conn;
                $weak_self->_schedule($weak_pool);
            };
        }
    }
    my $engine = Unblock::HTTP::_EngineFactory->create(
        'Client', $protocol, %$options, %arg,
    );
    $engine->start if $protocol eq 'h3';
    $conn->{engine} = $engine;
    push @{ $pool->{connections} }, $conn;
    return $engine;
}

# Alternative connection failure before dispatch is safe to recover from:
# the engine never saw this request. Once dispatched, no retry is automatic.
sub _fallback_alternative {
    my ($self, $pool, $op, $error) = @_;
    return 0 unless $op->{alt_svc} && !$op->{transaction}
        && !$op->is_terminal
        && ($self->{policy}->enabled('http/1.1') || $self->{policy}->enabled('h2'));
    $self->{alt_svc}->invalidate($op->{origin}{info}{key});
    for my $pending (@{ $pool->{pending} }) {
        next unless $pending->{alt_svc} && !$pending->is_terminal;
        delete $pending->{alt_svc};
        $pending->{version} = 'tcp';
        $pending->{state} = 'queued';
    }
    return 1;
}

sub _learn_alt_svc {
    my ($self, $pool, $conn, $response) = @_;
    return if $conn->{stale};
    return unless $conn->{verified_origin}
        && $pool->{info}{scheme} eq 'https'
        && $self->{policy}->enabled('h3');
    $self->{alt_svc}->observe($pool->{info}{key}, $response);
    return;
}

sub _dispatch {
    my ($self, $pool, $conn, $op) = @_;
    $self->_cancel_idle($conn) if $conn->{idle_cancel};
    $conn->{active}++;
    $op->{state} = 'active';
    # The Client owns in-flight operations even if the caller discards its
    # handle. Transaction callbacks must not own the operation or pool:
    # once terminal, that would retain the Transaction through a cycle.
    my $op_id = refaddr($op);
    $self->{active_operations}{$op_id} = $op;
    my ($weak_self, $weak_pool, $weak_conn, $weak_op) =
        ($self, $pool, $conn, $op);
    weaken($weak_self);
    weaken($weak_pool);
    weaken($weak_conn);
    weaken($weak_op);
    my $callbacks = $op->{callbacks};
    my $ws_spec = $op->{websocket_connect};
    my %engine_callback;
    $engine_callback{on_data} = $callbacks->{on_data} if $callbacks->{on_data};
    $engine_callback{on_informational} = $callbacks->{on_informational}
        if $callbacks->{on_informational};
    $engine_callback{on_drain} = $callbacks->{on_drain}
        if $callbacks->{on_drain};

    # Alt-Svc discovery only affects later TCP-first requests. A Client
    # configured for H3 alone can never consult the alternative cache;
    # avoid allocating and running an unused per-response observer there.
    if ($pool->{info}{scheme} eq 'https'
        && $self->{policy}->enabled('h3')
        && ($self->{policy}->enabled('h2')
            || $self->{policy}->enabled('http/1.1'))) {
        # Once per response headers, not on the body hot path.
        $engine_callback{on_response} = sub {
            my ($tx, $response) = @_;
            $weak_self->_learn_alt_svc($weak_pool, $weak_conn, $response)
                if $weak_self && $weak_pool && $weak_conn;
            $callbacks->{on_response}->($tx, $response)
                if $callbacks->{on_data} && $callbacks->{on_response};
        };
    } elsif ($callbacks->{on_response} && $callbacks->{on_data}) {
        $engine_callback{on_response} = $callbacks->{on_response};
    }
    if ($callbacks->{on_response} || ($callbacks->{on_end} && $callbacks->{on_data})) {
        $engine_callback{on_complete} = sub {
            my ($tx) = @_;
            if ($callbacks->{on_data}) {
                $callbacks->{on_end}->($tx) if $callbacks->{on_end};
            } else {
                $callbacks->{on_response}->($tx, $tx->response)
                    if $callbacks->{on_response};
            }
        };
    }
    if ($callbacks->{on_error}) {
        $engine_callback{on_error} = $callbacks->{on_error};
    }
    if ($ws_spec && ($conn->{protocol} eq 'h2'
                     || $conn->{protocol} eq 'h3')) {
        # Unlike HTTP1, a WebSocket occupies one multiplexed H2/H3 stream.
        # Its normal transaction lifetime remains active until END_STREAM.
        # No host socket takeover or HTTP pool detachment is performed.
        $engine_callback{on_response} = sub {
            my ($tx, $response) = @_;
            # A rejected H3 handshake must not throw out of Net::QUIC's
            # receive dispatch. Defer a reset of this stream only.
            my $valid = eval {
                $ws_spec->{handshake}->validate_client_response($response);
                1;
            };
            if (!$valid) {
                die $@ if $conn->{protocol} ne 'h3';
                my $active_op = $weak_op or return;
                $active_op->{websocket_handshake_error} =
                    "$@" || 'HTTP3 WebSocket handshake failed';
                my $active_self = $weak_self or return;
                $active_self->{factory}{defer}->(sub {
                    $tx->cancel unless $tx->is_terminal;
                });
                return;
            }
            require Unblock::HTTP::_WebSocketH2Body;
            require Unblock::WebSocket::Client;
            my $active_op = $weak_op or return;
            my $active_self = $weak_self or return;
            my $bridge = Unblock::HTTP::_WebSocketH2Body->new(
                transaction => $tx, defer => $active_self->{factory}{defer},
            );
            my $ws = Unblock::WebSocket::Client->new(
                %{ $ws_spec->{handshake}->connection_options },
                %{ $ws_spec->{options} },
                transport => $bridge,
                ($callbacks->{on_error}
                    ? (on_error => $callbacks->{on_error}) : ()),
            );
            $bridge->websocket($ws);
            $active_op->{websocket} = $ws;
            $active_op->{websocket_bridge} = $bridge;
            $ws_spec->{on_open}->($ws, $tx)
                if $ws_spec->{on_open};
        };
        $engine_callback{on_data} = sub {
            my $active_op = $weak_op or return;
            # An H3 rejection may carry an ordinary HTTP error body.
            # Discard it after validation has failed; it is not framed
            # WebSocket DATA and must not unwind the QUIC receive call.
            return if $active_op->{websocket_handshake_error};
            my $ws = $active_op->{websocket}
                or die 'multiplexed WebSocket DATA arrived before validated response';
            $ws->input($_[1]);
        };
        $engine_callback{on_drain} = sub {
            my $active_op = $weak_op or return;
            my $bridge = $active_op->{websocket_bridge} or return;
            $bridge->resume;
        };
        $engine_callback{on_complete} = sub {
            my $active_op = $weak_op or return;
            my $ws = $active_op->{websocket} or return;
            $ws->input_eof if !$ws->is_closed;
        };
    }
    elsif ($ws_spec) {
        # Validation must happen before HTTP1 yields its byte-stream.
        # Invalid 101 replies and ordinary HTTP rejection responses are
        # failed handshakes, not successful established WebSockets.
        $engine_callback{on_response} = sub {
            my ($tx, $response) = @_;
            $ws_spec->{handshake}->validate_client_response($response);
        };
        $engine_callback{on_switch} = sub {
            my ($tx, $response) = @_;
            my $active_self = $weak_self or return;
            my $active_pool = $weak_pool or return;
            my $active_conn = $weak_conn or return;
            my $active_op = $weak_op or return;
            local $active_pool->{callback_depth} =
                ($active_pool->{callback_depth} || 0) + 1;
            my $host = $active_conn->{host};
            croak 'connect_websocket(): transport must implement unblock_upgrade()'
                unless $host->can('unblock_upgrade');

            require Unblock::WebSocket::Client;
            my $ws = Unblock::WebSocket::Client->new(
                %{ $ws_spec->{handshake}->connection_options },
                %{ $ws_spec->{options} },
                transport => $host,
                ($callbacks->{on_error}
                    ? (on_error => $callbacks->{on_error}) : ()),
            );
            # The framework changes the input owner synchronously, while
            # leaving its ordered write queue and the socket unchanged.
            $host->unblock_upgrade($ws);
            $active_op->{websocket} = $ws;
            # Keep the detached pool bookkeeping alive only until HTTP1
            # invokes on_finish immediately after this on_switch callback.
            # The ordinary callback closure intentionally holds weak refs.
            $active_op->{upgrade_retirement} = [$active_pool, $active_conn];
            $active_conn->{released} = 1; # transferred, never close by pool
            $active_self->_cancel_idle($active_conn)
                if $active_conn->{idle_cancel};
            $active_pool->{connections} = [
                grep { $_ != $active_conn } @{ $active_pool->{connections} }
            ];
            $ws_spec->{on_open}->($ws, $tx)
                if $ws_spec->{on_open};
            my $tail = $active_conn->{engine}->take_remainder;
            $ws->input($tail) if length $tail;
        };
    }
    $engine_callback{on_finish} = sub {
        my ($tx) = @_;
        my $active_op = $weak_op or return;
        return if $active_op->is_terminal;
        my $upgrade_retirement = delete $active_op->{upgrade_retirement};
        my ($active_self, $active_pool, $active_conn) =
            ($weak_self,
             $weak_pool || ($upgrade_retirement && $upgrade_retirement->[0]),
             $weak_conn || ($upgrade_retirement && $upgrade_retirement->[1]));
        return unless $active_self && $active_pool && $active_conn;
        local $active_pool->{callback_depth} =
            ($active_pool->{callback_depth} || 0) + 1;
        $active_op->{transaction} ||= $tx;
        if (my $bridge = delete $active_op->{websocket_bridge}) {
            $bridge->detach;
        }
        $active_op->{state} = ($active_op->{timeout_error}
            || $active_op->{websocket_handshake_error}) ? 'error'
            : $tx->is_cancelled ? 'cancelled'
            : $tx->is_error ? 'error' : 'complete';
        $active_op->{error} = $active_op->{timeout_error}
            || $active_op->{websocket_handshake_error}
            || ($tx->is_error ? $tx->error : undef);
        $active_op->_cancel_timer;
        $active_conn->{active}--;
        if (($active_op->{timeout_error}
             || $active_op->{websocket_handshake_error})
            && $callbacks->{on_error}) {
            eval { $callbacks->{on_error}->($tx, $active_op->{error}); 1 }
                or warn $@;
        }
        my $ok = eval {
            $callbacks->{on_finish}->($tx) if $callbacks->{on_finish};
            1;
        };
        warn $@ unless $ok;
        # Keep the strong active ownership through application callbacks.
        # A caller-retained handle still owns the real engine Transaction.
        delete $active_self->{active_operations}{$op_id};
        # A quiet, reusable connection needs no additional loop turn.
        # Preserve deferred H1 reentrancy, pending queues, idle timers
        # and immediate cleanup of closed/draining/stale connections.
        if ($active_self->{shutdown}) {
            $active_self->_drop_connection(
                $active_pool, $active_conn, 'shutdown',
            ) if !$active_conn->{active} && !$active_conn->{released};
            return;
        }
        $active_self->_schedule($active_pool)
            if @{ $active_pool->{pending} }
                || defined($active_self->{idle_timeout})
                || $active_conn->{stale}
                || _closed($active_conn) || _retired($active_conn);
    };
    my $no_credit = 0;
    my $ok = eval {
        die "connect_websocket(): requires HTTP1, HTTP2 or HTTP3 transport\n"
            if $ws_spec && $conn->{protocol} ne 'http/1.1'
                && $conn->{protocol} ne 'h2' && $conn->{protocol} ne 'h3';
        die "connect_websocket(): HTTP1 requires unblock_upgrade()\n"
            if $ws_spec && $conn->{protocol} eq 'http/1.1'
                && !$conn->{host}->can('unblock_upgrade');
        $op->{transaction} = $conn->{engine}->request(
            $op->{request},
            stream_body => $op->{stream_body},
            %engine_callback,
        );
        # HTTP/3 returns undef before opening a QUIC bidi stream.
        # Defer the SAME unsent operation until the engine signals credit.
        $no_credit = 1 if !defined($op->{transaction})
            && !$op->is_terminal && $conn->{protocol} eq 'h3';
        die "$conn->{protocol} request was not admitted by its engine\n"
            unless $no_credit || defined($op->{transaction}) || $op->is_terminal;
        1;
    };
    if ($ok && $no_credit) {
        delete $self->{active_operations}{$op_id};
        $conn->{active}--;
        $conn->{credit_blocked} = 1;
        $op->{state} = 'queued';
        unshift @{ $pool->{pending} }, $op;
        $self->{pending_count}++;
        return 0;
    }
    unless ($ok) {
        delete $self->{active_operations}{$op_id};
        if (!$op->is_terminal) {
            $conn->{active}--;
            $self->_fail_active($op, "$@");
        }
        $self->_schedule($pool);
    }
    return 1;
}

sub _schedule {
    my ($self, $pool) = @_;
    return if $self->{shutdown};
    return if $pool->{scheduled}++;
    my $ok = eval {
        $self->{factory}{defer}->(sub {
            $pool->{scheduled} = 0;
            $self->_pump($pool);
        });
        1;
    };
    if (!$ok) {
        $pool->{scheduled} = 0;
        warn "Client defer callback failed: $@";
    }
}

sub _fail_active {
    my ($self, $op, $error) = @_;
    return if $op->is_terminal;
    $op->{state} = 'error';
    $op->{error} = $error;
    $op->_cancel_timer;
    $self->_pending_callbacks($op, 1);
}

sub _fail_pending {
    my ($self, $pool, $op, $error) = @_;
    $self->_abandon_connect($pool, $op);
    for (my $i = 0; $i < @{ $pool->{pending} }; $i++) {
        next unless $pool->{pending}[$i] == $op;
        splice @{ $pool->{pending} }, $i, 1;
        $self->{pending_count}--;
        last;
    }
    return if $op->is_terminal;
    $op->{state} = 'error';
    $op->{error} = $error;
    $op->_cancel_timer;
    $self->_pending_callbacks($op, 1);
}

sub _pending_callbacks {
    my ($self, $op, $failed) = @_;
    my $callbacks = $op->{callbacks};
    if ($failed && $callbacks->{on_error}) {
        eval { $callbacks->{on_error}->($op, $op->{error}); 1 }
            or warn $@;
    }
    if ($callbacks->{on_finish}) {
        eval { $callbacks->{on_finish}->($op); 1 }
            or warn $@;
    }
}

sub _cancel_queued {
    my ($self, $op) = @_;
    my $pool = $op->{origin};
    $self->_abandon_connect($pool, $op);
    for (my $i = 0; $i < @{ $pool->{pending} }; $i++) {
        next unless $pool->{pending}[$i] == $op;
        splice @{ $pool->{pending} }, $i, 1;
        $self->{pending_count}--;
        last;
    }
    $self->_pending_callbacks($op, 0);
    $self->_schedule($pool);
}

1;

__END__

=head1 NAME

Unblock::HTTP::Client - Reusable HTTP client with framework transport factories

=head1 SYNOPSIS

    my $client = Unblock::HTTP::Client->new(
        http1 => {}, http2 => {}, http3 => {},
        connect_stream => sub {
            my ($origin, $alpn_choices, $ready) = @_;
            # Framework opens TCP/TLS and completes asynchronously:
            # $ready->(transport => $stream, alpn => $selected_alpn);
        },
        connect_quic => sub {
            my ($origin, $ready) = @_;
            # Framework establishes QUIC and completes asynchronously:
            # $ready->(connection => $ready_quic);
        },
        defer => sub {
            my ($callback) = @_;
            # Framework schedules callback for a later event-loop turn.
        },
        schedule_timer => sub {
            my ($seconds, $callback) = @_;
            # Framework schedules a one-shot timer, then returns a coderef
            # that cancels it when the request finishes.
        },
    );

    # Optional idle_timeout => 30 requires schedule_timer and an adapter
    # should supply release_connection to close its owned transport.
    my $operation = $client->request(
        method => 'GET', url => 'https://example.com/',
        timeout => 15,  # Optional, seconds; requires schedule_timer.
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

=head1 DESCRIPTION

One definition handles requests to many origins. It owns HTTP-aware
scheduling and protocol engine objects, not sockets, TLS or timers.
The attached framework owns transports and calls the real engine's
input(), input_eof(), transport_error() and resume_output() methods.
Factories must retain and feed those returned engines.

C<request()> returns an operation handle immediately. Its C<transaction()>
returns the actual engine transaction after dispatch. No transaction
wrapping, method injection or duplicate receive accumulator is used.

=head1 FACTORIES

C<connect_stream($origin, $alpn_choices, $ready)> is for TCP/TLS. Each
factory invocation MUST establish a distinct transport, or return an
existing idle transport whose ownership is explicitly transferred. Never
attach multiple different engines to the same framework stream. The
origin is a hash with scheme, host, port and authority; ALPN choices are
wire names h2 and/or http/1.1. Call C<$ready-E<gt>(transport =E<gt> $host,
alpn =E<gt> $negotiated)> exactly once after connection establishment.
An empty negotiated ALPN means HTTP/1.1, which must be enabled.
Transport must provide unblock_send/unblock_finish/unblock_abort.
For verified HTTPS TLS connections, supply C<verified_origin =E<gt> 1>
only after the framework has validated the peer certificate and matched
it to the original request hostname. Without that explicit assurance,
received Alt-Svc headers are ignored.

C<connect_quic($origin, $ready)> provides a ready, open QUIC connection
and calls C<$ready-E<gt>(connection =E<gt> $quic)> exactly once. The
Client starts the H3 engine; the framework handles Net::QUIC::Driver
UDP and dynamically scheduled timers. Either factory can report
C<$ready-E<gt>(error =E<gt> $reason)>.

When Alt-Svc has advertised HTTP/3, the C<connect_quic> origin hash
additionally contains C<alternative_host> and C<alternative_port>. The
ordinary C<host>, C<port>, C<authority> and request headers still describe
the ORIGINAL origin. The QUIC factory must authenticate its peer against
that original origin, not merely the alternative endpoint, and return
C<verified_origin =E<gt> 1> after that verification. Otherwise the
alternative is rejected and the unsent request may fall back to TCP.

C<defer($callback)> MUST arrange a later event-loop turn, not call inline.
This prevents queued requests from reentering an HTTP/1 engine before its
previous on_finish callback has unwound.

C<schedule_timer($seconds, $callback)> is an optional framework factory
used when a request has a positive C<timeout> or when the Client is
configured with C<idle_timeout>. It must
schedule a one-shot callback for a future event-loop turn and return a
coderef that cancels that timer. Timer cancellation is invoked once at
terminal cleanup. No event loop, timers or blocking waits are created
inside the core. The timeout covers the ENTIRE request lifetime, including
pending queue time, connection setup and response completion. With no
C<timeout>, no Client operation timer is created.

C<idle_timeout =E<gt> $seconds> is an optional positive idle connection
lifetime. It requires C<schedule_timer> and defaults to disabled. A
connection's timer is armed after its last transaction finishes and no
operations are queued for that origin; it is cancelled upon reuse and
rearmed after the next quiet period. Queued requests waiting for H2 peer
SETTINGS or H3 QUIC stream credit prevent idle expiration. Expiration never
cancels an active transaction.

C<release_connection($host, $engine, $protocol, $reason)> is an optional
framework hook for reclaiming the socket, QUIC resources, and attached
engine exactly once. The reason is C<idle_timeout>, C<evicted>, C<closed>,
C<draining>, or C<network_changed>, or C<shutdown>. If the callback is omitted, the Client calls the engine's
C<close()> when supported, otherwise the connection's C<close()>. Framework
adapters that own transport lifecycle should provide the hook to clean up
their actual socket/QUIC objects. Idle timeouts use one cancellable timer
per idle connection; there is no global polling loop.

=head1 REQUESTS AND SCHEDULING

C<request(method =E<gt> 'GET', url =E<gt> $url, ...)> constructs a
Uniform::HTTP::Request with canonical scheme, authority and origin-form
target. HTTP and HTTPS URLs are accepted; userinfo and fragments are not.
C<http_version =E<gt> '1.1'>, C<'2'> or C<'3'> is strict and cannot
silently downgrade. An ordinary cold request prefers TCP/TLS H2/H1
negotiation; H3 without discovery is only chosen explicitly or when
it is the sole enabled protocol. Authenticated same-host Alt-Svc h3 records
can select a later request's QUIC transport. C<clear>, freshness lifetime,
Age and invalidation after failed connections are honored in a bounded
in-memory cache. Cross-host alternatives and DNS HTTPS discovery are not
supported. No connection-establishment racing occurs.

Defaults: max_pending_requests = 128, max_connections_per_origin = 4,
max_streams_per_connection = 32. Idle expiration is disabled unless
C<idle_timeout> is explicitly set. Every limit must be positive.
The request queue rejects overflow. HTTP/1 handles one request at a
time on each connection. HTTP/2 admission also honors the real engine's
C<can_open_transaction()>, including the peer's advertised concurrent
stream limit and GOAWAY/draining state. If the peer advertises zero streams,
the request remains queued until a later SETTINGS increase; the Client
does not repeatedly discard a healthy connection. HTTP/3 uses the bounded
per-connection cap. If QUIC cannot open a bidirectional stream, the
engine returns no transaction and emits a later one-shot
C<on_request_available> notification when stream availability changes.
The Client preserves the SAME unsent operation in its bounded queue,
blocks that H3 connection until the engine notification, then uses
framework C<defer> before trying admission again. It does not poll
QUIC or manufacture a Transaction. Once an engine returns a real
Transaction, no automatic replay is permitted.
Draining/GOAWAY connections are retired once idle.

Connections are reused by origin and the requested protocol policy.

C<shutdown()> permanently stops new requests, cancels queued and connecting
operations (including their framework timers and cancellable factories),
and releases idle transports with reason C<shutdown>. Accepted transactions
are not cancelled or replayed: active HTTP1/2/3 connections retire after
their last transaction finishes. The method is idempotent, returns the
Client, and makes no new connections. Pending cancellations invoke
on_finish(operation) but not on_error. Late factory readiness cannot
reattach. C<is_shutdown()> reports whether admission has stopped.
Applications may explicitly cancel active handles when immediate
termination is needed. Network changes after shutdown do nothing.

C<network_changed()> is an explicit notification from the framework when
the underlying network identity has changed (for example, a VPN switch or
network interface handoff). The Client does NOT detect network events
itself. The method flushes all cached Alt-Svc hints and discards unused
connections immediately via C<release_connection> with reason
C<network_changed>. A connection with active transactions is marked
retiring; its existing requests are neither cancelled nor replayed,
and it is released only after those transactions finish. Pending requests
retain their operation handles, deadlines, queue positions and callbacks.
Any old in-progress connection factory is abandoned, using its optional
cancellation hook; late readiness is ignored. Advertisements received on
a connection predating the network change cannot repopulate Alt-Svc.
The next scheduler turn establishes fresh transports as capacity permits.

C<pool_stats()> returns a copy of the current scheduler counts with
C<origins>, C<connections>, C<active>, C<idle>, C<retiring>,
C<credit_blocked>, C<connecting>, C<pending>, and C<by_origin>.
C<by_origin> is a list of snapshot hashes with scheme, host, port
and the same counts for each origin (other than C<origins>).
These are observational counts only. No engine, socket, QUIC object or
mutable scheduler structure is returned. It does not run callbacks,
attach transports or create timers.

An operation can be cancelled while still queued/connecting, including
while an H3 connection is waiting for peer bidirectional-stream credit.
A connect factory may return a cancellation coderef to abort establishment
if the initiating operation is cancelled or times out. Later readiness from
an abandoned attempt is ignored, never attached to an HTTP engine, and the
factory is responsible for disposing of any unused transport it created.

With no on_data, the engine buffers the complete response within the
configured per-protocol max_buffered_body_bytes (1 MiB by default);
on_response runs once on successful body completion. With on_data,
streaming is selected automatically; on_response runs at final headers,
on_data($tx, $chunk) receives body bytes, and on_end($tx) runs after the
response body. on_finish runs after terminal state. Engine-issued request
callbacks receive actual engine Transaction objects. Factory failures and
pre-dispatch cancellations cannot have a Transaction: on_error/on_finish
receive the operation handle instead. Cancellation is not an error.
An unsuccessful alternative connection can fall back to TCP BEFORE the
request reaches an HTTP engine, including a POST, because no request has
been transmitted. The Client never automatically replays a dispatched
transaction, even a GET: transport errors cannot establish whether a peer
processed it. A strict HTTP version cannot fall back.

A C<timeout =E<gt> $seconds> requires C<schedule_timer> on the Client.
Expiry before dispatch reports on_error(operation, "request timed out ...")
followed by on_finish(operation); no fake engine Transaction is created.
Expiry after dispatch cancels the real engine transaction using its native
C<cancel()> method, reports on_error($tx, $timeout_error) before
on_finish($tx), and sets the operation state to C<error>. The engine
transaction itself records a cancellation because no protocol parser
error has been invented. An intentional user C<cancel()> remains distinct:
it does not manufacture an on_error callback. No timed-out request is
automatically replayed.

=head1 HTTP/1.1 WEBSOCKETS

C<connect_websocket()> is an opt-in HTTP/1.1 client upgrade, available only
with C<http1 =E<gt> { websocket =E<gt> 1 }>. It uses the same one-object
Client factory and per-origin admission queue as ordinary HTTP requests:

    my $client = Unblock::HTTP::Client->new(
        http1 => { websocket => 1 },
        connect_stream => sub { ... },
        defer => sub { ... },
    );
    my $operation = $client->connect_websocket(
        url => 'wss://example.com/chat',
        on_open => sub {
            my ($ws, $http_tx) = @_;
            $ws->send_text('hello');
        },
        on_message => sub {
            my ($ws, $message, $type) = @_;
        },
        on_error => sub {
            my ($object, $error) = @_;
        },
    );

The optional L<Unblock::WebSocket> library builds and validates the
HTTP/1.1 GET Upgrade request. C<on_open($ws, $http_tx)> runs only after
the HTTP 101 response has passed validation and the framework stream has
been assigned to the WebSocket. The Client operation is the handshake
operation, not a wrapper around the established WebSocket. Its
C<transaction()> returns the real H1 transaction, and C<websocket()>
returns the real C<Unblock::WebSocket::Client> after successful Upgrade.
C<on_finish> observes the HTTP handshake terminal state; it does not wait
for the WebSocket Close handshake.

The method accepts C<url> with ws or wss scheme, optional C<headers>,
C<origin>, C<subprotocols> and C<permessage_deflate> for handshake
negotiation, WebSocket constructor options C<backend>,
C<max_message_size>, C<high_water>, C<low_water> and C<random_bytes>,
and handlers C<on_open>, C<on_message>, C<on_ping>, C<on_pong>,
C<on_close>, C<on_drain>, C<on_error>, C<on_finish> and optional
handshake C<timeout>. C<on_error> may be called with the operation or
HTTP transaction for a handshake failure, and with the WebSocket engine
for a later WebSocket protocol error. C<on_open> is optional, but is
needed to react immediately to asynchronous establishment.

A TCP/TLS host used for a WebSocket must additionally implement
C<unblock_upgrade($ws)> and synchronously select that WebSocket as its
new input, EOF, error and resume-output consumer. It must retain the same
ordered socket output queue: the HTTP request and frames use that queue.
The Client transfers any HTTP1 C<take_remainder()> into the WebSocket
after the transition. For a native borrowed-input provider, C<INPUT_SWITCH>
leaves the unconsumed window with the native transport; it must feed
that suffix into the new consumer exactly once.

After the successful switch, the connection is removed from the HTTP pool
without calling C<release_connection()> or closing the transport. The
framework and WebSocket own the connection lifetime from then on;
C<shutdown()> does not forcibly close an already-established WebSocket.
Other HTTP work for the same origin opens/reuses a different HTTP stream.
Rejected or malformed handshakes fail the original operation; there is
no automatic request replay. Calling C<cancel()> before establishment
uses the usual queued/connecting/active operation cancellation semantics.

=head1 HTTP/2 WEBSOCKET EXTENDED CONNECT

Opt in with C<http2 =E<gt> { websocket =E<gt> 1 }> and select it with
C<http_version =E<gt> '2'> in C<connect_websocket()>. If only HTTP/2
has WebSocket enabled, the method defaults to HTTP/2; if HTTP/1.1
WebSocket is also enabled, the default remains HTTP/1.1.

    my $client = Unblock::HTTP::Client->new(
        http2 => { websocket => 1 },
        connect_stream => sub { ... },
        defer => sub { ... },
    );
    my $operation = $client->connect_websocket(
        url => 'wss://example.com/chat',
        http_version => '2',
        on_open => sub {
            my ($ws, $tx) = @_;
            $ws->send_text('hello over HTTP/2');
        },
        on_message => sub {
            my ($ws, $message, $type) = @_;
        },
    );

The Client waits for the server's first HTTP/2 SETTINGS frame before
issuing Extended CONNECT, and requires the peer to advertise
SETTINGS_ENABLE_CONNECT_PROTOCOL = 1. A peer that does not advertise
support causes an explicit operation error without submitting CONNECT.
The request is never automatically downgraded or replayed; one
waiting connection does not cause repeated TCP connection attempts.
The framework C<defer> hook must schedule work for a later event-loop
turn, not execute inline during an HTTP/2 callback.

The HTTP/2 WebSocket handshake uses CONNECT with the websocket
C<:protocol> pseudo-header and expects status 200. On successful
response validation the callback C<on_open($ws, $tx)> receives the
real WebSocket Client and the original H2 Transaction. The
operation's C<websocket()> accessor returns the same WebSocket.
Incoming DATA is dispatched to that WebSocket's C<input()>. Outgoing
WebSocket frame buffers are accepted by an internal per-stream bridge
and sent through C<$tx-E<gt>write()> on a later deferred turn. Stream
output congestion waits for C<on_drain()>; graceful WebSocket Close
eventually sends request END_STREAM. Errors and cancellation reset
only the affected H2 stream.

Unlike HTTP/1.1 Upgrade, HTTP/2 Extended CONNECT never transfers
the socket or removes it from the pool. Other ordinary HTTP and
WebSocket operations can use independent streams on the same
connection. C<on_finish> therefore runs when the H2 Transaction
actually ends, not when the WebSocket handshake succeeds. C<shutdown()>
allows any active WebSocket streams to finish before releasing the
retiring shared connection, consistent with ordinary active HTTP/2
requests. The framework continues to feed the H2 engine normally;
C<unblock_upgrade()> is neither used nor required for HTTP/2.

=head1 HTTP/3 WEBSOCKET EXTENDED CONNECT

Opt in with C<http3 =E<gt> { websocket =E<gt> 1 }> and select
C<http_version =E<gt> '3'> with C<connect_websocket()>:

    my $client = Unblock::HTTP::Client->new(
        http3 => { websocket => 1 },
        connect_quic => sub { ... },
        defer => sub { ... },
    );
    my $operation = $client->connect_websocket(
        url => 'wss://example.com/chat',
        http_version => '3',
        on_open => sub {
            my ($ws, $tx) = @_;
            $ws->send_text('hello over QUIC');
        },
        on_message => sub {
            my ($ws, $payload, $type) = @_;
        },
    );

When HTTP/3 is the only enabled WebSocket protocol,
C<connect_websocket()> selects version 3 by default; otherwise
the default precedence is HTTP/1.1, HTTP/2, HTTP/3. Version 3
requires an HTTPS origin (a wss URL), and uses a strict connection:
it never falls back to TCP or replays a dispatched CONNECT.

The existing C<connect_quic> factory supplies a ready, authenticated
Net::QUIC connection. The unified Client starts the HTTP/3 engine and
waits for the CURRENT server SETTINGS frame before attempting Extended
CONNECT. The server must advertise SETTINGS_ENABLE_CONNECT_PROTOCOL = 1.
An H3 connection awaiting SETTINGS does not cause new QUIC connection
attempts for the same queued WebSocket. An explicit lack of support
fails the unsent operation with on_error and on_finish and does not
send CONNECT. Remembered 0-RTT SETTINGS alone do not authorize this
WebSocket admission path.

The WebSocket client handshake expects HTTP 200. After validation
C<on_open($ws, $tx)> receives the real WebSocket engine and actual H3
Transaction; C<$operation-E<gt>websocket()> returns that same engine.
Outgoing WebSocket frames use the existing deferred per-stream H2/H3
DATA bridge, with streaming C<write()>, C<on_drain()> and C<end()>.
Incoming DATA calls the WebSocket's C<input()> directly. C<defer> must
not execute callback work inline within QUIC or H3 receive callbacks.
A refused or invalid HTTP/3 handshake records an operation error and
defers stream-local cancellation, without throwing out of the QUIC
receive dispatch. The operation reports C<state() eq 'error'> and invokes
C<on_error($tx, $message)> once; the actual H3 Transaction passed to
C<on_finish> reports C<cancelled> because the stream is intentionally
reset, not because the HTTP/3 parser discovered a protocol error.
This is the same distinction as an active request timeout. Ordinary
HTTP3 requests are unaffected.

The QUIC connection remains multiplexed and pooled throughout. A
WebSocket occupies one H3 request stream; independent WebSockets and
ordinary requests can share that QUIC connection. QUIC bidi credit
exhaustion requeues the SAME unsent operation, waking only when the
existing engine reports new request credit; it does not open a new
connection, discard bytes or replay a sent request. Cancellation or
errors terminate only the relevant stream. Client C<shutdown()>
retires the pooled QUIC connection after its accepted active streams
finish; graceful WebSocket Close sends END_STREAM. The operation's
C<on_finish> observes the final H3 transaction state, not the
successful opening HTTP 200.

=head1 LIMITATIONS

Cross-host Alt-Svc, retries after dispatch,
DNS HTTPS discovery and optional framework convenience
classes are not implemented. Frameworks retain their network transports
and use their normal writable readiness/QUIC timer paths. This branch
requires the coordinated receive/lifecycle engine feature branches,
not released engines.

=head1 LICENSE

MIT License.

=cut
