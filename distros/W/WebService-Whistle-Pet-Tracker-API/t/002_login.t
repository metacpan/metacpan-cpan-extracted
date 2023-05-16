use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;
BEGIN { use_ok('WebService::Whistle::Pet::Tracker::API') };

my $email    = $ENV{'WHISTLE_EMAIL'};
my $password = $ENV{'WHISTLE_PASSWORD'};
my $skip     = not ($email and $password);

SKIP: {
  skip 'Environment WHISTLE_EMAIL and WHISTLE_PASSWORD not set', 3 if $skip;
  my $ws = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
  my $login = $ws->login;
  diag(Dumper($login));
  isa_ok($login, 'HASH');
  ok($ws->login->{'auth_token'}, 'login has auth_token');
  like($ws->auth_token, qr/[A-Za-z0-9._]{20,}/);
}
