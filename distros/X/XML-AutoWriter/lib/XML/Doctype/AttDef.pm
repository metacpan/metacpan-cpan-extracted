package XML::Doctype::AttDef ;

=head1 NAME

XML::Doctype::AttDef - A class representing a definition in an <!ATTLIST> tag

=head1 SYNOPSIS

   $attr = $elt->attribute( $name ) ;
   $attr->name ;

=head1 DESCRIPTION

This module is used to represent <!ELEMENT> tags in an XML::Doctype object.
It contains <!ATTLIST> tags as well.

=head1 STATUS

This module is alpha code.  It's developed enough to support XML::ValidWriter,
but need a lot of work.  Some big things that are lacking are:

=over

=cut

use strict ;
use vars qw( $VERSION %_default_dtds ) ;
use fields (
   'DEFAULT', # The default value if QUANT is '#FIXED' or '', undef otherwise
   'NAME',
   'OUT_DEFAULT', # Used to set a universal output default value
   'QUANT',   # '#REQUIRED', '#IMPLIED', '#FIXED', undef
   'TYPE',    # 'CDATA', 'ID', ...
) ;

use Carp ;

$VERSION = 0.1 ;

=head1 METHODS

=item new

   $dtd = XML::Doctype::AttDef->new( $name, $type, $default ) ;

=cut

sub new {
   my XML::Doctype::AttDef $self = fields::new( shift );

   ( $self->{NAME}, $self->{TYPE} ) = @_[0,1] ;
   if ( $_[0] =! /^#/ ) {
      ( $self->{QUANT}, $self->{DEFAULT} ) = @_[2,3] ;
   }
   else {
      $self->{DEFAULT} = $_[2] ;
   }

   return $self ;
}


=item default

   ( $spec, $value ) = $attr->default ;
   $attr->default( '#REQUIRED' ) ;
   $attr->default( '#IMPLIED' ) ;
   $attr->default( '', 'foo' ) ;
   $attr->default( '#FIXED', 'foo' ) ;

Sets/gets the default value.  This is a 

=cut

sub default {
   my XML::Doctype::AttDef $self = shift ;

   if ( @_ ) {
      my ( $default ) = @_ ;
      my $quant = $self->quant ;
      if ( defined $default ) {
         if ( defined $quant && $quant =~ /^#(REQUIRED|IMPLIED)/ ) {
	    carp
	 "Attribute '", $self->name, "' $quant default set to '$default'" ;
	 }
      }
      else {
         if ( ! defined $quant ) {
	    carp "Attribute '", $self->name, "' default set to undef" ;
         }
         elsif ( $quant eq '#FIXED' ) {
	    carp "Attribute '", $self->name, "' #FIXED default set to undef" ;
	 }
      }
      $self->{DEFAULT} = $default ;
   }

   return $self->{DEFAULT} ;
}


=item quant

   $attdef->quant( $q ) ;
   $q = $attdef->quant ;

Sets/gets the attribute quantifier: '#REQUIRED', '#FIXED', '#IMPLIED', or ''.

=cut

sub quant {
   my XML::Doctype::AttDef $self = shift ;

   $self->{QUANT} = shift if @_ ;
   return $self->{QUANT} ;
}


=item name

   $attdef->name( $name ) ;
   $name = $attdef->name ;

Sets/gets this attribute name.  Don't change the name while an attribute
is in an element's attlist, since it will then be filed under the wrong
name.

=cut

sub name {
   my XML::Doctype::AttDef $self = shift ;

   $self->{NAME} = shift if @_ ;
   return $self->{NAME} ;
}


=item default_on_write

   $attdef->default_on_write( $value ) ;
   $value = $attdef->default_on_write ;

   $attdef->default_on_write( $attdef->default ) ;

Sets/gets the value which is automatically output for this attribute
if none is supplied to $writer->startTag.  This is typically used
to set a document-wide default for #REQUIRED attributes (and perhaps
plain attributes) so that the attribute is treated like a #FIXED tag
and emitted with a fixed value.

The default_on_write does not need to be the same as the default unless
the quantifier is #FIXED.

=cut

sub default_on_write {
   my XML::Doctype::AttDef $self = shift ;

   $self->{OUT_DEFAULT} = shift if @_ ;
   return $self->{OUT_DEFAULT} ;
}


=head1 SUBCLASSING

This object uses the fields pragma, so you should use base and fields for
any subclasses.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

This module is Copyright 2000, 2005 Barrie Slaymaker.  All rights reserved.

This module is licensed under your choice of the Artistic, BSD or
General Public License.

=cut

1 ;
