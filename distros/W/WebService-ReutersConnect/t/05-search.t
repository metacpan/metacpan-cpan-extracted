#!perl -w
use strict;
use warnings;
use Test::More ;
use Test::Fatal qw/dies_ok lives_ok/;
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

{
  ## General search
  ok( my @items = $reuters->fetch_search() , "Ok can fetch search without any params");
  # foreach my $item ( @items ){
  #   diag($item->id().' - \''.$item->slug().'\' - '.$item->guid().' - '.$item->channel_alias());
  # }
}

my @channels = $reuters->fetch_channels();
## map{ diag($_->description()) } @channels;

{
  ## Search on ONE channel.
  ok( my @items = $reuters->fetch_search({ channels => [ $channels[0] ] }) ,"Ok can fetch from one channel only");
  foreach my $item ( @items ){
    cmp_ok( $item->channel_alias() , 'eq' , $channels[0]->alias() , "Ok good channel");
  }
}

{
  ## Search on TWO channels
  ok( my @items = $reuters->fetch_search({ channels => [ @channels[0..1] ] }), "Ok can fetch from 2 channels");
  foreach my $item ( @items ){
    ok( $item->channel_alias() eq $channels[0]->alias() ||
        $item->channel_alias() eq $channels[1]->alias()
        , "Ok good channel");
    cmp_ok( $item->channel_alias() , 'ne' , $channels[3]->alias() , "Ok no bad channel");
  }
}

{
  ## Search on categories.
  my @categories = @{$channels[0]->categories()} ;
  ok( @categories , "Ok got categories from channel 0");
  ok( my @items = $reuters->fetch_search({ categories => \@categories }), "Ok can fetch with category filtering");
}

{
  ## Search about something that doesnt exists.
  my @items = $reuters->fetch_search({ q => 'headline:c3eec75a303511e29a0fe7c886fb5896' });
  cmp_ok( scalar(@items) , '==' , 0 ,"Nothing found");
}

{
  ## my $now = DateTime->now();
  ## We use LWP::UserAgent::Mock. Responses are frozen in time
  my $now = DateTime->new( year => 2012,
                           month => 11,
                           day => 29,
                           hour => 12,
                           minute => 6 );

  my $one_month_ago = $now->clone->subtract( months => 1 );
  ## Search some Pics about britain in the last 30 days (hopefully there will be at least one)
  my $res = $reuters->search({ media_types => [ 'P' , 'V' ],
                               q => 'headline:britain' ,
                               date_from => $one_month_ago,
                               limit => 3,
                               sort => 'date'
                             });
  my @items = @{ $res->items() };
  ok( @items , "Ok got some results for Picture and Video media");
  ok( $res->size() , "There is a size");
  ok( $res->num_found() , "There is a num found");
  #diag("Size: ".$res->size());
  #diag("Num Found: ".$res->num_found());
  #diag("Start: ".$res->start());
  # foreach my $item ( @items ){
  #   diag($item->headline());
  #   diag($item->preview_url());
  # }
}

{ ## Baaaaad sort
  dies_ok { $reuters->fetch_search({ sort => 'fjeijfiejf' }) } "Ok dies on bad sort";
}

LWP::UserAgent::Mockable->finished;
done_testing();
