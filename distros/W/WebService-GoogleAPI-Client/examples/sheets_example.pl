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
## SEE ALSO - https://github.com/APIs-guru/openapi-directory/blob/master/APIs/googleapis.com/gmail/v1/swagger.yaml 



=head2 SHEETS API ENDPOINTS

sheets.spreadsheets.values.clear
sheets.spreadsheets.developerMetadata.get
sheets.spreadsheets.values.batchGet
sheets.spreadsheets.getByDataFilter
sheets.spreadsheets.values.get
sheets.spreadsheets.values.batchClear
sheets.spreadsheets.get
sheets.spreadsheets.create
sheets.spreadsheets.values.batchGetByDataFilter
sheets.spreadsheets.values.batchUpdateByDataFilter
sheets.spreadsheets.values.batchClearByDataFilter
sheets.spreadsheets.developerMetadata.search
sheets.spreadsheets.batchUpdate
sheets.spreadsheets.sheets.copyTo
sheets.spreadsheets.values.batchUpdate
sheets.spreadsheets.values.update
sheets.spreadsheets.values.append

=head2 GOALS

  - show summary details pulled from discovery docs 
  - show all methods in HTML table with description including code snippets for worked examples
  - describe helper functions the simplify data handling
  - inform improvements to core Modules ( param parsing / validation / feature evolution etc )
  - idenitfy opportunities for use in full working applications 

=head2 LIST ALL SHEETS

V3 - OLDER
    As described at https://developers.google.com/sheets/api/v3/worksheets#retrieve_a_list_of_spreadsheets
    https://spreadsheets.google.com/feeds/spreadsheets/private/full

V4 - CURRENT
    - need to use Google Drive as per https://stackoverflow.com/a/37881096/2779629
    - and in docs - https://developers.google.com/sheets/api/guides/migration#list_spreadsheets_for_the_authenticated_user
    


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

my $api = 'sheets';

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
  
   say $gapi_agent->api_query( api_endpoint_id => 'sheets.spreadsheets.get', options=>{ spreadsheetId=> '14hc9iqhVVFMmvYi8-DZQ23GupqUZbR0SFtqiFwgkAuo' })->to_string;
   #exit;
  # say $gapi_agent->api_query( api_endpoint_id => 'gmail.users.messages.list')->to_string;
  foreach my $meth (qw/sheets.spreadsheets.get /) ##      -- FAILERS - 
  {
    say "Testing endpoint '$meth' with no additional options";
    my $r = $gapi_agent->api_query( api_endpoint_id => $meth, options => {});
    say $r->to_string;
    say '-----';
    say $r->{body};
    say '-----';
    say Dumper $r;
  }
  exit;

}
