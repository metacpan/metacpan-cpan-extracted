package Thrall;

=head1 NAME

Thrall - a simple PSGI/Plack HTTP server which uses threads

=head1 SYNOPSIS

  $ plackup -s Thrall --port=80 [options] your-app.psgi

  $ plackup -s Thrall --port=443 --ssl=1 --ssl-key-file=file.key
                      --ssl-cert-file=file.crt [options] your-app.psgi

  $ plackup -s Thrall --port=80 --ipv6 [options] your-app.psgi

  $ plackup -s Thrall --socket=/tmp/thrall.sock [options] your-app.psgi

  $ starlight your-app.psgi

=head1 DESCRIPTION

Thrall is a standalone HTTP/1.1 server with keep-alive support. It uses
threads instead pre-forking, so it works correctly on Windows. It is pure-Perl
implementation which doesn't require any XS package.

See L<plackup> and L<thrall> (lower case) for available command line
options.

=for readme stop

=cut


use 5.008_001;

use strict;
use warnings;

our $VERSION = '0.0305';

1;


__END__

=head1 SEE ALSO

L<thrall>,
L<Starlight>,
L<Starlet>,
L<Starman>

=head1 AUTHORS

Piotr Roszatycki <dexter@cpan.org>

Based on Starlet by:

Kazuho Oku

miyagawa

kazeburo

Some code based on Plack:

Tatsuhiko Miyagawa

=head1 LICENSE

Copyright (c) 2013-2017 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
