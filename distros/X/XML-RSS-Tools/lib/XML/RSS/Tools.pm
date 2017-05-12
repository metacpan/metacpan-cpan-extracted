# --------------------------------------------------
#
# XML::RSS::Tools
# Version 0.34
# $Id: Tools.pm 101 2014-05-27 14:25:39Z adam $
#
# Copyright iredale Consulting, all rights reserved
# http://www.iredale.net/
#
# OSI Certified Open Source Software
#
# --------------------------------------------------

package XML::RSS::Tools;

use 5.010;                 # No longer been tested on anything earlier
use utf8;
use strict;                # Naturally
use warnings;              # Naturally
use warnings::register;    # So users can "use warnings 'XML::RSS::Tools'"
use Carp;                  # We're a nice module
use XML::RSS;              # Handle the RSS/RDF files
use XML::LibXML;           # Hand the XML file for XSLT
use XML::LibXSLT;          # Hand the XSL file and do the XSLT
use URI;                   # Deal with URIs nicely
use FileHandle;            # Allow the use of File Handle Objects

our $VERSION = '0.34';

#
#   Tools Constructor
#

sub new {
    my $class = shift;
    my %args   = @_;

    my $object = bless {
        _rss_version    => 0.91,            # We convert all feeds to this version
        _xml_string     => q{},             # Where we hold the input RSS/RDF
        _xsl_string     => q{},             # Where we hold the XSL Template
        _output_string  => q{},             # Where the output string goes
        _transformed    => 0,               # Flag for transformation
        _error_message  => q{},             # Error message
        _uri_url        => q{},             # URI URL
        _uri_file       => q{},             # URI File
        _uri_scheme     => q{},             # URI Scheme
        _xml_catalog    => q{},             # XML Catalog file
        _http_client    => 'auto',          # Which HTTP Client to use
        _proxy_server   => q{},             # A Proxy Server
        _proxy_user     => q{},             # Username on the proxy server
        _proxy_password => q{},             # Password for user on the proxy server
        _debug          => $args{debug} || 0,       # Debug flag
        _auto_wash      => $args{auto_wash} || 1,   # Flag for auto_washing input RSS/RDF
    },
    ref $class || $class;

    if ( $args{version} ) {
        croak "No such version of RSS $args{version}"
            unless set_version( $object, $args{version} );
    }

    if ( $args{http_client} ) {
        croak "Not configured for HTTP Client $args{http_client}"
            unless set_http_client( $object, $args{http_client} );
    }

    if ( $args{xml_catalog} ) {
        croak 'XML Catalog Support not enabled in your version of XML::LibXML'
            if $XML::LibXML::VERSION < 1.53;
        croak "Unable to read XML catalog $args{xml_catalog}"
            unless set_xml_catalog( $object, $args{xml_catalog} );
    }

    return $object;
}

#
#   Output what we have as a string
#
sub as_string {
    my $self = shift;
    my $mode = shift || q{};

    if ($mode) {
        if ( $mode =~ /rss/mxi ) {
            carp 'No RSS File to output'
                if !$self->{_rss_string} && $self->{_debug};
            return $self->{_rss_string};
        }
        elsif ( $mode =~ /xsl/mxi ) {
            carp 'No XSL Template to output'
                if !$self->{_xsl_string} && $self->{_debug};
            return $self->{_xsl_string};
        }
        elsif ( $mode =~ /error/mxi ) {
            if ( $self->{_error_message} ) {
                my $message = $self->{_error_message};
                $self->{_error_message} = q{};
                return $message;
            }
        }
        else {
            croak "Unknown mode: $mode";
        }
    }
    else {
        carp 'Nothing To Output Yet'
            if !$self->{_transformed} && $self->{_debug};
        return $self->{_output_string};
    }
    return;
}

#
#   Set/Read the debug level
#
sub debug {
    my $self  = shift;
    my $debug = shift;
    $self->{_debug} = $debug if defined $debug;
    return $self->{_debug};
}

#
#   Read the auto_wash level
#
sub get_auto_wash {
    my $self = shift;
    return $self->{_auto_wash};
}

#
#   Set the auto_wash level
#
sub set_auto_wash {
    my $self = shift;
    my $wash = shift;
    $self->{_auto_wash} = $wash if defined $wash;
    return $self->{_auto_wash};
}

#
#   Read the HTTP client mode
#
sub get_http_client {
    my $self = shift;
    return $self->{_http_client};
}

#
#   Set which HTTP client to use
#
sub set_http_client {
    my $self   = shift;
    my $client = shift;

    return $self->_raise_error( 'No HTTP Client requested' )
        unless defined $client;
    return $self->_raise_error( "Not configured for HTTP Client $client" )
        unless ( grep {/$client/mx} qw(auto ghttp lwp lite curl) );

    $self->{_http_client} = lc $client;
    return $self->{_http_client};
}

#
#   Get the HTTP proxy
#
sub get_http_proxy {
    my $self = shift;
    my $proxy;

    if ( $self->{_proxy_server} ) {
        $proxy = $self->{_proxy_user} . q{:} . $self->{_proxy_password} . q{@}
            if ( $self->{_proxy_user} && $self->{_proxy_password} );
        $proxy .= $self->{_proxy_server};
        return $proxy;
    }
}

#
#   Set the HTTP proxy
#
sub set_http_proxy {
    my $self = shift;
    my %args = @_;

    $self->{_proxy_server}   = $args{proxy_server};
    $self->{_proxy_user}     = $args{proxy_user};
    $self->{_proxy_password} = $args{proxy_pass};

    return $self;
}

#
#   Get the RSS Version
#
sub get_version {
    my $self = shift;
    return $self->{_rss_version};
}

#
#   Set the RSS Version
#
sub set_version {
    my $self    = shift;
    my $version = shift;

    return $self->_raise_error( 'No RSS version supplied' )
        unless defined $version;
    return $self->_raise_error("No such version of RSS $version")
        unless ( grep {/$version/mx} qw(0 0.9 0.91 0.92 0.93 0.94 1.0 2.0) );

    $self->{_rss_version} = $version;
    if ($version) {
        return $self->{_rss_version};
    }
    else {
        return '0.0';
    }
}

#
#   Get XML Catalog File
#
sub get_xml_catalog {
    my $self = shift;
    return $self->{_xml_catalog};
}

#
#   Set XML catalog file
#
sub set_xml_catalog {
    my $self         = shift;
    my $catalog_file = shift;

    croak 'XML Catalog Support not enabled in your version of XML::LibXML'
        if $XML::LibXML::VERSION < 1.53;

    if ( $self->_check_file( $catalog_file ) ) {
        $self->{_xml_catalog} = $catalog_file;
        return $self;
    }
    else {
        return;
    }
}

#
#   Load an RSS file, and call RSS conversion to standard RSS format
#
sub rss_file {
    my $self      = shift;
    my $file_name = shift;

    if ( $self->_check_file( $file_name ) ) {
        my $fh = FileHandle->new( $file_name, 'r' )
            or croak "Unable to open $file_name for reading";
        $self->{_rss_string} = $self->_load_filehandle( $fh );
        undef $fh;
        $self->_parse_rss_string;
        $self->{_transformed} = 0;
        return $self;
    }
    else {
        return;
    }
}

#
#   Load an XSL file
#
sub xsl_file {
    my $self      = shift;
    my $file_name = shift;

    if ( $self->_check_file( $file_name ) ) {
        my $fh = FileHandle->new( $file_name, 'r' )
            or croak "Unable to open $file_name for reading";
        $self->{_xsl_string} = $self->_load_filehandle( $fh );
        undef $fh;
        $self->{_transformed} = 0;
        return $self;
    }
    else {
        return;
    }
}

#
#   Load an RSS file from a FH, and call RSS conversion to standard RSS format
#
sub rss_fh {
    my $self      = shift;
    my $file_name = shift;

    if ( ref $file_name  eq 'FileHandle' ) {
        $self->{_rss_string} = $self->_load_filehandle( $file_name );
        _parse_rss_string($self);
        $self->{_transformed} = 0;
        return $self;
    }
    else {
        return $self->_raise_error(
            'FileHandle error: No FileHandle Object Passed' );
    }
}

#
#   Load an XSL file from a FH
#
sub xsl_fh {
    my $self      = shift;
    my $file_name = shift;

    if ( ref $file_name eq 'FileHandle' ) {
        $self->{_xsl_string}  = $self->_load_filehandle( $file_name );
        $self->{_transformed} = 0;
        return $self;
    }
    else {
        return $self->_raise_error(
            'FileHandle error: No FileHandle Object Passed' );
    }
}

#
#   Load an RSS file via HTTP and call RSS conversion to standard RSS format
#
sub rss_uri {
    my $self = shift;
    my $uri  = shift;

    $uri = $self->_process_uri( $uri );
    return unless $uri;

    return $self->rss_file( $self->{_uri_file} )
        if ( $self->{_uri_scheme} eq 'file' );

    my $xml = $self->_http_get( $uri );
    return unless $xml;
    $self->{_rss_string} = $xml;
    _parse_rss_string( $self );
    $self->{_transformed} = 0;
    return $self;
}

#
#   Load an XSL file via HTTP
#
sub xsl_uri {
    my $self = shift;
    my $uri  = shift;

    $uri = $self->_process_uri( $uri );
    return unless $uri;

    return $self->xsl_file( $self->{_uri_file} )
        if ( $self->{_uri_scheme} eq 'file' );

    my $xml = $self->_http_get( $uri );
    return unless $xml;
    $self->{_xsl_string}  = $xml;
    $self->{_transformed} = 0;
    return $self;
}

#
#   Parse a string and convert to standard RSS
#
sub rss_string {
    my $self = shift;
    my $xml  = shift;

    return unless $xml;
    $self->{_rss_string} = $xml;
    _parse_rss_string($self);
    $self->{_transformed} = 0;
    return $self;
}

#
#   Import an XSL from string
#
sub xsl_string {
    my $self = shift;
    my $xml  = shift;

    return unless $xml;
    $self->{_xsl_string}  = $xml;
    $self->{_transformed} = 0;
    return $self;
}

#
#   Do the transformation
#
sub transform {
    my $self = shift;

    croak 'No XSLT loaded' unless $self->{_xsl_string};
    croak 'No RSS loaded'  unless $self->{_rss_string};
    croak q{Can't transform twice without a change} if $self->{_transformed};

    my $xslt       = XML::LibXSLT->new;
    my $xml_parser = XML::LibXML->new;
    if ( $self->{_xml_catalog} ) {
        $xml_parser->load_catalog( $self->{_xml_catalog} );                 # Load the catalogue
    }
    else {
        $xml_parser->expand_entities( 0 );                                  # Otherwise don't touch entities
    }
    $xml_parser->keep_blanks( 0 );
    $xml_parser->validation( 0 );
    $xml_parser->complete_attributes( 0 );
    my $source_xml = $xml_parser->parse_string( $self->{_rss_string} );     # Parse the source XML
    my $style_xsl  = $xml_parser->parse_string( $self->{_xsl_string} );     # and Template XSL files
    my $stylesheet = $xslt->parse_stylesheet( $style_xsl );                 # Load the parsed XSL into XSLT
    my $result_xml = $stylesheet->transform( $source_xml );                 # Transform the source XML
    $self->{_output_string}
        = $stylesheet->output_string( $result_xml );                          # Store the result
    $self->{_transformed} = 1;
    return $self;
}

#   ---------------
#   Private Methods
#   ---------------

#
#   Parse the RSS string
#
sub _parse_rss_string {
    my $self = shift;
    my $xml  = $self->{_rss_string};

    $xml = _wash_xml( $xml ) if $self->{_auto_wash};

    if ( $self->{_rss_version} ) {    # Only normalise if version is true
        my $rss = XML::RSS->new;
        $rss->parse( $xml );
        if ( $rss->{version} != $self->{_rss_version} ) {
            $rss->{output} = $self->{_rss_version};
            $xml = $rss->as_string;
            $xml = _wash_xml( $xml ) if $self->{_auto_wash};
        }
        $self->{_xml_rss} = $rss;
    }
    $self->{_rss_string} = $xml;
    return $self;
}

#
#   Load file from File Handle
#
sub _load_filehandle {
    my $self   = shift;
    my $handle = shift;
    my $content;

    while ( my $line = $handle->getline ) {
        $content .= $line;
    }
    return $content;
}

#
#   Wash the XML File of known nasties
#
sub _wash_xml {
    my $xml = shift;

    $xml = _clean_entities( $xml );
    $xml =~ s/\s+/ /gsmx;
    $xml =~ s/> />/gmx;
    $xml =~ s/^.*(<\?xml)/$1/gsmx;    # Remove bogus content before <?xml start
    return $xml;
}

#
#   Check that the requested file is there and readable
#
sub _check_file {
    my $self      = shift;
    my $file_name = shift;

    return $self->_raise_error( 'File error: No file name supplied' )
        unless $file_name;
    return $self->_raise_error( "File error: Cannot find $file_name" )
        unless -e $file_name;
    return $self->_raise_error( "File error: $file_name isn't a real file" )
        unless -f _;
    return $self->_raise_error( "File error: Cannot read file $file_name" )
        unless -r _;
    return $self->_raise_error( "File error: $file_name is zero bytes long" )
        if -z _;
    return $self;
}

#
#   Process a URI ready for HTTP getting
#
sub _process_uri {
    my $self = shift;
    my $uri  = shift;

    return $self->_raise_error( 'No URI provided.' ) unless $uri;
    my $uri_object = URI->new( $uri )->canonical;
    return $self->_raise_error( "URI provided ($uri) is not valid." )
        unless $uri_object;

    $self->{_uri_scheme} = $uri_object->scheme;
    return $self->_raise_error(
        'No URI Scheme in ' . $uri_object->as_string . q{.} )
        unless $self->{_uri_scheme};
    return $self->_raise_error(
        'Unsupported URI Scheme (' . $self->{_uri_scheme} . q{).} )
        unless $self->{_uri_scheme} =~ /http|file/mx;

    $self->{_uri_file} = $uri_object->file if $self->{_uri_scheme} eq 'file';

    return $uri_object->as_string;
}

#
#   Grab something via HTTP
#
sub _http_get {
    my $self = shift;
    my $uri  = shift;

    my $user_agent = "XML::RSS::Tools/$VERSION";

    if ( $self->{_http_client} eq 'auto' ) {
        my @modules = qw "WWW::Curl::Easy HTTP::GHTTP HTTP::Lite LWP";
        foreach my $module (@modules) {
            eval { require $module; };
            if ( ! $@ ) {
                $self->{_http_client} = lc $module ;
                $self->{_http_client} =~ s/.*:://mx;
                last;
            }
        }
        return $self->_raise_error(
            'HTTP error: No HTTP client library installed')
            if $self->{_http_client} eq 'auto';
    }

    if ( $self->{_http_client} eq 'lite' ) {
        require HTTP::Lite;
        my $ua = HTTP::Lite->new;
        $ua->add_req_header( 'User-Agent',
            "$user_agent HTTP::Lite/$HTTP::Lite::VERSION ($^O)"
        );
        $ua->proxy( $self->{_proxy_server} ) if $self->{_proxy_server};
        my $r = $ua->request($uri)
            or return $self->_raise_error( "Unable to get document: $!" );
        return $self->_raise_error( "HTTP error: $r, " . $ua->status_message )
            unless $r == 200;
        return $ua->body;
    }

    if (   $self->{_http_client} eq 'lwp'
        || $self->{_http_client} eq 'useragent' )
    {
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        $ua->agent( $user_agent . ' ' . $ua->agent . " ($^O)" );
        $ua->proxy( [ 'http', 'ftp' ], $self->{_proxy_server} )
            if $self->{_proxy_server};
        my $response = $ua->request( HTTP::Request->new( 'GET', $uri ) );
        return $self->_raise_error( 'HTTP error: ' . $response->status_line )
            if $response->is_error;
        return $response->content( );
    }

    if ( $self->{_http_client} eq 'ghttp' ) {
        require HTTP::GHTTP;
        my $ua = HTTP::GHTTP->new($uri);
        $ua->set_header( 'User-Agent',
            "$user_agent HTTP::GHTTP/$HTTP::GHTTP::VERSION ($^O)" );
        if ( $self->{_proxy_server} ) {
            $ua->set_proxy( $self->{_proxy_server} );
            $ua->set_proxy_authinfo( $self->{_proxy_user},
                $self->{_proxy_password} )
                if ( $self->{_proxy_user} && $self->{_proxy_password} );
        }
        $ua->process_request;
        my $xml = $ua->get_body;
        if ( $xml ) {
            my ( $status, $message ) = $ua->get_status;
            return $self->_raise_error("HTTP error: $status, $message")
                unless $status == 200;
            return $xml;
        }
        else {
            return $self->_raise_error(
                "HTTP error: Unable to connect to server: $uri");
        }
    }

    if ($self->{_http_client} eq 'curl' ) {
        require WWW::Curl::Easy;
        my ($curl, $response_body, $file_b, $response_head,
            $file_h, $response, $response_code);

        $curl = WWW::Curl::Easy->new;

        open $file_b, '>', \$response_body;
        open $file_h, '>', \$response_head;

        $curl->setopt( WWW::Curl::Easy->CURLOPT_USERAGENT,
            "$user_agent WWW::Curl::Easy/$WWW::Curl::Easy::VERSION ($^O)" );
        $curl->setopt( WWW::Curl::Easy->CURLOPT_HEADER, 0 );
        $curl->setopt( WWW::Curl::Easy->CURLOPT_NOPROGRESS, 1 );
        $curl->setopt( WWW::Curl::Easy->CURLOPT_URL, $uri );
        $curl->setopt( WWW::Curl::Easy->CURLOPT_WRITEDATA, $file_b );
        $curl->setopt( WWW::Curl::Easy->CURLOPT_WRITEHEADER, $file_h );

        $response = $curl->perform;

        close $file_b;
        close $file_h;

        if ($response == 0) {
            $response_code = $curl->getinfo(
                WWW::Curl::Easy->CURLINFO_HTTP_CODE );
            return $self->_raise_error( "HTTP error: $response_code" )
                unless $response_code == 200;
            return $response_body
        }
        else {
            return $self->_raise_error( "HTTP error : " .
                $curl->strerror( $response ) . " ($response)" );
        }

    }
}

#
#   Fix Entities
#   This subroutine is a mix of Matt Sergent's rss-mirror script
#   And chunks of the HTML::Entites module if you have Perl 5.8 or
#   later you don't need this code.
#
sub _clean_entities {
    my $xml = shift;

    my %entity = (
        trade   => '&#8482;',
        euro    => '&#8364;',
        quot    => q{"},
        apos    => q{'},
        AElig   => q{Æ},
        Aacute  => q{Á},
        Acirc   => q{Â},
        Agrave  => q{À},
        Aring   => q{Å},
        Atilde  => q{Ã},
        Auml    => q{Ä},
        Ccedil  => q{Ç},
        ETH     => q{Ð},
        Eacute  => q{É},
        Ecirc   => q{Ê},
        Egrave  => q{È},
        Euml    => q{Ë},
        Iacute  => q{Í},
        Icirc   => q{Î},
        Igrave  => q{Ì},
        Iuml    => q{Ï},
        Ntilde  => q{Ñ},
        Oacute  => q{Ó},
        Ocirc   => q{Ô},
        Ograve  => q{Ò},
        Oslash  => q{Ø},
        Otilde  => q{Õ},
        Ouml    => q{Ö},
        THORN   => q{Þ},
        Uacute  => q{Ú},
        Ucirc   => q{Û},
        Ugrave  => q{Ù},
        Uuml    => q{Ü},
        Yacute  => q{Ý},
        aacute  => q{á},
        acirc   => q{â},
        aelig   => q{æ},
        agrave  => q{à},
        aring   => q{å},
        atilde  => q{ã},
        auml    => q{ä},
        ccedil  => q{ç},
        eacute  => q{é},
        ecirc   => q{ê},
        egrave  => q{è},
        eth     => q{ð},
        euml    => q{ë},
        iacute  => q{í},
        icirc   => q{î},
        igrave  => q{ì},
        iuml    => q{ï},
        ntilde  => q{ñ},
        oacute  => q{ó},
        ocirc   => q{ô},
        ograve  => q{ò},
        oslash  => q{ø},
        otilde  => q{õ},
        ouml    => q{ö},
        szlig   => q{ß},
        thorn   => q{þ},
        uacute  => q{ú},
        ucirc   => q{û},
        ugrave  => q{ù},
        uuml    => q{ü},
        yacute  => q{ý},
        yuml    => q{ÿ},
        copy    => q{©},
        reg     => q{®},
        nbsp    => q{\240},
        iexcl   => q{¡},
        cent    => q{¢},
        pound   => q{£},
        curren  => q{¤},
        yen     => q{¥},
        brvbar  => q{¦},
        sect    => q{§},
        uml     => q{¨},
        ordf    => q{ª},
        laquo   => q{«},
        'not'   => q{¬},
        shy     => q{­},
        macr    => q{¯},
        deg     => q{°},
        plusmn  => q{±},
        sup1    => q{¹},
        sup2    => q{²},
        sup3    => q{³},
        acute   => q{´},
        micro   => q{µ},
        para    => q{¶},
        middot  => q{·},
        cedil   => q{¸},
        ordm    => q{º},
        raquo   => q{»},
        frac14  => q{¼},
        frac12  => q{½},
        frac34  => q{¾},
        iquest  => q{¿},
        'times' => q{×},
        divide  => q{÷},
    );
    my $entities = join q{|}, keys %entity;
    $xml =~ s/&(?!(#[0-9]+|#x[0-9a-fA-F]+|\w+);)/&amp;/gm;       # Matt's ampersand entity fixer
    $xml =~ s/&($entities);/$entity{$1}/gimx;                    # Deal with odd entities
    return $xml;
}

#
#   Raise error condition
#
sub _raise_error {
    my $self    = shift;
    my $message = shift;

    $self->{_error_message} = $message;
    carp $message if $self->{_debug};
    return;
}

1;

__END__

=head1 NAME

XML::RSS::Tools - A tool-kit providing a wrapper around a HTTP client,
a RSS parser, and a XSLT engine.

=head1 VERSION

This documentation refers to XML::RSS::Tools version 0.33

=head1 SYNOPSIS

  use XML::RSS::Tools;
  my $rss_feed = XML::RSS::Tools->new;
  $rss_feed->rss_uri( 'http:://foo/bar.rdf' );
  $rss_feed->xsl_file( '/my/rss_transformation.xsl' );
  $rss_feed->transform;
  say $rss_feed->as_string;

=head1 DESCRIPTION

RSS/RDF feeds are commonly available ways of distributing or syndicating
the latest news about a given web site. Weblog (blog) sites in particular
are prolific generators of RSS feeds. This module provides a VERY high
level way of manipulating them. You can easily use LWP, the XML::RSS and
XML::LibXSLT do to this yourself, but this module is a wrapper around
these modules, allowing for the simple creation of a RSS client.

When working with XML if the file is invalid for some reason this module
will croak bringing your application down. When calling methods that
deal with XML manipulation you should enclose them in an eval statement
should you wish your program to fail gracefully.

Otherwise method calls will return true on success and false on failure.
For example after loading a URI via HTTP, you may wish to check the
error status before proceeding with your code:

  unless ( $rss_feed->rss_uri( 'http://this.goes.nowhere/' ) ) {
    say "Unable to obtain file via HTTP", $rss_feed->as_string( 'error' );
    # Do what else
    # you have to.
  } else {
    # carry on...
  }

Check the HTML documentation for extra examples, and background.

=head1 CONSTRUCTOR

=head2 new

  my $rss_object = XML::RSS::Tools->new;

Or with optional parameters.

  my $rss_object = XML::RSS::Tools->new(
    version     => 0.91,
    http_client => "lwp",
    auto_wash   => 1,
    debug       => 1);

The module will die if it's created with invalid parameters.

=head1 SUBROUTINES/METHODS

=head2 Source RSS feed

  $rss_object->rss_file( '/my/file.rss' );
  $rss_object->rss_uri( 'http://my.server.com/index.rss' );
  $rss_object->rss_uri( 'file:/my/file.rss' );
  $rss_object->rss_string( $xml_file );
  $rss_object->rss_fh( $file_handle );

All return true on success, false on failure. If an XML file was
provided but was invalid XML the parser will fail fatally at this time.
The input RSS feed will automatically be normalised to the preferred RSS
version at this time. Chose your version before you load it!

As of version URI version 1.32 the way that URIs are mapped has changed
slightly, this may result in erroneous file location. The variable
$URI::file::DEFAULT_AUTHORITY should be set to undef in versions later
than 1.32 to revert their behaviour to that of the older version, see
the URI changes file for more details.


=head2 Source XSL Template

  $rss_object->xsl_file( '/my/file.xsl' );
  $rss_object->xsl_uri( 'http://my.server.com/index.xsl' );
  $rss_object->xsl_uri( 'file:/my/file.xsl' );
  $rss_object->xsl_string( $xml_file );
  $rss_object->xsl_fh( $file_handle );

All return true on success, false on failure. The XSLT file is NOT
parsed or verified at this time.

=head2 Other Methods

=head3 transform

  $rss_object->transform( );

Performs the XSL transformation on the source RSS file with the loaded
XSLT file.

=head3 as_string

  $rss_object->as_string;

Returns the RSS file after it's been though the XSLT process. Optionally
you can pass this method one additional parameter to obtain the source
RSS, XSL Template and any error message:

  $rss_object->as_string( 'xsl' );
  $rss_object->as_string( 'rss' );
  $rss_object->as_string( 'error' );

If there is nothing to stringify you will get nothing.

=head3 debug

  $rss_object->debug( 1 );

A simple switch that control the debug status of the module. By default
debug is off. Returns the current status. With debug on you will get
more warnings sent to stderr.

=head3 set_auto_wash and get_auto_wash

  $rss_object->set_auto_wash( 1 );
  $rss_object->get_auto_wash;

If auto_wash is true, then all RSS files are cleaned before RSS
normalisation to replace known entities by their numeric value and fix
known invalid XML constructs. By default auto_wash is set to true.

=head3 set_version

  $rss_object->set_version(0.92);

All incoming RSS feeds are automatically converted to one default RSS
version. If RSS version is set to 0 then normalisation is not performed.
The default RSS version is 0.91.

=head3 get_version

  $rss_object->get_version;

Return the default RSS version.

=head3 set_http_client and get_http_client

  $rss_object->set_http_client('lwp');
  $rss_object->get_http_client;

These methods set the HTTP client to use and get back the one selected.
Acceptable values are:

=over

=item *

auto

Will use attempt to use the HTTP client modules in order of performance.

=item *

curl

Balint Szilakszi's libcurl based C<WWW::Curl::Easy>.

=item *

ghttp

Matt Sergeant's libghttp based C<HTTP::GHTTP>.

=item *

lite

Roy Hooper's pure Perl C<HTTP::Lite> client. Slower than ghttp, but still
faster than lwp.

=item *

lwp

LWP is the Rolls-Royce solution, it can do everything, but it's rather big,
so it's slow to load, and it's not exactly fast. It is however far more
common and is by far the most complete.

=back

If set to auto the module will first try C<WWW::Curl::Easy>,
C<HTTP::GHTTP> then C<HTTP::Lite> then C<LWP>, to retrieve files on
the Internet. Though C<LWP> is the slowest option but it is far more
common than all the others, so this method allows you to specify which
client to use if you wish to.

=head3 set_http_proxy and get_http_proxy

If you are connected to the Internet via a HTTP proxy, then you can pass
your HTTP Proxy details to the HTTP clients.

  $rss_object->set_http_proxy(proxy_server => "http://proxy.server.com:3128/");

You may also pass BASIC authentication details through if you need.

  $rss_object->set_http_proxy(
    proxy_server => "http://proxy.server.com:3128/",
    proxy_user   => "username",
    proxy_pass   => "password");

If you need to recover the proxy settings there is also the get_http_proxy
command which returns the proxy and BASIC authentication details as a
single URI.

    say $rss_object->get_http_proxy;
    # username:password@http://proxy.server.com:3128/

=head3 set_xml_catalog

Set the XML catalog. See below.

=head3 get_xml_catalog

Return the XML catalog in use.

=head2 XML Catalog

To speed up large scale XML processing it is advised to create an XML Catalog
(I<sic>) so that the XML parser does not have to make slow and expensive
requests to files on the Internet. The catalogue contains details of the
DTD and external entities so that they can be retrieved from the local file
system quicker and at lower load that from the Internet. If XML processing
is being carried out on a system not connected to the Internet, the libxml2
parser will still attempt to connect to the Internet which will add a delay of
about 60 seconds per XML file. If a catalogue is created then the process will
be much quicker as the libxml2 parser will use the local information stored
in the catalogue.

    $rss_object->set_xml_catalog( $xml_catalog_file);

This will pass the specified file to the XML parsers to use as a local
XML Catalog. If your version of XML::LibXML does not support XML
Catalogs it will die if you attempt to use this method (see below).

    $rss_object->get_xml_catalog;

This will return the file name of the XML Catalog in use.

Depending upon how your core libxml2 library is compiled, you should
also be able to use pre-configured XML Catalog files stored in your
C</etc/xml/catalog>.

XML Catalog support was introduced in version 2.4.3 of libxml2, and
significantly revised in version 2.4.7. Support for XML Catalog was
introduced into version 1.53 of the XML::LibXML module. Therefore for XML
Catalog support your libxml2 library should be version 2.4.3 or better and
your XML::LibXML should be version 1.5.3 or better. However there appears
to be bugs in some of the later version of XML::LibXML, at this time I do
not know which versions work correctly and which do not. Please bear this
in mind if you wish to use XML Catalogs.


=head1 PREREQUISITES

To function you must have C<URI> installed. If you plan to normalise your
RSS data before transforming you must also have C<XML::RSS> installed. To
transform any RSS files to HTML you will also need to use C<XML::LibXSLT>
and C<XML::LibXML>.

One of C<HTTP::GHTTP>, C<HTTP::Lite> or C<LWP> will bring this module to full
functionality. GHTTP is much faster than LWP, but is it not as widely
available as LWP. By default GHTTP will be used if it is available, then
Lite, finally LWP. If you have two or more installed you may manually select
which one you wish to use.

=pod OSNAMES

Any OS able to run the core requirements.

=head2 EXPORT

None.

=head1 HISTORY

0.33 More minor changes, tested on more modern perls. More modern build.

0.32 Minor build and kwalitee tweaks. Mo actual module code changes
     since version 0.30

...

0.01 Initial Build. Shown to the public on PerlMonks May 2002, for feedback.

See CHANGES file.

=head1 BUGS AND LIMITATIONS

=over

=item *

External Entities

If an RSS or XSLT file is passed into LibXML and it contains references
to external files, such as a DTD or external entities, LibXML will
automatically attempt to obtain the files, before performing the
transformation. If the files referred to are on the public INTERNET
and you do not have a connection when this happens you may find that
the process waits around for several minutes until LibXML gives up. If
you plan to use this module in an asynchronous manner, you should setup
an XML Catalog for LibXML using the xmlcatalog command. See:
http://www.xmlsoft.org/catalog.html for more details. You can pass your
catalog into the module and a local copy will then be used rather than
the one on the Internet.

=item *

Defective XML

Many commercial RSS feeds are derived from the Content Management
System in use at the site. Often the RSS feed is not well formed and is
thus invalid. This will prevent the RSS parser and/or XSLT engine from
functioning and you will get no output. The auto_wash option attempts
to fix these errors, but it is is neither perfect nor ideal. Some
people report good success with complaining to the site. Mark Pilgrim
estimates that about 10% of RSS feeds have defective XML.

=item *

XML::RSS Limitations

XML::RSS up-to and including version 0.96 has a number of defects. The
module is currently being maintained by Shlomi Fish. See
http://perl-rss.sourceforge.net/ and http://svn.perl.org/modules/XML-RSS/

Since version 1.xx most problems have been fixed, please upgrade if you can.

=item *

Build Problems

There are alas quite a lot of differences between differing versions of
libxml2/libxslt and XML::LibXML/LibXSLT which makes writing definitive
tests hard. Some failures are false positives, some successes may be
false negatives. Feedback welcomed.

=back

=head2 To Do

=over

=item *

Support Atom feeds.

=item *

Import Proxy settings from environment.

=item *

Turn on proxy support for WWW::Curl

=back

=head1 AUTHOR

Adam Trickett, E<lt>atrickett@cpan.orgE<gt>

This module contains the direct and indirect input of a number of
friendly Perl Hackers on Perlmonks/use.perl: Ovid; Matts; Merlyn; hfb;
link; Martin and more...

=head1 SEE ALSO

L<perl>, L<XML::RSS>, L<XML::LibXSLT>, L<XML::LibXML>, L<XML::RSS::LibXML>,
L<URI>, L<LWP>, L<XML::Feed>.

This module is not an aggregator tool for that I suggest you investigate
Plagger

=head1 LICENSE AND COPYRIGHT

This version as C<XML::RSS::Tools>, Copyright Adam John Trickett 2002-2014

OSI Certified Open Source Software.
Free Software Foundation Free Software.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 DEDICATION

This module is dedicated to my beloved mother who believed in me, even when
I didn't.

=cut
