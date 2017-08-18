package URI::tcp;
use strict;
use warnings;

our $VERSION = '2.0.0';

use parent qw(URI::_server);

=head1 NAME

URI::tcp - tcp connection string

=head1 SYNOPSIS

    $uri = URI->new('tcp://host:1234');

    $sock = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port',
        Proto    => $uri->protocol,
    );

=head1 DESCRIPTION

URI extension for TCP protocol

=head1 EXTENDED METHODS

=head2 protocol()

return I<tcp>

same as C<scheme> method

=cut

sub protocol {
    my ($self) = @_;

    return $self->scheme;
}

=head1 history

Module C<URI::tcp> was indexed by L<SOAP::Lite>, but isn't possible to use it. This L<pull request|https://github.com/redhotpenguin/soaplite/pull/31> change it.

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

1;
