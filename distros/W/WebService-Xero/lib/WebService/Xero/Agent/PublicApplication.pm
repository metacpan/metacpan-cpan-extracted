package WebService::Xero::Agent::PublicApplication;


use 5.006;
use strict;
use warnings;
use base ('WebService::Xero::Agent');

use Crypt::OpenSSL::RSA;
use Digest::MD5 qw( md5_base64 );

use URI::Encode qw(uri_encode uri_decode );
use Data::Random qw( rand_chars );
use Net::OAuth 0.20;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

=head1 NAME

WebService::Xero::Agent::PublicApplication - Connects to Xero Public Application API 

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

Public Applications

Public applications use a 3-legged authorisation process. A user will need to authorise your application against each organisation that 
you want access to. For a great description of the 3-legged flow see L<http://oauthbible.com/#oauth-10a-three-legged> .

For a working example that uses Mojolicious Web Framework see L<https://github.com/pscott-au/mojolicious-xero-public-app-demo>


=head2 XERO PUBLIC APPLICATION API CONFIGURATION

Public applications are configured in the Xero Developer API Console. These setting are used in your application to access your user's Xero Accounting data through Xero's Public Application API.

Your users will be directed from your website to Xero and asked for access confirmation. If they agree your application will use an Access Token to query Xero data for the life of the session (up to 30 minutes).

You application can then access the Xero Services to retrieve, update and create contact, invoices etc.

See L<https://app.xero.com/Application> for more detail.

=head2 TODO



=head1 METHODS

=cut

sub _validate_agent 
{
  my ( $self  ) = @_;
  ## TODO: validate required WebService::Xero::Agent properties required for a public application.

  return $self;
}


=head2 get_request_token()

  Takes the callback URL as a parameter which is used to create the request for
  a request token. The request is submitted to Xero and if successful this
  method eturns the Token and sets the 'login_url' property of the agent.

  Assumes that the public application API configuration is set in the agent ( CONSUMER KEY and SECRET )

=cut 

sub get_request_token ## FOR PUBLIC APP (from old Xero::get_auth_token)
{
  ## talks to Xero to get an auth token 
  my ( $self, $my_callback_url ) = @_;
  my $data = undef;

  
  my $access = Net::OAuth->request("request token")->new(
   'version' => '1.0',
   'request_url' => 'https://api.xero.com/oauth/RequestToken?oauth_callback=' . uri_encode( $my_callback_url ),
    callback =>  $my_callback_url,
    consumer_key     => $self->{CONSUMER_KEY},
    consumer_secret  => $self->{CONSUMER_SECRET},
    request_method   => 'GET',
    signature_method => 'HMAC-SHA1',
    timestamp        => time,
    nonce            => 'ccp' . md5_base64( join('', rand_chars(size => 8, set => 'alphanumeric')) . time ), #$nonce
  );
  $access->sign();
  #warn $access->to_url."\n";
  my $res = $self->{ua}->get( $access->to_url  ); ## {oauth_callback=> uri_encode('http://localhost/')}
  if ($res->is_success)
  {
    my $response = $res->content();
    #warn("GOT A NEW auth_token ---" . $response);
    if ( $response =~ /oauth_token=([^&]+)&oauth_token_secret=([^&]+)&oauth_callback_confirmed=true/m)
    {
      $self->{oauth_token} = $1;#, "\n";
      $self->{oauth_token_secret} = $2;#, "\n";

      $self->{login_url} = 'https://api.xero.com/oauth/Authorize?oauth_token='
            . $self->{oauth_token}
            . '&oauth_callback='
            . $my_callback_url;

      $self->{status} = 'GOT REQUEST TOKEN AND GENERATED Xero login_url that includes callback';
      return $self->{oauth_token};
    }
  } 
  else 
  {
    return $self->_error("ERROR: " . $res->content);
  }
}
#####################################


=head2 get_access_token()

  When Xero redirects the user back to the application it includes parameters that
  when combined with the previously generated token can be used to create an access
  token that can access the Xero API services directly.

INPUT PARAMETERS AS A LIST ( NOT NAMED )

$oauth_token          oauth_token    GET Param includes in the redirected request back from Xero
$oauth_verifier       auth_verifier  GET Param includes in the redirected request back from Xero
$org                  org            GET Param includes in the redirected request back from Xero
$stored_token_secret  
$stored_token

  When the Xero callback redirect returns the user to the application after authorising the
  app in Xero, the get params oauth_token and oauth_verifier are included in the URL which


=cut 


#####################################
sub get_access_token  ## FOR PUBLIC APP
{
  my ( $self,  $oauth_token, $oauth_verifier, $org, $stored_token_secret, $stored_token ) = @_;
  my $data = undef;
  if ( defined $stored_token_secret )
  {

    my $new_oauth_token_secret = $self->{CONSUMER_SECRET} . '&' .$stored_token_secret;

    my $uri = "https://api.xero.com/oauth/AccessToken";
    my $access = Net::OAuth->request("access token")->new(
      consumer_key     => $self->{CONSUMER_KEY},
      consumer_secret  => $self->{CONSUMER_SECRET}, 
      token_secret            => $stored_token_secret,  ## persistently stored session token 
      token                   => $stored_token,         ## persistently stored session token 
      verifier         => $oauth_verifier,
      request_url      => $uri,
      request_method   => 'GET',
      signature_method => 'HMAC-SHA1',
      timestamp        => time,
      nonce            => join('', rand_chars(size=>16, set=>'alphanumeric')),
      version          => '1.0',
    );
    $access->sign();
    return $self->_error( "COULDN'T VERIFY! Check OAuth parameters.") unless $access->verify;
    my $res = $self->{ua}->get( $access->to_url );  
    my $x = $res->content;
    if ($res->is_success)
    {
      $data = $x;
      if ( $x =~ /oauth_token=([^\&]+)\&oauth_token_secret=([^\&]+)\&oauth_expires_in=(\d+)\&xero_org_muid=(.*)$/m )
      {
         $self->{oauth_token} = $1; $self->{oauth_token_secret} = $2; $self->{oauth_expires_in} = $3; $self->{xero_org_muid} = $4;
         $self->{TOKEN} = $self->{oauth_token}; $self->{TOKEN_SECRET} = $self->{oauth_token_secret};
         $self->{status} = 'GOT ACCESS TOKEN';
        #warn (qq{replacing oauth_token=$self->{oauth_token} and token_secret= $self->{oauth_token_secret}});
      }
      else {
        $self->{status} = 'GOT A RESPONSE FROM XERO TO REQUEST FOR ACCESS TOKEN BUT UNABLE TO UNDERSTAND IT';
        return $self->_error("Failed to extract tokens from $x");
      }
      
      return $res->content;
    } else {
       return $self->_error("ERROR: " . $res->content);
    }
  }
  else 
  {
    return $self->_error("Unable to recover xero_token for user_id=$self->{customer_id} to build request for access token");;
  }
  return $data;
}
#####################################


=head2 do_xero_api_call()

  INPUT PARAMETERS AS A LIST ( NOT NAMED )

* $uri (required)    - the API endpoint URI ( eg 'https://api.xero.com/api.xro/2.0/Contacts/')
* $method (optional) - 'POST' or 'GET' .. PUT not currently supported
* $xml (optional)    - the payload for POST updates as XML

  RETURNS

    The response is requested in JSON format which is then processed into a Perl structure that
    is returned to the caller.



=head2 The OAuth Dance

Public Applications require the negotiation of a token by directing the user to Xero to authenticate and accepting the callback as the
user is redirected to your application.

To implement you need to persist token details across multiple user web page requests in your application.

To fully understand the integration implementation requirements it is useful to familiarise yourself with the terminology.

=head3 OAUTH 1.0a TERMINOLOGY

=begin TEXT

User              A user who has an account of the Service Provider (Xero) and tries to use the Consumer. (The API Application config in Xero API Dev Center .)
Service Provider  Service that provides Open API that uses OAuth. (Xero.)
Consumer          An application or web service that wants to use functions of the Service Provider through OAuth authentication. (End User)
Request Token     A value that a Consumer uses to be authorized by the Service Provider After completing authorization, it is exchanged for an Access Token. 
                    (The identity of the guest.)
Access Token      A value that contains a key for the Consumer to access the resource of the Service Provider. (A visitor card.)

=end TEXT


=head2 Authentication occurs in 3 steps (legs):

=head3 Step 1 - Get an Unauthorised Request Token  

    use WebService::Xero::Agent::PublicApplication;

    my $xero = WebService::Xero::Agent::PublicApplication->new( CONSUMER_KEY    => 'YOUR_OAUTH_CONSUMER_KEY', 
                                                          CONSUMER_SECRET => 'YOUR_OAUTH_CONSUMER_SECRET', 
                                                          CALLBACK_URL    => 'http://localhost/xero_tester.cgi'
                                                          );
    my $callback_url = 'http://localhost/cgi-bin/test_xero_public_application.cgi'; ## NB Domain must be configured in Xero App Config
    $xero->get_request_token(  $callback_url ); ## This generates the token to include in the user redirect (A)
    ## NB need to store $xero->{oauth_token},$xero->{oauth_token_secret} in persistent storage as will be required at later steps for this session.
    print $xero->{login_url}; ## need to include a link to this URL in your app for the user to click on    (B)

=head3 Step 2 - Redirect User

    user click on link to $xero->{login_url} which takes them to Xero - when they authorise your app they are redirected back to your callback URL (C)(D)


=head3 Step 3 - Swap a Request Token for an Access Token

    The callback URL includes extra GET parameters that are used with the token details stored earlier to obtain an access token.
    
   my $oauth_verifier = $cgi->url_param('oauth_verifier');
   my $org            = $cgi->param('org');
   my $oauth_token    = $cgi->url_param('oauth_token');

   $xero->get_access_token( $oauth_token, $oauth_verifier, $org, $stored_token_secret, $stored_oauth_token ); ## (E)(F)

=head3 Step 4 - Access the Xero API using the access token 

    my $contact_struct = $xero->do_xero_api_call( 'https://api.xero.com/api.xro/2.0/Contacts' );  ## (G)


=head2 Other Notes

The access token received will expire after 30 minutes. If you want access for longer you will need the user to re-authorise your application.

Xero API Applications have a limit of 1,000/day and 60/minute request per organisation.

Your application can have access to many organisations at once by going through the authorisation process for each organisation.

=head3 Xero URLs used for authorisation and using the API

Get an Unauthorised Request Token:  https://api.xero.com/oauth/RequestToken
Redirect a user:  https://api.xero.com/oauth/Authorize
Swap a Request Token for an Access Token: https://api.xero.com/oauth/AccessToken
Connect to the Xero API:  https://api.xero.com/api.xro/2.0/


=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Xero::Agent::PublicApplication


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Xero>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Xero>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Xero>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Xero/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Scott.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.




=begin HTML

<p><img src="https://oauth.net/core/diagram.png"></p>

=end HTML

=cut

1; # End of WebService::Xero
