#!perl -w
use strict;
use warnings;
use Test::More ;
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


ok( my $reuters = WebService::ReutersConnect->new( { username => $ENV{REUTERS_USERNAME} // REUTERS_DEMOUSER,
                                                     password => $ENV{REUTERS_PASSWORD} // REUTERS_DEMOPASSWORD,
                                                   }), "Ok build a reuters");


## Get channels and fetch all items from the first one.
my @channels = $reuters->fetch_channels({ channel => [ 'xHO143',  'STK567' ] });

## diag("Querying items from channel ".$channels[1]->alias().":".$channels[1]->description());

ok( my @items = $reuters->fetch_items($channels[1]->alias()), "Ok can fetch new items from channel");
foreach my $item ( @items ){
  ## diag($item->headline());
  ok( $item->headline() , "Ok got headline");
  cmp_ok( $item->date_created()->time_zone_short_name() , 'eq' , 'UTC' , "Got UTC timezone for date_created");
  ok( $item->guid() , "Ok got guid");
  ok( $item->media_type() , "Ok got mediatype");
  ok( $item->preview_url() , "Ok got preview_url");
}

{
  ## Test with a date_from
  my $channel = $channels[0];
  ## diag("Fetching items from channel ".$channel->alias().':'.$channel->description());
  ## my $now = DateTime->now();
  ## We use LWP::UserAgent::Mock. Responses are frozen in time
  my $now = DateTime->new( year => 2012,
                           month => 11,
                           day => 29,
                           hour => 12,
                           minute => 6 );
  my $yesterday    = $now->clone->subtract( days => 1 );
  my $two_days_ago = $now->clone->subtract( days => 2 );
  my $three_days_ago = $now->clone->subtract( days => 3 );
  ok( my @items = $reuters->fetch_items($channel, { date_from => $two_days_ago }), "Ok can get items from 2 days to now");
  ## This is a bit tricky to test as it depends on the external source. Come back to it when test uses a mocked Reuter source
  ## cmp_ok( $items[-1]->date_created()->ymd() , 'le' , $yesterday->ymd(), "Ok date of the earliest item is earlier than yesterday");
  cmp_ok( $items[0]->date_created()->ymd() , 'eq' , $now->ymd(), "Ok latest item date is today");

  ok( @items = $reuters->fetch_items($channel, { date_from => $three_days_ago, date_to => $yesterday }),
      "Ok can get items from 2 days to now to yesterday");
  ## diag("Got ".scalar(@items)." items back");
  cmp_ok( $items[-1]->date_created()->ymd() , 'le' , $yesterday->ymd(), "Ok date of the earliest item is earlier than yesterday");
  cmp_ok( $items[0]->date_created()->ymd() , 'ge' , $two_days_ago->ymd(), "Ok latest item date is two days ago, because yesterday is not inclusive");

  ## Ok now we want to fetch only one item
  ok( my  $xml_doc  = $reuters->fetch_item_xdoc({ item => $items[0] }) , "Ok can fetch XML Xdoc");
  foreach my $ns_node ( @{$xml_doc->xml_namespaces()} ){
    ok($ns_node->declaredURI(), "Ok node has declared URI");
  }

  ok( my $xc = $xml_doc->xml_xpath() , "Ok got context");
  ## diag( $xml_doc->toString() );
  ok( $xc->findvalue('/rcx:newsMessage') , "Ok can find value in the default namespace prefix");
  ok( $xc->findvalue('//rcx:description') , "Ok can find description");
  ok( $xc->findvalue('//rcx:headline') , "Ok can find headline");
  ok( my ($html_node) = $xc->findnodes('//x:html') , "Ok find HTML node");
  ok( $html_node->toString() , "Ok can call toString on this node" );

  ok( $xml_doc = $reuters->fetch_item_xdoc( { guid => $items[0]->guid() , channel => $items[0]->channel()->alias(),
                                              company_markup => 1 }), "Ok can fetch by GUID and channel");
  ## diag( $xml_doc->toString());
  ok( $xml_doc->xml_xpath->findvalue('//rcx:description') , "Ok can find description");
  ok( $xml_doc->xml_xpath->findvalue('//rcx:headline') , "Ok can find headline");

}

LWP::UserAgent::Mockable->finished;
done_testing();
