#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my @strings;
my $i=0;
my $version;
my $help;

my $ok = GetOptions (
		     help => \$help,
		     version => \$version,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "scorer2-sort.pl - sort scorer2 formatted file column by column\n";
    print 'Last modified by : $Id: scorer2-sort.pl,v 1.8 2009/02/13 14:49:56 kvarada Exp $';
    print "\n";
    exit;
}

while (<>)
{
	chomp;
	# removing the special characters as scorer2 requires the 
	# words to be sorted ignoring these special characters. 
	s/-|_|'//g;
	$strings[$i++]=$_;	
}
	
my @sorted_strings = sort sort_column @strings;
print join "\n",@sorted_strings;

sub sort_column 
{
  my($token11,$token12,$token13,$token14)=($a =~ /(\S+).([a|n|r|v]) (\d+) (\d+)/);
  my($token21,$token22,$token23,$token24)=( $b =~ /(\S+).([a|n|r|v]) (\d+) (\d+)/);

  if($token11 eq $token21 )
  {
	if( $token12 eq $token22)
	{
		return $token13 cmp $token23;
 	}
	return $token12 cmp $token22;
  }
  return $token11 cmp $token21;
}

sub showUsage
{
    my $long = shift;
    print "Usage: scorer2-sort.pl FILE [FILE ...]  | {--help | --version}\n";

    if ($long) 
    {
	print "Options:\n";
       print "\tone or more scorer2 formatted files\n";
	print "\t--help               show this help message\n";
	print "\t--version            show version information\n";
    }
}

=head1 NAME

scorer2-sort.pl - sort scorer2 formatted files column by column

=head1 SYNOPSIS

 scorer2-sort.pl FILE

=head1 DESCRIPTION

This script is used for sorting scorer2 formatted files column 
by column. At first, the words before '.' are sorted. In the case 
where 2 words are same, they are sorted on their tag, i.e on the string  
after '.'. For example for the entries below, 

action.n 238 1

act.v 75 1 

add.v 275 2 

act.n 630 1 

The sorted entries would be 

act.n 630 1

act.v 75 1

action.n 238 1

add.v 275 2

Observe that the words before . are sorted first and hence 'act' appears 
before 'action'. Moreover, note that 'act.n' appears before 'act.v' as the
words are same and n < v. 

=head1 AUTHORS

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: scorer2-sort.pl,v 1.8 2009/02/13 14:49:56 kvarada Exp $

=head1 SEE ALSO

 L<semcor-reformat.pl> L<wsd-experiments.pl> L<scorer2-format.pl> L<allwords-scorer2.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, Varada Kolhatkar, Ted Pedersen, Jason Michelizzi

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.2
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover
Texts.

Note: a copy of the GNU Free Documentation License is available on
the web at L<http://www.gnu.org/copyleft/fdl.html> and is included in
this distribution as FDL.txt.

=cut
