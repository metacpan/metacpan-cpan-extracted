package XML::Doctype::ElementDecl ;

=head1 NAME

XML::Doctype::ElementDecl - A class representing an <!ELEMENT> tag

=head1 SYNOPSIS

   $elt = $dtd->element( 'foo' ) ;
   $elt->name() ;
   $elt->attr( 'foo' ) ;

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
   'ATTDEFS',
   'CONTENT',   # 'EMPTY', 'ANY' or a regexp.  undef if ! is_declared().
   'DECLARED',
   'NAME',
   'NAMES',
   'PATHS',     # A hash which XML::ValidWriter uses to cache the paths
                # it finds from this element name to possible child elements.
   'TODO',      # A list of children that XML::ValidWriter has not yet
                # explored for possible inclusion in PATHS.
) ;

use Carp ;
use UNIVERSAL qw( isa ) ;

$VERSION = 0.1 ;

=head1 METHODS

=item new

   # Undefined element constructors:
   $dtd = XML::Doctype::ElementDecl->new( $name ) ;
   $dtd = XML::Doctype::ElementDecl->new( $name, undef, \@attdefs ) ;

   # Defined element constructors
   $dtd = XML::Doctype::ElementDecl->new( $name, \@kids, \@attdef ) ;
   $dtd = XML::Doctype::ElementDecl->new( $name, [], \@attdefs ) ;

=cut

sub _assemble_re {
   ## Convert the tree of XML::Parser::ContentModel instances to a
   ## regular expression and accumulate a HASH of element names in
   ## NAMES.  This hash is later converted to an ARRAY.
   my XML::Doctype::ElementDecl $self = shift ;
   my ( $cp ) = @_ ;

   if ( $cp->isname ) {
      return '(?:#PCDATA)*' if $cp->name eq '#PCDATA' ;
      ${$self->{NAMES}->{$cp->name}} = 1 ;
      return join( '', '<', quotemeta $cp->name, '>' ) unless $cp->quant ;
   }
   
   return join( '', map $self->_assemble_re( $_ ), $cp->children )
      if $cp->isseq && ! $cp->quant ;

   return join( '',
      '(?:',
      $cp->isname
         ? ( '<', quotemeta( $cp->name ), '>' )
      : $cp->isseq
         ? join( '',  map $self->_assemble_re( $_ ), $cp->children )
      : $cp->ischoice
         ? join( '|', map $self->_assemble_re( $_ ), $cp->children )
      : $cp->ismixed
         ? join(
	    '|',
	    '(?:#PCDATA)?',
	    map(
	       defined $_ ? $self->_assemble_re( $_ ) : (),
	       $cp->children
	    )
	 )
      : (),
      ')',
      $cp->quant || ()
   ) ;

}

sub new {
   my XML::Doctype::ElementDecl $self = fields::new( shift );

   my $cm ; # The XML::Expat::ContentModel object for this DECL.
   ( $self->{NAME}, $cm, $self->{ATTDEFS} ) = @_ ;

   if ( $cm ) {
      if ( $cm->isany ) {
	 $self->{CONTENT} = 'ANY' ;
	 $self->{NAMES} = [] ;
      }
      elsif ( $cm->isempty ) {
	 $self->{CONTENT} = 'EMPTY' ;
	 $self->{NAMES} = [] ;
      }
      elsif ( $cm->ismixed || $cm->isseq || $cm->ischoice ) {
	 $self->{NAMES} = {} ;
	 my $re = $self->_assemble_re( $cm ) ;
	 $self->{CONTENT} = "^$re\$" ; # qr/^$re$/ ;
	 $self->{NAMES} = [ $self->{NAMES} ? keys %{$self->{NAMES}} : () ] ;
      }
      else {
	 croak "'$cm' passed for a content model" ;
      }
   }
   else {
      $self->{NAMES} = [] ;
   }

   return $self ;
}


sub _freeze {
   my $self = shift ;
   if ( defined $self->{CONTENT} && ref $self->{CONTENT} eq 'Regexp' ) {
      ## need two assigns to really, really divorce the SV from the
      ## quircky-half-object RegExp type.
      $self->{CONTENT} = '' ;
      $self->{CONTENT} = "$self->{CONTENT}" ;
   }
}


=item add_attdef

   $elt_decl->add_attdef( $att_def ) ;

=cut

sub add_attdef {
   my XML::Doctype::ElementDecl $self = shift ;
   my ( $attdef ) = @_ ;
   $self->{ATTDEFS}->{$attdef->name} = $attdef ;
}
  

=item attdef

   $attr = $elt->attdef( $name ) ;

Returns the XML::Doctype::AttDef named by $name or undef if there is no
such attribute.

=cut

sub attdef {
   my XML::Doctype::ElementDecl $self = shift ;
   my ( $name ) = @_ ;

   return $self->{ATTDEFS}->{$name} if exists $self->{ATTDEFS}->{$name} ;
   return ;
}


=item attdefs

   $attdefs = $elt->attdefs( $name ) ;

Returns the list of XML::Doctype::AttDef instances associated with this
element.

=cut

sub attdefs {
   my XML::Doctype::ElementDecl $self = shift ;
   my ( $name ) = @_ ;

   return $self->{ATTDEFS} ? values %{$self->{ATTDEFS}} : () ;
}


=item attribute_names

Returns a list of the attdefs' names.

=cut

sub attribute_names {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{ATTDEFS} ? keys %{$self->{ATTDEFS}} : () ;
}


=item child_names

   @names = $elt->child_names ;

Returns a list of names of elements in this element decl's content model.

=cut

sub child_names {
   my XML::Doctype::ElementDecl $self = shift ;

   return @{$self->{NAMES}} ;
}


=item is_declared

   if ( $elt_decl->is_declared ) ...
   $elt_decl->is_declared( 1 ) ;

Returns TRUE if there is any data defined in the element other than name and
attributes or if is_declared has been set by calling is_declared( 1 ) or
passing DECLARED => 1 to new().

=cut

sub is_declared {
   my XML::Doctype::ElementDecl $self = shift ;

   $self->{DECLARED} = shift if @_ ;

   return $self->{DECLARED} || defined $self->{CONTENT} ;
}


=item is_empty

=cut

sub is_empty {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{CONTENT} && $self->{CONTENT} eq 'EMPTY' ;
}


=item is_any

=cut

sub is_any {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{CONTENT} && $self->{CONTENT} eq 'ANY' ;
}


=item is_mixed

=cut

sub is_mixed {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{CONTENT} && $self->{CONTENT} =~ /#PCDATA/ ;
}

sub can_contain_pcdata {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{CONTENT}
      && (
	 $self->{CONTENT} eq 'ANY'
	 || return $self->{CONTENT} =~ /#PCDATA/
      ) ;
}

=item name

   $n = $elt_decl->name ;

Gets the name of the element.

=cut

sub name {
   my XML::Doctype::ElementDecl $self = shift ;

   return $self->{NAME} ;
}


=item validate_content

   $v = $elt_decl->validate_content( \@seq ) ;

Takes an ARRAY ref of tag names (or '#PCDATA') and checks to see if
it would be valid content for elements of this type.

Right now, this must be called only when an element's end tag is
emitted.  It can be broadened to be incremental if need be.

=cut

sub validate_content {
   my XML::Doctype::ElementDecl $self = shift ;
   my ( $c ) = @_ ;

   return 1     if ! defined $self->{CONTENT} || $self->{CONTENT} eq 'ANY' ;
   return ! @$c if $self->{CONTENT} eq 'EMPTY' ;

   ## Must be mixed.  If this elt can have no kids, the test
   ## is quick.  Otherwise we need to validate agains the content
   ## model tree.
   my $content_desc = join(
      '',
      map $_ eq '#PCDATA' ? $_ : "<$_>",
      @$c
   ) ;

# print STDERR "$content_desc\n$self->{CONTENT}\n" ;

#print $self->{CONTENT}, "\n" ;

   return $content_desc =~ $self->{CONTENT} ;
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
