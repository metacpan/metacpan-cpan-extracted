#!/usr/bin/env perl

use WebService::GoogleAPI::Client;
use WebService::GoogleAPI::Client::UserAgent;
use Data::Dumper qw (Dumper);
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Which;
use feature 'say';
use MIME::Base64;
use Mojo::UserAgent;
use Mojo::Message::Response;


use Sub::Override;

=pod
use FindBin qw($Bin);
say `ls -l $Bin/gapi.json`;
print "\n\n";
say $Bin;exit;
=cut


=head1 mojo_ua_mocking_test.pl

=head2 USAGE

=cut






say "starting ";

=pod
my $ua  = Mojo::UserAgent->new;
#my $tx = $ua->build_tx(GET => 'http://example.com');
#print Dumper $tx;
#exit;
my $res = $ua->get('http://0.0.0.0:8000');#->result;
#exit;
if    ($res->is_success)  { say 'success - body = ' . $res->body }
elsif ($res->is_error)    { say $res->message }
elsif ($res->code == 301) { say $res->headers->location }
else                      { say 'Whatever...' }

say 'finished';
=cut


###############################################################################################
###############################################################################################
###############################################################################################

#exit;

my $ds = {};
my $chi = CHI->new(driver => 'RawMemory', 'datastore' => $ds );
## assumes gapi.json configuration in working directory with scoped project and user authorization
## manunally sets the client user email to be the first in the gapi.json file
my $gapi_client = WebService::GoogleAPI::Client->new( debug => 0, gapi_json => 'gapi.json', chi => $chi  );
my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                                             ## default to the first user
$gapi_client->user( $user );

if ( 1==1 )
{
    my $pre_get_all_apis_json = pre_get_all_apis_json();
    my $override = Sub::Override->new('Mojo::Transaction::res', sub {
        my $res =  Mojo::Message::Response->new ;
        $res->code( 200 );
        $res->body(  pre_get_all_apis_json() );
        #$res2->headers->location('fnar');
        print "MY FIRST OVERLOADED SUB\n";
        return $res;
        });
    
    my $all = $gapi_client->discover_all();
say "-------\n\n\n\n\n";
    my $pre_get_gmail_spec_json = pre_get_gmail_spec_json();
    my $override2 = Sub::Override->new('Mojo::Transaction::res', 
                                sub {
                                        my $res2 =  Mojo::Message::Response->new ;
                                        $res2->code( 200 );
                                        $res2->body( pre_get_gmail_spec_json() );
                                        return $res2;
                                    });
    
    #my $gapi_client = WebService::GoogleAPI::Client->new( debug => 01, gapi_json => 'gapi.json', chi => $chi  );
    my $gmail_api_spec = $gapi_client->methods_available_for_google_api_id('gmail', 'v1');
    print Dumper $gmail_api_spec ;

    my $gmail_api = $gapi_client->methods_available_for_google_api_id( 'gmail' );
    say join(',', keys %$gmail_api);

    {
        my $override3 = Sub::Override->new('Mojo::Transaction::res', sub {
            my $res2 =  Mojo::Message::Response->new ;
            $res2->code( 200 );
            $res2->body( "TESTED FINE" );
            #$res2->headers->location('fnar');
    print "MY SECOND OVERLOADED SUB\n";
            return $res2;
            });

    my $cl = $gapi_client->api_query( api_endpoint_id => 'gmail.users.messages.list'  );
    print Dumper $cl;

    }

}





sub pre_get_all_apis_json
{
  return <<'_END'
    {
    "kind": "discovery#directoryList",
    "discoveryVersion": "v1",
    "items": [
    {
    "kind": "discovery#directoryItem",
    "id": "abusiveexperiencereport:v1",
    "name": "abusiveexperiencereport",
    "version": "v1",
    "title": "Abusive Experience Report API",
    "description": "Views Abusive Experience Report data, and gets a list of sites that have a significant number of abusive experiences.",
    "discoveryRestUrl": "https://abusiveexperiencereport.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/abusive-experience-report/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "acceleratedmobilepageurl:v1",
    "name": "acceleratedmobilepageurl",
    "version": "v1",
    "title": "Accelerated Mobile Pages (AMP) URL API",
    "description": "This API contains a single method, batchGet. Call this method to retrieve the AMP URL (and equivalent AMP Cache URL) for given public URL(s).",
    "discoveryRestUrl": "https://acceleratedmobilepageurl.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/amp/cache/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "accesscontextmanager:v1beta",
    "name": "accesscontextmanager",
    "version": "v1beta",
    "title": "Access Context Manager API",
    "description": "An API for setting attribute based access control to requests to GCP services.",
    "discoveryRestUrl": "https://accesscontextmanager.googleapis.com/$discovery/rest?version=v1beta",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/access-context-manager/docs/reference/rest/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adexchangebuyer:v1.2",
    "name": "adexchangebuyer",
    "version": "v1.2",
    "title": "Ad Exchange Buyer API",
    "description": "Accesses your bidding-account information, submits creatives for validation, finds available direct deals, and retrieves performance reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/adexchangebuyer/v1.2/rest",
    "discoveryLink": "./apis/adexchangebuyer/v1.2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/ad-exchange/buyer-rest",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adexchangebuyer:v1.3",
    "name": "adexchangebuyer",
    "version": "v1.3",
    "title": "Ad Exchange Buyer API",
    "description": "Accesses your bidding-account information, submits creatives for validation, finds available direct deals, and retrieves performance reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/adexchangebuyer/v1.3/rest",
    "discoveryLink": "./apis/adexchangebuyer/v1.3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/ad-exchange/buyer-rest",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adexchangebuyer:v1.4",
    "name": "adexchangebuyer",
    "version": "v1.4",
    "title": "Ad Exchange Buyer API",
    "description": "Accesses your bidding-account information, submits creatives for validation, finds available direct deals, and retrieves performance reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/adexchangebuyer/v1.4/rest",
    "discoveryLink": "./apis/adexchangebuyer/v1.4/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/ad-exchange/buyer-rest",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adexchangebuyer2:v2beta1",
    "name": "adexchangebuyer2",
    "version": "v2beta1",
    "title": "Ad Exchange Buyer API II",
    "description": "Accesses the latest features for managing Ad Exchange accounts, Real-Time Bidding configurations and auction metrics, and Marketplace programmatic deals.",
    "discoveryRestUrl": "https://adexchangebuyer.googleapis.com/$discovery/rest?version=v2beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/ad-exchange/buyer-rest/reference/rest/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adexperiencereport:v1",
    "name": "adexperiencereport",
    "version": "v1",
    "title": "Ad Experience Report API",
    "description": "Views Ad Experience Report data, and gets a list of sites that have a significant number of annoying ads.",
    "discoveryRestUrl": "https://adexperiencereport.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/ad-experience-report/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "admin:datatransfer_v1",
    "name": "admin",
    "version": "datatransfer_v1",
    "title": "Admin Data Transfer API",
    "description": "Transfers user data from one user to another.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/admin/datatransfer_v1/rest",
    "discoveryLink": "./apis/admin/datatransfer_v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/admin-sdk/data-transfer/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "admin:directory_v1",
    "name": "admin",
    "version": "directory_v1",
    "title": "Admin Directory API",
    "description": "Manages enterprise resources such as users and groups, administrative notifications, security features, and more.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/admin/directory_v1/rest",
    "discoveryLink": "./apis/admin/directory_v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/admin-sdk/directory/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "admin:reports_v1",
    "name": "admin",
    "version": "reports_v1",
    "title": "Admin Reports API",
    "description": "Fetches reports for the administrators of G Suite customers about the usage, collaboration, security, and risk for their users.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/admin/reports_v1/rest",
    "discoveryLink": "./apis/admin/reports_v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/admin-sdk/reports/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adsense:v1.4",
    "name": "adsense",
    "version": "v1.4",
    "title": "AdSense Management API",
    "description": "Accesses AdSense publishers' inventory and generates performance reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/adsense/v1.4/rest",
    "discoveryLink": "./apis/adsense/v1.4/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/adsense-16.png",
        "x32": "https://www.google.com/images/icons/product/adsense-32.png"
    },
    "documentationLink": "https://developers.google.com/adsense/management/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "adsensehost:v4.1",
    "name": "adsensehost",
    "version": "v4.1",
    "title": "AdSense Host API",
    "description": "Generates performance reports, generates ad codes, and provides publisher management capabilities for AdSense Hosts.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/adsensehost/v4.1/rest",
    "discoveryLink": "./apis/adsensehost/v4.1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/adsense-16.png",
        "x32": "https://www.google.com/images/icons/product/adsense-32.png"
    },
    "documentationLink": "https://developers.google.com/adsense/host/",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "alertcenter:v1beta1",
    "name": "alertcenter",
    "version": "v1beta1",
    "title": "G Suite Alert Center API",
    "description": "G Suite Alert Center API to view and manage alerts on issues affecting your domain.",
    "discoveryRestUrl": "https://alertcenter.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/admin-sdk/alertcenter/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "analytics:v2.4",
    "name": "analytics",
    "version": "v2.4",
    "title": "Google Analytics API",
    "description": "Views and manages your Google Analytics data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/analytics/v2.4/rest",
    "discoveryLink": "./apis/analytics/v2.4/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/analytics-16.png",
        "x32": "https://www.google.com/images/icons/product/analytics-32.png"
    },
    "documentationLink": "https://developers.google.com/analytics/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "analytics:v3",
    "name": "analytics",
    "version": "v3",
    "title": "Google Analytics API",
    "description": "Views and manages your Google Analytics data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/analytics/v3/rest",
    "discoveryLink": "./apis/analytics/v3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/analytics-16.png",
        "x32": "https://www.google.com/images/icons/product/analytics-32.png"
    },
    "documentationLink": "https://developers.google.com/analytics/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "analyticsreporting:v4",
    "name": "analyticsreporting",
    "version": "v4",
    "title": "Google Analytics Reporting API",
    "description": "Accesses Analytics report data.",
    "discoveryRestUrl": "https://analyticsreporting.googleapis.com/$discovery/rest?version=v4",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/analytics/devguides/reporting/core/v4/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androiddeviceprovisioning:v1",
    "name": "androiddeviceprovisioning",
    "version": "v1",
    "title": "Android Device Provisioning Partner API",
    "description": "Automates Android zero-touch enrollment for device resellers, customers, and EMMs.",
    "discoveryRestUrl": "https://androiddeviceprovisioning.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/zero-touch/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidenterprise:v1",
    "name": "androidenterprise",
    "version": "v1",
    "title": "Google Play EMM API",
    "description": "Manages the deployment of apps to Android for Work users.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/androidenterprise/v1/rest",
    "discoveryLink": "./apis/androidenterprise/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/android-16.png",
        "x32": "https://www.google.com/images/icons/product/android-32.png"
    },
    "documentationLink": "https://developers.google.com/android/work/play/emm-api",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidmanagement:v1",
    "name": "androidmanagement",
    "version": "v1",
    "title": "Android Management API",
    "description": "The Android Management API provides remote enterprise management of Android devices and apps.",
    "discoveryRestUrl": "https://androidmanagement.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/android/management",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidpublisher:v1",
    "name": "androidpublisher",
    "version": "v1",
    "title": "Google Play Developer API",
    "description": "Accesses Android application developers' Google Play accounts.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/androidpublisher/v1/rest",
    "discoveryLink": "./apis/androidpublisher/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/android-16.png",
        "x32": "https://www.google.com/images/icons/product/android-32.png"
    },
    "documentationLink": "https://developers.google.com/android-publisher",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidpublisher:v1.1",
    "name": "androidpublisher",
    "version": "v1.1",
    "title": "Google Play Developer API",
    "description": "Accesses Android application developers' Google Play accounts.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/androidpublisher/v1.1/rest",
    "discoveryLink": "./apis/androidpublisher/v1.1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/android-16.png",
        "x32": "https://www.google.com/images/icons/product/android-32.png"
    },
    "documentationLink": "https://developers.google.com/android-publisher",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidpublisher:v2",
    "name": "androidpublisher",
    "version": "v2",
    "title": "Google Play Developer API",
    "description": "Accesses Android application developers' Google Play accounts.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/androidpublisher/v2/rest",
    "discoveryLink": "./apis/androidpublisher/v2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/android-16.png",
        "x32": "https://www.google.com/images/icons/product/android-32.png"
    },
    "documentationLink": "https://developers.google.com/android-publisher",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "androidpublisher:v3",
    "name": "androidpublisher",
    "version": "v3",
    "title": "Google Play Developer API",
    "description": "Accesses Android application developers' Google Play accounts.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/androidpublisher/v3/rest",
    "discoveryLink": "./apis/androidpublisher/v3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/android-16.png",
        "x32": "https://www.google.com/images/icons/product/android-32.png"
    },
    "documentationLink": "https://developers.google.com/android-publisher",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appengine:v1alpha",
    "name": "appengine",
    "version": "v1alpha",
    "title": "App Engine Admin API",
    "description": "Provisions and manages developers' App Engine applications.",
    "discoveryRestUrl": "https://appengine.googleapis.com/$discovery/rest?version=v1alpha",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/appengine/docs/admin-api/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appengine:v1beta",
    "name": "appengine",
    "version": "v1beta",
    "title": "App Engine Admin API",
    "description": "Provisions and manages developers' App Engine applications.",
    "discoveryRestUrl": "https://appengine.googleapis.com/$discovery/rest?version=v1beta",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/appengine/docs/admin-api/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appengine:v1",
    "name": "appengine",
    "version": "v1",
    "title": "App Engine Admin API",
    "description": "Provisions and manages developers' App Engine applications.",
    "discoveryRestUrl": "https://appengine.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/appengine/docs/admin-api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appengine:v1beta4",
    "name": "appengine",
    "version": "v1beta4",
    "title": "App Engine Admin API",
    "description": "Provisions and manages developers' App Engine applications.",
    "discoveryRestUrl": "https://appengine.googleapis.com/$discovery/rest?version=v1beta4",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/appengine/docs/admin-api/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appengine:v1beta5",
    "name": "appengine",
    "version": "v1beta5",
    "title": "App Engine Admin API",
    "description": "Provisions and manages developers' App Engine applications.",
    "discoveryRestUrl": "https://appengine.googleapis.com/$discovery/rest?version=v1beta5",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/appengine/docs/admin-api/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appsactivity:v1",
    "name": "appsactivity",
    "version": "v1",
    "title": "Drive Activity API",
    "description": "Provides a historical view of activity.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/appsactivity/v1/rest",
    "discoveryLink": "./apis/appsactivity/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/activity/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "appstate:v1",
    "name": "appstate",
    "version": "v1",
    "title": "Google App State API",
    "description": "The Google App State API.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/appstate/v1/rest",
    "discoveryLink": "./apis/appstate/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/games/services/web/api/states",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "bigquery:v2",
    "name": "bigquery",
    "version": "v2",
    "title": "BigQuery API",
    "description": "A data platform for customers to create, manage, share and query data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/bigquery/v2/rest",
    "discoveryLink": "./apis/bigquery/v2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/search-16.gif",
        "x32": "https://www.google.com/images/icons/product/search-32.gif"
    },
    "documentationLink": "https://cloud.google.com/bigquery/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "bigquerydatatransfer:v1",
    "name": "bigquerydatatransfer",
    "version": "v1",
    "title": "BigQuery Data Transfer API",
    "description": "Transfers data from partner SaaS applications to Google BigQuery on a scheduled, managed basis.",
    "discoveryRestUrl": "https://bigquerydatatransfer.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/bigquery/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "binaryauthorization:v1beta1",
    "name": "binaryauthorization",
    "version": "v1beta1",
    "title": "Binary Authorization API",
    "description": "The management interface for Binary Authorization, a system providing policy control for images deployed to Kubernetes Engine clusters.",
    "discoveryRestUrl": "https://binaryauthorization.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/binary-authorization/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "blogger:v2",
    "name": "blogger",
    "version": "v2",
    "title": "Blogger API",
    "description": "API for access to the data within Blogger.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/blogger/v2/rest",
    "discoveryLink": "./apis/blogger/v2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/blogger-16.png",
        "x32": "https://www.google.com/images/icons/product/blogger-32.png"
    },
    "documentationLink": "https://developers.google.com/blogger/docs/2.0/json/getting_started",
    "labels": [
        "limited_availability"
    ],
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "blogger:v3",
    "name": "blogger",
    "version": "v3",
    "title": "Blogger API",
    "description": "API for access to the data within Blogger.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/blogger/v3/rest",
    "discoveryLink": "./apis/blogger/v3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/blogger-16.png",
        "x32": "https://www.google.com/images/icons/product/blogger-32.png"
    },
    "documentationLink": "https://developers.google.com/blogger/docs/3.0/getting_started",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "books:v1",
    "name": "books",
    "version": "v1",
    "title": "Books API",
    "description": "Searches for books and manages your Google Books library.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/books/v1/rest",
    "discoveryLink": "./apis/books/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/ebooks-16.png",
        "x32": "https://www.google.com/images/icons/product/ebooks-32.png"
    },
    "documentationLink": "https://developers.google.com/books/docs/v1/getting_started",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "calendar:v3",
    "name": "calendar",
    "version": "v3",
    "title": "Calendar API",
    "description": "Manipulates events and other calendar data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/calendar/v3/rest",
    "discoveryLink": "./apis/calendar/v3/rest",
    "icons": {
        "x16": "http://www.google.com/images/icons/product/calendar-16.png",
        "x32": "http://www.google.com/images/icons/product/calendar-32.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/calendar/firstapp",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "chat:v1",
    "name": "chat",
    "version": "v1",
    "title": "Hangouts Chat API",
    "description": "Create bots and extend the new Hangouts Chat.",
    "discoveryRestUrl": "https://chat.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/hangouts/chat",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "civicinfo:v2",
    "name": "civicinfo",
    "version": "v2",
    "title": "Google Civic Information API",
    "description": "Provides polling places, early vote locations, contest data, election officials, and government representatives for U.S. residential addresses.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/civicinfo/v2/rest",
    "discoveryLink": "./apis/civicinfo/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/civic-information",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "classroom:v1",
    "name": "classroom",
    "version": "v1",
    "title": "Google Classroom API",
    "description": "Manages classes, rosters, and invitations in Google Classroom.",
    "discoveryRestUrl": "https://classroom.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/classroom",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudasset:v1beta1",
    "name": "cloudasset",
    "version": "v1beta1",
    "title": "Cloud Asset API",
    "description": "The cloud asset API manages the history and inventory of cloud resources.",
    "discoveryRestUrl": "https://cloudasset.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://console.cloud.google.com/apis/api/cloudasset.googleapis.com/overview",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudbilling:v1",
    "name": "cloudbilling",
    "version": "v1",
    "title": "Cloud Billing API",
    "description": "Allows developers to manage billing for their Google Cloud Platform projects programmatically.",
    "discoveryRestUrl": "https://cloudbilling.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/billing/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudbuild:v1alpha1",
    "name": "cloudbuild",
    "version": "v1alpha1",
    "title": "Cloud Build API",
    "description": "Creates and manages builds on Google Cloud Platform.",
    "discoveryRestUrl": "https://cloudbuild.googleapis.com/$discovery/rest?version=v1alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/cloud-build/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudbuild:v1",
    "name": "cloudbuild",
    "version": "v1",
    "title": "Cloud Build API",
    "description": "Creates and manages builds on Google Cloud Platform.",
    "discoveryRestUrl": "https://cloudbuild.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/cloud-build/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "clouddebugger:v2",
    "name": "clouddebugger",
    "version": "v2",
    "title": "Stackdriver Debugger API",
    "description": "Examines the call stack and variables of a running application without stopping or slowing it down.",
    "discoveryRestUrl": "https://clouddebugger.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/debugger",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "clouderrorreporting:v1beta1",
    "name": "clouderrorreporting",
    "version": "v1beta1",
    "title": "Stackdriver Error Reporting API",
    "description": "Groups and counts similar errors from cloud services and applications, reports new errors, and provides access to error groups and their associated errors.",
    "discoveryRestUrl": "https://clouderrorreporting.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/error-reporting/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudfunctions:v1",
    "name": "cloudfunctions",
    "version": "v1",
    "title": "Cloud Functions API",
    "description": "Manages lightweight user-provided functions executed in response to events.",
    "discoveryRestUrl": "https://cloudfunctions.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/functions",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudfunctions:v1beta2",
    "name": "cloudfunctions",
    "version": "v1beta2",
    "title": "Cloud Functions API",
    "description": "Manages lightweight user-provided functions executed in response to events.",
    "discoveryRestUrl": "https://cloudfunctions.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/functions",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudiot:v1",
    "name": "cloudiot",
    "version": "v1",
    "title": "Cloud IoT API",
    "description": "Registers and manages IoT (Internet of Things) devices that connect to the Google Cloud Platform.",
    "discoveryRestUrl": "https://cloudiot.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/iot",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudiot:v1beta1",
    "name": "cloudiot",
    "version": "v1beta1",
    "title": "Cloud IoT API",
    "description": "Registers and manages IoT (Internet of Things) devices that connect to the Google Cloud Platform.",
    "discoveryRestUrl": "https://cloudiot.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/iot",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudkms:v1",
    "name": "cloudkms",
    "version": "v1",
    "title": "Cloud Key Management Service (KMS) API",
    "description": "Manages keys and performs cryptographic operations in a central cloud service, for direct use by other cloud resources and applications.",
    "discoveryRestUrl": "https://cloudkms.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/kms/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudprofiler:v2",
    "name": "cloudprofiler",
    "version": "v2",
    "title": "Stackdriver Profiler API",
    "description": "Manages continuous profiling information.",
    "discoveryRestUrl": "https://cloudprofiler.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/profiler/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudresourcemanager:v1",
    "name": "cloudresourcemanager",
    "version": "v1",
    "title": "Cloud Resource Manager API",
    "description": "The Google Cloud Resource Manager API provides methods for creating, reading, and updating project metadata.",
    "discoveryRestUrl": "https://cloudresourcemanager.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/resource-manager",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudresourcemanager:v1beta1",
    "name": "cloudresourcemanager",
    "version": "v1beta1",
    "title": "Cloud Resource Manager API",
    "description": "The Google Cloud Resource Manager API provides methods for creating, reading, and updating project metadata.",
    "discoveryRestUrl": "https://cloudresourcemanager.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/resource-manager",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudresourcemanager:v2",
    "name": "cloudresourcemanager",
    "version": "v2",
    "title": "Cloud Resource Manager API",
    "description": "The Google Cloud Resource Manager API provides methods for creating, reading, and updating project metadata.",
    "discoveryRestUrl": "https://cloudresourcemanager.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/resource-manager",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudresourcemanager:v2beta1",
    "name": "cloudresourcemanager",
    "version": "v2beta1",
    "title": "Cloud Resource Manager API",
    "description": "The Google Cloud Resource Manager API provides methods for creating, reading, and updating project metadata.",
    "discoveryRestUrl": "https://cloudresourcemanager.googleapis.com/$discovery/rest?version=v2beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/resource-manager",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudshell:v1alpha1",
    "name": "cloudshell",
    "version": "v1alpha1",
    "title": "Cloud Shell API",
    "description": "Allows users to start, configure, and connect to interactive shell sessions running in the cloud.",
    "discoveryRestUrl": "https://cloudshell.googleapis.com/$discovery/rest?version=v1alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/shell/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudshell:v1",
    "name": "cloudshell",
    "version": "v1",
    "title": "Cloud Shell API",
    "description": "Allows users to start, configure, and connect to interactive shell sessions running in the cloud.",
    "discoveryRestUrl": "https://cloudshell.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/shell/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudtasks:v2beta2",
    "name": "cloudtasks",
    "version": "v2beta2",
    "title": "Cloud Tasks API",
    "description": "Manages the execution of large numbers of distributed requests.",
    "discoveryRestUrl": "https://cloudtasks.googleapis.com/$discovery/rest?version=v2beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/tasks/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudtasks:v2beta3",
    "name": "cloudtasks",
    "version": "v2beta3",
    "title": "Cloud Tasks API",
    "description": "Manages the execution of large numbers of distributed requests.",
    "discoveryRestUrl": "https://cloudtasks.googleapis.com/$discovery/rest?version=v2beta3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/tasks/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudtrace:v2alpha1",
    "name": "cloudtrace",
    "version": "v2alpha1",
    "title": "Stackdriver Trace API",
    "description": "Sends application trace data to Stackdriver Trace for viewing. Trace data is collected for all App Engine applications by default. Trace data from other applications can be provided using this API. This library is used to interact with the Trace API directly. If you are looking to instrument your application for Stackdriver Trace, we recommend using OpenCensus.",
    "discoveryRestUrl": "https://cloudtrace.googleapis.com/$discovery/rest?version=v2alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/trace",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudtrace:v1",
    "name": "cloudtrace",
    "version": "v1",
    "title": "Stackdriver Trace API",
    "description": "Sends application trace data to Stackdriver Trace for viewing. Trace data is collected for all App Engine applications by default. Trace data from other applications can be provided using this API. This library is used to interact with the Trace API directly. If you are looking to instrument your application for Stackdriver Trace, we recommend using OpenCensus.",
    "discoveryRestUrl": "https://cloudtrace.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/trace",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "cloudtrace:v2",
    "name": "cloudtrace",
    "version": "v2",
    "title": "Stackdriver Trace API",
    "description": "Sends application trace data to Stackdriver Trace for viewing. Trace data is collected for all App Engine applications by default. Trace data from other applications can be provided using this API. This library is used to interact with the Trace API directly. If you are looking to instrument your application for Stackdriver Trace, we recommend using OpenCensus.",
    "discoveryRestUrl": "https://cloudtrace.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/trace",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "composer:v1",
    "name": "composer",
    "version": "v1",
    "title": "Cloud Composer API",
    "description": "Manages Apache Airflow environments on Google Cloud Platform.",
    "discoveryRestUrl": "https://composer.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/composer/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "composer:v1beta1",
    "name": "composer",
    "version": "v1beta1",
    "title": "Cloud Composer API",
    "description": "Manages Apache Airflow environments on Google Cloud Platform.",
    "discoveryRestUrl": "https://composer.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/composer/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "compute:alpha",
    "name": "compute",
    "version": "alpha",
    "title": "Compute Engine API",
    "description": "Creates and runs virtual machines on Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/compute/alpha/rest",
    "discoveryLink": "./apis/compute/alpha/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/compute_engine-16.png",
        "x32": "https://www.google.com/images/icons/product/compute_engine-32.png"
    },
    "documentationLink": "https://developers.google.com/compute/docs/reference/latest/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "compute:beta",
    "name": "compute",
    "version": "beta",
    "title": "Compute Engine API",
    "description": "Creates and runs virtual machines on Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/compute/beta/rest",
    "discoveryLink": "./apis/compute/beta/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/compute_engine-16.png",
        "x32": "https://www.google.com/images/icons/product/compute_engine-32.png"
    },
    "documentationLink": "https://developers.google.com/compute/docs/reference/latest/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "compute:v1",
    "name": "compute",
    "version": "v1",
    "title": "Compute Engine API",
    "description": "Creates and runs virtual machines on Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/compute/v1/rest",
    "discoveryLink": "./apis/compute/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/compute_engine-16.png",
        "x32": "https://www.google.com/images/icons/product/compute_engine-32.png"
    },
    "documentationLink": "https://developers.google.com/compute/docs/reference/latest/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "container:v1",
    "name": "container",
    "version": "v1",
    "title": "Kubernetes Engine API",
    "description": "The Google Kubernetes Engine API is used for building and managing container based applications, powered by the open source Kubernetes technology.",
    "discoveryRestUrl": "https://container.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/container-engine/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "container:v1beta1",
    "name": "container",
    "version": "v1beta1",
    "title": "Kubernetes Engine API",
    "description": "The Google Kubernetes Engine API is used for building and managing container based applications, powered by the open source Kubernetes technology.",
    "discoveryRestUrl": "https://container.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/container-engine/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "content:v2",
    "name": "content",
    "version": "v2",
    "title": "Content API for Shopping",
    "description": "Manages product items, inventory, and Merchant Center accounts for Google Shopping.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/content/v2/rest",
    "discoveryLink": "./apis/content/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/shopping-content",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "customsearch:v1",
    "name": "customsearch",
    "version": "v1",
    "title": "CustomSearch API",
    "description": "Searches over a website or collection of websites",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/customsearch/v1/rest",
    "discoveryLink": "./apis/customsearch/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/custom-search/v1/using_rest",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dataflow:v1b3",
    "name": "dataflow",
    "version": "v1b3",
    "title": "Dataflow API",
    "description": "Manages Google Cloud Dataflow projects on Google Cloud Platform.",
    "discoveryRestUrl": "https://dataflow.googleapis.com/$discovery/rest?version=v1b3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dataflow",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dataproc:v1",
    "name": "dataproc",
    "version": "v1",
    "title": "Cloud Dataproc API",
    "description": "Manages Hadoop-based clusters and jobs on Google Cloud Platform.",
    "discoveryRestUrl": "https://dataproc.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dataproc/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dataproc:v1beta2",
    "name": "dataproc",
    "version": "v1beta2",
    "title": "Cloud Dataproc API",
    "description": "Manages Hadoop-based clusters and jobs on Google Cloud Platform.",
    "discoveryRestUrl": "https://dataproc.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dataproc/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "datastore:v1",
    "name": "datastore",
    "version": "v1",
    "title": "Cloud Datastore API",
    "description": "Accesses the schemaless NoSQL database to provide fully managed, robust, scalable storage for your application.",
    "discoveryRestUrl": "https://datastore.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/datastore/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "datastore:v1beta1",
    "name": "datastore",
    "version": "v1beta1",
    "title": "Cloud Datastore API",
    "description": "Accesses the schemaless NoSQL database to provide fully managed, robust, scalable storage for your application.",
    "discoveryRestUrl": "https://datastore.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/datastore/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "datastore:v1beta3",
    "name": "datastore",
    "version": "v1beta3",
    "title": "Cloud Datastore API",
    "description": "Accesses the schemaless NoSQL database to provide fully managed, robust, scalable storage for your application.",
    "discoveryRestUrl": "https://datastore.googleapis.com/$discovery/rest?version=v1beta3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/datastore/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "deploymentmanager:alpha",
    "name": "deploymentmanager",
    "version": "alpha",
    "title": "Google Cloud Deployment Manager Alpha API",
    "description": "The Deployment Manager API allows users to declaratively configure, deploy and run complex solutions on the Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/deploymentmanager/alpha/rest",
    "discoveryLink": "./apis/deploymentmanager/alpha/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/deployment-manager/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "deploymentmanager:v2beta",
    "name": "deploymentmanager",
    "version": "v2beta",
    "title": "Google Cloud Deployment Manager API V2Beta Methods",
    "description": "The Deployment Manager API allows users to declaratively configure, deploy and run complex solutions on the Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/deploymentmanager/v2beta/rest",
    "discoveryLink": "./apis/deploymentmanager/v2beta/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/deployment-manager/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "deploymentmanager:v2",
    "name": "deploymentmanager",
    "version": "v2",
    "title": "Google Cloud Deployment Manager API",
    "description": "Declares, configures, and deploys complex solutions on Google Cloud Platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/deploymentmanager/v2/rest",
    "discoveryLink": "./apis/deploymentmanager/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/deployment-manager/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dfareporting:v2.8",
    "name": "dfareporting",
    "version": "v2.8",
    "title": "DCM/DFA Reporting And Trafficking API",
    "description": "Manages your DoubleClick Campaign Manager ad campaigns and reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dfareporting/v2.8/rest",
    "discoveryLink": "./apis/dfareporting/v2.8/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/doubleclick-advertisers/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dfareporting:v3.0",
    "name": "dfareporting",
    "version": "v3.0",
    "title": "DCM/DFA Reporting And Trafficking API",
    "description": "Manages your DoubleClick Campaign Manager ad campaigns and reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dfareporting/v3.0/rest",
    "discoveryLink": "./apis/dfareporting/v3.0/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/doubleclick-advertisers/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dfareporting:v3.1",
    "name": "dfareporting",
    "version": "v3.1",
    "title": "DCM/DFA Reporting And Trafficking API",
    "description": "Manages your DoubleClick Campaign Manager ad campaigns and reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dfareporting/v3.1/rest",
    "discoveryLink": "./apis/dfareporting/v3.1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/doubleclick-advertisers/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dfareporting:v3.2",
    "name": "dfareporting",
    "version": "v3.2",
    "title": "DCM/DFA Reporting And Trafficking API",
    "description": "Manages your DoubleClick Campaign Manager ad campaigns and reports.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dfareporting/v3.2/rest",
    "discoveryLink": "./apis/dfareporting/v3.2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/doubleclick-16.gif",
        "x32": "https://www.google.com/images/icons/product/doubleclick-32.gif"
    },
    "documentationLink": "https://developers.google.com/doubleclick-advertisers/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dialogflow:v2",
    "name": "dialogflow",
    "version": "v2",
    "title": "Dialogflow API",
    "description": "Builds conversational interfaces (for example, chatbots, and voice-powered apps and devices).",
    "discoveryRestUrl": "https://dialogflow.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dialogflow-enterprise/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dialogflow:v2beta1",
    "name": "dialogflow",
    "version": "v2beta1",
    "title": "Dialogflow API",
    "description": "Builds conversational interfaces (for example, chatbots, and voice-powered apps and devices).",
    "discoveryRestUrl": "https://dialogflow.googleapis.com/$discovery/rest?version=v2beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dialogflow-enterprise/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "digitalassetlinks:v1",
    "name": "digitalassetlinks",
    "version": "v1",
    "title": "Digital Asset Links API",
    "description": "Discovers relationships between online assets such as websites or mobile apps.",
    "discoveryRestUrl": "https://digitalassetlinks.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/digital-asset-links/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "discovery:v1",
    "name": "discovery",
    "version": "v1",
    "title": "APIs Discovery Service",
    "description": "Provides information about other Google APIs, such as what APIs are available, the resource, and method details for each API.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/discovery/v1/rest",
    "discoveryLink": "./apis/discovery/v1/rest",
    "icons": {
        "x16": "http://www.google.com/images/icons/feature/filing_cabinet_search-g16.png",
        "x32": "http://www.google.com/images/icons/feature/filing_cabinet_search-g32.png"
    },
    "documentationLink": "https://developers.google.com/discovery/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dlp:v2",
    "name": "dlp",
    "version": "v2",
    "title": "Cloud Data Loss Prevention (DLP) API",
    "description": "Provides methods for detection, risk analysis, and de-identification of privacy-sensitive fragments in text, images, and Google Cloud Platform storage repositories.",
    "discoveryRestUrl": "https://dlp.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/dlp/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dns:v1",
    "name": "dns",
    "version": "v1",
    "title": "Google Cloud DNS API",
    "description": "Configures and serves authoritative DNS records.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dns/v1/rest",
    "discoveryLink": "./apis/dns/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/cloud-dns",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dns:v1beta2",
    "name": "dns",
    "version": "v1beta2",
    "title": "Google Cloud DNS API",
    "description": "Configures and serves authoritative DNS records.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dns/v1beta2/rest",
    "discoveryLink": "./apis/dns/v1beta2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/cloud-dns",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "dns:v2beta1",
    "name": "dns",
    "version": "v2beta1",
    "title": "Google Cloud DNS API",
    "description": "Configures and serves authoritative DNS records.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/dns/v2beta1/rest",
    "discoveryLink": "./apis/dns/v2beta1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/cloud-dns",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "doubleclickbidmanager:v1",
    "name": "doubleclickbidmanager",
    "version": "v1",
    "title": "DoubleClick Bid Manager API",
    "description": "API for viewing and managing your reports in DoubleClick Bid Manager.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/doubleclickbidmanager/v1/rest",
    "discoveryLink": "./apis/doubleclickbidmanager/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/bid-manager/",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "doubleclicksearch:v2",
    "name": "doubleclicksearch",
    "version": "v2",
    "title": "DoubleClick Search API",
    "description": "Reports and modifies your advertising data in DoubleClick Search (for example, campaigns, ad groups, keywords, and conversions).",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/doubleclicksearch/v2/rest",
    "discoveryLink": "./apis/doubleclicksearch/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/doubleclick-search/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "drive:v2",
    "name": "drive",
    "version": "v2",
    "title": "Drive API",
    "description": "Manages files in Drive including uploading, downloading, searching, detecting changes, and updating sharing permissions.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/drive/v2/rest",
    "discoveryLink": "./apis/drive/v2/rest",
    "icons": {
        "x16": "https://ssl.gstatic.com/docs/doclist/images/drive_icon_16.png",
        "x32": "https://ssl.gstatic.com/docs/doclist/images/drive_icon_32.png"
    },
    "documentationLink": "https://developers.google.com/drive/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "drive:v3",
    "name": "drive",
    "version": "v3",
    "title": "Drive API",
    "description": "Manages files in Drive including uploading, downloading, searching, detecting changes, and updating sharing permissions.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/drive/v3/rest",
    "discoveryLink": "./apis/drive/v3/rest",
    "icons": {
        "x16": "https://ssl.gstatic.com/docs/doclist/images/drive_icon_16.png",
        "x32": "https://ssl.gstatic.com/docs/doclist/images/drive_icon_32.png"
    },
    "documentationLink": "https://developers.google.com/drive/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "file:v1beta1",
    "name": "file",
    "version": "v1beta1",
    "title": "Cloud Filestore API",
    "description": "The Cloud Filestore API is used for creating and managing cloud file servers.",
    "discoveryRestUrl": "https://file.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/filestore/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firebasedynamiclinks:v1",
    "name": "firebasedynamiclinks",
    "version": "v1",
    "title": "Firebase Dynamic Links API",
    "description": "Programmatically creates and manages Firebase Dynamic Links.",
    "discoveryRestUrl": "https://firebasedynamiclinks.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://firebase.google.com/docs/dynamic-links/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firebasehosting:v1beta1",
    "name": "firebasehosting",
    "version": "v1beta1",
    "title": "Firebase Hosting API",
    "description": "",
    "discoveryRestUrl": "https://firebasehosting.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://firebase.google.com/docs/hosting/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firebaserules:v1",
    "name": "firebaserules",
    "version": "v1",
    "title": "Firebase Rules API",
    "description": "Creates and manages rules that determine when a Firebase Rules-enabled service should permit a request.",
    "discoveryRestUrl": "https://firebaserules.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://firebase.google.com/docs/storage/security",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firestore:v1",
    "name": "firestore",
    "version": "v1",
    "title": "Cloud Firestore API",
    "description": "Accesses the NoSQL document database built for automatic scaling, high performance, and ease of application development.",
    "discoveryRestUrl": "https://firestore.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/firestore",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firestore:v1beta1",
    "name": "firestore",
    "version": "v1beta1",
    "title": "Cloud Firestore API",
    "description": "Accesses the NoSQL document database built for automatic scaling, high performance, and ease of application development.",
    "discoveryRestUrl": "https://firestore.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/firestore",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "firestore:v1beta2",
    "name": "firestore",
    "version": "v1beta2",
    "title": "Cloud Firestore API",
    "description": "Accesses the NoSQL document database built for automatic scaling, high performance, and ease of application development.",
    "discoveryRestUrl": "https://firestore.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/firestore",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "fitness:v1",
    "name": "fitness",
    "version": "v1",
    "title": "Fitness",
    "description": "Stores and accesses user data in the fitness store from apps on any platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/fitness/v1/rest",
    "discoveryLink": "./apis/fitness/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/fit/rest/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "fusiontables:v1",
    "name": "fusiontables",
    "version": "v1",
    "title": "Fusion Tables API",
    "description": "API for working with Fusion Tables data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/fusiontables/v1/rest",
    "discoveryLink": "./apis/fusiontables/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/fusiontables",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "fusiontables:v2",
    "name": "fusiontables",
    "version": "v2",
    "title": "Fusion Tables API",
    "description": "API for working with Fusion Tables data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/fusiontables/v2/rest",
    "discoveryLink": "./apis/fusiontables/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/fusiontables",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "games:v1",
    "name": "games",
    "version": "v1",
    "title": "Google Play Game Services API",
    "description": "The API for Google Play Game Services.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/games/v1/rest",
    "discoveryLink": "./apis/games/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/games/services/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "gamesConfiguration:v1configuration",
    "name": "gamesConfiguration",
    "version": "v1configuration",
    "title": "Google Play Game Services Publishing API",
    "description": "The Publishing API for Google Play Game Services.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/gamesConfiguration/v1configuration/rest",
    "discoveryLink": "./apis/gamesConfiguration/v1configuration/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/games/services",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "gamesManagement:v1management",
    "name": "gamesManagement",
    "version": "v1management",
    "title": "Google Play Game Services Management API",
    "description": "The Management API for Google Play Game Services.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/gamesManagement/v1management/rest",
    "discoveryLink": "./apis/gamesManagement/v1management/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/games/services",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "genomics:v1alpha2",
    "name": "genomics",
    "version": "v1alpha2",
    "title": "Genomics API",
    "description": "Uploads, processes, queries, and searches Genomics data in the cloud.",
    "discoveryRestUrl": "https://genomics.googleapis.com/$discovery/rest?version=v1alpha2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/genomics",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "genomics:v2alpha1",
    "name": "genomics",
    "version": "v2alpha1",
    "title": "Genomics API",
    "description": "Uploads, processes, queries, and searches Genomics data in the cloud.",
    "discoveryRestUrl": "https://genomics.googleapis.com/$discovery/rest?version=v2alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/genomics",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "genomics:v1",
    "name": "genomics",
    "version": "v1",
    "title": "Genomics API",
    "description": "Uploads, processes, queries, and searches Genomics data in the cloud.",
    "discoveryRestUrl": "https://genomics.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/genomics",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "gmail:v1",
    "name": "gmail",
    "version": "v1",
    "title": "Gmail API",
    "description": "Access Gmail mailboxes including sending user email.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest",
    "discoveryLink": "./apis/gmail/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/googlemail-16.png",
        "x32": "https://www.google.com/images/icons/product/googlemail-32.png"
    },
    "documentationLink": "https://developers.google.com/gmail/api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "groupsmigration:v1",
    "name": "groupsmigration",
    "version": "v1",
    "title": "Groups Migration API",
    "description": "Groups Migration Api.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/groupsmigration/v1/rest",
    "discoveryLink": "./apis/groupsmigration/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/discussions-16.gif",
        "x32": "https://www.google.com/images/icons/product/discussions-32.gif"
    },
    "documentationLink": "https://developers.google.com/google-apps/groups-migration/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "groupssettings:v1",
    "name": "groupssettings",
    "version": "v1",
    "title": "Groups Settings API",
    "description": "Lets you manage permission levels and related settings of a group.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/groupssettings/v1/rest",
    "discoveryLink": "./apis/groupssettings/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/groups-settings/get_started",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "iam:v1",
    "name": "iam",
    "version": "v1",
    "title": "Identity and Access Management (IAM) API",
    "description": "Manages identity and access control for Google Cloud Platform resources, including the creation of service accounts, which you can use to authenticate to Google and make API calls.",
    "discoveryRestUrl": "https://iam.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/iam/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "iamcredentials:v1",
    "name": "iamcredentials",
    "version": "v1",
    "title": "IAM Service Account Credentials API",
    "description": "Creates short-lived, limited-privilege credentials for IAM service accounts.",
    "discoveryRestUrl": "https://iamcredentials.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/iam/docs/creating-short-lived-service-account-credentials",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "iap:v1beta1",
    "name": "iap",
    "version": "v1beta1",
    "title": "Cloud Identity-Aware Proxy API",
    "description": "Controls access to cloud applications running on Google Cloud Platform.",
    "discoveryRestUrl": "https://iap.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/iap",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "identitytoolkit:v3",
    "name": "identitytoolkit",
    "version": "v3",
    "title": "Google Identity Toolkit API",
    "description": "Help the third party sites to implement federated login.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/identitytoolkit/v3/rest",
    "discoveryLink": "./apis/identitytoolkit/v3/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/identity-toolkit/v3/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "indexing:v3",
    "name": "indexing",
    "version": "v3",
    "title": "Indexing API",
    "description": "Notifies Google when your web pages change.",
    "discoveryRestUrl": "https://indexing.googleapis.com/$discovery/rest?version=v3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/search/apis/indexing-api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "jobs:v3p1beta1",
    "name": "jobs",
    "version": "v3p1beta1",
    "title": "Cloud Talent Solution API",
    "description": "Cloud Talent Solution provides the capability to create, read, update, and delete job postings, as well as search jobs based on keywords and filters.",
    "discoveryRestUrl": "https://jobs.googleapis.com/$discovery/rest?version=v3p1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/talent-solution/job-search/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "jobs:v2",
    "name": "jobs",
    "version": "v2",
    "title": "Cloud Talent Solution API",
    "description": "Cloud Talent Solution provides the capability to create, read, update, and delete job postings, as well as search jobs based on keywords and filters.",
    "discoveryRestUrl": "https://jobs.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/talent-solution/job-search/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "jobs:v3",
    "name": "jobs",
    "version": "v3",
    "title": "Cloud Talent Solution API",
    "description": "Cloud Talent Solution provides the capability to create, read, update, and delete job postings, as well as search jobs based on keywords and filters.",
    "discoveryRestUrl": "https://jobs.googleapis.com/$discovery/rest?version=v3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/talent-solution/job-search/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "kgsearch:v1",
    "name": "kgsearch",
    "version": "v1",
    "title": "Knowledge Graph Search API",
    "description": "Searches the Google Knowledge Graph for entities.",
    "discoveryRestUrl": "https://kgsearch.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/knowledge-graph/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "language:v1",
    "name": "language",
    "version": "v1",
    "title": "Cloud Natural Language API",
    "description": "Provides natural language understanding technologies to developers. Examples include sentiment analysis, entity recognition, entity sentiment analysis, and text annotations.",
    "discoveryRestUrl": "https://language.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/natural-language/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "language:v1beta1",
    "name": "language",
    "version": "v1beta1",
    "title": "Cloud Natural Language API",
    "description": "Provides natural language understanding technologies to developers. Examples include sentiment analysis, entity recognition, entity sentiment analysis, and text annotations.",
    "discoveryRestUrl": "https://language.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/natural-language/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "language:v1beta2",
    "name": "language",
    "version": "v1beta2",
    "title": "Cloud Natural Language API",
    "description": "Provides natural language understanding technologies to developers. Examples include sentiment analysis, entity recognition, entity sentiment analysis, and text annotations.",
    "discoveryRestUrl": "https://language.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/natural-language/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "licensing:v1",
    "name": "licensing",
    "version": "v1",
    "title": "Enterprise License Manager API",
    "description": "Views and manages licenses for your domain.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/licensing/v1/rest",
    "discoveryLink": "./apis/licensing/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/licensing/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "logging:v2",
    "name": "logging",
    "version": "v2",
    "title": "Stackdriver Logging API",
    "description": "Writes log entries and manages your Logging configuration.",
    "discoveryRestUrl": "https://logging.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/logging/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "logging:v2beta1",
    "name": "logging",
    "version": "v2beta1",
    "title": "Stackdriver Logging API",
    "description": "Writes log entries and manages your Logging configuration.",
    "discoveryRestUrl": "https://logging.googleapis.com/$discovery/rest?version=v2beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/logging/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "manufacturers:v1",
    "name": "manufacturers",
    "version": "v1",
    "title": "Manufacturer Center API",
    "description": "Public API for managing Manufacturer Center related data.",
    "discoveryRestUrl": "https://manufacturers.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/manufacturers/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "mirror:v1",
    "name": "mirror",
    "version": "v1",
    "title": "Google Mirror API",
    "description": "Interacts with Glass users via the timeline.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/mirror/v1/rest",
    "discoveryLink": "./apis/mirror/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/glass",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "ml:v1",
    "name": "ml",
    "version": "v1",
    "title": "Cloud Machine Learning Engine",
    "description": "An API to enable creating and using machine learning models.",
    "discoveryRestUrl": "https://ml.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/ml/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "monitoring:v3",
    "name": "monitoring",
    "version": "v3",
    "title": "Stackdriver Monitoring API",
    "description": "Manages your Stackdriver Monitoring data and configurations. Most projects must be associated with a Stackdriver account, with a few exceptions as noted on the individual method pages.",
    "discoveryRestUrl": "https://monitoring.googleapis.com/$discovery/rest?version=v3",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/monitoring/api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "oauth2:v1",
    "name": "oauth2",
    "version": "v1",
    "title": "Google OAuth2 API",
    "description": "Obtains end-user authorization grants for use with other Google APIs.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/oauth2/v1/rest",
    "discoveryLink": "./apis/oauth2/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/accounts/docs/OAuth2",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "oauth2:v2",
    "name": "oauth2",
    "version": "v2",
    "title": "Google OAuth2 API",
    "description": "Obtains end-user authorization grants for use with other Google APIs.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/oauth2/v2/rest",
    "discoveryLink": "./apis/oauth2/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/accounts/docs/OAuth2",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "oslogin:v1alpha",
    "name": "oslogin",
    "version": "v1alpha",
    "title": "Cloud OS Login API",
    "description": "Manages OS login configuration for Google account users.",
    "discoveryRestUrl": "https://oslogin.googleapis.com/$discovery/rest?version=v1alpha",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/compute/docs/oslogin/rest/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "oslogin:v1beta",
    "name": "oslogin",
    "version": "v1beta",
    "title": "Cloud OS Login API",
    "description": "Manages OS login configuration for Google account users.",
    "discoveryRestUrl": "https://oslogin.googleapis.com/$discovery/rest?version=v1beta",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/compute/docs/oslogin/rest/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "oslogin:v1",
    "name": "oslogin",
    "version": "v1",
    "title": "Cloud OS Login API",
    "description": "Manages OS login configuration for Google account users.",
    "discoveryRestUrl": "https://oslogin.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/compute/docs/oslogin/rest/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pagespeedonline:v1",
    "name": "pagespeedonline",
    "version": "v1",
    "title": "PageSpeed Insights API",
    "description": "Analyzes the performance of a web page and provides tailored suggestions to make that page faster.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/pagespeedonline/v1/rest",
    "discoveryLink": "./apis/pagespeedonline/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/pagespeed-16.png",
        "x32": "https://www.google.com/images/icons/product/pagespeed-32.png"
    },
    "documentationLink": "https://developers.google.com/speed/docs/insights/v1/getting_started",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pagespeedonline:v2",
    "name": "pagespeedonline",
    "version": "v2",
    "title": "PageSpeed Insights API",
    "description": "Analyzes the performance of a web page and provides tailored suggestions to make that page faster.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/pagespeedonline/v2/rest",
    "discoveryLink": "./apis/pagespeedonline/v2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/pagespeed-16.png",
        "x32": "https://www.google.com/images/icons/product/pagespeed-32.png"
    },
    "documentationLink": "https://developers.google.com/speed/docs/insights/v2/getting-started",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pagespeedonline:v4",
    "name": "pagespeedonline",
    "version": "v4",
    "title": "PageSpeed Insights API",
    "description": "Analyzes the performance of a web page and provides tailored suggestions to make that page faster.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/pagespeedonline/v4/rest",
    "discoveryLink": "./apis/pagespeedonline/v4/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/pagespeed-16.png",
        "x32": "https://www.google.com/images/icons/product/pagespeed-32.png"
    },
    "documentationLink": "https://developers.google.com/speed/docs/insights/v4/getting-started",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "partners:v2",
    "name": "partners",
    "version": "v2",
    "title": "Google Partners API",
    "description": "Searches certified companies and creates contact leads with them, and also audits the usage of clients.",
    "discoveryRestUrl": "https://partners.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/partners/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "people:v1",
    "name": "people",
    "version": "v1",
    "title": "People API",
    "description": "Provides access to information about profiles and contacts.",
    "discoveryRestUrl": "https://people.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/people/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "playcustomapp:v1",
    "name": "playcustomapp",
    "version": "v1",
    "title": "Google Play Custom App Publishing API",
    "description": "An API to publish custom Android apps.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/playcustomapp/v1/rest",
    "discoveryLink": "./apis/playcustomapp/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/android/work/play/custom-app-api",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "plus:v1",
    "name": "plus",
    "version": "v1",
    "title": "Google+ API",
    "description": "Builds on top of the Google+ platform.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/plus/v1/rest",
    "discoveryLink": "./apis/plus/v1/rest",
    "icons": {
        "x16": "http://www.google.com/images/icons/product/gplus-16.png",
        "x32": "http://www.google.com/images/icons/product/gplus-32.png"
    },
    "documentationLink": "https://developers.google.com/+/api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "plusDomains:v1",
    "name": "plusDomains",
    "version": "v1",
    "title": "Google+ Domains API",
    "description": "Builds on top of the Google+ platform for Google Apps Domains.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/plusDomains/v1/rest",
    "discoveryLink": "./apis/plusDomains/v1/rest",
    "icons": {
        "x16": "http://www.google.com/images/icons/product/gplus-16.png",
        "x32": "http://www.google.com/images/icons/product/gplus-32.png"
    },
    "documentationLink": "https://developers.google.com/+/domains/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "poly:v1",
    "name": "poly",
    "version": "v1",
    "title": "Poly API",
    "description": "The Poly API provides read access to assets hosted on poly.google.com to all, and upload access to poly.google.com for whitelisted accounts.",
    "discoveryRestUrl": "https://poly.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/poly/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "proximitybeacon:v1beta1",
    "name": "proximitybeacon",
    "version": "v1beta1",
    "title": "Proximity Beacon API",
    "description": "Registers, manages, indexes, and searches beacons.",
    "discoveryRestUrl": "https://proximitybeacon.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/beacons/proximity/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pubsub:v1beta1a",
    "name": "pubsub",
    "version": "v1beta1a",
    "title": "Cloud Pub/Sub API",
    "description": "Provides reliable, many-to-many, asynchronous messaging between applications.",
    "discoveryRestUrl": "https://pubsub.googleapis.com/$discovery/rest?version=v1beta1a",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/pubsub/docs",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pubsub:v1",
    "name": "pubsub",
    "version": "v1",
    "title": "Cloud Pub/Sub API",
    "description": "Provides reliable, many-to-many, asynchronous messaging between applications.",
    "discoveryRestUrl": "https://pubsub.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/pubsub/docs",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "pubsub:v1beta2",
    "name": "pubsub",
    "version": "v1beta2",
    "title": "Cloud Pub/Sub API",
    "description": "Provides reliable, many-to-many, asynchronous messaging between applications.",
    "discoveryRestUrl": "https://pubsub.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/pubsub/docs",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "redis:v1",
    "name": "redis",
    "version": "v1",
    "title": "Google Cloud Memorystore for Redis API",
    "description": "The Google Cloud Memorystore for Redis API is used for creating and managing Redis instances on the Google Cloud Platform.",
    "discoveryRestUrl": "https://redis.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/memorystore/docs/redis/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "redis:v1beta1",
    "name": "redis",
    "version": "v1beta1",
    "title": "Google Cloud Memorystore for Redis API",
    "description": "The Google Cloud Memorystore for Redis API is used for creating and managing Redis instances on the Google Cloud Platform.",
    "discoveryRestUrl": "https://redis.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/memorystore/docs/redis/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "replicapool:v1beta1",
    "name": "replicapool",
    "version": "v1beta1",
    "title": "Replica Pool API",
    "description": "The Replica Pool API allows users to declaratively provision and manage groups of Google Compute Engine instances based on a common template.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/replicapool/v1beta1/rest",
    "discoveryLink": "./apis/replicapool/v1beta1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/compute/docs/replica-pool/",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "replicapoolupdater:v1beta1",
    "name": "replicapoolupdater",
    "version": "v1beta1",
    "title": "Google Compute Engine Instance Group Updater API",
    "description": "[Deprecated. Please use compute.instanceGroupManagers.update method. replicapoolupdater API will be disabled after December 30th, 2016] Updates groups of Compute Engine instances.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/replicapoolupdater/v1beta1/rest",
    "discoveryLink": "./apis/replicapoolupdater/v1beta1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/compute/docs/instance-groups/manager/#applying_rolling_updates_using_the_updater_service",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "reseller:v1",
    "name": "reseller",
    "version": "v1",
    "title": "Enterprise Apps Reseller API",
    "description": "Creates and manages your customers and their subscriptions.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/reseller/v1/rest",
    "discoveryLink": "./apis/reseller/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/reseller/",
    "labels": [
        "limited_availability"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "runtimeconfig:v1",
    "name": "runtimeconfig",
    "version": "v1",
    "title": "Cloud Runtime Configuration API",
    "description": "The Runtime Configurator allows you to dynamically configure and expose variables through Google Cloud Platform. In addition, you can also set Watchers and Waiters that will watch for changes to your data and return based on certain conditions.",
    "discoveryRestUrl": "https://runtimeconfig.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/deployment-manager/runtime-configurator/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "runtimeconfig:v1beta1",
    "name": "runtimeconfig",
    "version": "v1beta1",
    "title": "Cloud Runtime Configuration API",
    "description": "The Runtime Configurator allows you to dynamically configure and expose variables through Google Cloud Platform. In addition, you can also set Watchers and Waiters that will watch for changes to your data and return based on certain conditions.",
    "discoveryRestUrl": "https://runtimeconfig.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/deployment-manager/runtime-configurator/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "safebrowsing:v4",
    "name": "safebrowsing",
    "version": "v4",
    "title": "Safe Browsing API",
    "description": "Enables client applications to check web resources (most commonly URLs) against Google-generated lists of unsafe web resources.",
    "discoveryRestUrl": "https://safebrowsing.googleapis.com/$discovery/rest?version=v4",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/safe-browsing/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "script:v1",
    "name": "script",
    "version": "v1",
    "title": "Apps Script API",
    "description": "Manages and executes Google Apps Script projects.",
    "discoveryRestUrl": "https://script.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/apps-script/api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "searchconsole:v1",
    "name": "searchconsole",
    "version": "v1",
    "title": "Google Search Console URL Testing Tools API",
    "description": "Provides tools for running validation tests against single URLs",
    "discoveryRestUrl": "https://searchconsole.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/webmaster-tools/search-console-api/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicebroker:v1alpha1",
    "name": "servicebroker",
    "version": "v1alpha1",
    "title": "Service Broker API",
    "description": "The Google Cloud Platform Service Broker API provides Google hosted implementation of the Open Service Broker API (https://www.openservicebrokerapi.org/).",
    "discoveryRestUrl": "https://servicebroker.googleapis.com/$discovery/rest?version=v1alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/kubernetes-engine/docs/concepts/add-on/service-broker",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicebroker:v1",
    "name": "servicebroker",
    "version": "v1",
    "title": "Service Broker API",
    "description": "The Google Cloud Platform Service Broker API provides Google hosted implementation of the Open Service Broker API (https://www.openservicebrokerapi.org/).",
    "discoveryRestUrl": "https://servicebroker.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/kubernetes-engine/docs/concepts/add-on/service-broker",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicebroker:v1beta1",
    "name": "servicebroker",
    "version": "v1beta1",
    "title": "Service Broker API",
    "description": "The Google Cloud Platform Service Broker API provides Google hosted implementation of the Open Service Broker API (https://www.openservicebrokerapi.org/).",
    "discoveryRestUrl": "https://servicebroker.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/kubernetes-engine/docs/concepts/add-on/service-broker",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "serviceconsumermanagement:v1",
    "name": "serviceconsumermanagement",
    "version": "v1",
    "title": "Service Consumer Management API",
    "description": "Manages the service consumers of a Service Infrastructure service.",
    "discoveryRestUrl": "https://serviceconsumermanagement.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-consumer-management/docs/overview",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicecontrol:v1",
    "name": "servicecontrol",
    "version": "v1",
    "title": "Service Control API",
    "description": "Provides control plane functionality to managed services, such as logging, monitoring, and status checks.",
    "discoveryRestUrl": "https://servicecontrol.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-control/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicemanagement:v1",
    "name": "servicemanagement",
    "version": "v1",
    "title": "Service Management API",
    "description": "Google Service Management allows service producers to publish their services on Google Cloud Platform so that they can be discovered and used by service consumers.",
    "discoveryRestUrl": "https://servicemanagement.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-management/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "servicenetworking:v1beta",
    "name": "servicenetworking",
    "version": "v1beta",
    "title": "Service Networking API",
    "description": "Provides automatic management of network configurations necessary for certain services.",
    "discoveryRestUrl": "https://servicenetworking.googleapis.com/$discovery/rest?version=v1beta",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-infrastructure/docs/service-networking/getting-started",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "serviceusage:v1",
    "name": "serviceusage",
    "version": "v1",
    "title": "Service Usage API",
    "description": "Enables services that service consumers want to use on Google Cloud Platform, lists the available or enabled services, or disables services that service consumers no longer use.",
    "discoveryRestUrl": "https://serviceusage.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-usage/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "serviceusage:v1beta1",
    "name": "serviceusage",
    "version": "v1beta1",
    "title": "Service Usage API",
    "description": "Enables services that service consumers want to use on Google Cloud Platform, lists the available or enabled services, or disables services that service consumers no longer use.",
    "discoveryRestUrl": "https://serviceusage.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/service-usage/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "sheets:v4",
    "name": "sheets",
    "version": "v4",
    "title": "Google Sheets API",
    "description": "Reads and writes Google Sheets.",
    "discoveryRestUrl": "https://sheets.googleapis.com/$discovery/rest?version=v4",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/sheets/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "siteVerification:v1",
    "name": "siteVerification",
    "version": "v1",
    "title": "Google Site Verification API",
    "description": "Verifies ownership of websites or domains with Google.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/siteVerification/v1/rest",
    "discoveryLink": "./apis/siteVerification/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/site-verification/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "slides:v1",
    "name": "slides",
    "version": "v1",
    "title": "Google Slides API",
    "description": "An API for creating and editing Google Slides presentations.",
    "discoveryRestUrl": "https://slides.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/slides/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "sourcerepo:v1",
    "name": "sourcerepo",
    "version": "v1",
    "title": "Cloud Source Repositories API",
    "description": "Access source code repositories hosted by Google.",
    "discoveryRestUrl": "https://sourcerepo.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/source-repositories/docs/apis",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "spanner:v1",
    "name": "spanner",
    "version": "v1",
    "title": "Cloud Spanner API",
    "description": "Cloud Spanner is a managed, mission-critical, globally consistent and scalable relational database service.",
    "discoveryRestUrl": "https://spanner.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/spanner/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "speech:v1",
    "name": "speech",
    "version": "v1",
    "title": "Cloud Speech API",
    "description": "Converts audio to text by applying powerful neural network models.",
    "discoveryRestUrl": "https://speech.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/speech-to-text/docs/quickstart-protocol",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "speech:v1beta1",
    "name": "speech",
    "version": "v1beta1",
    "title": "Cloud Speech API",
    "description": "Converts audio to text by applying powerful neural network models.",
    "discoveryRestUrl": "https://speech.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/speech-to-text/docs/quickstart-protocol",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "sqladmin:v1beta4",
    "name": "sqladmin",
    "version": "v1beta4",
    "title": "Cloud SQL Admin API",
    "description": "Creates and manages Cloud SQL instances, which provide fully managed MySQL or PostgreSQL databases.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/sqladmin/v1beta4/rest",
    "discoveryLink": "./apis/sqladmin/v1beta4/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/sql/docs/reference/latest",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "storage:v1",
    "name": "storage",
    "version": "v1",
    "title": "Cloud Storage JSON API",
    "description": "Stores and retrieves potentially large, immutable data objects.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/storage/v1/rest",
    "discoveryLink": "./apis/storage/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/cloud_storage-16.png",
        "x32": "https://www.google.com/images/icons/product/cloud_storage-32.png"
    },
    "documentationLink": "https://developers.google.com/storage/docs/json_api/",
    "labels": [
        "labs"
    ],
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "storage:v1beta1",
    "name": "storage",
    "version": "v1beta1",
    "title": "Cloud Storage JSON API",
    "description": "Lets you store and retrieve potentially-large, immutable data objects.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/storage/v1beta1/rest",
    "discoveryLink": "./apis/storage/v1beta1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/cloud_storage-16.png",
        "x32": "https://www.google.com/images/icons/product/cloud_storage-32.png"
    },
    "documentationLink": "https://developers.google.com/storage/docs/json_api/",
    "labels": [
        "labs"
    ],
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "storage:v1beta2",
    "name": "storage",
    "version": "v1beta2",
    "title": "Cloud Storage JSON API",
    "description": "Lets you store and retrieve potentially-large, immutable data objects.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/storage/v1beta2/rest",
    "discoveryLink": "./apis/storage/v1beta2/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/cloud_storage-16.png",
        "x32": "https://www.google.com/images/icons/product/cloud_storage-32.png"
    },
    "documentationLink": "https://developers.google.com/storage/docs/json_api/",
    "labels": [
        "labs"
    ],
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "storagetransfer:v1",
    "name": "storagetransfer",
    "version": "v1",
    "title": "Storage Transfer API",
    "description": "Transfers data from external data sources to a Google Cloud Storage bucket or between Google Cloud Storage buckets.",
    "discoveryRestUrl": "https://storagetransfer.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/storage/transfer",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "streetviewpublish:v1",
    "name": "streetviewpublish",
    "version": "v1",
    "title": "Street View Publish API",
    "description": "Publishes 360 photos to Google Maps, along with position, orientation, and connectivity metadata. Apps can offer an interface for positioning, connecting, and uploading user-generated Street View images.",
    "discoveryRestUrl": "https://streetviewpublish.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/streetview/publish/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "surveys:v2",
    "name": "surveys",
    "version": "v2",
    "title": "Surveys API",
    "description": "Creates and conducts surveys, lists the surveys that an authenticated user owns, and retrieves survey results and information about specified surveys.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/surveys/v2/rest",
    "discoveryLink": "./apis/surveys/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "tagmanager:v1",
    "name": "tagmanager",
    "version": "v1",
    "title": "Tag Manager API",
    "description": "Accesses Tag Manager accounts and containers.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/tagmanager/v1/rest",
    "discoveryLink": "./apis/tagmanager/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/tag-manager/api/v1/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "tagmanager:v2",
    "name": "tagmanager",
    "version": "v2",
    "title": "Tag Manager API",
    "description": "Accesses Tag Manager accounts and containers.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/tagmanager/v2/rest",
    "discoveryLink": "./apis/tagmanager/v2/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/tag-manager/api/v2/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "tasks:v1",
    "name": "tasks",
    "version": "v1",
    "title": "Tasks API",
    "description": "Lets you manage your tasks and task lists.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/tasks/v1/rest",
    "discoveryLink": "./apis/tasks/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/tasks-16.png",
        "x32": "https://www.google.com/images/icons/product/tasks-32.png"
    },
    "documentationLink": "https://developers.google.com/google-apps/tasks/firstapp",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "testing:v1",
    "name": "testing",
    "version": "v1",
    "title": "Cloud Testing API",
    "description": "Allows developers to run automated tests for their mobile applications on Google infrastructure.",
    "discoveryRestUrl": "https://testing.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/cloud-test-lab/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "texttospeech:v1",
    "name": "texttospeech",
    "version": "v1",
    "title": "Cloud Text-to-Speech API",
    "description": "Synthesizes natural-sounding speech by applying powerful neural network models.",
    "discoveryRestUrl": "https://texttospeech.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/text-to-speech/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "texttospeech:v1beta1",
    "name": "texttospeech",
    "version": "v1beta1",
    "title": "Cloud Text-to-Speech API",
    "description": "Synthesizes natural-sounding speech by applying powerful neural network models.",
    "discoveryRestUrl": "https://texttospeech.googleapis.com/$discovery/rest?version=v1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/text-to-speech/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "toolresults:v1beta3",
    "name": "toolresults",
    "version": "v1beta3",
    "title": "Cloud Tool Results API",
    "description": "Reads and publishes results from Firebase Test Lab.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/toolresults/v1beta3/rest",
    "discoveryLink": "./apis/toolresults/v1beta3/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://firebase.google.com/docs/test-lab/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "tpu:v1alpha1",
    "name": "tpu",
    "version": "v1alpha1",
    "title": "Cloud TPU API",
    "description": "TPU API provides customers with access to Google TPU technology.",
    "discoveryRestUrl": "https://tpu.googleapis.com/$discovery/rest?version=v1alpha1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/tpu/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "tpu:v1",
    "name": "tpu",
    "version": "v1",
    "title": "Cloud TPU API",
    "description": "TPU API provides customers with access to Google TPU technology.",
    "discoveryRestUrl": "https://tpu.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/tpu/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "translate:v2",
    "name": "translate",
    "version": "v2",
    "title": "Cloud Translation API",
    "description": "Integrates text translation into your website or application.",
    "discoveryRestUrl": "https://translation.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://code.google.com/apis/language/translate/v2/getting_started.html",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "urlshortener:v1",
    "name": "urlshortener",
    "version": "v1",
    "title": "URL Shortener API",
    "description": "Lets you create, inspect, and manage goo.gl short URLs",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/urlshortener/v1/rest",
    "discoveryLink": "./apis/urlshortener/v1/rest",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/url-shortener/v1/getting_started",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "vault:v1",
    "name": "vault",
    "version": "v1",
    "title": "G Suite Vault API",
    "description": "Archiving and eDiscovery for G Suite.",
    "discoveryRestUrl": "https://vault.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/vault",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "videointelligence:v1p1beta1",
    "name": "videointelligence",
    "version": "v1p1beta1",
    "title": "Cloud Video Intelligence API",
    "description": "Cloud Video Intelligence API.",
    "discoveryRestUrl": "https://videointelligence.googleapis.com/$discovery/rest?version=v1p1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/video-intelligence/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "videointelligence:v1",
    "name": "videointelligence",
    "version": "v1",
    "title": "Cloud Video Intelligence API",
    "description": "Cloud Video Intelligence API.",
    "discoveryRestUrl": "https://videointelligence.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/video-intelligence/docs/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "videointelligence:v1beta2",
    "name": "videointelligence",
    "version": "v1beta2",
    "title": "Cloud Video Intelligence API",
    "description": "Cloud Video Intelligence API.",
    "discoveryRestUrl": "https://videointelligence.googleapis.com/$discovery/rest?version=v1beta2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/video-intelligence/docs/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "vision:v1p1beta1",
    "name": "vision",
    "version": "v1p1beta1",
    "title": "Cloud Vision API",
    "description": "Integrates Google Vision features, including image labeling, face, logo, and landmark detection, optical character recognition (OCR), and detection of explicit content, into applications.",
    "discoveryRestUrl": "https://vision.googleapis.com/$discovery/rest?version=v1p1beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/vision/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "vision:v1p2beta1",
    "name": "vision",
    "version": "v1p2beta1",
    "title": "Cloud Vision API",
    "description": "Integrates Google Vision features, including image labeling, face, logo, and landmark detection, optical character recognition (OCR), and detection of explicit content, into applications.",
    "discoveryRestUrl": "https://vision.googleapis.com/$discovery/rest?version=v1p2beta1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/vision/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "vision:v1",
    "name": "vision",
    "version": "v1",
    "title": "Cloud Vision API",
    "description": "Integrates Google Vision features, including image labeling, face, logo, and landmark detection, optical character recognition (OCR), and detection of explicit content, into applications.",
    "discoveryRestUrl": "https://vision.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/vision/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "webfonts:v1",
    "name": "webfonts",
    "version": "v1",
    "title": "Google Fonts Developer API",
    "description": "Accesses the metadata for all families served by Google Fonts, providing a list of families currently available (including available styles and a list of supported script subsets).",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/webfonts/v1/rest",
    "discoveryLink": "./apis/webfonts/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/feature/font_api-16.png",
        "x32": "https://www.google.com/images/icons/feature/font_api-32.gif"
    },
    "documentationLink": "https://developers.google.com/fonts/docs/developer_api",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "webmasters:v3",
    "name": "webmasters",
    "version": "v3",
    "title": "Search Console API",
    "description": "View Google Search Console data for your verified sites.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/webmasters/v3/rest",
    "discoveryLink": "./apis/webmasters/v3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/webmaster_tools-16.png",
        "x32": "https://www.google.com/images/icons/product/webmaster_tools-32.png"
    },
    "documentationLink": "https://developers.google.com/webmaster-tools/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "websecurityscanner:v1alpha",
    "name": "websecurityscanner",
    "version": "v1alpha",
    "title": "Web Security Scanner API",
    "description": "Web Security Scanner API (under development).",
    "discoveryRestUrl": "https://websecurityscanner.googleapis.com/$discovery/rest?version=v1alpha",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/security-scanner/",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "websecurityscanner:v1beta",
    "name": "websecurityscanner",
    "version": "v1beta",
    "title": "Web Security Scanner API",
    "description": "Web Security Scanner API (under development).",
    "discoveryRestUrl": "https://websecurityscanner.googleapis.com/$discovery/rest?version=v1beta",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://cloud.google.com/security-scanner/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "youtube:v3",
    "name": "youtube",
    "version": "v3",
    "title": "YouTube Data API",
    "description": "Supports core YouTube features, such as uploading videos, creating and managing playlists, searching for content, and much more.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest",
    "discoveryLink": "./apis/youtube/v3/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/youtube-16.png",
        "x32": "https://www.google.com/images/icons/product/youtube-32.png"
    },
    "documentationLink": "https://developers.google.com/youtube/v3",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "youtubeAnalytics:v1",
    "name": "youtubeAnalytics",
    "version": "v1",
    "title": "YouTube Analytics API",
    "description": "Retrieves your YouTube Analytics data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/youtubeAnalytics/v1/rest",
    "discoveryLink": "./apis/youtubeAnalytics/v1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/youtube-16.png",
        "x32": "https://www.google.com/images/icons/product/youtube-32.png"
    },
    "documentationLink": "http://developers.google.com/youtube/analytics/",
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "youtubeAnalytics:v1beta1",
    "name": "youtubeAnalytics",
    "version": "v1beta1",
    "title": "YouTube Analytics API",
    "description": "Retrieves your YouTube Analytics data.",
    "discoveryRestUrl": "https://www.googleapis.com/discovery/v1/apis/youtubeAnalytics/v1beta1/rest",
    "discoveryLink": "./apis/youtubeAnalytics/v1beta1/rest",
    "icons": {
        "x16": "https://www.google.com/images/icons/product/youtube-16.png",
        "x32": "https://www.google.com/images/icons/product/youtube-32.png"
    },
    "documentationLink": "http://developers.google.com/youtube/analytics/",
    "labels": [
        "deprecated"
    ],
    "preferred": false
    },
    {
    "kind": "discovery#directoryItem",
    "id": "youtubeAnalytics:v2",
    "name": "youtubeAnalytics",
    "version": "v2",
    "title": "YouTube Analytics API",
    "description": "Retrieves your YouTube Analytics data.",
    "discoveryRestUrl": "https://youtubeanalytics.googleapis.com/$discovery/rest?version=v2",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/youtube/analytics",
    "preferred": true
    },
    {
    "kind": "discovery#directoryItem",
    "id": "youtubereporting:v1",
    "name": "youtubereporting",
    "version": "v1",
    "title": "YouTube Reporting API",
    "description": "Schedules reporting jobs containing your YouTube Analytics data and downloads the resulting bulk data reports in the form of CSV files.",
    "discoveryRestUrl": "https://youtubereporting.googleapis.com/$discovery/rest?version=v1",
    "icons": {
        "x16": "https://www.gstatic.com/images/branding/product/1x/googleg_16dp.png",
        "x32": "https://www.gstatic.com/images/branding/product/1x/googleg_32dp.png"
    },
    "documentationLink": "https://developers.google.com/youtube/reporting/v1/reports/",
    "preferred": true
    }
    ]
}
_END
}

sub pre_get_gmail_spec_json
{
  return <<'__END'
{
 "kind": "discovery#restDescription",
 "etag": "\"J3WqvAcMk4eQjJXvfSI4Yr8VouA/zhBQnUVXp-QQ6Y6QUt5UiGZD_sA\"",
 "discoveryVersion": "v1",
 "id": "gmail:v1",
 "name": "gmail",
 "version": "v1",
 "revision": "20180904",
 "title": "Gmail API",
 "description": "Access Gmail mailboxes including sending user email.",
 "ownerDomain": "google.com",
 "ownerName": "Google",
 "icons": {
  "x16": "https://www.google.com/images/icons/product/googlemail-16.png",
  "x32": "https://www.google.com/images/icons/product/googlemail-32.png"
 },
 "documentationLink": "https://developers.google.com/gmail/api/",
 "protocol": "rest",
 "baseUrl": "https://www.googleapis.com/gmail/v1/users/",
 "basePath": "/gmail/v1/users/",
 "rootUrl": "https://www.googleapis.com/",
 "servicePath": "gmail/v1/users/",
 "batchPath": "batch/gmail/v1",
 "parameters": {
  "alt": {
   "type": "string",
   "description": "Data format for the response.",
   "default": "json",
   "enum": [
    "json"
   ],
   "enumDescriptions": [
    "Responses with Content-Type of application/json"
   ],
   "location": "query"
  },
  "fields": {
   "type": "string",
   "description": "Selector specifying which fields to include in a partial response.",
   "location": "query"
  },
  "key": {
   "type": "string",
   "description": "API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.",
   "location": "query"
  },
  "oauth_token": {
   "type": "string",
   "description": "OAuth 2.0 token for the current user.",
   "location": "query"
  },
  "prettyPrint": {
   "type": "boolean",
   "description": "Returns response with indentations and line breaks.",
   "default": "true",
   "location": "query"
  },
  "quotaUser": {
   "type": "string",
   "description": "An opaque string that represents a user for quota purposes. Must not exceed 40 characters.",
   "location": "query"
  },
  "userIp": {
   "type": "string",
   "description": "Deprecated. Please use quotaUser instead.",
   "location": "query"
  }
 },
 "auth": {
  "oauth2": {
   "scopes": {
    "https://mail.google.com/": {
     "description": "Read, send, delete, and manage your email"
    },
    "https://www.googleapis.com/auth/gmail.compose": {
     "description": "Manage drafts and send emails"
    },
    "https://www.googleapis.com/auth/gmail.insert": {
     "description": "Insert mail into your mailbox"
    },
    "https://www.googleapis.com/auth/gmail.labels": {
     "description": "Manage mailbox labels"
    },
    "https://www.googleapis.com/auth/gmail.metadata": {
     "description": "View your email message metadata such as labels and headers, but not the email body"
    },
    "https://www.googleapis.com/auth/gmail.modify": {
     "description": "View and modify but not delete your email"
    },
    "https://www.googleapis.com/auth/gmail.readonly": {
     "description": "View your email messages and settings"
    },
    "https://www.googleapis.com/auth/gmail.send": {
     "description": "Send email on your behalf"
    },
    "https://www.googleapis.com/auth/gmail.settings.basic": {
     "description": "Manage your basic mail settings"
    },
    "https://www.googleapis.com/auth/gmail.settings.sharing": {
     "description": "Manage your sensitive mail settings, including who can manage your mail"
    }
   }
  }
 },
 "schemas": {
  "AutoForwarding": {
   "id": "AutoForwarding",
   "type": "object",
   "description": "Auto-forwarding settings for an account.",
   "properties": {
    "disposition": {
     "type": "string",
     "description": "The state that a message should be left in after it has been forwarded.",
     "enum": [
      "archive",
      "dispositionUnspecified",
      "leaveInInbox",
      "markRead",
      "trash"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      "",
      ""
     ]
    },
    "emailAddress": {
     "type": "string",
     "description": "Email address to which all incoming messages are forwarded. This email address must be a verified member of the forwarding addresses."
    },
    "enabled": {
     "type": "boolean",
     "description": "Whether all incoming mail is automatically forwarded to another address."
    }
   }
  },
  "BatchDeleteMessagesRequest": {
   "id": "BatchDeleteMessagesRequest",
   "type": "object",
   "properties": {
    "ids": {
     "type": "array",
     "description": "The IDs of the messages to delete.",
     "items": {
      "type": "string"
     }
    }
   }
  },
  "BatchModifyMessagesRequest": {
   "id": "BatchModifyMessagesRequest",
   "type": "object",
   "properties": {
    "addLabelIds": {
     "type": "array",
     "description": "A list of label IDs to add to messages.",
     "items": {
      "type": "string"
     }
    },
    "ids": {
     "type": "array",
     "description": "The IDs of the messages to modify. There is a limit of 1000 ids per request.",
     "items": {
      "type": "string"
     }
    },
    "removeLabelIds": {
     "type": "array",
     "description": "A list of label IDs to remove from messages.",
     "items": {
      "type": "string"
     }
    }
   }
  },
  "Delegate": {
   "id": "Delegate",
   "type": "object",
   "description": "Settings for a delegate. Delegates can read, send, and delete messages, as well as manage contacts, for the delegator's account. See \"Set up mail delegation\" for more information about delegates.",
   "properties": {
    "delegateEmail": {
     "type": "string",
     "description": "The email address of the delegate."
    },
    "verificationStatus": {
     "type": "string",
     "description": "Indicates whether this address has been verified and can act as a delegate for the account. Read-only.",
     "enum": [
      "accepted",
      "expired",
      "pending",
      "rejected",
      "verificationStatusUnspecified"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      "",
      ""
     ]
    }
   }
  },
  "Draft": {
   "id": "Draft",
   "type": "object",
   "description": "A draft email in the user's mailbox.",
   "properties": {
    "id": {
     "type": "string",
     "description": "The immutable ID of the draft.",
     "annotations": {
      "required": [
       "gmail.users.drafts.send"
      ]
     }
    },
    "message": {
     "$ref": "Message",
     "description": "The message content of the draft."
    }
   }
  },
  "Filter": {
   "id": "Filter",
   "type": "object",
   "description": "Resource definition for Gmail filters. Filters apply to specific messages instead of an entire email thread.",
   "properties": {
    "action": {
     "$ref": "FilterAction",
     "description": "Action that the filter performs."
    },
    "criteria": {
     "$ref": "FilterCriteria",
     "description": "Matching criteria for the filter."
    },
    "id": {
     "type": "string",
     "description": "The server assigned ID of the filter."
    }
   }
  },
  "FilterAction": {
   "id": "FilterAction",
   "type": "object",
   "description": "A set of actions to perform on a message.",
   "properties": {
    "addLabelIds": {
     "type": "array",
     "description": "List of labels to add to the message.",
     "items": {
      "type": "string"
     }
    },
    "forward": {
     "type": "string",
     "description": "Email address that the message should be forwarded to."
    },
    "removeLabelIds": {
     "type": "array",
     "description": "List of labels to remove from the message.",
     "items": {
      "type": "string"
     }
    }
   }
  },
  "FilterCriteria": {
   "id": "FilterCriteria",
   "type": "object",
   "description": "Message matching criteria.",
   "properties": {
    "excludeChats": {
     "type": "boolean",
     "description": "Whether the response should exclude chats."
    },
    "from": {
     "type": "string",
     "description": "The sender's display name or email address."
    },
    "hasAttachment": {
     "type": "boolean",
     "description": "Whether the message has any attachment."
    },
    "negatedQuery": {
     "type": "string",
     "description": "Only return messages not matching the specified query. Supports the same query format as the Gmail search box. For example, \"from:someuser@example.com rfc822msgid: is:unread\"."
    },
    "query": {
     "type": "string",
     "description": "Only return messages matching the specified query. Supports the same query format as the Gmail search box. For example, \"from:someuser@example.com rfc822msgid: is:unread\"."
    },
    "size": {
     "type": "integer",
     "description": "The size of the entire RFC822 message in bytes, including all headers and attachments.",
     "format": "int32"
    },
    "sizeComparison": {
     "type": "string",
     "description": "How the message size in bytes should be in relation to the size field.",
     "enum": [
      "larger",
      "smaller",
      "unspecified"
     ],
     "enumDescriptions": [
      "",
      "",
      ""
     ]
    },
    "subject": {
     "type": "string",
     "description": "Case-insensitive phrase found in the message's subject. Trailing and leading whitespace are be trimmed and adjacent spaces are collapsed."
    },
    "to": {
     "type": "string",
     "description": "The recipient's display name or email address. Includes recipients in the \"to\", \"cc\", and \"bcc\" header fields. You can use simply the local part of the email address. For example, \"example\" and \"example@\" both match \"example@gmail.com\". This field is case-insensitive."
    }
   }
  },
  "ForwardingAddress": {
   "id": "ForwardingAddress",
   "type": "object",
   "description": "Settings for a forwarding address.",
   "properties": {
    "forwardingEmail": {
     "type": "string",
     "description": "An email address to which messages can be forwarded."
    },
    "verificationStatus": {
     "type": "string",
     "description": "Indicates whether this address has been verified and is usable for forwarding. Read-only.",
     "enum": [
      "accepted",
      "pending",
      "verificationStatusUnspecified"
     ],
     "enumDescriptions": [
      "",
      "",
      ""
     ]
    }
   }
  },
  "History": {
   "id": "History",
   "type": "object",
   "description": "A record of a change to the user's mailbox. Each history change may affect multiple messages in multiple ways.",
   "properties": {
    "id": {
     "type": "string",
     "description": "The mailbox sequence ID.",
     "format": "uint64"
    },
    "labelsAdded": {
     "type": "array",
     "description": "Labels added to messages in this history record.",
     "items": {
      "$ref": "HistoryLabelAdded"
     }
    },
    "labelsRemoved": {
     "type": "array",
     "description": "Labels removed from messages in this history record.",
     "items": {
      "$ref": "HistoryLabelRemoved"
     }
    },
    "messages": {
     "type": "array",
     "description": "List of messages changed in this history record. The fields for specific change types, such as messagesAdded may duplicate messages in this field. We recommend using the specific change-type fields instead of this.",
     "items": {
      "$ref": "Message"
     }
    },
    "messagesAdded": {
     "type": "array",
     "description": "Messages added to the mailbox in this history record.",
     "items": {
      "$ref": "HistoryMessageAdded"
     }
    },
    "messagesDeleted": {
     "type": "array",
     "description": "Messages deleted (not Trashed) from the mailbox in this history record.",
     "items": {
      "$ref": "HistoryMessageDeleted"
     }
    }
   }
  },
  "HistoryLabelAdded": {
   "id": "HistoryLabelAdded",
   "type": "object",
   "properties": {
    "labelIds": {
     "type": "array",
     "description": "Label IDs added to the message.",
     "items": {
      "type": "string"
     }
    },
    "message": {
     "$ref": "Message"
    }
   }
  },
  "HistoryLabelRemoved": {
   "id": "HistoryLabelRemoved",
   "type": "object",
   "properties": {
    "labelIds": {
     "type": "array",
     "description": "Label IDs removed from the message.",
     "items": {
      "type": "string"
     }
    },
    "message": {
     "$ref": "Message"
    }
   }
  },
  "HistoryMessageAdded": {
   "id": "HistoryMessageAdded",
   "type": "object",
   "properties": {
    "message": {
     "$ref": "Message"
    }
   }
  },
  "HistoryMessageDeleted": {
   "id": "HistoryMessageDeleted",
   "type": "object",
   "properties": {
    "message": {
     "$ref": "Message"
    }
   }
  },
  "ImapSettings": {
   "id": "ImapSettings",
   "type": "object",
   "description": "IMAP settings for an account.",
   "properties": {
    "autoExpunge": {
     "type": "boolean",
     "description": "If this value is true, Gmail will immediately expunge a message when it is marked as deleted in IMAP. Otherwise, Gmail will wait for an update from the client before expunging messages marked as deleted."
    },
    "enabled": {
     "type": "boolean",
     "description": "Whether IMAP is enabled for the account."
    },
    "expungeBehavior": {
     "type": "string",
     "description": "The action that will be executed on a message when it is marked as deleted and expunged from the last visible IMAP folder.",
     "enum": [
      "archive",
      "deleteForever",
      "expungeBehaviorUnspecified",
      "trash"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      ""
     ]
    },
    "maxFolderSize": {
     "type": "integer",
     "description": "An optional limit on the number of messages that an IMAP folder may contain. Legal values are 0, 1000, 2000, 5000 or 10000. A value of zero is interpreted to mean that there is no limit.",
     "format": "int32"
    }
   }
  },
  "Label": {
   "id": "Label",
   "type": "object",
   "description": "Labels are used to categorize messages and threads within the user's mailbox.",
   "properties": {
    "color": {
     "$ref": "LabelColor",
     "description": "The color to assign to the label. Color is only available for labels that have their type set to user."
    },
    "id": {
     "type": "string",
     "description": "The immutable ID of the label.",
     "annotations": {
      "required": [
       "gmail.users.labels.update"
      ]
     }
    },
    "labelListVisibility": {
     "type": "string",
     "description": "The visibility of the label in the label list in the Gmail web interface.",
     "enum": [
      "labelHide",
      "labelShow",
      "labelShowIfUnread"
     ],
     "enumDescriptions": [
      "",
      "",
      ""
     ],
     "annotations": {
      "required": [
       "gmail.users.labels.create",
       "gmail.users.labels.update"
      ]
     }
    },
    "messageListVisibility": {
     "type": "string",
     "description": "The visibility of the label in the message list in the Gmail web interface.",
     "enum": [
      "hide",
      "show"
     ],
     "enumDescriptions": [
      "",
      ""
     ],
     "annotations": {
      "required": [
       "gmail.users.labels.create",
       "gmail.users.labels.update"
      ]
     }
    },
    "messagesTotal": {
     "type": "integer",
     "description": "The total number of messages with the label.",
     "format": "int32"
    },
    "messagesUnread": {
     "type": "integer",
     "description": "The number of unread messages with the label.",
     "format": "int32"
    },
    "name": {
     "type": "string",
     "description": "The display name of the label.",
     "annotations": {
      "required": [
       "gmail.users.labels.create",
       "gmail.users.labels.update"
      ]
     }
    },
    "threadsTotal": {
     "type": "integer",
     "description": "The total number of threads with the label.",
     "format": "int32"
    },
    "threadsUnread": {
     "type": "integer",
     "description": "The number of unread threads with the label.",
     "format": "int32"
    },
    "type": {
     "type": "string",
     "description": "The owner type for the label. User labels are created by the user and can be modified and deleted by the user and can be applied to any message or thread. System labels are internally created and cannot be added, modified, or deleted. System labels may be able to be applied to or removed from messages and threads under some circumstances but this is not guaranteed. For example, users can apply and remove the INBOX and UNREAD labels from messages and threads, but cannot apply or remove the DRAFTS or SENT labels from messages or threads.",
     "enum": [
      "system",
      "user"
     ],
     "enumDescriptions": [
      "",
      ""
     ]
    }
   }
  },
  "LabelColor": {
   "id": "LabelColor",
   "type": "object",
   "properties": {
    "backgroundColor": {
     "type": "string",
     "description": "The background color represented as hex string #RRGGBB (ex #000000). This field is required in order to set the color of a label. Only the following predefined set of color values are allowed:\n#000000, #434343, #666666, #999999, #cccccc, #efefef, #f3f3f3, #ffffff, #fb4c2f, #ffad47, #fad165, #16a766, #43d692, #4a86e8, #a479e2, #f691b3, #f6c5be, #ffe6c7, #fef1d1, #b9e4d0, #c6f3de, #c9daf8, #e4d7f5, #fcdee8, #efa093, #ffd6a2, #fce8b3, #89d3b2, #a0eac9, #a4c2f4, #d0bcf1, #fbc8d9, #e66550, #ffbc6b, #fcda83, #44b984, #68dfa9, #6d9eeb, #b694e8, #f7a7c0, #cc3a21, #eaa041, #f2c960, #149e60, #3dc789, #3c78d8, #8e63ce, #e07798, #ac2b16, #cf8933, #d5ae49, #0b804b, #2a9c68, #285bac, #653e9b, #b65775, #822111, #a46a21, #aa8831, #076239, #1a764d, #1c4587, #41236d, #83334c"
    },
    "textColor": {
     "type": "string",
     "description": "The text color of the label, represented as hex string. This field is required in order to set the color of a label. Only the following predefined set of color values are allowed:\n#000000, #434343, #666666, #999999, #cccccc, #efefef, #f3f3f3, #ffffff, #fb4c2f, #ffad47, #fad165, #16a766, #43d692, #4a86e8, #a479e2, #f691b3, #f6c5be, #ffe6c7, #fef1d1, #b9e4d0, #c6f3de, #c9daf8, #e4d7f5, #fcdee8, #efa093, #ffd6a2, #fce8b3, #89d3b2, #a0eac9, #a4c2f4, #d0bcf1, #fbc8d9, #e66550, #ffbc6b, #fcda83, #44b984, #68dfa9, #6d9eeb, #b694e8, #f7a7c0, #cc3a21, #eaa041, #f2c960, #149e60, #3dc789, #3c78d8, #8e63ce, #e07798, #ac2b16, #cf8933, #d5ae49, #0b804b, #2a9c68, #285bac, #653e9b, #b65775, #822111, #a46a21, #aa8831, #076239, #1a764d, #1c4587, #41236d, #83334c"
    }
   }
  },
  "ListDelegatesResponse": {
   "id": "ListDelegatesResponse",
   "type": "object",
   "description": "Response for the ListDelegates method.",
   "properties": {
    "delegates": {
     "type": "array",
     "description": "List of the user's delegates (with any verification status).",
     "items": {
      "$ref": "Delegate"
     }
    }
   }
  },
  "ListDraftsResponse": {
   "id": "ListDraftsResponse",
   "type": "object",
   "properties": {
    "drafts": {
     "type": "array",
     "description": "List of drafts.",
     "items": {
      "$ref": "Draft"
     }
    },
    "nextPageToken": {
     "type": "string",
     "description": "Token to retrieve the next page of results in the list."
    },
    "resultSizeEstimate": {
     "type": "integer",
     "description": "Estimated total number of results.",
     "format": "uint32"
    }
   }
  },
  "ListFiltersResponse": {
   "id": "ListFiltersResponse",
   "type": "object",
   "description": "Response for the ListFilters method.",
   "properties": {
    "filter": {
     "type": "array",
     "description": "List of a user's filters.",
     "items": {
      "$ref": "Filter"
     }
    }
   }
  },
  "ListForwardingAddressesResponse": {
   "id": "ListForwardingAddressesResponse",
   "type": "object",
   "description": "Response for the ListForwardingAddresses method.",
   "properties": {
    "forwardingAddresses": {
     "type": "array",
     "description": "List of addresses that may be used for forwarding.",
     "items": {
      "$ref": "ForwardingAddress"
     }
    }
   }
  },
  "ListHistoryResponse": {
   "id": "ListHistoryResponse",
   "type": "object",
   "properties": {
    "history": {
     "type": "array",
     "description": "List of history records. Any messages contained in the response will typically only have id and threadId fields populated.",
     "items": {
      "$ref": "History"
     }
    },
    "historyId": {
     "type": "string",
     "description": "The ID of the mailbox's current history record.",
     "format": "uint64"
    },
    "nextPageToken": {
     "type": "string",
     "description": "Page token to retrieve the next page of results in the list."
    }
   }
  },
  "ListLabelsResponse": {
   "id": "ListLabelsResponse",
   "type": "object",
   "properties": {
    "labels": {
     "type": "array",
     "description": "List of labels.",
     "items": {
      "$ref": "Label"
     }
    }
   }
  },
  "ListMessagesResponse": {
   "id": "ListMessagesResponse",
   "type": "object",
   "properties": {
    "messages": {
     "type": "array",
     "description": "List of messages.",
     "items": {
      "$ref": "Message"
     }
    },
    "nextPageToken": {
     "type": "string",
     "description": "Token to retrieve the next page of results in the list."
    },
    "resultSizeEstimate": {
     "type": "integer",
     "description": "Estimated total number of results.",
     "format": "uint32"
    }
   }
  },
  "ListSendAsResponse": {
   "id": "ListSendAsResponse",
   "type": "object",
   "description": "Response for the ListSendAs method.",
   "properties": {
    "sendAs": {
     "type": "array",
     "description": "List of send-as aliases.",
     "items": {
      "$ref": "SendAs"
     }
    }
   }
  },
  "ListSmimeInfoResponse": {
   "id": "ListSmimeInfoResponse",
   "type": "object",
   "properties": {
    "smimeInfo": {
     "type": "array",
     "description": "List of SmimeInfo.",
     "items": {
      "$ref": "SmimeInfo"
     }
    }
   }
  },
  "ListThreadsResponse": {
   "id": "ListThreadsResponse",
   "type": "object",
   "properties": {
    "nextPageToken": {
     "type": "string",
     "description": "Page token to retrieve the next page of results in the list."
    },
    "resultSizeEstimate": {
     "type": "integer",
     "description": "Estimated total number of results.",
     "format": "uint32"
    },
    "threads": {
     "type": "array",
     "description": "List of threads.",
     "items": {
      "$ref": "Thread"
     }
    }
   }
  },
  "Message": {
   "id": "Message",
   "type": "object",
   "description": "An email message.",
   "properties": {
    "historyId": {
     "type": "string",
     "description": "The ID of the last history record that modified this message.",
     "format": "uint64"
    },
    "id": {
     "type": "string",
     "description": "The immutable ID of the message."
    },
    "internalDate": {
     "type": "string",
     "description": "The internal message creation timestamp (epoch ms), which determines ordering in the inbox. For normal SMTP-received email, this represents the time the message was originally accepted by Google, which is more reliable than the Date header. However, for API-migrated mail, it can be configured by client to be based on the Date header.",
     "format": "int64"
    },
    "labelIds": {
     "type": "array",
     "description": "List of IDs of labels applied to this message.",
     "items": {
      "type": "string"
     }
    },
    "payload": {
     "$ref": "MessagePart",
     "description": "The parsed email structure in the message parts."
    },
    "raw": {
     "type": "string",
     "description": "The entire email message in an RFC 2822 formatted and base64url encoded string. Returned in messages.get and drafts.get responses when the format=RAW parameter is supplied.",
     "format": "byte",
     "annotations": {
      "required": [
       "gmail.users.drafts.create",
       "gmail.users.drafts.update",
       "gmail.users.messages.insert",
       "gmail.users.messages.send"
      ]
     }
    },
    "sizeEstimate": {
     "type": "integer",
     "description": "Estimated size in bytes of the message.",
     "format": "int32"
    },
    "snippet": {
     "type": "string",
     "description": "A short part of the message text."
    },
    "threadId": {
     "type": "string",
     "description": "The ID of the thread the message belongs to. To add a message or draft to a thread, the following criteria must be met: \n- The requested threadId must be specified on the Message or Draft.Message you supply with your request. \n- The References and In-Reply-To headers must be set in compliance with the RFC 2822 standard. \n- The Subject headers must match."
    }
   }
  },
  "MessagePart": {
   "id": "MessagePart",
   "type": "object",
   "description": "A single MIME message part.",
   "properties": {
    "body": {
     "$ref": "MessagePartBody",
     "description": "The message part body for this part, which may be empty for container MIME message parts."
    },
    "filename": {
     "type": "string",
     "description": "The filename of the attachment. Only present if this message part represents an attachment."
    },
    "headers": {
     "type": "array",
     "description": "List of headers on this message part. For the top-level message part, representing the entire message payload, it will contain the standard RFC 2822 email headers such as To, From, and Subject.",
     "items": {
      "$ref": "MessagePartHeader"
     }
    },
    "mimeType": {
     "type": "string",
     "description": "The MIME type of the message part."
    },
    "partId": {
     "type": "string",
     "description": "The immutable ID of the message part."
    },
    "parts": {
     "type": "array",
     "description": "The child MIME message parts of this part. This only applies to container MIME message parts, for example multipart/*. For non- container MIME message part types, such as text/plain, this field is empty. For more information, see RFC 1521.",
     "items": {
      "$ref": "MessagePart"
     }
    }
   }
  },
  "MessagePartBody": {
   "id": "MessagePartBody",
   "type": "object",
   "description": "The body of a single MIME message part.",
   "properties": {
    "attachmentId": {
     "type": "string",
     "description": "When present, contains the ID of an external attachment that can be retrieved in a separate messages.attachments.get request. When not present, the entire content of the message part body is contained in the data field."
    },
    "data": {
     "type": "string",
     "description": "The body data of a MIME message part as a base64url encoded string. May be empty for MIME container types that have no message body or when the body data is sent as a separate attachment. An attachment ID is present if the body data is contained in a separate attachment.",
     "format": "byte"
    },
    "size": {
     "type": "integer",
     "description": "Number of bytes for the message part data (encoding notwithstanding).",
     "format": "int32"
    }
   }
  },
  "MessagePartHeader": {
   "id": "MessagePartHeader",
   "type": "object",
   "properties": {
    "name": {
     "type": "string",
     "description": "The name of the header before the : separator. For example, To."
    },
    "value": {
     "type": "string",
     "description": "The value of the header after the : separator. For example, someuser@example.com."
    }
   }
  },
  "ModifyMessageRequest": {
   "id": "ModifyMessageRequest",
   "type": "object",
   "properties": {
    "addLabelIds": {
     "type": "array",
     "description": "A list of IDs of labels to add to this message.",
     "items": {
      "type": "string"
     }
    },
    "removeLabelIds": {
     "type": "array",
     "description": "A list IDs of labels to remove from this message.",
     "items": {
      "type": "string"
     }
    }
   }
  },
  "ModifyThreadRequest": {
   "id": "ModifyThreadRequest",
   "type": "object",
   "properties": {
    "addLabelIds": {
     "type": "array",
     "description": "A list of IDs of labels to add to this thread.",
     "items": {
      "type": "string"
     }
    },
    "removeLabelIds": {
     "type": "array",
     "description": "A list of IDs of labels to remove from this thread.",
     "items": {
      "type": "string"
     }
    }
   }
  },
  "PopSettings": {
   "id": "PopSettings",
   "type": "object",
   "description": "POP settings for an account.",
   "properties": {
    "accessWindow": {
     "type": "string",
     "description": "The range of messages which are accessible via POP.",
     "enum": [
      "accessWindowUnspecified",
      "allMail",
      "disabled",
      "fromNowOn"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      ""
     ]
    },
    "disposition": {
     "type": "string",
     "description": "The action that will be executed on a message after it has been fetched via POP.",
     "enum": [
      "archive",
      "dispositionUnspecified",
      "leaveInInbox",
      "markRead",
      "trash"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      "",
      ""
     ]
    }
   }
  },
  "Profile": {
   "id": "Profile",
   "type": "object",
   "description": "Profile for a Gmail user.",
   "properties": {
    "emailAddress": {
     "type": "string",
     "description": "The user's email address."
    },
    "historyId": {
     "type": "string",
     "description": "The ID of the mailbox's current history record.",
     "format": "uint64"
    },
    "messagesTotal": {
     "type": "integer",
     "description": "The total number of messages in the mailbox.",
     "format": "int32"
    },
    "threadsTotal": {
     "type": "integer",
     "description": "The total number of threads in the mailbox.",
     "format": "int32"
    }
   }
  },
  "SendAs": {
   "id": "SendAs",
   "type": "object",
   "description": "Settings associated with a send-as alias, which can be either the primary login address associated with the account or a custom \"from\" address. Send-as aliases correspond to the \"Send Mail As\" feature in the web interface.",
   "properties": {
    "displayName": {
     "type": "string",
     "description": "A name that appears in the \"From:\" header for mail sent using this alias. For custom \"from\" addresses, when this is empty, Gmail will populate the \"From:\" header with the name that is used for the primary address associated with the account. If the admin has disabled the ability for users to update their name format, requests to update this field for the primary login will silently fail."
    },
    "isDefault": {
     "type": "boolean",
     "description": "Whether this address is selected as the default \"From:\" address in situations such as composing a new message or sending a vacation auto-reply. Every Gmail account has exactly one default send-as address, so the only legal value that clients may write to this field is true. Changing this from false to true for an address will result in this field becoming false for the other previous default address."
    },
    "isPrimary": {
     "type": "boolean",
     "description": "Whether this address is the primary address used to login to the account. Every Gmail account has exactly one primary address, and it cannot be deleted from the collection of send-as aliases. This field is read-only."
    },
    "replyToAddress": {
     "type": "string",
     "description": "An optional email address that is included in a \"Reply-To:\" header for mail sent using this alias. If this is empty, Gmail will not generate a \"Reply-To:\" header."
    },
    "sendAsEmail": {
     "type": "string",
     "description": "The email address that appears in the \"From:\" header for mail sent using this alias. This is read-only for all operations except create."
    },
    "signature": {
     "type": "string",
     "description": "An optional HTML signature that is included in messages composed with this alias in the Gmail web UI."
    },
    "smtpMsa": {
     "$ref": "SmtpMsa",
     "description": "An optional SMTP service that will be used as an outbound relay for mail sent using this alias. If this is empty, outbound mail will be sent directly from Gmail's servers to the destination SMTP service. This setting only applies to custom \"from\" aliases."
    },
    "treatAsAlias": {
     "type": "boolean",
     "description": "Whether Gmail should  treat this address as an alias for the user's primary email address. This setting only applies to custom \"from\" aliases."
    },
    "verificationStatus": {
     "type": "string",
     "description": "Indicates whether this address has been verified for use as a send-as alias. Read-only. This setting only applies to custom \"from\" aliases.",
     "enum": [
      "accepted",
      "pending",
      "verificationStatusUnspecified"
     ],
     "enumDescriptions": [
      "",
      "",
      ""
     ]
    }
   }
  },
  "SmimeInfo": {
   "id": "SmimeInfo",
   "type": "object",
   "description": "An S/MIME email config.",
   "properties": {
    "encryptedKeyPassword": {
     "type": "string",
     "description": "Encrypted key password, when key is encrypted."
    },
    "expiration": {
     "type": "string",
     "description": "When the certificate expires (in milliseconds since epoch).",
     "format": "int64"
    },
    "id": {
     "type": "string",
     "description": "The immutable ID for the SmimeInfo."
    },
    "isDefault": {
     "type": "boolean",
     "description": "Whether this SmimeInfo is the default one for this user's send-as address."
    },
    "issuerCn": {
     "type": "string",
     "description": "The S/MIME certificate issuer's common name."
    },
    "pem": {
     "type": "string",
     "description": "PEM formatted X509 concatenated certificate string (standard base64 encoding). Format used for returning key, which includes public key as well as certificate chain (not private key)."
    },
    "pkcs12": {
     "type": "string",
     "description": "PKCS#12 format containing a single private/public key pair and certificate chain. This format is only accepted from client for creating a new SmimeInfo and is never returned, because the private key is not intended to be exported. PKCS#12 may be encrypted, in which case encryptedKeyPassword should be set appropriately.",
     "format": "byte"
    }
   }
  },
  "SmtpMsa": {
   "id": "SmtpMsa",
   "type": "object",
   "description": "Configuration for communication with an SMTP service.",
   "properties": {
    "host": {
     "type": "string",
     "description": "The hostname of the SMTP service. Required."
    },
    "password": {
     "type": "string",
     "description": "The password that will be used for authentication with the SMTP service. This is a write-only field that can be specified in requests to create or update SendAs settings; it is never populated in responses."
    },
    "port": {
     "type": "integer",
     "description": "The port of the SMTP service. Required.",
     "format": "int32"
    },
    "securityMode": {
     "type": "string",
     "description": "The protocol that will be used to secure communication with the SMTP service. Required.",
     "enum": [
      "none",
      "securityModeUnspecified",
      "ssl",
      "starttls"
     ],
     "enumDescriptions": [
      "",
      "",
      "",
      ""
     ]
    },
    "username": {
     "type": "string",
     "description": "The username that will be used for authentication with the SMTP service. This is a write-only field that can be specified in requests to create or update SendAs settings; it is never populated in responses."
    }
   }
  },
  "Thread": {
   "id": "Thread",
   "type": "object",
   "description": "A collection of messages representing a conversation.",
   "properties": {
    "historyId": {
     "type": "string",
     "description": "The ID of the last history record that modified this thread.",
     "format": "uint64"
    },
    "id": {
     "type": "string",
     "description": "The unique ID of the thread."
    },
    "messages": {
     "type": "array",
     "description": "The list of messages in the thread.",
     "items": {
      "$ref": "Message"
     }
    },
    "snippet": {
     "type": "string",
     "description": "A short part of the message text."
    }
   }
  },
  "VacationSettings": {
   "id": "VacationSettings",
   "type": "object",
   "description": "Vacation auto-reply settings for an account. These settings correspond to the \"Vacation responder\" feature in the web interface.",
   "properties": {
    "enableAutoReply": {
     "type": "boolean",
     "description": "Flag that controls whether Gmail automatically replies to messages."
    },
    "endTime": {
     "type": "string",
     "description": "An optional end time for sending auto-replies (epoch ms). When this is specified, Gmail will automatically reply only to messages that it receives before the end time. If both startTime and endTime are specified, startTime must precede endTime.",
     "format": "int64"
    },
    "responseBodyHtml": {
     "type": "string",
     "description": "Response body in HTML format. Gmail will sanitize the HTML before storing it."
    },
    "responseBodyPlainText": {
     "type": "string",
     "description": "Response body in plain text format."
    },
    "responseSubject": {
     "type": "string",
     "description": "Optional text to prepend to the subject line in vacation responses. In order to enable auto-replies, either the response subject or the response body must be nonempty."
    },
    "restrictToContacts": {
     "type": "boolean",
     "description": "Flag that determines whether responses are sent to recipients who are not in the user's list of contacts."
    },
    "restrictToDomain": {
     "type": "boolean",
     "description": "Flag that determines whether responses are sent to recipients who are outside of the user's domain. This feature is only available for G Suite users."
    },
    "startTime": {
     "type": "string",
     "description": "An optional start time for sending auto-replies (epoch ms). When this is specified, Gmail will automatically reply only to messages that it receives after the start time. If both startTime and endTime are specified, startTime must precede endTime.",
     "format": "int64"
    }
   }
  },
  "WatchRequest": {
   "id": "WatchRequest",
   "type": "object",
   "description": "Set up or update a new push notification watch on this user's mailbox.",
   "properties": {
    "labelFilterAction": {
     "type": "string",
     "description": "Filtering behavior of labelIds list specified.",
     "enum": [
      "exclude",
      "include"
     ],
     "enumDescriptions": [
      "",
      ""
     ]
    },
    "labelIds": {
     "type": "array",
     "description": "List of label_ids to restrict notifications about. By default, if unspecified, all changes are pushed out. If specified then dictates which labels are required for a push notification to be generated.",
     "items": {
      "type": "string"
     }
    },
    "topicName": {
     "type": "string",
     "description": "A fully qualified Google Cloud Pub/Sub API topic name to publish the events to. This topic name **must** already exist in Cloud Pub/Sub and you **must** have already granted gmail \"publish\" permission on it. For example, \"projects/my-project-identifier/topics/my-topic-name\" (using the Cloud Pub/Sub \"v1\" topic naming format).\n\nNote that the \"my-project-identifier\" portion must exactly match your Google developer project id (the one executing this watch request)."
    }
   }
  },
  "WatchResponse": {
   "id": "WatchResponse",
   "type": "object",
   "description": "Push notification watch response.",
   "properties": {
    "expiration": {
     "type": "string",
     "description": "When Gmail will stop sending notifications for mailbox updates (epoch millis). Call watch again before this time to renew the watch.",
     "format": "int64"
    },
    "historyId": {
     "type": "string",
     "description": "The ID of the mailbox's current history record.",
     "format": "uint64"
    }
   }
  }
 },
 "resources": {
  "users": {
   "methods": {
    "getProfile": {
     "id": "gmail.users.getProfile",
     "path": "{userId}/profile",
     "httpMethod": "GET",
     "description": "Gets the current user's Gmail profile.",
     "parameters": {
      "userId": {
       "type": "string",
       "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
       "default": "me",
       "required": true,
       "location": "path"
      }
     },
     "parameterOrder": [
      "userId"
     ],
     "response": {
      "$ref": "Profile"
     },
     "scopes": [
      "https://mail.google.com/",
      "https://www.googleapis.com/auth/gmail.compose",
      "https://www.googleapis.com/auth/gmail.metadata",
      "https://www.googleapis.com/auth/gmail.modify",
      "https://www.googleapis.com/auth/gmail.readonly"
     ]
    },
    "stop": {
     "id": "gmail.users.stop",
     "path": "{userId}/stop",
     "httpMethod": "POST",
     "description": "Stop receiving push notifications for the given user mailbox.",
     "parameters": {
      "userId": {
       "type": "string",
       "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
       "default": "me",
       "required": true,
       "location": "path"
      }
     },
     "parameterOrder": [
      "userId"
     ],
     "scopes": [
      "https://mail.google.com/",
      "https://www.googleapis.com/auth/gmail.metadata",
      "https://www.googleapis.com/auth/gmail.modify",
      "https://www.googleapis.com/auth/gmail.readonly"
     ]
    },
    "watch": {
     "id": "gmail.users.watch",
     "path": "{userId}/watch",
     "httpMethod": "POST",
     "description": "Set up or update a push notification watch on the given user mailbox.",
     "parameters": {
      "userId": {
       "type": "string",
       "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
       "default": "me",
       "required": true,
       "location": "path"
      }
     },
     "parameterOrder": [
      "userId"
     ],
     "request": {
      "$ref": "WatchRequest"
     },
     "response": {
      "$ref": "WatchResponse"
     },
     "scopes": [
      "https://mail.google.com/",
      "https://www.googleapis.com/auth/gmail.metadata",
      "https://www.googleapis.com/auth/gmail.modify",
      "https://www.googleapis.com/auth/gmail.readonly"
     ]
    }
   },
   "resources": {
    "drafts": {
     "methods": {
      "create": {
       "id": "gmail.users.drafts.create",
       "path": "{userId}/drafts",
       "httpMethod": "POST",
       "description": "Creates a new draft with the DRAFT label.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Draft"
       },
       "response": {
        "$ref": "Draft"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "35MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/drafts"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/drafts"
         }
        }
       }
      },
      "delete": {
       "id": "gmail.users.drafts.delete",
       "path": "{userId}/drafts/{id}",
       "httpMethod": "DELETE",
       "description": "Immediately and permanently deletes the specified draft. Does not simply trash it.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the draft to delete.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "get": {
       "id": "gmail.users.drafts.get",
       "path": "{userId}/drafts/{id}",
       "httpMethod": "GET",
       "description": "Gets the specified draft.",
       "parameters": {
        "format": {
         "type": "string",
         "description": "The format to return the draft in.",
         "default": "full",
         "enum": [
          "full",
          "metadata",
          "minimal",
          "raw"
         ],
         "enumDescriptions": [
          "",
          "",
          "",
          ""
         ],
         "location": "query"
        },
        "id": {
         "type": "string",
         "description": "The ID of the draft to retrieve.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Draft"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "list": {
       "id": "gmail.users.drafts.list",
       "path": "{userId}/drafts",
       "httpMethod": "GET",
       "description": "Lists the drafts in the user's mailbox.",
       "parameters": {
        "includeSpamTrash": {
         "type": "boolean",
         "description": "Include drafts from SPAM and TRASH in the results.",
         "default": "false",
         "location": "query"
        },
        "maxResults": {
         "type": "integer",
         "description": "Maximum number of drafts to return.",
         "default": "100",
         "format": "uint32",
         "location": "query"
        },
        "pageToken": {
         "type": "string",
         "description": "Page token to retrieve a specific page of results in the list.",
         "location": "query"
        },
        "q": {
         "type": "string",
         "description": "Only return draft messages matching the specified query. Supports the same query format as the Gmail search box. For example, \"from:someuser@example.com rfc822msgid: is:unread\".",
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ListDraftsResponse"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "send": {
       "id": "gmail.users.drafts.send",
       "path": "{userId}/drafts/send",
       "httpMethod": "POST",
       "description": "Sends the specified, existing draft to the recipients in the To, Cc, and Bcc headers.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Draft"
       },
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "35MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/drafts/send"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/drafts/send"
         }
        }
       }
      },
      "update": {
       "id": "gmail.users.drafts.update",
       "path": "{userId}/drafts/{id}",
       "httpMethod": "PUT",
       "description": "Replaces a draft's content.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the draft to update.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "request": {
        "$ref": "Draft"
       },
       "response": {
        "$ref": "Draft"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "35MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/drafts/{id}"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/drafts/{id}"
         }
        }
       }
      }
     }
    },
    "history": {
     "methods": {
      "list": {
       "id": "gmail.users.history.list",
       "path": "{userId}/history",
       "httpMethod": "GET",
       "description": "Lists the history of all changes to the given mailbox. History results are returned in chronological order (increasing historyId).",
       "parameters": {
        "historyTypes": {
         "type": "string",
         "description": "History types to be returned by the function",
         "enum": [
          "labelAdded",
          "labelRemoved",
          "messageAdded",
          "messageDeleted"
         ],
         "enumDescriptions": [
          "",
          "",
          "",
          ""
         ],
         "repeated": true,
         "location": "query"
        },
        "labelId": {
         "type": "string",
         "description": "Only return messages with a label matching the ID.",
         "location": "query"
        },
        "maxResults": {
         "type": "integer",
         "description": "The maximum number of history records to return.",
         "default": "100",
         "format": "uint32",
         "location": "query"
        },
        "pageToken": {
         "type": "string",
         "description": "Page token to retrieve a specific page of results in the list.",
         "location": "query"
        },
        "startHistoryId": {
         "type": "string",
         "description": "Required. Returns history records after the specified startHistoryId. The supplied startHistoryId should be obtained from the historyId of a message, thread, or previous list response. History IDs increase chronologically but are not contiguous with random gaps in between valid IDs. Supplying an invalid or out of date startHistoryId typically returns an HTTP 404 error code. A historyId is typically valid for at least a week, but in some rare circumstances may be valid for only a few hours. If you receive an HTTP 404 error response, your application should perform a full sync. If you receive no nextPageToken in the response, there are no updates to retrieve and you can store the returned historyId for a future request.",
         "format": "uint64",
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ListHistoryResponse"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      }
     }
    },
    "labels": {
     "methods": {
      "create": {
       "id": "gmail.users.labels.create",
       "path": "{userId}/labels",
       "httpMethod": "POST",
       "description": "Creates a new label.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Label"
       },
       "response": {
        "$ref": "Label"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "delete": {
       "id": "gmail.users.labels.delete",
       "path": "{userId}/labels/{id}",
       "httpMethod": "DELETE",
       "description": "Immediately and permanently deletes the specified label and removes it from any messages and threads that it is applied to.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the label to delete.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "get": {
       "id": "gmail.users.labels.get",
       "path": "{userId}/labels/{id}",
       "httpMethod": "GET",
       "description": "Gets the specified label.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the label to retrieve.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Label"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "list": {
       "id": "gmail.users.labels.list",
       "path": "{userId}/labels",
       "httpMethod": "GET",
       "description": "Lists all labels in the user's mailbox.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ListLabelsResponse"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "patch": {
       "id": "gmail.users.labels.patch",
       "path": "{userId}/labels/{id}",
       "httpMethod": "PATCH",
       "description": "Updates the specified label. This method supports patch semantics.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the label to update.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "request": {
        "$ref": "Label"
       },
       "response": {
        "$ref": "Label"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "update": {
       "id": "gmail.users.labels.update",
       "path": "{userId}/labels/{id}",
       "httpMethod": "PUT",
       "description": "Updates the specified label.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the label to update.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "request": {
        "$ref": "Label"
       },
       "response": {
        "$ref": "Label"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.labels",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      }
     }
    },
    "messages": {
     "methods": {
      "batchDelete": {
       "id": "gmail.users.messages.batchDelete",
       "path": "{userId}/messages/batchDelete",
       "httpMethod": "POST",
       "description": "Deletes many messages by message ID. Provides no guarantees that messages were not already deleted or even existed at all.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "BatchDeleteMessagesRequest"
       },
       "scopes": [
        "https://mail.google.com/"
       ]
      },
      "batchModify": {
       "id": "gmail.users.messages.batchModify",
       "path": "{userId}/messages/batchModify",
       "httpMethod": "POST",
       "description": "Modifies the labels on the specified messages.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "BatchModifyMessagesRequest"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "delete": {
       "id": "gmail.users.messages.delete",
       "path": "{userId}/messages/{id}",
       "httpMethod": "DELETE",
       "description": "Immediately and permanently deletes the specified message. This operation cannot be undone. Prefer messages.trash instead.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the message to delete.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "scopes": [
        "https://mail.google.com/"
       ]
      },
      "get": {
       "id": "gmail.users.messages.get",
       "path": "{userId}/messages/{id}",
       "httpMethod": "GET",
       "description": "Gets the specified message.",
       "parameters": {
        "format": {
         "type": "string",
         "description": "The format to return the message in.",
         "default": "full",
         "enum": [
          "full",
          "metadata",
          "minimal",
          "raw"
         ],
         "enumDescriptions": [
          "",
          "",
          "",
          ""
         ],
         "location": "query"
        },
        "id": {
         "type": "string",
         "description": "The ID of the message to retrieve.",
         "required": true,
         "location": "path"
        },
        "metadataHeaders": {
         "type": "string",
         "description": "When given and format is METADATA, only include headers specified.",
         "repeated": true,
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "import": {
       "id": "gmail.users.messages.import",
       "path": "{userId}/messages/import",
       "httpMethod": "POST",
       "description": "Imports a message into only this user's mailbox, with standard email delivery scanning and classification similar to receiving via SMTP. Does not send a message.",
       "parameters": {
        "deleted": {
         "type": "boolean",
         "description": "Mark the email as permanently deleted (not TRASH) and only visible in Google Vault to a Vault administrator. Only used for G Suite accounts.",
         "default": "false",
         "location": "query"
        },
        "internalDateSource": {
         "type": "string",
         "description": "Source for Gmail's internal date of the message.",
         "default": "dateHeader",
         "enum": [
          "dateHeader",
          "receivedTime"
         ],
         "enumDescriptions": [
          "",
          ""
         ],
         "location": "query"
        },
        "neverMarkSpam": {
         "type": "boolean",
         "description": "Ignore the Gmail spam classifier decision and never mark this email as SPAM in the mailbox.",
         "default": "false",
         "location": "query"
        },
        "processForCalendar": {
         "type": "boolean",
         "description": "Process calendar invites in the email and add any extracted meetings to the Google Calendar for this user.",
         "default": "false",
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Message"
       },
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.insert",
        "https://www.googleapis.com/auth/gmail.modify"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "50MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/messages/import"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/messages/import"
         }
        }
       }
      },
      "insert": {
       "id": "gmail.users.messages.insert",
       "path": "{userId}/messages",
       "httpMethod": "POST",
       "description": "Directly inserts a message into only this user's mailbox similar to IMAP APPEND, bypassing most scanning and classification. Does not send a message.",
       "parameters": {
        "deleted": {
         "type": "boolean",
         "description": "Mark the email as permanently deleted (not TRASH) and only visible in Google Vault to a Vault administrator. Only used for G Suite accounts.",
         "default": "false",
         "location": "query"
        },
        "internalDateSource": {
         "type": "string",
         "description": "Source for Gmail's internal date of the message.",
         "default": "receivedTime",
         "enum": [
          "dateHeader",
          "receivedTime"
         ],
         "enumDescriptions": [
          "",
          ""
         ],
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Message"
       },
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.insert",
        "https://www.googleapis.com/auth/gmail.modify"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "50MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/messages"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/messages"
         }
        }
       }
      },
      "list": {
       "id": "gmail.users.messages.list",
       "path": "{userId}/messages",
       "httpMethod": "GET",
       "description": "Lists the messages in the user's mailbox.",
       "parameters": {
        "includeSpamTrash": {
         "type": "boolean",
         "description": "Include messages from SPAM and TRASH in the results.",
         "default": "false",
         "location": "query"
        },
        "labelIds": {
         "type": "string",
         "description": "Only return messages with labels that match all of the specified label IDs.",
         "repeated": true,
         "location": "query"
        },
        "maxResults": {
         "type": "integer",
         "description": "Maximum number of messages to return.",
         "default": "100",
         "format": "uint32",
         "location": "query"
        },
        "pageToken": {
         "type": "string",
         "description": "Page token to retrieve a specific page of results in the list.",
         "location": "query"
        },
        "q": {
         "type": "string",
         "description": "Only return messages matching the specified query. Supports the same query format as the Gmail search box. For example, \"from:someuser@example.com rfc822msgid:\u003csomemsgid@example.com\u003e is:unread\". Parameter cannot be used when accessing the api using the gmail.metadata scope.",
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ListMessagesResponse"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "modify": {
       "id": "gmail.users.messages.modify",
       "path": "{userId}/messages/{id}/modify",
       "httpMethod": "POST",
       "description": "Modifies the labels on the specified message.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the message to modify.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "request": {
        "$ref": "ModifyMessageRequest"
       },
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "send": {
       "id": "gmail.users.messages.send",
       "path": "{userId}/messages/send",
       "httpMethod": "POST",
       "description": "Sends the specified message to the recipients in the To, Cc, and Bcc headers.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "Message"
       },
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.compose",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.send"
       ],
       "supportsMediaUpload": true,
       "mediaUpload": {
        "accept": [
         "message/rfc822"
        ],
        "maxSize": "35MB",
        "protocols": {
         "simple": {
          "multipart": true,
          "path": "/upload/gmail/v1/users/{userId}/messages/send"
         },
         "resumable": {
          "multipart": true,
          "path": "/resumable/upload/gmail/v1/users/{userId}/messages/send"
         }
        }
       }
      },
      "trash": {
       "id": "gmail.users.messages.trash",
       "path": "{userId}/messages/{id}/trash",
       "httpMethod": "POST",
       "description": "Moves the specified message to the trash.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the message to Trash.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "untrash": {
       "id": "gmail.users.messages.untrash",
       "path": "{userId}/messages/{id}/untrash",
       "httpMethod": "POST",
       "description": "Removes the specified message from the trash.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the message to remove from Trash.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Message"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      }
     },
     "resources": {
      "attachments": {
       "methods": {
        "get": {
         "id": "gmail.users.messages.attachments.get",
         "path": "{userId}/messages/{messageId}/attachments/{id}",
         "httpMethod": "GET",
         "description": "Gets the specified message attachment.",
         "parameters": {
          "id": {
           "type": "string",
           "description": "The ID of the attachment.",
           "required": true,
           "location": "path"
          },
          "messageId": {
           "type": "string",
           "description": "The ID of the message containing the attachment.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "messageId",
          "id"
         ],
         "response": {
          "$ref": "MessagePartBody"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly"
         ]
        }
       }
      }
     }
    },
    "settings": {
     "methods": {
      "getAutoForwarding": {
       "id": "gmail.users.settings.getAutoForwarding",
       "path": "{userId}/settings/autoForwarding",
       "httpMethod": "GET",
       "description": "Gets the auto-forwarding setting for the specified account.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "AutoForwarding"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "getImap": {
       "id": "gmail.users.settings.getImap",
       "path": "{userId}/settings/imap",
       "httpMethod": "GET",
       "description": "Gets IMAP settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ImapSettings"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "getPop": {
       "id": "gmail.users.settings.getPop",
       "path": "{userId}/settings/pop",
       "httpMethod": "GET",
       "description": "Gets POP settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "PopSettings"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "getVacation": {
       "id": "gmail.users.settings.getVacation",
       "path": "{userId}/settings/vacation",
       "httpMethod": "GET",
       "description": "Gets vacation responder settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "VacationSettings"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "updateAutoForwarding": {
       "id": "gmail.users.settings.updateAutoForwarding",
       "path": "{userId}/settings/autoForwarding",
       "httpMethod": "PUT",
       "description": "Updates the auto-forwarding setting for the specified account. A verified forwarding address must be specified when auto-forwarding is enabled.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "AutoForwarding"
       },
       "response": {
        "$ref": "AutoForwarding"
       },
       "scopes": [
        "https://www.googleapis.com/auth/gmail.settings.sharing"
       ]
      },
      "updateImap": {
       "id": "gmail.users.settings.updateImap",
       "path": "{userId}/settings/imap",
       "httpMethod": "PUT",
       "description": "Updates IMAP settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "ImapSettings"
       },
       "response": {
        "$ref": "ImapSettings"
       },
       "scopes": [
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "updatePop": {
       "id": "gmail.users.settings.updatePop",
       "path": "{userId}/settings/pop",
       "httpMethod": "PUT",
       "description": "Updates POP settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "PopSettings"
       },
       "response": {
        "$ref": "PopSettings"
       },
       "scopes": [
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      },
      "updateVacation": {
       "id": "gmail.users.settings.updateVacation",
       "path": "{userId}/settings/vacation",
       "httpMethod": "PUT",
       "description": "Updates vacation responder settings.",
       "parameters": {
        "userId": {
         "type": "string",
         "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "request": {
        "$ref": "VacationSettings"
       },
       "response": {
        "$ref": "VacationSettings"
       },
       "scopes": [
        "https://www.googleapis.com/auth/gmail.settings.basic"
       ]
      }
     },
     "resources": {
      "delegates": {
       "methods": {
        "create": {
         "id": "gmail.users.settings.delegates.create",
         "path": "{userId}/settings/delegates",
         "httpMethod": "POST",
         "description": "Adds a delegate with its verification status set directly to accepted, without sending any verification email. The delegate user must be a member of the same G Suite organization as the delegator user.\n\nGmail imposes limtations on the number of delegates and delegators each user in a G Suite organization can have. These limits depend on your organization, but in general each user can have up to 25 delegates and up to 10 delegators.\n\nNote that a delegate user must be referred to by their primary email address, and not an email alias.\n\nAlso note that when a new delegate is created, there may be up to a one minute delay before the new delegate is available for use.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "request": {
          "$ref": "Delegate"
         },
         "response": {
          "$ref": "Delegate"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "delete": {
         "id": "gmail.users.settings.delegates.delete",
         "path": "{userId}/settings/delegates/{delegateEmail}",
         "httpMethod": "DELETE",
         "description": "Removes the specified delegate (which can be of any verification status), and revokes any verification that may have been required for using it.\n\nNote that a delegate user must be referred to by their primary email address, and not an email alias.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "delegateEmail": {
           "type": "string",
           "description": "The email address of the user to be removed as a delegate.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "delegateEmail"
         ],
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "get": {
         "id": "gmail.users.settings.delegates.get",
         "path": "{userId}/settings/delegates/{delegateEmail}",
         "httpMethod": "GET",
         "description": "Gets the specified delegate.\n\nNote that a delegate user must be referred to by their primary email address, and not an email alias.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "delegateEmail": {
           "type": "string",
           "description": "The email address of the user whose delegate relationship is to be retrieved.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "delegateEmail"
         ],
         "response": {
          "$ref": "Delegate"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "list": {
         "id": "gmail.users.settings.delegates.list",
         "path": "{userId}/settings/delegates",
         "httpMethod": "GET",
         "description": "Lists the delegates for the specified account.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "response": {
          "$ref": "ListDelegatesResponse"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        }
       }
      },
      "filters": {
       "methods": {
        "create": {
         "id": "gmail.users.settings.filters.create",
         "path": "{userId}/settings/filters",
         "httpMethod": "POST",
         "description": "Creates a filter.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "request": {
          "$ref": "Filter"
         },
         "response": {
          "$ref": "Filter"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "delete": {
         "id": "gmail.users.settings.filters.delete",
         "path": "{userId}/settings/filters/{id}",
         "httpMethod": "DELETE",
         "description": "Deletes a filter.",
         "parameters": {
          "id": {
           "type": "string",
           "description": "The ID of the filter to be deleted.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "id"
         ],
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "get": {
         "id": "gmail.users.settings.filters.get",
         "path": "{userId}/settings/filters/{id}",
         "httpMethod": "GET",
         "description": "Gets a filter.",
         "parameters": {
          "id": {
           "type": "string",
           "description": "The ID of the filter to be fetched.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "id"
         ],
         "response": {
          "$ref": "Filter"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "list": {
         "id": "gmail.users.settings.filters.list",
         "path": "{userId}/settings/filters",
         "httpMethod": "GET",
         "description": "Lists the message filters of a Gmail user.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "response": {
          "$ref": "ListFiltersResponse"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        }
       }
      },
      "forwardingAddresses": {
       "methods": {
        "create": {
         "id": "gmail.users.settings.forwardingAddresses.create",
         "path": "{userId}/settings/forwardingAddresses",
         "httpMethod": "POST",
         "description": "Creates a forwarding address. If ownership verification is required, a message will be sent to the recipient and the resource's verification status will be set to pending; otherwise, the resource will be created with verification status set to accepted.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "request": {
          "$ref": "ForwardingAddress"
         },
         "response": {
          "$ref": "ForwardingAddress"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "delete": {
         "id": "gmail.users.settings.forwardingAddresses.delete",
         "path": "{userId}/settings/forwardingAddresses/{forwardingEmail}",
         "httpMethod": "DELETE",
         "description": "Deletes the specified forwarding address and revokes any verification that may have been required.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "forwardingEmail": {
           "type": "string",
           "description": "The forwarding address to be deleted.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "forwardingEmail"
         ],
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "get": {
         "id": "gmail.users.settings.forwardingAddresses.get",
         "path": "{userId}/settings/forwardingAddresses/{forwardingEmail}",
         "httpMethod": "GET",
         "description": "Gets the specified forwarding address.",
         "parameters": {
          "forwardingEmail": {
           "type": "string",
           "description": "The forwarding address to be retrieved.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "forwardingEmail"
         ],
         "response": {
          "$ref": "ForwardingAddress"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "list": {
         "id": "gmail.users.settings.forwardingAddresses.list",
         "path": "{userId}/settings/forwardingAddresses",
         "httpMethod": "GET",
         "description": "Lists the forwarding addresses for the specified account.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "response": {
          "$ref": "ListForwardingAddressesResponse"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        }
       }
      },
      "sendAs": {
       "methods": {
        "create": {
         "id": "gmail.users.settings.sendAs.create",
         "path": "{userId}/settings/sendAs",
         "httpMethod": "POST",
         "description": "Creates a custom \"from\" send-as alias. If an SMTP MSA is specified, Gmail will attempt to connect to the SMTP service to validate the configuration before creating the alias. If ownership verification is required for the alias, a message will be sent to the email address and the resource's verification status will be set to pending; otherwise, the resource will be created with verification status set to accepted. If a signature is provided, Gmail will sanitize the HTML before saving it with the alias.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "request": {
          "$ref": "SendAs"
         },
         "response": {
          "$ref": "SendAs"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "delete": {
         "id": "gmail.users.settings.sendAs.delete",
         "path": "{userId}/settings/sendAs/{sendAsEmail}",
         "httpMethod": "DELETE",
         "description": "Deletes the specified send-as alias. Revokes any verification that may have been required for using it.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "sendAsEmail": {
           "type": "string",
           "description": "The send-as alias to be deleted.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "sendAsEmail"
         ],
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "get": {
         "id": "gmail.users.settings.sendAs.get",
         "path": "{userId}/settings/sendAs/{sendAsEmail}",
         "httpMethod": "GET",
         "description": "Gets the specified send-as alias. Fails with an HTTP 404 error if the specified address is not a member of the collection.",
         "parameters": {
          "sendAsEmail": {
           "type": "string",
           "description": "The send-as alias to be retrieved.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "sendAsEmail"
         ],
         "response": {
          "$ref": "SendAs"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "list": {
         "id": "gmail.users.settings.sendAs.list",
         "path": "{userId}/settings/sendAs",
         "httpMethod": "GET",
         "description": "Lists the send-as aliases for the specified account. The result includes the primary send-as address associated with the account as well as any custom \"from\" aliases.",
         "parameters": {
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId"
         ],
         "response": {
          "$ref": "ListSendAsResponse"
         },
         "scopes": [
          "https://mail.google.com/",
          "https://www.googleapis.com/auth/gmail.modify",
          "https://www.googleapis.com/auth/gmail.readonly",
          "https://www.googleapis.com/auth/gmail.settings.basic"
         ]
        },
        "patch": {
         "id": "gmail.users.settings.sendAs.patch",
         "path": "{userId}/settings/sendAs/{sendAsEmail}",
         "httpMethod": "PATCH",
         "description": "Updates a send-as alias. If a signature is provided, Gmail will sanitize the HTML before saving it with the alias.\n\nAddresses other than the primary address for the account can only be updated by service account clients that have been delegated domain-wide authority. This method supports patch semantics.",
         "parameters": {
          "sendAsEmail": {
           "type": "string",
           "description": "The send-as alias to be updated.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "sendAsEmail"
         ],
         "request": {
          "$ref": "SendAs"
         },
         "response": {
          "$ref": "SendAs"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.basic",
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "update": {
         "id": "gmail.users.settings.sendAs.update",
         "path": "{userId}/settings/sendAs/{sendAsEmail}",
         "httpMethod": "PUT",
         "description": "Updates a send-as alias. If a signature is provided, Gmail will sanitize the HTML before saving it with the alias.\n\nAddresses other than the primary address for the account can only be updated by service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "sendAsEmail": {
           "type": "string",
           "description": "The send-as alias to be updated.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "sendAsEmail"
         ],
         "request": {
          "$ref": "SendAs"
         },
         "response": {
          "$ref": "SendAs"
         },
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.basic",
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        },
        "verify": {
         "id": "gmail.users.settings.sendAs.verify",
         "path": "{userId}/settings/sendAs/{sendAsEmail}/verify",
         "httpMethod": "POST",
         "description": "Sends a verification email to the specified send-as alias address. The verification status must be pending.\n\nThis method is only available to service account clients that have been delegated domain-wide authority.",
         "parameters": {
          "sendAsEmail": {
           "type": "string",
           "description": "The send-as alias to be verified.",
           "required": true,
           "location": "path"
          },
          "userId": {
           "type": "string",
           "description": "User's email address. The special value \"me\" can be used to indicate the authenticated user.",
           "default": "me",
           "required": true,
           "location": "path"
          }
         },
         "parameterOrder": [
          "userId",
          "sendAsEmail"
         ],
         "scopes": [
          "https://www.googleapis.com/auth/gmail.settings.sharing"
         ]
        }
       },
       "resources": {
        "smimeInfo": {
         "methods": {
          "delete": {
           "id": "gmail.users.settings.sendAs.smimeInfo.delete",
           "path": "{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}",
           "httpMethod": "DELETE",
           "description": "Deletes the specified S/MIME config for the specified send-as alias.",
           "parameters": {
            "id": {
             "type": "string",
             "description": "The immutable ID for the SmimeInfo.",
             "required": true,
             "location": "path"
            },
            "sendAsEmail": {
             "type": "string",
             "description": "The email address that appears in the \"From:\" header for mail sent using this alias.",
             "required": true,
             "location": "path"
            },
            "userId": {
             "type": "string",
             "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
             "default": "me",
             "required": true,
             "location": "path"
            }
           },
           "parameterOrder": [
            "userId",
            "sendAsEmail",
            "id"
           ],
           "scopes": [
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.settings.sharing"
           ]
          },
          "get": {
           "id": "gmail.users.settings.sendAs.smimeInfo.get",
           "path": "{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}",
           "httpMethod": "GET",
           "description": "Gets the specified S/MIME config for the specified send-as alias.",
           "parameters": {
            "id": {
             "type": "string",
             "description": "The immutable ID for the SmimeInfo.",
             "required": true,
             "location": "path"
            },
            "sendAsEmail": {
             "type": "string",
             "description": "The email address that appears in the \"From:\" header for mail sent using this alias.",
             "required": true,
             "location": "path"
            },
            "userId": {
             "type": "string",
             "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
             "default": "me",
             "required": true,
             "location": "path"
            }
           },
           "parameterOrder": [
            "userId",
            "sendAsEmail",
            "id"
           ],
           "response": {
            "$ref": "SmimeInfo"
           },
           "scopes": [
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/gmail.modify",
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.settings.sharing"
           ]
          },
          "insert": {
           "id": "gmail.users.settings.sendAs.smimeInfo.insert",
           "path": "{userId}/settings/sendAs/{sendAsEmail}/smimeInfo",
           "httpMethod": "POST",
           "description": "Insert (upload) the given S/MIME config for the specified send-as alias. Note that pkcs12 format is required for the key.",
           "parameters": {
            "sendAsEmail": {
             "type": "string",
             "description": "The email address that appears in the \"From:\" header for mail sent using this alias.",
             "required": true,
             "location": "path"
            },
            "userId": {
             "type": "string",
             "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
             "default": "me",
             "required": true,
             "location": "path"
            }
           },
           "parameterOrder": [
            "userId",
            "sendAsEmail"
           ],
           "request": {
            "$ref": "SmimeInfo"
           },
           "response": {
            "$ref": "SmimeInfo"
           },
           "scopes": [
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.settings.sharing"
           ]
          },
          "list": {
           "id": "gmail.users.settings.sendAs.smimeInfo.list",
           "path": "{userId}/settings/sendAs/{sendAsEmail}/smimeInfo",
           "httpMethod": "GET",
           "description": "Lists S/MIME configs for the specified send-as alias.",
           "parameters": {
            "sendAsEmail": {
             "type": "string",
             "description": "The email address that appears in the \"From:\" header for mail sent using this alias.",
             "required": true,
             "location": "path"
            },
            "userId": {
             "type": "string",
             "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
             "default": "me",
             "required": true,
             "location": "path"
            }
           },
           "parameterOrder": [
            "userId",
            "sendAsEmail"
           ],
           "response": {
            "$ref": "ListSmimeInfoResponse"
           },
           "scopes": [
            "https://mail.google.com/",
            "https://www.googleapis.com/auth/gmail.modify",
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.settings.sharing"
           ]
          },
          "setDefault": {
           "id": "gmail.users.settings.sendAs.smimeInfo.setDefault",
           "path": "{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}/setDefault",
           "httpMethod": "POST",
           "description": "Sets the default S/MIME config for the specified send-as alias.",
           "parameters": {
            "id": {
             "type": "string",
             "description": "The immutable ID for the SmimeInfo.",
             "required": true,
             "location": "path"
            },
            "sendAsEmail": {
             "type": "string",
             "description": "The email address that appears in the \"From:\" header for mail sent using this alias.",
             "required": true,
             "location": "path"
            },
            "userId": {
             "type": "string",
             "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
             "default": "me",
             "required": true,
             "location": "path"
            }
           },
           "parameterOrder": [
            "userId",
            "sendAsEmail",
            "id"
           ],
           "scopes": [
            "https://www.googleapis.com/auth/gmail.settings.basic",
            "https://www.googleapis.com/auth/gmail.settings.sharing"
           ]
          }
         }
        }
       }
      }
     }
    },
    "threads": {
     "methods": {
      "delete": {
       "id": "gmail.users.threads.delete",
       "path": "{userId}/threads/{id}",
       "httpMethod": "DELETE",
       "description": "Immediately and permanently deletes the specified thread. This operation cannot be undone. Prefer threads.trash instead.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "ID of the Thread to delete.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "scopes": [
        "https://mail.google.com/"
       ]
      },
      "get": {
       "id": "gmail.users.threads.get",
       "path": "{userId}/threads/{id}",
       "httpMethod": "GET",
       "description": "Gets the specified thread.",
       "parameters": {
        "format": {
         "type": "string",
         "description": "The format to return the messages in.",
         "default": "full",
         "enum": [
          "full",
          "metadata",
          "minimal"
         ],
         "enumDescriptions": [
          "",
          "",
          ""
         ],
         "location": "query"
        },
        "id": {
         "type": "string",
         "description": "The ID of the thread to retrieve.",
         "required": true,
         "location": "path"
        },
        "metadataHeaders": {
         "type": "string",
         "description": "When given and format is METADATA, only include headers specified.",
         "repeated": true,
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Thread"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "list": {
       "id": "gmail.users.threads.list",
       "path": "{userId}/threads",
       "httpMethod": "GET",
       "description": "Lists the threads in the user's mailbox.",
       "parameters": {
        "includeSpamTrash": {
         "type": "boolean",
         "description": "Include threads from SPAM and TRASH in the results.",
         "default": "false",
         "location": "query"
        },
        "labelIds": {
         "type": "string",
         "description": "Only return threads with labels that match all of the specified label IDs.",
         "repeated": true,
         "location": "query"
        },
        "maxResults": {
         "type": "integer",
         "description": "Maximum number of threads to return.",
         "default": "100",
         "format": "uint32",
         "location": "query"
        },
        "pageToken": {
         "type": "string",
         "description": "Page token to retrieve a specific page of results in the list.",
         "location": "query"
        },
        "q": {
         "type": "string",
         "description": "Only return threads matching the specified query. Supports the same query format as the Gmail search box. For example, \"from:someuser@example.com rfc822msgid: is:unread\". Parameter cannot be used when accessing the api using the gmail.metadata scope.",
         "location": "query"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId"
       ],
       "response": {
        "$ref": "ListThreadsResponse"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.metadata",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.readonly"
       ]
      },
      "modify": {
       "id": "gmail.users.threads.modify",
       "path": "{userId}/threads/{id}/modify",
       "httpMethod": "POST",
       "description": "Modifies the labels applied to the thread. This applies to all messages in the thread.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the thread to modify.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "request": {
        "$ref": "ModifyThreadRequest"
       },
       "response": {
        "$ref": "Thread"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "trash": {
       "id": "gmail.users.threads.trash",
       "path": "{userId}/threads/{id}/trash",
       "httpMethod": "POST",
       "description": "Moves the specified thread to the trash.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the thread to Trash.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Thread"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      },
      "untrash": {
       "id": "gmail.users.threads.untrash",
       "path": "{userId}/threads/{id}/untrash",
       "httpMethod": "POST",
       "description": "Removes the specified thread from the trash.",
       "parameters": {
        "id": {
         "type": "string",
         "description": "The ID of the thread to remove from Trash.",
         "required": true,
         "location": "path"
        },
        "userId": {
         "type": "string",
         "description": "The user's email address. The special value me can be used to indicate the authenticated user.",
         "default": "me",
         "required": true,
         "location": "path"
        }
       },
       "parameterOrder": [
        "userId",
        "id"
       ],
       "response": {
        "$ref": "Thread"
       },
       "scopes": [
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/gmail.modify"
       ]
      }
     }
    }
   }
  }
 }
}
__END
}