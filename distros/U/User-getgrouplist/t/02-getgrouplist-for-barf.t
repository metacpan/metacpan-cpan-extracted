#!perl -Tw

use Test::More tests => 1;

use User::getgrouplist;

my $username = "barfuser";

my $uid = getpwnam($username);	# Hopefully this does NOT exist!

SKIP: {
	skip "Username $username exists on this machine, cannot test", 1 if $uid;

	my @list = getgrouplist($username);

	ok(! @list, 'Empty group list for user ' . $username);
}
