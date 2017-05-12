use strict;
use warnings;
use Test::More;
use WebService::LiveJournal::Client;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 14;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal::Client->new(
  server => $server,
  username => $user,
  password => $pass,
);

diag $WebService::LiveJournal::Client::error unless defined $client;

while(1)
{
  my $list = $client->getevents('lastn', howmany => 50);
  last unless @$list > 0;
  foreach my $event (@$list)
  {
    note "deleting $event";
    $event->delete;
  }
}

my $itemid = do {
  my $event = $client->create(
    subject => 'foo',
    event => "bar\nbaz\n",
  );
  $event->settags(qw( one two three ));
  is((sort $event->gettags)[0], 'one',   'event.gettags.0 = one');
  is((sort $event->gettags)[1], 'three', 'event.gettags.0 = three');
  is((sort $event->gettags)[2], 'two',   'event.gettags.0 = two');
  isa_ok $event, 'WebService::LiveJournal::Event';
  is $event->update, 1, 'update returns 1';
  
  $event->itemid;
};

do {
  my $event = $client->get_event($itemid);

  is((sort $event->gettags)[0], 'one',   'event.gettags.0 = one');
  is((sort $event->gettags)[1], 'three', 'event.gettags.0 = three');
  is((sort $event->gettags)[2], 'two',   'event.gettags.0 = two');

  $event->set_tags(qw( x1 x2 x3 ));
  $event->update;
  
  is((sort $event->gettags)[0], 'x1', 'event.gettags.0 = x1');
  is((sort $event->gettags)[1], 'x2', 'event.gettags.0 = x2');
  is((sort $event->gettags)[2], 'x3', 'event.gettags.0 = x3');
};

do {
  my $event = $client->get_event($itemid);
  
  is((sort $event->get_tags)[0], 'x1', 'event.gettags.0 = x1');
  is((sort $event->get_tags)[1], 'x2', 'event.gettags.0 = x2');
  is((sort $event->get_tags)[2], 'x3', 'event.gettags.0 = x3');
};