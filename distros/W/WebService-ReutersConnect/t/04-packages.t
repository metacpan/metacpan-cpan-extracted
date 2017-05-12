#!perl -w
use strict;
use warnings;
use Test::More ;
use Test::Fatal qw(dies_ok lives_ok);
use Log::Log4perl qw/:easy/;
use DateTime;
Log::Log4perl->easy_init($ERROR);

## Mockable UserAgent
BEGIN{
  $ENV{LWP_UA_MOCK} ||= 'playback';
  $ENV{LWP_UA_MOCK_FILE} = __FILE__.'.lwp-mock.out';
  eval{ require  LWP::UserAgent::Mockable; LWP::UserAgent::Mockable->import(); };
  plan skip_all => 'Cannot load LWP::UserAgent::Mockable. Skipping' if $@;
}

use WebService::ReutersConnect qw/:demo/;


ok( my $reuters = WebService::ReutersConnect->new( { username => $ENV{REUTERS_USERNAME} // REUTERS_DEMOUSER
                                                     , password => $ENV{REUTERS_PASSWORD} // REUTERS_DEMOPASSWORD }), "Ok build a reuters");


## Get channels and fetch all items from the first one.
my @channels = $reuters->fetch_channels();
my $olr_channel;
foreach my $channel ( @channels ){
  ##diag($channel->alias().' - '.$channel->description());
  # foreach my $cat ( @{$channel->categories()} ){
  #   diag('  CAT: '.$cat->id().' - '.$cat->description());
  # }

  if( $channel->is_online_report() ){
    $olr_channel = $channel;
  }
}

## Find channel which is online report.


## diag("Querying packages from channel ".$olr_channel->alias().":".$olr_channel->description());
{
##  local $TODO = "Wait until reuters makes a Online Report Channel available to test account";
  my @items = ();
  ## $reuters->debug(1);
  @items = $reuters->fetch_packages($olr_channel, { limit => 2  });
  for( my $i = 0 ; $i < scalar(@items) - 1 ; $i++ ){
    ok( $items[$i]->date_created() >= $items[$i+1]->date_created() , "Ok ordering is by date");
  }
  foreach my $item ( @items ){
    # diag($item->date_created().' '.$item->id().' '.$item->headline().' '.$item->media_type());
    # diag("           ".( $item->preview_url() // 'NO PREVIEW URL' ));
    ok( $item->is_composite(), "Ok item is composite");
    ok( $item->headline() , "Ok got headline");
    cmp_ok( $item->date_created()->time_zone_short_name() , 'eq' , 'UTC' , "Got UTC timezone for date_created");
    ok( $item->guid() , "Ok got guid");
    ok( $item->media_type() , "Ok got mediatype");
    ok( scalar(@{$item->main_links()}), "Ok got more than zero main links");
    ## diag("  ** Main links" );
    ## foreach my $link ( @{$item->main_links()} ){
    ##   diag("    ".$link->id()." (".$link->media_type().")");
    ## }
    foreach my $supp_set( @{$item->supplemental_sets()} ){
      ok( $supp_set->id() , "Ok suppset has id");
      ## diag("Extra set with ID ".$supp_set->id());
      ok( $supp_set->size() , "Ok suppset has size" );
      foreach my $item ( @{$supp_set->items()} ){
        ok( $item->id() , "Ok item in subset has ID" );
        ## diag("     ".$item->id()." (".$item->media_type().")");
      }
    }
  }
}

my $breaking_news = undef;
{
  ## Fetch packages ordered by editor
  my @items = $reuters->packages($olr_channel, { limit => 10 ,  use_snep => 1  });
  my $date_order = 1;
  ## Check the ordering is not necesseraly by date.
  for( my $i = 0 ; $i < scalar(@items) - 1 ; $i++ ){
    unless( $items[$i]->date_created() >= $items[$i+1]->date_created() ){ $date_order = 0; last; }
  }
  ok( !$date_order , "There are some items that are not sorted by date in the result (assuming they are editorially sorted)");
  $breaking_news = $items[0];
}

{
  #my ( $extended_bn ) = $reuters->fetch_package($olr_channel, [ $breaking_news ]);
  my $extended_bn = $breaking_news->fetch_richer_me();
  cmp_ok( $extended_bn->id() , 'eq' , $breaking_news->id() , "Those two items are the same in reality");
  ## But the extended links have extra stuff.
  foreach my $link ( @{$extended_bn->main_links()} ){
    ## diag( "   ".$link->media_type().' '.$link->headline() );
    ok( $link->slug(), "Ok main links have slugs");
    ok( $link->headline() , "Ok main link have headline");
    if( $link->media_type() eq 'V' ||
        $link->media_type() eq 'P' ){
      ## diag(" -> ".$link->preview_url());
      ok( $link->preview_url() , "Video and pics have preview URLs");
    }
    if( $link->media_type() eq 'T' ){
      ## diag( "  -> ".$link->fragment() );
      ok( $link->fragment() , "Ok link has fragment");
    }
  }
}


{
  ## Also test the OLR method.
  ## diag("Querying Online Reports");
  ## $reuters->debug(1);
  my @items = $reuters->fetch_olr();
  foreach my $item ( @items ){
    ##diag("ITEM: ".$item->date_created().' : '.$item->headline());
    ok( $item->is_composite(), "Item is composite");
    ok( $item->channel() , "Ok cat get item channel");
    ##diag("Item is in channel ".$item->channel()->description());
    ## $reuters->debug(1);
    #my $richer = $item->fetch_richer_me();
    #ok( $richer->is_composite() , "Richer is also composite");
  }
}

LWP::UserAgent::Mockable->finished;
done_testing();
