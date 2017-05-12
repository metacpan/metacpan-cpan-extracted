use strict;
use warnings;
use WebService::Eventful;
use Test::More;

my $app_key = $ENV{EVDB_APP_KEY};
plan skip_all => 'set EVDB_APP_KEY to enable this test'
  unless $app_key;
plan tests => 3;

my $evdb = WebService::Eventful->new(app_key => $app_key, debug => 1, verbose => 1);
  
my $event = $evdb->call('events/get', { id => 'E0-001-000218163-6' });
is(ref($event), 'HASH', 'event data was returned');
is($event->{id}, 'E0-001-000218163-6', 'event ID matches');
is($event->{title}, 'Harry Potter Release Party - at Midnight!', 'event title matches');
