package XML::Filter::GenericChunk;

# $Id: GenericChunk.pm,v 1.8 2002/03/14 09:20:53 cb13108 Exp $

use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::SAX::Parser;
use XML::SAX::Base;

# this is done because of mod_perl!
$XML::Filter::GenericChunk::VERSION = '0.07';
@XML::Filter::GenericChunk::ISA = qw( XML::SAX::Base );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{TagName}      ||= [];
    $self->{RelaxedNames} ||= 0;
    $self->{NamespaceURI} ||= "";
    $self->{TagByName}    = {};
    # $self->{DropElement}  = 0;

    $self->_prepare_names();

    return $self;
}

sub start_document {
    my $self = shift;

    $self->{WBChunk} = "";
    $self->{CurrentElement} = "";
    $self->{DropElement} ||= 0;

    $self->SUPER::start_document(@_);
}

sub start_element {
    my $self = shift;
    my $element = shift;
    $self->_init_element($element);

    unless ( $self->is_tag() and $self->{DropElement} == 1 ) { 
        $self->SUPER::start_element($element);
    }
}

sub end_element {
    my $self = shift;
    my $element = shift;

    # need to remember if this is the active tag, because after reset this 
    # information is not available anymore
    my $istag = $self->is_tag();

    $self->_reset_element($element);
    $self->reset_data();

    unless ( $istag and $self->{DropElement} == 1 ) { 
        $self->SUPER::end_element($element);
    }
}

sub relaxed_names {
    my $self = shift;
    if ( scalar @_ && defined $_[0] ) {
        $self->{RelaxedNames} = shift;
    }
    return $self->{RelaxedNames};
}

sub set_tagname {
    my $self = shift;
    push @{$self->{TagName}}, @_;
    $self->_prepare_names();
}

sub set_namespace {
    my $self = shift;
    my $uri = shift;
    $self->{NamespaceURI} = $uri if defined $uri;
}

sub reset_tagname {
    my $self = shift;
    $self->{TagName} = [];
    $self->{TagByName} = {};
}

sub is_tag {
    return length $_[0]->{CurrentElement} > 0 ? 1 : 0;
}

sub flush_chunk {
    my $self = shift;

    my $docfrag = $self->get_data_fragment();
    if ( defined $docfrag and defined $docfrag->childNodes() ) {
        # TODO: check if there are any namespaces to be fixed!

        my $saxparser = XML::LibXML::SAX::Parser->new( Handler => $self->{Handler} );
        foreach my $node ( $docfrag->childNodes() ) {
            $saxparser->process_node( $node );
        }
    }
}

sub get_data_fragment {
    my $self = shift;
    return undef unless length $self->{WBChunk};

    my $docfrag = undef;
    my $parser = XML::LibXML->new();

    eval {
        if ( defined $self->{Encoding} ) {
            $docfrag = $parser->parse_xml_chunk( $self->get_data,
                                                 $self->{Encoding} );
        }
        else {
            $docfrag = $parser->parse_xml_chunk( $self->get_data );
        }
    };

    $self->reset_data;

    if ( $@ ) {
        die "brocken chunk\n" . $@;
    }

    return $docfrag;
}

sub add_data {
    my $self = shift;
    foreach my $s ( @_ ) {
        $self->{WBChunk} .= $s if defined $s;
    }
}

sub get_data   { $_[0]->{WBChunk}; }
sub reset_data { $_[0]->{WBChunk} = ""; }

sub _prepare_names {
    my $self = shift;
    # this precaches the tagnames
    map {$self->{TagByName}->{$_} = 1;} @{$self->{TagName}};
}

sub _init_element {
    my $self = shift;
    my $element = shift;

    unless( length $self->{CurrentElement} > 0 ) {
        # in this case we test the entire name!
        my $name = "";
        if ( $self->relaxed_names() == 1 ) {
            $name = $element->{Name};
            if ( defined $name and exists $self->{TagByName}->{$name} ) {
                $self->{CurrentElement} = $name;
                return;
            }

        }
        elsif ( length $self->{NamespaceURI} ) {
            return unless defined $element->{NamespaceURI}
              and $self->{NamespaceURI} eq $element->{NamespaceURI};
        }

        $name = $element->{LocalName};

        if ( defined $name and exists $self->{TagByName}->{$name} ) {
            $self->{CurrentElement} = $name;
        }
    }
}

sub _reset_element {
    my $self = shift;
    my $element = shift;

    if ( $self->is_tag() ) {
        my $name = "";
        if ( $self->relaxed_names() == 1) {
            $name = $element->{Name};
            if ( defined $name
                 and defined $self->{CurrentElement}
                 and $self->{CurrentElement} eq $name ) {
                $self->{CurrentElement} = "";
                return;
            }
        }
        elsif ( length $self->{NamespaceURI} ) {
            return unless defined $element->{NamespaceURI}
              and $self->{NamespaceURI} eq $element->{NamespaceURI};
        }

        $name = $element->{LocalName};

        if ( defined $name
             and defined $self->{CurrentElement}
             and $self->{CurrentElement} eq $name ) {
            $self->{CurrentElement} = "";
        }
    }
}

1;
__END__

=head1 NAME

XML::Filter::GenericChunk - Base Class for SAX Filters parsing WellBallanced Chunks

=head1 SYNOPSIS

  use XML::Filter::GenericChunk;

=head1 DESCRIPTION

XML::Filter::GenericChunk is inherited by
XML::SAX::Base. XML::Filter::GenericChunk itself is an abstract class,
therefore as a filter it will not result any useful output. If you
need a simple Chunk filter for your SAX pipeline, check
XML::Filter::CharacterChunk which is shipped with this module.

=head2 The Constructor

new() is the constructor of this class. It takes three extra
parameter:

=over 4

=item B<TagName>

This expects an array reference with the TagNames the filter should
handle.

=item B<RelaxedNames>

Relaxed name handling is an extra feature. RelaxedNames is a boolean
switch, that allows one to filter all tags of a certain name -
independant of the Namespace they belong to. This may is useful, but
also dangerous, too. By default, strict namespace handling is
activated.

=item B<NamespaceURI>

If only a certain namespace should be filtered, this parameter allows
to specify the NamespaceURI. If NamespaceURI is omited, the qualifing
name is tested (prefix and local name), otherwise only the local name
will be tested.

=head2 Methods

=over 4

=item add_data

This function is very important. It helps to collect the chunk until
it is really processed. It takes an array of string, that are added to
the chunk.

=item flush_chunk

As the central feature method B<flush_chunk> will process the chunk
that was set through B<add_data> to the filter. The chunk will cause
the filter to generate the appropiate SAX events as it would be
processed by a XML parser.

If the chunk is not wellballanced, this function will
B<die()>. Therefore make shure it is wrapped into an eval block. In
any case the currently stored chunk will be removed from the
filter. Because of this B<flush_chunk> should only be called if the
chunk should contain a valid chunk.

=item get_data

simply returns the data collected by add_data() as a string value.

=item reset_data

removes all data collected until this point.

=item get_data_fragment

This function parses the data collected with add_data() into a
document fragment. This function is internally used by
flush_chunk(). It is pretty usefull, to use this function if one needs
more control than flush_chunk() provides.

=item is_tag

this function allows to test a inherited calls to find out, if the
current sequence is handled by the filter.

=item relaxed_names

This takes a boolean value in order to toggle the relax name handling
after the filter creation.

=item set_namespace

Sets/ removes the namespace uri of the filter.

=item set_tagname

This method allows to add extra tag names to the list of tested
tagnames.  it expects an array instead of an array reference!

=item reset_tagname

This helper function is used to remove all tagnames that are filtered.

=back

=head2 Examples

TODO

=head1 AUTHOR

Christian Glahn, christian.glahn@uibk.ac.at,
Innsbruck University

=head1 SEE ALSO

XML::LibXML, XML::SAX::Base, XML::Filter::CharacterChunk

=cut
