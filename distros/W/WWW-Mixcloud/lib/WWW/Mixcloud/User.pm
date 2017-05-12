# ABSTRACT: Represents a user in the Mixcloud API
package WWW::Mixcloud::User;

use Moose;
use namespace::autoclean;

use Carp qw/ croak /;

our $VERSION = '0.01'; # VERSION

use WWW::Mixcloud::Picture;


has url => (
    is       => 'ro',
    required => 1,
);


has username => (
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


has pictures => (
    isa      => 'ArrayRef[WWW::Mixcloud::Picture]',
    is       => 'ro',
    required => 1,
    default  => sub { [] },
);

__PACKAGE__->meta->make_immutable;


sub new_from_data {
    my $class = shift;
    my $data  = shift || croak 'Data reference required for construction';

    my $pictures = WWW::Mixcloud::Picture->new_list_from_data( $data->{pictures} );

    return $class->new({
        url      => $data->{url},
        username => $data->{username},
        name     => $data->{name},
        key      => $data->{key},
        pictures => $pictures,
    });

}

1;

__END__
=pod

=head1 NAME

WWW::Mixcloud::User - Represents a user in the Mixcloud API

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 url

=head2 username

=head2 name

=head2 key

=head2 pictures

ArrayRef of L<WWW::Mixcloud::Picture> objects.

=head1 METHODS

=head2 new_from_data

    my $user = WWW::Mixcloud::User->new_from_data( $data )

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

