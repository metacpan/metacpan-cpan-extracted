#!/home/ben/software/install/bin/perl
use warnings;
use strict;
# $Bin is the directory of our script itself.
use FindBin '$Bin';
use Trav::Dir;
# A list of files.
my @files;
# The Trav::Dir object.
my $o = Trav::Dir->new ();
# Tell the Trav::Dir object to find all the files under the above directory.
$o->find_files ("$Bin/..", \@files);
# This is how Perl gets the lengths of arrays.
# See perldoc -f scalar.
my $nfiles = scalar (@files);
# "rand(n)" is always < n, and int truncates the fractional part.
# See perldoc -f rand, perldoc -f int.
my $random = int (rand ($nfiles)); 
# At last we have our random file.
print $files[$random];
