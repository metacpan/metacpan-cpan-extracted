#!/usr/bin/perl
#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# see also ../xmldeps.pl for another parsing of the same file
$type = shift @ARGV;

die "Bad argument, use: genrefs pdf|html <refs\n" if ($type ne "pdf" && $type ne "html");

while(<STDIN>) {
	chomp;
	next if (/\s*#/);
	next if (/^\s*$/);
	($file, $width, $pdfsuf) = split(/\s+/);

	open(FILE, ">", "$type/$file.xml") || die "Unable to open $type/$file: $!\n";
	if ($type eq "pdf") {
		print FILE "<graphic scale=\"100%\" contentwidth=\"$width\" fileref=\"../../$file.$pdfsuf\"/>\n";
	} else {
		# in HTML the path is relative to the HTML file, not to current directory
		print FILE "<graphic scale=\"100%\" fileref=\"$file.lowres.png\"/>\n";
	}
	close FILE;
}
