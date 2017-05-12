package XML::APML::ExplicitData;

use strict;
use warnings;

use XML::APML::Concept;
use XML::APML::Source;

use base 'Class::Data::Accessor';

__PACKAGE__->mk_classaccessor( tag_name => 'ExplicitData' );
__PACKAGE__->mk_classaccessor( is_implicit => 0 );

=head1 NAME

XML::APML::ExplicitData - ExplicitData markup

=head1 SYNOPSIS

=head1 DESCRIPTION

Class that represents ExplicitData mark-up for APML

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    bless {
        concepts => [],
        sources  => [],
    }, $class;
}

=head2 concepts

Get all concepts.
Returns as array in list context.

    my @concepts = $explicit->concepts;

Or returns as array reference.

    my $concepts = $explicit->concepts;

Also, you can set multiple concepts at once.

    $explicit->concepts($concept1, $concept2, $concept3);

=cut

sub concepts {
    my $self = shift;
    $self->add_concept($_) for @_;
    return wantarray ? @{ $self->{concepts} } : $self->{concepts};
}

=head2 add_concept

Add concept

    $explicit->add_concept($concept);

=cut

sub add_concept {
    my ($self, $concept) = @_;
    push @{ $self->{concepts} }, $concept;
}

=head2 sources

Get all sources.
Returns as array in list context.

    my @sources = $explicit->sources;

Or returns as array reference.

    my $sources = $explicit->sources;

Also, you can set multiple sources at once.

    $explicit->sources($source1, $source2, $source3);

=cut

sub sources {
    my $self = shift;
    $self->add_source($_) for @_;
    return wantarray ? @{ $self->{sources} } : $self->{sources};
}

=head2 add_source

Add source

    $explicit->add_source($source);

=cut

sub add_source {
    my ($self, $source) = @_;
    push @{ $self->{sources} }, $source;
}

sub parse_node {
    my ($class, $node) = @_;
    my $data = $class->new;
    my @concepts = $node->findnodes('*[local-name()=\'Concepts\']/*[local-name()=\'Concept\']');
    $data->add_concept(XML::APML::Concept->parse_node($_, $class->is_implicit)) for @concepts;
    my @sources = $node->findnodes('*[local-name()=\'Sources\']/*[local-name()=\'Source\']');
    $data->add_source(XML::APML::Source->parse_node($_, $class->is_implicit)) for @sources;
    $data;
}

sub build_dom {
    my ($self, $doc) = @_;
    my $class = ref $self;
    my $elem = $doc->createElement($class->tag_name);
    my $concepts = $doc->createElement('Concepts');
    for my $concept ( @{ $self->{concepts} } ) {
        $concepts->appendChild($concept->build_dom($doc, $class->is_implicit));
    }
    $elem->appendChild($concepts);
    my $sources = $doc->createElement('Sources');
    for my $source ( @{ $self->{sources} } ) {
        $sources->appendChild($source->build_dom($doc, $class->is_implicit));
    }
    $elem->appendChild($sources);
    $elem;
}

1;

