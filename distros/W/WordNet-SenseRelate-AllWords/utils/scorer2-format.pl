#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $infile;
my $help;
my $version;

my $ok = GetOptions (
		     'file=s' => \$infile,
		     help => \$help,
		     version => \$version,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "scorer2-format.pl - Reformat wsd.pl output for use by the scorer2 evaluation program\n";
    print 'Last modified by : $Id: scorer2-format.pl,v 1.10 2009/05/25 22:23:29 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $infile) {
    showUsage();
    exit 1;
}
	
my $id = 0;

open FH, '<', $infile or die "Cannot open $infile: $!";
while (my $line = <FH>) {
    my @forms = split /\s+/, $line;
    foreach my $form (@forms) {
	#my ($w, $p, $s) = split /\#/, $form;
	my ($w, $p, $s)=($form =~ /(\S+)\#([n|r|v|a])\#(\d+)/);
	# inc the id number
	$id++;

	unless (defined $w && defined $s && defined $p){
		next;
	}
	
	# check to see if there is a sense number assigned
	if ($s !~ m/NR/ && $s !~ m/ND/ ) {
	    print $w, '.', $p, ' ', $id, ' ', $s, "\n";
	}
	else {
	    # do nothing
	}
    }
}
close FH;

sub showUsage
{
    my $long = shift;
    print "Usage: scorer2-format.pl --file FILE  | {--help | --version}\n";

    if ($long) 
    {
	print "Options:\n";
       print "\t--file               wsd.pl output formatted file\n";
	print "\t--help               show this help message\n";
	print "\t--version            show version information\n";
    }
}

__END__

=head1 NAME

scorer2-format.pl - Reformat wsd.pl output for use by the allwords-scorer2.pl evaluation program 

=head1 SYNOPSIS

 scorer2-format.pl INFILE

=head1 DESCRIPTION

This script reads file from the command line and reformats
it so that it can be scored using the allwords-scorer2.pl program.  
The input format is that of the wsd.pl program that is distributed with
WordNet-SenseRelate.  The output is printed to the standard output and the
configuration information is printed to the standard error. 

=head1 allwords-scorer2.pl

allwords-scorer2.pl is modeled after scorer2 C program used to score entries to Senseval.
The scorer2 C program is available for download at L<http://www.senseval.org/senseval3/scoring>.

=head1 AUTHORS

 Jason Michelizzi

 Varada Kolhatkar, University of Minnesota, Duluth
 <kolha002 at d.umn.edu>

 Ted Pedersen, University of Minnesota, Duluth
 <tpederse at d.umn.edu>

This document last modified by : 
$Id: scorer2-format.pl,v 1.10 2009/05/25 22:23:29 kvarada Exp $

=head1 SEE ALSO

 L<semcor-reformat.pl> L<wsd-experiments.pl> L<scorer2-sort.pl> L<allwords-scorer2.pl>


=head1 COPYRIGHT 

Copyright (C) 2005-2008 by Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.


