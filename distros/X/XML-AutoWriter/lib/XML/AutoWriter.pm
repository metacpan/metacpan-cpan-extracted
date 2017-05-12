package XML::AutoWriter ;
use strict ;
use vars qw( $VERSION ) ;

$VERSION = 0.40;

use Carp ;
use XML::Doctype;
use XML::Doctype::ElementDecl;
use XML::ValidWriter;

use base qw( XML::ValidWriter ) ;

=head1 NAME

XML::AutoWriter - DOCTYPE based XML output

=head1 SYNOPSIS

   use XML::Doctype         NAME => a, SYSTEM_ID => 'a.dtd' ;
   use XML::AutoWriter qw( :all :dtd_tags ) ;
   #
   # a.dtd contains:
   #
   #   <!ELEMENT a ( b1, b2?, b3* ) >
   #	  <!ATTLIST   a aa1 CDATA       #REQUIRED >
   #   <!ELEMENT b1 ( c1 ) >
   #   <!ELEMENT b2 ( c2 ) >
   #
   b1 ;                # Emits <a><b1>
   c2( attr=>"val" ) ; # Emits </b1><b2><c2 attr="val">
   endAllTags ;        # Emits </c2></b2></a>

   ## If you've got an XML::Doctype object handy:
   use XML::AutoWriter qw( :dtd_tags ), DOCTYPE => $doctype ;

   ## If you've saved a preparsed DTD as a perl module
   use FooML::Doctype::v1_0001 ;
   use XML::AutoWriter qw( :dtd_tags ) ;

   ## Or as a normal perl object:
   $writer = XML::AutoWriter->new( ... ) ;
   $writer->startTag( 'b1' ) ;
   $writer->startTag( 'c2' ) ;
   $writer->end ;

=head1 STATUS

Alpha.  Use and patch, don't depend on things not changing drastically.

Many methods supplied by XML::Writer are not yet supplied here.

=head1 DESCRIPTION

This module subclasses L<XML::ValidWriter> and provides automatic
start and end tag generation, allowing you to emit only the 'important'
tags.

See XML::ValidWriter for the details on all functions not documented
here.

=head2 XML::Writer API compatibility

Much of the interface is patterned
after XML::Writer so that it can possibly be used as a drop-in
replacement.  It will take awhile before this module emulates enough
of XML::Writer to be a drop-in replacement in situations where the
more advanced XML::Writer methods are used.

=head2 Automatic start tags

Automatic start tag creation is done when emitting a start tag that is
not allowed to be a child of the currently open tag
but is allowed to be contained in the currently open tag's subset.  In
this case, the minimal number of start tags necessary to allow
All start tags between the current tag and the desired tag are automatically
emitted with no attributes.

=head2 Automatic end tags

If start tag autogeneration fails, then end tag autogeneration is attempted.
startTag() scans the stack of currently open tags trying to close as few as
possible before start tag autogeneration suceeds.

Explicit end tags may be emitted to prevent unwanted automatic start
tags, and, in the future, warnings or errors will be available in place
of automatic start and end tag creation.


=head1 METHODS AND FUNCTIONS

All of the routines in this module can be called as either functions
or methods unless otherwise noted.

To call these routines as functions use either the DOCTYPE or
:dtd_tags options in the parameters to the use statement:

   use XML::AutoWriter DOCTYPE => XML::Doctype->new( ... ) ;
   use XML::AutoWriter qw( :dtd_tags ) ;

This associates an XML::AutoWriter and an XML::Doctype with the
package.  These are used by the routines when called as functions.

=over

=cut

=item new

   $writer = XML::AutoWriter->new( DTD => $dtd, OUTPUT => \*FH ) ;

Creates an XML::AutoWriter.

All other parameters are passed to
the XML::ValidWriter base class constructor.

=cut

#sub new is inherited

sub _find_path {
   ## Find a path from $root to $dest by doing a breadth-first
   ## search.  Cache the results as we go to speed us up next time.
   my XML::Doctype $doctype ;
   my ( $root, $dest ) ;
   ( $doctype, $root, $dest ) = @_ ;

   ## Break encapsulation on XML::Doctype for speed.
   my $elts = $doctype->{ELTS} ;
   croak "Unknown tag '$root'" unless exists $elts->{$root} ;
   croak "Unknown tag '$dest'"
      unless $dest eq '#PCDATA' || exists $elts->{$dest} ;

   require XML::Doctype::ElementDecl;
   my XML::Doctype::ElementDecl $root_elt = $elts->{$root} ;
   # print STDERR "searching for $root ... $dest\n" ;

   return []
      if $root_elt->is_any
         || ( $dest eq '#PCDATA' && $root_elt->can_contain_pcdata ) ;

   my $paths = $root_elt->{PATHS} ;
   unless ( $paths ) {
      ## Init the cache
      $paths = $root_elt->{PATHS} = {
         map {( $_ => [] )} $root_elt->child_names
      } ;
      $root_elt->{TODO} = [ $root_elt->child_names ] ;
   }

   ## Check the cache
   return $root_elt->{PATHS}->{$dest}
      if exists $root_elt->{PATHS}->{$dest} ;

   ## Do the search, starting where we left off.  @todo is a list of known
   ## descendant names.  We scan each such name looking for more descendants
   ## until we exhaust the tree or we find the one we're looking for.  We
   ## avoid loops.
   my $todo = $root_elt->{TODO} ;
   while ( @$todo ) {
      # print STDERR "todo: ", join( ' ', @$todo ), "\n" ;

      my $gkid = shift @$todo ;
      # print STDERR "doing $gkid\n" ;
      push @$todo, $elts->{$gkid}->child_names ;

      my $gkid_path = $paths->{$gkid} ;

      if ( $elts->{$gkid}->can_contain_pcdata() ) {
	 $paths->{'#PCDATA'} = [ @$gkid_path, $gkid ]
	    unless exists $paths->{'#PCDATA'} ;
	 # print STDERR "checking (pcdata) ",
	 # join( '', map "<$_>", @{$paths->{'#PCDATA'}} ), "\n" ;
	 if ( $dest eq '#PCDATA' ) {
	    # print STDERR "Yahoo!\n" ;
	    return $paths->{'#PCDATA'} ;
	 }
      }

      for my $ggkid ( $elts->{$gkid}->child_names ) {
	 next if exists $paths->{$ggkid} ;

	 $paths->{$ggkid} = [ @$gkid_path, $gkid ] ;
	 # print STDERR "checking ",
	 # join( '', map "<$_>", @{$paths->{$ggkid}}, $ggkid ), " ($dest)\n" ;
	 if ( $ggkid eq $dest ) {
	    # print STDERR "Yahoo!\n" ;
	    return $paths->{$ggkid}
	 }
      }
   }
   # print STDERR "rats...\n" ;
   return ;
}


=item characters

   characters( 'yabba dabba dooo' ) ;
   $writer->characters( 'yabba dabba dooo' ) ;

If the currently open tag cannot contain #PCDATA, then start tag autogeneration
will be attempted, followed by end tag autogeneration.

Start tag autogeneration takes place even if you pass in only '', or even (),
the empty list.

=cut

sub characters {
   my XML::AutoWriter $self = &XML::ValidWriter::_self ;

   my $stack = $self->{STACK} ;
   my $doctype = $self->{DOCTYPE} ;

   ## Don't re-emit root if it's been emitted, so that the error message
   ## will be about emitting our $tag, not the root tag.
   $self->startTag( $doctype->name )
      if ! @$stack && ! defined $self->{EMITTED_ROOT} ;

   for ( my $i = $#$stack ; $i >= 0 ; --$i ) {
      my XML::VWElement $elt = $stack->[$i];
      my $path = _find_path( $doctype, $elt->{NAME}, '#PCDATA' ) ;

      if ( defined $path ) {
         while ( $#$stack > $i ) {
	    my XML::VWElement $end_elt = $stack->[-1];
	    $self->endTag( $end_elt->{NAME} )
         }
	 $self->SUPER::startTag( $_ ) for @$path ;
	 last ;
      }
   }

   $self->SUPER::characters( @_ ) ;
}


=item endTag

   endTag ;
   endTag( 'a' ) ;
   $writer->endTag ;
   $writer->endTag( 'a' ) ;

Prints one or more end tags.  The tag name is optional and defaults to the
most recently emitted start tag if not present.

This will emit as many close tags as necessary to close the supplied tag
name, or will emit an error if the tag name specified is not open in the
output document.

=cut

sub endTag {
   my XML::AutoWriter $self = &XML::ValidWriter::_self ;

   return $self->SUPER::endTag() unless @_ ;

   my ( $tag ) = @_ ;

   my $stack = $self->{STACK} ;

   ## Close all tags down to & including the one asked for.  Don't
   ## destroy the stack until we have a match, so we can print it
   ## as an error message if we bottom out.
   for ( my $i = $#$stack ; $i >= 0 ; --$i ) {
      my XML::VWElement $elt = $stack->[$i];
      if ( $elt->{NAME} eq $tag ) {
	 $self->SUPER::endTag() while $#$stack >= $i ;
	 return ;
      }
   }

   confess "No '$tag' open, only " . join( ', ', map { "'$_->{NAME}'"} @$stack ) ;
}


=item startTag

   startTag( 'a', attr => val ) ;  # use default XML::AutoWriter for
                                   # current package.
   $writer->startTag( 'a', attr => val ) ;

Emits a named start tag with optional attributes.  If the named tag
cannot be a child of the most recently started tag, then any tags
that need to be opened between that one and the named tag are opened.

If the named tag cannot be enclosed within the most recently opened
tag, no matter how deep, then startTag() tries to end as few started tags
as necessary to allow the named tag to be emitted within a tag already on the
stack.

This warns (once) if no <?xml?> declaration has been emitted.  It does not
check to see if a <!DOCTYPE...> has been emitted.  It dies if an attempt
is made to emit a second root element.

=cut

sub startTag {
   my XML::AutoWriter $self = &XML::ValidWriter::_self ;
   my $tag = shift ;
   croak "Must supply a tag name" unless defined $tag ;

   my $stack = $self->{STACK} ;
   my $doctype = $self->{DOCTYPE} ;

   ## Don't re-emit root if it's been emitted, so that the error message
   ## will be about emitting our $tag, not the root tag.
   $self->startTag( $doctype->name )
      if ! @$stack
	 && ! defined $self->{EMITTED_ROOT}
	 && $tag ne $doctype->name ;

   for ( my $i = $#$stack ; $i >= 0 ; --$i ) {
      my XML::VWElement $elt = $stack->[$i];
      my $path = _find_path( $doctype, $elt->{NAME}, $tag ) ;
      if ( defined $path ) {
         while ( $#$stack > $i ) {
            my XML::VWElement $end_elt = $stack->[-1];
            $self->endTag( $end_elt->{NAME} )
         }
	 $self->SUPER::startTag( $_ ) for @$path ;
	 last ;
      }
   }

   $self->SUPER::startTag( $tag, @_ ) ;
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

This module is Copyright 2000, 2005, 2009 Barrie Slaymaker.  Some rights reserved.

This module is licensed under your choice of the Artistic, BSD or
General Public License.

=cut

1 ;
