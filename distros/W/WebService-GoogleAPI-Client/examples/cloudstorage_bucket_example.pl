#!/usr/bin/env perl


use Modern::Perl;

use WebService::GoogleAPI::Client;
use Data::Dumper qw (Dumper);
use Data::Dump 'pp';
use Carp;
#use File::Temp qw/ tempfile tempdir /;
#use File::Which;
#use feature 'say';
#use MIME::Base64;
use Text::Table;
use MIME::Types;
#use utf8;
use Image::PNG::Libpng;

my $config = {
  #api => 'storage:v1beta2',
  api => 'storage',
  debug => 01,
  project => $ENV{GOOGLE_PROJECT_ID},
  upload  =>  $ARGV[0] || undef,
  parameters_concise => 01,
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

}


## assumes gapi.json configuration in working directory with scoped project and user authorization
## manunally sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => $config->{debug}, gapi_json => 'gapi.json' );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );

#display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api}, 'v1beta2' );
my $versioned_api = display_api_summary_and_return_versioned_api_string( $gapi_client, $config->{api} );

#say "Versioned version of API = $versioned_api ";


## interestingly an auth'd request is denied without the correct scope .. so can't use that to find the missing scope :)
#my $methods = $gapi_client->methods_available_for_google_api_id( $versioned_api );
# say join("\n\t", "STORAGE API METHODS:\n", sort keys %$methods );
#exit;



check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.buckets.list" );


## 
my $r = $gapi_client->api_query(  api_endpoint_id => 'storage.buckets.list',  #storage.objects.list
                                 options => { 
                                     project => $config->{project}
                                  } 
                                  );
#print Dumper  $r; # ->json;
my $d = $r->json;
say pp $d;
say "First bucket has id = '$d->{items}[0]{id}'" if defined $d->{items}[0]{id};

check_api_endpoint_and_user_scopes( $gapi_client, "$versioned_api.objects.insert" );


=pod
    "message": "Upload requests must include an uploadType URL parameter and a URL path beginning with /upload/",
    "extendedHelp": "https://cloud.google.com/storage/docs/json_api/v1/how-tos/upload"
$r = $gapi_client->api_query(  api_endpoint_id => 'storage.objects.insert',  #storage.objects.list
                                 options => { 
                                     userProject => $config->{project},
                                     bucket => $d->{items}[0]{id},
                                     uploadType => 'media'
                                     #contentEncoding
#                                      q=> '',
#                                      target => 'fr',
#                                      format => 'text',
                                  } 
                                  );
print Dumper  $r; # ->json;
exit;
pp $r->json;
=cut



exit;


sub check_api_endpoint_and_user_scopes ## TODO - Doesn't actually do waht it says here yet
{
    my ( $client, $api_endpoint ) = @_;
  say '-' x 40;
  my $has_scope = $client->has_scope_to_access_api_endpoint( $api_endpoint );
    my $api_spec = $client->get_api_discovery_for_api_id( $api_endpoint  ); ## only for base url
    my $base_url = $api_spec->{baseUrl};
    # print pp $api_spec;exit;
    
    my $api_method_details = $gapi_client->extract_method_discovery_detail_from_api_spec( $api_endpoint );
    #print pp $api_method_details;exit;


    ## Construct summary textual display for the endpoint

    my $scopes_txt = join("\n", @{$api_method_details->{scopes}} );
    my $param_order_txt = join(",", @{$api_method_details->{parameterOrder}} );


    ## parameters 
    my $parameters_txt = '';
    if ( $config->{parameters_concise})
    {     ## SHORT VERSION - just the names
      $parameters_txt = join("\n", sort keys %{$api_method_details->{parameters}} );
    }
    else  ## LONG VERSION - name, description, location, type
    {
        foreach my $param ( sort keys %{$api_method_details->{parameters}}  )
        {
            $parameters_txt .= "  $param\n";
            #say Dumper $api_method_details->{parameters}{$param}; exit;
            my $text_table = Text::Table->new();
            foreach my $field (qw/description type  location required/) 
            {
                if (defined $api_method_details->{parameters}{$param}{$field} )
                {
                    $text_table->add( '     ', $field, "'$api_method_details->{parameters}{$param}{$field}'"  ) ;
                }
            }
            $parameters_txt .= $text_table . "\n";
        }
    }


    print qq{
# $api_method_details->{description} - ( $api_method_details->{id} )

METHOD: $api_method_details->{httpMethod}
PATH: $base_url$api_method_details->{path}
REQUIRED PARAMETER ORDER: $param_order_txt


## SCOPES
$scopes_txt    

## PARAMETERS
$parameters_txt
    
    };
    print "User has scope = $has_scope\n";
  say '-' x 40;
}




sub display_api_summary_and_return_versioned_api_string
{
    my ( $client, $api_name, $version  ) = @_;
    $api_name =~ s/\..*$//smg;
    if ($api_name =~ /^([^:]*):(.*)$/xsm )
    {
        $api_name = $1;
        $version = $2;
    }

    #say "api $api_name version $version";

    my $new_hash = {}; ## index by 'api:version' ( id )
    my $preferred_api_name = ''; ## this is set to the preferred version if described 
    my $text_table = Text::Table->new();

    foreach my $api ( @{ %{$client->discover_all()}{items} } )
    {
        # convert JSON::PP::Boolean to true|false strings
        if ( defined $api->{preferred} )
        {
            $api->{preferred}  = "$api->{preferred}";
            $api->{preferred}  = $api->{preferred} eq '0' ? 'no' : 'YES';
            
            if ( $preferred_api_name eq '' && $api->{preferred} eq 'YES' )
            {
                if (  $api->{id} =~ /$api_name/mx )
                {
                    $preferred_api_name = $api->{id} ;
                    $new_hash->{ $api_name } = $api;
                }
            }


        }
        #$new_hash->{ $api->{name} } = $api unless defined $new_hash->{ $api->{name} };
        $new_hash->{ $api->{id} } = $api;
        if (  $api->{name} =~ /$api_name/xm  )
        {
            foreach my $field (qw/title version preferred id  description discoveryRestUrl documentationLink name/)
            {
                #say qq{$field = $api->{$field}};
                $text_table->add( $field, $api->{$field}  );
            }
            $text_table->add(' ',' ');
        }
    }

    
    say "## Google $new_hash->{$api_name}{title} ( $api_name ) SUMMARY\n\n";
    say $text_table;
    
    if ( defined $version)
    {
        $api_name = "$api_name:$version";
    }
    else 
    {
        $api_name = $preferred_api_name;
    }
    say pp $new_hash->{$api_name}  if $config->{debug}; 
    
    return $api_name;
}





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

gsutil is a Python application that lets you access Cloud Storage from the command line. You can use gsutil to do a wide range of bucket and object management tasks, including:

=over 4

=item * Creating and deleting buckets.

=item * Uploading, downloading, and deleting objects.

=item * Listing buckets and objects.

=item * Moving, copying, and renaming objects.

=item * Editing object and bucket ACLs.

=back

    Peters-MacBook-Pro-2:examples peter$ gsutil ls
    gs://computerproscomau-vcm/
    gs://perl-webservice/


=cut
