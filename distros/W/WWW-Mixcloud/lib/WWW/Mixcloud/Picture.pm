# ABSTRACT: Represents a picture in the Mixcloud API
package WWW::Mixcloud::Picture;

use Moose;
use namespace::autoclean;

use Carp qw/ croak /;

our $VERSION = '0.01'; # VERSION


has size => (
    is       => 'ro',
    required => 1,
);


has url => (
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;


sub new_list_from_data {
    my $class = shift;
    my $data  = shift || croak 'Data reference required for construction';

    my @pictures;

    while ( my ( $size, $url ) = each %{$data} ) {
        push @pictures, $class->new({
            size => $size,
            url  => $url,
        });
    }

    return \@pictures;
}

1;

__END__
=pod

=head1 NAME

WWW::Mixcloud::Picture - Represents a picture in the Mixcloud API

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 size

=head2 url

=head1 METHODS

=head2 new_list_from_data

    my @pictures = WWW::Mixcloud::Pictures->new_list_from_data( $data )

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

