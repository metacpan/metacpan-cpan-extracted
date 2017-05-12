BEGIN { $ENV{TOADFARM_ACTION} = 'test'; }
use Mojo::Base -strict;
use Test::More;
use Toadfarm -test;

# TEST_CHROOT_ARGS="--userspec www-data:www-data /" ...
# TEST_CHROOT_ARGS="-u www-data /" ...
plan skip_all => 'TEST_CHROOT_ARGS=...' unless $ENV{TEST_CHROOT_ARGS};

diag "[$$] REAL_USER_ID=$<";

unless ($ENV{TOADFARM_CHROOT}++) {
  diag join ' ', qw(sudo -n -E), $^X, -I => $INC[0], $0, @ARGV;
  exec qw(sudo -n -E), $^X, -I => $INC[0], $0, @ARGV;
}

change_root(split ' ', $ENV{TEST_CHROOT_ARGS} || '');

isnt $<, 0, 'changed user from root';

done_testing;
