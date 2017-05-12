# ABSTRACT: Represents a track in the Mixcloud API
package WWW::Mixcloud::Track;

use Moose;
use namespace::autoclean;

use Carp qw/ croak /;

our $VERSION = '0.01'; # VERSION

use WWW::Mixcloud::Artist;


has url => (
    is       => 'ro',
    required => 1,
);


has artist => (
    isa      => 'WWW::Mixcloud::Artist',
    is       => 'ro',
    required => 1,
);


has name => (
    is       => 'ro',
    required => 1,
);


has key => (
    is       => 'ro',
    required => 1,
);


has slug => (
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;


sub new_from_data {
    my $class = shift;
    my $data  = shift || croak 'Data reference required for construction';

    return $class->new({
        url    => $data->{url},
        artist => WWW::Mixcloud::Artist->new_from_data( $data->{artist} ),
        name   => $data->{name},
        key    => $data->{key},
        slug   => $data->{slug},
    });
}

1;

__END__
=pod

=head1 NAME

WWW::Mixcloud::Track - Represents a track in the Mixcloud API

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 url

=head2 artist

An L<WWW::Mixcloud::Artist> object.

=head2 name

=head2 key

=head2 slug

=head1 METHODS

=head2 new_from_data

my $track = WWW::Mixcloud::Track->new_from_data( $data )

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

