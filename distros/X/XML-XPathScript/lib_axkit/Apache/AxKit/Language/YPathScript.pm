package Apache::AxKit::Language::YPathScript;

use strict;


=head1 NAME

Apache::AxKit::Language::YPathScript - An XML Stylesheet Language

=head1 SYNOPSIS

  AxAddStyleMap "application/x-xpathscript => \
        Apache::AxKit::Language::YPathScript"

=head1 DESCRIPTION

YPathScript is a fork of the original AxKit's XPathScript using 
XML::XPathScript as its transforming engine. 

As it is mostly 
backward compatible with the classic Axkit XPathScript module, 
the definitive reference for 
XPathScript, located at http://axkit.org/docs/xpathscript/guide.dkb,
also applies to YPathScript, excepts for the differences listed in the
sections below.

=head1 PRE-DEFINED STYLESHEET VARIABLES AND FUNCTIONS

=head2 VARIABLES

=over

=item $r

A copy of the Apache::AxKit::request object -- which is itself a wrapper around
the Apache::request object -- tied to the current document.

	<%	%args = $r->args() %>
	<p>args: <%= join ' : ', map "$_ => $args{$_}", keys %args %></p>

=back 

=head2 FUNCTIONS

=over

=item $node = XML::XPathScript::current->document( $uri )

Fetch the xml document located at $uri and return it as a dom node.

=back

=cut

use Apache;
use Apache::File;
use Apache::AxKit::Provider;
use Apache::AxKit::Language;
use Apache::AxKit::Cache;
use Apache::AxKit::Exception;
use Apache::AxKit::CharsetConv;
use XML::XPathScript; 

use vars qw( @ISA $VERSION $stash );
@ISA = qw/ Apache::AxKit::Language XML::XPathScript /;

$VERSION = '1.53';

=head2 Functions

=over

=item $xps = new Apache::AxKit::Language::YPathScript($xml_provider, $style_provider)

Construct a new YPathScript language interpreter out of the provided
providers.

=cut

sub new
{
	my( $class, $xml_provider, $style_provider ) = @_;
	
	my $self = XML::XPathScript::new( $class, 
							xml_provider => $xml_provider, 
	                        style_provider => $style_provider );

	return $self;
}

=item	$rc = handler( $class, $request, $xml_provider, $style_provider )

	The handler function called by Apache. 

=cut

sub handler 
{
	AxKit::Debug( 10, "this is Apache::AxKit::Language::YPathScript version $VERSION" );
	
    my ( $class, $r, $xml_provider, $style_provider) = @_;

	my $xps = new Apache::AxKit::Language::YPathScript( $xml_provider, $style_provider );

    $xps->{local_ent_handler} = $xml_provider->get_ext_ent_handler();

    AxKit::Debug(6, "YPathScript: Getting XML Source");
  
	# try to find the XML document
    my $xml = $r->pnotes('dom_tree')                       # dom_tree is an XML::LibXML DOM
	   	     	|| $r->pnotes('xml_string')
		     	|| get_source_tree($xml_provider);
   
    AxKit::Debug(7, "XML retrieved: $xml\n");

    $xps->set_xml( $xml );

	# $xpath->set_context($source_tree);   what does this do?

	AxKit::Debug( 6, "Recompiling stylesheet\n" );
	$xps->set_stylesheet( get_source_tree($style_provider) );
	
	#$xps->get_stylesheet( $style_provider );

    AxKit::Debug(7, "Running YPathScript script\n");
    local $^W;
	$xps->compile( '$r' );
	return $xps->process( '', $r );
}

=item $file_content = I<include_file( $filename )>

=item $file_content = I<include_file( $filename, @includestack )>

Overloaded from XML::XPathScript in order to provide URI-based
stylesheet inclusions: $filename may now be any AxKit URI.  The AxKit
language class drops support for plain filenames that exists in the
ancestor class: this means that include directives like

   <!-- #include file="/some/where.xps" -->

in existing stylesheets should be turned into

   <!-- #include file="file:///some/where.xps" -->

in order to work with AxKit.

=cut

sub include_file 
{
    my ($self, $filename, @includestack) = @_;
	
	my $provider = $self->{xml_provider};

    AxKit::Debug(10, "YPathScript: entering include_file ($filename)");

    # return if already included
    my $key = $provider->key();
    return '' if grep $_ eq $filename, @{$stash->{$key}{includes}};

    push @{$stash->{$key}{includes}}, $filename;
    
    my $apache = $provider->apache_request;
    my $sub = $apache->lookup_uri( $filename );
    local $AxKit::Cfg = Apache::AxKit::ConfigReader->new( $sub );
    
    my $inc_provider = Apache::AxKit::Provider->new_style_provider( $sub );
	
	AxKit::Debug( 10, "File: $filename, Sub: $sub, $inc_provider: $inc_provider" );
    
    my $contents;
    eval 
	{ 
        my $fh = $inc_provider->get_fh();
        local $/;
        $contents = <$fh>;
    };
    if ($@) 
	{
		eval{ $contents = ${ $inc_provider->get_strref() } };
		if( $@ ){ AxKit::Debug( 10, "couldn't include $filename" ) }
    }
    
    my $r = AxKit::Apache->request();
    if (my $charset = $r->dir_config('AxOutputCharset')) {
        
        AxKit::Debug(8, "XPS: got charset: $charset");
        
        my $map = Apache::AxKit::CharsetConv->new($charset, "utf-8") 
					or die "No such charset: $charset";

        $contents = $map->convert($contents);
    }
    
    $stash->{$key}{includes} = [];
    
    AxKit::Debug(10, "YPathScript: extracting from '$key' contents: $contents\n");

	return $self->extract( $inc_provider, @includestack );
}

=item 	$doc = get_source_tree( $xml_provider  )

Read an XML document from the provider and return it as a string.

=cut

sub get_source_tree 
{
    my $provider = shift;
    my $xml;

    AxKit::Debug(7, "YPathScript: reparsing file");

    eval 
	{
        my $fh = $provider->get_fh();
        local $/;
        $xml = <$fh>;
        close $fh;
    };
   
	# didn't work? try get_strref
	$xml = $provider->get_strref() if $@;
    
    AxKit::Debug(7, "YPathScript: Returning source tree");
    return $xml;
}

=item $string = I<read_stylesheet( $stylesheet )>

Retrieve and return the $stylesheet (which can be a filehandler or a string) as a string. 

=cut

sub read_stylesheet
{
	my ( $self, $stylesheet ) = @_;
	my $contents;

	if( ref( $stylesheet ) ) {
    	eval {	 
			my $fh = $stylesheet->get_fh();
			local $/;
			$contents = <$fh>;
		};
		$self->debug( 7, "wasn't able to extract $stylesheet: $@" ) if $@;
	}
	else {
		$contents = $stylesheet;  # it's a string
	}
    
    my $r = AxKit::Apache->request();
    if (my $charset = $r->dir_config('AxOutputCharset')) {
        
        $self->debug(8, "XPS: got charset: $charset");
        
        my $map = Apache::AxKit::CharsetConv->new($charset, "utf-8") 
			or $self->die( "No such charset: $charset" );
        $contents = $map->convert($contents);
    }

	return $contents;	
}

=item $self->debug( $level, $message )

Print $message if the requested debug level 
is equal or smaller than $level.

=cut

sub debug{ shift; AxKit::Debug( @_ ) }

=item $self->die( $suicide_note )

Print the $suicide_note and exit;

=cut

sub die{ die @_ }

=item  $nodeset = $self->document( $uri )

Read XML document located at $uri, parse it and return it in a node object.

The $uri can be specified using the regular schemes ('http://foo.org/bar.xml', 
'ftp://foo.org/bar.xml'), or the Axkit scheme ('axkit://baz.xml'), or as
a local file ('/home/web/foo.xml', './foo.xml' ).

=cut

sub document {
    # warn "Document function called\n";
    return unless $Apache::AxKit::Language::YPathScript::local_ent_handler;
    my( $self, $uri ) = @_;

	my( $results, $parser );	
	if( $XML::XPathScript::XML_parser eq 'XML::XPath' ) {
		my $xml_parser = XML::Parser->new(
				ErrorContext => 2,
				Namespaces => $XML::XPath::VERSION < 1.07 ? 1 : 0,
				# ParseParamEnt => 1,
				);
	
		$parser = XML::XPath::XMLParser->new(parser => $xml_parser);
		$results = XML::XPath::NodeSet->new();
	} else {
		$parser = XML::LibXML->new();
		$results = XML::LibXML::Node->new();
	}

    my $newdoc;
    if ($uri =~ /^axkit:/) {
        $newdoc = $parser->parse( AxKit::get_axkit_uri($uri) );
    }
    elsif ($uri =~ /^\w\w+:/) { # assume it's scheme://foo uri
        eval {
         	$self->debug( 5, "trying to parse $uri" );
            $newdoc = $parser->parse(
                    $Apache::AxKit::Language::YPathScript::local_ent_handler->(
                        undef, undef, $uri
                    )
                );
            $self->debug( 5, warn "Parsed OK into $newdoc\n" );
        };
        if (my $E = $@) {
            if ($E->isa('Apache::AxKit::Exception::IO')) {
                AxKit::Debug(2, $E);
            }
            else {
                throw Apache::AxKit::Exception::Error(-text => "Parse of '$uri' failed: $E");
            };
        }
    }
    else {
        AxKit::Debug(3, "Parsing local: $uri\n");
        
        # create a subrequest, so we get the right AxKit::Cfg for the URI
        my $sub = AxKit::Apache->request->lookup_uri($uri);
        local $AxKit::Cfg = Apache::AxKit::ConfigReader->new($sub);
        
        my $provider = Apache::AxKit::Provider->new_content_provider($sub);
        
        $newdoc = $parser->parse( xml => get_source_tree($provider) );
    }

    $results->push($newdoc) if $newdoc;
    $self->debug(8, "YPathScript: document() returning");
    return $results;
}

'Apache::AxKit::Language::YPathScript';

__END__

=back

=head1 BUGS

Please send bug reports to <bug-xml-xpathscript@rt.cpan.org>,
or via the web interface at 
http://rt.cpan.org/Public/Dist/Display.html?Name=XML-XPathScript .

=head1 AUTHOR 

Yanick Champoux <yanick@cpan.org>

Original Axkit::Apache::AxKit::Language module 
by Matt Sergeant <matt@sergeant.org>

