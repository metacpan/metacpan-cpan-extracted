package t::lib::My::Pkg;
use Moose;

with qw(XML::Writer::Compiler::AutoPackage);

use Data::Dumper;
use HTML::Element::Library;

use XML::Element;

has 'data' => (
    is      => 'rw',
    trigger => \&maybe_morph
);
has 'writer' => ( is => 'rw', isa => 'XML::Writer' );
has 'string' => ( is => 'rw', isa => 'XML::Writer::String' );

sub _tag_note {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( note => @$attr );

    $self->_tag_note_to;
    $self->_tag_note_from;
    $self->_tag_note_heading;
    $self->_tag_note_body;
    $self->writer->endTag;
}

sub _tag_note_to {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note to) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( to => @$attr );

    $self->_tag_note_to_person;
    $self->writer->endTag;
}

sub _tag_note_to_person {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note to person) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( person => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_note_from {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note from) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( from => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_note_heading {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note heading) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( heading => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_note_body {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(note body) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( body => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub xml {
    my ($self) = @_;
    my $method = '_tag_note';
    $self->$method;
    $self->writer->end;
    $self;
}

1;
