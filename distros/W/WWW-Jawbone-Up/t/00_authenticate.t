use strict;
use Test::More tests => 2;
use WWW::Jawbone::Up::Mock;

my $bad =
  WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 'wrongpassword');

is($bad, undef, 'invalid credentials');

my $alan = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

isa_ok($alan, 'WWW::Jawbone::Up', 'autentications successful');
