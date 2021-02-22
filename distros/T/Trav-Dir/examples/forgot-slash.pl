#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Trav::Dir;
my $o = Trav::Dir->new ();
my @files;
$o->find_files (".", @files);


