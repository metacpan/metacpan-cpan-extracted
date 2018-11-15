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
  #api => 'storage:v1beta2',
  api => 'storage',
  debug => 01,
  project => $ENV{GOOGLE_PROJECT_ID},
  selected_bucket => undef, ## filled with first available bucket of user for project
  upload  =>  $ARGV[0] || undef,
  file_content => undef, ## will be filled with content of file at path 'upload'
  
};


=head1 cloudstorage_bucket_example.pl

Provides an OAUTH'd client interface to L<https://cloud.google.com/storage/docs/json_api/v1/>

    perl cloudstorage_bucket_example.pl sample.png

NB: 

=over 2

=item file must exist and will be uploaded to the first bucket in the project list 

=item must have export GOOGLE_PROJECT_ID= set with project ID

=back

=for html
<a href="https://code.google.com/apis/language/translate/v2/getting_started.html"><img src="https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"></a>

=head2 PRE-REQUISITES


Setup a Google Project in the Google Console and add the Translate API Library. You may need 
to enable billing to access Google Cloud Services.
Setup an OAUTH Credential set and feed this into the CLI goauth 
included in WebService::GoogleAPI::Client and use the tool to authorise
your user to access the project which will also create the local gapi.json config.

assumes gapi.json configuration in working directory with scoped project and user authorization
  


=head2 RELEVANT SCOPES

=over 2

=item  L<https://www.googleapis.com/auth/devstorage.full_control> - Read/write and ACL management access to Google Cloud Storage.

=item L<https://www.googleapis.com/auth/devstorage.read_write> - Read/write access to Google Cloud Storage.

=item L<https://www.googleapis.com/auth/devstorage.read_only> - Read-only access to Google Cloud Storage.

=back


=head2 GOOGLE API LINKS

=over 2

=item L<https://console.developers.google.com/apis/>

=item L<https://cloud.google.com/storage/docs/json_api/v1/>

=item L<https://developers.google.com/apis-explorer/>

=back 

=cut


say 'x' x 180;
croak('must have environment variable GOOGLE_PROJECT_ID set to run') unless defined $ENV{GOOGLE_PROJECT_ID};

if ( $config->{upload} )
{
    #my $mt    = MIME::Types->new();
    croak("not going to try to upload file $config->{upload} as it doesn't seem to be available in the path") unless -e $config->{upload};
    $config->{MIMETYPE} = MIME::Types->new()->mimeTypeOf( $config->{upload});
    ## maybe consider use File::Slurp; qw/read_file/ .. so my $config->{file_content} = read_file( $config->{upload} , binmode => ':raw' , scalar_ref => 1 );
    open F, $config->{upload};
    $config->{file_content} = do { local $/; <F> };
    close F;

}




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

#say "Versioned version of API = $versioned_api ";

## interestingly an auth'd request is denied without the correct scope .. so can't use that to find the missing scope :)
#my $methods = $gapi_client->methods_available_for_google_api_id( $versioned_api );
# say join("\n\t", "STORAGE API METHODS:\n", sort keys %$methods );
#exit;

####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- storage.buckets.list
####
####
check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.buckets.list" );


####
####
####            EXECUTE API - GET LIST OF BUCKETS  
####
####
my $r = $gapi_client->api_query(  api_endpoint_id => 'storage.buckets.list',  #storage.objects.list
                                 options => { 
                                     project => $config->{project}
                                  } 
                                  );
#print Dumper  $r; # ->json;
my $d = $r->json;
say pp $d;
say "First bucket has id = '$d->{items}[0]{id}'" if defined $d->{items}[0]{id};
$config->{selected_bucket} = $d->{items}[0]{id};

####
####
####            DISPLAY A SUMMARY OF THE API-ENDPOINT  -- storage.objects.insert
####
####

check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.objects.insert" );

####
####
####            EXECUTE API - INSERT A FILE INTO A BUCKET .. NB - not working using API Spec
####
####
=pod
    "message": "Upload requests must include an uploadType URL parameter and a URL path beginning with /upload/",
    "extendedHelp": "https://cloud.google.com/storage/docs/json_api/v1/how-tos/upload"
$r = $gapi_client->api_query(  api_endpoint_id => 'storage.objects.insert',  #storage.objects.list
                                 options => { 
                                     userProject => $config->{project},
                                     bucket => $d->{items}[0]{id},
                                     uploadType => 'media'
                                     #contentEncoding
                                  } 
                                  );
print Dumper  $r; # ->json;
exit;
pp $r->json;
=cut


=pod

As per L<https://cloud.google.com/storage/docs/uploading-objects> 
"https://www.googleapis.com/upload/storage/v1/b/[BUCKET_NAME]/o?uploadType=media&name=[OBJECT_NAME]

$config->{MIMETYPE}
$config->{file_content}
$config->{selected_bucket}

NB _ to make publicly accessible  you need to add 
{
"entity": "allUsers",
"role": "READER"
}
to the file or bucket through the browser - will include example on API in future.

as per L<https://cloud.google.com/storage/docs/access-control/making-data-public>

=cut
## split out the filename - a bit rough
if ( $config->{upload} =~ /([^\/]*)$/xsmg )
{
     $config->{upload} = $1;
}

say "File content length = " . length( $config->{file_content});
say "MIME TYPE of $config->{upload} is '$config->{MIMETYPE}'";
#exit;
$r = $gapi_client->api_query( { 
                                path => "https://www.googleapis.com/upload/storage/v1/b/$config->{selected_bucket}/o?uploadType=media&name=$config->{upload}",  
                                method => 'POST',
                                 options => $config->{file_content}
                                  });
#print Dumper  $r; # ->json;

pp $r->json;
exit;


exit;







=pod

=head2 OTHER INTERFACES TO THE GOOGLE CLOUD BUCKET STORAGE 

=head2 Google Cloud Storage Browser L<https://console.cloud.google.com/storage/browser>

Includes a bucket file browser 

=head3 Transfer 

Transfer data to your Cloud Storage buckets from Amazon Simple Storage Service (S3), HTTP/HTTPS servers, or other buckets. 
You can schedule one-time or daily transfers, and you can filter files based on name prefix and when they were changed.

=head3 Transfer Appliance

Transfer Appliance lets you quickly and securely transfer large amounts of data to Google Cloud Platform via a high capacity storage server 
 you lease from Google and ship to our datacenter. Transfer Appliance is recommended for data that exceeds 20 TB or would take more 
 than a week to upload.



=head2 gcloud Google SDK L<https://cloud.google.com/sdk/install>

The Cloud SDK is a set of tools for Cloud Platform. 
It contains gcloud, gsutil, and bq, which you can use to access Google Compute Engine, Google Cloud Storage, 
Google BigQuery, and other products and services from the command-line. 

You can run these tools interactively or in your automated scripts.

    gcloud compute backend-buckets list
    Listed 0 items.



=head2 gsutil L<https://cloud.google.com/storage/docs/gsutil>

I believe gsutil is installed as part of the gcloud Google SDK.

gsutil is a Python application that lets you access Cloud Storage from the command line. You can use gsutil to do a wide range of bucket and object management tasks, including:

=over 4

=item * Creating and deleting buckets.

=item * Uploading, downloading, and deleting objects.

=item * Listing buckets and objects.

=item * Moving, copying, and renaming objects.

=item * Editing object and bucket ACLs.

=back

    bash$ gsutil ls
    gs://computerproscomau-vcm/
    gs://perl-webservice/


=cut
