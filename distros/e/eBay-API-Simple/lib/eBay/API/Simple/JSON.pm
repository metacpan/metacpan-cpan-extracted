package eBay::API::Simple::JSON;

use strict;
use warnings;

use base 'eBay::API::SimpleBase';
use JSON;
use HTTP::Request;
use HTTP::Headers;
use XML::Simple;
use URI::Escape;
use utf8;

our $DEBUG = 0;

=head1 NAME 

eBay::API::Simple::JSON - Support for grabbing an RSS feed via API call

=head1 USAGE

  my $api = eBay::API::Simple::JSON->new();

  my $data = {     
    "user_eais_token" => "tim", 
    "body_text" => "mytext",    
    "foo" => "bar",
    "greener_alt_topic" => "/green/api/v1/greenerAlternativeTopic/2/",     
    "items"=> [ {         
        "ebay_item_id"=> "250814913221",         
        "photo"=> "http=>//thumbs2.ebaystatic.com/m/m9X7sXOK303v4e_fgxm_-7w/140.jpg",        
        "price"=> 2.96,         
        "title"=> "TEST PUT - VAPUR 16 OZ FLEXIBLE FOLDABLE WATER BOTTLE BPA FREE"     
    } ],     
    "meta_title"=> "Foldable bottles can be stashed away when the water is gone",     
    "title"=> "TEST PUT - Foldable bottles can be stashed away when the water is gone" 
  };

  $api->execute(
    'http://localhost-django-vm.ebay.com/green/api/v1/greenerAlternative/',
    $data
  );

  print $api->request_content() ."\n";

  if ( $api->has_error() ) {
    print "FAILED: " . $api->response_content();
    #print "FAILED: " . $api->response_hash->{error_message} . "\n";
  }
  else {
    print "SUCCESS!\n";
    print $api->response_object->header('Location') . "\n";
  }
 
  my $hash = $call->response_hash();

  # execution methods for "GET", "POST", "PUT", and "DELETE" requests
  $api->get( $endpoint );
  $api->post( $endpoint, data );
  $api->put( $endpoint, $data );
  $api->delete( $endpoint );
  
=head1 PUBLIC METHODS

=head2 new( { %options } } 

my $call = ebay::API::Simple::JSON->new();

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->api_config->{request_method}  ||= 'POST';

    return $self;    
}

=head2 prepare( $url, $%args )

  $call->prepare( 
    'http://sfbay.craigslist.org/search/sss',
    { query  => 'shirt', format => 'rss', } 
  );
  
This method will construct the API request using the supplied URL. 

=head3 Options

=over 4

=item $url (required)

Feed URL to fetch

=item %$args (optional)

The supplied args will be encoded and appended to the URL

=back

=cut

sub prepare {
    my $self = shift;

    $self->{url} = shift;

    if ( ! defined $self->{url} ) {
        die "missing url";
    }

    # collect the optional args
    $self->{request_data} = shift;
}

=head2 process()

This method will process the API response.

=cut

sub process {
    my $self = shift;

    $self->SUPER::process();

    $self->response_hash(); # build the hash now to detect errors
}

=head2 get( $url )

execute a "GET" request to the specified endpoint

=cut

sub get {
    my $self = shift;
    $self->{custom_method} = 'GET';
    $self->execute(@_);
    $self->{custom_method} = undef;
}

=head2 post( $url )

execute a "POST" request to the specified endpoint

=cut

sub post {
    my $self = shift;
    $self->{custom_method} = 'POST';
    $self->execute(@_);    
    $self->{custom_method} = undef;
}

=head2 put( $url )

execute a "PUT" request to the specified endpoint

=cut

sub put {
    my $self = shift;
    $self->{custom_method} = 'PUT';
    $self->execute(@_);    
    $self->{custom_method} = undef;
}

=head2 delete( $url )

execute a "DELETE" request to the specified endpoint

=cut

sub delete {
    my $self = shift;
    $self->{custom_method} = 'DELETE';
    $self->execute(@_);    
    $self->{custom_method} = undef;
}

=head1 BASECLASS METHODS

=head2 request_agent

Accessor for the LWP::UserAgent request agent

=head2 request_object

Accessor for the HTTP::Request request object

=head2 request

Accessor for the HTTP::Request request object

=cut

sub request {
    my $self = shift;
    return $self->request_object();
}

=head2 request_content

Accessor for the complete request body from the HTTP::Request object

=head2 response_content

Accessor for the HTTP response body content

=head2 response_object

Accessor for the HTTP::Response response object

=head2 response

Accessor for the HTTP::Response response object

=cut

sub response {
    my $self = shift;
    return $self->response_object;
}

=head2 response_dom

Accessor for the LibXML response DOM

=cut

sub response_dom {
    die "can't use with the JSON backend";
}

=head2 response_hash

Accessor for the hashified response content

=cut

sub response_hash {
    my $self = shift;

    if ( ! defined $self->{response_hash} && $self->response_content ) {
        eval {
            $self->{response_hash} = decode_json( $self->response_content );
        };
        if ( $@ ) {
            $self->errors_append( { 'decode_error' => $@ } );
        }
    }

    return $self->{response_hash};
}

=head2 response_json

Accessor for the json response content

=cut

sub response_json {
    my $self = shift;
    return $self->response_content;
}

=head2 nodeContent( $tag, [ $dom ] ) 

Helper for LibXML that retrieves node content

=cut

sub nodeContent {
    die "not implemented for the JSON backend";
}

=head2 errors 

Accessor to the hashref of errors

=head2 has_error

Returns true if the call contains errors

=cut

sub has_error {
    my $self = shift;
    
    my $has_error =  (keys( %{ $self->errors } ) > 0) ? 1 : 0; 
    return 1 if $has_error;
    return $self->response_object->is_error;
}

=head2 errors_as_string

Returns a string of API errors if there are any.

=cut

sub errors_as_string {
    my $self = shift;
    
    return "" unless $self->has_error;

    my @e;
    for my $k ( keys %{ $self->errors } ) {
        push( @e, $k . '-' . $self->errors->{$k} );
    }

    if ( $self->response_object->is_error ) {
        push( @e, $self->response_content );
    }
    
    return join( "\n", @e );
 
}

=head1 PRIVATE METHODS

=head2 _get_request_body

This method supplies the JSON body for the web service request

=cut

sub _get_request_body {
    my $self = shift;
    return undef if ! defined $self->{request_data};
    my $body;
    eval {
        my $json = JSON->new->utf8;
        $body = $json->allow_blessed->convert_blessed->encode( $self->{request_data} );
    };
    if ( $@ ) {
        $self->errors_append( { 'decode_error' => $@ } );
    }
    return $body;
}

=head2 _get_request_headers 

This methods supplies the headers for the RSS API call

=cut

sub _get_request_headers {
    my $self = shift;
   
    my $obj = HTTP::Headers->new();
    $obj->push_header( 'Content-Type' => 'application/json' );
    return $obj;
}

=head2 _get_request_object 

This method creates the request object and returns to the parent class

=cut

sub _get_request_object {
    my $self     = shift;
    
    my $body = $self->_get_request_body;
    
    my $request_method = $self->{custom_method};
    if ( ! $request_method ) {
        $request_method = defined $body ? 'POST' : 'GET';
    }
    
    my $request_obj = HTTP::Request->new(
        $request_method,
        $self->{url},
        $self->_get_request_headers,
        $self->_get_request_body,
    );

    if( $self->api_config->{authorization_basic}{enabled} ) {
        $request_obj->authorization_basic(
            $self->api_config->{authorization_basic}{username},
            $self->api_config->{authorization_basic}{password}
        );
    }

    return $request_obj;
}

1;

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 COPYRIGHT

Tim Keefer 2009

=cut
