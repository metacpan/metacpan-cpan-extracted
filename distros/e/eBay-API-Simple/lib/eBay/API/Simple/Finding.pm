package eBay::API::Simple::Finding;

use strict;
use warnings;

use base 'eBay::API::SimpleBase';

use HTTP::Request;
use HTTP::Headers;
use XML::Simple;
use Encode;
use utf8;

our $DEBUG = 0;

=head1 NAME

eBay::API::Simple::Finding - Support for eBay's Finding 2.0 web service

=head1 DESCRIPTION

This class provides support for eBay's Finding 2.0 web services.

See http://developer.ebay.com/products/finding/

=head1 USAGE

  my $call = eBay::API::Simple::Finding->new( 
    { appid => '<your app id here>' } 
  );
  
  $call->execute( 'findItemsByKeywords', { keywords => 'shoe' } );

  if ( $call->has_error() ) {
     die "Call Failed:" . $call->errors_as_string();
  }

  # getters for the response DOM or Hash
  my $dom  = $call->response_dom();
  my $hash = $call->response_hash();

  print $call->nodeContent( 'timestamp' );
  print $call->nodeContent( 'totalEntries' );

  my @nodes = $dom->findnodes(
    '//item'
  );

  foreach my $n ( @nodes ) {
    print $n->findvalue('title/text()') . "\n";
  }

=head1 SANDBOX USAGE

  my $call = eBay::API::Simple::Finding->new( { 
    appid => '<your app id here>',
    domain => 'svcs.sandbox.ebay.com',
  } );
  
  $call->execute( 'findItemsByKeywords', { keywords => 'shoe' } );

  if ( $call->has_error() ) {
     die "Call Failed:" . $call->errors_as_string();
  }

  # getters for the response DOM or Hash
  my $dom  = $call->response_dom();
  my $hash = $call->response_hash();

=head1 PUBLIC METHODS

=head2 new( { %options } } 

Constructor for the Finding API call

  my $call = eBay::API::Simple::Finding->new( { 
    appid => '<your app id here>' 
    ... 
  } );

=head3 Options

=over 4

=item appid (required)

This appid is required by the web service. App ids can be obtained at 
http://developer.ebay.com

=item siteid

eBay site id to be supplied to the web service endpoint

defaults to EBAY-US

=item domain

domain for the web service endpoint

defaults to svcs.ebay.com

=item service

SOA Service name 

defaults to FindingService

=item uri

endpoint URI

defaults to /services/search/FindingService/v1

=item version

Version to be supplied to the web service endpoint

defaults to 1.0.0

=item https

Specifies is the API calls should be made over https.

defaults to 0

=item enable_attributes

This flag adds support for attributes in the request. If enabled request
data notes much be defined like so,

myElement => { content => 'element content', myattr => 'attr value' }

defaults to 0

=back

=head3 ALTERNATE CONFIG VIA ebay.yaml

  An ebay.yaml file can be use for configuring each 
  service endpoint.

  YAML files can be placed at the below locations. The first 
  file found will be loaded.

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

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->api_config->{service}  ||= 'FindingService';
    $self->api_config->{domain}  ||= 'svcs.ebay.com';
    $self->api_config->{uri}     ||= '/services/search/FindingService/v1';
    $self->api_config->{version} ||= '1.0.0';
    $self->api_config->{https}   ||= 0;
    $self->api_config->{siteid}  ||= 'EBAY-US';
    $self->api_config->{response_encoding} ||= 'XML'; # JSON, NV, SOAP
    $self->api_config->{request_encoding}  ||= 'XML';

    $self->_load_yaml_defaults();
    
    if ( $DEBUG ) {
        print STDERR sprintf( "API CONFIG:\n%s\n",
            $self->api_config_dump()
        );        
    }

    
    $self->_load_credentials();
    
    return $self;    
}

=head2 prepare( $verb, $call_data )

  $self->prepare( 'findItemsByKeywords', { keywords => 'shoe' } );
 
This method will construct the API request based on the $verb and
the $call_data.

=item $verb (required)

call verb, i.e. findItemsItemsByKeywords

=item $call_data (required)

hashref of call_data that will be turned into xml.

=cut

sub prepare {
    my $self = shift;
    
    $self->{verb}      = shift;
    $self->{call_data} = shift;

    if ( ! defined $self->{verb} || ! defined $self->{call_data} ) {
        die "missing verb and call_data";
    }
    
    # make sure we have appid
    $self->_load_credentials();
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

    # handle a special unicode issue with perl 5.8.1
    if ( $self->{call_data}->{keywords} && $] eq '5.008001' ) {   
        Encode::_utf8_off($self->{call_data}->{keywords});
    }
    elsif ($self->{call_data}->{keywords}) {
        $self->{call_data}->{keywords} 
            = Encode::encode('utf8', $self->{call_data}->{keywords});
    }

    my $xml = "<?xml version='1.0' encoding='utf-8'?>"
        . "<" . $self->{verb} . "Request xmlns=\"http://www.ebay.com/marketplace/search/v1/services\">"
        . XMLout( 
            $self->{call_data}, 
            NoAttr => !$self->api_config->{enable_attributes},    
            KeepRoot => 1, 
            RootName => undef 
        )
        . "</" . $self->{verb} . "Request>";

    return $xml; 
}

=head2 _get_request_headers 

This method supplies the HTTP::Headers obj for the web service request

=cut

sub _get_request_headers {
    my $self = shift;
   
    my $obj = HTTP::Headers->new();
    
    $obj->push_header("X-EBAY-SOA-SERVICE-NAME" => $self->api_config->{service});
    $obj->push_header("X-EBAY-SOA-SERVICE-VERSION" => $self->api_config->{version});
    $obj->push_header("X-EBAY-SOA-SECURITY-APPNAME"  => $self->api_config->{appid});
    $obj->push_header("X-EBAY-SOA-GLOBAL-ID"  => $self->api_config->{siteid});
    $obj->push_header("X-EBAY-SOA-OPERATION-NAME" => $self->{verb});
    $obj->push_header("X-EBAY-SOA-REQUEST-DATA-FORMAT"  => $self->api_config->{request_encoding});
    $obj->push_header("X-EBAY-SOA-RESPONSE-DATA-FORMAT" => $self->api_config->{response_encoding});
    $obj->push_header("Content-Type" => "text/xml");
    
    return $obj;
}

=head2 _get_request_object 

This method creates and returns the HTTP::Request object for the
web service call.

=cut

sub _get_request_object {
    my $self = shift;

    my $url = sprintf( 'http%s://%s%s',
        ( $self->api_config->{https} ? 's' : '' ),
        $self->api_config->{domain},
        $self->api_config->{uri}
    );
  
    my $request_obj = HTTP::Request->new(
        "POST",
        $url,
        $self->_get_request_headers,
        $self->_get_request_body
    );

    return $request_obj;
}

sub _load_credentials {
    my $self = shift;
    
    # we only need to load credentials once
    return if $self->{_credentials_loaded};
    
    my @missing;
    
    # required by the API
    for my $p ( qw/appid/ ) {
        next if defined $self->api_config->{$p};
        
        if ( my $val = $self->_fish_ebay_ini( $p ) ) {
            $self->api_config->{$p} = $val;
        }
        else {
            push( @missing, $p );
        }
    }

    # die if we didn't get everything
    if ( scalar @missing > 0 ) {
        die "missing API credential: " . join( ", ", @missing );
    }
    
    $self->{_credentials_loaded} = 1;
    return;
}

sub _fish_ebay_ini {
    my $self = shift;
    my $arg  = shift;

    # initialize our hashref
    $self->{_ebay_ini} ||= {};
    
    # revert eBay::API::Simple keys to standard keys
    $arg = 'ApplicationKey' if $arg eq 'appid';

    # return it if we've already found it
    return $self->{_ebay_ini}{$arg} if defined $self->{_ebay_ini}{$arg};
    
    # ini files in order of importance
    my @files = (
        './ebay.ini',           
        "$ENV{HOME}/ebay.ini",
        '/etc/ebay.ini',
    );
    
    foreach my $file ( reverse @files ) {        
        if ( open( FILE, "<", $file ) ) {
        
            while ( my $line = <FILE> ) {
                chomp( $line );
            
                next if $line =~ m!^\s*\#!;
            
                my( $k, $v ) = split( /=/, $line );
            
                if ( defined $k && defined $v) {
                    $v =~ s/^\s+//;
                    $v =~ s/\s+$//;
                    
                    $self->{_ebay_ini}{$k} = $v;
                }
            }

            close FILE;
        }
    }
    
    return $self->{_ebay_ini}{$arg} if defined $self->{_ebay_ini}{$arg};
    return undef;
}

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=cut

1;
