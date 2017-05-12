#!/usr/bin/perl

=head1 NAME

thrall - a simple PSGI/Plack HTTP server which uses threads

=cut

use 5.008_001;

use strict;
use warnings;

our $VERSION = '0.0305';

use Plack::Runner;

sub version {
    print "Thrall $VERSION\n";
}

my $runner = Plack::Runner->new(
    server     => 'Thrall',
    env        => 'deployment',
    loader     => 'Delayed',
    version_cb => \&version,
);

$runner->parse_options(@ARGV);

if ($runner->{help}) {
    require Pod::Usage;
    Pod::Usage::pod2usage(-verbose => 1, -input => \*DATA);
}

$runner->run;

__DATA__

=head1 SYNOPSIS

  $ thrall --workers=20 --max-reqs-per-child=100 app.psgi

  $ thrall --port=80 --ipv6=1 app.psgi

  $ thrall --port=443 --ssl=1 --ssl-key-file=file.key --ssl-cert-file=file.crt app.psgi

  $ thrall --socket=/tmp/thrall.sock app.psgi

=head1 DESCRIPTION

Thrall is a standalone HTTP/1.1 server with keep-alive support. It uses
threads instead pre-forking, so it works correctly on Windows. It is pure-Perl
implementation which doesn't require any XS package.

Thrall was started as a fork of L<Starlet> server. It has almost the same code
as L<Starlet> and it was adapted to use threads instead fork().

=for readme stop

=head1 OPTIONS

In addition to the options supported by L<plackup>, thrall accepts
following options(s).

=head2 --max-workers

Number of worker threads. (default: 10)

=head2 --timeout

Seconds until timeout. (default: 300)

=head2 --keepalive-timeout

Timeout for persistent connections. (default: 2)

=head2 --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

=head2 --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

=head2 --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by C<--max-reqs-per-chlid>.
(default: none)

=head2 --spawn-interval

If set, worker processes will not be spawned more than once than every given
seconds.  Also, when SIGHUP is being received, no more than one worker
processes will be collected every given seconds. This feature is useful for
doing a "slow-restart". (default: none)

=head2 --main-process-delay

The Thrall does not synchronize its processes and it requires a small delay
in main process so it doesn't consume all CPU. (default: 0.1)

=head2 --ssl

Enables SSL support. The L<IO::Socket::SSL> module is required. (default: 0)

=head2 --ssl-key-file

Specifies the path to SSL key file. (default: none)

=head2 --ssl-cert-file

Specifies the path to SSL certificate file. (default: none)

=head2 --ssl-ca-file

Specifies the path to SSL CA certificate file which will be a part of server's
certificate chain. (default: none)

=head2 --ssl-client-ca-file

Specifies the path to SSL CA certificate file for client verification.
(default: none)

=head2 --ssl-verify-mode

Specifies the verification mode for the client certificate.
See L<IO::Socket::SSL/SSL_verify_mode> for details. (default: 0)

=head2 --ipv6

Enables IPv6 support. The L<IO::Socket::IP> module is required. (default: 0)

=head2 --socket

Enables UNIX socket support. The L<IO::Socket::UNIX> module is required. The
socket file have to be not yet created. The first character C<@> or C<\0> in
the socket file name means that abstract socket address will be created.
(default: none)

=head2 --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This options is usually used if main
process is started with root privileges beacause binding to the low-numbered
(E<lt>1024) port. (default: none)

=head2 --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with comma or space
character. (default: none)

=head2 --umask

Changes file mode creation mask. The L<perlfunc/umask> is an octal number
representing disabled permissions bits for newly created files. It is usually
C<022> when group shouldn't have permission to write or C<002> when group
should have permission to write. (default: none)

=head2 --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

=head2 --pid

Specify the pid file path. Use it with C<-D|--daemonize> option.
(default: none)

=head2 --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using C<--daemonize>.
(default: none)

=head2 -q, --quiet

Suppress the message about starting a server.

=for readme continue

=head1 SEE ALSO

L<Starlight>,
L<Starlet>,
L<Starman>

=head1 LIMITATIONS

See L<threads/"BUGS AND LIMITATIONS"> and L<perlthrtut/"Thread-Safety of
System Libraries"> to read about limitations for PSGI applications started
with Thrall and check if you encountered a known problem.

Especially, PSGI applications should avoid: changing current working
directory, catching signals, starting new processes. Environment variables
might (Linux, Unix) or might not (Windows) be shared between threads.

Thrall is very slow on first request for each thread. It is because spawning
new thread is slow in Perl itself. Thrall is very fast on another requests and
generally is faster than any implementation which uses fork.

=head1 BUGS

There is a problem with Perl threads implementation which occurs on Windows.
Some requests can fail with message:

  failed to set socket to nonblocking mode:An operation was attempted on
  something that is not a socket.

or

  Bad file descriptor at (eval 24) line 4.

Cygwin version seems to be correct.

This problem was introduced in Perl 5.16 and fixed in Perl 5.19.5.

See L<https://rt.perl.org/rt3/Public/Bug/Display.html?id=119003> and
L<https://github.com/dex4er/Thrall/issues/5> for more information about this
issue.

=head2 Reporting

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/Starlight/issues>

The code repository is available at
L<http://github.com/dex4er/Starlight>

=head1 AUTHORS

Piotr Roszatycki <dexter@cpan.org>

Based on Starlet by:

Kazuho Oku

miyagawa

kazeburo

Some code based on Plack:

Tatsuhiko Miyagawa

Some code based on Net::Server::Daemonize:

Jeremy Howard <j+daemonize@howard.fm>

Paul Seamons <paul@seamons.com>

=head1 LICENSE

Copyright (c) 2013-2017 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
