use Mojo::Base -strict;
use Test::More;
use Toadfarm -test;

if (delete $ENV{TOADFARM_SUDO}) {
  diag join ' ', qw(sudo -n -E), $^X, -I => $INC[0], $0, @ARGV;
  exec qw(sudo -n -E), $^X, -I => $INC[0], $0, @ARGV;
}

eval { start ['http://*:80'], user => 'whoever' };
like $@, qr{Cannot change user without TOADFARM_INSECURE=1}, 'Cannot change user';

eval { start ['http://*:80'], group => 'whatever' };
like $@, qr{Cannot change group without TOADFARM_INSECURE=1}, 'Cannot change group';

if ($> == 0) {
  eval { start ['http://*:80'], group => undef, user => undef };
  like $@, qr{Cannot run as 'root' without TOADFARM_INSECURE=1}, 'Cannot run as root';

  eval "package Mojolicious::Plugin::SetUserGroup; use Mojo::Base 'Mojolicious::Plugin'; sub register {}; 1" or die $@;
  plugin 'SetUserGroup';
  eval { start ['http://*:80'], group => undef, user => undef };
  $@ ||= '';
  is $@, '', 'Can start as root when SetUserGroup is loaded';
}

done_testing;
