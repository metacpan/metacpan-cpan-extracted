#!/usr/bin/env perl

use Modern::Perl;

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use Data::Dump 'pp';
use Carp;
use Text::Table;
use MIME::Types;
#use utf8;

require './EXAMPLE_HELPERS.pm'; ## check_api_endpoint_and_user_scopes() and display_api_summary_and_return_versioned_api_string()

my $config = {
  api => 'people',
  debug => 0,
};


=head1 contacts_v3_api.pl

Provides an OAUTH'd client interface to L<https://developers.google.com/people/>

    perl people_api.pl 

Provides a list of contacts - and use nextPageToken to continue to get all


=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. You may need 
to enable billing to access Google Cloud Services.
Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 RELEVANT SCOPES

The people.connections.list endpoint requires one of the following scopes:
=over 2

=item L<https://www.googleapis.com/auth/contacts>	Requests that your app be given read and write access to the contacts in the authenticated user’s Google Contacts.

=item L<https://www.googleapis.com/auth/contacts.readonly>	Requests that your app be given read access to the contacts in the authenticated user’s Google Contacts.

=back

More details at L<https://developers.google.com/people/v1/how-tos/authorizing>


=head2 GOOGLE API LINKS

=over 2

=item L<https://console.developers.google.com/apis/>

=item L<https://www.google.com/contacts/u/0/#contacts>

=item L<https://developers.google.com/apis-explorer/>

=back 

=cut


say 'x' x 180;
croak('must have environment variable GOOGLE_PROJECT_ID set to run') unless defined $ENV{GOOGLE_PROJECT_ID};


####
####
####            SET UP THE CLIENT AS THE DEFAULT USER 
####
####
## assumes gapi.json configuration in working directory with scoped project and user authorization
## manually sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => $config->{debug}, gapi_json => 'gapi.json' );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );




####
####
####            DISPLAY AN OVERVIEW OF THE API VERSIONS 
####            AND SELECT THE PREFERRED VERSION IF NOT SPECIFIED
####

#display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api}, 'v1beta2' );
my $versioned_api = display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api} );

say "Versioned version of API = $versioned_api ";

my $methods = $gapi_client->methods_available_for_google_api_id( $versioned_api );
 say join("\n\t", "STORAGE API METHODS:\n", sort keys %$methods );

####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- people.connections.list
####            See https://developers.google.com/people/api/rest/v1/people.connections/list
####
check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.people.connections.list" );
#exit;

####
####
####            EXECUTE API - GET LIST OF CONTACTS  
####
####
my $ret = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.people.connections.list",  
#my $ret = $gapi_client->api_query(  api_endpoint_id => "people.people.connections.list",  
                                 options => { 
                                     personFields => 'names,phoneNumbers,emailAddresses,urls',
                                     'resourceName' => 'people/me',
                                     sortOrder    => 'LAST_MODIFIED_ASCENDING',
                                     pageSize     => 5,
                                    } 
                                  );

#print Dumper $ret;
if ( $ret->{code} eq '200')
{
  extract_and_display_people_detail_from_response( $ret->json );
}
else 
{
    say qq{REQUEST NOT OK - $ret->{status} };
}

exit;

############# HELPER SUBS ################


sub extract_and_display_people_detail_from_response
{
  my ( $r ) = @_; ## should be a Mojo::Message::Response->json structure

  foreach my $c ( @{ $r->{"connections"}} )
  {
      $c->{"emailAddresses"}[0]{value} = '' unless defined $c->{"emailAddresses"}[0]{value};
      $c->{names}[0]{"displayName"} = '' unless defined $c->{names}[0]{"displayName"};
      $c->{"resourceName"} = '' unless defined $c->{"resourceName"};
      print qq{
          RESOURCE: $c->{"resourceName"}
          DISPLAY NAME: $c->{names}[0]{"displayName"}
          EMAIL: $c->{"emailAddresses"}[0]{value}

      };
  }
  $r->{nextPageToken} = '' unless $r->{nextPageToken};
  print qq{
  nextPageToken = $r->{nextPageToken}
  totalPeople   =  $r->{totalPeople}
  totalItems    = $r->{"totalItems"}
  };

  return $r->{nextPageToken}; ## could use this to continue getting all contacts

}
