use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;
use Time::HiRes qw( sleep );

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 3;

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

my $test_id;

foreach my $num (1..20)
{
  my $event = $client->create(
    subject  => "title $num",
    event    => "bar\nbaz\n",
    year     => 1969+$num,
    month    => 6,
    day      => 29,
    hour     => 4,
    min      => 30,
    security => 'public',
  );
  $event->save;
  note "created $num";
  sleep 0.05;
  $test_id = $event->itemid if $num == 10;
}

my $count = 0;

my $last_sync = $client->sync_items(sub {
  my($action, $type, $id) = @_;
  note " item $action $type $id";
  
  my $event = $client->getevent(itemid => $id);
  return unless $event;
  
  $count++;
});

is $count, 20, 'count = 20';

$count = 0;

$last_sync = $client->sync_items(last_sync => $last_sync, sub {
  my($action, $type, $id) = @_;
  note " item $action $type $id";
  $count++;
});

is $count, 0, 'count = 0';

my $event = $client->get_event( $test_id );
$event->event('a new text');
$event->save;

$count = 0;

$last_sync = $client->sync_items(last_sync => $last_sync, sub {
  my($action, $type, $id) = @_;
  note " item $action $type $id";
  $count++;
});

is $count, 1, 'count = 1';
