package XML::XPathScript;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: a Perl framework for XML stylesheets
$XML::XPathScript::VERSION = '2.00';
use strict;
use warnings;
use Carp;


sub current {
    croak 'Wrong context for calling current()'
        unless defined $XML::XPathScript::current;

    return $XML::XPathScript::current;
}


sub interpolation {
    my $self = shift;
    return $self->interpolating( @_ );
}

sub interpolating {
    my $self=shift;

    if ( @_ ) {
        $self->processor->set_interpolation( 
            $self->{interpolating} = shift
        );
    }

    return $self->{interpolating} || 0;
}


sub interpolation_regex {
    my $self = shift;

    if ( my $regex = shift ) {
        $self->processor->set_interpolation_regex( 
            $self->{interpolation_regex} = $regex
        )
    }

    return $self->{interpolation_regex};
}



sub binmode {
    my ($self)=@_;
    $self->{binmode}=1;
    $self->{processor}->enable_binmode;
    binmode ORIGINAL_STDOUT if (! defined $self->{printer});
    return;
}


use vars qw( $XML_parser $debug_level );

use Symbol;
use File::Basename;
use XML::XPathScript::Processor;
use XML::XPathScript::Template;

our $XML_parser = 'XML::LibXML';

my %use_parser = (
    'XML::LibXML' => 'use XML::LibXML',
    'XML::XPath' => <<'END_USE',
			use XML::XPath 1.0;
			use XML::XPath::XMLParser;
			use XML::XPath::Node;
			use XML::XPath::NodeSet;
			use XML::Parser;
END_USE
);

die "parser $XML_parser unknown\n" unless $use_parser{$XML_parser};
eval $use_parser{$XML_parser}.";1" 
    or die "couldn't import $XML_parser";

# internal variable for debugging information. 
# 0 is total silence and 10 is complete verbiage
$debug_level = 0;

sub import
{
    my $self = shift @_;

    if ( grep { $_ eq 'XML::XPath' } @_ ) {
        $XML::XPathScript::XML_parser = 'XML::XPath';
    }
    elsif ( grep { $_ eq 'XML::LibXML' } @_ ) {
        $XML::XPathScript::XML_parser = 'XML::LibXML';
    }
    return;
}


sub new {
    my $class = shift;
    die "Invalid hash call to new" if @_ % 2;
    my %params = @_;
    my $self = \%params;
    bless $self, $class;
    $self->{processor} = XML::XPathScript::Processor->new;
    $self->set_xml( $params{xml} ) if $params{xml};

    $self->interpolation( exists $params{interpolation} 
                               ? $params{interpolation} : 1 );

    $self->interpolation_regex( $params{interpolation_regex} 
                                || qr/{(.*?)}/ );



    if (  $XML::XPathScript::XML_parser eq 'XML::XPath' ) {
        require XML::XPath;
        require XML::XPath::XMLParser;
        require XML::XPath::Node;
        require XML::XPath::NodeSet;
        require XML::Parser;
    } 
    else {
        require XML::LibXML;
    }

    croak $@ if $@;
    
    return $self;
}


sub transform {
    my( $self, $xml, $stylesheet, $args ) = @_;
    my $output;
    
    $self->set_xml( $xml ) if $xml;

    if ( $stylesheet ) {
        $self->{compiledstylesheet} = undef;
        $self->{stylesheet} = $stylesheet;
    }

    $self->process( \$output, $args ? @$args : () );

    return $output;
}


sub set_dom {
    my( $self, $dom ) = @_;
    $self->{dom} = $dom;
    $self->{processor}->set_dom( $dom );
    return $self;
}


sub set_xml {
    my( $self, $xml ) = @_;

    $self->{xml} = $xml;

    my $retval = ref $xml ? $self->_set_xml_ref() 
                          : $self->_set_xml_scalar()
                          ;

    $self->{processor}->set_dom( $self->{dom} );
    
    return $retval;

    # FIXME

my $xpath;


	# a third option should be auto, for which we
	# would use the already-defined object
	if( $XML_parser eq 'auto' )
	{
		if (UNIVERSAL::isa($self->{xml},"XML::XPath")) 
		{
			$xpath=$self->{xml};
			$XML_parser = 'XML::XPath';
		}
		elsif(UNIVERSAL::isa($self->{xml},"XML::LibXML" ))
		{
			$xpath=$self->{xml};
			$XML_parser = 'XML::LibXML';
		}
	}

    if (UNIVERSAL::isa($self->{xml},"XML::XPath")) 
	{
		if( $XML_parser eq 'XML::XPath' or $XML_parser eq 'auto' )
		{
			$xpath=$self->{xml};
			$XML_parser = 'XML::XPath';
		}
		else 		# parser if XML::LibXML
		{
			$xpath = XML::LibXML->parse_string( $self->{xml}->toString )->documentElement;
		}
    } 
	elsif (UNIVERSAL::isa($self->{xml},"XML::libXML")) 
	{
		if( $XML_parser eq 'XML::LibXML' or $XML_parser eq 'auto' )
		{
			$xpath=$self->{xml};
			$XML_parser = 'XML::LibXML';
		}
		else 		# parser if xpath
		{
			$xpath = new XML::XPath( xml => $self->{xml}->toString );
		}
    } 
	else
	{
		$XML_parser = 'XML::LibXML' if $XML_parser eq 'auto';

		if (ref($self->{xml})) 
		{
			$xpath= ( $XML_parser eq 'XML::LibXML' ) ? 
			    XML::LibXML->new->parse_fh( $self->{xml} )->documentElement :
				XML::XPath->new(ioref => $self->{xml})
		} 
	}

	$self->{dom} = $xpath;
}

sub _set_xml_ref {
    my $self = shift;
    my $xml = $self->{xml};

    if ( $XML_parser eq 'XML::LibXML' ) {
        if ( $xml->isa( 'XML::LibXML::Document' ) ) {
            $self->{dom} = $xml;
            return;
        }

        if ( $xml->isa( 'XML::LibXML::Node' ) ) {
            my $dom = XML::LibXML::Document->new;
            $dom->setDocumentElement( $xml );
            $self->{dom} = $dom;
            return;
        }
    }
    else {  # XML::XPath
        if ( $xml->isa( 'XML::XPath' ) ) {
            $self->{dom} = $xml;
            return;
        }

        if( $xml->isa( 'XML::XPath::Node' ) ) {
            # evil hack
            my $dom = XML::XPath->new( xml => $xml->toString );
            $self->{dom} = $dom;
            return;
        }
    }

    # try to read it as an io
    $self->{dom} = $XML_parser eq 'XML::LibXML' 
                 ? XML::LibXML->new->parse_fh( $xml )->documentElement 
                 : XML::XPath->new(ioref => $xml)
                 ;

    return;
}

sub _set_xml_scalar {
    my $self = shift;
    my $xml = $self->{xml};

    # is it a file? 
    if( index( $xml, "\n" ) == -1 and        # quick'n'dirty checks
        index( $xml, '<' )  == -1 and        # for non-filename characters
        index( $xml, '>' ) == -1 and -f $xml ) {
        open my $fh, '<', $xml or croak "couldn't open xml file $xml: $!";

        $self->{dom} = $XML_parser eq 'XML::LibXML' 
                     ? XML::LibXML->new->parse_file( $xml )->documentElement
                     : XML::XPath->new( filename => $xml )
                     ;

        return;
    }

    # then it must be a string

    $self->{dom} = $XML_parser eq 'XML::LibXML' 
                 ? XML::LibXML->new->parse_string( $xml )->documentElement 
                 : XML::XPath->new( xml => $xml );

    return;
}


sub set_stylesheet {
    my ( $self, $stylesheet ) = @_;

    $self->{compiledstylesheet} = undef;
    $self->{stylesheet} = $stylesheet;

    $self->compile if $self->{stylesheet};
}


sub process {
    my ($self, $printer, @extravars) = @_;

    do { $$printer="" } if (UNIVERSAL::isa($printer, "SCALAR"));
    $self->{printer}=$printer if $printer;

    croak "xml document not defined" unless $self->{dom};

    # FIXME
	eval { $self->{dom}->ownerDocument->setEncoding( "UTF-8" ) }
		if $XML_parser eq 'XML::LibXML';

	{
		local *ORIGINAL_STDOUT;
		*ORIGINAL_STDOUT = *STDOUT;
   		local *STDOUT;

		# Perl 5.6.1 dislikes closed but tied descriptors (causes SEGVage)
   		*STDOUT = *ORIGINAL_STDOUT if $^V lt v5.7.0; 

	   	tie *STDOUT, __PACKAGE__;
        $self->compile unless $self->{compiledstylesheet};
	   	my $retval = $self->{compiledstylesheet}->( $self, @extravars );
	   	untie *STDOUT;
	   	return $retval;
	}
}


sub extract {
    my ($self,$stylesheet,@includestack) = @_;

    my $filename = $self->{stylesheet_dependencies}[0] || "stylesheet";

    my $contents = $self->read_stylesheet( $stylesheet );

    my @tokens = split /(<%[-=~#@]*|-?%>)/, $contents;

    no warnings qw/ uninitialized /;

    my $script;
    my $line = 1;
    TOKEN:
    while ( @tokens ) {
        my $token = shift @tokens;

        if ( -1 == index $token, '<%' ) {
            $line += $token =~ tr/\n//;
            $token =~ s/\s+$// if  -1 < index $tokens[0], '<%'
                               and -1 < index $tokens[0], '-';
            $token =~ s/\|/\\\|/g;
            # check for include
            $token =~ s{<!--#include.+file=(['"])(.*?)\1.*?-->}
                       { '|);'
                         . $self->include_file( $2, @includestack)
                         . 'print(q|'}seg;
            $script .= 'print(q|'.$token.'|);' if length $token;

            next TOKEN;
        }

        $script .= "\n#line $line $filename\n";

        my $opening_tag = $token;
        my $code;
        my $closing_tag;
        my $level = 1;
        while( @tokens ) {
            my $t = shift @tokens;
            $level++ if -1 < index $t, '<%';
            $level-- if -1 < index $t, '%>';
            if ( $level == 0 ) {
                $closing_tag = $t;
                last;
            }
            $code .= $t;
        }

        die "stylesheet <% %>s are unbalanced: $opening_tag$code\n"
            unless $closing_tag;

        $line += $code =~ tr/\n//;

        if ( -1 < index $opening_tag, '=' ) {
            $script .= 'print( '.$code.' );';
        }
        elsif ( -1 < index $opening_tag, '~' ) {
            $code =~ s/^\s+//; 
            $code =~ s/\s+$//; 
            $script .= 'print $processor->apply_templates( qq<'. $code .'> );';
        }
        elsif( -1 < index $opening_tag, '#' ) {
            # do nothing
        }
        elsif( -1 < index $opening_tag, '@' ) {
            $code =~ s/^\s+(\S+).*?\n//;    # strip first line
            my $tag = $1 
                or die "tag name missing in <%\@ %> at line $line\n";

            my $here_delimiter = 'END_TAG';
            while ( $code =~ /$here_delimiter/ ) {
                $here_delimiter .= 'x';
            }
            $script .= <<END_SNIPPET;
\$template->set( $tag => { content => <<'$here_delimiter' } );
$code
$here_delimiter
END_SNIPPET
        }
        else {
                    # always add a ';', just in case
            $script .= $code . ';';
        }

        if ( -1 < index $closing_tag, '-' ) {
            $tokens[0] =~ s/^\s*//;
            my $temp = $&;
            $line += $temp =~ tr/\n//;
        }
    }

    return $script;

    # FIXME not needed anymore
    # <%- -%> magic
    $contents =~ s#(\s+)<%-([=~]?)#<%$2$1#gs;
    $contents =~ s#-%>(\s+)#$1%>#gs;

    # <%~ %> magic
    $contents =~ s#<%~\s+(\S+)\s+%>#<%= apply_templates( qq<$1> ) %>#gs;

    $script="#line 1 $filename\n",
    $line = 1;

    while ($contents =~ /\G(.*?)(<!--#include|<%[=#]?)/gcs) {
        my ($text, $type) = ($1, $2);
        $line += $text =~ tr/\n//; # count \n's in text
        $text =~ s/\|/\\\|/g;
        $script .= "print(q|$text|);";
        $script .= "\n#line $line $filename\n";
        if ($type eq '<%=') {
            $contents =~ /\G(.*?)%>/gcs || die "No terminating '%>' after line $line";
            my $perl = $1;
            $script .= "print( $perl );\n";
            $line += $perl =~ tr/\n//;
        }
        elsif ($type eq '<!--#include') {
            my %params;
            while ($contents =~ /\G(\s+(\w+)\s*=\s*(["'])([^\3]*?)\3|\s*-->)/gcs) {
                last if $1 eq '-->';
                $params{$2} = $4 if (defined $2);
            }

			die "No matching file attribute in #include at line $line"
				unless $params{file};

            no warnings qw/ uninitialized /;
            $script .= $self->include_file($params{file},@includestack);
        }
        else {
            $contents =~ /\G(.*?)%>/gcs || die "No terminating '%>' after line $line";
            my $perl = $1;
	    if( $type ne '<%#' ) {
		    $perl =~ s/;?$/;/s; # add on ; if its missing. As in <% $foo = 'Hello' %>
		    $script .= $perl;
	    }
            $line += $perl =~ tr/\n//;
        }
    }

    if ($contents =~ /\G(.+)/gcs) {
        my $text = $1;
        $text =~ s/\|/\\\|/g;
        $script .= "print(q|$text|);";
    }

    return $script;
}


sub read_stylesheet
{
	my( $self, $stylesheet ) = @_;
	
	# $stylesheet can be a filehandler
	# or a string
    if( ref($stylesheet) ) {
        local $/;
        return <$stylesheet>;
    }
    else {
        return $stylesheet;
    }
	
}


sub include_file {
    my ($self, $filename, @includestack) = @_;

    if ( $filename !~ m#^\.?/# ) {
        # We guarantee that all values we insert into @includestack begin
        # either with "/" or "./". This allows us to do the relative
        # directory thing, and at the same time we get to safely ignore
        # bizarre URIs inserted by inheriting classes.

        my $reldir = $includestack[0] && $includestack[0] =~ m#^\.?/#
                   ? dirname($includestack[0]) 
                   : '.'
                   ;

        $filename = "$reldir/$filename";
    }
	
	# are we going recursive?
    if ( grep { $_ eq $filename } @includestack ) {
        warn 'loop detected in stylesheet include chain: ',
                join( ' => ', reverse(@includestack), $filename ), "\n";
        return undef;
    }

    my $stylesheet;
    unless ( $stylesheet = $self->{stylesheet_cache}{$filename} ) {
        open my $fh, '<', $filename 
            or Carp::croak "Can't read include file '$filename': $!";
        $stylesheet = $self->{stylesheet_cache}{$filename} 
                    = $self->read_stylesheet( $fh );
    }

    return $self->extract($stylesheet, $filename, @includestack);
}



# Internal documentation: the return value is an anonymous sub whose
# prototype is
#     &$compiledfunc($xpathscriptobj, $val1, $val2,...);

sub compile {
    my ($self,@extravars) = @_;

    $self->{compiledstylesheet} = undef;

    my $stylesheet;
    $self->{stylesheet_cache} = {};

    if (exists $self->{stylesheet}) {
		$stylesheet=$self->{stylesheet};
    } 
	elsif (exists $self->{stylesheetfile}) {
		# This hack fails if $self->{stylesheetfile} contains
		# double quotes.  I think we can ignore this and get
		# away.
		$stylesheet=qq:<!--#include file="$self->{stylesheetfile}" -->:;
    } 
	else {
		die "Cannot compile without a stylesheet\n";
    };

    my $script = $self->extract($stylesheet);

    my $package=gen_package_name();

	my $extravars = join ',', @extravars;

    my $processor = $self->{processor};

    # needs to be eval'ed first for the constants
    # to be seen
    eval "package $package;"
        ."\$processor->import_functional();";
	
	my $eval = <<EOT;
		    package $package;
		    no strict;   # Don't moan on sloppyly
		    no warnings; # written stylesheets
			
			use $XML_parser;  

		    sub {
		    	my (\$self, $extravars ) = \@_;
                my \$processor = processor();
				local \$XML::XPathScript::current=\$self;
		    	my \$t = \$processor->{template} 
                            = XML::XPathScript::Template->new();
                my \$template = \$t;
                local \$XML::XPathScript::trans = \$t;
                #\$processor->{doc} = \$self->{dom};
                #\$processor->{parser} = '$XML_parser';
                #\$processor->{binmode} = \$self->{binmode};
                #\$processor->{is_interpolating} = \$self->interpolation;
                #\$processor->{interpolation_regex} = \$self->interpolation_regex;

				$script
		    }
EOT

	#warn "script ready for compil: $eval";
    local $^W;
	$self->debug( 10, "Compiling code:\n $eval" );
    my $retval = eval $eval;
    die $@ unless defined $retval;

    return $self->{compiledstylesheet} = $retval;
}



sub print {
    no warnings qw/ uninitialized /;
    my ($self, @text)=@_;
    my $printer=$self->{printer};

    if (!defined $printer) {
	    print ORIGINAL_STDOUT @text;
    } elsif (ref($printer) eq 'CODE') {
	    $printer->(@text);
    } elsif (UNIVERSAL::isa($printer, 'SCALAR')) {
	    $$printer.= join '', @text;
    } else {
	    local $\=undef;
	    print $printer @text;
    };

    return;
}


#  $self->debug( $level, $message )
#	Display debugging information

sub debug {
	warn $_[2] if $_[1] <= $debug_level;
}


sub get_stylesheet_dependencies {
    my $self = shift;
    $self->compile unless $self->{compiledstylesheet};
    return sort keys %{$self->{stylesheet_cache}};
}


sub processor {
    return $_[0]->{processor};
}


do {
my $uniquifier;
sub gen_package_name {
    $uniquifier++;
    return "XML::XPathScript::STYLESHEET$uniquifier";
}
};


sub document {
    # warn "Document function called\n";
    my( $self, $uri ) = @_;
	  
    my( $results, $parser );	
	if( $XML_parser eq 'XML::XPath' ) {
		my $xml_parser = XML::Parser->new(
				ErrorContext => 2,
				Namespaces => $XML::XPath::VERSION < 1.07 ? 1 : 0,
				# ParseParamEnt => 1,
				);
	
		$parser = XML::XPath::XMLParser->new(parser => $xml_parser);
		$results = XML::XPath::NodeSet->new();
	} 
	elsif ( $XML_parser eq 'XML::LibXML' ) {
		$parser = XML::LibXML->new;
		$results = XML::LibXML::Document->new;
	}
	else {
		$self->die( "xml parser not valid: $XML_parser" );
	}

	
    my $newdoc;
	# TODO: must handle axkit: scheme a little more cleverly
    if ($uri =~ /^\w\w+:/ and $uri !~ /^axkit:/ ) { # assume it's scheme://foo uri
        eval {
         	$self->debug( 5, "trying to parse $uri" );
			eval "use LWP::Simple";
            $newdoc = $parser->parse_string( LWP::Simple::get( $uri ) );
            $self->debug( 5, "Parsed OK into $newdoc\n" );
        };
        if (my $E = $@) {
			$self->debug("Parse of '$uri' failed: $E" );
        }
    }
    else {
        $self->debug(3, "Parsing local: $uri\n");
		if( $XML_parser eq 'XML::LibXML' ) {
        	$newdoc = $parser->parse_file( $uri );
		} elsif( $XML_parser eq 'XML::XPath' ) {
			$newdoc = XML::XPath->new( filename => $uri );
		}
		else { die "invalid parser: $XML_parser\n"; }
    }

	if( $newdoc ) {
		if( $XML_parser eq 'XML::LibXML' ) {
			$results = $newdoc->documentElement();
		} 
		elsif( $XML_parser eq 'XML::XPath' ) {
			$results = $newdoc->findnodes('/')->[0]->getChildNodes->[0];
		}
	}
	
    $self->debug(8, "XPathScript: document() returning");
    return $results;
}

sub TIEHANDLE { my $self = ''; bless \$self, $_[0] }
sub PRINT {
	my $self = shift;
	return XML::XPathScript::current()->print( @_ );
}
sub BINMODE {
    return XML::XPathScript::current()->binmode( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript - a Perl framework for XML stylesheets

=head1 VERSION

version 2.00

=head1 SYNOPSIS

  use XML::XPathScript;

  # the short way
  my $xps = XML::XPathScript->new;
  my $transformed = $xps->transform( $xml, $stylesheet );

  # having the output piped to STDOUT directly
  my $xps = XML::XPathScript->new( xml => $xml, stylesheet => $stylesheet );
  $xps->process;

  # caching the compiled stylesheet for reuse and
  # outputting to multiple files
  my $xps = XML::XPathScript->new( stylesheetfile => $filename )
  foreach my $xml (@xmlfiles) {
    my $transformed = $xps->transform( $xml );

    # do stuff with $transformed ...
  };

  # Making extra variables available to the stylesheet dialect:
  my $xps = XML::XPathScript->new;
  $xps->compile( qw/ $foo $bar / );

           # in stylesheet, $foo will be set to 'a'
           # and $bar to 'b'
  $xps->transform( $xml, $stylesheet, [ 'a', 'b' ] ); 

=head1 DESCRIPTION

XPathScript is a stylesheet language similar in many ways to XSLT (in
concept, not in appearance), for transforming XML from one format to
another (possibly HTML, but XPathScript also shines for non-XML-like
output).

Like XSLT, XPathScript offers a dialect to mix verbatim portions of
documents and code. Also like XSLT, it leverages the powerful
``templates/apply-templates'' and ``cascading stylesheets'' design
patterns, that greatly simplify the design of stylesheets for
programmers. The availability of the I<XPath> query language inside
stylesheets promotes the use of a purely document-dependent,
side-effect-free coding style. But unlike XSLT which uses its own
dedicated control language with an XML-compliant syntax, XPathScript
uses Perl which is terse and highly extendable.

The result of the merge is an extremely powerful tool for rendering
complex XML documents into other formats. Stylesheets written in
XPathScript are very easy to create, extend and reuse, even if they
manage hundreds of different XML tags.

=head1 STYLESHEET WRITER DOCUMENTATION

If you are interested to write stylesheets, refers to the
B<XML::XPathScript::Stylesheet> manpage. You might also want 
to take a peek at the manpage of B<xpathscript>, a program 
bundled with this module to perform XPathScript transformations
via the command line. 

=head1 STYLESHEET UTILITY METHODS 

Those methods are meants to be used from within a stylesheet.

=head2 current

    $xps = XML::XPathScript->current

This class method returns
the stylesheet object currently being applied. This can be called from
anywhere within the stylesheet, except a BEGIN or END block or
similar. B<Beware though> that using the return value for altering (as
opposed to reading) stuff from anywhere except the stylesheet's top
level is unwise.

=head2 interpolation 

    $interpolate = $XML::XPathScript::current->interpolation
    $interpolate = $XML::XPathScript::current->interpolation( $boolean )

Gets (first call form) or sets (second form) the XPath interpolation
boolean flag. If true, values set in C< pre > and C< post >
may contain expressions within curly braces, that will be
interpreted as XPath expressions and substituted in place.

For example, when interpolation is on, the following code

    $template->set( link => { pre  => '<a href="{@url}">',
                              post => '</a>'               } );

is enough for rendering a C<< <link> >> element as an HTML hyperlink.
The interpolation-less version is slightly more complex as it requires a
C<testcode>:

   sub link_testcode  {
      my ($node, $t) = @_;
      my $url = $node->findvalue('@url');
      $t->set({ pre  => "<a href='$url'>",
                post => "</a>"             });
	  return DO_SELF_AND_KIDS();
   };

Interpolation is on by default. 

=head2 interpolation_regex

    $regex = $XML::XPathScript::current->interpolation_regex
    $XML::XPathScript::current->interpolation_regex( $regex )

Gets or sets the regex to use for interpolation. The value to be 
interpolated must be capture by $1. 

By default, the interpolation regex is qr/{(.*?)}/.

Example:

    $XML::XPathScript::current->interpolation_regex( qr#\|(.*?)\|# );

    $template->set( bird => { pre => '|@name| |@gender| |@type|' } );

=head2 binmode

Declares that the stylesheet output is B<not> in UTF-8, but instead in
an (unspecified) character encoding embedded in the stylesheet source
that neither Perl nor XPathScript should have any business dealing
with. Calling C<< XML::XPathScript->current()->binmode() >> is an
B<irreversible> operation with the consequences outlined in L</The
Unicode mess>.

=head1 TECHNICAL DOCUMENTATION

The rest of this POD documentation is B<not> useful to programmers who
just want to write stylesheets; it is of use only to people wanting to
call existing stylesheets or more generally embed the XPathScript
engine into some wider framework.

I<XML::XPathScript> is an object-oriented class with the following features:

=over

=item *

an I<embedded Perl dialect> that allows the merging of the stylesheet
code with snippets of the output document. Don't be afraid, this is
exactly the same kind of stuff as in I<Text::Template>, I<HTML::Mason>
or other similar packages: instead of having text inside Perl (that
one I<print()>s), we have Perl inside text, with a special escaping
form that a preprocessor interprets and extracts. For XPathScript,
this preprocessor is embodied by the I<xpathscript> shell tool (see
L</xpathscript Invocation>) and also available through this package's
API;

=item *

a I<templating engine>, that does the apply-templates loop, starting
from the top XML node and applying templates to it and its subnodes as
directed by the stylesheet.

=back

When run, the stylesheet is expected to fill in the I<template object>
$template, which is a lexically-scoped variable made available to it at
preprocess time.

=head1 METHODS

=head2 new

    $xps = XML::XPathScript->new( %arguments )

Creates a new XPathScript translator. The recognized named arguments are

=over

=item xml => $xml

$xml is a scalar containing XML text, or a reference to a filehandle
from which XML input is available, or an I<XML::XPath> or
I<XML::libXML> object.

An XML::XPathscript object without an I<xml> argument
to the constructor is only able to compile stylesheets (see
L</SYNOPSIS>).

=item stylesheet => $stylesheet

$stylesheet is a scalar containing the stylesheet text, or a reference
to a filehandle from which the stylesheet text is available.  The
stylesheet text may contain unresolved C<< <!--#include --> >>
constructs, which will be resolved relative to ".".

=item stylesheetfile => $filename

Same as I<stylesheet> but let I<XML::XPathScript> do the loading
itself.  Using this form, relative C<< <!--#include --> >>s in the
stylesheet file will be honored with respect to the dirname of
$filename instead of "."; this provides SGML-style behaviour for
inclusion (it does not depend on the current directory), which is
usually what you want.

=item compiledstylesheet => $function

Re-uses a previous return value of I<compile()> (see L</SYNOPSIS> and
L</compile>), typically to apply the same stylesheet to several XML
documents in a row.

=item interpolation_regex => $regex

Sets the interpolation regex. Whatever is
captured in $1 will be used as the xpath expression. 
Defaults to qr/{(.*?)}/.

=back

=head2 transform

    $xps->transform( $xml, $stylesheet, \@args )

Transforms the document $xml with the $stylesheet (optionally passing to
the stylesheet the argument array @args) and returns the result.

If the passed $xml or $stylesheet is undefined, the previously loaded xml 
document or stylesheet is used.

E.g.,

    # vanilla-flavored transformation
    my $xml = '<doc>...</doc>';
    my $stylesheet = '<% ... %>';
    my $transformed = $xps->transform( $xml, $stylesheet );

    # transform many documents
    $xps->set_stylesheet( $stylesheet );
    for my $xml ( @xml_documents ) {
        my $transformed = $xps->transform( $xml );
        # do stuff with $transformed ...
    }
    
    # do many transformation of a document
    $xps->set_xml( $xml );
    for my $stylesheet ( @stylesheets ) {
        my $transformed = $xps->transform( undef, $stylesheet );
        # do stuff with $transformed ...
    }

=head2 set_dom

    $xps->set_dom( $dom )

Set the DOM of the document to process. I<$dom>
must be a node object of one of the supported 
parsers (XML::LibXML, XML::XPath, B::XPath).

=head2 set_xml

    $xps->set_xml( $xml )

Sets the xml document to $xml. $xml can be a file, a file handler 
reference, a string, or a XML::LibXML or XML::XPath node.

=head2 set_stylesheet

    $xps->set_stylesheet( $stylesheet )

Sets the processor's stylesheet to $stylesheet.

=head2 process

    $xps->process
    $xps->process( $printer )
    $xps->process( $printer, @varvalues )

Processes the document and stylesheet set at construction time, and
prints the result to STDOUT by default. If $printer is set, it must be
either a reference to a filehandle open for output, or a reference to
a string, or a reference to a subroutine which does the output, as in

    open my $fh, '>', 'transformed.txt' 
        or die "can't open file transformed.txt: $!";
    $xps->process( $fh );

    my $transformed;
    $xps->process( \$transformed );

    $xps->process( sub { 
        my $output = shift;
        $output =~ y/<>/%%/;
        print $output;
    } );

If the stylesheet was I<compile()>d with extra I<varname>s, then the
calling code should call I<process()> with a corresponding number of
@varvalues. The corresponding lexical variables will be set
accordingly, so that the stylesheet code can get at them (looking at
L</SYNOPSIS>) is the easiest way of getting the meaning of this
sentence).

=head2 extract

    $xps->extract( $stylesheet )
    $xps->extract( $stylesheet, $filename )
    $xps->extract( $stylesheet, @includestack ) # from include_file() only

The embedded dialect parser. Given $stylesheet, which is either a
filehandle reference or a string, returns a string that holds all the
code in real Perl. Unquoted text and C<< <%= stuff %> >> constructs in
the stylesheet dialect are converted into invocations of I<<
XML::XPathScript->current()->print() >>, while C<< <% stuff %> >>
constructs are transcripted verbatim.

C<< <!-- #include --> >> constructs are expanded by passing their
filename argument to L</include_file> along with @includestack (if any)
like this:

   $self->include_file($includefilename,@includestack);

@includestack is not interpreted by I<extract()> (except for the first
entry, to create line tags for the debugger). It is only a bandaid for
I<include_file()> to pass the inclusion stack to itself across the
mutual recursion existing between the two methods (see
L</include_file>).  If I<extract()> is invoked from outside
I<include_file()>, the last invocation form should not be used.

This method does a purely syntactic job. No special framework
declaration is prepended for isolating the code in its own package,
defining $t or the like (L</compile> does that). It may be overriden
in subclasses to provide different escape forms in the stylesheet
dialect.

=head2 read_stylesheet

    $string = $xps->read_stylesheet( $stylesheet )

Read the $stylesheet (which can be a filehandler or a string). 
Used by I<extract> and exists such that it can be overloaded in
I<Apache::AxKit::Language::YPathScript>.

=head2 include_file

    $xps->include_file( $filename )
    $xps->include_file( $filename, @includestack )

Resolves a C<< <!--#include file="foo" --> >> directive on behalf of
I<extract()>, that is, returns the script contents of
I<$filename>. The return value must be de-embedded too, which means
that I<extract()> has to be called recursively to expand the contents
of $filename (which may contain more C<< <!--#include --> >>s etc.)

$filename has to be slash-separated, whatever OS it is you are using
(this is the XML way of things). If $filename is relative (i.e. does
not begin with "/" or "./"), it is resolved according to the basename
of the stylesheet that includes it (that is, $includestack[0], see
below) or "." if we are in the topmost stylesheet. Filenames beginning
with "./" are considered absolute; this gives stylesheet writers a way
to specify that they really really want a stylesheet that lies in the
system's current working directory.

@includestack is the include stack currently in use, made up of all
values of $filename through the stack, lastly added (innermost)
entries first. The toplevel stylesheet is not in @includestack
(that is, the outermost call does not specify an @includestack).

This method may be overridden in subclasses to provide support for
alternate namespaces (e.g. ``axkit://'' URIs).

=head2 I<compile()>

=head2 I<compile(varname1, varname2,...)>

Compiles the stylesheet set at I<new()> time and returns an anonymous
CODE reference. 

I<varname1>, I<varname2>, etc. are extraneous arguments that will be
made available to the stylesheet dialect as lexically scoped
variables. L</SYNOPSIS> shows how to use this feature to pass variables
to AxKit XPathScript stylesheets, which explains this
feature better than a lengthy paragraph would do.

The return value is an opaque token that encapsulates a compiled
stylesheet.  It should not be used, except as the
I<compiledstylesheet> argument to I<new()> to initiate new objects and
amortize the compilation time.  Subclasses may alter the type of the
return value, but will need to overload I<process()> accordingly of
course.

The I<compile()> method is idempotent. Subsequent calls to it will
return the very same token, and calls to it when a
I<compiledstylesheet> argument was set at I<new()> time will return
said argument.

=head2 print

    $xps->print($text)

Outputs a chunk of text on behalf of the stylesheet. The default
implementation is to use the second argument to L</process>. 
Overloading this
method in a subclass provides yet another method to redirect output.

=head2 get_stylesheet_dependencies

    @files = $xps->get_stylesheet_dependencies

Returns the files the loaded stylesheet depends on (i.e., has been
included by the stylesheet or one of its includes). The order in which
files are returned by the function has no special signification.

=head2 processor

    $processor = $xps->processor

Returns the processor object associated with I<$xps>.

=head1 FUNCTIONS

#=head2 gen_package_name
#
#Generates a fresh package name in which we would compile a new
#stylesheet. Never returns twice the same name.

=head2 document

    $nodeset = $xps->document( $uri )

Reads XML given in $uri, parses it and returns it in a nodeset.

=head1 SEE ALSO

L<XML::XPathScript::Stylesheet>, L<XML::XPathScript::Processor>, 
L<XML::XPathScript::Template>, L<XML::XPathScript::Template::Tag>

Guide of the original Axkit XPathScript: 
http://axkit.org/wiki/view/AxKit/XPathScriptGuide

XPath documentation from W3C:
http://www.w3.org/TR/xpath

Unicode character table:
http://www.unicode.org/charts/charindex.html

=head1 AUTHORS

=over 4

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Dominique Quatravaux <domq@cpan.org>

=item *

Matt Sergeant <matt@sergeant.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2008, 2007 by Matt Sergeant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
