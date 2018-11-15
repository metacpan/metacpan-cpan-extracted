#!/usr/bin/env perl

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Which;
use feature 'say';
use MIME::Base64;

require './EXAMPLE_HELPERS.pm'; ## check_api_endpoint_and_user_scopes() and display_api_summary_and_return_versioned_api_string()


#use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
# binmode(STDOUT, ":utf8"); ## to allow output of utf to terminal - see also http://perldoc.perl.org/perlrun.html#-C

=head1 translation_example.pl

Provides an OAUTH'd client interface to L<https://cloud.google.com/translate/>

    perl translation_example.pl "this is english - translate into French for me"

NB: Defaults English to French - modify source code to adjust settings.


=for html
<a href="https://code.google.com/apis/language/translate/v2/getting_started.html"><img src="https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"></a>

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. You may need 
to enable billing to access Google Cloud Services.
Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 REQUIRED SCOPES

=over 2

=item  L<https://www.googleapis.com/auth/cloud-translation>

=item  L<https://www.googleapis.com/auth/cloud-platform>

=back

                      {
                         'discoveryRestUrl' => 'https://translation.googleapis.com/$discovery/rest?version=v2',
                         'description' => 'Integrates text translation into your website or application.',
                         'preferred' => true,
                         'kind' => 'discovery#directoryItem',
                         'id' => 'translate:v2',
                         'version' => 'v2',
                         'title' => 'Cloud Translation API',
                         'icons' => {
                                      'x32' => 'https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png',
                                      'x16' => 'https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png'
                                    },
                         'name' => 'translate',
                         'documentationLink' => 'https://code.google.com/apis/language/translate/v2/getting_started.html'
                       },




=head2 GOOGLE API LINKS

=over 2

=item L<https://console.developers.google.com/apis/>

=item L<https://cloud.google.com/translate/docs/reference/translate>

=item L<https://developers.google.com/apis-explorer/>

=back 

=head2 TODO



=cut


my $params = {};
$params->{text} = $ARGV[0] || die('require at least 1 param');

print "Translating '$params->{text}'\n";


## assumes gapi.json configuration in working directory with scoped project and user authorization
## manunally sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => 0, gapi_json => 'gapi.json', debug=>0 );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );

#my $list = $gapi_client->discover_all();
#say Dumper $list;

## interestingly an auth'd request is denied without the correct scope .. so can't use that to find the missing scope :)
#my $methods = $gapi_client->methods_available_for_google_api_id( 'translate' );
#say join(',', keys %$methods );

## todo include a check and handle if only pass in the api endpoint without the hash key
##    - should not need to pass in options ! 

#my $r = $gapi_client->api_query(  api_endpoint_id => 'translate.languages.list'); 
#say Dumper $r->json;


## 

check_api_endpoint_and_user_scopes( $gapi_client, 'translate.translations.translate' );


my $r = $gapi_client->api_query(  api_endpoint_id => 'translate.translations.translate', 
                                  options => { 
                                      q=> $params->{text},
                                      target => 'fr',
                                      format => 'text',
                                  } );
#say Dumper $r->json;
say $r->json->{data}{translations}[0]{translatedText};



