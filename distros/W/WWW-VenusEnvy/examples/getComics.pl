#!/usr/bin/perl -w

use strict;

my $comicDir = "$ENV{HOME}/data/comics";
unless (-d $comicDir) {
	require File::Path;
	mkpath($comicDir, 1);
}

chdir($comicDir) || die "Unable to change directory: $!";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $date = sprintf('%04d%02d%02d',($year += 1900),++$mon,$mday);

eval { require WWW::Dilbert; };
unless ($@) {
	unless (-d "$comicDir/dilbert") {
		mkdir "$comicDir/dilbert" || die "Unable to make directory: $!";
	}
	my $filename = WWW::Dilbert::mirror_strip("dilbert/dilbert$date.gif");
	print "Downloaded Dilbert comic to $filename.\n";
}

eval { require WWW::VenusEnvy; };
unless ($@) {
	unless (-d "$comicDir/venusenvy") {
		mkdir "$comicDir/venusenvy" || die "Unable to make directory: $!";
	}
	my $filename = WWW::VenusEnvy::mirror_strip();
	my $new_filename = "venusenvy/venusenvy$filename";
	if (-f $new_filename) {
		print "Old VenusEnvy comic strip ignored.\n";
		unlink $filename || die "Unable to delete $filename: $!";
	} else {
		print "Downloaded VenusEnvy comic to $new_filename.\n";
		rename $filename, $new_filename
			|| die "Unable to move $filename to $new_filename: $!";
	}
}


