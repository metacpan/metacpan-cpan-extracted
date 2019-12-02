package XML::NewsML_G2::Concept_Item;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::Substancial_Item';

has '+nature', default => 'concept';

__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

XML::NewsML_G2::Concept_Item - base class for concept items e.g. events

=head1 DESCRIPTION

This module acts as a base class e.g. for NewsML-G2 event items.
See L<XML::NewsML_G2::Event_Item>.

=head1 AUTHOR

Christian Eder C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
