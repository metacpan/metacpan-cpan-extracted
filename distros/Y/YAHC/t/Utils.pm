package t::Utils;

use POSIX;
use Test::More;
use HTTP::Tiny;
use Data::Dumper;
use JSON qw/encode_json/;
use Time::HiRes qw/time sleep/;
use Plack::Middleware::Chunked;

use constant {
    SSL_CRT => 't/cert/server.crt',
    SSL_KEY => 't/cert/server.key',
};

my $chars = 'qwertyuiop[]asdfghjkl;\'zxcvbnm,./QWERTYUIOP{}":LKJHGFDSAZXCVBNM<>?1234567890-=+_)(*&^%$#@!\\ ' . "\n\t\r";

sub _generate_sequence {
    my $len = shift;
    my $lc = length($chars);
    my $out = '';

    while ($len-- > 0) {
        $out .= substr($chars, rand($lc), 1);
    }

    return $out;
}

my %PIDS;
sub _pids {
    return \%PIDS;
}

sub _fork {
    my ($cb, $lifetime) = @_;
    $lifetime ||= 60;

    my $pid = fork;
    defined $pid or die "failed to fork: $!";

    if ($pid != 0) {
        # return in parent
        $PIDS{$pid} = 1;
        return $pid;
    }

    local $SIG{ALRM} = sub { POSIX::_exit(1) };
    alarm($lifetime); # 60 sec of timeout

    eval {
        $cb->();
        1;
    } or do {
        warn "$@\n";
        POSIX::_exit(1); # avoid running END block
    };

    POSIX::_exit(0); # avoid running END block
}

sub _generaete_random_port {
    return 10000 + int(rand(2000));
}

sub _start_plack_server_on_random_port {
    my $opts = shift;
    my $port = _generaete_random_port();

    # I pass 127.0.0.1 to all server instances to make sure that we use IPv4 stack.
    # I still want to use "localhost" to test DNS lookup for clients
    return _start_plack_server({ host => '127.0.0.1', port => $port, %{ $opts || {} } }), "localhost", $port;
}

sub _start_plack_server {
    my $args = shift;
    my $host = $args->{host};
    my $port = $args->{port};
    my $ssl  = $args->{ssl};
    my $chunked = $args->{chunked};
    my $keep_alive = $args->{keep_alive};
    my $server = $args->{server};

    my $pid = _fork(sub {
        note(sprintf("starting plack server %s", Dumper($args)));

        require Plack::Runner;
        my $runner = Plack::Runner->new(defined $server ? (server => $server) : ());

        my @opts = ("--host", $host, "--port", $port, "--no-default-middleware", "--max-requests", 1000000, "--workers", 1);
        push @opts, ("--enable-ssl", '--ssl-key-file', SSL_KEY, '--ssl-cert-file', SSL_CRT) if $ssl;
        push @opts, ("--keepalive-timeout", 300) if $keep_alive;
        $runner->parse_options(@opts);

        my @stats;
        my $app = sub {
            my $req = shift;
            my $path = $req->{PATH_INFO};
            if ($path eq '/') {
                return [200, [], []];
            } elsif ($path eq '/ping' ) {
                return [200, [], ['pong']];
            } elsif ($path eq '/reset') {
                @stats = ();
                return [200, [], []];
            } elsif ($path eq '/report') {
                return [200, [], [ encode_json(\@stats) ]];
            } elsif ($path eq '/record') {
                my $body = '';
                read($req->{'psgi.input'}, $body, $req->{CONTENT_LENGTH} || 0);

                push @stats, {
                    query_string => $req->{QUERY_STRING},
                    body_length  => length($body),
                    time         => time,
                };

                return [200, [ 'Content-Type' => $req->{CONTENT_TYPE} || '' ], [$body]];
            } else {
                die "invalid request $path\n";
            }
        };

        $app = Plack::Middleware::Chunked->wrap($app) if $chunked;
        $runner->run($app);
    }, 300);

    note("waiting for plack to be up");

    my $ht = _get_http_tiny();
    my $scheme = $ssl ? "https" : "http";
    foreach (1..50) {
        last if $ht->get("$scheme://$host:$port/ping")->{success};
        sleep(0.1);
    }

    $ht->get("$scheme://$host:$port/ping")->{success}
        or die "plack is not up";

    note("plack is up");
    return $pid;
}

sub _get_http_tiny {
    return HTTP::Tiny->new(SSL_options => {
        SSL_cert_file   => SSL_CRT,
        SSL_key_file    => SSL_KEY,
        SSL_verify_mode => 0, # SSL_VERIFY_NONE
    });
}

sub _get_toxyproxy_addr {
    return $ENV{TOXYPROXY} || "localhost:8474";
}

sub _check_toxyproxy_and_reset {
    my $ht = HTTP::Tiny->new();
    my $addr = _get_toxyproxy_addr();
    return $ht->get("http://$addr/version")->{success}
}

sub new_toxic {
    my ($name, $upstream, $toxic) = @_;

    my $port = 13000 + int(rand(2000));
    my $listen = "127.0.0.1:$port";
    note("creating new proxy '$name' listening on $listen on upstreaming to $upstream");

    my $ht = HTTP::Tiny->new();
    my $addr = _get_toxyproxy_addr();
    $ht->delete("http://$addr/proxies/$name");

    my $result = $ht->post("http://$addr/proxies", { content => encode_json({
        name     => $name,
        listen   => $listen,
        upstream => $upstream,
    })});

    $result->{success}
        or die "failed to create new proxy '$name' in toxyproxy: " . $result->{reason};

    my $upstream_toxic_name = "upstream_toxic_$name";
    $result = $ht->post("http://$addr/proxies/$name/toxics", { content => encode_json({
        name    => $upstream_toxic_name,
        stream  => "upstream",
        %{ $toxic },
    })});

    $result->{success} or die "failed to create new toxic '$upstream_toxic_name': " . $result->{reason};

    my $downstream_toxic_name = "downstream_toxic_$name";
    $result = $ht->post("http://$addr/proxies/$name/toxics", { content => encode_json({
        name    => $downstream_toxic_name,
        stream  => "downstream",
        %{ $toxic },
    })});

    $result->{success} or die "failed to create new toxic '$downstream_toxic_name': " . $result->{reason};

    return $listen;
}

1;
