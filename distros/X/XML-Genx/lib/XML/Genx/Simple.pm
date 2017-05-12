# @(#) $Id: Simple.pm 1270 2006-10-08 17:29:33Z dom $

package XML::Genx::Simple;

use strict;
use warnings;

use base 'XML::Genx';

our $VERSION = '0.22';

sub Element {
    my $self = shift;
    my ( $name, $text, %attrs ) = @_;

    # Sadly, we can't cache a copy when it's a reference (presumably
    # an XML::Genx::Element), because we have no easy way to get at
    # the actual name through the pointer.
    my $el = ref $name ? $name : $self->_DeclaredElement( $name );

    $el->StartElement;
    while ( my ( $name, $val ) = each %attrs ) {
        my $at = $self->_DeclaredAttribute( $name );
        $at->AddAttribute( $val );
    }
    $self->AddText( $text );
    $self->EndElement;
}

sub DESTROY {
    my $self = shift;
    # Clean up any loose pointers we have...
    $self->_UndeclareElements;
    $self->_UndeclareAttributes;

    # And pass control back to our parents.
    $self->SUPER::DESTROY;
}

#---------------------------------------------------------------------
# Private down here.
#---------------------------------------------------------------------

{
    # Because we don't have anywhere inside $self to store the extra
    # information we want, we need to use some private storage.
    my %el;
    sub _DeclaredElement {
        my $self = shift;
        my ( $name ) = @_;
        return $el{ $self }{ $name } ||= $self->DeclareElement( $name );
    }
    sub _UndeclareElements {
        my $self = shift;
        delete $el{ $self };
    }
}

{
    # Ditto about lack of storage in self.
    my %att;
    sub _DeclaredAttribute {
        my $self = shift;
        my ( $name ) = @_;
        return $att{ $self }{ $name } ||= $self->DeclareAttribute( $name );
    }
    sub _UndeclareAttributes {
        my $self = shift;
        delete $att{ $self };
    }
}

1;
__END__

=head1 NAME

XML::Genx::Simple - A slightly simpler wrapper class for genx

=head1 SYNOPSIS

  use XML::Genx::Simple;
  my $w = XML::Genx::Simple->new;
  eval {
    # <root><foo id="1">bar</foo></root>
    $w->StartDocFile( *STDOUT );
    $w->StartElementLiteral( 'root' );
    $w->Element( foo => 'bar', id => 1 );
    $w->EndElement;
    $w->EndDocument;
  };
  die "Writing XML failed: $@" if $@;

=head1 DESCRIPTION

This class provides some helper methods to make using XML::Genx
simpler in the common case.

=head1 METHODS

=over 4

=item StartDocString ( )

Starts a new document, and collects the result into a string.

This method is offered as an extension to the genx API since it is
significantly quicker.  Many thanks to A. Pagaltzis for suggesting it.

=item GetDocString ( )

Returns the string from the current writer object.  

B<NB>: This is only guaranteed to be well-formed XML after you have
called EndDocument().

B<NB>: This will only produce sensible output if you've called
StartDocString() previously.

=item Element ( NAME, TEXT, [ATTRS] )

Outputs E<lt>NAMEE<gt>TEXTE<lt>/NAMEE<gt> in one go.  NAME can be
either a text string or an XML::Genx::Element object.

If NAME is a text string, an XML::Genx::Element object will be
created, used and cached.  So there's no real advantage to passing one
in.

Optionally, ATTRS can be passed in as a list of key/value pairs.
Again, each key used as an attribute name will be cached.

This method provides no namespace support.

=back

=head1 SEE ALSO

L<XML::Genx>.

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

@(#) $Id: Simple.pm 1270 2006-10-08 17:29:33Z dom $

=cut
