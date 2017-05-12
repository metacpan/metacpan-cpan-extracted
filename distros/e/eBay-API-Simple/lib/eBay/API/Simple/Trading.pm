package eBay::API::Simple::Trading;

use strict;
use warnings;

use base 'eBay::API::SimpleBase';

use HTTP::Request;
use HTTP::Headers;
use XML::Simple;
use utf8;

our $DEBUG = 0;

=head1 NAME

eBay::API::Simple::Trading - Support for eBay's Trading web service

=head1 DESCRIPTION

This class provides support for eBay's Trading web services.

See http://developer.ebay.com/products/trading/

=head1 USAGE

  my $call = eBay::API::Simple::Trading->new( { 
    appid   => '<your appid>',
    devid   => '<your devid>',
    certid  => '<your certid>',
    token   => '<auth token>',
  } );
  
  $call->execute( 'GetSearchResults', { Query => 'shoe' } );

  if ( $call->has_error() ) {
     die "Call Failed:" . $call->errors_as_string();
  }

  # getters for the response DOM or Hash
  my $dom  = $call->response_dom();
  my $hash = $call->response_hash();

  print $call->nodeContent( 'Timestamp' );

  my @nodes = $dom->findnodes(
    '//Item'
  );

  foreach my $n ( @nodes ) {
    print $n->findvalue('Title/text()') . "\n";
  }

=head1 SANDBOX USAGE

  my $call = eBay::API::Simple::Trading->new( { 
    appid   => '<your appid>',
    devid   => '<your devid>',
    certid  => '<your certid>',
    token   => '<auth token>',
    domain  => 'api.sandbox.ebay.com',
  } );
  
  $call->execute( 'GetSearchResults', { Query => 'shoe' } );

  if ( $call->has_error() ) {
     die "Call Failed:" . $call->errors_as_string();
  }

  # getters for the response DOM or Hash
  my $dom  = $call->response_dom();
  my $hash = $call->response_hash();

=head1 PUBLIC METHODS

=head2 new( { %options } } 

Constructor for the Trading API call

    my $call = eBay::API::Simple::Trading->new( { 
      appid   => '<your appid>',
      devid   => '<your devid>',
      certid  => '<your certid>',
      token   => '<auth token>',
      ... 
    } );

=head3 Options

=over 4

=item appid (required)

This is required by the web service and can be obtained at 
http://developer.ebay.com

=item devid (required)

This is required by the web service and can be obtained at 
http://developer.ebay.com

=item certid (required)

This is required by the web service and can be obtained at 
http://developer.ebay.com

=item token (required)

This is required by the web service and can be obtained at 
http://developer.ebay.com

=item siteid

eBay site id to be supplied to the web service endpoint

defaults to 0

=item domain

domain for the web service endpoint

defaults to open.api.ebay.com

=item uri

endpoint URI

defaults to /ws/api.dll

=item version

Version to be supplied to the web service endpoint

defaults to 543

=item https

Specifies is the API calls should be made over https.

defaults to 1

=item enable_attributes

This flag adds support for attributes in the request. If enabled request
data notes much be defined like so,

myElement => { content => 'element content', myattr => 'attr value' }

defaults to 0

=back

=head3 ALTERNATE CONFIG VIA ebay.yaml

An ebay.yaml file can be used for configuring each 
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
    
    $self->api_config->{domain}  ||= 'api.ebay.com';    
    $self->api_config->{uri}     ||= '/ws/api.dll';
    $self->api_config->{version} ||= '543';
        
    unless ( defined $self->api_config->{https} ) {
        $self->api_config->{https} = 1;
    }

    unless ( defined $self->api_config->{siteid} ) {
        $self->api_config->{siteid} = 0;
    }

    $self->_load_yaml_defaults();
    
    if ( $DEBUG ) {
        print STDERR sprintf( "API CONFIG:\n%s\n",
            $self->api_config_dump()
        );        
    }

        
    return $self;
}

=head2 prepare( $verb, $call_data )

  $call->prepare( 'GetSearchResults', { Query => 'shoe' } );
 
This method will construct the API request based on the $verb and
the $call_data.

=item $verb (required)

call verb, i.e. GetSearchResults

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

    # make sure we have appid, devid, certid, token
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

=head2 _validate_response

This is called from the base class. The method is suppose to provide the
custom validation code and push to the error stack if the response isn't
valid

=cut

sub _validate_response {
    my $self = shift;

    if ( $self->nodeContent('Ack') eq 'Failure' ) {
        $self->errors_append( {
            'Call Failure' => $self->nodeContent('LongMessage')
        } );
    }
}

=head2 _get_request_body

This method supplies the request body for the Shopping API call

=cut

sub _get_request_body {
    my $self = shift;

    # if auth_method is set to 'token' use token
    # if auth_method is set to 'iaftoken' use iaftoken
    # if auth_method is set to 'user' use username/password
    if ( $self->{auth_method} eq 'token' ) {
         my $xml = "<?xml version='1.0' encoding='utf-8'?>"
             . "<" . $self->{verb} . "Request xmlns=\"urn:ebay:apis:eBLBaseComponents\">"
             . "<RequesterCredentials><eBayAuthToken>"
             . ( $self->api_config->{token} || '' )
             . "</eBayAuthToken></RequesterCredentials>"
             . XMLout( 
                 $self->{call_data}, 
                 NoAttr => !$self->api_config->{enable_attributes},
                 KeepRoot => 1, 
                 RootName => undef 
             )
             . "</" . $self->{verb} . "Request>";

          return $xml;
    }
    elsif ( $self->{auth_method} eq 'iaftoken' ) {
         my $xml = "<?xml version='1.0' encoding='utf-8'?>"
             . "<" . $self->{verb} . "Request xmlns=\"urn:ebay:apis:eBLBaseComponents\">"
             . XMLout( 
                 $self->{call_data}, 
                 NoAttr => !$self->api_config->{enable_attributes},
                 KeepRoot => 1, 
                 RootName => undef 
             )
             . "</" . $self->{verb} . "Request>";

          return $xml;
    }
    elsif ( $self->{auth_method} eq 'user' ) {
        my $xml = "<?xml version='1.0' encoding='utf-8'?>"
             . "<" . $self->{verb} . "Request xmlns=\"urn:ebay:apis:eBLBaseComponents\">"
             . "<RequesterCredentials><Username>"
             . $self->api_config->{username} . "</Username>";
        
        if ( $self->api_config->{password} ) {
            $xml .= "<Password>"
             . $self->api_config->{password} . "</Password>";
        }
        
        $xml .= "</RequesterCredentials>"
             . XMLout( $self->{call_data}, NoAttr => 1, KeepRoot => 1, RootName => undef )
             . "</" . $self->{verb} . "Request>";

        return $xml;
    }
}

=head2 _get_request_headers

This method supplies the headers for the Shopping API call

=cut

sub _get_request_headers {
    my $self = shift;

    my $obj = HTTP::Headers->new();

    $obj->push_header("X-EBAY-API-COMPATIBILITY-LEVEL" =>
        $self->api_config->{version});
    $obj->push_header("X-EBAY-API-DEV-NAME"  => $self->api_config->{devid});
    $obj->push_header("X-EBAY-API-APP-NAME"  => $self->api_config->{appid});
    $obj->push_header("X-EBAY-API-CERT-NAME" => $self->api_config->{certid});
    $obj->push_header("X-EBAY-API-SITEID"    => $self->api_config->{siteid});
    $obj->push_header("X-EBAY-API-CALL-NAME" => $self->{verb});
    if ( $self->{auth_method} eq 'iaftoken' ) {
        $obj->push_header("X-EBAY-API-IAF-TOKEN" => $self->api_config->{iaftoken});
    }
    $obj->push_header("Content-Type" => "text/xml");

    return $obj;
}

=head2 _get_request_object

This method creates the request object and returns to the parent class

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
    for my $reqd ( qw/devid appid certid/ ) {
        next if defined $self->api_config->{$reqd};

        if ( defined (my $val = $self->_fish_ebay_ini( $reqd )) ) {
            $self->api_config->{$reqd} = $val;
        }
        else {
            push( @missing, $reqd );
        }
    }

    if ( scalar @missing > 0 ) {
        die "missing Authentication: " . join( ", ", @missing );
    }

    # Collect token, iaftoken, username, password, domain, https, uri and version from
    # the ebay.ini file
    # if token found, set auth_method to 'token'
    # if iaftoken found, set auth_method to 'iaftoken'
    # if username/password found set auth_method to 'user'

    for my $optional ( qw/token iaftoken username password domain https uri version/ ) {

       next if defined $self->api_config->{$optional};

       if ( defined ( my $val = $self->_fish_ebay_ini( $optional )) ) {
           $self->api_config->{$optional} = $val;
       }
       else {
           print STDERR "Not defined : " . $optional . "\n" if $DEBUG;
       }
    }

    if ( exists ( $self->api_config->{token} ) ) {
        $self->{auth_method} = 'token';

        delete($self->api_config->{iaftoken});
        delete($self->api_config->{username});
        delete($self->api_config->{password});
    }
    elsif ( exists ( $self->api_config->{iaftoken} ) ) {
        $self->{auth_method} = 'iaftoken';

        delete($self->api_config->{username});
        delete($self->api_config->{password});
    }
    elsif ((exists( $self->api_config->{username} ))
        && (exists( $self->api_config->{password} ))) {
        $self->{auth_method} = 'user';
    }
    elsif ( exists( $self->api_config->{username} ) ) {
        $self->{auth_method} = 'user';        
    }
    else {
        die "missing Authentication : token or username/password \n";
    }


    $self->{_credentials_loaded} = 1;
    return;
}

sub _fish_ebay_ini {
    my $self = shift;
    my $arg  = shift;
    my @files;

    # initialize our hashref
    $self->{_ebay_ini} ||= {};

    # revert eBay::API::Simple keys to standard keys
    $arg = 'DeveloperKey'    if $arg eq 'devid';
    $arg = 'ApplicationKey' if $arg eq 'appid';
    $arg = 'CertificateKey' if $arg eq 'certid';
    $arg = 'Token'          if $arg eq 'token';
    $arg = 'IAFToken'       if $arg eq 'iaftoken';
    $arg = 'UserName'       if $arg eq 'username';
    $arg = 'Password'       if $arg eq 'password';
    $arg = 'Domain'         if $arg eq 'domain';
    $arg = 'Https'          if $arg eq 'https';
    $arg = 'Uri'            if $arg eq 'uri';
    $arg = 'Version'        if $arg eq 'version';

    # return it if we've already found it
    return $self->{_ebay_ini}{$arg} if defined $self->{_ebay_ini}{$arg};

    # ini files in order of importance

    # Make exception for windows
    if ( $^O eq 'MSWin32' ) {
        @files = ( './ebay.ini', './ebay.yaml' );
    }
    else {
          @files = (
              './ebay.yaml',
              "$ENV{HOME}/ebay.yaml",
              '/etc/ebay.yaml',
             './ebay.ini',
             "$ENV{HOME}/ebay.ini",
             '/etc/ebay.ini',
         );
    }

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

1;

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 CONTRIBUTORS

Jyothi Krishnan

=cut
