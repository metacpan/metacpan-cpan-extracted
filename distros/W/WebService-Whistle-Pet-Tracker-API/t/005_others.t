use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
BEGIN { use_ok('WebService::Whistle::Pet::Tracker::API') };

my $email         = $ENV{'WHISTLE_EMAIL'};
my $password      = $ENV{'WHISTLE_PASSWORD'};
my $pet_id        = $ENV{'WHISTLE_PET_ID'};
my $day_number    = $ENV{'WHISTLE_DAY_NUMBER'};
my $skip          = not ($email and $password);

SKIP: {
  skip 'Environment WHISTLE_EMAIL and WHISTLE_PASSWORD not set', 7 if $skip;
  my $ws      = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
  $pet_id     = $ws->pets->[0]->{'id'} unless $pet_id; #default to first pet
  $day_number = int(time/24/60/60)-1   unless $day_number; #default to yesterday
  diag("Pet: $pet_id, Day: $day_number");
  
  diag('pet_dailies');
  my $pet_dailies = $ws->pet_dailies($pet_id);
  diag(Dumper($pet_dailies));
  isa_ok($pet_dailies, 'ARRAY');
  isa_ok($pet_dailies->[0], 'HASH');

  diag('pet_daily_items');
  my $item = $ws->pet_daily_items($pet_id, $day_number);
  diag(Dumper($item));
  isa_ok($item, 'ARRAY');
  isa_ok($item->[0], 'HASH');

  diag('pet_stats');
  my $stats = $ws->pet_stats($pet_id);
  diag(Dumper($stats));
  isa_ok($stats, 'HASH');
  
  diag('places');
  my $places = $ws->places;
  diag(Dumper($places));
  isa_ok($places, 'ARRAY'); 
  isa_ok($places->[0], 'HASH');
}
