#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use WebService::GarminConnect;

plan tests => 4;

# Both the username and password are required arguments.
my $gc;
eval {
  $gc = WebService::GarminConnect->new();
};
is($gc, undef, 'constructor fails with no arguments');

eval {
  $gc = WebService::GarminConnect->new(username => 'user1');
};
is($gc, undef, 'constructor fails with just username');

eval {
  $gc = WebService::GarminConnect->new(password => 'mypass');
};
is($gc, undef, 'constructor fails with just password');

eval {
  $gc = WebService::GarminConnect->new(username => 'user1',
                                       password => 'mypass');
};
isnt($gc, undef, 'constructor succeeds with both username and password');
