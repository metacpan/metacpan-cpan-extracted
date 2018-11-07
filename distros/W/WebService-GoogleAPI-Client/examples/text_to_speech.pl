#!/usr/bin/env perl

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Which;
use feature 'say';
use MIME::Base64;

=head1 text_to_speech.pl

=head2 PRE-REQUISITES

assumes gapi.json configuration in working directory with scoped project and user authorization
  
uses ffplay which is part if ffmpeg to play the mp3 files retrieved through the api
  
     brew install ffmpeg –with-ffplay

L<https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize>

Scope required for Speech API Beta is https://www.googleapis.com/auth/cloud-platform
Assumes that Google Text To Speech API is enabled

See also alternative using gcloud as described at https://cloud.google.com/text-to-speech/docs/quickstart-protocol

=head2 USAGE

    text_to_speech.pl 'welcome to the end of the world' 'welcome.mp3'

first param required, second param of filename optional

=head2 TODO

* more optional parameters 
* Selectable voices - https://cloud.google.com/text-to-speech/docs/voices 
* Check out Google TTS Voice Training Project - https://github.com/google/voice-builder#prerequisites ( Voice Builder: A Tool for Building Text-To-Speech Voices
)

=cut

my $params = {};
$params->{text} = $ARGV[0] || die('require at least 1 param');
$params->{fname} = $ARGV[1] || '';

print "Saying '$params->{text}'\n";


## assumes gapi.json configuration in working directory with scoped project and user authorization
## manunally sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => 0, gapi_json => 'gapi.json' );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );

my $r;
  my $text_to_speech_request_options = {
    'input' => {
      'text' => $params->{text}
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
    my $unlink = 0;
    $unlink = 1 if $params->{fname};
    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.mp3' );    ## should prolly unlink=1 if not planning to use output file in future
    print $tmp $decoded_mp3;
    `cp $tmp $params->{fname}` if $params->{fname};

    if ( which( 'ffplay' ) )
    {
      print "ffplay -nodisp  -autoexit  $tmp\n";
      exec("ffplay -nodisp  -loglevel -8 -autoexit  $tmp");

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