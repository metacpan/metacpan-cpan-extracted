package t::lib::My::Pkg;
use Moose;

use HTML::Element::Library;

use Data::Diver qw( Dive DiveRef DiveError );
use XML::Element;

has 'data' => (
    is      => 'rw',
    trigger => \&maybe_morph
);

sub DIVE {
    my $ref = Dive(@_);
    my $ret;

    #warn "DIVEREF: $ref";
    if ( ref $ref ) {
        $ret = '';
    }
    elsif ( not defined $ref ) {
        $ret = '';
    }
    else {
        $ret = $ref;
    }

    #warn "DIVERET: $ret";
    $ret;

}

sub maybe_morph {
    my ($self) = @_;
    if ( $self->can('morph') ) {
        warn "MORPHING";
        $self->morph;
    }
}

sub note {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->to;
    $self->from;
    $self->heading;
    $self->body;
    $self->writer->endTag;
}

sub to {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note to) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->person;
    $self->writer->endTag;
}

sub person {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note to person) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->characters($data);
    $self->writer->endTag;
}

sub from {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note from) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->characters($data);
    $self->writer->endTag;
}

sub heading {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note heading) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->characters($data);
    $self->writer->endTag;
}

sub body {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = DIVE( $root, qw(note body) );

    my ( $attr, $data ) = EXTRACT($elemdata);
    $self->writer->startTag(@$attr);

    $self->characters($data);
    $self->writer->endTag;
}

sub tree {
    my $self = shift;
    my $href = shift;
    XML::Element->new_from_lol( $self->lol );
}

1;
