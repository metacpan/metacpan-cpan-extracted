package XML::Genx;

use strict;
use warnings;

our $VERSION = '0.22';

# Use XSLoader first if possible.
eval {
    require XSLoader;
    XSLoader::load( __PACKAGE__, $VERSION );
    1;
} or do {
    require DynaLoader;
    # Avoid inheriting from DynaLoader, simulate class method call.
    DynaLoader::bootstrap( __PACKAGE__, $VERSION );
};

1;
__END__

=head1 NAME

XML::Genx - A simple, correct XML writer

=head1 SYNOPSIS

  use XML::Genx;
  my $w = XML::Genx->new;
  eval {
      # <foo>bar</foo>
      $w->StartDocFile( *STDOUT );
      $w->StartElementLiteral( 'foo' );
      $w->AddText( 'bar' );
      $w->EndElement;
      $w->EndDocument;
  };
  die "Writing XML failed: $@" if $@;

=head1 DESCRIPTION

This class is used for generating XML.  The underlying library (genx)
ensures that the output is well formed, canonical XML.  That is, all
characters are correctly encoded, namespaces are handled properly and
so on.  If you manage to generate non-well-formed XML using XML::Genx,
please submit a bug report.

The API is mostly a wrapper over the original C library.  Consult the
genx documentation for the fine detail.  This code is based on genx
I<beta5>.

For more detail on how to use this class, see L</EXAMPLES>.

=head1 METHODS

All methods will die() when they encounter an error.  Otherwise they
return zero.

=over 4

=item new ( )

Constructor.  Returns a new L<XML::Genx> object.

=item StartDocFile ( FILEHANDLE )

Starts writing output to FILEHANDLE.  You have to open this yourself.

This method will not accept a filename.

=item StartDocSender ( CALLBACK )

Takes a coderef (C< sub {} >), which gets called each time that genx
needs to output something.  CALLBACK will be called with two
arguments: the text to output and the name of the function that called
it (one of I<write>, I<write_bounded>, or I<flush>).

  $w->StartDocSender( sub { print $_[0] } );

In the case of I<flush>, the first argument will always be an empty
string.

The string passed to CALLBACK will always be UTF-8.

B<NB>: If you just want to append to a string, have a look at
L<XML::Genx::Simple/StartDocString>.

=item EndDocument ( )

Finishes writing to the output stream.

=item StartElementLiteral ( [NAMESPACE], LOCALNAME )

Starts an element LOCALNAME, in NAMESPACE.  If NAMESPACE is not present
or undef, or an empty string, no namespace is used.  NAMESPACE can
either be a string or an XML::Genx::Namespace object.

=item AddAttributeLiteral ( [NAMESPACE], LOCALNAME, VALUE )

Adds an attribute LOCALNAME, with contents VALUE.  If NAMESPACE is not
present or undef, or an empty string, no namespace is used.  NAMESPACE
can either be a string or an XML::Genx::Namespace object.

=item EndElement ( )

Output a closing tag for the currently open element.

=item LastErrorMessage ( )

Returns the string value of the last error.

=item LastErrorCode ( )

Returns the integer status code of the last error.  This can be
compared to one of the values in L<XML::Genx::Constants>.

This will return zero if no error condition is present.

This value cannot be relied upon to stay the same after further method
calls to the same object.

=item GetErrorMessage ( CODE )

Given a genxStatus code, return the equivalent string.

=item ScrubText ( STRING )

Returns a new version of STRING with prohibited characters removed.
Prohibited characters includes non UTF-8 byte sequences and characters
which are not allowed in XML 1.0.

=item AddText ( STRING )

Output STRING.  STRING must be valid UTF-8.

=item AddCharacter ( C )

Output the Unicode character with codepoint C (an integer).  This is
normally obtained by ord().

=item Comment ( STRING )

Output STRING as an XML comment.  Genx will complain if STRING
contains "--".

=item PI ( TARGET, STRING )

Output a processing instruction, with target TARGET and STRING as the
body.  Genx will complain if STRING contains "?>" or if TARGET is the
string "xml" (in any case).

=item UnsetDefaultNamespace ( )

Insert an C< xmlns="" > attribute.  Has no effect if the default
namespace is already in effect.

=item GetVersion ( )

Return the version number of the Genx library in use.

=item DeclareNamespace ( URI, PREFIX )

Returns a new namespace object.  The resulting object has two methods
defined on it.

=over 4

=item GetNamespacePrefix ( )

Returns the current prefix in scope for this namespace.

=item AddNamespace ( [PREFIX] )

Adds the namespace into the document, optionally with PREFIX.

=back

B<NB>: This object is only valid as long as the original L<XML::Genx>
object that created it is still alive.

=item DeclareElement ( [NS], NAME )

Returns a new element object.  NS must an object returned by
DeclareNamespace(), or undef to indicate no namespace (or not present
at all).

The resulting object has one method available to call.

=over 4

=item StartElement ( )

Outputs a start tag.

=back

B<NB>: This object is only valid as long as the original L<XML::Genx>
object that created it is still alive.

=item DeclareAttribute ( [NS], NAME )

Returns a new attribute object.  NS must an object returned by
DeclareNamespace(), or undef to indicate no namespace (or not present
at all).

There is one method defined for this object.

=over 4

=item AddAttribute ( VALUE )

Adds an attribute to the current element with VALUE as the contents.

=back

B<NB>: This object is only valid as long as the original L<XML::Genx>
object that created it is still alive.

=back

=head1 LIMITATIONS

According to the Genx manual, the things that Genx can't do include:

=over 4

=item *

Generating output in anything but UTF8.

=item *

Writing namespace-oblivious XML. That is to say, you can't have an
element or attribute named foo:bar unless foo is a prefix associated
with some namespace.

=item *

Empty-element tags.

=item *

Writing XML or <!DOCTYPE> declarations. Of course, you could squeeze
these into the output stream yourself before any Genx calls that
generate output.

=item *

Pretty-printing. Of course, you can pretty-print yourself by putting the
linebreaks in the right places and indenting appropriately, but Genx
won't do it for you. Someone might want to write a pretty-printer that
sits on top of Genx.

=back

=head1 EXAMPLES

=over 4

=item *

Simple XML, with no namespaces or attributes.

  $w->StartDocFile( *STDOUT );
  $w->StartElementLiteral( 'strong' );
  $w->AddText( 'bad' );
  $w->EndElement();
  $w->EndDocument();

This produces:

  <strong>bad</strong>

=item *

XML with attributes.

  $w->StartDocFile( *STDOUT );
  $w->StartElementLiteral( 'a' );
  $w->AddAttributeLiteral( href => 'http://www.cpan.org/' );
  $w->AddText( 'CPAN' );
  $w->EndElement();
  $w->EndDocument();

This produces:

  <a href="http://www.cpan.org/">CPAN</a>


=item *

XML with a default namespace.  Note that you have to explicitly pass in
an empty string to specify the default namespace.  Just leaving out the
second argument will result in an autogenerated prefix instead.

  $w->StartDocFile( *STDOUT );
  my $ns = $w->DeclareNamespace( "http://www.w3.org/1999/xhtml", "" );
  $w->StartElementLiteral( $ns, 'strong' );
  $w->AddText( 'bad' );
  $w->EndElement();
  $w->EndDocument();

This produces:

  <strong xmlns="http://www.w3.org/1999/xhtml">bad</strong>

=item *

XML with prefixed namespaces.

  $w->StartDocFile( *STDOUT );
  my $ns = $w->DeclareNamespace( "http://www.w3.org/1999/xhtml", "xh" );
  $w->StartElementLiteral( $ns, 'strong' );
  $w->AddText( 'bad' );
  $w->EndElement();
  $w->EndDocument();

This produces:

  <xh:strong xmlns:xh="http://www.w3.org/1999/xhtml">bad</xh:strong>

=item *

XML with attributes in a namespace.

  $w->StartDocFile( *STDOUT );
  my $ns = $w->DeclareNamespace( "http://www.w3.org/1999/xlink", "x" );
  $w->StartElementLiteral( 'user' );
  $w->AddAttributeLiteral( $ns, href => '/user/42' );
  $w->AddText( 'Fred' );
  $w->EndElement();
  $w->EndDocument();

This produces:

  <user xmlns:x="http://www.w3.org/1999/xlink" x:href="/user/42">Fred</user>

=item *

Declaring elements.  If you are going to be using the same element many
times over, it's worthwhile to predeclare it, since genx doesn't have to
check the validity of the element name on each call.

  $w->StartDocFile( *STDOUT );
  my $ns = $w->DeclareNamespace( 'http://www.w3.org/1999/xhtml', "" );
  my $li = $w->DeclareElement( 'li' );
  $w->StartElementLiteral( 'ul' );

  $li->StartElement();
  $w->AddText( 'Fred' );
  $w->EndElement();

  $li->StartElement();
  $w->AddText( 'Barney' );
  $w->EndElement();

  $w->EndElement();
  $w->EndDocument();

This produces:

  <ul xmlns="http://www.w3.org/1999/xhtml"><li>Fred</li><li>Barney</li></ul>

You might also want to look at L<XML::Genx::Simple/Element>, which does
this for you (when there aren't any namespace involved).

=back

=head1 SEE ALSO

L<XML::Genx::Constants>, L<XML::Genx::Simple>.

L<http://www.tbray.org/ongoing/When/200x/2004/02/20/GenxStatus>

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>

The genx library was created by Tim Bray L<http://www.tbray.org/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dominic Mitchell. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 4

=item 1.

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item 2.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

The genx library is:

Copyright (c) 2004 by Tim Bray and Sun Microsystems.  For copying
permission, see L<http://www.tbray.org/ongoing/genx/COPYING>.

=head1 VERSION

@(#) $Id: Genx.pm 1270 2006-10-08 17:29:33Z dom $

=cut
