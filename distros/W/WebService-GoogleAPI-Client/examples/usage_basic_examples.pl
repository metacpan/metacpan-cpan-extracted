#!/usr/bin/env perl

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Which;
use feature 'say';

use Mojo::Util qw/getopt/;

getopt
  'c|credentials' => \my $creds,
  'u|user'        => \my $user;

$creds //= './gapi.json';
die "can't do cool things with no username!" unless $user;

## assumes gapi.json configuration in working directory with scoped project and user authorization
my $gapi_client = WebService::GoogleAPI::Client->new(gapi_json => $creds, user => $user);


use Email::Simple;    ## RFC2822 formatted messages
use MIME::Base64;

my $r;                ## using to contain result of queries ( Mojo::Message::Response instance )


print "Sending email to self\n";
$r = $gapi_client->api_query(
  api_endpoint_id => 'gmail.users.messages.send',
  options         => {
    raw => encode_base64(
      Email::Simple->create(
        header =>
          [To => $user, From => $user, Subject => "Test email from '$user' ",],
        body => "This is the body of email to '$user'",
      )->as_string
    )
  },
);

if ( 0 )
{
  my $text_to_speech_request_options = {
    'input' => {
      'text' => 'Using the Web-Services-Google-Client Perl module, it is now a simple matter to access all of the Google API Resources in a consistent manner. Nice work Peter!'
    },
    'voice'       => { 'languageCode'  => 'en-gb', 'name' => 'en-GB-Standard-A', 'ssmlGender' => 'FEMALE' },
    'audioConfig' => { 'audioEncoding' => 'MP3' }
  };

  ## Using this API requires authorised https://www.googleapis.com/auth/cloud-platform scope

  if ( 0 )    ## use a full manually constructed non validating standard user agent query builder approach ( includes auto O-Auth token handling )
  {
    $r = $gapi_client->api_query( method => 'POST', path => 'https://texttospeech.googleapis.com/v1/text:synthesize', options => $text_to_speech_request_options );

  }
  else        ## use the api end-point id and take full advantage of pre-submission validation etc
  {
    $r = $gapi_client->api_query(
      api_endpoint_id => 'texttospeech.text.synthesize',

      # method => 'POST',                                                   ## not required as determined from API SPEC
      # path   => 'https://texttospeech.googleapis.com/v1/text:synthesize', ## not required as determined from API SPEC
      options => $text_to_speech_request_options
    );
    ## NB - this approach will also autofill any defaults that aren't defined
    ##      confirm that the user has the required scope before submitting to Google.
    ##      confirms that all required fields are populated
    ##      where an error is detected - result is a 418 code ( I'm a teapot ) with the body containing the error descriptions

  }

  if ( $r->is_success )    ## $r is a standard Mojo::Message::Response instance
  {
    my $returned_data = $r->json;   ## convert from json to native hashref - result is a hashref with a key 'audioContent' containing synthesized audio in base64-encoded MP3 format
    my $decoded_mp3 = decode_base64( $returned_data->{ audioContent } );

    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mp3' );    ## should prolly unlink=1 if not planning to use output file in future
    print $tmp $decoded_mp3;

    if ( which( 'ffplay' ) )
    {
      print "ffplay -nodisp  -autoexit  $tmp\n";
      `ffplay -nodisp  -autoexit  $tmp`;

    }
    close( $tmp );

  }
  else
  {
    if ( $r->code eq '418' )
    {
      print qq{Cool - I'm a teapot - this was caught ebfore sending the request through to Google \n};
      print $r->body;
    }
    else    ## other error - should appear in warnings but can inspect $r for more detail
    {
      print Dumper $r;
    }

  }
}


## edge cases to inform improvement to test coverage

my $x = WebService::GoogleAPI::Client->new();
say " WebService::GoogleAPI::Client->new() is a " . ref( $x );

#exit;
#my $y = $x->api_query();
#say Dumper $y;
say "WebService::GoogleAPI::Client->new->api_query() is a " . ref( WebService::GoogleAPI::Client->new->api_query() );    # eq 'Mojo::Message::Response';

say "WebService::GoogleAPI::Client->new->has_scope_to_access_api_endpoint()" . WebService::GoogleAPI::Client->new->has_scope_to_access_api_endpoint();
use WebService::GoogleAPI::Client::Discovery;

#say my $x = WebService::GoogleAPI::Client::Discovery->new->list_of_available_google_api_ids();
say 'fnarly' if ref( WebService::GoogleAPI::Client::Discovery->new->discover_all() ) eq 'HASH';

#say Dumper $x;

say WebService::GoogleAPI::Client::Discovery->new->api_verson_urls;
exit;
my $f = WebService::GoogleAPI::Client::AuthStorage->new;    #->get_credentials_for_refresh();
print Dumper $f;
my $dd = $f->get_credentials_for_refresh();


#say join(',', WebService::GoogleAPI::Client->new->list_of_available_google_api_ids() ) . ' as list';
#say  WebService::GoogleAPI::Client->new->list_of_available_google_api_ids() . ' as scalar';
