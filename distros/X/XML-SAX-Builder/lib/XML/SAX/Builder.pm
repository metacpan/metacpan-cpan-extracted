# @(#) $Id: Builder.pm,v 1.4 2003/04/24 12:48:43 dom Exp $
package XML::SAX::Builder;

use strict;
use warnings;

use Carp qw( croak );
use XML::NamespaceSupport;
use XML::SAX::Writer;

our $VERSION = '0.02';
our $AUTOLOAD;

sub new {
    my $class = shift;
    # Escape hatch.
    return XML::SAX::Builder::Tag->new( $class->{Handler}, 'new', @_ )
        if ref $class;
    my ( $handler, %opts ) = @_;

    # Default to spitting out XML to STDOUT.
    $handler ||= XML::SAX::Writer->new;
    bless { Handler => $handler, %opts }, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my @args = @_;
    my $tag  = $AUTOLOAD;
    $tag =~ s/.*:://;
    return if $tag eq 'DESTROY';
    $tag = "$self->{Prefix}:$tag"
        if $self->{Prefix};
    XML::SAX::Builder::Tag->new( $self->{ Handler }, $tag, @args );
}

# Start a new namespace.
sub xmlns {
    my $self = shift;
    XML::SAX::Builder::Namespace->new( $self->{ Handler }, @_ );
}

# Output unescaped stuff.
sub xmlcdata {
    my $self = shift;
    XML::SAX::Builder::CDATA->new( $self->{ Handler }, @_ );
}

# Output an XML DOCTYPE
sub xmldtd {
    my $self = shift;
    XML::SAX::Builder::Doctype->new( $self->{ Handler }, @_ );
}

# Output an XML comment
sub xmlcomment {
    my $self = shift;
    XML::SAX::Builder::Comment->new( $self->{ Handler }, @_ );
}

# Output an XML Processing Instruction.
sub xmlpi {
    my $self = shift;
    XML::SAX::Builder::ProcessingInstruction->new( $self->{ Handler }, @_ );
}

# Return a new generator which will automatically prefix elements.
sub xmlprefix {
    my $self = shift;
    my ($prefix) = @_;
    croak "usage: xmlprefix(prefix)"
        unless $prefix;
    my $class = ref $self;
    return $class->new( $self->{Handler}, Prefix => $prefix );
}

sub _only_one_element {
    my $self = shift;
    my ( @builders ) = @_;

    # A namespace only allows one element child, so this rule is
    # effectively propogated downwards.
    my @tag = grep {
           ref eq 'XML::SAX::Builder::Tag'
        || ref eq 'XML::SAX::Builder::Namespace'
    } @builders;
    return @tag == 1;
}

# Finalise the document.
sub xml {
    my $self = shift;
    my ( @builders ) = @_;
    croak "one and only one root element allowed"
        unless $self->_only_one_element( @builders );
    $self->{ Handler }->start_document( {} );
    my $nsup = XML::NamespaceSupport->new( { xmlns => 1 } );
    $nsup->push_context;
    foreach ( @builders ) {
        if ( ref && $_->can( 'run' ) ) {
            $_->run( $nsup );
        } else {
            $self->{ Handler }->characters( $_ );
        }
    }
    $self->{ Handler }->end_document( {} );
}

#---------------------------------------------------------------------

package XML::SAX::Builder::Base;
use strict;
use warnings;

sub new {
    my ( $class, $handler, @args ) = @_;
    bless $class->_make_closure( $handler, @args ), $class;
}

sub run { shift->(@_) }

sub is_valid_name {
    local $_ = $_[1];
    # This is deliberately very simplistic...
    return m/^[\w:][\w:.-]*$/;
}

sub _is_reserved_name {
    local $_ = $_[1];
    return m/^xml/i;
}

sub _is_valid_lang {
    local $_ = $_[1];
    return m/^
    (
      [a-zA-Z][a-zA-Z]  # ISO639Code
      |
      i-[a-zA-Z]+       # IanaCode
      |
      x-[a-zA-Z]+       # UserCode
    )
    (-[a-zA-Z]+)*       # Subcode
    $/x;
}

#---------------------------------------------------------------------

package XML::SAX::Builder::Tag;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my $class = shift;
    my ( $handler, $tag, @args ) = @_;
    Carp::croak "names beginning with /xml/i are reserved"
        if $class->_is_reserved_name( $tag );
    Carp::croak "doctype must appear before the first element"
        if grep { ref eq 'XML::SAX::Builder::Doctype' } @args;
    Carp::croak "invalid character in name"
        unless $class->is_valid_name( $tag );
    return sub {
        my ($self, $nsup) = @_;
        Carp::croak "usage self->(nsup)"
            unless $self && $nsup;
        my $data = $self->_make_element_data( $nsup, $tag );
        $nsup->push_context;
        $self->_add_attributes( $nsup, $data, shift @args )
            if $args[0] && ref $args[0] eq 'HASH';
        $handler->start_element( $data );
        foreach ( @args ) {
            if ( ref && $_->can( 'run' ) ) {
                $_->run( $nsup );
            } else {
                $handler->characters( { Data => $_ } );
            }
        }
        $handler->end_element( $data );
        $nsup->pop_context;
    };
}

sub _make_element_data {
    my $self = shift;
    my ( $nsup, $tag ) = @_;
    my ( $uri, $prefix, $lname ) = $nsup->process_element_name( $tag );
    $uri ||= ''; $prefix ||= ''; $lname ||= '';
    my $data = {
        LocalName    => $lname,
        Name         => $tag,
        NamespaceURI => $uri,
        Prefix       => $prefix,
    };
    $self->_add_namespace_attributes( $nsup, $data );
    return $data;
}

sub _add_namespace_attributes {
    my $self = shift;
    my ( $nsup, $data ) = @_;
    my %new_namespaces =
        map { $_ => $nsup->get_uri( $_ ) } $nsup->get_declared_prefixes;
    foreach my $prefix ( keys %new_namespaces ) {
        my $xmlns = length( $prefix ) ? "xmlns:$prefix" : "xmlns";
        $new_namespaces{ $xmlns } = delete $new_namespaces{ $prefix };
    }
    $self->_add_attributes( $nsup, $data, \%new_namespaces );
}

sub _add_attributes {
    my $self = shift;
    my ( $nsup, $data, $attr ) = @_;
    Carp::croak "invalid LanguageID"
        if $attr->{'xml:lang'} && !$self->_is_valid_lang( $attr->{'xml:lang'} );
    foreach ( keys %$attr ) {
        my ($uri, $prefix, $lname) = $nsup->process_attribute_name( $_ );
        $uri ||= ''; $prefix ||= ''; $lname ||= '';
        $data->{ Attributes }->{ "{$uri}$_" } = {
            Name         => $_,
            LocalName    => $lname,
            Prefix       => $prefix,
            NamespaceURI => $uri,
            Value        => $attr->{ $_ },
        };
    }
}

#---------------------------------------------------------------------

package XML::SAX::Builder::Namespace;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my $class = shift;
    my ( $handler, $prefix, $uri, @args ) = @_;
    my $child = $args[0];
    Carp::croak "new(handler,prefix,uri,child)"
        unless $handler && defined $prefix && $uri && $child;
    Carp::croak "Only one child of a namespace element is permitted"
        if @args > 1;
    Carp::croak "Namespace child must be element or namespace: $child"
        unless ref($child) eq 'XML::SAX::Builder::Tag' || ref($child) eq __PACKAGE__;
    return sub {
        my ( $self, $nsup ) = @_;
        $nsup->declare_prefix( $prefix => $uri );
        my $data = {
            Prefix       => $prefix,
            NamespaceURI => $uri,
        };
        $handler->start_prefix_mapping( $data );
        $child->run( $nsup );
        $handler->end_prefix_mapping( $data );
    };
}

#---------------------------------------------------------------------

package XML::SAX::Builder::CDATA;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my ( $class, $handler, @args ) = @_;
    Carp::croak "arguments must be character data only"
        if grep { ref } @args;
    @args = grep { defined } @args;
    return sub {
        my ( $self, $nsup ) = @_;
        $handler->start_cdata( {} );
        $handler->characters( { Data => join ( '', @args ) } );
        $handler->end_cdata( {} );
    };
}

#---------------------------------------------------------------------

package XML::SAX::Builder::Doctype;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my ( $class, $handler, $name, $system, $public ) = @_;
    Carp::croak "doctype: must specify name"      unless $name;
    Carp::croak "doctype: must specify system id" unless $system;
    return sub {
        my ( $self, $nsup ) = @_;
        my $data = {
            Name     => $name,
            PublicId => $public,
            SystemId => $system,
        };
        $handler->start_dtd( $data );
        $handler->end_dtd( $data );
    }
}

#---------------------------------------------------------------------

package XML::SAX::Builder::Comment;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my ( $class, $handler, $data ) = @_;
    return sub {
        my ( $self, $nsup ) = @_;
        $handler->comment( { Data => $data } );
    }
}

#---------------------------------------------------------------------

package XML::SAX::Builder::ProcessingInstruction;
use strict;
use warnings;
use base 'XML::SAX::Builder::Base';

sub _make_closure {
    my ( $class, $handler, $target, $data ) = @_;
    Carp::croak "usage: xmlpi(target,data)"
        unless @_ == 4;
    Carp::croak "names beginning with /xml/i are reserved"
        if $class->_is_reserved_name( $target );
    return sub {
        my ( $self, $nsup ) = @_;
        $handler->processing_instruction( {
            Target => $target,
            Data   => $data,
        } );
    }
}

1;
__END__

=head1 NAME

XML::SAX::Builder - build XML documents using SAX

=head1 SYNOPSIS

  my $x = XML::SAX::Builder->new;
  $x->xml( $x->foo( 'bar' ) );

  # Produces:
  # <foo>bar</foo>

  $x->xml( $x->foo( { id => 1 }, 'bar' ) );

  # Produces:
  # <foo id='1'>bar</foo>

  $x->xml( $x->foo( $x->bar(1), 'middle', $x->baz ) );

  # Produces:
  # <foo><bar>1</bar>middle<baz /></foo>

  $x->xml( $x->xmlns( '' => 'urn:foo', $x->foo( 'bar' ) ) );

  # Produces:
  # <foo xmlns='urn:foo'>bar</foo>

  my $pfx = $x->xmlprefix( 'pfx' );
  $x->xml( $x->xmlns( foo => 'urn:foo', $pfx->foo( 'bar' ) ) );

  # Produces:
  # <pfx:foo xmlns:pfx='urn:foo'>bar</pfx:foo>

=head1 DESCRIPTION

This module is a set of classes to allow easy construction of XML
documents, in particular in association with an XML::SAX pipeline.  The
default is to output the XML to stdout, although this is easily changed.

=head1 METHODS

=over 4

=item new ( [ HANDLER ] )

Return a new builder object.  Optionall, a SAX HANDLER may be passed in.
If none is passed in, the default is to use an XmL::SAX::Writer instead.
The default configuration for XML::SAX::Writer sends XML to STDOUT.  If
you wish to get XML sent elsewhere, supply your own XML::SAX::Writer
object.

=item I<element> ( [ [ ATTRS ], OBJ, ... ] )

Any element may be produced by calling it as a method on the Builder
object.  Each argument may be a previously created element, or a piece
of text.

Optionally, the first argument may be a hash reference.  If so, it will
be used as a list of attributes for the element.

=item xml ( OBJECT )

Calling this method actually creates the XML document.  That is to say,
it fires all the handlers for the objects that have been built up and
passed in.  No XML will be output until this method has been called.

=item xmlns ( PREFIX, URI, CHILD )

This method inserts a new namespace into the resulting XML.  PREFIX and
URI are the namespace prefix and uri.  CHILD is either an element
object, or another namespace object.

=item xmlcdata ( TEXT, [ TEXT ] )

Inserts all arguments concatenated together inside a E<lt>![CDATA block.

=item xmldtd ( ELEMENT, SYSTEM [, PUBLIC ] )

Insert a DOCTYPE declaration into the resulting XML.  You have to specify
ELEMENT as the top level element name.

=item xmlcomment ( TEXT )

Inserts TEXT as an XML comment.

=item xmlpi ( TARGET, DATA )

Inserts TARGET and DATA as a processing instruction.

=item xmlprefix ( PREFIX )

Returns a new instance of XML::SAX::Builder, which will automatically
prefix all element names with PREFIX.  This can then be used in place of
the original builder object where needed.  The Handler will be copied
from original builder object.

B<NB>: It's still up to you to ensure that the prefix you're using is
valid according to the current namespace scope!  What that means: If
you're thinking of using this function without calling xmlns() nearby,
you'll lose.

=back

=head1 TODO

CDATA doesn't work at present, because XML::Filter::BufferText, which is
used by XML::SAX::Writer, gets it wrong (inheritance & AUTOLOAD - always
a bad mix :).

Having to specify the top level element name to the doctype is nasty,
but I can't see an obvious way to automatically pick it up right now.

You can't have a tag called I<DESTROY>.

=head1 SEE ALSO

L<XML::SAX>, L<XML::SAX::Writer>.

Alternative XML document constructors: L<XML::SAX::Generator>,
L<XML::Writer>.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan@semantico.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 semantico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# vim: set ai et sw=4 :
