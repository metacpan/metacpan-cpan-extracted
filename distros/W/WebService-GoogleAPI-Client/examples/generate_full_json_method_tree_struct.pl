#!/usr/bin/env perl

use WebService::GoogleAPI::Client;

use Data::Dumper qw (Dumper);
use WebService::GoogleAPI::Client::Discovery;

require Email::Simple;    ## RFC2822 formatted messages
use MIME::Base64;
use utf8;
use open ':std', ':encoding(UTF-8)';    ## allows to print out utf8 without errors
use feature 'say';
use JSON;
use Carp;
use strict;
use warnings;

my $DEBUG = 001;


      ##    BASIC CLIENT CONFIGURATION 

if ( -e './gapi.json')  { say "auth file exists" } else { croak('I only work if gapi.json is here'); }; ## prolly better to fail on setup ?
my $gapi_agent = WebService::GoogleAPI::Client->new( debug => $DEBUG, gapi_json =>'./gapi.json'  );

my $aref_token_emails = $gapi_agent->auth_storage->storage->get_token_emails_from_storage;
my $user              = $aref_token_emails->[0]; ## default to the first user
$gapi_agent->user( $user );

say "Running tests with default user email = $user";

say 'Root cache folder: ' .  $gapi_agent->discovery->chi->root_dir(); ## cached content temporary directory 

construct_tree_struct($gapi_agent, 'calendar' ); exit;


sub construct_tree_struct
{
  my ( $gapi_client ) = @_;
  #$gapi_client->discover_all('force');
  $gapi_client->discover_all();
  my @api_list = $gapi_client->list_of_available_google_api_ids();

  my $list_of_unique_keys_at_index = []; ## each element is a hash count of the unique keys at that level

  #print Dumper \@api_list; exit;

  foreach my $api_root (@api_list)
  #foreach my $api_root ( qw/admin adsense calendar chat gmail sheets slides youtube/ ) ##  @api_list
  {

    ## skipping requests that were giving a 403 error .. not sure why .. perhaps check whether active etc 
    #next if $api_root =~ /android|binaryauthorization|cloudasset|cloudkms|firebaserules|firestore|indexing|jobs|language|oslogin|redis|testing|translate|videointelligence/xm;
    ## NB - the above list will fail for authenticated usage as reported at https://developers.google.com/discovery/forum?place=msg%2Fgoogle-apis-discovery%2FaFqRWcw0ADg%2FJszsGJTWAgAJ
    ## i have included an option in UserAgent::validated_api_query that allows disabling auth but currently no
    ##  way to filter it down to $gapi_client->methods_available_for_google_api_id and others .. leaving for now
    ##  as probably not worth polluting all the param space .. is likely to resurface as I examine usage of dsicovery
    ##  functionality without an auth'd configuration soon enough anyway or Google may resolve the inconsitency.
    ##  or users can live without the auth'd discovery for these services .. will keep an eye on this.
    
    my $meths_by_id = $gapi_client->methods_available_for_google_api_id($api_root);
    foreach my $meth ( keys %{$meths_by_id} )
    {
      my @parts = ( 'Google', split(/\./, $meth) );
      for ( my $i = 0; $i<@parts; $i++ )
      {
        $list_of_unique_keys_at_index->[$i] = {} unless defined $list_of_unique_keys_at_index->[$i];
        $list_of_unique_keys_at_index->[$i]{ join('.', @parts[0..$i] )  }++;
      }
      say "method = $meth";
    }
    #sleep(2) if ( $api_root =~ /^v/xm);
  }

  #say Dumper $list_of_unique_keys_at_index; exit;
  shift @$list_of_unique_keys_at_index; ## trim off the head 
  #say Dumper children_with_parent_named( $list_of_unique_keys_at_index,'gmail' );
  say to_json(children_with_parent_named( $list_of_unique_keys_at_index, 'Google' ) );

#  say Dumper $ret;
#  exit;
  
}

## children_with_parent_named
sub children_with_parent_named 
{
  my (  $list, $parent_name ) = @_; # $ret, , $key

  my $counts = shift @$list; ## take from head of the array
  my $ret = {};
  my $children = [];
  my $leaves   = [];
  foreach my $count_key ( sort keys %$counts )
  {
    if ( $count_key =~ /^$parent_name/xm )
    {
      if ( $counts->{$count_key} > 1 ) ## child has childred
      {
        push @$children, children_with_parent_named(  [@$list], "$count_key" );
      } 
      elsif ( $counts->{$count_key} == 1 )  ## child is a node
      {
        push @$children, { name => $count_key, other => '' };
      }
    }
  }
  if ( @$children > 0 )
  {
    return {
      name => $parent_name,
      children => $children
    };
  }
  else 
  {
    return { name => $parent_name, more => ''};
  }
}
