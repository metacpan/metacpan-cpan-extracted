package XML::DOM::XML_Base;
use XML::DOM;
our $VERSION = '0.02';

BEGIN { }

package XML::DOM::Element;
use strict;

our $scheme_re  = '[a-zA-Z][a-zA-Z0-9.+\-]*';

sub _isAbsolute {
  return shift =~ /^($scheme_re):/so ? 1 : 0
}

sub getBase {
  my ( $self ) = @_;
  my $parent = $self;
  my $fullbase = '';
  do {
    if ( $parent->isa( 'XML::DOM::Element' ) ) {
      if ( my $base = $parent->getAttribute( 'xml:base' ) ) {
        $fullbase = $base.$fullbase;
        # [2] done
        if ( _isAbsolute( $fullbase ) ) {
          return $fullbase;
        }
      }
    }
  } while ( $parent = $parent->getParentNode() );
  # [3,4] wasn't possible to get an absolute URI, so return the best
  # relative URI we have
  return $fullbase;
}

sub getAttributeWithBase {
  my ( $self, $name ) = @_;
  # XML Base spec (http://www.w3.org/TR/xmlbase/) says:
  # The rules for determining the base URI can be summarized as follows (highest priority to lowest):
  #  [1] The base URI is embedded in the document's content.
  #  [2] The base URI is that of the encapsulating entity (message, document, or none).
  #  [3] The base URI is the URI used to retrieve the entity.
  #  [4] The base URI is defined by the context of the application.

  my $val = $self->getAttribute( $name ) or return undef;

  # [1] done
  if ( _isAbsolute( $val ) ) {
    return $val;
  }
  else {
    return $self->getBase().$val;
  }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::DOM::XML_Base - Apply xml:base to attribute values.

=head1 SYNOPSIS

  use XML::DOM::XML_Base;
  my $parser = XML::DOM::Parser->new();

  my $xml = qq(
    <ecto x="1" xml:base="a/">
      <meso x="2" xml:base="b/">
        <endo x="3" xml:base="c/"/>
      </meso>
    </ecto>
  );

  # build the DOM
  my $dom = $parser->parse( $xml );

  # get some elements
  my $endo = $dom->getElementsByTagName( 'endo' )->item( 0 );
  my $meso = $dom->getElementsByTagName( 'meso' )->item( 0 );
  my $ecto = $dom->getElementsByTagName( 'ecto' )->item( 0 );

  print $endo->getBase()."\n"; # a/b/c/
  print $meso->getBase()."\n"; # a/b/
  print $ecto->getBase()."\n"; # a/

  print $endo->getAttributeWithBase( 'x' )."\n"; # a/b/c/3
  print $meso->getAttributeWithBase( 'x' )."\n"; # a/b/2
  print $ecto->getAttributeWithBase( 'x' )."\n"; # a/1

=head1 DESCRIPTION

C<XML::DOM::XML_Base> implements the W3C XML Base specification as an
extension to L<XML::DOM>.

XML Base spec (http://www.w3.org/TR/xmlbase/) says:
The rules for determining the base URI can be summarized as follows
(highest priority to lowest):

  [1] The base URI is embedded in the document's content.
  [2] The base URI is that of the encapsulating entity (message, document, or none).
  [3] The base URI is the URI used to retrieve the entity.
  [4] The base URI is defined by the context of the application.

Rules [1] and [2] and handled by this module by recursively examining parent
nodes for C<xml:base> attributes, and returning the first constructable absolute URI,
or the relative URI constructed at the end of the recursion (i.e. at the root XML
element).

Rules [3] and [4] are outside the scope of what C<XML::DOM::XML_Base> is capable of,
as an L<XML::DOM::Document> can be constructed without a URI (e.g. from a string or
filehandle).

=head1 SEE ALSO

L<URI>, L<XML::DOM>

XML Base Specification (http://www.w3.org/TR/xmlbase/)

XML Base Tutorial (http://www.zvon.org/xxl/XMLBaseTutorial/Output/)

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
