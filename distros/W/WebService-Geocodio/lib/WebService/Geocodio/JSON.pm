use strict;
use warnings;

package WebService::Geocodio::JSON;
$WebService::Geocodio::JSON::VERSION = '0.05';
# ABSTRACT: A JSON de/serializer class

use Moo::Role;
use strictures 2;
use JSON;
use Carp qw(confess);


has 'json' => (
    is => 'ro',
    lazy => 1,
    default => sub { JSON->new() },
);


sub encode {
    my ($self, $aref) = @_;

    return $self->json->encode($aref);
}


sub decode {
    my ($self, $data) = @_;

    return $self->json->decode($data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Geocodio::JSON - A JSON de/serializer class

=head1 VERSION

version 0.05

=head1 ATTRIBUTES

=head2 json

A JSON serializer/deserializer instance. Default is L<JSON>.

=head1 METHODS

=head2 encode

Serialize a Perl data structure to a JSON string

=head2 decode

Deserialize a JSON string to a Perl data structure

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
