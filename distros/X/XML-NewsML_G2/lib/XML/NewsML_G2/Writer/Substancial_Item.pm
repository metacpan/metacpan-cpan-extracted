package XML::NewsML_G2::Writer::Substancial_Item;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::Writer';

sub _create_subjects_media_topic {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('media topics')
        if $self->_root_item->has_media_topics;
    foreach my $mt_qcode ( sort keys %{ $self->_root_item->media_topics } ) {
        my $mt = $self->_root_item->media_topics->{$mt_qcode};
        my $why = $mt->direct ? 'why:direct' : 'why:ancestor';
        push @res,
            my $s = $self->create_element(
            'subject',
            type       => 'cpnat:abstract',
            why        => $why,
            _name_text => $mt
            );
        $self->scheme_manager->add_qcode_or_literal( $s, 'medtop',
            $mt->qcode );
        foreach my $lang ( sort keys %{ $mt->translations } ) {
            $s->appendChild(
                $self->create_element(
                    'name',
                    'xml:lang' => $lang,
                    _text      => $mt->translations->{$lang}
                )
            );
        }
        if ( $mt->parent ) {
            $s->appendChild( my $b = $self->create_element('broader') );
            $self->scheme_manager->add_qcode_or_literal( $b, 'medtop',
                $mt->parent->qcode );
            my $hierarchy = $self->_create_hierarchy( $mt, 'medtop' );
            $b->appendChild($hierarchy) if $hierarchy;
        }
    }
    return @res;
}

sub _create_subject_concept {
    my ( $self, $name, $item, $qcode_prefix ) = @_;

    my $elem = $self->create_element( $name, _name_text => $item );
    $self->scheme_manager->add_qcode_or_literal( $elem, $qcode_prefix,
        $item->qcode );
    foreach my $lang ( sort keys %{ $item->translations } ) {
        $elem->appendChild(
            $self->create_element(
                'name',
                'xml:lang' => $lang,
                _text      => $item->translations->{$lang}
            )
        );
    }
    return $elem;
}

sub _create_subjects_concepts {
    my ($self) = @_;

    my @res;
    push @res, $self->doc->createComment('concepts')
        if $self->_root_item->has_concepts;
    foreach my $concept_uid ( sort keys %{ $self->_root_item->concepts } ) {
        my $concept = $self->_root_item->concepts->{$concept_uid};
        push @res, my $s = $self->create_element('subject');
        $s->appendChild(
            $self->_create_subject_concept(
                'mainConcept', $concept->main, 'medtop'
            )
        );
        foreach my $facet_qcode ( sort keys %{ $concept->facets } ) {
            my $facet = $concept->facets->{$facet_qcode};
            my ($facet_cls) = reverse split '::', $facet->meta->name;
            $s->appendChild(
                $self->_create_subject_concept(
                    'facetConcept', $facet, lc $facet_cls
                )
            );
        }
    }

    return @res;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

XML::NewsML_G2::Writer::Substancial_Item - base class for writers
creating DOM trees conforming to substancial items

=head1 DESCRIPTION

This module acts as a base class e.g. for event item writers and news item
writers.
See L<XML::NewsML_G2::Writer::News_Item>, L<XML::NewsML_G2::Writer::Event_Item>.


=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
