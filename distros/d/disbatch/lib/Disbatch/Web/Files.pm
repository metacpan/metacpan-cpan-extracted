package Disbatch::Web::Files;
$Disbatch::Web::Files::VERSION = '4.103';
use 5.12.0;
use warnings;

use Limper::SendFile;
use Limper;

get qr{^/} => sub {
    send_file request->{path};        # sends request->{uri} by default
};


1;

=encoding utf8

=head1 NAME

Disbatch::Web::Files - Disbatch::Web routes for files

=head1 VERSION

version 4.103

=head1 NOTE

These routes were formerly in L<Disbatch::Web>, but moved here. They are loaded automatically.

=head1 BROWSER ROUTES

=over 2

=item GET qr{^/}

Returns the contents of the request path.

=back

=head1 SEE ALSO

L<Disbatch::Web>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
