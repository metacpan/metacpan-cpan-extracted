package URI::udp;
use strict;
use warnings;

use parent qw(URI::_server);

=head1 NAME

URI::udp - udp connection string

=head1 SYNOPSIS

    $uri = URI->new('udp://host:1234');

    $sock = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port',
        Proto    => $uri->protocol,
    );

=head1 DESCRIPTION

URI extension for UDP protocol

=head1 EXTENDED METHODS

=head2 protocol()

return I<udp>

same as C<scheme> method

=cut

sub protocol {
    my ($self) = @_;

    return $self->scheme;
}

=head1 contributing

for dependency use L<cpanfile>...

for resolve dependency use L<Carton> (or carton - is more experimental) 

    carton install

for run test use C<minil test>

    carton exec minil test


if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

=head2 warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1
