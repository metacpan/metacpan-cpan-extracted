package XML::ValidWriter ;

=head1 NAME

XML::ValidWriter - DOCTYPE driven valid XML output

=head1 SYNOPSIS

   ## As a normal perl object:
   $writer = XML::ValidWriter->new(
      DOCTYPE => $xml_doc_type,
      OUTPUT => \*FH
   ) ;
   $writer->startTag( 'b1' ) ;
   $writer->startTag( 'c2' ) ;
   $writer->end ;

   ## Writing to a scalar:
   $writer = XML::ValidWriter->new(
      DOCTYPE => $xml_doc_type,
      OUTPUT => \$buf
   ) ;

   ## Or, in scripting mode:
   use XML::Doctype         NAME => a, SYSTEM_ID => 'a.dtd' ;
   use XML::ValidWriter qw( :all :dtd_tags ) ;
   b1 ;                # Emits <a><b1>
   c2( attr=>"val" ) ; # Emits </b1><b2><c2 attr="val">
   endAllTags ;        # Emits </c2></b2></a>

   ## If you've got an XML::Doctype object handy:
   use XML::ValidWriter qw( :dtd_tags ), DOCTYPE => $doctype ;

   ## If you've saved a preparsed DTD as a perl module
   use FooML::Doctype::v1_0001 ;
   use XML::ValidWriter qw( :dtd_tags ) ;

   #
   # This all assumes that the DTD contains:
   #
   #   <!ELEMENT a ( b1, b2?, b3* ) >
   #	  <!ATTLIST   a aa1 CDATA       #REQUIRED >
   #   <!ELEMENT b1 ( c1 ) >
   #   <!ELEMENT b2 ( c2 ) >
   #

=head1 STATUS

Alpha.  Use and patch, don't depend on things not changing drastically.

Many methods supplied by XML::Writer are not yet supplied here.

=head1 DESCRIPTION

This module uses the DTD contained in an XML::Doctype to enable compile-
and run-time checks of XML output validity.  It also provides methods and
functions named after the elements mentioned in the DTD.  If an
XML::ValidWriter uses a DTD that mentions the element type TABLE, that
instance will provide the methods

   $writer->TABLE( $content, ...attrs... ) ;
   $writer->start_TABLE( ...attrs... ) ;
   $writer->end_TABLE() ;
   $writer->empty_TABLE( ...attrs... ) ;

.  These are created for undeclared elements--those elements not explicitly
declared with an <!ELEMENT ..> declaration--as well.  If an element
type name conflicts with a method, it will not override the internal method.

When an XML::Doctype is parsed, the name of the doctype defines the root
node of the document.  This name can be changed, though, see L<XML::Doctype>
for details.

In addition to the object-oriented API, a function API is also provided.
This allows you to import most of the methods of XML::ValidWriter as functions
using standard import specifications:

   use XML::ValidWriter qw( :all ) ; ## Could list function names instead

C<:all> does not import the functions named after elements mentioned in
the DTD, you need to import those tags using C<:dtd_tags>:

   use XML::Doctype NAME => 'foo', SYSTEM_ID => 'fooml.dtd' ;
   use XML::ValidWriter qw( :all :dtd_tags ) ;

or

   BEGIN {
      $doctype = XML::Doctype->new( ... ) ;
   }

   use XML::ValidWriter DOCTYPE => $doctype, qw( :all :dtd_tags ) ;

=head2 XML::Writer API compatibility

Much of the interface is patterned
after XML::Writer so that it can possibly be used as a drop-in
replacement.  It will take awhile before this module emulates enough
of XML::Writer to be a drop-in replacement in situations where the
more advanced XML::Writer methods are used.  If you find you need
a method not suported here, write it and send it in!

This was not derived from XML::Writer because XML::Writer does not
expose it's stack.  Even if it did, it's might be difficult to store
enough state in it's stack.

Unlike XML::Writer, this does not call in all of the IO::* family, and
method dispatch should be faster.  DTD-specific methods are also supported
(see L</AUTOLOAD>).

=head2 Quick and Easy Unix Filter Apps

For quick applications that provide Unix filter application
functionality, XML::ValidWriter and XML::Doctype cooperate to allow you
to

=over

=item 1

Parse a DTD at compile-time and set that as the default DTD for
the current package.  This is done using the

   use XML::Doctype NAME => 'FooML, SYSTEM_ID => 'fooml.dtd' ;

syntax.

=item 2

Define and export a set of functions corresponding to start and end tags for
all declared and undeclared ELEMENTs in the DTD.  This is done by using
the C<:dtd_tags> export symbol like so:

   use XML::Doctype     NAME => 'FooML, SYSTEM_ID => 'fooml.dtd' ;
   use XML::ValidWriter qw(:dtd_tags) ;

If the elements a, b_c, and d-e are referred to in the DTD, the following
functions will be exported:

   a()        end_a()       # like startTag( 'a', ... ) and endTag( 'a' )
   b_c()      end_b_c()
   d_e()      end_d_e()     {'d-e'}()     {'end_d-e'}()

These functions emit only tags, unlike the similar functions found
in CGI.pm and XML::Generator, which also allow you to pass content
in as parameters.

See below for details on conflict resolution in the mapping of entity
names containing /\W/ to Perl subroutine names.

If the elements declared in the DTD might conflict with functions
in your package namespace, simple put them in some safe namespace:

   package FooML ;
   use XML::Doctype         NAME => 'FooML', SYSTEM_ID => 'fooml.dtd' ;
   use XML::ValidWriter qw(:dtd_tags) ;

   package Whatever ;

The advantage of importing these subroutine names is that perl
can then detect use of unknown tags at compile time.

If you don't want to use the default DTD, use the C<-dtd> option:

   BEGIN { $dtd = XML::Doctype->new( .... ) }
   use XML::ValidWriter qw(:dtd_tags), -dtd => \$dtd ;

=item 3

Use the default DTD to validate emitted XML.  startTag() and endTag()
will check the tag being emitted against the list of currently open
tags and either emit a minimal set of missing end and start tags
necessary to achieve document validity or produce errors or warnings.

Since the functions created by the C<:dtd_tags> export symbol are wrappers
around startTag() and endTag(), they provide this functionality as well.

So, if you have a DTD like

   <!ELEMENT a ( b1, b2?, b3* ) >

       <!ATTLIST   a aa1 CDATA       #REQUIRED >

   <!ELEMENT b1 ( c1 ) >
   <!ELEMENT b2 ( c2 ) >
   <!ELEMENT b3 ( c3 ) >

you can do this:

   use XML::Doctype     NAME => 'a', SYSTEM_ID => 'a.dtd' ;
   use XML::ValidWriter ':dtd_tags' ;

   getDoctype->element_decl('a')->attdef('aa1')->default_on_write('foo') ;

   a ;
      b1 ;
	 c1 ;
	 end_c1 ;
      end_b1 ;
      b3 ;
	 c3( -attr => val ) ;
	 end_c3 ;
      end_b3 ;
   end_a ;

and emit a document like

   <a aa1="foo">
      <b1>
         <c1 />
      </b1>
      <b3>
         <c3 attr => "val" />
      </b3>
   </a>

.

=back

=head1 OUTPUT OPTIMIZATION

XML is a very simple langauge and does not offer a lot of room for
optimization.  As the spec says "Terseness in XML markup is of
minimal importance."  XML::ValidWriter does optimize the following
on output:

C<E<lt>a...E<gt>E<lt>/aE<gt>>   becomes 'E<lt>a... />'

Spurious emissions of C<]]E<gt>E<lt>![CDATA[> are supressed.

XML::ValidWriter chooses whether or not to use a <![CDATA[...]]> section
or simply escape '<' and '&'.  If you are emitting content for
an element in multiple 
calls to L</characters>, the first call decides whether or not to use
CDATA, so it's to your advantage to emit as much in the first call
as possible.  You can do

   characters( @lots_of_segments ) ;

if it helps.

=cut

use strict ;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS ) ;
use fields (
   'AT_BOL',      # Set if the last thing emitted was a "\n".
   'CDATA_END_PART', # ']' or ']]' if we're in CDATA mode and the last parm
                  # to the last call to characters() ended in this.
   'CHECKED_XML_DECL',
   'FILE_NAME',   # set if the constructor received OUTPUT => 'foo.barml'
   'CREATED_AT',  # File and line number the instance was created at
   'DATA_MODE',   # Whether or not to be in data mode
   'DOCTYPE',     # The parsed DOCTYPE & DTD
   'EMITTED_DOCTYPE',
   'EMITTED_ROOT',
   'EMITTED_XML',
   'IS_STANDALONE',
   'METHODS',     # Cache of AUTOLOADed methods
   'OUTPUT',      # The output filehandle
   'STACK',       # The array of open elements
   'SHOULD_WARN', # Turns on warnings for things that should (but may not be)
                  # the case, like emitting '<?xml?>'.  defaults to '1'.
   'WAS_END_TAG', # Set if last thing emitted was an empty tag or an end tag
   'STRAGGLERS',  # '>' if we just emitted a start tag, ']]>' if <![CDATA[
) ;
use UNIVERSAL qw( isa ) ;

use Carp ;

my @EXPORT_OK = qw(
   characters
   dataElement
   defaultWriter
   emptyTag
   endAllTags
   endTag
   getDataMode
   getDoctype
   getOutput
   rawCharacters
   startTag
   select_xml
   setDataMode
   setDoctype
   setOutput
   xmlDecl
) ;

$VERSION = 0.38;

##
## A tiny helper class of instances ValidWriter places on the stack as
## it opens new elements
##
package XML::VWElement ;

use fields qw( NAME ELT_DECL CONTENT ) ;

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my XML::VWElement $self ;
   {
      no strict 'refs' ;
      $self = bless {}, $class ;
   }

   my ( $elt_decl ) = @_ ;

   $self->{NAME} = $elt_decl->name ;
   $self->{ELT_DECL} = $elt_decl ;
   $self->{CONTENT} = [] ;

   return $self ;
}

sub add_content {
   my XML::VWElement $self = shift ;

   for ( @_ ) {
      if ( ! @{$self->{CONTENT}}
         || ! ( $_                     eq '#PCDATA' 
	    &&  $self->{CONTENT}->[-1] eq '#PCDATA'
	 )
      ) {
         push @{$self->{CONTENT}}, $_ ;
      }
   }
}

package XML::ValidWriter;
##
## This module can maintain a set of XML::ValidWriter instances,
## one for each calling package.
##
my %pkg_writers ;

sub _self {
   ## MUST be called as C< &_self ;>

   ## If it's a reference to anything but a plain old hash, then the
   ## first param is either an XML::ValidWriter, a reference to a glob
   ## a reference to a SCALAR, or a reference to an IO::Handle.
   return shift if ( @_ && ref $_[0] && isa( $_[0], 'XML::ValidWriter' ) ) ;
   my $callpkg = caller(1) ;
   croak "No default XML::ValidWriter declared for package '$callpkg'"
      unless $pkg_writers{$callpkg} ;
   return $pkg_writers{$callpkg} ;
}

=head1 METHODS AND FUNCTIONS

All of the routines in this module can be called as either functions
or methods unless otherwise noted.

To call these routines as functions use either the DOCTYPE or
:dtd_tags options in the parameters to the use statement:

   use XML::ValidWriter DOCTYPE => XML::Doctype->new( ... ) ;
   use XML::ValidWriter qw( :dtd_tags ) ;

This associates an XML::ValidWriter and an XML::Doctype with the
package.  These are used by the routines when called as functions.

=over

=item new

   $writer = XML::ValidWriter->new( DTD => $dtd, OUTPUT => \*FH ) ;

Creates an XML::ValidWriter.

The value passed for OUTPUT may be:

=over

=item a SCALAR ref

if you want to direct output to append to a scalar.  This scalar is
truncated whenever the XML::ValidWriter object is reset() or
DESTROY()ed

=item a file handle glob ref or a reference to an IO object

XML::ValidWriter does not load IO.  This is
the only mode compatible with XML::Writer.

=item a file name

A simple scalar is taken to be a filename to be created or truncated
and emitted to.  This file will be closed when the XML::ValidWriter object
is reset or deatroyed.

=back

NOTE: if you leave OUTPUT undefined, then the currently select()ed
output is used at each emission (ie calling select() can alter the
destination mid-stream).  This eases writing command line filter
applications, the select() interaction is unintentional, and please
don't depend on it.  I reserve the right to cache the select()ed
filehandle at creation time or at time of first emission at some
point in the future.

=cut

sub new {
   my XML::ValidWriter $self = fields::new( shift );
   $self->{SHOULD_WARN} = 1 ;

   while ( @_ ) {
      for my $parm ( shift ) {
         if ( $parm eq 'DOCTYPE' ) {
	    croak "Can't have two DOCTYPE parms"
	       if defined $self->{DOCTYPE} ;
	    $self->{DOCTYPE} = shift ;
	 }
	 elsif ( $parm eq 'OUTPUT' ) {
	    croak "Can't have two OUTPUT parms"
	       if defined $self->{OUTPUT} || defined $self->{FILE_NAME} ;
	    if ( ref $_[0] ) {
	       $self->{OUTPUT} = shift ;
	    }
	    else {
	       $self->{FILE_NAME} = shift ;
	    }
	 }
      }
   }

   ## Find the original caller
   my $caller_depth = 1 ;
   ++$caller_depth
      while caller && isa( scalar( caller $caller_depth ), __PACKAGE__ ) ;
   $self->{CREATED_AT} = join( ', ', (caller( $caller_depth ))[1,2] );
   $self->reset ;

   return $self ;
}


=item import

Can't think of why you'd call this method directly, it gets called
when you use this module:

   use XML::ValidWriter qw( :all ) ;

In addition to the normal functionality of exporting functions like
startTag() and endTag(), XML::ValidWriter's import() can create
functions corresponding to all elements in a DTD.  This is done using
the special C<:dtd_tags> export symbol.  For example,

   use XML::Doctype     NAME => 'FooML', SYSTEM_ID => 'fooml.dtd' ;
   use XML::ValidWriter qw( :dtd_tags ) ;

where fooml.dtd referse to a tag type of 'blurb' causes these
functions to be imported:

   blurb()         # calls defaultWriter->startTag( 'blurb', @_ ) ;
   blurb_element() # calls defaultWriter->dataElement( 'blurb', @_ ) ;
   empty_blurb()   # calls defaultWriter->emptyTag( 'blurb', @_ ) ;
   end_blurb()     # calls defaultWriter->endTag( 'blurb' ) ;
   
The range of characters for element types is much larger than
the range of characters for bareword perl subroutine names, which
are limited to [a-zA-Z0-9_].  In this case, XML::ValidWriter will
export an oddly named function that you can use a symbolic reference
to call (you will need C<no strict 'refs' ;> if you are doing
a C<use strict ;>):

   &{"space-1999:moonbase"}( ...attributes ... ) ;

.  XML::ValidWriter will also try to fold the name in to bareword
space by converting /\W/ symbols to '_'.
If the resulting function name,

   space_1999_moonbase( ...attributes... ) ;
   
has not been generated and is not the name of an element type, then
it will also be exported.

If you are using a DTD that might introduce function names that
conflict with existing ones, simple export them in to their own
namespace:

   package ML ;

   use XML::Doctype     NAME => 'foo', SYSTEM_ID => 'fooml.dtd' ;
   use XML::ValidWriter qw( :dtd_tags ) ;

   package main ;

   use XML::ValidWriter qw( :all ) ;

   ML::foo ;
   ML::c2 ;
   ML::c1 ;
   ML::end_a ;

I gave serious thought to converting ':' in element names to '::' in
function declarations, which might work well in the functions-in-their-own-
namespace case, but not in the default case, since Perl does not
(yet) have relative namespaces. Another alternative is to allow a
mapping of XML namespaces to Perl namespaces to be done.

=cut

## use %pkg_writers, defined above

## This import is odd: it allows subclasses to 'inherit' exports
sub import {
   my $pkg     = shift ;
   my $callpkg = caller ;

   my $doctype ;
   my @args ;
   my @syms ;
   my $export_dtd_tags ;
   my $op ;
   while ( @_ ) {
      $op = shift ;
      if ( $op eq 'DOCTYPE' ) {
	 $doctype = shift ;
      }
      elsif ( $op eq ':dtd_tags' ) {
	 $export_dtd_tags = 1 ;
      }
      elsif ( $op eq ':all' ) {
	 push @syms, @EXPORT_OK ;
      }
      elsif ( $op =~ /^[A-Z_0-9]+$/ ) {
	 push @args, $op ;
	 push @args, shift ;
      }
      elsif ( $op =~ /^[:$%@*]/ ) {
	 croak "import tag '$op' not supported" ;
      }
      else {
	 push @syms, $op ;
      }
   }

   if ( $export_dtd_tags || $doctype ) {
      $pkg_writers{$callpkg} = $pkg->new( @args )
         unless $pkg_writers{$callpkg} ;

      $doctype = $XML::Doctype::_default_dtds{$callpkg}
	 if ! $doctype && exists $XML::Doctype::_default_dtds{$callpkg} ;

      $pkg_writers{$callpkg}->setDoctype( $doctype ) if $doctype ;
   }

   $pkg_writers{$callpkg}->exportDTDTags( $callpkg )
      if $export_dtd_tags ;

   my %ok = map { ( $_ => 1 ) } @EXPORT_OK ;
   for my $sym ( @syms ) {
      no strict 'refs' ;
      $sym =~ s/^&// ;
      if ( $ok{$sym} ) {
	 if ( defined &{"$pkg\::$sym"} ) {
	    *{"$callpkg\::$sym"} = \&{"$pkg\::$sym"} ;
	    next ;
	 }
	 elsif ( defined &{$sym} ) {
	    *{"$callpkg\::$sym"} = \&{"$sym"} ;
	    next ;
	 }
      }
      croak "Function '$sym' not exported by '$pkg' or " . __PACKAGE__ ;
   }
}


my %escapees ;
$escapees{'&'}   = '&amp;'  ;
$escapees{'<'}   = '&lt;'   ;
$escapees{'>'}   = '&gt;'   ;
$escapees{']>'}  = ']&gt;'  ;
$escapees{']]>'} = ']]&gt;' ;
$escapees{'"'}   = '&quot;' ;
$escapees{"'"}   = '&apos;' ;

# Takes a list, returns a list: don't use in scalar context.
sub _esc {
   croak "_esc used in scalar context" unless wantarray ;
   my $text ;
   return map {
      $text = $_ ;
      if ( $text =~ /([\x00-\x08\x0B\x0C\x0E-\x1F])/ ) {
	 croak sprintf(
	    "Illegal character 0x%02d (^%s) sent",
	    ord $1,
	    chr( ord( "A" ) + ord( $1 ) - 1 )
	 )
      }
      $text =~ s{([&<]|^>|^\]>|\]\]>)}{$escapees{$1}}eg ;
      $text ;
   } @_ ;
}


sub _esc1 {
   my $text = shift ;
   if ( $text =~ /([\x00-\x08\x0B\x0C\x0E-\x1F])/ ) {
      croak sprintf(
         "Invalid character 0x%02d (^%s) sent",
         ord $1,
	 chr( ord( "A" ) + ord( $1 ) - 1 )
      )
   }
   $text =~ s{([&<]|^>|^\]>|\]\]>)}{$escapees{$1}}eg ;
   return $text ;
}

sub _attr_esc1 {
   my $text = shift ;
   if ( $text =~ /([\x00-\x08\x0B\x0C\x0E-\x1F])/ ) {
      croak sprintf(
         "Invalid character 0x%02d (^%s) sent",
         ord $1,
	 chr( ord( "A" ) + ord( $1 ) - 1 )
      )
   }
   $text =~ s{([&<"'])}{$escapees{$1}}eg ;
   return $text ;
}


sub _esc_cdata_ends {
   ## This could be very memory hungry, but alas...
   my $text = join( '', @_ ) ;
   if ( $text =~ /([\x00-\x08\x0B\x0C\x0E-\x1F])/ ) {
      croak sprintf(
         "Invalid character 0x%02d (^%s) sent",
         ord $1,
	 chr( ord( "A" ) + ord( $1 ) - 1 )
      )
   }
   $text =~ s{\]\]>}{]]]]><![CDATA[>}g ;
   return $text ;
}


=item characters

   characters( "escaped text", "& more" ) ;
   $writer->characters( "escaped text", "& more" ) ;

Emits character data.  Character data will be escaped before output, by either
transforming 'E<lt>' and '&' to &lt; and &amp;, or by enclosing in a
'C<E<lt>![CDATA[...]]E<gt>>' bracket, depending on which will be more
human-readable, according to the module.

=cut

sub characters {
   my XML::ValidWriter $self = &_self ;
   my $to = $self->{OUTPUT} || select ;

   croak "Can't emit characters before the root element"
      if ! defined $self->{EMITTED_ROOT} ;

   my $stack = $self->{STACK} ;
   croak "Can't emit characters outside of the root element"
      unless @$stack ;

   my XML::VWElement $end_elt = $stack->[-1];
   my $open_elt = $self->getDoctype->element_decl( $end_elt->{NAME} ) ;

   croak "Element '$open_elt->{NAME}' can't contain #PCDATA"
      unless ! $open_elt || $open_elt->can_contain_pcdata ;

   croak "Undefined value passed to characters() in <$open_elt->{NAME}>"
      if grep ! defined $_, @_ ;

   my $length ;
   my $decide_cdata = $self->{STRAGGLERS} eq '>' ;
   my $in_cdata_mode ;

   if ( $decide_cdata ) {
      my $escs = 0 ;
      my $cdata_ends = 0 ;
      my $cdata_escs = 0 ;
      my $pos ;

      ## I assume that splitting CDATA ends between chunks is very
      ## rare.  If an app does that a lot, then this could guess 'wrong'
      ## and use CDATA escapes in a situation where they result in more
      ## bytes out than <& escaping would.
      for ( @_ ) {
	 $escs += tr/<&// ;
	 $pos = 0 ;
	 ++$cdata_ends while ( $pos = index $_, ']]>', $pos + 3 ) >= 0 ;
	 $cdata_escs += tr/\x00-\x08\x0b\x0c\x0e-\x1f// ;
	 $length += length $_ ;
      }
      ## Each &lt; or &amp; is 4 or 5 chars.
      ## Each ]]]]><![CDATA[< is 15.
      ## Each ]]>&#xN;<![CDATA[ is 17 or 18.
      ## We ## add 12 since <![CDATA[]]> is 12 chars.
      $in_cdata_mode = 4.5*$escs > 15*$cdata_ends + 17.75*$cdata_escs + 12 ;
   }
   else {
      $in_cdata_mode = $self->{STRAGGLERS} eq ']]>' ;
      $length += length $_ for @_ ;
   }

   return unless $length ;

   ## I chose to stay in or out of CDATA mode for an element
   ## in order to keep document structure relatively simple...to keep human
   ## readers from getting confused between escaping modes.
   ## This may lead to degeneracy if it's an (SG|X)ML document being emitted in
   ## an element, so this may change.
   if ( $in_cdata_mode ) {
      if ( $self->{STRAGGLERS} eq ']]>' ) {
	 ## Don't emit ']]><![CDATA[' between consecutive CDATA character
	 ## chunks.
         $self->{STRAGGLERS} = '' ;
      }
      else {
	 $self->{STRAGGLERS} .= '<![CDATA['
      }
      if ( ref $to eq 'SCALAR' ) {
	 $$to = join( '',
	    $$to,
	    $self->{STRAGGLERS},
	    _esc_cdata_ends( $self->{CDATA_END_PART}, @_ )
	 ) ;

	 $self->{CDATA_END_PART} = 
	    $$to =~ s/(\]\]?)(?!\n)\Z//
	       ? $1
	       : '' ;

      }
      else {
	 no strict 'refs' ;

	 my $chunk = _esc_cdata_ends( $self->{CDATA_END_PART}, @_ ) ;
	 $self->{CDATA_END_PART} = 
	    $chunk =~ s/(\]\]?)(?!\n)\Z//
	       ? $1
	       : '' ;

	 print $to $self->{STRAGGLERS}, $chunk
	    or croak "$! writing chars in <$open_elt->{NAME}>" ;

      }

      $self->{STRAGGLERS} = ']]>' ;
   }
   else {
      if ( ref $to eq 'SCALAR' ) {
	 $$to .= $self->{STRAGGLERS} ;
	 $$to .= _esc1( join( '', @_ ) ) ;
      }
      else {
	 no strict 'refs' ;
	 print $to $self->{STRAGGLERS}, _esc( @_ )
	    or croak "$! writing chars in <$open_elt->{NAME}>" ;
      }
      $self->{STRAGGLERS} = '' ;
#      $self->{CDATA_END_PART} = '' ;
   }

   $stack->[-1]->add_content( '#PCDATA' )
      if @{$stack} ;

   $self->{WAS_END_TAG} = 0 ;

   return ;
}


=item dataElement

   $writer->dataElement( $tag ) ;
   $writer->dataElement( $tag, $content ) ;
   $writer->dataElement( $tag, $content, attr1 => $val1, ... ) ;
   dataElement( $tag ) ;
   dataElement( $tag, $content ) ;
   dataElement( $tag, $content, attr1 => $val1, ... ) ;

Does the equivalent to

   ## Split the optional args in to attributes and elements arrays.
   $writer->startTag( $tag, @attributes ) ;
   $writer->characters( $content ) ;
   $writer->endTag( $tag ) ;

This function is exportable as dataElement(), and is also exported
for each element 'foo' found in the DTD as foo().

=cut

sub dataElement {
   my XML::ValidWriter $self = shift ;

   my ( $tag ) = shift ;

   croak "Odd number of parameters passed to dataElement for <$tag>"
      if @_ && ! @_ & 1 ;

   ## We avoid copying content (attribute or element) more than we
   ## have to so as not to do more copies than necessary of
   ## potenially huge content.  We still do have to copy content to 
   ## pass it to characters(), though.
   $self->startTag( $tag, @_[1..$#_] ) ;
   my $is_empty = $self->{WAS_END_TAG} ;

   ## If ! defined we want to pass it in, so we get an error
   if ( @_ && ( ! defined $_[0] || length $_[0] ) ) {
      croak "Can't emit character data to EMPTY <$tag>"
         if $self->{WAS_END_TAG} ;
      $self->characters( $_[0] ) ;
   }


   $self->endTag( $tag ) unless $is_empty ;
   return ;
}


=item defaultWriter

   $writer = defaultWriter ;       ## Not a method!
   $writer = defaultWriter( 'Foo::Bar' ) ;

Returns the default XML::ValidWriter for the given package, or the current
package if none is specified.  This is useful for getting at
methods like C<reset> that are not also functions.

Croaks if no default writer has been defined (see L</import>).

=cut

sub defaultWriter(;$) {
   my $pkg = @_ ? shift : caller ;
   
   croak "No default XML::ValidWriter created for package '$pkg'"
      unless exists $pkg_writers{$pkg}
         &&         $pkg_writers{$pkg} ;
   
}


=item doctype

   # Using the writer's associated DTD:
   doctype ;

   # Ignoring the writer's associated DTD:
   doctype( $type ) ;
   doctype( $type, undef, $system ) ;
   doctype( $type, $public, $system ) ;

   $writer->doctype ;
   ...etc

See L</internalDoctype> to emit the entire DTD in the document.

This checks to make sure that no doctype or elements have been emitted.

A warning is emitted if standalone="yes" was specified in the <?xml..?>
declaration and a system id is specified.  This is extremely likely to
be an error.  If you need to silence the warning, write me (see below).

Passing '' or '0' (zero) as a $public_id or as a $system_id also generates
a warning, as these are extremely likely to be errors.

=cut

sub doctype {
   my XML::ValidWriter $self = &_self ;
   my ( $type, $public_id, $system_id ) = @_ ;

   croak "<!DOCTYPE ...> already emitted"
      if defined $self->{EMITTED_DOCTYPE} ;

   croak "<!DOCTYPE ...> can't be emitted after elements"
      if defined $self->{EMITTED_ROOT} ;

   croak "A PUBLIC_ID was specified, but no SYSTEM_ID"
      if $public_id && ! $system_id ;

   carp "'' passed for a PUBLIC_ID"
      if defined $public_id && ! $public_id ;

   carp "'' passed for a SYSTEM_ID"
      if defined $system_id && ! $system_id ;

   carp "SYSTEM_ID specified for a standalone document"
      if defined $system_id && $self->{IS_STANDALONE} ;

   $self->rawCharacters(
      "<!DOCTYPE ",
      $type,
      $public_id
         ? (
	    " PUBLIC ",
	    $public_id,
	    " ",
	    $system_id,
	 )
	 : $system_id
	    ? (
	       " SYSTEM ",
	       $system_id,
	    )
	    : () ,
      ">"
   ) ;

   $self->{EMITTED_DOCTYPE} = defined $type ? $type : "UNKNOWN" ;
}

=item emptyTag

   emptyTag( $tag[, attr1 => $val1... ] ) ;
   $writer->emptyTag( $tag[, attr1 => $val1... ] ) ;

Emits an empty tag like '<foo />'.  The extra space is for compatibility
with XHTML.

=cut

sub emptyTag {
   my XML::ValidWriter $self = shift ;

   ## Sneaky, sneaky...
   return $self->startTag( @_, '#EMPTY' ) ;
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
   my XML::ValidWriter $self = &_self ;

   $self->{CHECKED_XML_DECL} ||=
      ( carp( "No <?xml?> emitted." ), 1 ) ;

   my $stack = $self->{STACK} ;
   unless ( @$stack ) {
      my $tag = @_ ? shift : '' ;
      if ( $self->{EMITTED_ROOT} ) {
	 croak "Too many end tags emitted" .
	    ( $tag ? ", can't emit '$tag'" : '' ) ;
      }

      croak "Can't endTag(", $tag ? " '$tag' " : '',
      ") when no tags have been emitted" ;
   }

   my XML::VWElement $se = pop @$stack ;
   my $tag = @_ ? shift : $se->{NAME} ;
   croak "Unmatched </$tag>, open tags are: ",
      join( '', map "<$_->{NAME}>", @$stack, $se )
      if $tag ne $se->{NAME} ;

   unless ( $se->{ELT_DECL}->validate_content( $se->{CONTENT} ) ) {
      if ( @{$se->{CONTENT}} ) {
	 croak(
	    "Invalid content for <$tag>: " .
	    join( '', map "<$_>", @{$se->{CONTENT}} ) 
	 )
      }
      else {
         croak "Content required for <$tag>" ;
      }
   }

   my $prefix = '' ;
   if ( $self->{DATA_MODE} && $self->{WAS_END_TAG} ) {
      $prefix = " " x ( 3 * @$stack ) ;
   }

   if ( $self->{STRAGGLERS} eq '>' ) {
      ## Last thing emitted was a start tag.
      $self->{STRAGGLERS} = '' ;
      $self->rawCharacters(
         ' />',
         ! @{$stack} || $self->getDataMode ? "\n" : ()
      ) ;
   }
   else {
      $self->rawCharacters(
	 $prefix, '</', $tag, '>',
	 ! @{$stack} || $self->getDataMode ? "\n" : ()
      ) ;
   }

   $self->{WAS_END_TAG} = 1 ;
}


=item end

   $writer->end ;      # Not a function!!

Emits all necessary end tags to close the document.  Available as a method
only, since 'end' is a little to generic to be exported as a function
name, IMHO.  See 'endAllTags' for the plain function equivalent function.

=cut

sub end {
   # Well, I lied, you could call it as a function.
   my XML::ValidWriter $self = &_self ;

   $self->endTag() while @{$self->{STACK}} ;

   croak "No root element emitted"
      unless defined $self->{EMITTED_ROOT} ;
}


=item endAllTags

   endAllTags ;
   $writer->endAllTags ;

A plain function that emits all necessart end tags to close the document.
Corresponds to the method C<end>, but is exportable as a function/

=cut

{
   no strict 'refs' ;
   *{"endAllTags"} = \&end ;
}

=item exportDTDTags

   $writer->exportDTDTags() ;
   $writer->exportDTDTags( $to_pkg ) ;

Exports the tags found in the DTD to the caller's namespace.

=cut

sub exportDTDTags {
   my XML::ValidWriter $self = &_self ;

   my $pkg = ref $self ;
   my $callpkg = @_ ? shift : caller ;

   my $doctype = $self->{DOCTYPE} ;

   croak "No DOCTYPE specified to export tags from"
      unless $doctype ;

   ## Export tag() and end_tag(), tag_element(), and empty_tag() ;
   no strict 'refs' ;
   for my $tag ( $doctype->element_names ) {
      *{"$callpkg\::start_$tag"} = sub {
	 $pkg_writers{$callpkg}->startTag( $tag, @_ ) ;
      },

      *{"$callpkg\::end_$tag"} = sub {
	 $pkg_writers{$callpkg}->endTag( $tag, @_ ) ;
      },

      *{"$callpkg\::empty_$tag"} = sub {
	 $pkg_writers{$callpkg}->emptyTag( $tag, @_ ) ;
      },

      *{"$callpkg\::$tag"} = sub {
	 $pkg_writers{$callpkg}->dataElement( $tag, @_ ) ;
      },

   }

}



=item getDataMode

   $m = getDataMode ;
   $m = $writer->getDataMode ;

Returns TRUE if the writer is in DATA_MODE.

=cut

sub getDataMode {
   my XML::ValidWriter $self = shift ;

   return $self->{DATA_MODE} ;
}


=item getDoctype

   $dtd = getDoctype ;
   $dtd = $writer->getDoctype ;

This is used to get the writer's XML::Doctype object.

=cut

sub getDoctype {
   my XML::ValidWriter $self = &_self ;
   return $self->{DOCTYPE} ;
}

=item getOutput

   $fh = getOutput ;
   $fh = $writer->getOutput ;

Gets the filehandle an XML::ValidWriter sends output to.

=cut

sub getOutput {
   my XML::ValidWriter $self = &_self ;
   return $self->{OUTPUT} ;
}


=item rawCharacters

   rawCharacters( "<unescaped text>", "& more text" ) ;
   $writer->rawCharacters( "<unescaped text>", "& more text" ) ;

This allows you to emit raw text without any escape processing.  The text
is not examined for tags, so you can invalidate your document and even
corrupt it's well-formedness.

=cut

## This is called everywhere to emit raw characters *except* characters(),
## which must go direct because it uses STRAGGLERS and CDATA_END_PART
## differently.
sub rawCharacters {
   my XML::ValidWriter $self = &_self ;

   my $to= $self->{OUTPUT} || select ;

   return unless grep length $_, @_ ;

   if ( ref $to eq 'SCALAR' ) {
      $$to .= join(
         '',
         _esc_cdata_ends( $self->{CDATA_END_PART} ),
	 $self->{STRAGGLERS},
	 @_
      ) ;
      $self->{AT_BOL} = substr( $$to, -1, 1 ) eq "\n" ;
   }
   else {
      no strict 'refs' ;

      for ( my $i = $#_ ; $i >= 0 ; --$i ) {
         next unless length $_[$i] ;
	 $self->{AT_BOL} = substr( $_[$i], -1, 1 ) eq "\n" ;
	 last ;
      }

      print $to
         _esc_cdata_ends( $self->{CDATA_END_PART} ),
         $self->{STRAGGLERS},
	 @_ or croak $!;
   }
   $self->{CDATA_END_PART} = '' ;
   $self->{STRAGGLERS} = '' ;
}


=item reset

   $writer->reset ;        # Not a function!

Resets a writer to be initialized, but not have emitted anything.

This is useful if you need to abort output, but want to reuse the
XML::ValidWriter.

=cut

sub reset {
   my XML::ValidWriter $self = shift ;
   $self->{STACK} = [] ;

   # If we should warn, clear the flag that says we checked it & vice versa
   $self->{CHECKED_XML_DECL} = ! $self->{SHOULD_WARN} ;

   ## I'd use assignement to a slice here, but older perls...
   $self->{IS_STANDALONE}   = 0 ;
   $self->{EMITTED_DOCTYPE} = undef ;
   $self->{EMITTED_ROOT}    = undef ;
   $self->{EMITTED_XML}     = undef ;

   $self->{AT_BOL}          = 1 ;
   $self->{WAS_END_TAG}     = 1 ;
   $self->{STRAGGLERS}      = '' ;
   $self->{CDATA_END_PART} = '' ;

   if ( defined $self->{FILE_NAME} ) {
      if ( defined $self->{OUTPUT} ) {
	 close $self->{OUTPUT} or croak "$! closing '$self->{FILE_NAME}'." ;
      }
      else {
	 require Symbol ;
	 $self->{OUTPUT} = Symbol::gensym() ;
      }
      eval "use Fcntl ; 1" or croak $@ ;
      open(
	 $self->{OUTPUT},
	 ">$self->{FILE_NAME}",
      ) 
	  or croak "$!: $self->{FILE_NAME}" ;
   }

   return ;
}



=item setDataMode

   setDataMode( 1 ) ;
   $writer->setDataMode( 1 ) ;

Enable or disable data mode.

=cut

sub setDataMode {
   my XML::ValidWriter $self = &_self ;

   $self->{DATA_MODE} = shift ;
   return ;
}



=item setDoctype

   setDoctype $doctype ;
   $writer->setDoctype( $doctype ) ;

This is used to set the doctype object.

=cut

sub setDoctype {
   my XML::ValidWriter $self = &_self ;
   $self->{DOCTYPE} = shift if @_ ;
   return ;
}

=item select_xml

   select_xml OUTHANDLE ;  # Nnot a method!!

Selects a filehandle to send the XML output to when not using the object
oriented interface.  This is similar to perl's builtin select,
but only affects startTag and endTag functions, (not methods).

This is only needed if you want to interleave output to the selected 
output files (usually STDOUT, see L<perlfunc/select> and to an
XML file on another filehandle.

If you want to redirect all output (yours and XML::Writer's) to the same
file, just use Perl's built-in select(), since startTag and endTag
emit to the currently selected filehandle by default.

Like select, this returns the old value.

=cut

sub select_xml(;*) {
   ## I cheat a little and this could be used as a method
   my XML::ValidWriter $self = &_self ;

   my $r = $self->getOutput ;
   $self->setOutput( shift ) if @_ ;
   return $r ;
}

=item setOutput

   setOutput( \*FH ) ;
   $writer->setOutput( \*FH ) ;

Sets the filehandle an XML::ValidWriter sends output to.

=cut

sub setOutput {
   my XML::ValidWriter $self = &_self ;
   $self->{OUTPUT} = shift if @_ ;
   return ;
}


=item startTag

   startTag( 'a', attr => val ) ;  # use default XML::ValidWriter for
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
   my XML::ValidWriter $self = &_self ;
   my $tag = shift ;
   croak "Must supply a tag name" unless defined $tag ;

   $self->{CHECKED_XML_DECL} ||=
      ( carp( "No <?xml?> emitted." ), 1 ) ;

   if ( ! @{$self->{STACK}} ) {
      if ( defined $self->{EMITTED_ROOT} ) {
	 croak
	    "Root element '$self->{EMITTED_ROOT}' ended, can't emit '$tag'"
      }
      else {
         if ( $tag ne $self->{DOCTYPE}->name ) {
	    croak
	       "Root element '$tag' does not match DOCTYPE '",
	       $self->getDTD->name,
	       "'"
	 }
      }
      $self->{EMITTED_ROOT} = $tag ;
   }

   my $elt_decl = $self->{DOCTYPE}->element_decl( $tag ) ;

   my @attrs ;
   my %attrs ;
   ## emptyTag sneaks an '#EMPTY' on the parms and calls us.
   my $is_empty = @_ && $_[-1] eq '#EMPTY'
      ? pop
      : $elt_decl->is_empty ;

   croak "Odd number of parameters passed to startTag( '$tag' ): ",
      scalar( @_ )
      if @_ & 1 ;

   while ( @_ ) {
      my ( $attr, $val ) = ( shift, shift ) ;

      croak "Undefined attribute name for <$tag>" 
         unless defined $attr ;

      croak "Undefined attribute value for <$tag>, attribute '$attr'" 
         unless defined $val ;

      croak "Attribute '$attr' already emitted"
         if $attrs{$attr} ;

      $attrs{$attr} = $val ;

      push @attrs, ( ' ', $attr, '="', _attr_esc1( $val ), '"' )  ;
   }

   if ( $elt_decl ) {
      for my $attdef ( $elt_decl->attdefs ) {
	 my $name  = $attdef->name ;
	 my $quant = $attdef->quant ;

	 push @attrs, (
	    ' ',
	    $name,
	    '="',
	    $attrs{$name} = _attr_esc1( $attdef->default_on_write ),
	    '"'
	 )
	    if ! exists $attrs{$name} && defined $attdef->default_on_write ;

	 if ( $quant eq '#FIXED' ) {
	    if ( exists $attrs{$name} ) {
		croak "Attribute '$name' is #FIXED to '" .  $attdef->default
		   . "' and cannot be emitted as '" .  $attrs{$name} . "'"
		   if $attdef->default ne $attrs{$name}
	    }
	    else {
	       ## Output #FIXED attributes if they weren't passed
	       push @attrs, ( ' ', $name, '="', _attr_esc1( $attdef->default ), '"' )  ;
	    }
	 }
	 elsif ( $quant eq '#REQUIRED' ) {
	    croak "Tag '$tag', attribute '$name' #REQUIRED, but not provided"
	       unless exists $attrs{$name} && defined $attrs{$name} ;
	 }
      }
   }

   ## TODO: A quick check to see if $tag can be it's parent's child.
   ## TODO: Incremental data model checking.
   my $stack = $self->{STACK} ;

   my $prefix = '' ;
   if ( $self->{DATA_MODE} ) {
      $prefix = ( $self->{AT_BOL} ? "" : "\n" ) . " " x ( 3 * @$stack ) ;
   }

   if ( $is_empty ) {
      $self->rawCharacters(
         $prefix, '<', $tag, @attrs, ' />',
         ! @$stack || $self->getDataMode ? "\n" : ()
      ) ;
   }
   else {
      $self->rawCharacters( $prefix, '<', $tag, @attrs ) ;
      $self->{STRAGGLERS} = '>' ;
   }

   $stack->[-1]->add_content( $tag )
      if @{$stack} ;
   push @$stack, XML::VWElement->new( $elt_decl )
      unless $is_empty ;

   $self->{WAS_END_TAG} = $is_empty ;

   return ;
}


=item xmlDecl([[$encoding][, $standalone])

   xmlDecl ;
   xmlDecl( "UTF-8" ) ;
   xmlDecl( "UTF-8", "yes" ) ;
   $writer->xmlDecl( ... ) ;

Emits an XML declaration.  Must be called before any of the other
output routines.

If $encoding is not defined, it is not output.  This is slightly
different than XML::Writer, which outputs 'UTF-8' if you pass in
undef, 0, or ''.

If $encoding is '' or 0, then it is output as "" or "0"
and a warning is generated.

If $standalone is defined and is not 'no', 0, or '', it is output as 'yes'.
If it is 'no', then it is output as 'no'.  If it's 0 or '' it is not
output.

=cut

sub xmlDecl {
   my XML::ValidWriter $self = &_self ;

   croak "<?xml?> already emitted"
      if defined $self->{EMITTED_XML} ;

   croak "<?xml?> not the first thing in the document"
      if defined $self->{EMITTED_DOCTYPE} || defined $self->{EMITTED_ROOT} ;

   my ( $encoding, $standalone ) = @_ ;

   if ( defined $encoding ) {
      carp "encoding '$encoding' passed"
         if ! $encoding ;
   }

   $standalone = 'yes' if $standalone && $standalone ne 'no' ;

   $self->rawCharacters(
      '<?xml version="1.0"',
      defined $encoding
         ? qq{ encoding="$encoding"}
	 : (),
      $standalone
         ? qq{ standalone="$standalone"}
	 : (),
      "?>\n"
   ) ;

   $self->{CHECKED_XML_DECL} = 1 ;
   $self->{IS_STANDALONE} = $standalone && $standalone eq 'yes' ;
   # declare open season on tag emission
   $self->{EMITTED_XML} = 1 ;
}

=item AUTOLOAD

This function is called whenever a function or method is not found
in XML::ValidWriter.

If it was a method being called, and the desired method name is a start
or end tag found in the DTD, then a method is cooked up on the fly.

These methods are slower than normal methods, but they are cached so
that they don't need to be recompiled.  The speed penalty is probably
not significant since they do I/O and are thus usually orders of
magnitude slower than normal Perl methods.

=cut

## TODO: Perhaps change exportDTDTags to use AUTOLOAD
## TODO: Allow caching of methods in package namespace as an option so
## that specializations of XML::ValidWriter can avoid the AUTOLOAD speed
## hit.

use vars qw( $AUTOLOAD ) ;

sub AUTOLOAD {
   croak "Function $AUTOLOAD not AUTOLOADable (no functions are)"
      unless isa( $_[0], __PACKAGE__ ) ;

   my XML::ValidWriter $self = $_[0] ;
   unless ( exists $self->{METHODS}->{$AUTOLOAD} ) {
      my ( $class, $ss, $method ) =
	 $AUTOLOAD =~ /^(.*)::((?:start_|end_|empty_)?)(.*?)$/ ;
      croak "Can't parse method name '$AUTOLOAD'" unless defined $class ;

      croak "Method $AUTOLOAD does not refer to an element in the XML::Doctype"
	 unless $self->{DOCTYPE}->element_decl( $method ) ;

      my $sub = $ss eq ''
	    ? sub {
	       my XML::ValidWriter $self = shift ;
	       $self->dataElement( $method, @_ ) ;
	    }
	 : $ss eq 'start_'
	    ? sub {
	       my XML::ValidWriter $self = shift ;
	       $self->startTag( $method, @_ ) ;
	    }
	 : $ss eq 'end_'
	    ? sub {
	       my XML::ValidWriter $self = shift ;
	       $self->endTag( $method, @_ ) ;
	    }
	 : sub {
	       my XML::ValidWriter $self = shift ;
	       $self->emptyTag( $method, @_ ) ;
	    }
	 ;

      $self->{METHODS}->{$AUTOLOAD} = $sub ;
   }
      
   goto &{$self->{METHODS}->{$AUTOLOAD}}
}

=item DESTROY

DESTROY is called when an XML::ValidWriter is cleaned up.  This is used
to automatically close all tags that remain open.  This will not work
if you have closed the output filehandle that the ValidWriter was
using.

This method will also warn if anything was emitted bit no root node was
emitted.  This warning can be silenced by calling

   $writer->reset() ;

when you abandon output.

=cut

##TODO: Prevent $self->end for errored objects.
##TODO: Prevent further output to errored objects if they cannot ever
## be valid.  Perhaps prevent it to all errored objects?

sub DESTROY {
   my XML::ValidWriter $self = shift ;

#   if ( @{$self->{STACK}} ) {
#      $self->end() ;
#   }

   if ( defined $self->{FILE_NAME} ) {
      close $self->{OUTPUT} or croak "$! closing '$self->{FILE_NAME}'." ;
   }

   if ( ! defined $self->{EMITTED_ROOT}
      && (  defined $self->{EMITTED_XML}
	 || defined $self->{EMITTED_DOCTYPE}
      )
   ) {
      ## TODO: Identify a document name here
      carp "No content emitted after preamble in ",
         ref $self,
	 " created at ",
	 $self->{CREATED_AT} ;
      ;
   }
}


=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

This module is Copyright 2000, 2005 Barrie Slaymaker.  All rights reserved.

This module is licensed under your choice of the Artistic, BSD or
General Public License.

=cut

1 ;
