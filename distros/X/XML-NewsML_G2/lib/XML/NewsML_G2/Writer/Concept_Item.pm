package XML::NewsML_G2::Writer::Concept_Item;

use Moose;
use Carp;
use namespace::autoclean;

extends 'XML::NewsML_G2::Writer::Substancial_Item';

has '+_root_node_name',      default => 'conceptItem';
has '+_nature_qcode_prefix', default => 'cinat';

sub _create_rights_info {
}

sub _create_subjects {
    my $self = shift;
    my @res;
    push @res, $self->_create_subjects_media_topic();
    push @res, $self->_create_subjects_concepts();
    return @res;
}

sub _create_content_meta {
    my ( $self, $root ) = @_;

    $root->appendChild( my $cm = $self->create_element('contentMeta') );
    my @subjects = $self->_create_subjects();
    $cm->appendChild($_) foreach (@subjects);
    return;
}

sub _create_content {
    my ( $self, $root ) = @_;

    $root->appendChild( my $concept = $self->create_element('concept') );
    $concept->appendChild( $self->_create_id_element() );
    $concept->appendChild( $self->_create_type_element() );
    $self->_create_inner_content($concept);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

XML::NewsML_G2::Writer::Concept_Item - base class for writers
creating DOM trees conforming to Concept Items

=head1 DESCRIPTION

This module acts as a base class e.g. for event item writers.
See L<XML::NewsML_G2::Writer::Event_Item>.


=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
