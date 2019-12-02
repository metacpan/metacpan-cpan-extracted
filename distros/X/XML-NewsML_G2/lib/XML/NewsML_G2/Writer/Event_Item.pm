package XML::NewsML_G2::Writer::Event_Item;

use Moose;
use Carp;
use namespace::autoclean;

extends 'XML::NewsML_G2::Writer::Concept_Item';

has 'event_item',
    isa      => 'XML::NewsML_G2::Event_Item',
    is       => 'ro',
    required => 1;

sub _build__root_item {
    my $self = shift;
    return $self->event_item;
}

sub _create_id_element {
    my ($self) = @_;

    my $result = $self->create_element('conceptId');
    $self->scheme_manager->add_qcode( $result, 'eventid',
        $self->event_item->event_id );
    return $result;
}

sub _create_type_element {
    my ($self) = @_;

    my $result = $self->create_element( 'type', qcode => 'cpnat:event' );
    return $result;
}

sub _create_location {
    my ($self) = @_;

    my $loc    = $self->event_item->location;
    my $result = $self->create_element('location');
    $result->appendChild(
        $self->create_element( 'name', _text => $loc->name ) );
    if ( $loc->latitude && $loc->longitude ) {
        $result->appendChild( my $details =
                $self->create_element('POIDetails') );
        $details->appendChild(
            $self->create_element(
                'position',
                latitude  => $loc->latitude,
                longitude => $loc->longitude
            )
        );
    }

    return $result;
}

sub _create_dates {
    my ($self) = @_;

    my $result = $self->create_element('dates');
    $result->appendChild(
        $self->create_element(
            'start',
            _text => $self->_formatter->format_datetime(
                $self->event_item->start
            )
        )
    );
    $result->appendChild(
        $self->create_element(
            'end',
            _text =>
                $self->_formatter->format_datetime( $self->event_item->end )
        )
    );
    return $result;
}

sub _create_coverage {
    my ($self) = @_;

    my $result = $self->create_element('newsCoverageStatus');
    $self->scheme_manager->add_qcode( $result, 'ncostat', 'int' );
    my $coverage = join '/', $self->event_item->all_coverage;
    $result->appendChild(
        $self->create_element( 'name', _text => $coverage ) );
    return $result;
}

sub _create_multilang_elements {
    my ( $self, $name, $text, %attrs ) = @_;
    my @result;
    push @result,
        $self->create_element( $name, _text => $text->text, %attrs );
    foreach my $lang ( $text->languages ) {
        my $trans = $text->get_translation($lang);
        push @result,
            $self->create_element(
            $name,
            _text      => $trans,
            'xml:lang' => $lang,
            %attrs
            );
    }

    return @result;
}

sub _create_inner_content {
    my ( $self, $parent ) = @_;
    $parent->appendChild( $self->doc->createComment('event information') );
    $parent->appendChild($_)
        foreach $self->_create_multilang_elements( 'name',
        $self->event_item->title );

    if ( my $subtitle = $self->event_item->subtitle ) {
        $parent->appendChild($_)
            foreach $self->_create_multilang_elements( 'definition',
            $subtitle, role => 'definitionrole:short' );
    }
    if ( my $summary = $self->event_item->summary ) {
        $parent->appendChild($_)
            foreach $self->_create_multilang_elements( 'definition',
            $summary, role => 'definitionrole:long' );
    }
    $parent->appendChild( my $details =
            $self->create_element('eventDetails') );
    $details->appendChild( $self->doc->createComment('dates') );
    $details->appendChild( $self->_create_dates() );
    if ( $self->event_item->has_coverage ) {
        $details->appendChild( $self->doc->createComment('coverage') );
        $details->appendChild( $self->_create_coverage() );
    }
    $details->appendChild( $self->doc->createComment('location') );
    $details->appendChild( $self->_create_location() );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

XML::NewsML_G2::Writer::Event_Item - create DOM tree conforming to
NewsML-G2 for Event Concept Items

=for test_synopsis
    my ($ei, $sm);

=head1 SYNOPSIS

    my $w = XML::NewsML_G2::Writer::Event_Item->new
        (event_item => $ei, scheme_manager => $sm);

    my $dom = $w->create_dom();

=head1 DESCRIPTION

This module implements the creation of a DOM tree conforming to
NewsML-G2 for Event Concept Items.  Depending on the version of the standard
specified, a version-dependent role will be applied. For the API of
this module, see the documentation of the superclass L<XML::NewsML_G2::Writer>.

=head1 ATTRIBUTES

=over 4

=item event_item

L<XML::NewsML_G2::Event_Item> instance used to create the output document

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
