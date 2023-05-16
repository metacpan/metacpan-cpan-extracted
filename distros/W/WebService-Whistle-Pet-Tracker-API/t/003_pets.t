use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 6;
BEGIN { use_ok('WebService::Whistle::Pet::Tracker::API') };

my $email    = $ENV{'WHISTLE_EMAIL'};
my $password = $ENV{'WHISTLE_PASSWORD'};
my $skip     = not ($email and $password);

SKIP: {
  skip 'Environment WHISTLE_EMAIL and WHISTLE_PASSWORD not set', 5 if $skip;
  my $ws   = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
  my $pets = $ws->pets;
  diag(Dumper($pets));
  isa_ok($pets, 'ARRAY', 'response');
  my $pet  = $pets->[0];
  isa_ok($pet, 'HASH', 'first pet');
  like($pet->{'id'}, qr/\A[0-9]+\Z/, 'pet id');
  like($pet->{'gender'}, qr/\A[mf]\Z/, 'pet gender');
  ok($pet->{'name'}, 'name');
}
