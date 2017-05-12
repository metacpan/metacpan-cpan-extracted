#!/usr/bin/perl

use strict;
use WordNet::QueryData;
use Getopt::Long;

my $total=0;
my @sensecount=();
my %poshash;
my $nosense=0;
my $file;
my $help;
my $version;
my $qd = WordNet::QueryData->new;

$poshash{nouns}=0;
$poshash{verbs}=0;
$poshash{adjectives}=0;
$poshash{adverbs}=0;


my $ok = GetOptions (
		     'file=s' => \$file,
		     help => \$help,
		     version => \$version,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "calculate-corpus-stats.pl - calculates statistics of the reformatted corpus\n";
    print 'Last modified by : $Id: calculate-corpus-stats.pl,v 1.3 2009/04/30 22:08:49 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $file ) {
    showUsage();
    exit 1;
}

open (FH, '<', $file) or die "Cannot open '$file': $!";

while(<FH>)
{
	chomp;
	my @instances=split(/ +/);
	foreach my $inst (@instances)
	{	
		$total++;
		my ($w,$p)=($inst =~ /(\S+)#(n|a|r|v)/);
		if($p eq "n"){
			$poshash{nouns}+=1;
		}elsif($p eq "v"){
			$poshash{verbs}+=1;
		}elsif($p eq "a"){
			$poshash{adjectives}+=1;
		}elsif($p eq "r"){
			$poshash{adverbs}+=1;
		}
		my @senses=$qd->querySense($inst);
		my $count=0;
		$count=$#senses;
		if($count < 0){
			$nosense++;
		}else{	
			$sensecount[$count]=$sensecount[$count]+1;
		}
	}
}

print "Total number of instances => ", $total,"\n";
print "The number of Noun Instances => ", $poshash{nouns},"\n";
print "The number of Verb Instances => ", $poshash{verbs},"\n";
print "The number of Adjective Instances => ", $poshash{adjectives},"\n";
print "The number of Adverb Instances => ", $poshash{adverbs},"\n";

my $i=0;
foreach my $s (@sensecount){
	if(defined $s){
		print "Numer of instances with ", $i+1, " sense(s) associated with the specified part of speech => ", $s,"\n";
	}
	$i++;
}

print "Numer of instances with no sense for the specified part of speech =>", $nosense,"\n";

sub showUsage
{
    my $long = shift;
    print "Usage: calculate-corpus-stats.pl --file FILE | {--help | --version}\n";

    if ($long) 
    {
	print "Options:\n";
       print "\t--file               name of the formatted corpus file which is formatted using the script semcor-reformat.pl\n";
	print "\t--help               show this help message\n";
	print "\t--version            show version information\n";
    }
}

__END__

=head1 NAME

calculate-corpus-stats.pl - perl script that gives corpus statistics given a semcor-reformatted corpus file. 

=head1 SYNOPSIS

calculate-corpus-stats.pl --file FILE

=head1 DESCRIPTION

This script gives the information about the distribution of instances based on the part of speech. It also gives
the distribution of instances based on the number of senses available for the instances. For example, the instance 
winter#n has only 1 sense associated with it and so it will be counted in the instances with only 1 sense. 

=head1 AUTHORS

 Varada Kolhatkar, University of Minnesota, Duluth
 <kolha002 at d.umn.edu>

 Ted Pedersen, University of Minnesota, Duluth
 <tpederse at d.umn.edu>

This document last modified by : 
$Id: calculate-corpus-stats.pl,v 1.3 2009/04/30 22:08:49 kvarada Exp $

=head1 SEE ALSO

 L<semcor-reformat.pl> 

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
