use strict;
use warnings;
use WebService::Eventful;
use Test::More;

my $app_key = $ENV{EVDB_APP_KEY};
plan skip_all => 'set EVDB_APP_KEY to enable this test'
  unless $app_key;

my $num_tests = 3;
my @flavors   = qw/rest yaml json/;

plan tests => $num_tests * @flavors;

foreach my $flavor (@flavors) {
  my $evdb  = WebService::Eventful->new(app_key => $app_key, flavor => $flavor, debug => 1
, verbose => 1);
  my $event = eval { $evdb->call('events/get', { id => 'E0-001-001321733-5' }) 
};
  my $error = $@;

  SKIP: {
    if ($error) {
      skip "$flavor: couldn't load parser", $num_tests
        if $error =~ /^Can't locate /;
      die $error;
    }

    is(ref($event), 'HASH', "$flavor: event data was returned");
    is($event->{id}, 'E0-001-001321733-5', "$flavor: event ID matches");
    is($event->{title}, 'Cloven Skies', "$flavor: event title matches");
  }
}
