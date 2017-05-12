#!/usr/bin/perl -w -I ../lib

use Test;
BEGIN { plan tests => 3 };

use Time::ZoneInfo;

my $VERBOSE = $ARGV[0] || 0;

print STDERR "# If you fail now it may be because you don't have a zonetab file where it is expected. You will have to do your own manual testing.\n";

my $zones = Time::ZoneInfo->new(); # zonetab => '/tmp/testfile');
if (defined($zones)) {
	ok(1);
} else {
	print STDERR "Failed because: " . $Time::ZoneInfo::ERROR . "\n";
	ok(0);
	exit 1;
}
 
if ($VERBOSE) {
	print "THE OBJECT IS :  $zones\n";
	print "NOW I AM CALLING A METHOD:\n";
	print "UNSORTED******************************\n";
}

my @zones = ();
foreach my $zone ($zones->zones) {
	print "$zone\n" if ($VERBOSE);
	push @zones, $zone;
}
ok($#zones > 0);
   
print "SORTED*********************************\n" if ($VERBOSE);
@zones = ();
foreach my $region (sort $zones->regions) {
	print "\t$region\n" if ($VERBOSE);
	foreach my $zone (sort $zones->zones($region)) {
		print "\t\t\t$zone\n" if ($VERBOSE);
	}
	push @zones, $region;
}
ok($#zones > 0);

exit 0;
