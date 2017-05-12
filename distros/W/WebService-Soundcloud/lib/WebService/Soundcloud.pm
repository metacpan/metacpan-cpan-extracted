package WebService::Soundcloud;

use 5.006;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use URI;
use JSON qw(decode_json);
use Data::Dumper;
use HTTP::Headers;
use Scalar::Util qw(reftype);

# declare domains
our %domain_for = (
   'prod'        => 'https://api.soundcloud.com/',
   'production'  => 'https://api.soundcloud.com/',
   'development' => 'https://api.sandbox-soundcloud.com/',
   'dev'         => 'https://api.sandbox-soundcloud.com/',
   'sandbox'     => 'https://api.sandbox-soundcloud.com/'
);

our $DEBUG    = 0;
our %path_for = (
   'authorize'    => 'connect',
   'access_token' => 'oauth2/token'
);

our %formats = (
   '*'    => '*/*',
   'json' => 'application/json',
   'xml'  => 'application/xml'
);

our $VERSION = '0.04';

=pod

=head1 NAME

WebService::Soundcloud - Thin wrapper around Soundcloud RESTful API!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    #!/usr/bin/perl
    use WebService::Soundcloud;
    
    my $scloud = WebService::Soundcloud->new($client_id, $client_secret, 
                           { redirect_uri => 'http://mydomain.com/callback' }
                         );
    
    # Now get authorization url
    my $authorization_url = $scloud->get_authorization_url();
    
    # Redirect the user to authorization url
    use CGI;
    my $q = new CGI;
    $q->redirect($authorization_url);
    
    # In your '/callback' handler capture code params
    # Check for error
    if ($q->param(error)) {
    	die "Authorization Failed: ". $q->param('error');
    }
    # Get authorization code
    my $code = $q->param('code');
    
    # Get Access Token
    my $access_token = $scloud->get_access_token($code);
    
    # Save access_token and refresh_token, expires_in, scope for future use
    my $oauth_token = $access_token->{access_token};
    
    # OAuth Dance is completed :-) Have fun now.

    # Default request and response formats are 'json'
    
    # a GET request '/me' - gets users details
    my $user = $scloud->get('/me');
    
    # a PUT request '/me' - updated users details
    my $user = $scloud->put('/me', encode_json(
                { 'user' => {
                  'description' => 'Have fun with Perl wrapper to Soundcloud API'
                } } ) );
                
    # Comment on a Track POSt request usage
    my $comment = $scloud->post('/tracks/<track_id>/comments', 
                            { body => 'I love this hip-hop track' } );
    
    # Delete a track
    my $track = $scloud->delete('/tracks/{id}');
    
    # Download a track
    my $file_path = $scloud->download('<track_id>', $dest_file);


=head1 DESCRIPTION

This module provides a wrapper around Soundcloud RESTful API to work with 
different kinds of soundcloud resources. It contains many functions for 
convenient use rather than standard Soundcloud RESTful API.

The complete API is documented at http://developers.soundcloud.com/docs.

In order to use this module you will need to register your application
with Soundcloud at http://soundcloud.com/you/apps : your application will
be given a client ID and a client secret which you will need to use to 
connect.

=head2 METHODS

=over 4

=item new

Returns a newly created C<WebService::Soundcloud> object. The first
argument is $client_id, the second argument is $client_secret - these
are required and will have been provided when you registered your
application with Soundcloud The third optional argument is a 
HASHREF that contains additional parameters that may be required:

=over 4

=item redirect_uri

This is the URI of your application to which the user will be redirected
after they have authorised the connection with Soundcloud.  This should
be the same as the one provided when you registered your application and
will be required for most applications.

=back

=cut

sub new
{
   my ($class, $client_id, $client_secret, $options ) = @_;

   if(!defined $client_id && !defined $client_secret )
   {
       croak "Client ID and Secret required";
   }

   $options = {} unless defined $options;

   my $self = bless $options, $class;

   $self->client_id($client_id);
   $self->client_secret($client_secret);

   $options->{debug}         = $DEBUG unless ( $options->{debug} );


   return $self;
}

=item client_id

Accessor for the Client ID that was provided when you registered your
application.

=cut

sub client_id
{
    my ( $self, $client_id ) = @_;

   if ( defined $client_id ) 
   {
       $self->{client_id} = $client_id;
   }

   return $self->{client_id};
}

=item client_secret

Accessor for the Client Secret that was provided when you registered
your application.

=cut

sub client_secret
{
    my ( $self, $client_secret ) = @_;

   if ( defined $client_secret ) 
   {
       $self->{client_secret} = $client_secret;
   }

   return $self->{client_secret};
}

=item redirect_uri

Accessor for the redirect_uri this can be passed as an option to the
constructor or supplied later (before any connect call.) This should
match to that provided when you registered your application.

It is the URI of your application that the user will be redirected
(with the authorization code as a parameter,) after they have clicked
"Connect" on the soundcloud connect page.  This will not be used if
you are using the credential based authentication to obtain the OAuth token
(e.g if you are an application with no UI that is operating for a single
user.)

=cut

sub redirect_uri
{
    my ( $self, $redirect_uri ) = @_;

   if ( defined $redirect_uri ) 
   {
       $self->{redirect_uri} = $redirect_uri;
   }

   return $self->{redirect_uri};
}

=item basic_params

This returns a HASHREF that is suitable to be used as the basic parameters
in most places, containing the application credentials (ID and Secret) and
redirect_uri

=cut

sub basic_params
{
    my ( $self ) = @_;

    my $params = {
        client_id => $self->client_id(),
        client_secret   => $self->client_secret(),
    };

    if ( defined $self->redirect_uri() )
    {
        $params->{redirect_uri} = $self->redirect_uri();
    }

    return $params;

}

=item ua

Returns the L<LWP::UserAgent> object that will be used to connect to the
API host

=cut

sub ua
{
    my ( $self ) = @_;

    if (!defined $self->{user_agent} )
    {
        $self->{user_agent} = LWP::UserAgent->new();
    }

    return $self->{user_agent};
}

=item get_authorization_url

This method is used to get authorization url, user should be redirected
for authenticate from soundcloud. This will return URL to which user
should be redirected.

=cut

sub get_authorization_url
{
   my ( $self, $args ) = @_;
   my $call   = 'get_authorization_url';
   my $params = $self->basic_params();

   $params->{response_type} = 'code';

   $params = { %{$params}, %{$args} } if ref($args) eq 'HASH';
   my $authorize_url = $self->_build_url( $path_for{'authorize'}, $params );
   return $authorize_url;
}

=item get_access_token

This method is used to receive access_token, refresh_token,
scope, expires_in details from soundcloud once user is
authenticated. access_token, refresh_token should be stored as it should
be sent along with every request to access private resources on the
user behalf.

The argument C<$code> is required unless you are using credential based
authentication, and will have been supplied to your C<redirect_uri> after
the user pressed "Connect" on the soundcloud connect page.

=cut

sub get_access_token
{
   my ( $self, $code, $args ) = @_;
   my $request;
   my $call   = 'get_access_token';
   my $params = $self->_access_token_params($code);

   $params = { %{$params}, %{$args} } if ref($args) eq 'HASH';
   return $self->_access_token($params);
}

=item _access_token_params

=cut

sub _access_token_params
{
   my ( $self, $code ) = @_;

   my $params = $self->basic_params();

   if ( $self->{scope} )
   {
      $params->{scope} = $self->{scope};
   }
   if ( $self->{username} && $self->{password} )
   {
      $params->{username}   = $self->{username};
      $params->{password}   = $self->{password};
      $params->{grant_type} = 'password';
   }
   elsif ( defined $code )
   {
      $params->{code}       = $code;
      $params->{grant_type} = 'authorization_code';
   }
   else
   {
      die "neither credentials or auth code provided";
   }

   return $params;
}

=item get_access_token_refresh

This method is used to get new access_token by exchanging refresh_token
before the earlier access_token is expired. You will receive new
access_token, refresh_token, scope and expires_in details from
soundcloud. access_token, refresh_token should be stored as it should
be sent along with every request to access private resources on the
user behalf.

If a C<scope> of 'non-expiring' was supplied at the time the initial tokem
was obtained then this should not be necessary.

=cut

sub get_access_token_refresh
{
   my ( $self, $refresh_token, $args ) = @_;

   my $params = $self->basic_params();

   $params->{refresh_token} = $refresh_token;
   $params->{grant_type}    = 'refresh_token';

   $params = { %{$params}, %{$args} } if ref($args) eq 'HASH';
   return $self->_access_token($params);
}

=item request

This performs an HTTP request with the $method supplied to the supplied
$url. The third argument $headers can be supplied to insert any required
headers into the request, if $content is supplied it will be processed
appropriately and inserted into the request.

An L<HTTP::Response> will be returned and this should be checked to
determine the status of the request.

=cut

sub request
{
   my ( $self, $method, $url, $headers, $content ) = @_;
   my $req = HTTP::Request->new( $method, $url, $headers );

   if ( defined $content )
   {
      my $u = URI->new();
      $u->query_form($content);
      my $query = $u->query();
      $req->content($query);
   }
   $self->log($req->as_string());
   return $self->ua()->request($req);
}

=item get_object

This returns a decoded object corresponding to the URI given

It will for the response_format to 'json' for the request as
parsing the XML is tricky given no schema.

=cut

sub get_object
{
   my ( $self, $url, $params, $headers ) = @_;

   my $obj;

   my $save_response_format = $self->response_format();
   $self->response_format('json');

   my $res = $self->get( $url, $params, $headers );

   if ( $res->is_success() )
   {
      $obj = decode_json( $res->decoded_content() );
   }

   $self->response_format($save_response_format);

   return $obj;
}

=item get_list

This returns a decoded LIST REF of the list method specified by URI

Currently this will force response_format to 'json' as parsin the XML
is tricky without a schema.

=cut

sub get_list
{
   my ( $self, $url, $params, $headers ) = @_;

   my $ret      = [];
   my $continue = 1;
   my $offset   = 0;
   my $limit    = 50;

   my $save_response_format = $self->response_format();
   $self->response_format('json');

   if ( !defined $params )
   {
      $params = {};
   }
   while ($continue)
   {
      $params->{limit}  = $limit;
      $params->{offset} = $offset;

      my $res = $self->get( $url, $params, $headers );

      if ( $res->is_success() )
      {
         if (defined(my $obj = $self->parse_content( $res->decoded_content())))
         {
             if (defined (my $type = reftype($obj) ) )
             {
                 if ( $type eq 'ARRAY' )
                 {
                     $offset += $limit;
                     $continue = scalar @{$obj};
                 }
                 elsif ( $type eq 'HASH' )
                 {
                     if ( exists $obj->{collection} )
                     {
                        if(!defined($url = $obj->{next_href}))
                        {
                            $continue = 0;
                        }
                        $obj = $obj->{collection};
                     }
                     else
                     {
                         croak "not a collection";
                     }
                 }
                 else
                 {
                     croak "Unexpected $type reference instead of list";
                 }
                  push @{$ret}, @{$obj};
             }
         }
         else
         {
             $continue = 0;
         }
      }
      else
      {
         warn $res->request()->uri();
         die $res->status_line();
      }
   }

   $self->response_format($save_response_format);

   return $ret;
}

=item get(<URL>, <PARAMS>, <HEADERS>)

This method is used to dispatch GET request on the give URL(first argument).
second argument is an anonymous hash request parameters to be send along with GET request.
The third optional argument(<HEADERS>) is used to send headers. 
This method will return HTTP::Response object

=cut

sub get
{
   my ( $self, $path, $params, $extra_headers ) = @_;
   my $url = $self->_build_url( $path, $params );
   my $headers = $self->_build_headers($extra_headers);
   return $self->request( 'GET', $url, $headers );
}

=item I<$OBJ>->post(<URL>, <CONTENT>, <HEADERS>)

This method is used to dispatch POST request on the give URL(first argument).
second argument is the content to be posted to URL.
The third optional argument(<HEADERS>) is used to send headers.
This method will return HTTP::Response object

=cut

sub post
{
   my ( $self, $path, $content, $extra_headers ) = @_;
   my $url     = $self->_build_url($path);
   my $headers = $self->_build_headers($extra_headers);
   return $self->request( 'POST', $url, $headers, $content );
}

=item I<$OBJ>->put(<URL>, <CONTENT>, <HEADERS>)

This method is used to dispatch PUT request on the give URL(first argument).
second argument is the content to be sent to URL.
The third optional argument(<HEADERS>) is used to send headers.
This method will return HTTP::Response object

=cut

sub put
{
   my ( $self, $path, $content, $extra_headers ) = @_;
   my $url = $self->_build_url($path);

# Set Content-Length Header as well otherwise nginx will throw 411 Length Required ERROR
   $extra_headers->{'Content-Length'} = 0
     unless $extra_headers->{'Content-Length'};
   my $headers = $self->_build_headers($extra_headers);
   return $self->request( 'PUT', $url, $headers, $content );
}

=item I<$OBJ>->delete(<URL>, <PARAMS>, <HEADERS>)

This method is used to dispatch DELETE request on the give URL(first argument).
second optional argument is an anonymous hash request parameters to be send 
along with DELETE request. The third optional argument(<HEADERS>) is used to 
send headers. This method will return HTTP::Response object

=cut

sub delete
{
   my ( $self, $path, $params, $extra_headers ) = @_;
   my $url = $self->_build_url( $path, $params );
   my $headers = $self->_build_headers($extra_headers);
   return $self->request( 'DELETE', $url, $headers );
}

=item I<$OBJ>->download(<TRACK_ID>, <DEST_FILE>)

This method is used to download a particular track id given as first argument.
second argument is name of the destination path where the downloaded track will 
be saved to. This method will return the file path of downloaded track.

=cut

sub download
{
   my ( $self, $trackid, $file ) = @_;
   my $url = $self->_build_url( "/tracks/$trackid/download", {});
   $self->log($url);

   my $rc = 0;
   # Set Response format to */*
   # Memorize old response format
   my $old_response_format = $self->{response_format};
   $self->response_format('*');
   my $headers = $self->_build_headers();
   $self->ua()->add_handler('response_redirect',\&_our_redirect);
   my $response = $self->request( 'GET', $url, $headers );

   $self->ua()->remove_handler('response_redirect');

   if (!($rc = $response->is_success()))
   {

       $self->log($response->request()->as_string());
       $self->log($response->as_string());
       foreach my $red ( $response->redirects() )
       {
           $self->log($red->request()->as_string());
           $self->log($red->as_string());
       }
   }
   # Reset response format
   $self->{response_format} = $formats{$old_response_format};
   return $rc;
}

=item _our_redirect

This subroutime is intended to be used as a callback on 'response_redirect'
It processes the response to make a new request for the redirect with the
Authorization header removed so that EC3 doesn't get confused.

=cut 

sub _our_redirect
{
   my ( $response, $ua, $h ) = @_;

   my $code = $response->code();

   my $req;

   if (_is_redirect($code) )
   {
       my $referal =  $response->request()->clone();
       $referal->remove_header('Host','Cookie','Referer','Authorization');

       if (my $ref_uri = $response->header('Location'))
       {
           my $uri = URI->new($ref_uri);
           $referal->header('Host' => $uri->host());
         $referal->uri($uri);
         if ( $ua->redirect_ok($referal, $response) )
         {
             $req = $referal;
         }
       }
   }

   return $req;
}

=item _is_redirect

Helper subroutine to determine if the code indicates a redirect.

=cut

sub _is_redirect
{
   my ($code) = @_;

   my $rc = 0;

   if ( defined $code )
   {
      if (  $code == &HTTP::Status::RC_MOVED_PERMANENTLY
         or $code == &HTTP::Status::RC_FOUND
         or $code == &HTTP::Status::RC_SEE_OTHER
         or $code == &HTTP::Status::RC_TEMPORARY_REDIRECT )
      {
         $rc = 1;
      }
   }
   return $rc;
}

=item request_format

Accessor for the request format to be used.  Acceptable values are 'json' and
'xml'.  The default is 'json'.
=cut

sub request_format
{
   my ( $self, $format ) = @_;

   if ($format)
   {
      $self->{request_format} = $format;
   }
   elsif(!defined $self->{request_format})
   {
      $self->{request_format} = 'json';
   }

   return $self->{request_format};
}

=item response_format

Accessor for the response format to be used.  The allowed values are 'json'
and 'xml'.  The default is 'json'.  This will cause the appropriate setting
of the Accept header in requests.

=cut

sub response_format
{
   my ( $self, $format ) = @_;
   if ($format)
   {
      $self->{response_format} = $format;
   }
   elsif (!defined $self->{response_format})
   {
      $self->{response_format} = 'json';
   }
   return $self->{response_format};
}

=item parse_content

This will return the parsed object corresponding to the response content
passed as asn argument.  It will select the appropriate parser based on the
value of 'response_format'.

It will return undef if there is a problem with the parsing.

=cut

sub parse_content
{
    my ( $self, $content ) = @_;

    my $object;

   if ( defined $content )
   {

      eval
      {
          if ( $self->response_format() eq 'json' )
          {
              $object = decode_json($content);
          }
          elsif ( $self->response_format() eq 'xml' )
          {
              require XML::Simple;
              my $xs = XML::Simple->new();
              $object = $xs->XMLin($content);
          }
      };
      if ( $@ )
      {
          warn $@;
      }
   }
    return $object;
}

=back

=head1 INTERNAL SUBROUTINES/METHODS

Please do not use these internal methods directly. They are internal to 
WebService::Soundcloud module itself. These can be renamed/deleted/updated at any point 
of time in future.

=over 4

=item I<$OBJ>->_access_token(<PARAMS>)

This method is used to get access_token from soundcloud. This will be called 
from get_access_token and get_access_token_refresh methods.

=cut

sub _access_token
{
   my ( $self, $params ) = @_;
   my $call     = '_access_token';
   my $url      = $self->_access_token_url();
   my $headers  = $self->_build_headers();
   my $response = $self->request( 'POST', $url, $headers, $params );
   die "Failed to fetch " 
     . $url . " "
     . $response->content() . " ("
     . $response->status_line() . ")"
     unless $response->is_success;
   my $uri          = URI->new;
   my $access_token = decode_json( $response->decoded_content );

   # store access_token, refresh_token
   foreach (qw(access_token refresh_token expire expires_in))
   {
      $self->{$_} = $access_token->{$_};
   }

   # set access_token, refresh_token
   return $access_token;
}

=item I<$OBJ>->_access_token_url(<PARAMS>)

This method is used to get access_token_url of soundcloud RESTful API. 
This will be called from _access_token method.

=cut

sub _access_token_url
{
   my ( $self, $params ) = @_;
   my $url = $self->_build_url( $path_for{'access_token'}, $params );
   return $url;
}

=item I<$OBJ>->_build_url(<PATH>, PARAMS>)

This method is used to prepare absolute URL for a given path and request parameters.

=cut

sub _build_url
{
   my ( $self, $path, $params ) = (@_);
   my $call = '_build_url';

   # get base URL
   my $base_url =
     $self->{development} ? $domain_for{development} : $domain_for{production};

   #$params->{client_id} = $self->client_id();
   # Prepare URI Object
   my $uri = URI->new_abs( $path, $base_url );
   
   if ( $uri->query() )
   {
       $params = { %{$params || {}}, $uri->query_form() };
   }
   $uri->query_form( %{$params} );
   return $uri;
}

=item I<$OBJ>->_build_headers(<HEADERS>)

This method is used to set extra headers to the current HTTP Request.

=cut

sub _build_headers
{
   my ( $self, $extra ) = @_;
   my $headers = HTTP::Headers->new;

   $headers->header( 'Accept' => $formats{ $self->{response_format} } )
     if ( $self->{response_format} );
   $headers->header( 'Content-Type' => $formats{ $self->{request_format} } . '; charset=utf-8' )
     if ( $self->{request_format} );
   $headers->header( 'Authorization' => "OAuth " . $self->{access_token} )
     if ( $self->{access_token} && !$extra->{no_auth});
   foreach my $key ( %{$extra} )
   {
      $headers->header( $key => $extra->{$key} );
   }
   return $headers;
}

=item I<$OBJ>->log(<MSG>)

This method is used to write some text to STDERR.

=cut

sub log
{
   my ( $self, $msg ) = @_;
   if ( $self->{debug} )
   {
      print STDERR "$msg\n";
   }
}

=back

=head1 AUTHOR

Mohan Prasad Gutta, C<< <mohanprasadgutta at gmail.com> >>

=head1 CONTRIBUTORS

Jonathan Stowe C<jns+gh@gellyfish.co.uk>

=head1 BUGS

Parts of this are extremely difficult to test properly so there almost
certainly will be bugs, please feel free to fix and send me a patch if
you find one.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc WebService::Soundcloud
    You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Soundcloud>

=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/WebService-Soundcloud>

=item * CPAN Ratings
L<http://cpanratings.perl.org/d/WebService-Soundcloud>

=item * Search CPAN
L<http://search.cpan.org/dist/WebService-Soundcloud/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mohan Prasad Gutta.
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut

1;
