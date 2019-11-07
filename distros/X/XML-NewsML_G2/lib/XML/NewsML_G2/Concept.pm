package XML::NewsML_G2::Concept;

use XML::NewsML_G2::Media_Topic;
use XML::NewsML_G2::Facet;

use Moose;
use namespace::autoclean;

has 'main', is => 'ro', isa => 'XML::NewsML_G2::Media_Topic';

has 'facets',
    is      => 'ro',
    isa     => 'HashRef[XML::NewsML_G2::Facet]',
    default => sub { {} },
    traits  => ['Hash'],
    handles => { has_facets => 'count' };

sub add_facet {
    my ( $self, $facet ) = @_;
    return if exists $self->facets->{ $facet->qcode };
    $self->facets->{ $facet->qcode } = $facet;
    return 1;
}

sub uid {
    my ($self) = @_;

    return join( '/', $self->main->qcode, sort keys %{ $self->facets } );
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Concept - a concept covered in the news item,
taken from a standardized controlled vocabulary

=head1 SYNOPSIS

    my $mt = XML::NewsML_G2::Media_Topic->new
        (name => 'alpine skiing', qcode => 20001057);
    my $facet = XML::NewsML_G2::Facet->new
        (name => 'alpine skiing slalom',
         qcode => 'aspfacetvalue:slalom-alpineskiing'
        );
    my $concept = XML::NewsML_G2::Concept->new(main => $mt);
    $concept->add_facet($facet);

=head1 ATTRIBUTES

=over 4

=item facets

Hash mapping qcodes to L<XML::NewsML_G2::Facet> instances

=back

=head1 METHODS

=over 4

=item add_facet

Add a new L<XML::NewsML_G2::Facet> instance

=item uid

Returns a generated unique id for this concept based on the qcodes of its main concept and its facets

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
