#!perl -w
use strict;
use warnings;
use Test::More ;
use Log::Log4perl qw/:easy/;
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

## Try to get my channels
ok( my @channels = $reuters->fetch_channels() );
my $ncat = 0;
my @channel_aliases = ();
foreach my $channel ( @channels ){
  ## diag("Channel ".$channel->alias().":".$channel->description());
  ok( $channel->alias() , "Ok channel has an alias");
  ok( $channel->description() , "Ok channel has a description");
  if( $channel->last_update() ){
    ok( $channel->last_update()->isa('DateTime') , "Ok got channel last update too");
  }
  if( scalar(@{$channel->categories()}) ){
    $ncat++;
  }
  push @channel_aliases , $channel->alias();
}
ok( $ncat , "Ok at least one channel has got a category");

## Try the channel option.
{
  ## Fetch the first two channels. Why not.
  ok( my @channels = $reuters->channels({ channel => [ @channel_aliases[0..1] ] }) , "Ok can fetch two channels");
  cmp_ok( scalar(@channels) , '==' , 2 , "Ok got two channels");
  foreach my $channel ( @channels ){
    ok( grep { $channel->alias() eq $_ } @channel_aliases[0..1] , "Ok found the same alias");
  }
}

## Getting some channels should put some categories in the $reuters object.
ok( scalar(keys %{$reuters->categories_idx()}) , "Ok there are some categories in the reuters object");

foreach my $key ( keys %{$reuters->categories_idx()} ){
  my $cat = $reuters->categories_idx()->{$key};
  ok( $cat->id() , "Ok this category has an ID");

  ## Test that we have at least one channel for each of these categories.
  ok( my @cat_channels = $reuters->channels({ channelCategory => [ $cat->id() ] }), "Ok we have some channels for category ".$cat->id());
  cmp_ok( scalar( @cat_channels) , '<' , scalar(@channels) , "And we got less than the whole set of channels.");
}

LWP::UserAgent::Mockable->finished;
done_testing();
