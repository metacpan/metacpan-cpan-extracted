use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 11;

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
  $event->postevent;
  $event->itemid;
};

do {
  my $event = $client->getevent(itemid => $itemid);
  isa_ok $event, 'WebService::LiveJournal::Event';
  is $event->subject, 'foo', 'event.subject = foo';
  is $event->event,   "bar\nbaz", 'event.event = bar\nbaz\n';
};

do {
  my $event = $client->getevent($itemid);
  isa_ok $event, 'WebService::LiveJournal::Event';
  is $event->subject, 'foo', 'event.subject = foo';
  is $event->event,   "bar\nbaz", 'event.event = bar\nbaz\n';
};

do {
  my $list = $client->getevents('lastn', howmany => 5);
  isa_ok $list, 'WebService::LiveJournal::List';
  isa_ok $list, 'WebService::LiveJournal::EventList';
  my $event = $list->[0];
  isa_ok $event, 'WebService::LiveJournal::Event';
  is $event->subject, 'foo', 'event.subject = foo';
  is $event->event,   "bar\nbaz", 'event.event = bar\nbaz\n';
};
