package XML::NewsML_G2::Facet;

use Moose;
use namespace::autoclean;

with(
    'XML::NewsML_G2::Role::HasQCode',
    'XML::NewsML_G2::Role::HasTranslations'
);

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Facet - a facet to be used in a facetted concept of the
news item, taken from a standardized controlled vocabulary

=head1 SYNOPSIS

    my $facet = XML::NewsML_G2::Facet->new
        (name => 'some aspect of the topic',
         qcode => 'something'
        );

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
