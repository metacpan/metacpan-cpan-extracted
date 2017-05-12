package eBay::API::SimpleBase;

use strict;
use warnings;

use XML::LibXML;
use XML::Simple;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use XML::Parser;
use URI::Escape;
use YAML;
use utf8;

use base 'eBay::API::Simple';

# set the preferred xml simple parser
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

our $DEBUG = 0;

=head1 NAME 

eBay::API::SimpleBase - Flexible SDK supporting all eBay web services

=head1 DESCRIPTION

This is the base class for the eBay::API::Simple::* libraries that provide
support for all of eBay's web services. This base class does nothing by itself
and must be subclassed to provide the complete web service support. 

=item L<eBay::API::Simple::Merchandising>

=item L<eBay::API::Simple::Finding>

=item L<eBay::API::Simple::Shopping>

=item L<eBay::API::Simple::Trading>

=item L<eBay::API::Simple::HTML>

=item L<eBay::API::Simple::JSON>

=item L<eBay::API::Simple::RSS>

=head1 GET THE SOURCE

http://code.google.com/p/ebay-api-simple

=head1 PUBLIC METHODS

=head2 eBay::API::Simple::{subclass}->new()

see subclass for more docs.

=item L<eBay::API::Simple::Merchandising>

=item L<eBay::API::Simple::Finding>

=item L<eBay::API::Simple::Shopping>

=item L<eBay::API::Simple::Trading>

=item L<eBay::API::Simple::HTML>

=item L<eBay::API::Simple::JSON>

=item L<eBay::API::Simple::RSS>

=cut

sub new {
    my $class    = shift;
    my $api_args = shift;

    my $self = {};  
    bless( $self, $class );
    
    # set some defaults 
    $self->api_config->{siteid}   = 0;
    $self->api_config->{enable_attributes} = 0;
    $self->api_config->{timeout}  = 20 unless defined $api_args->{timeout};
    $self->api_config->{parallel} = $api_args->{parallel};
    
    unless (defined $api_args->{preserve_namespace}) {
        $self->api_config->{preserve_namespace} = 0;
    }
    
    # set the config args 
    $self->api_config_append( $api_args );
    
    return $self;   
}

=head2 execute( $verb, $call_data )

Calling this method will prepare the request, execute, and process the response.

It is recommended that prepare and process be subclassed rather than this method.

=item $verb (required)

call verb, i.e. FindItems 

=item $call_data (required)

hashref of call_data that will be turned into xml.

=cut

sub execute {
    my $self = shift;

    $self->prepare( @_ );

    $self->_execute_http_request();

    if ( defined $self->{response_content} ) {
        $self->process();
    }
}

=head2 prepare( $verb, $call_data )

This is called by execute to prepare the request
and may be supplied by the subclass.

=cut

sub prepare {
    my $self = shift;

    $self->{verb}      = shift;
    $self->{call_data} = shift;
    
    if ( ! defined $self->{verb} || ! defined $self->{call_data} ) {
        die "missing verb and call_data";
    }
}

=head2 process()

This is called by execute to process the response
and may be supplied by the subclass.

=cut

sub process {
    my $self = shift;

    if ( $DEBUG ) {
        print STDERR $self->request_object->as_string();
        print STDERR $self->response_object->as_string();
    }
}

=head2 request_agent

Accessor for the LWP::UserAgent request agent

=cut

sub request_agent {
    my $self = shift;
    return $self->{request_agent};
}

=head2 request_object

Accessor for the HTTP::Request request object

=cut

sub request_object {
    my $self = shift;
    return $self->{request_object};
}

=head2 request_content

Accessor for the complete request body from the HTTP::Request object

=cut

sub request_content {
    my $self = shift;
    return $self->{request_object}->as_string();
} 

=head2 response_content

Accessor for the HTTP response body content

=cut

sub response_content {
    my $self = shift;
    return $self->{response_content};
}

=head2 response_object

Accessor for the HTTP::Request response object

=cut

sub response_object {
    my $self = shift;
    return $self->{response_object};
}

=head2 response_dom

Accessor for the LibXML response DOM

=cut

sub response_dom {
    my $self = shift;

    if ( ! defined $self->{response_dom} ) {
        my $parser = XML::LibXML->new();    
        eval {
            $self->{response_dom} = 
                $parser->parse_string( $self->response_content );
        };
        if ( $@ ) {
            $self->errors_append( { 'parsing_error' => $@ } );
        }
    }

    return $self->{response_dom};
}

=head2 response_hash

Accessor for the hashified response content

=cut

sub response_hash {
    my $self = shift;

    if ( ! defined $self->{response_hash} ) {
        $self->{response_hash} = XMLin( $self->response_content,
            forcearray => [],
            keyattr    => []
        );
    }

    return $self->{response_hash};
}

=head2 response_json

Not implemented yet.

=cut

sub response_json {
    my $self = shift;

    if ( ! defined $self->{response_json} ) {
        $self->{response_json} = ''; # xml2json( $self->{response_content} );
    }

    return $self->{response_json};
}

=head2 nodeContent( $tag, [ $dom ] ) 

Helper for LibXML that retrieves node content

=item $tag (required)

This is the name of the xml element

=item $dom (optional)

optionally a DOM object can be passed in. If no DOM object 
is passed then the main response DOM object is used.

=cut
 
sub nodeContent {
    my $self = shift;
    my $tag  = shift;
    my $node = shift;

    $node ||= $self->response_dom();

    return if ! $tag || ! $node;

    my $e = $node->getElementsByTagName($tag);
    if ( defined $e->[0] ) {
        return $e->[0]->textContent();

    }
    else { 
        #print STDERR "no info for $tag\n";
        return;
    }
}

=head2 errors 

Accessor to the hashref of errors

=cut

sub errors {
    my $self = shift;
    $self->{errors} = {} unless defined $self->{errors};
    return $self->{errors};
}

=head2 has_error

Returns true if the call contains errors

=cut

sub has_error {
    my $self = shift;
    my $has_error =  (keys( %{ $self->errors } ) > 0) ? 1 : 0;
    return $has_error;
}

=head2 errors_as_string

Returns a string of API errors if there are any.

=cut

sub errors_as_string {
    my $self = shift;

    my @e;
    for my $k ( keys %{ $self->errors } ) {
        push( @e, $k . '-' . $self->errors->{$k} );
    }
    
    return join( "\n", @e );
}

=head1 INTERNAL METHODS

=head2 api_config

Accessor to a hashref of api config data that will be used to execute
the api call.

  siteid,domain,uri,etc.

=cut

sub api_config {
    my $self = shift;
    $self->{api_config} = {} unless defined $self->{api_config};
    return $self->{api_config};
}

=head2 api_config_append( $hashref )

This method is used to merge config into the config_api hash

=cut

sub api_config_append {
    my $self = shift;
    my $config_hash = shift;

    for my $k ( keys %{ $config_hash } ) {
        $self->api_config->{$k} = $config_hash->{$k};
    }
}

=head2 api_config_dump()

This method is used for debugging

=cut

sub api_config_dump {
    my $self = shift;

    my $str;
    
    while ( my( $key, $value ) = each( %{ $self->api_config } ) ) {
         $str .= sprintf( "%s=%s\n", $key, $value );
    }
    
    return $str;
}

=head2 errors_append

This method lets you append errors to the errors stack

=cut

sub errors_append {
    my $self = shift;
    my $hashref = shift;

    for my $k ( keys %{ $hashref } ) {
        $self->errors->{$k} = $hashref->{$k};
    }

}

=head1 PRIVATE METHODS

=head2 _execute_http_request

This method performs the http request and should be used by 
each subclass.

=cut

sub _execute_http_request {
    my $self = shift;

    # clear previous call data
    $self->_reset();
 
    unless ( defined $self->{request_agent} ) {
        $self->{request_agent} = $self->_get_request_agent();
    }

    unless ( defined $self->{request_object} ) {
        $self->{request_object} = $self->_get_request_object();
    }

    if ( defined $self->api_config->{parallel} ) {
        $self->{request_object}->{_ebay_api_simple_instance} = $self;
        $self->api_config->{parallel}->register( $self->{request_object} );
        return undef;
    }

    my $max_tries = 1;
    
    if ( defined $self->api_config->{retry} ) {
        $max_tries =  $self->api_config->{retry} + 1;
    }

    my $content = '';
    my $error   = '';
    my $response;

    for ( my $i=0; $i < $max_tries; ++$i ) {
        $response = $self->{request_agent}->request( $self->{request_object} );

        if ( $response->is_success ) {
            last; # exit the loop
        }
    }

    $self->_process_http_request( $response );
  
    return $self->{response_content};
}

=head2 _process_http_request

This method processes the http request after it has completed.

=cut

sub _process_http_request {
    my $self = shift;
    my $response = shift;

    $self->{response_object} = $response;

    if ( $response->is_success ) {
        my $content = $response->content();

        unless ($self->api_config->{preserve_namespace}) {
            # strip out the namespace param, with single or double quotes
            $content =~ s/xmlns=("[^"]+"|'[^']+') *//;
        }

        $self->{response_content} = $content;

        # call the classes validate response method if it exists
        $self->_validate_response() if $self->can('_validate_response');
    }
    else {
        # store the error 
        my $error   = $response->status_line;
        $self->errors_append( { http_response => $error } ) if defined $error;     

        my $content = $response->content();
        $self->{response_content} = $content;
    }
}

=head2 _reset

Upon execute() we need to undef any data from a previous call. This
method will clear all call data and is usually done before each execute

=cut

sub _reset {
    my $self = shift;

    # clear previous call
    $self->{errors}            = undef;
    $self->{response_object}   = undef;
    $self->{response_content}  = undef;
    $self->{request_agent}     = undef;
    $self->{request_object}    = undef;
    $self->{response_dom}      = undef;
    $self->{response_json}     = undef;
    $self->{response_hash}     = undef;

}

=head2 _build_url( $base_url, $%params )

Constructs a URL based on the supplied args

=cut

sub _build_url {
    my $self = shift;
    my $base = shift;
    my $args = shift;

    my @p;
    for my $k ( sort keys %{ $args } ) {
        if ( ref( $args->{$k} ) eq 'ARRAY' ) {
            for my $ap ( @{ $args->{$k} } ) {
                push( @p, 
                    ( $k . '=' . uri_escape_utf8( $ap ) ) 
                );                    
            }
        }
        else {
            push( @p, ( $k . '=' . uri_escape_utf8( $args->{$k} ) ) );
        }        
    }

    return( scalar( @p ) > 0 ? $base . '?' . join('&', @p) : $base );
}

=head2 _get_request_body

The request body should be provided by the subclass

=cut

sub _get_request_body {
    my $self = shift;
    
    my $xml = "<sample>some content</sample>";

    return $xml; 
}

=head2 _get_request_headers 

The request headers should be provided by the subclass

=cut

sub _get_request_headers {
    my $self = shift;
   
    my $obj = HTTP::Headers->new();

    $obj->push_header("SAMPLE-HEADER" => 'foo');
    
    return $obj;
}

=head2 _get_request_agent

The request request agent should be used by all subclasses

=cut

sub _get_request_agent {
    my $self = shift;

    my $ua= LWP::UserAgent->new();

    $ua->agent( sprintf( '%s / eBay API Simple (Version: %s)',
        $ua->agent,
        $eBay::API::Simple::VERSION,
    ) );

    # timeout in seconds
    if ( defined $self->api_config->{timeout} ) {
        $ua->timeout( $self->api_config->{timeout} );
    }
    
    # add proxy
    if ( $self->api_config->{http_proxy} ) {
        $ua->proxy( ['http'], $self->api_config->{http_proxy} );
    }

    if ( $self->api_config->{https_proxy} ) {
        $ua->proxy( ['https'], $self->api_config->{https_proxy} );
    }
    
    return $ua;
}

=head2 _get_request_object

The request object should be provided by the subclass

=cut

sub _get_request_object {
    my $self = shift;

    my $url = sprintf( 'http%s://%s%s',
        ( $self->api_config->{https} ? 's' : '' ),
        $self->api_config->{domain},
        $self->api_config->{uri}
    );
  
    my $objRequest = HTTP::Request->new(
        "POST",
        $url,
        $self->_get_request_headers,
        $self->_get_request_body
    );

    if( $self->api_config->{authorization_basic}{enabled} ) {
        $objRequest->authorization_basic(
            $self->api_config->{authorization_basic}{username},
            $self->api_config->{authorization_basic}{password}
        );
    }
        
    return $objRequest;
}

sub authorization_basic {
     my $self = shift;
     my $username = shift;
     my $password = shift;
     $self->api_config->{authorization_basic}{username} = $username;
     $self->api_config->{authorization_basic}{password} = $password;
     $self->api_config->{authorization_basic}{enabled} = 1;
}

sub disable_authorization_basic {
     my $self = shift;
     $self->api_config->{authorization_basic}{enabled} = 0;
}

=head2 _load_yaml_defaults

This method will search for the ebay.yaml file and load configuration defaults
for each service endpoint

YAML files can be placed at the below locations. The first file found will
be loaded.

  ./ebay.yaml, ~/ebay.yaml, /etc/ebay.yaml 

Sample YAML:

  # Trading - External
  api.ebay.com:
    appid: <your appid>
    certid: <your certid>
    devid: <your devid>
    token: <token>
    
  # Shopping
  open.api.ebay.com:
    appid: <your appid>
    certid: <your certid>
    devid: <your devid>
    version: 671

  # Finding/Merchandising
  svcs.ebay.com:
    appid: <your appid>
    version: 1.0.0


=cut

sub _load_yaml_defaults {
    my $self = shift;

    return 1 if $self->{_yaml_loaded};
    
    my @files = (
        "./ebay.yaml",
        "/etc/ebay.yaml",
    );

    push(@files, "$ENV{HOME}/ebay.yaml") if defined ($ENV{HOME});

    foreach my $file ( reverse @files ) {

        if ( open( FILE, "<", $file ) ) {

            my $yaml;
            { 
                local $/ = undef; 
                $yaml = <FILE>; 
            }                

            my $hashref = YAML::Load($yaml);
            my $domain  = $self->api_config->{domain};

            if ( defined $hashref->{ $domain } ) {
                $self->api_config_append( $hashref->{ $domain } );
            }
            
            $self->{_yaml_loaded} = 1;
            close FILE;
            last;
        }
    }


}

1;

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 CONTRIBUTOR

Andrew Dittes <adittes@gmail.com>
Brian Gontowski <bgontowski@gmail.com>

=cut
