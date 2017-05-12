use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 2;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

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
  $event->picture('engine');
  is $event->picture, 'engine', 'event.picture = engine';
  $event->update;
  $event->itemid;
};

do {
  my $event = $client->get_event($itemid);
  is $event->picture, 'engine', 'event.picture = engine';
};
