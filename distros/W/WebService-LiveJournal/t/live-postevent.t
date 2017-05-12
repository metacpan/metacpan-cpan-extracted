use strict;
use warnings;
use Test::More;
use WebService::LiveJournal::Client;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 6;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal::Client->new(
  server => $server,
  username => $user,
  password => $pass,
);

diag $WebService::LiveJournal::Client::error unless defined $client;

isa_ok $client, 'WebService::LiveJournal::Client';

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

my $event = $client->create(
  subject => 'foo',
  event => "bar\nbaz\n",
);

isa_ok $event, 'WebService::LiveJournal::Event';

is $event->postevent, 1, 'postevent returns 1';

like $event->itemid, qr{^\d+$}, "event.itemid " . $event->itemid;
like $event->url, qr{^https?://}, "event.url " . $event->url;
like $event->anum, qr{^\d+$}, "event.itemid " . $event->anum;

