use strict;
use warnings;
use Test::More;
use Unix::Groups::FFI qw(getgroups setgroups);
use Errno qw(EPERM EINVAL);

my @current_groups = split ' ', $);
shift @current_groups;
is_deeply {map { ($_ => 1) } getgroups}, {map { ($_ => 1) } @current_groups},
  'Retrieved supplementary groups';

my $username = getpwuid $>;
my $gid = (getpwnam $username)[3];

SKIP: {
  skip 'getgrouplist not implemented', 6 unless eval { Unix::Groups::FFI->import('getgrouplist'); 1 };
  
  ok +(grep { $_ == $gid } getgrouplist($username, $gid)), "getgrouplist contains passed $gid";
  ok +(grep { $_ == $gid } getgrouplist($username)), "getgrouplist contains implicit $gid";
  
  my $nonexistent = 'nonexistent1';
  $nonexistent++ while defined scalar getpwnam $nonexistent;
  ok !eval { getgrouplist($nonexistent, $gid); 1 }, "getgrouplist fails on nonexistent user with $gid";
  cmp_ok 0+$!, '==', EINVAL, 'Invalid argument';
  ok !eval { getgrouplist($nonexistent); 1 }, 'getgrouplist fails on nonexistent user without gid';
  cmp_ok 0+$!, '==', EINVAL, 'Invalid argument';
}

SKIP: {
  skip 'These tests are for unprivileged users', 4 if eval { setgroups(getgroups); 1 };
  
  ok !eval { setgroups($gid); 1 }, 'Failed to set supplementary groups';
  cmp_ok 0+$!, '==', EPERM, 'Insufficient privilege';
  
  SKIP: {
    skip 'initgroups not implemented', 2 unless eval { Unix::Groups::FFI->import('initgroups'); 1 };
    ok !eval { initgroups($username, $gid); 1 }, 'Failed to initialize supplementary groups';
    cmp_ok 0+$!, '==', EPERM, 'Insufficient privilege';
  }
}

done_testing;
