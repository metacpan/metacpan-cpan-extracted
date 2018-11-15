#!/usr/bin/env perl

use Modern::Perl;

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use Data::Dump 'pp';
use Carp;
use Text::Table;
use MIME::Types;
use Image::PNG::Libpng;
use Mojo::JSON;

binmode(STDOUT, ":utf8"); ## to allow output of utf to terminal - see also http://perldoc.perl.org/perlrun.html#-C

require './EXAMPLE_HELPERS.pm'; ## check_api_endpoint_and_user_scopes() and display_api_summary_and_return_versioned_api_string()

my $config = {
  api => 'drive',
  debug => 01,
  do => { ## allows to filter which blocks of example code are run
      'about.get' => 0,
      'files.list' => 1,

  }
};


=head1 cloud_dns.pl

Provides an OAUTH'd client interface to L<https://developers.google.com/drive/api/v3/reference/>

    perl drive_example.pl 

NB: 

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. You may need 
to enable billing to access Google Cloud Services.

Projects require the API to be enabled for the project in the APIs console. L<https://console.cloud.google.com/apis/library/drive.googleapis.com?q=drive>

drive.googleapis.com


Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 RELEVANT SCOPES

=over 2

=item https://www.googleapis.com/auth/drive

=item and others 

=back


=head2 GOOGLE API LINKS

=over 2


=item L<https://developers.google.com/drive/api/v3/reference/>

=item L<https://developers.google.com/apis-explorer/>

=item L<https://issuetracker.google.com/issues/new?component=191650&template=823909> For logging tickets etc with Google

=back 

=cut


say 'x' x 180;






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

if ( $config->{do}{'about.get'})
{
    #############################################################################
    ## drive:v3
    ####
    ####
    ####            drive.about.get - Gets information about the user, the user's Drive, and system capabilities.
    ####
    #### NB: As at 12/11/2018 the API Discovery Spec does not describe the required fields param which expects a list of keys from the
    ####  response object described at https://developers.google.com/drive/api/v3/reference/about#resource
    #### this has been asked at https://stackoverflow.com/questions/53256997/how-to-report-errors-in-discovery-v3-specification-required-parameters-missing

    check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.about.get" );


    ####
    ####
    ####            EXECUTE API - drive.about.get
    ####
    ####
    my $r = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.about.get",  
                                    options => { 
                                        fields => '*', #'user,canCreateTeamDrives,kind,maxUploadSize,appInstalled,canCreateTeamDrives,importFormats,exportFormats'
                                    } 
                                    );
    #print Dumper  $r; # ->json;
    if ( $config->{debug} )
    {
        my $d = $r->json;
        say pp $d;
        #exit;
    }
    ############################################################################
}


if ( $config->{do}{'files.list'})
{
    ####
    ####
    ####            drive.files.list 
    ####
    ####
    check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.files.list" );
    #exit;

    ####
    ####
    ####            EXECUTE API - GET LIST OF MANAGED ZONES  
    ####            includes pagination to continue retrieving all results
    ####
    my $pagination = { ## used to record pagination state
        is_more => 1,
        nextPageToken => ''
    };
    while ( $pagination->{is_more} ==1 )
    {
        my $options = { 
                    #orderBy => 'modifiedTime desc',
                    supportsTeamDrives => 'true', #\1, # Mojo::JSON->true,
                    corpus => 'user'
                };
        ## only include pagination parameter if we have one
        $options->{pageToken} = $pagination->{nextPageToken} unless $pagination->{nextPageToken} eq '';
        my $d = $gapi_client->api_query(  api_endpoint_id => "$versioned_api.files.list",  
                                        options => $options
                                        )->json;
        if ( defined $d->{nextPageToken} )
        {
            $pagination->{nextPageToken} = $d->{nextPageToken};
        }
        else ## no more pages to reqeust - ok to finish
        {
            $pagination->{is_more} = 0;
        }
        process_file_list_results( $d );
    } ## while more files to request
} ## end drives.files.list





exit;


say "Done ";exit;


######################## HELPER SUBS - DISPLAY RESULTS ETC ##############

sub process_file_list_results
{
    my ( $rd ) = @_; ## results data structure
    foreach my $f ( @{ $rd->{files} })
    {
        say "$f->{name}\t$f->{mimeType}";
    }
    #say "Sleep 5";sleep(5);
}

=pod

=head2 OTHER INTERFACES TO GOOGLE DRIVE SERVICES



=head2 gcloud Google SDK L<https://cloud.google.com/sdk/install>

The Cloud SDK is a set of tools for Cloud Platform. 
It contains gcloud, gsutil, and bq, which you can use to access Google Compute Engine, Google Cloud Storage, 
Google BigQuery, and other products and services from the command-line. 

You can run these tools interactively or in your automated scripts.
L<https://cloud.google.com/sdk/gcloud/reference/dns/>

Currently it appears the gcloud does not provide support for the Drive API as asked L<https://groups.google.com/forum/#!topic/google-cloud-dev/OU_4S2f6GR0>


=head2 Net::Google::Drive

Provides a simlified interface to commonly used end-points.

L<https://metacpan.org/pod/Net::Google::Drive>

=cut
