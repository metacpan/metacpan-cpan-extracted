[![Build Status](https://travis-ci.org/dex4er/Thrall.svg?branch=master)](https://travis-ci.org/dex4er/Thrall)[![CPAN version](https://badge.fury.io/pl/Thrall.svg)](https://metacpan.org/release/Thrall)

# NAME

thrall - a simple PSGI/Plack HTTP server which uses threads

# SYNOPSIS

    $ thrall --workers=20 --max-reqs-per-child=100 app.psgi

    $ thrall --port=80 --ipv6=1 app.psgi

    $ thrall --port=443 --ssl=1 --ssl-key-file=file.key --ssl-cert-file=file.crt app.psgi

    $ thrall --socket=/tmp/thrall.sock app.psgi

# DESCRIPTION

Thrall is a standalone HTTP/1.1 server with keep-alive support. It uses
threads instead pre-forking, so it works correctly on Windows. It is pure-Perl
implementation which doesn't require any XS package.

Thrall was started as a fork of [Starlet](https://metacpan.org/pod/Starlet) server. It has almost the same code
as [Starlet](https://metacpan.org/pod/Starlet) and it was adapted to use threads instead fork().

# OPTIONS

In addition to the options supported by [plackup](https://metacpan.org/pod/plackup), thrall accepts
following options(s).

## --max-workers

Number of worker threads. (default: 10)

## --timeout

Seconds until timeout. (default: 300)

## --keepalive-timeout

Timeout for persistent connections. (default: 2)

## --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

## --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

## --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by `--max-reqs-per-chlid`.
(default: none)

## --spawn-interval

If set, worker processes will not be spawned more than once than every given
seconds.  Also, when SIGHUP is being received, no more than one worker
processes will be collected every given seconds. This feature is useful for
doing a "slow-restart". (default: none)

## --main-process-delay

The Thrall does not synchronize its processes and it requires a small delay
in main process so it doesn't consume all CPU. (default: 0.1)

## --ssl

Enables SSL support. The [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) module is required. (default: 0)

## --ssl-key-file

Specifies the path to SSL key file. (default: none)

## --ssl-cert-file

Specifies the path to SSL certificate file. (default: none)

## --ssl-ca-file

Specifies the path to SSL CA certificate file which will be a part of server's
certificate chain. (default: none)

## --ssl-client-ca-file

Specifies the path to SSL CA certificate file for client verification.
(default: none)

## --ssl-verify-mode

Specifies the verification mode for the client certificate.
See ["SSL\_verify\_mode" in IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL#SSL_verify_mode) for details. (default: 0)

## --ipv6

Enables IPv6 support. The [IO::Socket::IP](https://metacpan.org/pod/IO::Socket::IP) module is required. (default: 0)

## --socket

Enables UNIX socket support. The [IO::Socket::UNIX](https://metacpan.org/pod/IO::Socket::UNIX) module is required. The
socket file have to be not yet created. The first character `@` or `\0` in
the socket file name means that abstract socket address will be created.
(default: none)

## --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This options is usually used if main
process is started with root privileges beacause binding to the low-numbered
(<1024) port. (default: none)

## --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with comma or space
character. (default: none)

## --umask

Changes file mode creation mask. The ["umask" in perlfunc](https://metacpan.org/pod/perlfunc#umask) is an octal number
representing disabled permissions bits for newly created files. It is usually
`022` when group shouldn't have permission to write or `002` when group
should have permission to write. (default: none)

## --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

## --pid

Specify the pid file path. Use it with `-D|--daemonize` option.
(default: none)

## --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using `--daemonize`.
(default: none)

## -q, --quiet

Suppress the message about starting a server.

# SEE ALSO

[Starlight](https://metacpan.org/pod/Starlight),
[Starlet](https://metacpan.org/pod/Starlet),
[Starman](https://metacpan.org/pod/Starman)

# LIMITATIONS

See ["BUGS AND LIMITATIONS" in threads](https://metacpan.org/pod/threads#BUGS-AND-LIMITATIONS) and ["Thread-Safety of
System Libraries" in perlthrtut](https://metacpan.org/pod/perlthrtut#Thread-Safety-of-System-Libraries) to read about limitations for PSGI applications started
with Thrall and check if you encountered a known problem.

Especially, PSGI applications should avoid: changing current working
directory, catching signals, starting new processes. Environment variables
might (Linux, Unix) or might not (Windows) be shared between threads.

Thrall is very slow on first request for each thread. It is because spawning
new thread is slow in Perl itself. Thrall is very fast on another requests and
generally is faster than any implementation which uses fork.

# BUGS

There is a problem with Perl threads implementation which occurs on Windows.
Some requests can fail with message:

    failed to set socket to nonblocking mode:An operation was attempted on
    something that is not a socket.

or

    Bad file descriptor at (eval 24) line 4.

Cygwin version seems to be correct.

This problem was introduced in Perl 5.16 and fixed in Perl 5.19.5.

See [https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003](https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003) and
[https://github.com/dex4er/Thrall/issues/5](https://github.com/dex4er/Thrall/issues/5) for more information about this
issue.

## Reporting

If you find the bug or want to implement new features, please report it at
[https://github.com/dex4er/Starlight/issues](https://github.com/dex4er/Starlight/issues)

The code repository is available at
[http://github.com/dex4er/Starlight](http://github.com/dex4er/Starlight)

# AUTHORS

Piotr Roszatycki <dexter@cpan.org>

Based on Starlet by:

Kazuho Oku

miyagawa

kazeburo

Some code based on Plack:

Tatsuhiko Miyagawa

Some code based on Net::Server::Daemonize:

Jeremy Howard &lt;j+daemonize@howard.fm>

Paul Seamons <paul@seamons.com>

# LICENSE

Copyright (c) 2013-2017 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
