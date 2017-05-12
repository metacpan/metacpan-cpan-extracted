package eBay::API::Simple::RSS;

use strict;
use warnings;

use base 'eBay::API::SimpleBase';

use HTTP::Request;
use HTTP::Headers;
use XML::Simple;
use URI::Escape;
use utf8;

our $DEBUG = 0;

=head1 NAME 

eBay::API::Simple::RSS - Support for grabbing an RSS feed via API call

=head1 USAGE

  my $call = eBay::API::Simple::RSS->new();
  $call->execute(
    'http://sfbay.craigslist.org/search/sss',
    {
        query  => 'shirt',
        format => 'rss',
    }
  );

  if ( $call->has_error() ) {
     die "Call Failed:" . $call->errors_as_string();
  }

  # getters for the response DOM or Hash
  my $dom  = $call->response_dom();
  my $hash = $call->response_hash();

  # collect all item nodes
  my @items = $dom->getElementsByTagName('item');

  foreach my $n ( @items ) {
    print $n->findvalue('title/text()') . "\n";
  }
  
=head1 PUBLIC METHODS

=head2 new( { %options } } 

my $call = ebay::API::Simple::RSS->new();

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->api_config->{request_method}  ||= 'GET';

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
    $self->{args} = shift;
}

=head1 BASECLASS METHODS

=head2 request_agent

Accessor for the LWP::UserAgent request agent

=head2 request_object

Accessor for the HTTP::Request request object

=head2 request_content

Accessor for the complete request body from the HTTP::Request object

=head2 response_content

Accessor for the HTTP response body content

=head2 response_object

Accessor for the HTTP::Request response object

=head2 response_dom

Accessor for the LibXML response DOM

=head2 response_hash

Accessor for the hashified response content

=head2 nodeContent( $tag, [ $dom ] ) 

Helper for LibXML that retrieves node content

=head2 errors 

Accessor to the hashref of errors

=head2 has_error

Returns true if the call contains errors

=head2 errors_as_string

Returns a string of API errors if there are any.

=head1 PRIVATE METHODS

=head2 _get_request_body

This method supplies the XML body for the web service request

=cut

sub _get_request_body {
    my $self = shift;
    my @p;
    
    if ( $self->api_config->{request_method} ne 'GET' ) {
        for my $k ( keys %{ $self->{args} } ) {
            if ( ref( $self->{args}{$k} ) eq 'ARRAY' ) {
                for my $ap ( @{ $self->{args}{$k} } ) {
                    push( @p, 
                        ( $k . '=' . uri_escape_utf8( $ap ) ) 
                    );                    
                }
            }
            else {
                push( @p, ( $k . '=' . uri_escape_utf8( $self->{args}{$k} ) ) );
            }
        }
    }
    
    return join( '&', @p ) or "";
}

=head2 _get_request_headers 

This methods supplies the headers for the RSS API call

=cut

sub _get_request_headers {
    my $self = shift;
   
    my $obj = HTTP::Headers->new();
    return $obj;
}

=head2 _get_request_object 

This method creates the request object and returns to the parent class

=cut

sub _get_request_object {
    my $self     = shift;
    
    my $req_url  = undef;
    
    # put the args in the url for a GET request only
    if ( $self->api_config->{request_method} eq 'GET'
        && defined $self->{args} ) {
        
        $req_url = $self->_build_url( $self->{url}, $self->{args} );
    }
    else {
        $req_url = $self->{url}; 
    }
    
    my $request_obj = HTTP::Request->new(
        ( $self->api_config->{request_method} || 'GET' ),
        $req_url,
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
