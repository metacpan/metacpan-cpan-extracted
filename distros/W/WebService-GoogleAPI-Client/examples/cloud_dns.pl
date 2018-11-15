#!/usr/bin/env perl

use Modern::Perl;

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use Data::Dump 'pp';
use Carp;
use Text::Table;
use MIME::Types;
use Image::PNG::Libpng;

require './EXAMPLE_HELPERS.pm'; ## check_api_endpoint_and_user_scopes() and display_api_summary_and_return_versioned_api_string()

my $config = {
  api => 'dns',
  debug => 01,
  project => $ENV{GOOGLE_PROJECT_ID},
  managedZone => $ENV{GOOGLE_DNS_MANAGED_ZONE}, 
};


=head1 cloud_dns.pl

Provides an OAUTH'd client interface to L<https://cloud.google.com/storage/docs/json_api/v1/>

    perl cloud_dns.pl <your-managed-domain>

NB: 

=over 2

=item must have export GOOGLE_PROJECT_ID= set with project ID

=back

=for html


???????
???????
<a href="https://code.google.com/apis/language/translate/v2/getting_started.html"><img src="https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"></a>

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Cloud API Library. 

The project resource is a top level container for resources including Cloud DNS ManagedZones. 
Projects can be created only in the APIs console. L<https://console.cloud.google.com/apis>

dns.googleapis.com


Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 RELEVANT SCOPES

=over 2

=item https://www.googleapis.com/auth/ndev.clouddns.readonly

=item https://www.googleapis.com/auth/ndev.clouddns.readwrite

=item https://www.googleapis.com/auth/cloud-platform

=item https://www.googleapis.com/auth/cloud-platform.read-only


=back


=head2 GOOGLE API LINKS

=over 2

=item L<https://cloud.google.com/dns/>

=item L<https://cloud.google.com/dns/docs/reference/v1/>

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
## manunally sets the client user email to be the first in the gapi.json file
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
#exit;
## interestingly an auth'd request is denied without the correct scope .. so can't use that to find the missing scope :)
my $methods = $gapi_client->methods_available_for_google_api_id( $versioned_api );
 say join("\n\t", "DNS API END POINTS:\n", sort keys %$methods );
#exit;


#############################################################################
## dns:v1.projects.get
####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- dns.managedZones.list
####
####
check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.projects.get" );
#exit;

####
####
####            EXECUTE API - LIST DNS PROJECTS  
####
####
my $r = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.projects.get",  
                                 options => { 
                                     project => $config->{project}
                                  } 
                                  );
#print Dumper  $r; # ->json;
if ( $config->{debug} )
{
    my $d = $r->json;
    say pp $d;
    #exit;
}


#############################################################################



####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- dns.managedZones.list
####
####
check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.managedZones.list" );
#exit;

####
####
####            EXECUTE API - GET LIST OF MANAGED ZONES  
####
####
my $r = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.managedZones.list",  
                                 options => { 
                                     project => $config->{project}
                                  } 
                                  );
#print Dumper  $r; # ->json;
if ( $config->{debug} )
{
    my $d = $r->json;
    say pp $d;
    #exit;
}

#############################################################################
#  dns.resourceRecordSets.list
####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- resourceRecordSets.list
####
####
check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.resourceRecordSets.list" );
#exit;

####
####
####            EXECUTE API - LIST DNS ZONE RECORD  
####
####
my $r = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.resourceRecordSets.list",  
                                 options => { 
                                     project => $config->{project},
                                     managedZone => $config->{managedZone}
                                  } 
                                  );
#print Dumper  $r; # ->json;
if ( $config->{debug} )
{
    my $d = $r->json;
    say pp $d;
    exit;
}




say "Done ";



=pod

=head2 OTHER INTERFACES TO GOOGLE DNS SERVICES



=head2 gcloud Google SDK L<https://cloud.google.com/sdk/install>

The Cloud SDK is a set of tools for Cloud Platform. 
It contains gcloud, gsutil, and bq, which you can use to access Google Compute Engine, Google Cloud Storage, 
Google BigQuery, and other products and services from the command-line. 

You can run these tools interactively or in your automated scripts.
L<https://cloud.google.com/sdk/gcloud/reference/dns/>

    gcloud dns managed-zones --help
    
    gcloud dns managed-zones create wwww-zone --description="wwww.com.au Zone" \
            --dns-name="wwww.com.au."


=cut
