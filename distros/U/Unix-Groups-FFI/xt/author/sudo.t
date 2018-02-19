use strict;
use warnings;
use Test::More;
use Unix::Groups::FFI qw(getgroups setgroups getgrouplist initgroups);
use Errno 'EINVAL';

plan skip_all => 'TEST_RUN_SUDO=1' unless $ENV{TEST_RUN_SUDO};
if ((my $uid = $>) != 0) {
	my $user = getpwuid $uid;
	$ENV{TEST_ORIGINAL_USER} = $user;
	my @args = ('sudo', '-nE', $^X);
	push @args, '-I', $_ for @INC;
	push @args, $0, @ARGV;
	exec @args;
}

plan skip_all => "user is missing in TEST_ORIGINAL_USER=$ENV{TEST_ORIGINAL_USER}"
	unless my $user = $ENV{TEST_ORIGINAL_USER};
plan skip_all => "invalid user in TEST_ORIGINAL_USER=$ENV{TEST_ORIGINAL_USER}"
	unless defined(my $gid = (getpwnam $user)[3]);

ok(eval { setgroups($gid); 1 }, "Set supplementary groups to $gid") or diag $@;
is_deeply [getgroups], [$gid], "Retrieved supplementary groups $gid";

ok !eval { setgroups((0)x2**18); 1 }, 'Failed to set 2**18 groups';
cmp_ok $!, '==', EINVAL, 'right error code';

ok(eval { initgroups($user, $gid); 1 }, "Initialized groups for $user with $gid") or diag $@;
ok +(grep { $_ == $gid } getgroups), "Supplementary groups contain $gid";

is_deeply {map { ($_ => 1) } getgroups}, {map { ($_ => 1) } getgrouplist($user, $gid)},
  "Supplementary groups match groups for $user with $gid";

ok(eval { initgroups($user); 1 }, "Initialized groups for $user") or diag $@;
ok +(grep { $_ == $gid } getgroups), "Supplementary groups contain $gid";

is_deeply {map { ($_ => 1) } getgroups}, {map { ($_ => 1) } getgrouplist($user)},
  "Supplementary groups match groups for $user";

my $nonexistent = 'nonexistent1';
$nonexistent++ while defined scalar getpwnam $nonexistent;

ok !eval { initgroups($nonexistent); 1 }, 'Failed to initialize groups for nonexistent user';
cmp_ok $!, '==', EINVAL, 'right error code';

ok !eval { initgroups($nonexistent, $gid); 1 }, "Failed to initialize groups for nonexistent user with $gid";
cmp_ok $!, '==', EINVAL, 'right error code';

done_testing;
