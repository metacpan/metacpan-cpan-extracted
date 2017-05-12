#!/usr/bin/perl

use strict;
use warnings;

my ($old_ip, $new_ip, @files) = @ARGV;

sub usage {
	print STDERR "Usage: change_ip.pl OLDIP NEWIP FILE1 FILE2 ...\n";
	exit 1;
}

if (!$old_ip || !$new_ip || !@files) {
	usage();
}

foreach my $file (@files) {
	# Create new text modify object to process every file
	# as writeto => outfilename is not specified, $file is overwritten
	# and a backup is created
	my $tm = new Text::Modify(file => $file, backup => 1);
	# Add to rule to replace the IP
	$tm->replace($old_ip,$new_ip,"replace ip address");
	# And process it
	$tm->process();
}