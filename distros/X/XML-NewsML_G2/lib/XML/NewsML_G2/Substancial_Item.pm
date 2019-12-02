package XML::NewsML_G2::Substancial_Item;

use Moose;
use namespace::autoclean;

# document properties
extends 'XML::NewsML_G2::AnyItem';

has 'title', isa => 'Str', is => 'ro', required => 1;
has 'subtitle', isa => 'Str', is => 'rw';
has 'summary',  isa => 'Str', is => 'rw';

has 'media_topics',
    isa     => 'HashRef[XML::NewsML_G2::Media_Topic]',
    is      => 'rw',
    default => sub { {} },
    traits  => ['Hash'],
    handles => { has_media_topics => 'count' };
has 'concepts',
    isa     => 'HashRef[XML::NewsML_G2::Concept]',
    is      => 'rw',
    default => sub { {} },
    traits  => ['Hash'],
    handles => { has_concepts => 'count' };

sub add_media_topic {
    my ( $self, $mt ) = @_;
    return if exists $self->media_topics->{ $mt->qcode };
    $self->media_topics->{ $mt->qcode } = $mt;
    $self->add_media_topic( $mt->parent ) if ( $mt->parent );
    return 1;
}

sub add_concept {
    my ( $self, $concept ) = @_;
    return if exists $self->concepts->{ $concept->uid };
    $self->concepts->{ $concept->uid } = $concept;
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Substancial_Item - base class for substancial item types

=head1 DESCRIPTION

This module acts as an abstract base class for substancial NewsML-G2 item types
as there are News_Items and Concept_Items. Instead of using this class, use the most appropriate subclass.

=head1 ATTRIBUTES

=over 4

=item media_topics

Hash mapping qcodes to L<XML::NewsML_G2::Media_Topic> instances

=item concepts

Hash mapping generated uids to L<XML::NewsML_G2::Concept> instances

=back

=head1 METHODS

=over 4

=item add_media_topic

Add a new L<XML::NewsML_G2::MediaTopic> instance

=item add_concept

Add a new L<XML::NewsML_G2::Concept> instance

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
