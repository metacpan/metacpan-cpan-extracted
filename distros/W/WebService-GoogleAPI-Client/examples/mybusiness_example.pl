#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
use feature 'say';
use JSON;
use Carp;
use strict;
use warnings;



=pod

                     },
## SEE ALSO - https://github.com/APIs-guru/openapi-directory/blob/master/APIs/googleapis.com/

https://mybusiness.googleapis.com/$discovery/rest?version=v4

=head2 MYBUSINESS API ENDPOINTS

mybusiness.accounts.locations.findMatches
mybusiness.accounts.locations.reviews.deleteReply
mybusiness.accounts.admins.create
mybusiness.accounts.invitations.accept
mybusiness.accounts.generateAccountNumber
mybusiness.accounts.locations.admins.create
mybusiness.accounts.locations.verifications.complete
mybusiness.accounts.locations.get
mybusiness.accounts.locations.patch
mybusiness.accounts.locations.media.create
mybusiness.chains.get
mybusiness.googleLocations.search
mybusiness.accounts.locations.reviews.list
mybusiness.accounts.locations.delete
mybusiness.accounts.locations.reviews.get
mybusiness.accounts.locations.create
mybusiness.accounts.locations.localPosts.reportInsights
mybusiness.accounts.locations.getGoogleUpdated
mybusiness.accounts.list
mybusiness.accounts.deleteNotifications
mybusiness.chains.search
mybusiness.accounts.invitations.list
mybusiness.accounts.locations.list
mybusiness.accounts.locations.reportInsights
mybusiness.accounts.locations.clearAssociation
mybusiness.accounts.admins.patch
mybusiness.accounts.locations.admins.patch
mybusiness.attributes.list
mybusiness.accounts.locations.media.customers.list
mybusiness.accounts.locations.media.patch
mybusiness.accounts.locations.localPosts.delete
mybusiness.accounts.locations.reviews.updateReply
mybusiness.accounts.invitations.decline
mybusiness.accounts.locations.media.delete
mybusiness.accounts.locations.media.get
mybusiness.accounts.locations.verify
mybusiness.accounts.locations.media.startUpload
mybusiness.accounts.getNotifications
mybusiness.accounts.locations.localPosts.create
mybusiness.accounts.update
mybusiness.accounts.locations.transfer
mybusiness.accounts.admins.delete
mybusiness.accounts.locations.fetchVerificationOptions
mybusiness.accounts.locations.admins.list
mybusiness.accounts.locations.localPosts.patch
mybusiness.accounts.updateNotifications
mybusiness.accounts.locations.localPosts.list
mybusiness.accounts.locations.verifications.list
mybusiness.accounts.get
mybusiness.accounts.locations.media.customers.get
mybusiness.accounts.locations.media.list
mybusiness.accounts.locations.batchGet
mybusiness.categories.list
mybusiness.accounts.locations.admins.delete
mybusiness.accounts.locations.localPosts.get
mybusiness.accounts.locations.associate
mybusiness.accounts.admins.list

=head2 SCOPES

As of writing this, the scopes are not defined in the discoverable resources and must be set

=head2 GOALS

  - show summary details pulled from discovery docs 
  - show all methods in HTML table with description including code snippets for worked examples
  - describe helper functions the simplify data handling
  - inform improvements to core Modules ( param parsing / validation / feature evolution etc )
  - idenitfy opportunities for use in full working applications 

=cut

my $DEBUG = 1;


      ##    BASIC CLIENT CONFIGURATION 

if ( -e './gapi.json')  { say "auth file exists" } else { croak('I only work if gapi.json is here'); }; ## prolly better to fail on setup ?
my $gapi_agent = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json =>'./gapi.json'  );
my $aref_token_emails = $gapi_agent->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0]; ## default to the first user
$gapi_agent->user( $user );

say "Running tests with default user email = $user";
say 'Root cache folder: ' .  $gapi_agent->discovery->chi->root_dir(); ## cached content temporary directory 

my $api = 'mybusiness';


if ( 1== 0 ) ## allows augment with Google My Business API Definition - as at 14th October 
{
  ## DISCOVERY SPECIFICATION - mostly internal - user shouldn't need to use this
  say "keys of api discovery hashref = " . join(',', sort keys ( %{WebService::GoogleAPI::Client::Discovery->new->discover_all() }) );
  #my $discover_all = WebService::GoogleAPI::Client::Discovery->new->discover_all( 1  ); ## passing in a 1 forces a reload

  ## augment with the mybusiness structure
$gapi_agent->discovery->augment_discover_all_with_unlisted_experimental_api( 
                     {
                       'version' => 'v4',
                       'preferred' => 1,
                       'title' => 'Google My Business API',
                       'description' => 'The Google My Business API provides an interface for managing business location information on Google.',
                       'id' => 'mybusiness:v4',
                       'kind' => 'discovery#directoryItem',
                       'documentationLink' => "https://developers.google.com/my-business/",
                       'icons' => {
                                  "x16"=> "http://www.google.com/images/icons/product/search-16.gif",
                                  "x32"=> "http://www.google.com/images/icons/product/search-32.gif"
                                },
                       'discoveryRestUrl' => 'https://developers.google.com/my-business/samples/mybusiness_google_rest_v4p2.json',
                       'name' => 'mybusiness'
                     }  );

  #my $discover_all = WebService::GoogleAPI::Client::Discovery->new->discover_all(  ); ## passing in a 1 forces a reload
  my $discover_all = $gapi_agent->discover_all(  );
  #exit;
  print Dumper $discover_all ; 
  for my $api ( @{ $discover_all->{items} } )
  {
    if ( $api->{preferred} )
    {
      my $key = "$api->{name}/$api->{version}/rest";
      #print my $v1 = qq{$api->{preferred} $api->{name} $api->{version} https://www.googleapis.com/discovery/v1/apis/$key \n};
      say my $v2 = qq{$api->{preferred} $api->{name} $api->{version} $api->{discoveryRestUrl}};
    }
    
    #WebService::GoogleAPI::Client::Discovery->new->get_rest({api});
  }
  #exit;
}

if ( 1 == 1 )
{
  my $api_spec = $gapi_agent->get_api_discovery_for_api_id( $api );
  ## keys = auth, basePath, baseUrl, batchPath, description, discoveryVersion, documentationLink, etag, icons, id, kind, name, ownerDomain, ownerName, parameters, protocol, resources, revision, rootUrl, schemas, servicePath, title, version
  say join(', ', sort keys %{$api_spec} );
  foreach my $k (qw/schemas resources auth /) { $api_spec->{$k} = 'removed to simplify';  } ## SIMPLIFY OUTPUT
  say Dumper $api_spec;

  my $meths_by_id = $gapi_agent->methods_available_for_google_api_id( $api );
  foreach my $meth ( keys %{$meths_by_id} )
  {
    say "$meth"
  }
  
   #say $gapi_agent->api_query( api_endpoint_id => 'sheets.spreadsheets.get', options=>{ spreadsheetId=> '14hc9iqhVVFMmvYi8-DZQ23GupqUZbR0SFtqiFwgkAuo' })->to_string;
   #exit;
  # say $gapi_agent->api_query( api_endpoint_id => 'gmail.users.messages.list')->to_string;
  foreach my $meth (qw/mybusiness.accounts.list  /) ##      -- FAILERS -  mybusiness.categories.list mybusiness.attributes.list
  {
    say "Testing endpoint '$meth' with no additional options";
    my $r = $gapi_agent->api_query( api_endpoint_id => $meth, options => {}, method=>'get');
    say $r->to_string;
    say '-----';
    say $r->{body};
    say '-----';
    say Dumper $r;
  }
  exit;

}
