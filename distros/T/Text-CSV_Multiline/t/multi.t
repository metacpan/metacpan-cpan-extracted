#!/usr/bin/perl -I../blib/lib

use strict;
use warnings;
use Test::Simple tests => 4;
use Text::CSV_Multiline;

my $tdir = -d "t" ? "t" : ".";

open my $fh, "<", "$tdir/1.csv"
	or die "Error: can't read $tdir/1.csv: $!\n";
while (my @row = csv_read_record($fh))
{
	my $found_quote = 0;
	foreach my $field (@row)
	{
		if ($field =~ /"/)
		{
			print "# found quote character in >>>$field<<<\n";
			$found_quote = 1;
		}
	}
	ok(!$found_quote, "read quote characters correctly");
}
close $fh;
