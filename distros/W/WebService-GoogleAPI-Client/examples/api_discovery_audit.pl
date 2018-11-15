#!/usr/bin/env perl


use strict;
use warnings;

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use WebService::GoogleAPI::Client::Discovery;
use Carp;
use feature 'say';

my $DEBUG = 0;

my $gapi_client = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json => 'gapi.json' );

my $aref_token_emails = $gapi_client->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0];                                             ## default to the first user
$gapi_client->user( $user );


  $gapi_client->discover_all();
  my @api_list = $gapi_client->list_of_available_google_api_ids();

  my $list_of_unique_keys_at_index = [];    ## each element is a hash count of the unique keys at that level

  #print Dumper \@api_list; exit;

  foreach my $api_root ( @api_list )

    #foreach my $api_root ( qw/admin adsense calendar chat gmail sheets slides youtube/ ) ##  @api_list
  {

    my $meths_by_id = $gapi_client->methods_available_for_google_api_id( $api_root ) || die($api_root );
    foreach my $meth ( keys %{ $meths_by_id } )
    {
        #print Dumper $meths_by_id->{$meth};exit;
        say $meths_by_id->{$meth}{path};
    }

  }