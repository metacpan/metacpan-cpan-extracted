package XML::NewsML_G2::SportFacetValue;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::Facet';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::SportFacetValue - a sport facet vakze to be used in a
facetted concept of the news item, taken from a standardized controlled
vocabulary at http://cv.iptc.org/newscodes/asportfacetvalue

=head1 SYNOPSIS

    my $facet = XML::NewsML_G2::SportFacetValue->new
        (name => 'alpine skiing slalom',
         qcode => 'slalom-alpineskiing'
        );

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
