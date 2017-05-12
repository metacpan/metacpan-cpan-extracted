#!perl -Tw

use Test::More tests => 2;

use User::getgrouplist;

my $username = undef;
my $gid;
my @ent;

@ent = getpwuid(0);	# Is this a unix/linuxish O/S (includes MacOS)?

if (@ent) {
	$username = 'root';
	$gid = 0;
} else {		# Or is it Cygwin?
	my @ent = getpwuid(500);	# We expect the "Administrator" account to be uid 500
	$username = $ent[0];
	$gid = $ent[4];
}

note("Checking user $username to be in group $gid\n");

SKIP: {
	skip 'Neither Unix/Linux nor Windows detected', 2 unless $username;

	my @list = getgrouplist($username);

	ok(scalar(@list) > 0, 'Found at least one group for ' . $username);

	ok((grep { $_ == $gid } @list), sprintf('Group %d in %s\'s group list', $gid, $username));
}
