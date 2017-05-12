##############################################################################
#
# Perl module: XML::XSLT
#
# By Geert Josten, gjosten@sci.kun.nl
# and Egon Willighagen, egonw@sci.kun.nl
#
#    $Log: XSLT.pm,v $
#    Revision 1.25  2004/02/19 08:38:40  gellyfish
#    * Fixed overlapping attribute-sets
#    * Allow multiple nodes for processing-instruction() etc
#    * Added test for for-each
#
#    Revision 1.24  2004/02/18 08:34:38  gellyfish
#    * Fixed select on "comment()" "processing-instruction()" etc
#    * Added test for select
#
#    Revision 1.23  2004/02/17 10:06:12  gellyfish
#    * Added test for xsl:copy
#
#    Revision 1.22  2004/02/17 08:52:29  gellyfish
#    * 'use-attribute-sets' works in xsl:copy and recursively
#
#    Revision 1.21  2004/02/16 10:29:20  gellyfish
#    * Fixed variable implementation to handle non literals
#    * refactored test implementation
#    * added tests
#
#    Revision 1.20  2003/06/24 16:34:51  gellyfish
#    * Allowed both name and match attributes in templates
#    * Lost redefinition warning with perl 5.8
#
#    Revision 1.19  2002/02/18 09:05:14  gellyfish
#    Refactoring
#
#    Revision 1.18  2002/01/16 21:05:27  gellyfish
#    * Added the manpage as an example
#    * Started to properly implement omit-xml-declaration
#
#    Revision 1.17  2002/01/13 10:35:00  gellyfish
#    Updated pod
#
#    Revision 1.16  2002/01/09 09:17:40  gellyfish
#    * added test for <xsl:text>
#    * Stylesheet whitespace stripping as per spec and altered tests ...
#
#    Revision 1.15  2002/01/08 10:11:47  gellyfish
#    * First cut at cdata-section-element
#    * test for above
#
#    Revision 1.14  2001/12/24 16:00:19  gellyfish
#    * Version released to CPAN
#
#    Revision 1.13  2001/12/20 09:21:42  gellyfish
#    More refactoring
#
#    Revision 1.12  2001/12/19 21:06:31  gellyfish
#    * Some refactoring and style changes
#
#    Revision 1.11  2001/12/19 09:11:14  gellyfish
#    * Added more accessors for object attributes
#    * Fixed potentially broken usage of $variables in _evaluate_template
#
#    Revision 1.10  2001/12/18 09:10:10  gellyfish
#    Implemented attribute-sets
#
#    Revision 1.9  2001/12/17 22:32:12  gellyfish
#    * Added Test::More to Makefile.PL
#    * Added _indent and _outdent methods
#    * Placed __get_attribute_sets in transform()
#
#    Revision 1.8  2001/12/17 11:32:08  gellyfish
#    * Rolled in various patches
#    * Added new tests
#
#
###############################################################################

=head1 NAME

XML::XSLT - A perl module for processing XSLT

=cut

######################################################################
package XML::XSLT;
######################################################################

use strict;

use XML::DOM 1.25;
use LWP::Simple qw(get);
use URI;
use Cwd;
use File::Basename qw(dirname);
use Carp;

# Namespace constants

use constant NS_XSLT  => 'http://www.w3.org/1999/XSL/Transform';
use constant NS_XHTML => 'http://www.w3.org/TR/xhtml1/strict';

use vars qw ( $VERSION @ISA @EXPORT_OK $AUTOLOAD );

$VERSION = '0.48';

@ISA       = qw( Exporter );
@EXPORT_OK = qw( &transform &serve );

my %deprecation_used;

######################################################################
# PUBLIC DEFINITIONS

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    my %args  = $self->__parse_args(@_);

    $self->{DEBUG}       = defined $args{debug} ? $args{debug} : "";
	 no strict 'subs';

	 if ( $self->{DEBUG} )
    {	
	    *__PACKAGE__::debug = \&debug;
	 }
	 else
	 {
		*__PACKAGE__::debug = sub {};
	 }

	 use strict 'subs';

    $self->{INDENT}      = defined $args{indent}      ? $args{indent}      : 0;
    $self->{PARSER}      = XML::DOM::Parser->new();
    $self->{PARSER_ARGS} =
      defined $args{DOMparser_args} ? $args{DOMparser_args} : {};
    $self->{VARIABLES}   = defined $args{variables}   ? $args{variables}   : {};
	 $self->debug(join ' ', keys %{$self->{VARIABLES}});
    $self->{WARNINGS}    = defined $args{warnings}    ? $args{warnings}    : 0;
    $self->{INDENT_INCR} = defined $args{indent_incr} ? $args{indent_incr} : 1;
    $self->{XSL_BASE}    =
      defined $args{base} ? $args{base} : 'file://' . cwd . '/';
    $self->{XML_BASE} =
      defined $args{base} ? $args{base} : 'file://' . cwd . '/';

    $self->use_deprecated( $args{use_deprecated} )
      if exists $args{use_deprecated};

    $self->debug("creating parser object:");

    $self->_indent();
    $self->open_xsl(%args);
    $self->_outdent();

    return $self;
}

sub use_deprecated
{
    my ( $self, $use_deprecated ) = @_;

    if ( defined $use_deprecated )
    {
        $self->{USE_DEPRECATED} = $use_deprecated;
    }

    return $self->{USE_DEPRECATED} || 0;
}

sub DESTROY { }    # Cuts out random dies on includes

sub default_xml_version
{
    my ( $self, $xml_version ) = @_;

    if ( defined $xml_version )
    {
        $self->{DEFAULT_XML_VERSION} = $xml_version;
    }

    return $self->{DEFAULT_XML_VERSION} ||= '1.0';
}

sub serve
{
    my $self  = shift;
    my $class = ref $self || croak "Not a method call";
    my %args  = $self->__parse_args(@_);
    my $ret;

    $args{http_headers}    = 1 unless defined $args{http_headers};
    $args{xml_declaration} = 1 unless defined $args{xml_declaration};
    $args{xml_version} = $self->default_xml_version()
      unless defined $args{xml_version};
    $args{doctype} = 'SYSTEM' unless defined $args{doctype};
    $args{clean}   = 0        unless defined $args{clean};

    $ret = $self->transform( $args{Source} )->toString;

    if ( $args{clean} )
    {
        eval { require HTML::Clean };

        if ($@)
        {
            CORE::warn("Not passing through HTML::Clean -- install the module");
        }
        else
        {
            my $hold = HTML::Clean->new( \$ret );
            $hold->strip;
            $ret = ${ $hold->data };
        }
    }

    if ( my $doctype = $self->doctype() )
    {
        $ret = $doctype . "\n" . $ret;
    }

    if ( $args{xml_declaration} )
    {
        $ret = $self->xml_declaration() . "\n" . $ret;
    }

    if ( $args{http_headers} )
    {
        $ret =
            "Content-Type: "
          . $self->media_type() . "\n"
          . "Content-Length: "
          . length($ret) . "\n\n"
          . $ret;
    }

    return $ret;
}

sub xml_declaration
{
    my ( $self, $xml_version, $output_encoding ) = @_;

    $xml_version     ||= $self->default_xml_version();
    $output_encoding ||= $self->output_encoding();

    return qq{<?xml version="$xml_version" encoding="$output_encoding"?>};
}

sub output_encoding
{
    my ( $self, $encoding ) = @_;

    if ( defined $encoding )
    {
        $self->{OUTPUT_ENCODING} = $encoding;
    }

    return exists $self->{OUTPUT_ENCODING} ? $self->{OUTPUT_ENCODING} : 'UTF-8';
}

sub doctype_system
{
    my ( $self, $doctype ) = @_;

    if ( defined $doctype )
    {
        $self->{DOCTYPE_SYSTEM} = $doctype;
    }

    return $self->{DOCTYPE_SYSTEM};
}

sub doctype_public
{
    my ( $self, $doctype ) = @_;

    if ( defined $doctype )
    {
        $self->{DOCTYPE_PUBLIC} = $doctype;
    }

    return $self->{DOCTYPE_PUBLIC};
}

sub result_document()
{
    my ( $self, $document ) = @_;

    if ( defined $document )
    {
        $self->{RESULT_DOCUMENT} = $document;
    }

    return $self->{RESULT_DOCUMENT};
}

sub debug
{
    my $self = shift;
    my $arg  = shift || "";

	 if ($self->{DEBUG} and $self->{DEBUG} > 1 )
	 {
        $arg  = (caller(1))[3] . ": $arg";
	 }

    print STDERR " " x $self->{INDENT}, "$arg\n"
      if $self->{DEBUG};
}

sub warn
{
    my $self = shift;
    my $arg  = shift || "";

    print STDERR " " x $self->{INDENT}, "$arg\n"
      if $self->{DEBUG};
    print STDERR "$arg\n"
      if $self->{WARNINGS} && !$self->{DEBUG};
}

sub open_xml
{
    my $self  = shift;
    my $class = ref $self || croak "Not a method call";
    my %args  = $self->__parse_args(@_);

    if ( defined $self->xml_document() && not $self->{XML_PASSED_AS_DOM} )
    {
        $self->debug("flushing old XML::DOM::Document object...");
        $self->xml_document()->dispose;
    }

    $self->{XML_PASSED_AS_DOM} = 1
      if ref $args{Source} eq 'XML::DOM::Document';

    if ( defined $self->result_document() )
    {
        $self->debug("flushing result...");
        $self->result_document()->dispose();
    }

    $self->debug("opening xml...");

    $args{parser_args} ||= {};

    my $xml_document = $self->__open_document(
        Source      => $args{Source},
        base        => $self->{XML_BASE},
        parser_args => { %{ $self->{PARSER_ARGS} }, %{ $args{parser_args} } },
    );

    $self->xml_document($xml_document);

    $self->{XML_BASE} =
      dirname( URI->new_abs( $args{Source}, $self->{XML_BASE} )->as_string )
      . '/';
    $self->result_document( $self->xml_document()->createDocumentFragment );
}

sub xml_document
{
    my ( $self, $xml_document ) = @_;

    if ( defined $xml_document )
    {
        $self->{XML_DOCUMENT} = $xml_document;
    }

    return $self->{XML_DOCUMENT};
}

sub open_xsl
{
    my $self  = shift;
    my $class = ref $self || croak "Not a method call";
    my %args  = $self->__parse_args(@_);

    $self->xsl_document()->dispose
      if not $self->{XSL_PASSED_AS_DOM}
      and defined $self->xsl_document();

    $self->{XSL_PASSED_AS_DOM} = 1
      if ref $args{Source} eq 'XML::DOM::Document';

    # open new document  # open new document
    $self->debug("opening xsl...");

    $args{parser_args} ||= {};

    my $xsl_document = $self->__open_document(
        Source      => $args{Source},
        base        => $self->{XSL_BASE},
        parser_args => { %{ $self->{PARSER_ARGS} }, %{ $args{parser_args} } },
    );

    $self->xsl_document($xsl_document);

    $self->{XSL_BASE} =
      dirname( URI->new_abs( $args{Source}, $self->{XSL_BASE} )->as_string )
      . '/';

    $self->__preprocess_stylesheet;
}

sub xsl_document
{
    my ( $self, $xsl_document ) = @_;

    if ( defined $xsl_document )
    {
        $self->{XSL_DOCUMENT} = $xsl_document;
    }

    return $self->{XSL_DOCUMENT};
}

# Argument parsing with backwards compatibility.
sub __parse_args
{
    my $self = shift;
    my %args;

    if ( @_ % 2 )
    {
        $args{Source} = shift;
        %args = ( %args, @_ );
    }
    else
    {
        %args = @_;
        if ( not exists $args{Source} )
        {
            my $name = [ caller(1) ]->[3];
            carp
"Argument syntax of call to $name deprecated.  See the documentation for $name"
              unless $self->use_deprecated($args{use_deprecated})
              or exists $deprecation_used{$name};
            $deprecation_used{$name} = 1;
            %args                    = ();
            $args{Source}            = shift;
            shift;
            %args = ( %args, @_ );
        }
    }

    return %args;
}

# private auxiliary function #
sub __my_tag_compression
{
    my ( $tag, $elem ) = @_;

=begin internal_docs

__my_tag_compression__( $tag, $elem )

A function for DOM::XML::setTagCompression to determine the style for printing 
of empty tags and empty container tags.

XML::XSLT implements an XHTML-friendly style.

Allow tag to be preceded by a namespace: ([\w\.]+\:){0,1}

  <br> -> <br />

  or

  <myns:hr> -> <myns:hr />

Empty tag list obtained from:

  http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd

According to "Appendix C. HTML Compatibility Guidelines",
  C.3 Element Minimization and Empty Element Content

  Given an empty instance of an element whose content model is not EMPTY
  (for example, an empty title or paragraph) do not use the minimized form
  (e.g. use <p> </p> and not <p />).

However, the <p> tag is processed like an empty tag here!

Tags allowed:

  base meta link hr br param img area input col

Special Case: p (even though it violates C.3)

The tags are matched in order of expected common occurence.

=end internal_docs

=cut

    $tag = [ split ':', $tag ]->[1] if index( $tag, ':' ) >= 0;
    return 2 if $tag =~ m/^(p|br|img|hr|input|meta|base|link|param|area|col)$/i;

    # Print other empty tags like this: <empty></empty>
    return 1;
}

# private auxiliary function #
sub __preprocess_stylesheet
{
    my $self = $_[0];

    $self->debug("preprocessing stylesheet...");

    $self->__get_first_element;
    $self->__extract_namespaces;
    $self->__get_stylesheet;

   # Why is this here when __get_first_element does, apparently, the same thing?
   # Because, in __get_stylesheet we warp the document.
    $self->top_xsl_node( $self->xsl_document()->getFirstChild );
    $self->__expand_xsl_includes;
    $self->__extract_top_level_variables;

    $self->__add_default_templates;
    $self->__cache_templates;    # speed optim

    $self->__set_xsl_output;
}

sub top_xsl_node
{
    my ( $self, $top_xsl_node ) = @_;

    if ( defined $top_xsl_node )
    {
        $self->{TOP_XSL_NODE} = $top_xsl_node;
    }

    return $self->{TOP_XSL_NODE};
}

# private auxiliary function #

sub __get_stylesheet
{
    my $self = shift;
    my $stylesheet;
    my $xsl_ns = $self->xsl_ns();
    my $xsl    = $self->xsl_document();

    foreach my $child ( $xsl->getElementsByTagName( '*', 0 ) )
    {
        my ( $ns, $tag ) = split( ':', $child->getTagName() );
        if ( not defined $tag )
        {
            $tag = $ns;
            $ns  = $self->default_ns();
        }
        if ( $tag eq 'stylesheet' || $tag eq 'transform' )
        {
            if ( my $attributes = $child->getAttributes() )
            {
                my $version = $attributes->getNamedItem('version');

                $self->xslt_version( $version->getNodeValue() ) if $version;
            }

            $stylesheet = $child;
            last;
        }
    }

    if ( !$stylesheet )
    {

        # stylesheet is actually one complete template!
        # put it in a template-element

        $stylesheet = $xsl->createElement("${xsl_ns}stylesheet");
        my $template = $xsl->createElement("${xsl_ns}template");
        $template->setAttribute( 'match', "/" );

        my $template_content = $xsl->getElementsByTagName( '*', 0 )->item(0);
        $xsl->replaceChild( $stylesheet, $template_content );
        $stylesheet->appendChild($template);
        $template->appendChild($template_content);
    }

    $self->xsl_document($stylesheet);
}

sub xslt_version
{
    my ( $self, $xslt_version ) = @_;

    if ( defined $xslt_version )
    {
        $self->{XSLT_VERSION} = $xslt_version;
    }

    return $self->{XSLT_VERSION} ||= '1.0';
}

# private auxiliary function #
sub __get_first_element
{
    my ($self) = @_;
    my $node = $self->xsl_document()->getFirstChild();

    $node = $node->getNextSibling until ref $node eq 'XML::DOM::Element';
    $self->top_xsl_node($node);
}

# private auxiliary function #
sub __extract_namespaces
{
    my ($self) = @_;

    my $attr = $self->top_xsl_node()->getAttributes;
    if ( defined $attr )
    {
        foreach
          my $attribute ( $self->top_xsl_node()->getAttributes->getValues )
        {
            my ( $pre, $post ) = split( ":", $attribute->getName, 2 );
            my $value = $attribute->getValue;

            # Take care of namespaces
            if ( $pre eq 'xmlns' and not defined $post )
            {
                $self->default_ns('');

                $self->{NAMESPACE}->{ $self->default_ns() }->{namespace} =
                  $value;
                $self->xsl_ns('')
                  if $value eq NS_XSLT;
                $self->debug(
                    "Namespace `" . $self->default_ns() . "' = `$value'" );
            }
            elsif ( $pre eq 'xmlns' )
            {
                $self->{NAMESPACE}->{$post}->{namespace} = $value;
                $self->xsl_ns("$post:")
                  if $value eq NS_XSLT;
                $self->debug("Namespace `$post:' = `$value'");
            }
            else
            {
                $self->default_ns('');
            }

            # Take care of versions
            if ( $pre eq "version" and not defined $post )
            {
                $self->{NAMESPACE}->{ $self->default_ns() }->{version} = $value;
                $self->debug( "Version for namespace `"
                      . $self->default_ns()
                      . "' = `$value'" );
            }
            elsif ( $pre eq "version" )
            {
                $self->{NAMESPACE}->{$post}->{version} = $value;
                $self->debug("Version for namespace `$post:' = `$value'");
            }
        }
    }
    if ( not defined $self->default_ns() )
    {
        my ($dns) = split( ':', $self->top_xsl_node()->getTagName );
        $self->default_ns($dns);
    }
    $self->debug( "Default Namespace: `" . $self->default_ns() . "'" );
    $self->xsl_ns( $self->default_ns() ) unless $self->xsl_ns();

    $self->debug( "XSL Namespace: `" . $self->xsl_ns() . "'" );

    # ** FIXME: is this right?
    $self->{NAMESPACE}->{ $self->default_ns() }->{namespace} ||= NS_XHTML;
}

sub default_ns
{
    my ( $self, $default_ns ) = @_;

    if ( defined $default_ns )
    {
        $self->{DEFAULT_NS} = $default_ns;
    }
    return exists $self->{DEFAULT_NS} ? $self->{DEFAULT_NS} : undef;
}

sub xsl_ns
{
    my ( $self, $prefix ) = @_;

    if ( defined $prefix )
    {
        $prefix .= ':' unless $prefix =~ /:$/;
        $self->{XSL_NS} = $prefix;
    }
    return $self->{XSL_NS};
}

# private auxiliary function #
sub __expand_xsl_includes
{
    my $self = shift;

    foreach my $include_node ( $self->top_xsl_node()
        ->getElementsByTagName( $self->xsl_ns() . "include" ) )
    {
        my $include_file = $include_node->getAttribute('href');

        die "include tag carries no selection!"
          unless defined $include_file;

        my $include_doc;
        eval {
            my $tmp_doc =
              $self->__open_by_filename( $include_file, $self->{XSL_BASE} );
            $include_doc = $tmp_doc->getFirstChild->cloneNode(1);
            $tmp_doc->dispose;
        };
        die "parsing of $include_file failed: $@"
          if $@;

        $self->debug("inserting `$include_file'");
        $include_doc->setOwnerDocument( $self->xsl_document() );
        $self->top_xsl_node()->replaceChild( $include_doc, $include_node );
        $include_doc->dispose;
    }
}

# private auxiliary function #
sub __extract_top_level_variables
{
    my $self = $_[0];

    $self->debug("Extracting variables");
    foreach my $child ( $self->xsl_document()->getChildNodes() )
    {
		  next unless $child->getNodeType() == ELEMENT_NODE;
		  my $name = $child->getNodeName();
        my ( $ns, $tag ) = split( ':', $name );

		  $self->debug("$ns $tag");
        if ( 1 ) 
					 
#					 ( $tag eq '' && $self->xsl_ns() eq '' )
#            || $self->xsl_ns() eq $ns )
        {
            $tag = $ns if $tag eq '';

				$self->debug($tag);
            if ( $tag eq 'variable' || $tag eq 'param' )
            {

                my $name = $child->getAttribute("name");
                if ($name)
                {
						  $self->debug("got $tag called $name");
                    my $value = $child->getAttributeNode("select");
                    if ( !defined $value )
                    {
								if ( $child->getChildNodes()->getLength() )
								{
                           my $result =
                              $self->xml_document()->createDocumentFragment;
                           $self->_evaluate_template( $child,
                                                      $self->xml_document(), 
																		'', 
																		$result );
                           $value = $self->_string($result);
                           $result->dispose();
								}
                    }
                    else
                    {
							   $value = $value->getValue();
                        if ( $value =~ /'(.*)'/ )
                        {
                            $value = $1;
                        }
                    }
						  unless ( !defined $value ) 
						  {
                       $self->debug("Setting $tag `$name' = `$value'");
                       $self->{VARIABLES}->{$name} = $value;
						  }
                }
                else
                {

                    # Required, so we die (http://www.w3.org/TR/xslt#variables)
                    die "$tag tag carries no name!";
                }
            }
        }
    }
}

# private auxiliary function #
sub __add_default_templates
{
    my $self = $_[0];
    my $doc  = $self->top_xsl_node()->getOwnerDocument;

    # create template for '*' and '/'
    my $elem_template = $doc->createElement( $self->xsl_ns() . "template" );
    $elem_template->setAttribute( 'match', '*|/' );

    # <xsl:apply-templates />
    $elem_template->appendChild(
        $doc->createElement( $self->xsl_ns() . "apply-templates" ) );

    # create template for 'text()' and '@*'
    my $attr_template = $doc->createElement( $self->xsl_ns() . "template" );
    $attr_template->setAttribute( 'match', 'text()|@*' );

    # <xsl:value-of select="." />
    $attr_template->appendChild(
        $doc->createElement( $self->xsl_ns() . "value-of" ) );
    $attr_template->getFirstChild->setAttribute( 'select', '.' );

    # create template for 'processing-instruction()' and 'comment()'
    my $pi_template = $doc->createElement( $self->xsl_ns() . "template" );
    $pi_template->setAttribute( 'match', 'processing-instruction()|comment()' );

    $self->debug("adding default templates to stylesheet");

    # add them to the stylesheet
    $self->xsl_document()->insertBefore( $pi_template, $self->top_xsl_node );
    $self->xsl_document()
      ->insertBefore( $attr_template, $self->top_xsl_node() );
    $self->xsl_document()
      ->insertBefore( $elem_template, $self->top_xsl_node() );
}

sub templates
{
    my ( $self, $templates ) = @_;

    if ( defined $templates )
    {
        $self->{TEMPLATE} = $templates;
    }

    unless ( exists $self->{TEMPLATE} )
    {
        $self->{TEMPLATE} = [];
        my $xsld = $self->xsl_document();
        my $tag  = $self->xsl_ns() . 'template';

        @{ $self->{TEMPLATE} } = $xsld->getElementsByTagName($tag);
    }

    return wantarray ? @{ $self->{TEMPLATE} } : $self->{TEMPLATE};
}

# private auxiliary function #
sub __cache_templates
{
    my $self = $_[0];

    # pre-cache template names and matches #
    # reversing the template order is much more efficient #

    foreach my $template ( reverse $self->templates() )
    {
        if ( $template->getParentNode->getTagName =~
            /^([\w\.\-]+\:){0,1}(stylesheet|transform|include)/ )
        {
            my $match = $template->getAttribute('match') || '';
            my $name  = $template->getAttribute('name')  || '';
            push( @{ $self->{TEMPLATE_MATCH} }, $match );
            push( @{ $self->{TEMPLATE_NAME} },  $name );
        }
    }
}

=item xsl_output_method

Get or set the <xsl:output method= attribute.  Valid arguments are 'html',
'text' and 'xml'

=cut

sub xsl_output_method
{
    my ( $self, $method) = @_;

	 if (defined $method and $method =~ /(?:html|text|xml)/ )
	 {
	    $self->{METHOD} = $method;
	 }

	 return exists $self->{METHOD} ? $self->{METHOD} : 'xml';
}

# private auxiliary function #
sub __set_xsl_output
{
    my $self = $_[0];

    # default settings
    $self->media_type('text/xml');

    # extraction of top-level xsl:output tag
    my ($output) =
      $self->xsl_document()
      ->getElementsByTagName( $self->xsl_ns() . "output", 0 );

    if ( defined $output )
    {

        # extraction and processing of the attributes
        my $attribs = $output->getAttributes;
        my $media   = $attribs->getNamedItem('media-type');
        my $method  = $attribs->getNamedItem('method');
        $self->media_type( $media->getNodeValue ) if defined $media;
        $self->xsl_output_method($method->getNodeValue) if defined $method;

        if ( my $omit = $attribs->getNamedItem('omit-xml-declaration') )
        {
            if ( $omit->getNodeValue() =~ /^(yes|no)$/ )
            {
                $self->omit_xml_declaration($1);
            }
            else
            {

                # I would say that this should be fatal
                # Perhaps there should be a 'strict' option to the constructor

                my $m =
                    qq{Wrong value for attribute "omit-xml-declaration" in\n\t}
                  . $self->xsl_ns()
                  . qq{output, should be "yes" or "no"};
                $self->warn($m);
            }
        }

        unless ( $self->omit_xml_declaration() )
        {
            my $output_ver = $attribs->getNamedItem('version');
            my $output_enc = $attribs->getNamedItem('encoding');
            $self->output_version( $output_ver->getNodeValue )
              if defined $output_ver;
            $self->output_encoding( $output_enc->getNodeValue )
              if defined $output_enc;

            if ( not $self->output_version() || not $self->output_encoding() )
            {
                $self->warn(
                        qq{Expected attributes "version" and "encoding" in\n\t}
                      . $self->xsl_ns()
                      . "output" );
            }
        }
        my $doctype_public = $attribs->getNamedItem('doctype-public');
        my $doctype_system = $attribs->getNamedItem('doctype-system');

        my $dp = defined $doctype_public ? $doctype_public->getNodeValue : '';

        $self->doctype_public($dp);

        my $ds = defined $doctype_system ? $doctype_system->getNodeValue : '';
        $self->doctype_system($ds);

        # cdata-section-elements should only be used if the output type
        # is XML but as we are not checking that right now ...

        my $cdata_section = $attribs->getNamedItem('cdata-section-elements');

        if ( defined $cdata_section )
        {
            my $cdata_sections = [];
            @{$cdata_sections} = split /\s+/, $cdata_section->getNodeValue();
            $self->cdata_sections($cdata_sections);
        }
    }
    else
    {
        $self->debug("Default Output options being used");
    }
}

sub omit_xml_declaration
{
    my ( $self, $omit_xml_declaration ) = @_;

    if ( defined $omit_xml_declaration )
    {
        if ( $omit_xml_declaration =~ /^(yes|no)$/ )
        {
            $self->{OMIT_XML_DECL} = ( $1 eq 'yes' );
        }
        else
        {
            $self->{OMIT_XML_DECL} = $omit_xml_declaration ? 1 : 0;
        }
    }

    return exists $self->{OMIT_XML_DECL} ? $self->{OMIT_XML_DECL} : 0;
}

sub cdata_sections
{
    my ( $self, $cdata_sections ) = @_;

    if ( defined $cdata_sections )
    {
        $self->{CDATA_SECTIONS} = $cdata_sections;
    }

    $self->{CDATA_SECTIONS} = [] unless exists $self->{CDATA_SECTIONS};

    return wantarray() ? @{ $self->{CDATA_SECTIONS} } : $self->{CDATA_SECTIONS};
}

sub is_cdata_section
{
    my ( $self, $element ) = @_;

    my %cdata_sections;

    my @cdata_temp = $self->cdata_sections();
    @cdata_sections{@cdata_temp} = (1) x @cdata_temp;

    my $tagname;

    if ( defined $element and ref($element) and ref($element) eq 'XML::DOM' )
    {
        $tagname = $element->getTagName();
    }
    else
    {
        $tagname = $element;
    }

    # Will need to do namespace checking on this really

    return exists $cdata_sections{$tagname} ? 1 : 0;
}

sub output_version
{
    my ( $self, $output_version ) = @_;

    if ( defined $output_version )
    {
        $self->{OUTPUT_VERSION} = $output_version;
    }

    return exists $self->{OUTPUT_VERSION}
      ? $self->{OUTPUT_VERSION}
      : $self->default_xml_version();
}

sub __get_attribute_sets
{
    my ($self) = @_;

    my $doc     = $self->xsl_document();
    my $nsp     = $self->xsl_ns();
    my $tagname = $nsp . 'attribute-set';
	 my %inc;
	 my @included;
    foreach my $attribute_set ( $doc->getElementsByTagName( $tagname, 0 ) )
    {
        my $attribs = $attribute_set->getAttributes();
        next unless defined $attribs;
        my $name_attr = $attribs->getNamedItem('name');
        next unless defined $name_attr;
        my $name = $name_attr->getValue();
        $self->debug("processing attribute-set $name");

		  if ( my $uas = $attribs->getNamedItem('use-attribute-sets') )
		  {
			   $self->_indent();
            $inc{$name} = $uas->getValue();
				$self->debug("Attribute set $name includes $inc{$name}");
				push @included, $name;
			   $self->_outdent();
		  }

        my $attr_set = {};

        my $tagname = $nsp . 'attribute';

        foreach
          my $attribute ( $attribute_set->getElementsByTagName( $tagname, 0 ) )
        {
            my $attribs = $attribute->getAttributes();
            next unless defined $attribs;
            my $name_attr = $attribs->getNamedItem('name');
            next unless defined $name_attr;
            my $attr_name = $name_attr->getValue();
            $self->debug("Processing attribute $attr_name");
            if ($attr_name)
            {
                my $result = $self->xml_document()->createDocumentFragment();
                $self->_evaluate_template( $attribute, $self->xml_document(),
                    '/', $result );    # might need variables
                my $value =
                  $self->fix_attribute_value( $self->__string__($result) );
                $attr_set->{$attr_name} = $value;
                $result->dispose();
                $self->debug("Adding attribute $attr_name with value $value");
            }
        }

        $self->__attribute_set_( $name, $attr_set );

    }
	 foreach my $as (@included )
	 {
		 $self->_indent();
		 $self->debug("adding attributes from $inc{$as} to $as");
		 my %fix = (%{$self->__attribute_set_($as)},%{$self->__attribute_set_($inc{$as})});
       $self->__attribute_set_($as,\%fix);
		 $self->_outdent();
	 }
}

# Accessor for attribute sets

sub __attribute_set_
{
    my ( $self, $name, $attr_hash ) = @_;

    if ( defined $attr_hash && defined $name )
    {
		  if ( exists $self->{ATTRIBUTE_SETS}->{$name}  )
		  {
		     %{$self->{ATTRIBUTE_SETS}->{$name}} = 
			               ( %{$self->{ATTRIBUTE_SETS}->{$name}}, %{$attr_hash});
		  }
		  else
		  {
           $self->{ATTRIBUTE_SETS}->{$name} = $attr_hash;
		  }
    }

    return defined $name
      && exists $self->{ATTRIBUTE_SETS}->{$name}
      ? $self->{ATTRIBUTE_SETS}->{$name}
      : undef;
}

sub open_project
{
    my $self = shift;
    my $xml  = shift;
    my $xsl  = shift;
    my ( $xmlflag, $xslflag, %args ) = @_;

    carp "open_project is deprecated."
      unless $self->use_deprecated()
      or exists $deprecation_used{open_project};
    $deprecation_used{open_project} = 1;

    $self->debug("opening project:");
    $self->_indent();

    $self->open_xml( $xml, %args );
    $self->open_xsl( $xsl, %args );

    $self->debug("done...");
    $self->_outdent();
}

sub transform
{
    my $self         = shift;

	 if ( keys %{$self->{VARIABLES}} )
	 {
		$self->debug("Adding variables");
		push @_,'variables', $self->{VARIABLES};
	 }

    my %topvariables = $self->__parse_args(@_);

    $self->debug("transforming document:");
    $self->_indent();

    $self->open_xml(%topvariables);

    $self->debug("done...");
    $self->_outdent();

    # The _get_attribute_set needs an open XML document

    $self->_indent();
    $self->__get_attribute_sets();
    $self->_outdent();

    $self->debug("processing project:");
    $self->_indent();

    $self->process(%topvariables);

    $self->debug("done!");
    $self->_outdent();
    $self->result_document()->normalize();
    return $self->result_document();
}

sub process
{
    my ( $self, %topvariables ) = @_;

    $self->debug("processing project:");
    $self->_indent();

    my $root_template = $self->_match_template( "match", '/', 1, '' );

	 $self->debug(join ' ', keys %topvariables);
    %topvariables = (
        defined $topvariables{variables} ? %{$topvariables{variables}} : (),
        defined $self->{VARIABLES}
          && ref $self->{VARIABLES}
          && ref $self->{VARIABLES} eq 'ARRAY' ? @{ $self->{VARIABLES} } : ()
    );

	 $self->debug(join ' ', keys %topvariables);


    $self->_evaluate_template(
        $root_template,    # starting template: the root template
        $self->xml_document(),
        '',                          # current XML selection path: the root
        $self->result_document(),    # current result tree node: the root
        { () },                      # current known variables: none
        \%topvariables    # previously known variables: top level variables
    );

    $self->debug("done!");
    $self->_outdent();
}

# Handles deprecations.
sub AUTOLOAD
{
    my $self = shift;
    my $type = ref($self) || croak "Not a method call";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    my %deprecation = (
        'output_string'      => 'toString',
        'result_string'      => 'toString',
        'output'             => 'toString',
        'result'             => 'toString',
        'result_mime_type'   => 'media_type',
        'output_mime_type'   => 'media_type',
        'result_tree'        => 'to_dom',
        'output_tree'        => 'to_dom',
        'transform_document' => 'transform',
        'process_project'    => 'process'
    );

    if ( exists $deprecation{$name} )
    {
        carp "$name is deprecated.  Use $deprecation{$name}"
          unless $self->use_deprecated()
          or exists $deprecation_used{$name};
        $deprecation_used{$name} = 1;
        eval qq{return \$self->$deprecation{$name}(\@_)};
    }
    else
    {
        croak "$name: No such method name";
    }
}

sub _my_print_text
{
    my ( $self, $FILE ) = @_;

    if ( UNIVERSAL::isa( $self, "XML::DOM::CDATASection" ) )
    {
        $FILE->print( $self->getData() );
    }
    else
    {
        $FILE->print( XML::DOM::encodeText( $self->getData(), "<&" ) );
    }
}

sub toString
{
    my $self = $_[0];

    local $^W;
    local *XML::DOM::Text::print = \&_my_print_text;

    my $string = $self->result_document()->toString();

    return $string;
}

sub to_dom
{
    my ($self) = @_;

    return $self->result_document();
}

sub media_type
{
    my ( $self, $media_type ) = @_;

    if ( defined $media_type )
    {
        $self->{MEDIA_TYPE} = $media_type;
    }

    return $self->{MEDIA_TYPE};
}

sub print_output
{
    my ( $self, $file, $mime ) = @_;
    $file ||= '';    # print to STDOUT by default
    $mime = 1 unless defined $mime;

    # print mime-type header etc by default

    #  $self->{RESULT_DOCUMENT}->printToFileHandle (\*STDOUT);
    #  or $self->{RESULT_DOCUMENT}->print (\*STDOUT); ???
    #  exit;

    carp "print_output is deprecated.  Use serve."
      unless $self->use_deprecated()
      or exists $deprecation_used{print_output};
    $deprecation_used{print_output} = 1;

    if ($mime)
    {
        print "Content-type: " . $self->media_type() . "\n\n";

        if ( $self->xsl_output_method =~ /(?:xml|html)/ )
        {
            unless ( $self->omit_xml_declaration() )
            {
                print $self->xml_declaration(), "\n";
            }
        }

        if ( my $doctype = $self->doctype() )
        {
            print "$doctype\n";
        }
    }

    if ($file)
    {
        if ( ref( \$file ) eq 'SCALAR' )
        {
            print $file $self->output_string, "\n";
        }
        else
        {
            if ( open( FILE, ">$file" ) )
            {
                print FILE $self->output_string, "\n";
                if ( !close(FILE) )
                {
                    die("Error writing $file: $!. Nothing written...\n");
                }
            }
            else
            {
                die("Error opening $file: $!. Nothing done...\n");
            }
        }
    }
    else
    {
        print $self->output_string, "\n";
    }
}

*print_result = *print_output;

sub doctype
{
    my ($self) = @_;

    my $doctype = "";

    if ( $self->doctype_public() || $self->doctype_system() )
    {
        my $root_name =
          $self->result_document()->getElementsByTagName( '*', 0 )->item(0)
          ->getTagName;

        if ( $self->doctype_public() )
        {
            $doctype =
                qq{<!DOCTYPE $root_name PUBLIC "}
              . $self->doctype_public() . qq{" "}
              . $self->doctype_system() . qq{">};
        }
        else
        {
            $doctype =
              qq{<!DOCTYPE $root_name SYSTEM "}
              . $self->doctype_system() . qq{">};
        }
    }

    $self->debug("returning doctype of $doctype");
    return $doctype;
}

sub dispose
{

    #my $self = $_[0];

    #$_[0]->[PARSER] = undef if (defined $_[0]->[PARSER]);
    $_[0]->result_document()->dispose if ( defined $_[0]->result_document() );

    # only dispose xml and xsl when they were not passed as DOM
    if ( not defined $_[0]->{XML_PASSED_AS_DOM}
        && defined $_ - [0]->xml_document() )
    {
        $_[0]->xml_document()->dispose;
    }
    if ( not defined $_[0]->{XSL_PASSED_AS_DOM}
        && defined $_ - [0]->xsl_document() )
    {
        $_[0]->xsl_document()->dispose;
    }

    $_[0] = undef;
}

######################################################################
# PRIVATE DEFINITIONS

sub __open_document
{
    my $self = shift;
    my %args = @_;
    %args = ( %{ $self->{PARSER_ARGS} }, %args );
    my $doc;

    $self->debug("opening document");

    eval {
        my $ref = ref( $args{Source} );
        if (
               !$ref
            && length $args{Source} < 255
            && (   -f $args{Source}
                || lc( substr( $args{Source}, 0, 5 ) ) eq 'http:'
                || lc( substr( $args{Source}, 0, 6 ) ) eq 'https:'
                || lc( substr( $args{Source}, 0, 4 ) ) eq 'ftp:'
                || lc( substr( $args{Source}, 0, 5 ) ) eq 'file:' )
          )
        {

            # Filename
            $self->debug("Opening URL");
            $doc = $self->__open_by_filename( $args{Source}, $args{base} );
        }
        elsif ( !$ref )
        {

            # String
            $self->debug("Opening String");
            $doc = $self->{PARSER}->parse( $args{Source} );
        }
        elsif ( $ref eq "SCALAR" )
        {

            # Stringref
            $self->debug("Opening Stringref");
            $doc = $self->{PARSER}->parse( ${ $args{Source} } );
        }
        elsif ( $ref eq "XML::DOM::Document" )
        {

            # DOM object
            $self->debug("Opening XML::DOM");
            $doc = $args{Source};
        }
        elsif ( $ref eq "GLOB" )
        {    # This is a file glob
            $self->debug("Opening GLOB");
            my $ioref = *{ $args{Source} }{IO};
            $doc = $self->{PARSER}->parse($ioref);
        }
        elsif ( UNIVERSAL::isa( $args{Source}, 'IO::Handle' ) )
        {    # IO::Handle
            $self->debug("Opening IO::Handle");
            $doc = $self->{PARSER}->parse( $args{Source} );
        }
        else
        {
            $doc = undef;
        }
    };
    die "Error while parsing: $@\n" . $args{Source} if $@;
    return $doc;
}

# private auxiliary function #
sub __open_by_filename
{
    my ( $self, $filename, $base ) = @_;
    my $doc;

    # ** FIXME: currently reads the whole document into memory
    #           might not be avoidable

    # LWP should be able to deal with files as well as links
    $ENV{DOMAIN} ||= "example.com";    # hide complaints from Net::Domain

    my $file = get( URI->new_abs( $filename, $base ) );

    return $self->{PARSER}->parse( $file, %{ $self->{PARSER_ARGS} } );
}

sub _match_template
{
    my ( $self, $attribute_name, $select_value, $xml_count, $xml_selection_path,
        $mode )
      = @_;
    $mode ||= "";

    my $template         = "";
    my @template_matches = ();

    $self->debug(
            qq{matching template for "$select_value" with count $xml_count\n\t}
          . qq{and path "$xml_selection_path":} );

    if ( $attribute_name eq "match" && ref $self->{TEMPLATE_MATCH} )
    {
        push @template_matches, @{ $self->{TEMPLATE_MATCH} };
    }
    elsif ( $attribute_name eq "name" && ref $self->{TEMPLATE_NAME} )
    {
        push @template_matches, @{ $self->{TEMPLATE_NAME} };
    }

  # note that the order of @template_matches is the reverse of $self->{TEMPLATE}
    my $count = @template_matches;
    foreach my $original_match (@template_matches)
    {

        # templates with no match or name or with both simultaniuously
        # have no $template_match value
        if ($original_match)
        {
            my $full_match = $original_match;

            # multipe match? (for example: match="*|/")
            while ( $full_match =~ s/^(.+?)\|// )
            {
                my $match = $1;
                if (
                    &__template_matches__(
                        $match,     $select_value,
                        $xml_count, $xml_selection_path
                    )
                  )
                {
                    $self->debug(
                        qq{  found #$count with "$match" in "$original_match"});

                    $template = ( $self->templates() )[ $count - 1 ];
                    return $template;

                    #	  last;
                }
            }

            # last match?
            if ( !$template )
            {
                if (
                    &__template_matches__(
                        $full_match, $select_value,
                        $xml_count,  $xml_selection_path
                    )
                  )
                {
                    $self->debug(
qq{  found #$count with "$full_match" in "$original_match"}
                    );
                    $template = ( $self->templates() )[ $count - 1 ];
                    return $template;

                    #          last;
                }
                else
                {
                    $self->debug(qq{  #$count "$original_match" did not match});
                }
            }
        }
        $count--;
    }

    if ( !$template )
    {
        $self->warn(qq{No template matching `$xml_selection_path' found !!});
    }

    return $template;
}

# auxiliary function #
sub __template_matches__
{
    my ( $template, $select, $count, $path ) = @_;

    my $nocount_path = $path;
    $nocount_path =~ s/\[.*?\]//g;

    if (   ( $template eq $select )
        || ( $template eq $path )
        || ( $template eq "$select\[$count\]" )
        || ( $template eq "$path\[$count\]" ) )
    {

        # perfect match or path ends with templates match
        #print "perfect match","\n";
        return "True";
    }
    elsif (
           ( $template eq substr( $path, -length($template) ) )
        || ( $template eq substr( $nocount_path, -length($template) ) )
        || ( "$template\[$count\]" eq substr( $path, -length($template) ) )
        || (
            "$template\[$count\]" eq substr( $nocount_path, -length($template) )
        )
      )
    {

        # template matches tail of path matches perfectly
        #print "perfect tail match","\n";
        return "True";
    }
    elsif ( $select =~ /\[\s*(\@.*?)\s*=\s*(.*?)\s*\]$/ )
    {

        # match attribute test
        my $attribute = $1;
        my $value     = $2;
        return "";    # False, no test evaluation yet #
    }
    elsif ( $select =~ /\[\s*(.*?)\s*=\s*(.*?)\s*\]$/ )
    {

        # match test
        my $element = $1;
        my $value   = $2;
        return "";    # False, no test evaluation yet #
    }
    elsif ( $select =~ /(\@\*|\@[\w\.\-\:]+)$/ )
    {

        # match attribute
        my $attribute = $1;

        #print "attribute match?\n";
        return ( ( $template eq '@*' )
              || ( $template eq $attribute )
              || ( $template eq "\@*\[$count\]" )
              || ( $template eq "$attribute\[$count\]" ) );
    }
    elsif ( $select =~ /(\*|[\w\.\-\:]+)$/ )
    {

        # match element
        my $element = $1;

        #print "element match?\n";
        return ( ( $template eq "*" )
              || ( $template eq $element )
              || ( $template eq "*\[$count\]" )
              || ( $template eq "$element\[$count\]" ) );
    }
    else
    {
        return "";    # False #
    }
}

sub _evaluate_test
{
    my ( $self, $test, $current_xml_node, $current_xml_selection_path,
        $variables )
      = @_;

    $self->debug("Doing test $test");

    if ( $test =~ /^(.+)\/\[(.+)\]$/ )
    {
        my $path = $1;
        $test = $2;

        $self->debug("evaluating test $test at path $path:");

        $self->_indent();
        my $node =
          $self->_get_node_set( $path, $self->xml_document(),
            $current_xml_selection_path, $current_xml_node, $variables );
        if (@$node)
        {
            $current_xml_node = $$node[0];
        }
        else
        {
            return "";
        }
        $self->_outdent();
    }
    else
    {
        $self->debug("evaluating path or test $test:");
        my $node =
          $self->_get_node_set( $test, $self->xml_document(),
            $current_xml_selection_path, $current_xml_node, $variables,
            "silent" );
        $self->_indent();
        if (@$node)
        {
            $self->debug("path exists!");
            return "true";
        }
        else
        {
            $self->debug("not a valid path, evaluating as test");
        }
        $self->_outdent();
    }

    $self->_indent();

    my $result =
      $self->__evaluate_test__( $test, $current_xml_selection_path,
        $current_xml_node, $variables );

    $self->debug("test evaluates @{[ $result ? 'true': 'false']}");
    $self->_outdent();
    return $result;
}

sub _evaluate_template
{
    my ( $self, $template, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->debug( qq{evaluating template content with current path }
          . qq{"$current_xml_selection_path": } );
    $self->_indent();

    die "No Template"
      unless defined $template && ref $template;
    $template->normalize;

    foreach my $child ( $template->getChildNodes )
    {
        my $ref = ref $child;

        $self->debug("$ref");
        $self->_indent();
        my $node_type = $child->getNodeType;
        if ( $node_type == ELEMENT_NODE )
        {
            $self->_evaluate_element( $child, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
        elsif ( $node_type == TEXT_NODE )
        {
            my $value = $child->getNodeValue;
            if ( length($value) and $value !~ /^[\x20\x09\x0D\x0A]+$/s )
            {
                $self->_add_node( $child, $current_result_node );
            }
        }
        elsif ( $node_type == CDATA_SECTION_NODE )
        {
            my $text = $self->xml_document()->createTextNode( $child->getData );
            $self->_add_node( $text, $current_result_node );
        }
        elsif ( $node_type == ENTITY_REFERENCE_NODE )
        {
            $self->_add_node( $child, $current_result_node );
        }
        elsif ( $node_type == DOCUMENT_TYPE_NODE )
        {

            # skip #
            $self->debug("Skipping Document Type node...");
        }
        elsif ( $node_type == COMMENT_NODE )
        {

            # skip #
            $self->debug("Skipping Comment node...");
        }
        else
        {
            $self->warn(
"evaluate-template: Dunno what to do with node of type $ref !!!\n\t"
                  . "($current_xml_selection_path)" );
        }

        $self->_outdent();
    }

    $self->debug("done!");
    $self->_outdent();
}

sub _add_node
{
    my ( $self, $node, $parent, $deep, $owner ) = @_;
    $owner ||= $self->xml_document();

    my $what = defined $deep ? 'deep' : 'non-deep';

    $self->debug("adding node ($what)..");

    $node = $node->cloneNode($deep);
    $node->setOwnerDocument($owner);
    if ( $node->getNodeType == ATTRIBUTE_NODE )
    {
        $parent->setAttributeNode($node);
    }
    else
    {
        $parent->appendChild($node);
    }
}

sub _apply_templates
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;
    my $children;
    my $params       = {};
    my $newvariables = defined $variables ? {%$variables} : {};

    my $select = $xsl_node->getAttribute('select');

    if ( $select =~ /\$/ and defined $variables )
    {

        # replacing occurences of variables:
        foreach my $varname ( keys(%$variables) )
        {
				$self->debug("Applying variable $varname");
            $select =~ s/[^\\]\$$varname/$$variables{$varname}/g;
        }
    }

    if ($select)
    {
        $self->debug(
qq{applying templates on children select of "$current_xml_selection_path":}
        );
        $children =
          $self->_get_node_set( $select, $self->xml_document(),
            $current_xml_selection_path, $current_xml_node, $variables );
    }
    else
    {
        $self->debug(
qq{applying templates on all children of "$current_xml_selection_path":}
        );
        $children = [ $current_xml_node->getChildNodes ];
    }

    $self->_process_with_params( $xsl_node, 
				                     $current_xml_node,
                                 $current_xml_selection_path, 
											$variables, 
											$params );

    # process xsl:sort here

    $self->_indent();

    my $count = 1;
    foreach my $child (@$children)
    {
        my $node_type = $child->getNodeType;

        if ( $node_type == DOCUMENT_TYPE_NODE )
        {

            # skip #
            $self->debug("Skipping Document Type node...");
        }
        elsif ( $node_type == DOCUMENT_FRAGMENT_NODE )
        {

            # skip #
            $self->debug("Skipping Document Fragment node...");
        }
        elsif ( $node_type == NOTATION_NODE )
        {

            # skip #
            $self->debug("Skipping Notation node...");
        }
        else
        {

            my $newselect = "";
            my $newcount  = $count;
            if ( !$select || ( $select eq '.' ) )
            {
                if ( $node_type == ELEMENT_NODE )
                {
                    $newselect = $child->getTagName;
                }
                elsif ( $node_type == ATTRIBUTE_NODE )
                {
                    $newselect = "@$child->getName";
                }
                elsif (( $node_type == TEXT_NODE )
                    || ( $node_type == ENTITY_REFERENCE_NODE ) )
                {
                    $newselect = "text()";
                }
                elsif ( $node_type == PROCESSING_INSTRUCTION_NODE )
                {
                    $newselect = "processing-instruction()";
                }
                elsif ( $node_type == COMMENT_NODE )
                {
                    $newselect = "comment()";
                }
                else
                {
                    my $ref = ref $child;
                    $self->debug("Unknown node encountered: `$ref'");
                }
            }
            else
            {
                $newselect = $select;
                if ( $newselect =~ s/\[(\d+)\]$// )
                {
                    $newcount = $1;
                }
            }

            $self->_select_template(
                $child,                      $newselect,
                $newcount,                   $current_xml_node,
                $current_xml_selection_path, $current_result_node,
                $newvariables,               $params
            );
        }
        $count++;
    }

    $self->_indent();
}

sub _for_each
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    my $ns = $self->xsl_ns();
    my $select = $xsl_node->getAttribute('select')
      || die "No `select' attribute in for-each element";

    if ( $select =~ /\$/ )
    {

        # replacing occurences of variables:
        foreach my $varname ( keys(%$variables) )
        {
            $select =~ s/[^\\]\$$varname/$$variables{$varname}/g;
        }
    }

    if ( defined $select )
    {
        $self->debug(
qq{applying template for each child $select of "$current_xml_selection_path":}
        );


        my $children = $self->_get_node_set( $select, 
					                              $self->xml_document(),
                                             $current_xml_selection_path, 
															$current_xml_node, $variables );

		  my $sort = $xsl_node->getElementsByTagName("$ns:sort",0);

        if ( my $nokeys = $sort->getLength() )
		  {
		     $self->debug("going to sort with $nokeys");
		  }
		  
        $self->_indent();
        my $count = 1;
        foreach my $child (@$children)
        {
            my $node_type = $child->getNodeType;

            if ( $node_type == DOCUMENT_TYPE_NODE )
            {

                # skip #
                $self->debug("Skipping Document Type node...");
            }
            elsif ( $node_type == DOCUMENT_FRAGMENT_NODE )
            {

                # skip #
                $self->debug("Skipping Document Fragment node...");
            }
            elsif ( $node_type == NOTATION_NODE )
            {

                # skip #
                $self->debug("Skipping Notation node...");
            }
            else
            {

                $self->_evaluate_template(
                    $xsl_node,
                    $child,
                    "$current_xml_selection_path/$select\[$count\]",
                    $current_result_node,
                    $variables,
                    $oldvariables
                );
            }
            $count++;
        }

        $self->_outdent();
    }
    else
    {
        $self->warn(qq%expected attribute "select" in <${ns}for-each>%);
    }

}

sub _select_template
{
    my ( $self, $child, $select, $count, $current_xml_node,
        $current_xml_selection_path, $current_result_node, $variables,
        $oldvariables )
      = @_;

    my $ref = ref $child;
    $self->debug(
qq{selecting template $select for child type $ref of "$current_xml_selection_path":}
    );

    $self->_indent();

    my $child_xml_selection_path = "$current_xml_selection_path/$select";
    my $template                 =
      $self->_match_template( "match", $select, $count,
        $child_xml_selection_path );

    if ($template)
    {

        $self->_evaluate_template( $template, $child,
            "$child_xml_selection_path\[$count\]",
            $current_result_node, $variables, $oldvariables );
    }
    else
    {
        $self->debug("skipping template selection...");
    }

    $self->_outdent();
}

sub _evaluate_element
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;
    my ( $ns, $xsl_tag ) = split( ':', $xsl_node->getTagName );

    if ( not defined $xsl_tag )
    {
        $xsl_tag = $ns;
        $ns      = $self->default_ns();
    }
    else
    {
        $ns .= ':';
    }
    $self->debug(
        qq{evaluating element `$xsl_tag' from `$current_xml_selection_path': });
    $self->_indent();

    if ( $ns eq $self->xsl_ns() )
    {
        my @attributes = $xsl_node->getAttributes->getValues;
        $self->debug(qq{This is an xsl tag});
        if ( $xsl_tag eq 'apply-templates' )
        {
            $self->_apply_templates( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'attribute' )
        {
            $self->_attribute( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'call-template' )
        {
            $self->_call_template( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'choose' )
        {
            $self->_choose( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'comment' )
        {
            $self->_comment( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'copy' )
        {
            $self->_copy( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'copy-of' )
        {
            $self->_copy_of( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables );
        }
        elsif ( $xsl_tag eq 'element' )
        {
            $self->_element( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
        elsif ( $xsl_tag eq 'for-each' )
        {
            $self->_for_each( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

        }
        elsif ( $xsl_tag eq 'if' )
        {
            $self->_if( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );

            #      } elsif ($xsl_tag eq 'output') {

        }
        elsif ( $xsl_tag eq 'param' )
        {
            $self->_variable( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables, 1 );

        }
        elsif ( $xsl_tag eq 'processing-instruction' )
        {
            $self->_processing_instruction( $xsl_node, $current_result_node );

        }
        elsif ( $xsl_tag eq 'text' )
        {
            $self->_text( $xsl_node, $current_result_node );

        }
        elsif ( $xsl_tag eq 'value-of' )
        {
            $self->_value_of( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables );

        }
        elsif ( $xsl_tag eq 'variable' )
        {
            $self->_variable( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables, 0 );

        }
        elsif ( $xsl_tag eq 'sort' )
        {
            $self->_sort( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables, 0 );
        }
        elsif ( $xsl_tag eq 'fallback' )
        {
            $self->_fallback( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables, 0 );
        }
        elsif ( $xsl_tag eq 'attribute-set' )
        {
            $self->_attribute_set( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables, 0 );
        }
        else
        {
            $self->_add_and_recurse( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
    }
    else
    {
        $self->debug( $ns . " does not match " . $self->xsl_ns() );

        # not entirely sure if this right but the spec is a bit vague

        if ( $self->is_cdata_section($xsl_tag) )
        {
            $self->debug("This is a CDATA section element");
            $self->_add_cdata_section( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
        else
        {
            $self->debug("This is a literal element");
            $self->_check_attributes_and_recurse( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
    }

    $self->_outdent();
}

sub _add_cdata_section
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    my $node = $self->xml_document()->createElement( $xsl_node->getTagName );

    my $cdata = '';

    foreach my $child_node ( $xsl_node->getChildNodes() )
    {
        if ( $child_node->can('asString') )
        {
            $cdata .= $child_node->asString();
        }
        else
        {
            $cdata .= $child_node->getNodeValue();
        }
    }

    $node->addCDATA($cdata);

    $current_result_node->appendChild($node);

}

sub _add_and_recurse
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

# the addition is commented out to prevent unknown xsl: commands to be printed in the result
    $self->_add_node( $xsl_node, $current_result_node );
    $self->_evaluate_template( $xsl_node, $current_xml_node,
        $current_xml_selection_path, $current_result_node, $variables,
        $oldvariables );    #->getLastChild);
}

sub _check_attributes_and_recurse
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->_add_node( $xsl_node, $current_result_node );
    $self->_attribute_value_of(
        $current_result_node->getLastChild, $current_xml_node,
        $current_xml_selection_path,        $variables
    );
    $self->_evaluate_template( $xsl_node, $current_xml_node,
        $current_xml_selection_path, $current_result_node->getLastChild,
        $variables, $oldvariables );
}

sub _element
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    my $name = $xsl_node->getAttribute('name');
    $self->debug(qq{inserting Element named "$name":});
    $self->_indent();

    if ( defined $name )
    {
        my $result = $self->xml_document()->createElement($name);

        $self->_evaluate_template( $xsl_node, $current_xml_node,
            $current_xml_selection_path, $result, $variables, $oldvariables );

	 	  $self->_apply_attribute_set($xsl_node,$result);
        $current_result_node->appendChild($result);
    }
    else
    {
        $self->warn(
            q{expected attribute "name" in <} . $self->xsl_ns() . q{element>} );
    }
    $self->_outdent();
}

sub _apply_attribute_set
{
   my ( $self,$xsl_node, $output_node) = @_;

   my $attr_set = $xsl_node->getAttribute('use-attribute-sets');

   if ($attr_set)
   {
      $self->_indent();
      my $set_name = $attr_set;

      if ( my $set = $self->__attribute_set_($set_name) )
      {
         $self->debug("Adding attribute-set '$set_name'");

         foreach my $attr_name ( keys %{$set} )
         {
           $self->debug(
                        "Adding attribute $attr_name ->" . $set->{$attr_name} );
           $output_node->setAttribute( $attr_name, $set->{$attr_name} );
         }
      }
      $self->_outdent();
   }
}

{
    ######################################################################
    # Auxiliary package for disable-output-escaping
    ######################################################################

    package XML::XSLT::DOM::TextDOE;
    use vars qw( @ISA );
    @ISA = qw( XML::DOM::Text );

    sub print
    {
        my ( $self, $FILE ) = @_;
        $FILE->print( $self->getData );
    }
}

sub _value_of
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables )
      = @_;

    my $select = $xsl_node->getAttribute('select');

    # Need to determine here whether the value is an XPath expression
    # and act accordingly

    my $xml_node;

    if ( defined $select )
    {
        $xml_node = $self->_get_node_set( $select, 
					                           $self->xml_document(),
                                          $current_xml_selection_path, 
														$current_xml_node, 
														$variables );

        $self->debug("stripping node to text:");

        $self->_indent();
        my $text = '';
        $text = $self->__string__( $xml_node->[0] ) if @{$xml_node};
        $self->_outdent();

        if ( $text ne '' )
        {
            my $node = $self->xml_document()->createTextNode($text);
            if ( $xsl_node->getAttribute('disable-output-escaping') eq 'yes' )
            {
                $self->debug("disabling output escaping");
                bless $node, 'XML::XSLT::DOM::TextDOE';
            }
            $self->_move_node( $node, $current_result_node );
        }
        else
        {
            $self->debug("nothing left..");
        }
    }
    else
    {
        $self->warn( qq{expected attribute "select" in <}
              . $self->xsl_ns()
              . q{value-of>} );
    }
}

sub __strip_node_to_text__
{
    my ( $self, $node ) = @_;

    my $result = "";

    my $node_type = $node->getNodeType;
    if ( $node_type == TEXT_NODE )
    {
        $result = $node->getData;
    }
    elsif (( $node_type == ELEMENT_NODE )
        || ( $node_type == DOCUMENT_FRAGMENT_NODE ) )
    {
        $self->_indent();
        foreach my $child ( $node->getChildNodes )
        {
            $result .= &__strip_node_to_text__( $self, $child );
        }
        $self->_outdent();
    }
    return $result;
}

sub __string__
{
    my ( $self, $node, $depth ) = @_;

    my $result = "";

    if ( defined $node )
    {
        my $ref = ( ref($node) || "not a reference" );
        $self->debug("stripping child nodes ($ref):");

        $self->_indent();

        if ( $ref eq "ARRAY" )
        {
            return $self->__string__( $$node[0], $depth );
        }
        else
        {
            my $node_type = $node->getNodeType;

            if (   ( $node_type == ELEMENT_NODE )
                || ( $node_type == DOCUMENT_FRAGMENT_NODE )
                || ( $node_type == DOCUMENT_NODE ) )
            {
                foreach my $child ( $node->getChildNodes )
                {
                    $result .= &__string__( $self, $child, 1 );
                }
            }
            elsif ( $node_type == ATTRIBUTE_NODE )
            {
                $result .= $node->getValue;
            }
            elsif (( $node_type == TEXT_NODE )
                || ( $node_type == CDATA_SECTION_NODE )
                || ( $node_type == ENTITY_REFERENCE_NODE ) )
            {
                $result .= $node->getData;
            }
            elsif (
                !$depth
                && (   ( $node_type == PROCESSING_INSTRUCTION_NODE )
                    || ( $node_type == COMMENT_NODE ) )
              )
            {
                $result .= $node->getData;   # COM,PI - only in 'top-level' call
            }
            else
            {

                # just to be consistent
                $self->warn("Can't get string-value for node of type $ref !");
            }
        }

        $self->debug(qq{  "$result"});
        $self->_outdent();
    }
    else
    {
        $self->debug(" no result");
    }

    return $result;
}

sub _move_node
{
    my ( $self, $node, $parent ) = @_;

    $self->debug("moving node..");

    $parent->appendChild($node);
}

sub _get_node_set
{
    my ( $self, $path, $root_node, $current_path, $current_node, $variables,
        $silent )
      = @_;
    $current_path ||= "/";
    $current_node ||= $root_node;
    $silent       ||= 0;

	 %{$variables} = (%{$self->{VARIABLES}}, %{$variables});
    $self->debug(qq{getting node-set "$path" from "$current_path"});

    $self->_indent();

    # expand abbriviated syntax
    $path =~ s/\@/attribute\:\:/g;
    $path =~ s/\.\./parent\:\:node\(\)/g;
    $path =~ s/\./self\:\:node\(\)/g;
    $path =~ s/\/\//\/descendant\-or\-self\:\:node\(\)\//g;

    #$path =~ s/\/[^\:\/]*?\//attribute::/g;

    if ( $path =~ /^\$([\w\.\-]+)$/ )
    {
        my $varname = $1;
		  $self->debug("looking for variable $varname");
		  $self->debug(join ' ', keys %{$variables});
        my $var     = $$variables{$varname};
        if ( defined $var )
        {
            if ( ref( $$variables{$varname} ) eq 'ARRAY' )
            {

                # node-set array-ref
                return $$variables{$varname};
            }
            elsif ( ref( $$variables{$varname} ) eq 'XML::DOM::NodeList' )
            {

                # node-set nodelist
                return [ @{ $$variables{$varname} } ];
            }
            elsif (
                ref( $$variables{$varname} ) eq 'XML::DOM::DocumentFragment' )
            {

                # node-set documentfragment
                return [ $$variables{$varname}->getChildNodes ];
            }
            else
            {
                # string or number?
                return [ $self->xml_document()
                      ->createTextNode( $$variables{$varname} ) ];
            }
        }
        else
        {
            # var does not exist
            return [];
        }
    }
    elsif ( $path eq $current_path || $path eq 'self::node()' )
    {
        $self->debug("direct hit!");
        return [$current_node];
    }
    else
    {

        # open external documents first #
        if ( $path =~
            /^\s*document\s*\(["'](.*?)["']\s*(,\s*(.*)\s*){0,1}\)\s*(.*)$/ )
        {
            my $filename = $1;
            my $sec_arg  = $3;
            $path = ( $4 || "" );

            $self->debug(qq{external selection ("$filename")!});

            if ($sec_arg)
            {
                $self->warn("Ignoring second argument of $path");
            }

            ($root_node) =
              $self->__open_by_filename( $filename, $self->{XSL_BASE} );
        }

        if ( $path =~ /^\// )
        {

            # start from the root #
            $current_node = $root_node;
        }
        elsif ( $path =~ /^self\:\:node\(\)\// )
        {    #'#"#'#"
             # remove preceding dot from './etc', which is expanded to 'self::node()'
             # at the top of this subroutine #
            $path =~ s/^self\:\:node\(\)//;
        }
        else
        {

            # to facilitate parsing, precede path with a '/' #
            $path = "/$path";
        }

        $self->debug(qq{using "$path":});

        if ( $path eq '/' )
        {
            $current_node = [$current_node];
        }
        else
        {
            $current_node = $self->__get_node_set__( $path, 
																	  [$current_node], 
																	  $silent );
        }

        $self->_outdent();

        return $current_node;
    }
}

# auxiliary function #
sub __get_node_set__
{
    my ( $self, $path, $node, $silent ) = @_;

    # a Qname (?) should actually be: [a-Z_][\w\.\-]*\:[a-Z_][\w\.\-]*

    if ( $path eq "" )
    {

        $self->debug("node found!");
        return $node;

    }
    else
    {
        my $list = [];
        foreach my $item (@$node)
        {
            my $sublist = $self->__try_a_step__( $path, $item, $silent );
            push( @$list, @$sublist );
        }
        return $list;
    }
}

sub __try_a_step__
{
    my ( $self, $path, $node, $silent ) = @_;


	 $self->_indent();
	 $self->debug("Trying $path >");
    if ( $path =~ s/^\/parent\:\:node\(\)// )
    {

        # /.. #
        $self->debug(qq{getting parent ("$path")});
        return &__parent__( $self, $path, $node, $silent );

    }
    elsif ( $path =~ s/^\/attribute\:\:(\*|[\w\.\:\-]+)// )
    {

        # /@attr #
        $self->debug(qq{getting attribute `$1' ("$path")});
        return &__attribute__( $self, $1, $path, $node, $silent );

    }
    elsif ( $path =~
s/^\/descendant\-or\-self\:\:node\(\)\/(child\:\:|)(\*|[\w\.\:\-]+)\[(\S+?)\]//
      )
    {

        # //elem[n] #
        $self->debug(qq{getting deep indexed element `$1' `$2' ("$path")});
        return &__indexed_element__( $self, $1, $2, $path, $node, $silent,
            "deep" );

    }
    elsif ( $path =~ s/^\/descendant\-or\-self\:\:node\(\)\/(\*|[\w\.\:\-]+)// )
    {

        # //elem #
        $self->debug(qq{getting deep element `$1' ("$path")});
        return &__element__( $self, $1, $path, $node, $silent, "deep" );

    }
    elsif ( $path =~ s/^\/(child\:\:|)(\*|[\w\.\:\-]+)\[(\S+?)\]// )
    {

        # /elem[n] #
        $self->debug(qq{getting indexed element `$2' `$3' ("$path")});
        return &__indexed_element__( $self, $2, $3, $path, $node, $silent );

    }
    elsif ( $path =~ s/^\/(child\:\:|)text\(\)// )
    {

        # /text() #
        $self->debug(qq{getting text ("$path")});
        return &__get_nodes__( $self, TEXT_NODE, $path, $node, $silent );

    }
    elsif ( $path =~ s/^\/(child\:\:|)processing-instruction\(\)// )
    {

        # /processing-instruction() #
        $self->debug(qq{getting processing instruction ("$path")});
        return $self->__get_nodes__(PROCESSING_INSTRUCTION_NODE, 
					                     $path, 
												$node,
                                    $silent );

    }
    elsif ( $path =~ s/^\/(child\:\:|)comment\(\)// )
    {

        # /comment() #
        $self->debug(qq{getting comment ("$path")});
        return &__get_nodes__( $self, COMMENT_NODE, $path, $node, $silent );

    }
    elsif ( $path =~ s/^\/(child\:\:|)(\*|[\w\.\:\-]+)// )
    {

        # /elem #
        $self->debug(qq{getting element `$2' ("$path")});
        return &__element__( $self, $2, $path, $node, $silent );

    }
    else
    {
        $self->warn(
            "get-node-from-path: Don't know what to do with path $path !!!");
        return [];
    }
}

sub __parent__
{
    my ( $self, $path, $node, $silent ) = @_;

    $self->_indent();
    if (   ( $node->getNodeType == DOCUMENT_NODE )
        || ( $node->getNodeType == DOCUMENT_FRAGMENT_NODE ) )
    {
        $self->debug("no parent!");
        $node = [];
    }
    else
    {
        $node = $node->getParentNode;

        $node = &__get_node_set__( $self, $path, [$node], $silent );
    }
    $self->_outdent();

    return $node;
}

sub __indexed_element__
{
    my ( $self, $element, $index, $path, $node, $silent, $deep ) = @_;
    $index ||= 0;
    $deep  ||= "";    # False #

    if ( $index =~ /^first\s*\(\)/ )
    {
        $index = 0;
    }
    elsif ( $index =~ /^last\s*\(\)/ )
    {
        $index = -1;
    }
    else
    {
        $index--;
    }

    my @list = $node->getElementsByTagName( $element, $deep );

    if (@list)
    {
        $node = $list[$index];
    }
    else
    {
        $node = "";
    }

    $self->_indent();
    if ($node)
    {
        $node = &__get_node_set__( $self, $path, [$node], $silent );
    }
    else
    {
        $self->debug("failed!");
        $node = [];
    }
    $self->_outdent();

    return $node;
}

sub __element__
{
    my ( $self, $element, $path, $node, $silent, $deep ) = @_;
    $deep ||= "";    # False #

    $node = [ $node->getElementsByTagName( $element, $deep ) ];

    $self->_indent();
    if (@$node)
    {
        $node = &__get_node_set__( $self, $path, $node, $silent );
    }
    else
    {
        $self->debug("failed!");
    }
    $self->_outdent();

    return $node;
}

sub __attribute__
{
    my ( $self, $attribute, $path, $node, $silent ) = @_;
    if ( $attribute eq '*' )
    {
        $node = [ $node->getAttributes->getValues ];

        $self->_indent();
        if ($node)
        {
            $node = &__get_node_set__( $self, $path, $node, $silent );
        }
        else
        {
            $self->debug("failed!");
        }
        $self->_outdent();
    }
    else
    {
        $node = $node->getAttributeNode($attribute);

        $self->_indent();
        if ($node)
        {
            $node = &__get_node_set__( $self, $path, [$node], $silent );
        }
        else
        {
            $self->debug("failed!");
            $node = [];
        }
        $self->_outdent();
    }

    return $node;
}

sub __get_nodes__
{
    my ( $self, $node_type, $path, $node, $silent ) = @_;

    my $result = [];

    $self->_indent();
    foreach my $child ( $node->getChildNodes )
    {
        if ( $child->getNodeType == $node_type )
        {
            push @{$result}, @{$self->__get_node_set__($path, 
									                            [$child], $silent )};
        }
    }
    $self->_outdent();

    if ( !@$result )
    {
        $self->debug("failed!");
    }

    return $result;
}

sub _attribute_value_of
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $variables )
      = @_;

    foreach my $attribute ( $xsl_node->getAttributes->getValues )
    {
        my $value = $attribute->getValue;
        study($value);

        #$value =~ s/(\*|\$|\@|\&|\?|\+|\\)/\\$1/g;
        $value =~ s/(\*|\?|\+)/\\$1/g;
        study($value);
        while ( $value =~ /\G[^\\]?\{(.*?[^\\]?)\}/ )
        {
            my $node =
              $self->_get_node_set( $1, $self->xml_document(),
                $current_xml_selection_path, $current_xml_node, $variables );
            if (@$node)
            {
                $self->_indent();
                my $text = $self->__string__( $$node[0] );
                $self->_outdent();
                $value =~ s/(\G[^\\]?)\{(.*?)[^\\]?\}/$1$text/;
            }
            else
            {
                $value =~ s/(\G[^\\]?)\{(.*?)[^\\]?\}/$1/;
            }
        }

        #$value =~ s/\\(\*|\$|\@|\&|\?|\+|\\)/$1/g;
        $value =~ s/\\(\*|\?|\+)/$1/g;
        $value =~ s/\\(\{|\})/$1/g;
        $attribute->setValue($value);
    }
}

sub _processing_instruction
{
    my ( $self, $xsl_node, $current_result_node, $variables, $oldvariables ) =
      @_;

    my $new_PI_name = $xsl_node->getAttribute('name');

    if ( $new_PI_name eq "xml" )
    {
        $self->warn( "<"
              . $self->xsl_ns()
              . "processing-instruction> may not be used to create XML" );
        $self->warn(
            "declaration. Use <" . $self->xsl_ns() . "output> instead..." );
    }
    elsif ($new_PI_name)
    {
        my $text   = $self->__string__($xsl_node);
        my $new_PI =
          $self->xml_document()
          ->createProcessingInstruction( $new_PI_name, $text );

        if ($new_PI)
        {
            $self->_move_node( $new_PI, $current_result_node );
        }
    }
    else
    {
        $self->warn( q{Expected attribute "name" in <}
              . $self->xsl_ns()
              . "processing-instruction> !" );
    }
}

sub _process_with_params
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $variables, $params )
      = @_;

    my @params =
      $xsl_node->getElementsByTagName( $self->xsl_ns() . "with-param" );
    foreach my $param (@params)
    {
        my $varname = $param->getAttribute('name');

        if ($varname)
        {
            my $value = $param->getAttribute('select');

            if ( !$value )
            {

                # process content as template
                $value = $self->xml_document()->createDocumentFragment;

                $self->_evaluate_template( $param, $current_xml_node,
                    $current_xml_selection_path, $value, $variables, {} );
                $$params{$varname} = $value;

            }
            else
            {

                # *** FIXME - should evaluate this as an expression!
                $$params{$varname} = $value;
            }
        }
        else
        {
            $self->warn( q{Expected attribute "name" in <}
                  . $self->xsl_ns()
                  . q{with-param> !} );
        }
    }

}

sub _call_template
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    my $params       = {};
    my $newvariables = defined $variables ? {%$variables} : {};
    my $name         = $xsl_node->getAttribute('name');

    if ($name)
    {
        $self->debug(qq{calling template named "$name"});

        $self->_process_with_params( $xsl_node, $current_xml_node,
            $current_xml_selection_path, $variables, $params );

        $self->_indent();
        my $template = $self->_match_template( "name", $name, 0, '' );

        if ($template)
        {
            $self->_evaluate_template( $template, $current_xml_node,
                $current_xml_selection_path, $current_result_node,
                $newvariables, $params );
        }
        else
        {
            $self->warn("no template named $name found!");
        }
        $self->_outdent();
    }
    else
    {
        $self->warn( q{Expected attribute "name" in <}
              . $self->xsl_ns()
              . q{call-template/>} );
    }
}

sub _choose
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->debug("evaluating choose:");

    $self->_indent();

    my $notdone  = "true";
    my $testwhen = "active";
    foreach my $child ( $xsl_node->getElementsByTagName( '*', 0 ) )
    {
        if (   $notdone
            && $testwhen
            && ( $child->getTagName eq $self->xsl_ns() . "when" ) )
        {
            my $test = $child->getAttribute('test');

            if ($test)
            {
                my $test_succeeds =
                  $self->_evaluate_test( $test, $current_xml_node,
                    $current_xml_selection_path, $variables );
                if ($test_succeeds)
                {
                    $self->_evaluate_template( $child, $current_xml_node,
                        $current_xml_selection_path, $current_result_node,
                        $variables, $oldvariables );
                    $testwhen = "";
                    $notdone  = "";
                }
            }
            else
            {
                $self->warn( q{expected attribute "test" in <}
                      . $self->xsl_ns()
                      . q{when>} );
            }
        }
        elsif ( $notdone
            && ( $child->getTagName eq $self->xsl_ns() . "otherwise" ) )
        {
            $self->_evaluate_template( $child, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
            $notdone = "";
        }
    }

    if ($notdone)
    {
        $self->debug("nothing done!");
    }

    $self->_outdent();
}

sub _if
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->debug("evaluating if:");

    $self->_indent();

    my $test = $xsl_node->getAttribute('test');

    if ($test)
    {
        my $test_succeeds =
          $self->_evaluate_test( $test, $current_xml_node,
            $current_xml_selection_path, $variables );
        if ($test_succeeds)
        {
            $self->_evaluate_template( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $current_result_node, $variables,
                $oldvariables );
        }
    }
    else
    {
        $self->warn(
            q{expected attribute "test" in <} . $self->xsl_ns() . q{if>} );
    }

    $self->_outdent();
}

sub __evaluate_test__
{
    my ( $self, $test, $path, $node, $variables ) = @_;

    my $tagname = eval { $node->getTagName() } || '';

    my ( $content, $test_cond, $expval, $lhs );
    $self->debug(qq{testing with "$test" and $tagname});

	 if ($test =~ /^\s*(\S+?)\s*(<=|>=|!=|<|>|=)\s*['"]?([^'"]*?)['"]?\s*$/)
	 {
		 $lhs       = $1;
       $test_cond = $2;
		 $expval    = $3;
	 }
	 $self->debug("Test LHS: $lhs");
    if ( $lhs =~ /^\@([\w\.\:\-]+)$/ )
    {
		  $self ->debug("Attribute: $1");
        $content = $node->getAttribute($1);
    }
    elsif ( $lhs =~ /^([\w\.\:\-]+)$/ )
    {
		  $self ->debug("Path: $1");
        my $test_path = $1;
        my $nodeset   = $self->_get_node_set( $test_path, 
					                               $self->xml_document(), 
															 $path, 
															 $node,
                                              $variables );
        return ( $expval ne '' ) unless @$nodeset;
        $content = &__string__( $self, $$nodeset[0] );
    }
    else
    {
        $self->debug("no match for test");
        return "";
    }
    my $numeric = ($content =~ /^\d+$/ && $expval =~ /^\d+$/ ? 1 : 0);

    $self->debug("evaluating $content $test $expval");

    $test_cond =~ s/\s+//g;

    if ( $test_cond eq '!=' )
    {
        return $numeric ? $content != $expval : $content ne $expval;
    }
    elsif ( $test_cond eq '=' )
    {
        return $numeric ? $content == $expval : $content eq $expval;
    }
    elsif ( $test_cond eq '<' )
    {
        return $numeric ? $content < $expval : $content lt $expval;
    }
    elsif ( $test_cond eq '>' )
    {
        return $numeric ? $content > $expval : $content gt $expval;
    }
    elsif ( $test_cond eq '>=' )
    {
        return $numeric ? $content >= $expval : $content ge $expval;
    }
    elsif ( $test_cond eq '<=' )
    {
        return $numeric ? $content <= $expval : $content le $expval;
    }
    else
    {
        $self->debug("no test matches");
        return 0;
    }
}

sub _copy_of
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables )
      = @_;

    my $nodelist;
    my $select = $xsl_node->getAttribute('select');
    $self->debug(qq{evaluating copy-of with select "$select":});

    $self->_indent();
    if ($select)
    {
        $nodelist =
          $self->_get_node_set( $select, $self->xml_document(),
            $current_xml_selection_path, $current_xml_node, $variables );
    }
    else
    {
        $self->warn( q{expected attribute "select" in <}
              . $self->xsl_ns()
              . q{copy-of>} );
    }
    foreach my $node (@$nodelist)
    {
        $self->_add_node( $node, $current_result_node, "deep" );
    }

    $self->_outdent();
}

sub _copy
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->debug("evaluating copy:");

    $self->_indent();
    if ( $current_xml_node->getNodeType == ATTRIBUTE_NODE )
    {
        my $attribute = $current_xml_node->cloneNode(0);
        $current_result_node->setAttributeNode($attribute);
    }
    elsif (( $current_xml_node->getNodeType == COMMENT_NODE )
        || ( $current_xml_node->getNodeType == PROCESSING_INSTRUCTION_NODE ) )
    {
        $self->_add_node( $current_xml_node, $current_result_node );
    }
    else
    {
        $self->_add_node( $current_xml_node, $current_result_node );
		  $self->_apply_attribute_set($xsl_node,$current_result_node->getLastChild());
        $self->_evaluate_template( $xsl_node, $current_xml_node,
            $current_xml_selection_path, $current_result_node->getLastChild,
            $variables, $oldvariables );
    }
    $self->_outdent();
}

sub _text
{

  #=item addText (text)
  #
  #Appends the specified string to the last child if it is a Text node, or else
  #appends a new Text node (with the specified text.)
  #
  #Return Value: the last child if it was a Text node or else the new Text node.
    my ( $self, $xsl_node, $current_result_node ) = @_;

    $self->debug("inserting text:");

    $self->_indent();

    $self->debug("stripping node to text:");

    $self->_indent();
    my $text = $self->__string__($xsl_node);
    $self->_outdent();

    if ( $text ne '' )
    {
        my $node = $self->xml_document()->createTextNode($text);
        if ( $xsl_node->getAttribute('disable-output-escaping') eq 'yes' )
        {
            $self->debug("disabling output escaping");
            bless $node, 'XML::XSLT::DOM::TextDOE';
        }
        $self->_move_node( $node, $current_result_node );
    }
    else
    {
        $self->debug("nothing left..");
    }

    $current_result_node->normalize();

    $self->_outdent();
}

sub _attribute
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    my $name = $xsl_node->getAttribute('name');
    $self->debug(qq{inserting attribute named "$name":});
    $self->_indent();

    if ($name)
    {
        if ( $name =~ /^xmlns:/ )
        {
            $self->debug("Won't create namespace declaration");
        }
        else
        {
            my $result = $self->xml_document()->createDocumentFragment;

            $self->_evaluate_template( $xsl_node, $current_xml_node,
                $current_xml_selection_path, $result, $variables,
                $oldvariables );

            $self->_indent();
            my $text = $self->fix_attribute_value( $self->__string__($result) );

            $self->_outdent();

            $current_result_node->setAttribute( $name, $text );
            $result->dispose();
        }
    }
    else
    {
        $self->warn( q{expected attribute "name" in <}
              . $self->xsl_ns()
              . q{attribute>} );
    }
    $self->_outdent();
}

sub _comment
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $oldvariables )
      = @_;

    $self->debug("inserting comment:");

    $self->_indent();

    my $result = $self->xml_document()->createDocumentFragment;

    $self->_evaluate_template( $xsl_node, $current_xml_node,
        $current_xml_selection_path, $result, $variables, $oldvariables );

    $self->_indent();
    my $text = $self->__string__($result);
    $self->_outdent();

    $self->_move_node( $self->xml_document()->createComment($text),
        $current_result_node );
    $result->dispose();

    $self->_outdent();
}

sub _variable
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $params, $is_param )
      = @_;

    my $varname = $xsl_node->getAttribute('name');

    if ($varname)
    {
        $self->debug("definition of variable \$$varname:");

        $self->_indent();

        if ( $is_param and exists $$params{$varname} )
        {

            # copy from parent-template

            $$variables{$varname} = $$params{$varname};

        }
        else
        {

            # new variable definition

            my $value = $xsl_node->getAttribute('select');

            if ( !$value )
            {

                #tough case, evaluate content as template

                $value = $self->xml_document()->createDocumentFragment;

                $self->_evaluate_template( $xsl_node, $current_xml_node,
                    $current_xml_selection_path, $value, $variables, $params );
            }
            else    # either a literal or path
            {
                if ( $value =~ /'(.*)'/ )
                {
                    $value = $1;
                }
                else
                {
                    my $node =
                      $self->_get_node_set( $value, $self->xml_document(),
                        $current_xml_selection_path, $current_xml_node,
                        $variables );
                    $value = $self->__string__($node);

                }

            }
            $variables->{$varname} = $value;
        }

        $self->_outdent();
    }
    else
    {
        $self->warn( q{expected attribute "name" in <}
              . $self->xsl_ns()
              . q{param> or <}
              . $self->xsl_ns()
              . q{variable>} );
    }
}

# not implemented - but log it and make it go away

sub _sort
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $params, $is_param )
      = @_;

    $self->debug("dummy process for sort");
}

# Not quite sure how fallback should be implemented as the spec seems a
# little vague to me

sub _fallback
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $params, $is_param )
      = @_;

    $self->debug("dummy process for fallback");
}

# This is a no-op - attribute-sets should not appear within templates and
# we have already processed the stylesheet wide ones.

sub _attribute_set
{
    my ( $self, $xsl_node, $current_xml_node, $current_xml_selection_path,
        $current_result_node, $variables, $params, $is_param )
      = @_;

    $self->debug("in _attribute_set");
}

sub _indent
{
    my ($self) = @_;
    $self->{INDENT} += $self->{INDENT_INCR};

}

sub _outdent
{
    my ($self) = @_;
    $self->{INDENT} -= $self->{INDENT_INCR};
}

sub fix_attribute_value
{
    my ( $self, $text ) = @_;

    # The spec say's that there can't be a literal line break in the
    # attributes value - white space at the beginning or the end is
    # almost certainly an mistake.

    $text =~ s/^\s+//g;
    $text =~ s/\s+$//g;

    if ($text)
    {
        $text =~ s/([\x0A\x0D])/sprintf("\&#%02X;",ord $1)/eg;
    }

    return $text;
}

1;

__DATA__

=head1 SYNOPSIS

 use XML::XSLT;

 my $xslt = XML::XSLT->new ($xsl, warnings => 1);

 $xslt->transform ($xmlfile);
 print $xslt->toString;

 $xslt->dispose();

=head1 DESCRIPTION

This module implements the W3C's XSLT specification. The goal is full
implementation of this spec, but we have not yet achieved
that. However, it already works well.  See L<XML::XSLT Commands> for
the current status of each command.

XML::XSLT makes use of XML::DOM and LWP::Simple, while XML::DOM
uses XML::Parser.  Therefore XML::Parser, XML::DOM and LWP::Simple
have to be installed properly for XML::XSLT to run.

=head1 Specifying Sources

The stylesheets and the documents may be passed as filenames, file
handles regular strings, string references or DOM-trees.  Functions
that require sources (e.g. new), will accept either a named parameter
or simply the argument.

Either of the following are allowed:

 my $xslt = XML::XSLT->new($xsl);
 my $xslt = XML::XSLT->new(Source => $xsl);

In documentation, the named parameter `Source' is always shown, but it
is never required.

=head2 METHODS

=over 4

=item new(Source => $xml [, %args])

Returns a new XSLT parser object.  Valid flags are:

=over 2

=item DOMparser_args

Hashref of arguments to pass to the XML::DOM::Parser object's parse
method.

=item variables

Hashref of variables and their values for the stylesheet.

=item base

Base of URL for file inclusion.

=item debug

Turn on debugging messages.

=item warnings

Turn on warning messages.

=item indent

Starting amount of indention for debug messages.  Defaults to 0.

=item indent_incr

Amount to indent each level of debug message.  Defaults to 1.

=back

=item open_xml(Source => $xml [, %args])

Gives the XSLT object new XML to process.  Returns an XML::DOM object
corresponding to the XML.

=over 4

=item base

The base URL to use for opening documents.

=item parser_args

Arguments to pase to the parser.

=back

=item open_xsl(Source => $xml, [, %args])

Gives the XSLT object a new stylesheet to use in processing XML.
Returns an XML::DOM object corresponding to the stylesheet.  Any
arguments present are passed to the XML::DOM::Parser.

=over 4

=item base

The base URL to use for opening documents.

=item parser_args

Arguments to pase to the parser.

=back

=item process(%variables)

Processes the previously loaded XML through the stylesheet using the
variables set in the argument.

=item transform(Source => $xml [, %args])

Processes the given XML through the stylesheet.  Returns an XML::DOM
object corresponding to the transformed XML.  Any arguments present
are passed to the XML::DOM::Parser.

=item serve(Source => $xml [, %args])

Processes the given XML through the stylesheet.  Returns a string
containg the result.  Example:

  use XML::XSLT qw(serve);

  $xslt = XML::XSLT->new($xsl);
  print $xslt->serve $xml;

=over 4

=item http_headers

If true, then prepends the appropriate HTTP headers (e.g. Content-Type,
Content-Length);

Defaults to true.

=item xml_declaration

If true, then the result contains the appropriate <?xml?> header.

Defaults to true.

=item xml_version

The version of the XML.

Defaults to 1.0.

=item doctype

The type of DOCTYPE this document is.  Defaults to SYSTEM.

=back

=item toString

Returns the result of transforming the XML with the stylesheet as a
string.

=item to_dom

Returns the result of transforming the XML with the stylesheet as an
XML::DOM object.

=item media_type

Returns the media type (aka mime type) of the object.

=item dispose

Executes the C<dispose> method on each XML::DOM object.

=back

=head1 XML::XSLT Commands

=over 4

=item xsl:apply-imports		no

Not supported yet.

=item xsl:apply-templates		limited

Attribute 'select' is supported to the same extent as xsl:value-of
supports path selections.

Not supported yet:
- attribute 'mode'
- xsl:sort and xsl:with-param in content

=item xsl:attribute			partially

Adds an attribute named to the value of the attribute 'name' and as value
the stringified content-template.

Not supported yet:
- attribute 'namespace'

=item xsl:attribute-set		yes

Partially

=item xsl:call-template		yes

Takes attribute 'name' which selects xsl:template's by name.

Weak support:
- xsl:with-param (select attrib not supported)

Not supported yet:
- xsl:sort

=item xsl:choose			yes

Tests sequentially all xsl:whens until one succeeds or
until an xsl:otherwise is found. Limited test support, see xsl:when

=item xsl:comment			yes

Supported.

=item xsl:copy				partially

=item xsl:copy-of			limited

Attribute 'select' functions as well as with
xsl:value-of

=item xsl:decimal-format		no

Not supported yet.

=item xsl:element			yes

=item xsl:fallback			no

Not supported yet.

=item xsl:for-each			limited

Attribute 'select' functions as well as with
xsl:value-of

Not supported yet:
- xsl:sort in content

=item xsl:if				limited

Identical to xsl:when, but outside xsl:choose context.

=item xsl:import			no

Not supported yet.

=item xsl:include			yes

Takes attribute href, which can be relative-local, 
absolute-local as well as an URL (preceded by
identifier http:).

=item xsl:key				no

Not supported yet.

=item xsl:message			no

Not supported yet.

=item xsl:namespace-alias		no

Not supported yet.

=item xsl:number			no

Not supported yet.

=item xsl:otherwise			yes

Supported.

=item xsl:output			limited

Only the initial xsl:output element is used.  The "text" output method
is not supported, but shouldn't be difficult to implement.  Only the
"doctype-public", "doctype-system", "omit-xml-declaration", "method",
and "encoding" attributes have any support.

=item xsl:param			experimental

Synonym for xsl:variable (currently). See xsl:variable for support.

=item xsl:preserve-space		no

Not supported yet. Whitespace is always preserved.

=item xsl:processing-instruction	yes

Supported.

=item xsl:sort				no

Not supported yet.

=item xsl:strip-space			no

Not supported yet. No whitespace is stripped.

=item xsl:stylesheet			limited

Minor namespace support: other namespace than 'xsl:' for xsl-commands
is allowed if xmlns-attribute is present. xmlns URL is verified.
Other attributes are ignored.

=item xsl:template			limited

Attribute 'name' and 'match' are supported to minor extend.
('name' must match exactly and 'match' must match with full
path or no path)

Not supported yet:
- attributes 'priority' and 'mode'

=item xsl:text				yes

Supported.

=item xsl:transform			limited

Synonym for xsl:stylesheet

=item xsl:value-of			limited

Inserts attribute or element values. Limited support:

<xsl:value-of select="."/>

<xsl:value-of select="/root-elem"/>

<xsl:value-of select="elem"/>

<xsl:value-of select="//elem"/>

<xsl:value-of select="elem[n]"/>

<xsl:value-of select="//elem[n]"/>

<xsl:value-of select="@attr"/>

<xsl:value-of select="text()"/>

<xsl:value-of select="processing-instruction()"/>

<xsl:value-of select="comment()"/>

and combinations of these.

Not supported yet:
- attribute 'disable-output-escaping'

=item xsl:variable			partial
or from literal text in the stylesheet.

=item xsl:when				limited

Only inside xsl:choose. Limited test support:

<xsl:when test="@attr='value'">

<xsl:when test="elem='value'">

<xsl:when test="path/[@attr='value']">

<xsl:when test="path/[elem='value']">

<xsl:when test="path">

path is supported to the same extend as with xsl:value-of

=item xsl:with-param			experimental

It is currently not functioning. (or is it?)

=back

=head1 SUPPORT

General information, bug reporting tools, the latest version, mailing
lists, etc. can be found at the XML::XSLT homepage:

  http://xmlxslt.sourceforge.net/

=head1 DEPRECATIONS

Methods and interfaces from previous versions that are not documented in this
version are deprecated.  Each of these deprecations can still be used
but will produce a warning when the deprecation is first used.  You
can use the old interfaces without warnings by passing C<new()> the
flag C<use_deprecated>.  Example:

 $parser = XML::XSLT->new($xsl, "FILE",
                          use_deprecated => 1);

The deprecated methods will disappear by the time a 1.0 release is made.

The deprecated methods are :

=over 2

=item  output_string      

use toString instead

=item  result_string      

use toString instead

=item  output             

use toString instead

=item  result             

use toString instead

=item  result_mime_type   

use media_type instead

=item  output_mime_type   

use media_type instead

=item  result_tree        

use to_dom instead

=item  output_tree        

use to_dom instead

=item  transform_document 

use transform instead

=item  process_project    

use process instead

=item open_project

use C<Source> argument to B<new()> and B<transform> instead.

=item print_output

use B<serve()> instead.

=back

=head1 BUGS

Yes.

=head1 HISTORY

Geert Josten and Egon Willighagen developed and maintained XML::XSLT
up to version 0.22.  At that point, Mark Hershberger started moving
the project to Sourceforge and began working on it with Bron Gondwana.

=head1 LICENCE

Copyright (c) 1999 Geert Josten & Egon Willighagen. All Rights
Reserverd.  This module is free software, and may be distributed under
the same terms and conditions as Perl.

=head1 AUTHORS

Geert Josten <gjosten@sci.kun.nl>

Egon Willighagen <egonw@sci.kun.nl>

Mark A. Hershberger <mah@everybody.org>

Bron Gondwana <perlcode@brong.net>

Jonathan Stowe <jns@gellyfish.com>

=head1 SEE ALSO

L<XML::DOM>, L<LWP::Simple>, L<XML::Parser>

=cut

Filename: $RCSfile: XSLT.pm,v $
Revision: $Revision: 1.25 $
   Label: $Name:  $

Last Chg: $Author: gellyfish $ 
      On: $Date: 2004/02/19 08:38:40 $

  RCS ID: $Id: XSLT.pm,v 1.25 2004/02/19 08:38:40 gellyfish Exp $
    Path: $Source: /cvsroot/xmlxslt/XML-XSLT/lib/XML/XSLT.pm,v $
