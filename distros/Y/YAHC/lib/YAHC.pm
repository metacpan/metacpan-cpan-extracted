package YAHC;

use strict;
use warnings;

our $VERSION = '0.035';

use EV;
use Time::HiRes;
use Exporter 'import';
use Scalar::Util qw/weaken/;
use Fcntl qw/F_GETFL F_SETFL O_NONBLOCK/;
use POSIX qw/EINPROGRESS EINTR EAGAIN EWOULDBLOCK strftime/;
use Socket qw/PF_INET SOCK_STREAM $CRLF SOL_SOCKET SO_ERROR inet_aton inet_ntoa pack_sockaddr_in/;
use constant SSL => $ENV{YAHC_NO_SSL} ? 0 : eval 'use IO::Socket::SSL 1.94 (); 1';
use constant SSL_WANT_READ  => SSL ? IO::Socket::SSL::SSL_WANT_READ()  : 0;
use constant SSL_WANT_WRITE => SSL ? IO::Socket::SSL::SSL_WANT_WRITE() : 0;

sub YAHC::Error::NO_ERROR                () { 0 }
sub YAHC::Error::REQUEST_TIMEOUT         () { 1 << 0 }
sub YAHC::Error::CONNECT_TIMEOUT         () { 1 << 1 }
sub YAHC::Error::DRAIN_TIMEOUT           () { 1 << 2 }
sub YAHC::Error::LIFETIME_TIMEOUT        () { 1 << 3 }
sub YAHC::Error::TIMEOUT                 () { 1 << 8 }
sub YAHC::Error::RETRY_LIMIT             () { 1 << 9 }

sub YAHC::Error::CONNECT_ERROR           () { 1 << 10 }
sub YAHC::Error::READ_ERROR              () { 1 << 11 }
sub YAHC::Error::WRITE_ERROR             () { 1 << 12 }
sub YAHC::Error::REQUEST_ERROR           () { 1 << 13 }
sub YAHC::Error::RESPONSE_ERROR          () { 1 << 14 }
sub YAHC::Error::CALLBACK_ERROR          () { 1 << 15 }
sub YAHC::Error::SSL_ERROR               () { 1 << 16 }
sub YAHC::Error::TERMINAL_ERROR          () { 1 << 30 }
sub YAHC::Error::INTERNAL_ERROR          () { 1 << 31 }

sub YAHC::State::INITIALIZED             () { 0   }
sub YAHC::State::RESOLVE_DNS             () { 5   }
sub YAHC::State::CONNECTING              () { 10  }
sub YAHC::State::CONNECTED               () { 15  }
sub YAHC::State::SSL_HANDSHAKE           () { 20  }
sub YAHC::State::WRITING                 () { 25  }
sub YAHC::State::READING                 () { 30  }
sub YAHC::State::USER_ACTION             () { 35  }
sub YAHC::State::COMPLETED               () { 100 } # terminal state

sub YAHC::SocketCache::GET               () { 1 }
sub YAHC::SocketCache::STORE             () { 2 }

use constant {
    # TCP_READ_CHUNK should *NOT* be lower than 16KB because of SSL things.
    # https://metacpan.org/pod/distribution/IO-Socket-SSL/lib/IO/Socket/SSL.pod
    # Another way might be if you try to sysread at least 16kByte all the time.
    # 16kByte is the maximum size of an SSL frame and because sysread returns
    # data from only a single SSL frame you can guarantee that there are no
    # pending data.
    TCP_READ_CHUNK              => 131072,
    CALLBACKS                   => [ qw/init_callback connecting_callback connected_callback
                                        writing_callback reading_callback callback/ ],
};

our @EXPORT_OK = qw/
    yahc_retry_conn
    yahc_reinit_conn
    yahc_terminal_error
    yahc_conn_last_error
    yahc_conn_id
    yahc_conn_url
    yahc_conn_target
    yahc_conn_state
    yahc_conn_errors
    yahc_conn_timeline
    yahc_conn_request
    yahc_conn_response
    yahc_conn_attempt
    yahc_conn_attempts_left
    yahc_conn_socket_cache_id
    yahc_conn_register_error
    yahc_conn_user_data
/;

our %EXPORT_TAGS = (all => \@EXPORT_OK);
my $LAST_CONNECTION_ID;

################################################################################
# User facing functons
################################################################################

sub new {
    my ($class, $args) = @_;
    $LAST_CONNECTION_ID = $$ * 1000 unless defined $LAST_CONNECTION_ID;

    die 'YAHC: ->new() expect args to be a hashref' if defined $args and ref($args) ne 'HASH';
    die 'YAHC: please do `my ($yahc, $yahc_storage) = YAHC::new()` and keep both these objects in the same scope' unless wantarray;

    # wrapping target selection here allows all client share same list
    # and more importantly to share index within the list
    $args->{_target}  = _wrap_host(delete $args->{host})             if $args->{host};
    $args->{_backoff} = _wrap_backoff(delete $args->{backoff_delay}) if $args->{backoff_delay};
    $args->{_socket_cache} = _wrap_socket_cache(delete $args->{socket_cache}) if $args->{socket_cache};

    my %storage;
    my $self = bless {
        loop                => delete($args->{loop}) || new EV::Loop,
        pid                 => $$, # store pid to detect forks
        storage             => \%storage,
        debug               => delete $args->{debug} || $ENV{YAHC_DEBUG} || 0,
        keep_timeline       => delete $args->{keep_timeline} || $ENV{YAHC_TIMELINE} || 0,
        pool_args           => $args,
    }, $class;

    # this's a radical way of avoiding circular references.
    # let's see how it plays out in practise.
    weaken($self->{storage});
    weaken($self->{$_} = $storage{$_} = {}) for qw/watchers callbacks connections/;

    if (delete $args->{account_for_signals}) {
        _log_message('YAHC: enable account_for_signals logic') if $self->{debug};
        my $sigcheck = $self->{watchers}{_sigcheck} = $self->{loop}->check(sub {});
        $sigcheck->keepalive(0);
    }

    return $self, \%storage;
}

sub request {
    my ($self, @args) = @_;
    die 'YAHC: new_request() expects arguments' unless @args;
    die 'YAHC: storage object is destroyed' unless $self->{storage};

    my ($conn_id, $request) = (@args == 1 ? ('connection_' . $LAST_CONNECTION_ID++, $args[0]) : @args);
    die "YAHC: Connection with name '$conn_id' already exists\n"
        if exists $self->{connections}{$conn_id};

    my $pool_args = $self->{pool_args};
    do { $request->{$_} ||= $pool_args->{$_} if $pool_args->{$_} } foreach (qw/host port scheme head
                                                                               request_timeout connect_timeout
                                                                               drain_timeout lifetime_timeout/);
    if ($request->{host}) {
        $request->{_target} = _wrap_host($request->{host});
    } elsif ($pool_args->{_target}) {
        $request->{_target} = $pool_args->{_target};
    } else {
        die "YAHC: host must be defined in request() or in new()\n";
    }

    if ($request->{backoff_delay}) {
        $request->{_backoff} = _wrap_backoff($request->{backoff_delay});
    } elsif ($pool_args->{_backoff}) {
        $request->{_backoff} = $pool_args->{_backoff};
    }

    if ($request->{socket_cache}) {
        $request->{_socket_cache} = _wrap_socket_cache($request->{socket_cache});
    } elsif ($pool_args->{_socket_cache}) {
        $request->{_socket_cache} = $pool_args->{_socket_cache};
    }

    my $scheme = $request->{scheme} ||= 'http';
    my $debug = delete $request->{debug} || $self->{debug};
    my $keep_timeline = delete $request->{keep_timeline} || $self->{keep_timeline};
    my $user_data = delete $request->{user_data};

    my $conn = {
        id          => $conn_id,
        request     => $request,
        response    => { status => 0 },
        attempt     => 0,
        retries     => $request->{retries} || 0,
        state       => YAHC::State::INITIALIZED(),
        selected_target => [],
        ($debug                   ? (debug => $debug) : ()),
        ($keep_timeline           ? (keep_timeline => $keep_timeline) : ()),
        ($debug || $keep_timeline ? (debug_or_timeline => 1) : ()),
        (defined $user_data       ? (user_data => $user_data) : ()),
        pid         => $$,
    };

    my %callbacks;
    foreach (@{ CALLBACKS() }) {
        next unless exists $request->{$_};
        my $cb = $callbacks{$_} = delete $request->{$_};
        $conn->{"has_$_"} = !!$cb;
    }

    $self->{watchers}{$conn_id} = {};
    $self->{callbacks}{$conn_id} = \%callbacks;
    $self->{connections}{$conn_id} = $conn;

    _set_lifetime_timer($self, $conn_id) if $request->{lifetime_timeout};

    return $conn if $request->{_test}; # for testing purposes
    _set_init_state($self, $conn_id);

    # if user fire new request in a callback we need to update stop_condition
    my $stop_condition = $self->{stop_condition};
    if ($stop_condition && $stop_condition->{all}) {
        $stop_condition->{connections}{$conn_id} = 1;
    }

    return $conn;
}

sub drop {
    my ($self, $c, $force_socket_close) = @_;
    my $conn_id = ref($c) eq 'HASH' ? $c->{id} : $c;
    my $conn = $self->{connections}{$conn_id} or return;
    _register_in_timeline($conn, "dropping connection from pool") if exists $conn->{debug_or_timeline};
    _set_completed_state($self, $conn_id, $force_socket_close) unless $conn->{state} == YAHC::State::COMPLETED();
    return $conn;
}

sub run         { shift->_run(0, @_)            }
sub run_once    { shift->_run(EV::RUN_ONCE)     }
sub run_tick    { shift->_run(EV::RUN_NOWAIT)   }
sub is_running  { !!shift->{loop}->depth        }
sub loop        { shift->{loop}                 }

sub break {
    my ($self, $reason) = @_;
    return unless $self->is_running;
    _log_message('YAHC: pid %d breaking event loop because %s', $$, ($reason || 'no reason')) if $self->{debug};
    $self->{loop}->break(EV::BREAK_ONE)
}

################################################################################
# Routines to manipulate connections (also user facing)
################################################################################

sub yahc_terminal_error {
    return (($_[0] & YAHC::Error::TERMINAL_ERROR()) == YAHC::Error::TERMINAL_ERROR()) ? 1 : 0;
}

sub yahc_reinit_conn {
    my ($conn, $args) = @_;
    die "YAHC: cannot reinit completed connection\n"
        if $conn->{state} >= YAHC::State::COMPLETED();

    $conn->{attempt} = 0;
    $conn->{state} = YAHC::State::INITIALIZED();
    return unless defined $args && ref($args) eq 'HASH';

    my $request = $conn->{request};
    $request->{_target}  = _wrap_host(delete $args->{host})             if $args->{host};
    $request->{_backoff} = _wrap_backoff(delete $args->{backoff_delay}) if $args->{backoff_delay};
    do { $request->{$_} = $args->{$_} if $args->{$_} } foreach (keys %$args);
}

sub yahc_retry_conn {
    my ($conn, $args) = @_;
    die "YAHC: cannot retry completed connection\n"
        if $conn->{state} >= YAHC::State::COMPLETED();
    return unless yahc_conn_attempts_left($conn) > 0;

    $conn->{state} = YAHC::State::INITIALIZED();
    return unless defined $args && ref($args) eq 'HASH';

    $conn->{request}{_backoff} = _wrap_backoff($args->{backoff_delay})
        if $args->{backoff_delay};
}

sub yahc_conn_last_error {
    my $conn = shift;
    return unless $conn->{errors} && @{ $conn->{errors} };
    return wantarray ? @{ $conn->{errors}[-1] } : $conn->{errors}[-1];
}

sub yahc_conn_id            { $_[0]->{id}       }
sub yahc_conn_state         { $_[0]->{state}    }
sub yahc_conn_errors        { $_[0]->{errors}   }
sub yahc_conn_timeline      { $_[0]->{timeline} }
sub yahc_conn_request       { $_[0]->{request}  }
sub yahc_conn_response      { $_[0]->{response} }
sub yahc_conn_attempt       { $_[0]->{attempt}  }
sub yahc_conn_attempts_left { $_[0]->{attempt} > $_[0]->{retries} ? 0 : $_[0]->{retries} - $_[0]->{attempt} + 1 }

sub yahc_conn_target {
    my $target = $_[0]->{selected_target};
    return unless $target && scalar @{ $target };
    my ($host, $ip, $port) = @{ $target };
    return ($host || $ip) . ($port ne '80' && $port ne '443' ? ":$port" : '');
}

sub yahc_conn_url {
    my $target = $_[0]->{selected_target};
    my $request = $_[0]->{request};
    return unless $target && @{ $target };

    my ($host, $ip, $port, $scheme) = @{ $target };
    return "$scheme://"
           . ($host || $ip)
           . ($port ne '80' && $port ne '443' ? ":$port" : '')
           . ($request->{path} || "/")
           . (defined $request->{query_string} ? ("?" . $request->{query_string}) : "");
}

sub yahc_conn_user_data {
    my $conn = shift;
    $conn->{user_data} = $_[0] if @_;
    return $conn->{user_data};
}

################################################################################
# Internals
################################################################################

sub _run {
    my ($self, $how, $until_state, @cs) = @_;
    die "YAHC: storage object is destroyed\n" unless $self->{storage};
    die "YAHC: reentering run\n" if $self->{loop}->depth;

    if ($self->{pid} != $$) {
        _log_message('YAHC: reinitializing event loop after forking') if $self->{debug};
        $self->{pid} = $$;
        $self->{loop}->loop_fork;

        my $active_connections = grep { $$ != $_->{pid} } values %{ $self->{connections} };
        warn "YAHC has $active_connections active connections after a fork, consider dropping them!"
            if $active_connections;
    }

    if (defined $until_state) {
        my $until_state_str = _strstate($until_state);
        die "YAHC: unknown until_state $until_state\n" if $until_state_str =~ m/unknown/;

        my $is_all = (@cs == 0);
        my @connections = $is_all ? values %{ $self->{connections} }
                                  : map { $self->{connections}{$_} || () }
                                    map { ref($_) eq 'HASH' ? $_->{id} : $_ } @cs;

        $self->{stop_condition} = {
            all             => $is_all,
            expected_state  => $until_state,
            connections     => { map { $_->{id} => 1 } grep { $_->{state} < $until_state } @connections },
        };
    } else {
        delete $self->{stop_condition};
    }

    my $loop = $self->{loop};
    $loop->now_update;

    if ($self->{debug}) {
        my $iterations = $loop->iteration;
        _log_message('YAHC: pid %d entering event loop%s', $$, ($until_state ? " with until state " . _strstate($until_state) : ''));
        $loop->run($how || 0);
        _log_message('YAHC: pid %d exited from event loop after %d iterations', $$, $loop->iteration - $iterations);
    } else {
        $loop->run($how || 0);
    }
}

sub _check_stop_condition {
    my ($self, $conn) = @_;
    my $stop_condition = $self->{stop_condition};
    return if !$stop_condition || $conn->{state} < $stop_condition->{expected_state};

    delete $stop_condition->{connections}{$conn->{id}};
    my $awaiting_connections = scalar keys %{ $stop_condition->{connections} };
    my $expected_state = $stop_condition->{expected_state};

    if ($awaiting_connections == 0) {
        $self->break(sprintf("until state '%s' is reached", _strstate($expected_state)));
        return 1;
    }

    _log_message("YAHC: still have %d connections awaiting state '%s'",
                 $awaiting_connections, _strstate($expected_state)) if $self->{debug};
}

################################################################################
# IO routines
################################################################################

sub _set_init_state {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";

    $conn->{response} = { status => 0 };
    $conn->{state} = YAHC::State::INITIALIZED();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    _call_state_callback($self, $conn, 'init_callback') if exists $conn->{has_init_callback};

    _close_or_cache_socket($self, $conn, 1); # force connection close if any (likely not)
    my $watchers = _delete_watchers_but_lifetime_timer($self, $conn_id); # implicit stop of all watchers

    return _set_user_action_state($self, $conn_id, YAHC::Error::RETRY_LIMIT(), "retries limit reached")
        if $conn->{attempt} > $conn->{retries};

    # don't move attempt increment before boundary check !!!
    # otherwise we can get off-by-one error in yahc_conn_attempts_left
    my $attempt = ++$conn->{attempt};
    if ($attempt > 1 && exists $conn->{request}{_backoff}) {
        my $backoff_delay = eval { $conn->{request}{_backoff}->($conn) };
        if (my $error = $@) {
            return _set_user_action_state($self, $conn_id, YAHC::Error::CALLBACK_ERROR() | YAHC::Error::TERMINAL_ERROR(),
                "exception in backoff callback (close connection): $error");
        };

        if ($backoff_delay) {
            $self->{loop}->now_update;
            _register_in_timeline($conn, "setting backoff_timer to %.3fs", $backoff_delay) if exists $conn->{debug_or_timeline};
            $watchers->{backoff_timer} = $self->{loop}->timer($backoff_delay, 0, _get_safe_wrapper($self, $conn, sub {
                _register_in_timeline($conn, "backoff timer of %.3fs expired, time for new attempt", $backoff_delay) if exists $conn->{debug_or_timeline};
                _set_init_state($self, $conn_id) if _init_helper($self, $conn_id) == 1;
            }));
            return;
        }
    }

    if (_init_helper($self, $conn_id) == 1) {
        _register_in_timeline($conn, "do attempt on next EV iteration, (iteration=%d)", $self->{loop}->iteration)
            if exists $conn->{debug_or_timeline};

        # from EV docs:
        # idle watcher call the callback when there are no other pending
        # watchers of the same or higher priority. The idle watchers are
        # being called once per event loop iteration - until stopped.
        #
        # so, what we do is we start idle watcher with priority 1 which is
        # higher then 0 used by all IO watchers. As result, the callback
        # will be called at the end of this iteration. And others if neccessary.

        my $retry_watcher = $watchers->{retry} ||= $self->{loop}->idle_ns(_get_safe_wrapper($self, $conn, sub {
            shift->stop; # stop this watcher, _set_init_state will start if neccessary
            _register_in_timeline($conn, "time for new attempt (iteration=%d)", $self->{loop}->iteration)
                if exists $conn->{debug_or_timeline};
            _set_init_state($self, $conn_id)
        }));

        $retry_watcher->priority(1);
        $retry_watcher->start;
    };
}

sub _init_helper {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    my $request = $conn->{request};

    $self->{loop}->now_update; # update time for timers
    _set_until_state_timer($self, $conn_id, 'request_timeout', YAHC::State::USER_ACTION(), YAHC::Error::TIMEOUT() | YAHC::Error::REQUEST_TIMEOUT())
        if $request->{request_timeout};
    _set_until_state_timer($self, $conn_id, 'connect_timeout', YAHC::State::CONNECTED(),   YAHC::Error::TIMEOUT() | YAHC::Error::CONNECT_TIMEOUT())
        if $request->{connect_timeout};
    _set_until_state_timer($self, $conn_id, 'drain_timeout',   YAHC::State::READING(),     YAHC::Error::TIMEOUT() | YAHC::Error::DRAIN_TIMEOUT())
        if $request->{drain_timeout};

    eval {
        my ($host, $ip, $port, $scheme) = _get_next_target($conn);
        _register_in_timeline($conn, "Target $scheme://$host:$port ($ip:$port) chosen for attempt #%d", $conn->{attempt})
            if exists $conn->{debug_or_timeline};

        my $sock;
        if (my $socket_cache = $request->{_socket_cache}) {
            $sock = $socket_cache->(YAHC::SocketCache::GET(), $conn);
        }

        if (defined $sock) {
            _register_in_timeline($conn, "reuse socket") if $conn->{debug_or_timeline};
            $watchers->{_fh} = $sock;
            $watchers->{io} = $self->{loop}->io($sock, EV::WRITE, sub {});
            _set_write_state($self, $conn_id);
        } else {
            _register_in_timeline($conn, "build new socket") if $conn->{debug_or_timeline};
            $sock = _build_socket_and_connect($ip, $port);
            _set_connecting_state($self, $conn_id, $sock);
        }

        1;
    } or do {
        my $error = $@ || 'zombie error';
        $error =~ s/\s+$//o;
        yahc_conn_register_error($conn, YAHC::Error::CONNECT_ERROR(), "connection attempt %d failed: %s", $conn->{attempt}, $error);
        return 1;
    };

    return 0;
}

sub _set_connecting_state {
    my ($self, $conn_id, $sock) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    $conn->{state} = YAHC::State::CONNECTING();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    _call_state_callback($self, $conn, 'connecting_callback') if exists $conn->{has_connecting_callback};

    my $connecting_cb = _get_safe_wrapper($self, $conn, sub {
        my $sockopt = getsockopt($sock, SOL_SOCKET, SO_ERROR);
        if (!$sockopt) {
            yahc_conn_register_error($conn, YAHC::Error::CONNECT_ERROR(), "Failed to do getsockopt(): '%s' errno=%d", "$!", $!+0);
            _set_init_state($self, $conn_id);
            return;
        }

        if (my $err = unpack("L", $sockopt)) {
            my $strerror = POSIX::strerror($err) || '<unknown POSIX error>';
            yahc_conn_register_error($conn, YAHC::Error::CONNECT_ERROR(), "Failed to connect: $strerror");
            _set_init_state($self, $conn_id);
            return;
        }

        _set_connected_state($self, $conn_id);
    });

    $watchers->{_fh} = $sock;
    $watchers->{io} = $self->{loop}->io($sock, EV::WRITE, $connecting_cb);
    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _set_connected_state {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    $conn->{state} = YAHC::State::CONNECTED();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    _call_state_callback($self, $conn, 'connected_callback') if exists $conn->{has_connected_callback};

    my $connected_cb = _get_safe_wrapper($self, $conn, sub {
        if ($conn->{is_ssl}) {
            _set_ssl_handshake_state($self, $conn_id);
        } else {
            _set_write_state($self, $conn_id);
        }
    });

    #$watcher->events(EV::WRITE);
    $watchers->{io}->cb($connected_cb);
    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _set_ssl_handshake_state {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    $conn->{state} = YAHC::State::SSL_HANDSHAKE();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    #_call_state_callback($self, $conn, 'writing_callback') if $conn->{has_writing_callback}; TODO

    my $fh = $watchers->{_fh};
    my $hostname = $conn->{selected_target}[0];

    my %options = (
        SSL_verifycn_name => $hostname,
        IO::Socket::SSL->can_client_sni ? ( SSL_hostname => $hostname ) : (),
        %{ $conn->{request}{ssl_options} || {} },
    );

    if ($conn->{debug_or_timeline}) {
        my $options_msg = join(', ', map { "$_=" . ($options{$_} || '') } keys %options);
        _register_in_timeline($conn, "start SSL handshake with options: $options_msg");
    }

    if (!IO::Socket::SSL->start_SSL($fh, %options, SSL_startHandshake => 0)) {
        return _set_user_action_state($self, $conn_id, YAHC::Error::SSL_ERROR() | YAHC::Error::TERMINAL_ERROR(),
            sprintf("failed to start SSL session: %s", _format_ssl_error()));
    }

    my $handshake_cb = _get_safe_wrapper($self, $conn, sub {
        my $w = shift;
        if ($fh->connect_SSL) {
            _register_in_timeline($conn, "SSL handshake successfully completed") if exists $conn->{debug_or_timeline};
            return _set_write_state($self, $conn_id);
        }

        if ($! == EWOULDBLOCK) {
            return $w->events(EV::READ)  if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_READ;
            return $w->events(EV::WRITE) if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_WRITE;
        }

        yahc_conn_register_error($conn, YAHC::Error::SSL_ERROR(), "Failed to complete SSL handshake: %s", _format_ssl_error());
        _set_init_state($self, $conn_id);
    });

    my $watcher = $watchers->{io};
    $watcher->cb($handshake_cb);
    $watcher->events(EV::WRITE | EV::READ);
    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _set_write_state {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    $conn->{state} = YAHC::State::WRITING();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    _call_state_callback($self, $conn, 'writing_callback') if exists $conn->{has_writing_callback};

    my $fh = $watchers->{_fh};
    my $buf = _build_http_message($conn);
    my $length = length($buf);

    warn "YAHC: HTTP message has UTF8 flag set! This will result in poor performance, see docs for details!"
        if utf8::is_utf8($buf);

    _register_in_timeline($conn, "writing body of %d bytes\n%s", $length, ($length > 1024? substr($buf, 0, 1024) . '... (cut to 1024 bytes)' : $buf))
        if exists $conn->{debug_or_timeline};

    my $write_cb = _get_safe_wrapper($self, $conn, sub {
        my $w = shift;
        my $wlen = syswrite($fh, $buf, $length);

        if (!defined $wlen) {
            if ($conn->{is_ssl}) {
                if ($! == EWOULDBLOCK) {
                    return $w->events(EV::READ)  if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_READ;
                    return $w->events(EV::WRITE) if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_WRITE;
                }

                yahc_conn_register_error($conn, YAHC::Error::WRITE_ERROR() | YAHC::Error::SSL_ERROR(), "Failed to send HTTPS data: %s", _format_ssl_error());
                return _set_init_state($self, $conn_id);
            }

            return if $! == EWOULDBLOCK || $! == EINTR || $! == EAGAIN;
            yahc_conn_register_error($conn, YAHC::Error::WRITE_ERROR(), "Failed to send HTTP data: '%s' errno=%d", "$!", $!+0);
            _set_init_state($self, $conn_id);
        } elsif ($wlen == 0) {
            yahc_conn_register_error($conn, YAHC::Error::WRITE_ERROR(), "syswrite returned 0");
            _set_init_state($self, $conn_id);
        } else {
            substr($buf, 0, $wlen, '');
            $length -= $wlen;
            _set_read_state($self, $conn_id) if $length == 0;
        }
    });

    my $watcher = $watchers->{io};
    $watcher->cb($write_cb);
    $watcher->events(EV::WRITE);
    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _set_read_state {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    $conn->{state} = YAHC::State::READING();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    _call_state_callback($self, $conn, 'reading_callback') if exists $conn->{has_reading_callback};

    my $buf = '';
    my $neck_pos = 0;
    my $decapitated = 0;
    my $content_length = 0;
    my $no_content_length = 0;
    my $is_chunked = 0;
    my $fh = $watchers->{_fh};
    my $chunk_size = 0;
    my $body = ''; # used for chunked encoding

    my $read_cb = _get_safe_wrapper($self, $conn, sub {
        my $w = shift;
        my $rlen = sysread($fh, my $b = '', TCP_READ_CHUNK);
        if (!defined $rlen) {
            if ($conn->{is_ssl}) {
                if ($! == EWOULDBLOCK) {
                    return $w->events(EV::READ)  if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_READ;
                    return $w->events(EV::WRITE) if $IO::Socket::SSL::SSL_ERROR == SSL_WANT_WRITE;
                }

                yahc_conn_register_error($conn, YAHC::Error::READ_ERROR() | YAHC::Error::SSL_ERROR(), "Failed to receive HTTPS data: %s", _format_ssl_error());
                return _set_init_state($self, $conn_id);
            }

            return if $! == EWOULDBLOCK || $! == EINTR || $! == EAGAIN;
            yahc_conn_register_error($conn, YAHC::Error::READ_ERROR(), "Failed to receive HTTP data: '%s' errno=%d", "$!", $!+0);
            _set_init_state($self, $conn_id);
        } elsif ($rlen == 0) {
            if ($no_content_length) {
                $conn->{response}{body} = $buf.$b;
                _set_user_action_state($self, $conn_id);
                return;
            }

            if ($content_length > 0) {
                yahc_conn_register_error($conn, YAHC::Error::READ_ERROR(), "Premature EOF, expect %d bytes more", $content_length - length($buf));
            } else {
                yahc_conn_register_error($conn, YAHC::Error::READ_ERROR(), "Premature EOF");
            }
            _set_init_state($self, $conn_id);
        } else {
            $buf .= $b;
            if (!$decapitated && ($neck_pos = index($buf, "${CRLF}${CRLF}")) > 0) {
                my $headers = _parse_http_headers($conn, substr($buf, 0, $neck_pos, '')); # $headers are always defined but might be empty, maybe fix later
                $is_chunked = ($headers->{'transfer-encoding'} || '') eq 'chunked';

                if ($is_chunked && exists $headers->{'trailer'}) {
                    _set_user_action_state($self, $conn_id, YAHC::Error::RESPONSE_ERROR(), "Chunked HTTP response with Trailer header");
                    return;
                }

                $decapitated = 1;
                substr($buf, 0, 4, ''); # 4 = length("$CRLF$CRLF")

                # Attempt to correctly determine content length, see RFC 2616 section 4.4
                if (($conn->{request}->{method} || '') eq 'HEAD' || $conn->{response}->{status} =~ /^(1..|204|304)$/) { # 1.
                    $content_length = 0;
                } elsif ($is_chunked) { # 2. (sort of, should actually also care for non-chunked transfer encodings)
                    # No content length, use chunked transfer encoding instead
                } elsif (exists $headers->{'content-length'}) { # 3.
                    $content_length = $headers->{'content-length'};
                    if ($content_length !~ m#\A[0-9]+\z#) {
                        _set_user_action_state($self, $conn_id, YAHC::Error::RESPONSE_ERROR(), "Not-numeric Content-Length received on the response");
                        return;
                    }
                } else {
                    # byteranges (point .4 on the spec) not supported
                    $no_content_length = 1;
                }
            }

            if ($decapitated && $is_chunked) {
                # in order to get the smallest chunk size we need
                # at least 4 bytes (2xCLRF), and there *MUST* be
                # last chunk which is at least 5 bytes (0\r\n\r\n)
                # so we can safely ignore $bufs that have less than 5 bytes
                while (length($buf) > ($chunk_size + 4)) {
                    my $neck_pos = index($buf, ${CRLF});
                    if ($neck_pos > 0) {
                        # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html
                        # All HTTP/1.1 applications MUST be able to receive and
                        # decode the "chunked" transfer-coding, and MUST ignore
                        # chunk-extension extensions they do not understand.
                        my ($s) = split(';', substr($buf, 0, $neck_pos), 1);
                        $chunk_size = hex($s);

                        _register_in_timeline($conn, "parsing chunk of size $chunk_size bytes") if exists $conn->{debug_or_timeline};
                        if ($chunk_size == 0) { # end with, but as soon as we see 0\r\n\r\n we just mark it as done
                            $conn->{response}{body} = $body;
                            _set_user_action_state($self, $conn_id);
                            return;
                        } else {
                            if (length($buf) >= $chunk_size + $neck_pos + 2 + 2) {
                                $body .= substr($buf, $neck_pos + 2, $chunk_size);
                                substr($buf, 0, $neck_pos + 2 + $chunk_size + 2, '');
                                $chunk_size = 0;
                            } else {
                                last; # dont have enough data in this pass, wait for one more read
                            }
                        }
                    } else {
                        last if $neck_pos < 0 && $chunk_size == 0; # in case we couldnt get the chunk size in one go, we must concat until we have something
                        _set_user_action_state($self, $conn_id, YAHC::Error::RESPONSE_ERROR(), "error processing chunked data, couldnt find CLRF[index:$neck_pos] in buf");
                        return;
                    }
                }
            } elsif ($decapitated && !$no_content_length && length($buf) >= $content_length) {
                $conn->{response}{body} = (length($buf) > $content_length ? substr($buf, 0, $content_length) : $buf);
                _set_user_action_state($self, $conn_id);
            }
        }
    });

    my $watcher = $watchers->{io};
    $watcher->cb($read_cb);
    $watcher->events(EV::READ);
    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _set_user_action_state {
    my ($self, $conn_id, $error, $strerror) = @_;
    $error ||= YAHC::Error::NO_ERROR();
    $strerror ||= '<no strerror>';

    # this state may be used in critical places,
    # so it should *NEVER* throw exception
    my $conn = $self->{connections}{$conn_id}
      or warn "YAHC: try to _set_user_action_state() for unknown connection $conn_id",
        return;

    $conn->{state} = YAHC::State::USER_ACTION();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};
    yahc_conn_register_error($conn, $error, $strerror) if $error != YAHC::Error::NO_ERROR;

    _close_or_cache_socket($self, $conn, $error != YAHC::Error::NO_ERROR);
    return _set_completed_state($self, $conn_id) unless exists $conn->{has_callback};

    eval {
        _register_in_timeline($conn, "call callback%s", $error ? " error=$error, strerror='$strerror'" : '') if exists $conn->{debug_or_timeline};
        my $cb = $self->{callbacks}{$conn_id}{callback};
        $cb->($conn, $error, $strerror);
        1;
    } or do {
        my $error = $@ || 'zombie error';
        yahc_conn_register_error($conn, YAHC::Error::CALLBACK_ERROR() | YAHC::Error::TERMINAL_ERROR(), "Exception in user action callback (close connection): $error");
        $self->{state} = YAHC::State::COMPLETED();
    };

    $self->{loop}->now_update;

    my $state = $conn->{state};
    if (yahc_terminal_error($error)) {
        yahc_conn_register_error($conn, YAHC::Error::CALLBACK_ERROR() | YAHC::Error::TERMINAL_ERROR(), "ignoring changed state due to terminal error")
            unless $state == YAHC::State::USER_ACTION() || $state == YAHC::State::COMPLETED();
        _set_completed_state($self, $conn_id, 1);
        return
    }

    _register_in_timeline($conn, "after invoking callback state is %s", _strstate($state)) if exists $conn->{debug_or_timeline};

    if ($state == YAHC::State::INITIALIZED()) {
        _set_init_state($self, $conn_id);
    } elsif ($state == YAHC::State::USER_ACTION() || $state == YAHC::State::COMPLETED()) {
        _set_completed_state($self, $conn_id);
    } else {
        yahc_conn_register_error($conn, YAHC::Error::CALLBACK_ERROR() | YAHC::Error::TERMINAL_ERROR(), "callback set unsupported state");
        _set_completed_state($self, $conn_id);
    }
}

sub _set_completed_state {
    my ($self, $conn_id, $force_socket_close) = @_;

    # this's a terminal state,
    # so setting this state should *NEVER* fail
    delete $self->{callbacks}{$conn_id};
    my $conn = delete $self->{connections}{$conn_id};

    if (!defined $conn) {
        delete($self->{watchers}{$conn_id}), # implicit stop of all watchers
        return;
    }

    $conn->{state} = YAHC::State::COMPLETED();
    _register_in_timeline($conn, "new state %s", _strstate($conn->{state})) if exists $conn->{debug_or_timeline};

    _close_or_cache_socket($self, $conn, $force_socket_close);
    delete $self->{watchers}{$conn_id}; # implicit stop of all watchers

    _check_stop_condition($self, $conn) if exists $self->{stop_condition};
}

sub _build_socket_and_connect {
    my ($ip, $port) = @_;

    my $sock;
    socket($sock, PF_INET, SOCK_STREAM, 0)
        or die sprintf("Failed to construct TCP socket: '%s' errno=%d\n", "$!", $!+0);

    my $flags = fcntl($sock, F_GETFL, 0) or die sprintf("Failed to get fcntl F_GETFL flag: '%s' errno=%d\n", "$!", $!+0);
    fcntl($sock, F_SETFL, $flags | O_NONBLOCK) or die sprintf("Failed to set fcntl O_NONBLOCK flag: '%s' errno=%d\n", "$!", $!+0);

    my $ip_addr = inet_aton($ip) or die "Invalid IP address";
    my $addr = pack_sockaddr_in($port, $ip_addr);
    if (!connect($sock, $addr) && $! != EINPROGRESS) {
        die sprintf("Failed to connect: '%s' errno=%d\n", "$!", $!+0);
    }

    return $sock;
}

sub _get_next_target {
    my $conn = shift;
    my ($host, $ip, $port, $scheme) = $conn->{request}{_target}->($conn);

    # TODO STATE_RESOLVE_DNS
    ($host, $port) = ($1, $2) if !$port && $host =~ m/^(.+):([0-9]+)$/o;
    $ip = $host if !$ip && $host =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/o;
    $ip ||= inet_ntoa(gethostbyname($host) or die "Failed to resolve $host\n");
    $scheme ||= $conn->{request}{scheme} || 'http';
    $port   ||= $conn->{request}{port} || ($scheme eq 'https' ? 443 : 80);

    $conn->{is_ssl} = $scheme eq 'https';
    return @{ $conn->{selected_target} = [ $host, $ip, $port, $scheme ] };
}

# this and following functions are used in terminal state
# so they should *NEVER* fail
sub _close_or_cache_socket {
    my ($self, $conn, $force_close) = @_;
    my $watchers = $self->{watchers}{$conn->{id}} or return;
    my $fh = delete $watchers->{_fh} or return;
    delete $watchers->{io}; # implicit stop

    my $socket_cache = $conn->{request}{_socket_cache};

    # Stolen from Hijk. Thanks guys!!!
    # We always close connections for 1.0 because some servers LIE
    # and say that they're 1.0 but don't close the connection on
    # us! An example of this. Test::HTTP::Server (used by the
    # ShardedKV::Storage::Rest tests) is an example of such a
    # server. In either case we can't cache a connection for a 1.0
    # server anyway, so BEGONE!

    if (   $force_close
        || !defined $socket_cache
        || (($conn->{request}{proto} || '') eq 'HTTP/1.0')
        || (($conn->{response}{proto} || '') eq 'HTTP/1.0')
        || (($conn->{response}{head}{connection} || '') eq 'close'))
    {
        _register_in_timeline($conn, "drop socket") if $conn->{debug_or_timeline};
        close($fh) if ref($fh) eq 'GLOB'; # checking ref to avoid exception
        return;
    }

    _register_in_timeline($conn, "storing socket for later use") if $conn->{debug_or_timeline};
    eval { $socket_cache->(YAHC::SocketCache::STORE(), $conn, $fh); 1; } or do {
        yahc_conn_register_error($conn, YAHC::Error::CALLBACK_ERROR(), "Exception in socket_cache callback (ignore error): $@");
    };
}

sub yahc_conn_socket_cache_id {
    my $conn = shift;
    return unless defined $conn;
    my ($host, undef, $port, $scheme) = @{ $conn->{selected_target} || [] };
    return unless $host && $port && $scheme;
    # Use $; so we can use the $socket_cache->{$$, $host, $port} idiom to access the cache.
    return join($;, $$, $host, $port, $scheme);
}

################################################################################
# Timers
################################################################################

sub _set_until_state_timer {
    my ($self, $conn_id, $timeout_name, $state, $error_to_report) = @_;

    my $timer_name = $timeout_name . '_timer';
    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    delete $watchers->{$timer_name}; # implicit stop
    my $timeout = $conn->{request}{$timeout_name};
    return unless $timeout;

    my $timer_cb = sub { # there is nothing what can throw exception
        if ($conn->{state} < $state) {
            yahc_conn_register_error($conn, $error_to_report, "$timeout_name of %.3fs expired", $timeout);
            _set_init_state($self, $conn_id);
        } else {
            _register_in_timeline($conn, "delete $timer_name") if exists $conn->{debug_or_timeline};
        }
    };

    _register_in_timeline($conn, "setting $timeout_name to %.3fs", $timeout) if exists $conn->{debug_or_timeline};

    # caller should call now_update
    my $w = $watchers->{$timer_name} = $self->{loop}->timer_ns($timeout, 0, $timer_cb);
    $w->priority(2); # set highest priority
    $w->start;
}

sub _set_lifetime_timer {
    my ($self, $conn_id) = @_;

    my $conn = $self->{connections}{$conn_id}  or die "YAHC: unknown connection id $conn_id\n";
    my $watchers = $self->{watchers}{$conn_id} or die "YAHC: no watchers for connection id $conn_id\n";

    delete $watchers->{lifetime_timer}; # implicit stop
    my $timeout = $conn->{request}{lifetime_timeout};
    return unless $timeout;

    _register_in_timeline($conn, "setting lifetime timer to %.3fs", $timeout) if exists $conn->{debug_or_timeline};

    $self->{loop}->now_update;
    my $w = $watchers->{lifetime_timer} = $self->{loop}->timer_ns($timeout, 0, sub {
        _set_user_action_state($self, $conn_id, YAHC::Error::TIMEOUT() | YAHC::Error::LIFETIME_TIMEOUT() | YAHC::Error::TERMINAL_ERROR(),
            sprintf("lifetime_timeout of %.3fs expired", $timeout)) if $conn->{state} < YAHC::State::COMPLETED();
    });

    $w->priority(2); # set highest priority
    $w->start;
}

################################################################################
# HTTP functions
################################################################################

# copy-paste from Hijk
sub _build_http_message {
    my $conn = shift;
    my $request = $conn->{request};
    my $path_and_qs = ($request->{path} || "/") . (defined $request->{query_string} ? ("?" . $request->{query_string}) : "");
    my $has_host = 0;

    return join(
        $CRLF,
        ($request->{method} || "GET") . " $path_and_qs " . ($request->{protocol} || "HTTP/1.1"),
        defined($request->{body}) ? ("Content-Length: " . length($request->{body})) : (),
        defined($request->{head}) && @{ $request->{head} } ? (
            map {
                $has_host ||= lc($request->{head}[2*$_]) eq 'host';
                $request->{head}[2*$_] . ": " . $request->{head}[2*$_+1]
            } 0..$#{$request->{head}}/2
        ) : (),
        !$has_host ? ("Host: " . $conn->{selected_target}[0]) : (),
        "",
        defined($request->{body}) ? $request->{body} : ""
    );
}

sub _parse_http_headers {
    my $conn = shift;
    my $proto       = substr($_[0], 0, 8);
    my $status_code = substr($_[0], 9, 3);
    substr($_[0], 0, index($_[0], $CRLF) + 2, ''); # 2 = length($CRLF)

    my %headers;
    for (split /${CRLF}/o, $_[0]) {
        my ($key, $value) = split(/: /, $_, 2);
        $headers{lc $key} = $value;
    }

    $conn->{response} = {
        proto  => $proto,
        status => $status_code,
        head   => \%headers,
    };

    if ($conn->{debug_or_timeline}) {
        my $headers_str = join(' ', map { "$_='$headers{$_}'" } keys %headers);
        _register_in_timeline($conn, "headers parsed: $status_code $proto headers=$headers_str");
    }

    return \%headers;
}

################################################################################
# Helpers
################################################################################

sub _delete_watchers_but_lifetime_timer {
    my ($self, $conn_id) = @_;

    my $watchers = $self->{watchers}{$conn_id};
    if (defined $watchers && (my $w = $watchers->{lifetime_timer})) {
        return $self->{watchers}{$conn_id} = { lifetime_timer => $w };
    }

    return $self->{watchers}{$conn_id} = {};
}

sub _wrap_host {
    my ($value) = @_;
    my $ref = ref($value);

    return sub { $value } if $ref eq '';
    return $value         if $ref eq 'CODE';

    my $idx = 0;
    return sub { $value->[$idx++ % @$value]; }
        if $ref eq 'ARRAY' && @$value > 0;

    die "YAHC: unsupported host format\n";
}

sub _wrap_backoff {
    my ($value) = @_;
    my $ref = ref($value);

    return sub { $value } if $ref eq '';
    return $value         if $ref eq 'CODE';

    die "YAHC: unsupported backoff format\n";
}

sub _wrap_socket_cache {
    my ($value) = @_;
    my $ref = ref($value);

    return $value if $ref eq 'CODE';
    return sub {
        my ($operation, $conn, $sock) = @_;
        if ($operation == YAHC::SocketCache::GET()) {
            my $socket_cache_id = yahc_conn_socket_cache_id($conn) or return;
            return delete $value->{$socket_cache_id};
        }

        if ($operation == YAHC::SocketCache::STORE()) {
            my $socket_cache_id = yahc_conn_socket_cache_id($conn) or return;
            close(delete $value->{$socket_cache_id}) if exists $value->{$socket_cache_id};
            $value->{$socket_cache_id} = $sock;
            return;
        }
    } if $ref eq 'HASH';

    die "YAHC: unsupported socket_cache format\n";
}

sub _call_state_callback {
    my ($self, $conn, $cb_name) = @_;
    my $cb = $self->{callbacks}{$conn->{id}}{$cb_name};
    return unless $cb;

    _register_in_timeline($conn, "calling $cb_name callback") if exists $conn->{debug_or_timeline};

    eval {
        $cb->($conn);
        1;
    } or do {
        my $error = $@ || 'zombie error';
        yahc_conn_register_error($conn, YAHC::Error::CALLBACK_ERROR(), "exception in state callback (ignore error): $error");
    };

    $self->{loop}->now_update;
}

sub _get_safe_wrapper {
    my ($self, $conn, $sub) = @_;
    return sub { eval {
        $sub->(@_);
        1;
    } or do {
        my $error = $@ || 'zombie error';
        _set_user_action_state($self, $conn->{id}, YAHC::Error::INTERNAL_ERROR() | YAHC::Error::TERMINAL_ERROR(),
            "exception in internal callback: $error");
    }};
}

sub _register_in_timeline {
    my ($conn, $format, @arguments) = @_;
    my $event = sprintf("$format", @arguments);
    _log_message("YAHC connection '%s': %s", $conn->{id}, $event) if exists $conn->{debug};
    push @{ $conn->{timeline} ||= [] }, [ $event, $conn->{state}, Time::HiRes::time ] if exists $conn->{keep_timeline};
}

sub yahc_conn_register_error {
    my ($conn, $error, $format, @arguments) = @_;
    my $strerror = sprintf("$format", @arguments);
    _register_in_timeline($conn, "strerror='$strerror' error=$error") if exists $conn->{debug_or_timeline};
    push @{ $conn->{errors} ||= [] }, [ $error, $strerror, [ @{ $conn->{selected_target} } ], Time::HiRes::time, $conn->{attempt} ];
}

sub _strstate {
    my $state = shift;
    return 'STATE_INIT'         if $state eq YAHC::State::INITIALIZED();
    return 'STATE_RESOLVE_DNS'  if $state eq YAHC::State::RESOLVE_DNS();
    return 'STATE_CONNECTING'   if $state eq YAHC::State::CONNECTING();
    return 'STATE_CONNECTED'    if $state eq YAHC::State::CONNECTED();
    return 'STATE_WRITING'      if $state eq YAHC::State::WRITING();
    return 'STATE_READING'      if $state eq YAHC::State::READING();
    return 'STATE_SSL_HANDSHAKE'if $state eq YAHC::State::SSL_HANDSHAKE();
    return 'STATE_USER_ACTION'  if $state eq YAHC::State::USER_ACTION();
    return 'STATE_COMPLETED'    if $state eq YAHC::State::COMPLETED();
    return "<unknown state $state>";
}

sub _log_message {
    my $format = shift;
    my $now = Time::HiRes::time;
    my ($sec, $ms) = split(/[.]/, $now);
    printf STDERR "[%s.%-5d] [$$] $format\n", POSIX::strftime('%F %T', localtime($now)), $ms || 0, @_;
}

sub _format_ssl_error { return sprintf("'%s' errno=%d ssl_error='%s' ssl_errno=%d", "$!", 0+$!, "$IO::Socket::SSL::SSL_ERROR", 0+$IO::Socket::SSL::SSL_ERROR); }

1;

__END__

=encoding utf8

=head1 NAME

YAHC - Yet another HTTP client

=head1 SYNOPSIS

    use YAHC qw/yahc_reinit_conn/;

    my @hosts = ('www.booking.com', 'www.google.com:80');
    my ($yahc, $yahc_storage) = YAHC->new({ host => \@hosts });

    $yahc->request({ path => '/', host => 'www.reddit.com' });
    $yahc->request({ path => '/', host => sub { 'www.reddit.com' } });
    $yahc->request({ path => '/', host => \@hosts });
    $yahc->request({ path => '/', callback => sub { ... } });
    $yahc->request({ path => '/' });
    $yahc->request({
        path => '/',
        callback => sub {
            yahc_reinit_conn($_[0], { host => 'www.newtarget.com' })
                if $_[0]->{response}{status} == 301;
        }
    });

    $yahc->run;

=head1 DESCRIPTION

YAHC is fast & minimal low-level asynchronous HTTP client intended to be used
where you control both the client and the server. Is especially suits cases
where set of requests need to be executed against group of machines.

It is B<NOT> a general HTTP user agent, it doesn't support redirects,
proxies and any number of other advanced HTTP features like (in
roughly descending order of feature completeness) L<LWP::UserAgent>,
L<WWW::Curl>, L<HTTP::Tiny>, L<HTTP::Lite> or L<Furl>. This library is
basically one step above manually talking HTTP over sockets.

YAHC supports SSL and socket reuse (latter is in experimental mode).

=head1 STATE MACHINE

Each YAHC connection goes through following list of states in its lifetime:

                  +-----------------+
              +<<-|   INITALIZED    <-<<+
              v   +-----------------+   ^
              v           |             ^
              v   +-------v---------+   ^
              +<<-+   RESOLVE DNS   +->>+
              v   +-----------------+   ^
              v           |             ^
              v   +-------v---------+   ^
              +<<-+    CONNECTING   +->>+
              v   +-----------------+   ^
              v           |             ^
     Path in  v   +-------v---------+   ^  Retry
     case of  +<<-+    CONNECTED    +->>+  logic
     failure  v   +-----------------+   ^  path
              v           |             ^
              v   +-------v---------+   ^
              +<<-+     WRITING     +->>+
              v   +-----------------+   ^
              v           |             ^
              v   +-------v---------+   ^
              +<<-+     READING     +->>+
              v   +-----------------+   ^
              v           |             ^
              v   +-------v---------+   ^
              +>>->   USER ACTION   +->>+
                  +-----------------+
                          |
                  +-------v---------+
                  |    COMPLETED    |
                  +-----------------+


There are three paths of workflow:

=over 4

=item 1) Normal execution (central line).

In normal situation a connection after being initialized goes through state:

- RESOLVE DNS (not implemented)

- CONNECTING - wait finishing of handshake

- CONNECTED

- WRITING - sending request body

- READING - awaiting and reading response

- USER ACTION - see below

- COMPLETED - all done, this is terminal state

SSL connection has extra state SSL_HANDSHAKE after CONNECTED state. State
'RESOLVE DNS' is not implemented yet.

=item 2) Retry path (right line).

In case of IO error during normal execution YAHC retries connection
C<retries> times. In practice this means that connection goes back to
INITIALIZED state.

=item 3) Failure path (left line).

If all retry attempts did not succeeded a connection goes to state 'USER
ACTION' (see below).

=back

=head2 State 'USER ACTION'

'USER ACTION' state is called right before connection if going to enter
'COMPLETED' state (with either failed or successful results) and is meant
to give a chance to user to interrupt the workflow.

'USER ACTION' state is entered in these circumstances:

=over 4

=item * HTTP response received. Note that non-200 responses are NOT treated as error. 

=item * unsupported HTTP response is received (such as response without Content-Length header)

=item * retries limit reached

=item * lifetime timeout has expired

=item * provided callback has thrown exception

=item * internal error has occured

=back

When a connection enters this state C<callback> CodeRef is called:

    $yahc->request({
        ...
        callback => sub {
            my (
                $conn,          # connection 'object'
                $error,         # one of YAHC::Error::* constants
                $strerror       # string representation of error
            ) = @_;

            # Note that fields in $conn->{response} are not reliable
            # if $error != YAHC::Error::NO_ERROR()

            # HTTP response is stored in $conn->{response}.
            # It can be also accessed via yahc_conn_response().
            my $response = $conn->{response};
            my $status = $response->{status};
            my $body = $response->{body};
        }
    });

If there was no IO error C<yahc_conn_response> return C<HashRef> representing
response. It contains the following key-value pairs.

    proto         => :Str
    status        => :StatusCode
    body          => :Str
    head          => :HashRef

In case of a error or non-200 HTTP response C<yahc_retry_conn> or
C<yahc_reinit_conn> may be called to give the request more chances to complete
successfully (for example by following redirects or providing new target
hosts). Also, note that in case of a error data returned by
C<yahc_conn_response> cannot be trusted. For example, if an IO error happened
during receiving HTTP body headers would state 200 response code.

YAHC lowercases headers names returned in C<head>. This is done to comply with
RFC which identify HTTP headers as case-insensitive.

In some cases connection cannot be retried anymore and callback is
called for information purposes only. This case can be distinguished by
C<$error> having YAHC::Error::TERMINAL_ERROR() bit set. One can use
C<yahc_terminal_error> helper to detect such case.

Note that C<callback> should NOT throw exception. If so the connection will be
immediately closed.

=head1 METHODS

=head2 new

This method creates YAHC object and accompanying storage object:

    my ($yahc, $yahc_storage) = YAHC->new();

This is a radical way of solving all possible memleak because of cyclic
references in callbacks. Since all references of callbacks are kept in
$yahc_storage object it's fine to use YAHC object inside request callback:

    my $yahc->request({
        callback => sub {
            $yahc->stop; # this is fine!!!
        },
    });

However, user has to guarantee that both $yahc and $yahc_storage objects are
kept in the same scope. So, they will be destroyed at the same time.

C<new> can be passed with all parameters supported by C<request>. They
will be inherited by all requests.

Additionally, C<new> supports three parameters: C<socket_cache>,
C<account_for_signals>, and C<loop>.

=head3 socket_cache

C<socket_cache> option controls socket reuse logic. By default socket cache is
disabled. If user wants YAHC reuse sockets he should set C<socket_cache> to a
HashRef.

    my ($yahc, $yahc_storage) = YAHC->new({ socket_cache => {} });

In this case YAHC maintains unused sockets keyed on C<join($;, $$, $host,
$port, $scheme)>. We use C<$;> so we can use the C<< $socket_cache->{$$, $host, $port,
$scheme} >> idiom to access the cache.

It's up to user to control the cache. It's also up to user to set necessary
request headers for keep-alive. YAHC does not cache socket in cases of an error,
HTTP/1.0 and when server explicitly instructs to close connection (i.e. header
'Connection' = 'close').

=head3 loop

By default, each YAHC object will use its own EV eventloop.  This is normally
preferred since it allows for more accurate timing metrics.

However, if the process is already using an eventloop, having an inner
loop means the outer one stays waiting until the inner one is done.

To get around this, one can specify the eventloop that YAHC will use:

    my ($yahc, $storage) = YAHC->new({
        loop => EV::default_loop(), # use the default EV eventloop
    });

Using the above, YAHC will be sharing the same eventloop as everyone
else, so some operations are now riskier and should be avoided;
For example, in most scenarios C<account_for_signals> should not be
used alongside C<loop>, as only whatever is entering the eventloop should set
the signal handlers.

=head3 account_for_signals

Another parameter C<account_for_signals> requires special attention! Here is
why:

=over 4

excerpt from EV documentation L<http://search.cpan.org/~mlehmann/EV-4.22/EV.pm#PERL_SIGNALS>

While Perl signal handling (%SIG) is not affected by EV, the behaviour with EV
is as the same as any other C library: Perl-signals will only be handled when
Perl runs, which means your signal handler might be invoked only the next time
an event callback is invoked.

=back

In practise this means that none of set %SIG handlers will be called until EV
calls one of perl callbacks. Which, in some cases, may take a long time. By
setting C<account_for_signals> YAHC adds C<EV::check> watcher with empty
callback effectively making EV calling the callback on every iteration. The
trickery comes at some performance cost. This is what EV documentation says
about it:

=over 4

... you can also force a watcher to be called on every event loop iteration by
installing a EV::check watcher. This ensures that perl gets into control for a
short time to handle any pending signals, and also ensures (slightly) slower
overall operation.

=back

So, if your code or the codes surrounding your code use %SIG handlers it's
wise to set C<account_for_signals>.

=head2 request

    protocol               => "HTTP/1.1", # (or "HTTP/1.0")
    scheme                 => "http" or "https"
    host                   => see below,
    port                   => ...,
    method                 => "GET",
    path                   => "/",
    query_string           => "",
    head                   => [],
    body                   => "",

    # timeouts
    connect_timeout        => undef,
    request_timeout        => undef,
    drain_timeout          => undef,
    lifetime_timeout       => undef,

    # burst control
    backoff_delay          => undef,

    # callbacks
    init_callback          => undef,
    connecting_callback    => undef,
    connected_callback     => undef,
    writing_callback       => undef,
    reading_callback       => undef,
    callback               => undef,

    # SSL options
    ssl_options            => {},

Notice how YAHC does not take a full URI string as input, you have to
specify the individual parts of the URL. Users who need to parse an
existing URI string to produce a request should use the L<URI> module
to do so.

For example, to send a request to C<http://example.com/flower?color=red>, pass
the following parameters:

    $yach->request({
        host         => "example.com",
        port         => "80",
        path         => "/flower",
        query_string => "color=red"
    });

=head3 request building

YAHC doesn't escape any values for you, it just passes them through
as-is. You can easily produce invalid requests if e.g. any of these
strings contain a newline, or aren't otherwise properly escaped.

Notice that you do not need to put the leading C<"?"> character in the
C<query_string>. You do, however, need to properly C<uri_escape> the content of
C<query_string>.

The value of C<head> is an C<ArrayRef> of key-value pairs instead of a
C<HashRef>, this way you can decide in which order the headers are
sent, and you can send the same header name multiple times. For
example:

    head => [
        "Content-Type" => "application/json",
        "X-Requested-With" => "YAHC",
    ]

Will produce these request headers:

    Content-Type: application/json
    X-Requested-With: YAHC

=head3 host

C<host> parameter can accept one of following values:

=over 4

    1) string - represents target host. String may have following formats:
    hostname:port, ip:port.

    2) ArrayRef of strings - YAHC will cycle through items selecting new host
    for each attempt.

    3) CodeRef. The subroutine is invoked for each attempt and should at least
    return a string (hostname or IP address). It can also return array
    containing: ($host, $ip, $port, $scheme). This option effectively give a
    user control over host selection for retries. The CodeRef is passed with
    connection "object" which can be fed to yahc_conn_* family of functions.

=back

=head3 timeouts

The value of C<connect_timeout>, C<request_timeout> and C<drain_timeout> is in
floating point seconds, and is used as the time limit for connecting to the
host (reaching CONNECTED state), full request time (reaching COMPLETED state)
and sending request to remote site (reaching READING state) respectively.

C<lifetime_timeout> has special purpose. Its task is to provide upper bound
timeout for a request lifetime. In other words, if a request comes with
multiple retries C<connect_timeout>, C<request_timeout> and C<drain_timeout>
are per attempt. C<lifetime_timeout> covers all attempts. If by the time
C<lifetime_timeout> expires a connection is not in COMPLETED state a error is
generated. Note that after this error the connection cannot be retried anymore.
So, it's forced to go to COMPLETED state.

The default value for all is C<undef>, meaning no timeout limit.

=head3 backoff_delay

C<backoff_delay> can be used to introduce delay between retries. This is a
great way to avoid load spikes on server side. Following example creates new
request which would be retried twice doing three attempts in total. Second and
third attempts will be delay by one second each.

    $yach->request({
        host          => "example.com",
        retries       => 2,
        backoff_delay => 1,
    });

C<backoff_delay> can be set in two ways:

=over 4

    1) floating point seconds - define constant delay between retires.

    2) CodeRef. The subroutine is invoked on each retry and should return
    floating point seconds. This option is useful for having exponentially
    growing delay or, for instance, jitted delays.

=back

The default value is C<undef>, meaning no delay.

=head3 callbacks

The value of C<init_callback>, C<connecting_callback>, C<connected_callback>,
C<writing_callback>, C<reading_callback> is a reference to a subroutine which is
called upon reaching corresponding state. Any exception thrown in the
subroutine will be ignored.

The value of C<callback> defines main request callback which is called when a
connection enters 'USER ACTION' state (see 'USER ACTION' state above).

Also see L<LIMITATIONS>

=head3 ssl_options

Performing HTTPS requires the value of C<ssl_options> extended by two parameters
set to current hostname:

        SSL_verifycn_name => $hostname,
        IO::Socket::SSL->can_client_sni ? ( SSL_hostname => $hostname ) : (),

Apart of this changes, the value is directly passed to
C<IO::Socket::SSL::start_SSL()>. For more details refer to IO::Socket::SSL
documentation L<https://metacpan.org/pod/IO::Socket::SSL>.

=head2 drop

Given connection HashRef or conn_id move connection to COMPLETED state (avoiding
'USER ACTION' state) and drop it from internal pool. The function takes two
parameters: first is either a connection id or connection HashRef. Second one
is a boolean flag indicating whether connection's socket should closed or it
might be reused.

=head2 run

Start YAHC's loop. The loop stops when all connection complete.

Note that C<run> can accept two extra parameters: until_state and
list of connections. These two parameters tell YAHC to break the loop once
specified connections reach desired state.

For example:

    $yahc->run(YAHC::State::READING(), $conn_id);

Will loop until connection '$conn_id' move to state READING meaning that the
data has been sent to remote side. In order to gather response one should later
call:

    $yahc->run(YAHC::State::COMPLETED(), $conn_id);

or simply:

    $yahc->run();

Leaving list of connection empty makes YAHC waiting for all connection reaching
needed until_state.

Note that waiting one particular connection to finish doesn't mean that others
are not executed. Instead, all active connections are looped at the same
time, but YAHC breaks the loop once waited connection reaches needed state.

=head2 run_once

Same as run but with EV::RUN_ONCE set. For more details check L<https://metacpan.org/pod/EV>

=head2 run_tick

Same as run but with EV::RUN_NOWAIT set. For more details check L<https://metacpan.org/pod/EV>

=head2 is_running

Return true if YAHC is running, false otherwise.

=head2 loop

Return underlying EV loop object.

=head2 break

Break running EV loop if any.

=head1 EXPORTED FUNCTIONS

=head2 yahc_reinit_conn

C<yahc_reinit_conn> reinitialize given connection. The attempt counter is reset
to 0. The function accepts HashRef as second argument. By passing it one can
change host, port, scheme, body, head and others parameters. The format and
meaning of these parameters is same as in C<request> method.

One of use cases of C<yahc_reinit_conn>, for example, is to handle redirects:

    use YAHC qw/yahc_reinit_conn/;

    my ($yahc, $yahc_storage) = YAHC->new();
    $yahc->request({
        host => 'domain_which_returns_301.com',
        callback => sub {
            ...
            my $conn = $_[0];
            yahc_reinit_conn($conn, { host => 'www.newtarget.com' })
                if $_[0]->{response}{status} == 301;
            ...
        }
    });

    $yahc->run;

C<yahc_reinit_conn> is meant to be called inside C<callback> i.e. when
connection is in 'USER ACTION' state.

=head2 yahc_retry_conn

Retries given connection. C<yahc_retry_conn> should be called only if
C<yahc_conn_attempts_left> returns positive value. Otherwise, it exits
silently. The function accepts HashRef as second argument. By passing it one
can change C<backoff_delay> parameter. See docs for C<request> for more details
about C<backoff_delay>.

Intended usage is to retry transient failures or to try different host:

    use YAHC qw/
        yahc_retry_conn
        yahc_conn_attempts_left
    /;

    my ($yahc, $yahc_storage) = YAHC->new();
    $yahc->request({
        retries => 2,
        host => [ 'host1', 'host2' ],
        callback => sub {
            ...
            my $conn = $_[0];
            if ($_[0]->{response}{status} == 503 && yahc_conn_attempts_left($conn)) {
                yahc_retry_conn($conn);
                return;
            }
            ...
        }
    });

    $yahc->run;

C<yahc_retry_conn> is meant to be called inside C<callback> similarly
to C<yahc_reinit_conn>.

=head2 yahc_conn_id

Return id of given connection.

=head2 yahc_conn_state

Return state of given connection.

=head2 yahc_conn_target

Return selected host and port for current attempt for given connection.
Format "host:port". Default port values are omitted.

=head2 yahc_conn_url

Same as C<yahc_conn_target> but return full URL

=head2 yahc_conn_user_data

Let user assosiate arbitrary data with a connection. Be aware of not creating
cyclic reference!

=head2 yahc_conn_errors

Return errors appeared in given connection. Note that the function returns all
errors, not only ones happened during current attempt. Returned value is
ArrayRef of ArrayRefs. Later one represents a error and contains following
items:

=over 4

    error number (see YAHC::Error constants)
    error string
    ArrayRef of host, ip, port, scheme
    time when the error happened
    attempt when the error happened

=back

=head2 yahc_conn_register_error

C<yahc_conn_register_error> adds new record in connection's error list. This
functions is used internally for keeping track of all low-level errors during
connection's lifetime. It can be also used by users for high-level errors such
as 50x responses. The function takes C<$conn>, C<$error> which is one of
C<YAHC::Error> constants and error description. Error description can be passed
in sprintf manner. For example:

    $yahc->request({
        ...
        callback => sub {
            ...
            my $conn = $_[0];
            my $status = $conn->{response}{status} || 0;
            if ($status == 503 || $status == 504) {
                yahc_conn_register_error(
                    $conn,
                    YAHC::Error::RESPONSE_ERROR(),
                    "server returned %d",
                    $status
                );

                yahc_retry_conn($conn);
                return;
            }
            ...
        }
    });

=head2 yahc_conn_last_error

Return last error appeared in connection. See C<yahc_conn_errors>.

=head2 yahc_terminal_error

Given a error return 1 if the error has YAHC::Error::TERMINAL_ERROR() bit set.
Otherwise return 0.

=head2 yahc_conn_timeline

Return timeline of given connection. See more about timeline in description of
C<new> method.

=head2 yahc_conn_request

Return request of given connection. See C<request>.

=head2 yahc_conn_response

Return response of given connection. See C<request>.

=head2 yahc_conn_attempt

Return current attempt starting from 1. The function can also return 0 if no
attempts were made yet.

=head2 yahc_conn_attempts_left

Return number of attempts left.

=head2 yahc_conn_socket_cache_id

Return socket_cache id for given connection. Should be used to generate key for
C<socket_cache>. If connection is not initialized yet C<undef> is returned.

=head1 ERRORS

YAHC provides set of constants for errors. Each constant returns bitmask which
can be used to detect presence of a particular error, for example, in
C<callback>. There is one exception: YAHC::Error::NO_ERROR() return 0
indicating no error during request execution.

Error handling code can look like following:

    $yahc->request({
        ...
        callback => sub {
            my (
                $conn,          # connection 'object'
                $error,         # one of YAHC::Error::* constants
                $strerror       # string representation of error
            ) = @_;

            if ($error & YAHC::Error::TIMEOUT()) {
                # A timeout has happend. Use one of YAHC::Error::*_TIMEOUT()
                # constants for more clarification
            } elsif ($error & YAHC::Error::SSL_ERROR()) {
                # We had some issues with SSL. $error might have
                # YAHC::Error::READ_ERROR() or YAHC::Error::WRITE_ERROR()
                # indicating whether is was read or write error.
            } elsif (...) { # etc
            }
        }
    });

The list of error constants. The names are self-explanatory in many cases:

=over 4

=item C<YAHC::Error::NO_ERROR()>

Return value 0 (not a bitmask)> meaning no error

=item C<YAHC::Error::REQUEST_TIMEOUT()>

=item C<YAHC::Error::CONNECT_TIMEOUT()>

=item C<YAHC::Error::DRAIN_TIMEOUT()>

=item C<YAHC::Error::LIFETIME_TIMEOUT()>

=item C<YAHC::Error::TIMEOUT()>

=item C<YAHC::Error::RETRY_LIMIT()>

The connection has exhausted all available retries. This error is usually
returned to C<callback>. Check connection's errors via C<yahc_conn_errors> to
inspect the reasons of failures for each individual attempt.

=item C<YAHC::Error::CONNECT_ERROR()>

=item C<YAHC::Error::READ_ERROR()>

=item C<YAHC::Error::WRITE_ERROR()>

=item C<YAHC::Error::SSL_ERROR()>

=item C<YAHC::Error::REQUEST_ERROR()>

not used

=item C<YAHC::Error::RESPONSE_ERROR()>

Server returned unparsable response

=item C<YAHC::Error::CALLBACK_ERROR()>

Usually represents exception in one of the callbacks

=item C<YAHC::Error::TERMINAL_ERROR()>

This bit is set when connection cannot be retried anymore and is forced to
complete

=item C<YAHC::Error::INTERNAL_ERROR()>

=back

=head1 REPOSITORY

L<https://github.com/ikruglov/YAHC>

=head1 NOTES

=head2 UTF8 flag

Note that YAHC has astonishing reduction in performance if any parameters
participating in building HTTP message has UTF8 flag set. Those fields are
C<protocol>, C<host>, C<port>, C<method>, C<path>, C<query_string>, C<head>,
C<body> and maybe others.

Just one example (check scripts/utf8_test.pl for code). Simple HTTP request
with 10MB of payload:

    elapsed without utf8 flag: 0.039s
    elapsed with utf8 flag: 0.540s

Because of this YAHC warns if detected UTF8-flagged payload. The user needs
to make sure that *all* data passed to YAHC is unflagged binary strings.

=head2 LIMITATIONS

=over 4

=item * State 'RESOLVE DNS' is not implemented yet.

=back

=head1 AUTHORS

Ivan Kruglov <ivan.kruglov@yahoo.com>

=head1 COPYRIGHT

Copyright (c) 2013-2017 Ivan Kruglov C<< <ivan.kruglov@yahoo.com> >>.

=head1 ACKNOWLEDGMENT

This module derived lots of ideas, code and docs from Hijk
L<https://github.com/gugod/Hijk>. This module was originally developed for
Booking.com.

=head1 LICENCE

The MIT License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
