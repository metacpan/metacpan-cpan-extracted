package XML::Doctype ;

=head1 NAME

XML::Doctype - A DTD object class

=head1 SYNOPSIS

   # To parse an external DTD at compile time, useful when
   # using XML::ValidWriter
   use XML::Doctype NAME => 'FooML', SYSTEM_ID => 'FooML.dtd' ;
   use XML::Doctype NAME => 'FooML', DTD_TEXT  => $dtd ;

   # Parsing at run-time
   $doctype = XML::Doctype->new( 'FooML', SYSTEM_ID => 'FooML.dtd' ) ;

   # or
   $doctype = XML::Doctype->new() ;
   $doctype->parse( 'FooML', 'FooML.dtd' ) ;

   # Saving the parsed object
   open( PM, ">FooML/DTD/v1_000.pm" ) or die $! ;
   print PM $doctype->as_pm( 'FooML::DTD::v1_000' ) ;

   # Using a saved parsed DTD
   use FooML::DTD::v1_000 ;

   $doctype = FooML::DTD::v1_000->new() ;


=head1 DESCRIPTION

This module parses DTDs and allows them to be saved as .pm files and
reloaded.  The ability to save and reload is intended to aid in packaging
parsed DTDs with XML tools so that XML::Parser need not be installed.

=head1 STATUS

This module is alpha code.  It's developed enough to support XML::ValidWriter,
but need a lot of work.  Some big things that are lacking are:

=over

=item *

methods or objects to build / traverse the DTD

=item *

XML::Doctype::ELEMENT

=item *

XML::Doctype::ATTLIST

=item *

XML::Doctype::ENITITY

=back

=cut

use strict ;
use vars qw( $VERSION %_default_dtds ) ;
use fields (
   'ELTS',       # A hash of declared & undeclared elements, keyed by name
   'NAME',       # The root node (the name from the DOCTYPE decl).
   'SYSID',
   'PUBID',
) ;

use Carp ;
use XML::Doctype::ElementDecl ;
use XML::Doctype::AttDef ;

$VERSION = 0.11 ;

=head1 METHODS

=item new

   $doctype = XML::Doctype->new() ;
   $doctype = XML::Doctype->new( 'FooML', DTD_TEXT => $doctype_text ) ;
   $doctype = XML::Doctype->new( 'FooML', SYSTEM_ID => 'FooML.dtd' ) ;

=cut

sub new {
   my XML::Doctype $self = fields::new( shift );

   return $self unless @_ ;

   my $name = shift ;

   if ( @_ == 1 ) {
      $self->parse_dtd_file( $name, shift ) ;
   }
   else {
      while ( @_ ) {
	 for ( shift ) {
	    if ( /^SYSTEM(?:_ID)?$/ ) {
	       $self->parse_dtd_file( $name, shift ) ;
	    }
	    elsif ( $_ eq 'DTD_TEXT' ) {
	       $self->parse_dtd( $name, shift ) ;
	    }
	    else {
	       croak "Unrecognized parameter '$_'" ;
	    }
	 }
      }
   }

   ## Do this here so subclass author won't be suprised when eventually
   ## calling save_as_pm.
   my $class = ref $self;
   no strict 'refs' ;
   croak "\$$class\::VERSION not defined" 
      unless defined ${"$class\::VERSION"} ;

   return $self ;
}


=item name

   $name = $doctype->name() ;

   Sets/gets the name.

=cut

sub name {
   my XML::Doctype $self = shift ;
   $self->{NAME} = shift if @_ ;
   return $self->{NAME}
}


##
## Called to translate the XML::Parser::ContentModel passed by XML::Parser
## in to a tree of XML::Doctype::ChildDecl instances.
sub _import_ContentModel {
}


sub _do_parse {
   my XML::Doctype $self = shift ;
   my ( $fake_doc ) = @_ ;

   my $elts = $self->{ELTS} = {} ;

   ## Should maybe use libwww to fetch URLs, but will do files for now
   ## We require this lazily to save load time and allow it to be
   ## not present if it's not needed.
   require XML::Parser ;
   my $p = XML::Parser->new(
      ParseParamEnt => 1,
      Handlers => {
         Doctype => sub {
            my $expat = shift ;
	    my ( $name, $sysid, $pubid, $internal ) = @_ ;
	    $self->{NAME} = $name ;
	    $self->{SYSID} = $sysid ;
	    $self->{PUBID} = $pubid ;
	 },
	 
	 Element => sub {
	    my $expat = shift ;
	    my ( $name, $model ) = @_ ;

	    croak "ELEMENT '$name' already defined"
	       if exists $elts->{$name} && $elts->{$name}->is_declared ;

            my $elt = XML::Doctype::ElementDecl->new( $name, $model ) ;
	    $elt->is_declared( 1 ) ;
            $elts->{$name} = $elt ;

	    for ( $elt->child_names ) {
	       $elts->{$_} = XML::Doctype::ElementDecl->new( $_ )
	          unless $elts->{$_} ;
	    }
	 },

         Attlist => sub {
	    my $expat = shift ;
	    my ( $elt_name, $att_name, $type, $default, $fixed ) = @_ ;

	    $elts->{$elt_name} = XML::Doctype::ElementDecl->new()
	       unless exists $elts->{$elt_name} ;

	    $default =~ s/^'(.*)'$/$1/ || $default =~ s/^"(.*)"$/$1/ ;
	    
	    $elts->{$elt_name}->add_attdef(
	       XML::Doctype::AttDef->new( 
		  $att_name,
		  $type,
		  $fixed ? ( '#FIXED', $default ) : ( $default, undef ),
	       )
	    ) ;
	 },
      },
   ) ;

   $p->parse( $fake_doc ) ;

   croak "Doctype",
      defined $self->{SYSID} ? " SYSTEM_ID $self->{SYSID}" : (),
      " did not declare root node <$self->{NAME}>"
      unless exists $self->{ELTS}->{$self->{NAME}} ;

#   require Data::Dumper ; print Data::Dumper::Dumper( $elts ) ;
   ## TODO: Check that all elements referred-to by name in the element tree
   ## rooted at $self->{NAME} are actually declared.
}


=item parse_dtd

   $doctype->parse_dtd( $name, $doctype_text ) ;
   $doctype->parse_dtd( $name, $doctype_text, 'internal' ) ;

Parses the text of a DTD from a scalar.  $name is used to indicate the
name of the DOCTYPE, and thus the root node.

The DTD is considered to be external unless the third parameter is
TRUE.

=cut

sub parse_dtd {
   my XML::Doctype $self = shift ;
   my ( $name, $text, $internal ) = @_ ;

   $self->_do_parse( <<TOHERE ) ;
<?xml version="1.0" encoding="US-ASCII" standalone="yes"?>
<!DOCTYPE $name [
$text
]>
<$name></$name>
TOHERE
}


=item parse_dtd_file

   $doctype->parse_dtd_file( $name, $system_id [, $public_id] ) ;
   $doctype->parse_dtd_file( $name, $system_id [, $public_id], 'internal' ) ;

Parses a DTD from a file.  Eventually will support full URL syntax.

$public_id is ignored for now, and $system_id is used to locate
the DTD.

This routine requires XML::Parser.  XML::Parser is not loaded at any
other time and is not needed to use the resulting DTD object.

The DTD is considered to be external unless the fourth parameter is
TRUE.

   $doctype->parse_dtd_file( $name, $system_id, $p_id, 'internal' ) ;
   $doctype->parse_dtd_file( $name, $system_id, undef, 'internal' ) ;

=cut


sub parse_dtd_file {
   my XML::Doctype $self = shift ;
   my ( $name, $system_id, undef, $internal ) = @_ ;

   $self->_do_parse( <<TOHERE ) ;
<?xml version="1.0" encoding="US-ASCII" standalone="no"?>
<!DOCTYPE $name SYSTEM "$system_id" >
<$name></$name>
TOHERE
}


=item system_id

   $system_id = $doctype->system_id() ;

   Sets/gets the system ID.

=cut

sub system_id {
   my XML::Doctype $self = shift ;
   $self->{SYSID} = shift if @_ ;
   return $self->{SYSID}
}

=item public_id

   $public_id = $doctype->public_id() ;

   Sets/gets the public_id.

=cut

sub public_id {
   my XML::Doctype $self = shift ;
   $self->{PUBID} = shift if @_ ;
   return $self->{PUBID}
}

=item element_decl

   $elt_decl = $doctype->element_decl( $name ) ;

Returns the XML::Doctype:Element object associated with $name.  These can
be defined by <!ELEMENT> tags or undefined, which can happen if they
were just referred-to by <!ELEMENT> or <!ATTLIST> tags.

=cut

sub element_decl {
   my XML::Doctype $self = shift ;
   my ( $name ) = @_ ;

   return $self->{ELTS}->{$name} if exists $self->{ELTS}->{$name} ;
   return ;
}

=item element_names

Returns an unsorted list of element names.  This list includes names that
are declared and undeclared (but referred to in element declarations or
attribute definitions).

=cut

sub element_names {
   my XML::Doctype $self = shift ;
   my $h = {} ;
   for ( keys %{$self->{ELTS}} ) {
      $h->{$_} = 1 ;
      $h->{$_} = 1 for $self->{ELTS}->{$_}->child_names() ;
   }

   return keys %$h ;
}


=item as_pm

   open( PM, "FooML/DTD/v1_001.pm" )            or die $! ;
   print PM $doctype->as_pm( 'FooML::DTD::v1_001' ) or die $! ;
   close PM                                     or die $! ;

Then, later:

   use FooML::DTD::v1_001 ;   # Do *not* use () as a parameter list!

Returns string containing the DTD as an independant module, allowing the
DTD to be parsed in the development environment and shipped as Perl code,
so that the target environment need not have XML::Parser installed.

This is useful for XML creation-only tools and as an
efficiency tuning measure if you will be rereading the same set of DTDs over
and over again.

=cut

## TODO: Save as pure, unblessed data structure that XML::Doctype can
## convert to internal format, to increase inter-version compatibility.

sub as_pm {
   my XML::Doctype $self = shift ;
   my ( $package ) = @_ ;

   my $date = localtime ;
   my $class = ref $self ;

   my $version ;
   if ( $class ne __PACKAGE__ ) {
      no strict 'refs' ;
      croak "\$$class\::VERSION not defined" 
         unless defined ${"$class\::VERSION"} ;
      $version = "$class, v" . ${"$class\::VERSION"} . ", (" ;
   }

   $version .= __PACKAGE__ . ", v$VERSION" ;
   $version .= ')'
      if $class ne __PACKAGE__ ;

   require Data::Dumper ;
   my $d = Data::Dumper->new( [$self], ['$doctype'],  ) ;
#   $d->Freezer( '_freeze' ) unless $d->can( 'Dumpperl' ) ;
   $d->Purity(1);     ## We really do want to dump executable code.
   $d->Indent(1);     ## Used fixed indent depth.  I find this more readable.

   return
      join( '', <<ENDPREAMBLE, $d->can( 'Dumpperl' ) ? $d->Dumpperl : $d->Dump, "\n 1 ;\n" );
package $package ;

##
## THIS FILE CREATED AUTOMATICALLY: YOU MAY LOSE ANY EDITS IF YOU MOFIFY IT.
##
## When: $date
## By:   $version
##

require XML::Doctype ;

sub import {
   my \$pkg = shift ;
   my \$callpkg = caller ;
   \$XML::Doctype::_default_dtds{\$callpkg} = \$doctype ;
}

ENDPREAMBLE
}


sub _freeze {
   my $self = shift ;
   $_->_freeze for values %{$self->{ELTS}} ;
   return $self ;
}


=item import

=item use

   use XML::Doctype NAME => 'FooML', SYSTEM_ID => 'dtds/FooML.dtd' ;

import() constructs a default DTD object for the calling package
so that XML::ValidWriter's functional interface can use it.

If XML::Doctype is subclassed, the subclasses' constructor is called with
all parameters.

=cut

sub import {
   my $class = shift ;
   my $callpkg = caller ;

   my @others ;
   my @dtd_args ;
   while ( @_ ) {
      for ( shift ) {
	 if ( $_ eq 'NAME' ) {
	    push @dtd_args, shift ;
	 }
	 elsif ( /^[A-Z][A-Z_0-9]*$/ ) {
	    push @dtd_args, $_, shift ;
	 }
	 else {
	    push @others, $_ ;
	 }
      }
   }
   $_default_dtds{$callpkg} = $class->new( @dtd_args ) 
      if @dtd_args ;

   croak join( ', ', @others ), " not exported by $class" if @others ; 
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
