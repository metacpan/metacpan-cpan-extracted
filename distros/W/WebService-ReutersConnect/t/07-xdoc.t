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
## $reuters->debug(1);
## Try to get my channels
ok( my @channels = $reuters->fetch_channels() );
my $ncat = 0;
my @channel_aliases = ();
foreach my $channel ( @channels ){
  ## diag("Channel ".$channel->alias().":".$channel->description());
  ok( $channel->alias() , "Ok channel has an alias");
  ok( $channel->description() , "Ok channel has a description");
}

my @items = $reuters->items('STK567') ; ## This is world service

my $xdoc = $reuters->item({ item => $items[0] });
## diag($xdoc->toString(1));

ok( my $body = $xdoc->get_html_body() , "Ok got a body node");
ok( my @body = $xdoc->get_html_body(), "Ok got the child nodes of the body");
foreach my $part( @body ){
  ok( $part->isa('XML::LibXML::Node') , "Ok body part is an XML node");
}
## diag(join("\n", map{ $_->toString(1)} @body ));

ok( my @subjects = $xdoc->get_subjects() , "Ok can get subjects");
foreach my $subject ( @subjects ){
  ## diag("Subject: ".$subject->name_main());
  ok( $subject->name_main() , "Ok subject has got main name");
}

LWP::UserAgent::Mockable->finished;
done_testing();
