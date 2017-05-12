# NAME

Test::Fake::HTTPD - a fake HTTP server

# SYNOPSIS

DSL-style

    use Test::Fake::HTTPD;

    my $httpd = run_http_server {
        my $req = shift;
        # ...

        # 1. HTTP::Response ok
        return $http_response;
        # 2. Plack::Response ok
        return $plack_response;
        # 3. PSGI response ok
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    printf "You can connect to your server at %s.\n", $httpd->host_port;
    # or
    printf "You can connect to your server at 127.0.0.1:%d.\n", $httpd->port;

    # access to fake HTTP server
    use LWP::UserAgent;
    my $res = LWP::UserAgent->new->get($httpd->endpoint); # "http://127.0.0.1:{port}"

    # Stop http server automatically at destruction time.

OO-style

    use Test::Fake::HTTPD;

    my $httpd = Test::Fake::HTTPD->new(
        timeout     => 5,
        daemon_args => { ... }, # HTTP::Daemon args
    );

    $httpd->run(sub {
        my $req = shift;
        # ...
        [ 200, [ 'Content-Type', 'text/plain' ], [ 'Hello World' ] ];
    });

    # Stop http server automatically at destruction time.

# DESCRIPTION

Test::Fake::HTTPD is a fake HTTP server module for testing.

# FUNCTIONS

- `run_http_server { ... }`

    Starts HTTP server and returns the guard instance.

        my $httpd = run_http_server {
            my $req = shift;
            # ...
            return $http_or_plack_or_psgi_res;
        };

        # can use $httpd guard object, same as OO-style
        LWP::UserAgent->new->get($httpd->endpoint);

- `run_https_server { ... }`

    Starts **HTTPS** server and returns the guard instance.

    If you use this method, you MUST install [HTTP::Daemon::SSL](https://metacpan.org/pod/HTTP::Daemon::SSL).

        extra_daemon_args
            SSL_key_file  => "certs/server-key.pem",
            SSL_cert_file => "certs/server-cert.pem";

        my $httpd = run_https_server {
            my $req = shift;
            # ...
            return $http_or_plack_or_psgi_res;
        };

        # can use $httpd guard object, same as OO-style
        my $ua = LWP::UserAgent->new(
            ssl_opts => {
                SSL_verify_mode => 0,
                verify_hostname => 0,
            },
        );
        $ua->get($httpd->endpoint);

# METHODS

- `new( %args )`

    Returns a new instance.

        my $httpd = Test::Fake::HTTPD->new(%args);

    `%args` are:

    - `timeout`

        timeout value (default: 5)

    - `listen`

        queue size for listen (default: 5)

    - `port`

        local bind port number (default: auto detection)

        my $httpd = Test::Fake::HTTPD->new(
            timeout => 10,
            listen  => 10,
            port    => 3333,
        );

- `run( sub { ... } )`

    Starts this HTTP server.

        $httpd->run(sub { ... });

- `scheme`

    Returns a scheme of running, "http" or "https".

        my $scheme = $httpd->scheme;

- `port`

    Returns a port number of running.

        my $port = $httpd->port;

- `host_port`

    Returns a URI host\_port of running. ("127.0.0.1:{port}")

        my $host_port = $httpd->host_port;

- `endpoint`

    Returns an endpoint URI of running. ("http://127.0.0.1:{port}" URI object)

        use LWP::UserAgent;

        my $res = LWP::UserAgent->new->get($httpd->endpoint);

        my $url = $httpd->endpoint;
        $url->path('/foo/bar');
        my $res = LWP::UserAgent->new->get($url);

# AUTHOR

NAKAGAWA Masaki <masaki@cpan.org>

# THANKS TO

xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Test::TCP](https://metacpan.org/pod/Test::TCP), [HTTP::Daemon](https://metacpan.org/pod/HTTP::Daemon), [HTTP::Daemon::SSL](https://metacpan.org/pod/HTTP::Daemon::SSL), [HTTP::Message::PSGI](https://metacpan.org/pod/HTTP::Message::PSGI)
