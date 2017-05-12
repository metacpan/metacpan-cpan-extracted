#!/usr/bin/perl
=head1 NAME

spearmans.pl - This program calculates Spearman's Rank Correlation 
between two datasets.

=head1 SYNOPSIS

This utility takes two files in the format of umls-similarity.pl output 
and calculates the Spearman's Rank Correlation. 

=head1 USAGE

Usage: spearmans.pl [OPTIONS] FILE1 FILE2

=head1 INPUT 

FILE1 FILE2

Two files in the following format:

score<>CUI1<>CUI2
score<>CUI3<>CUI4
ect ...

The output format of umls-similarity.pl will work here because it 
extracts the CUIs from the paranthesis, so no worries. If you are 
not using the CUI format or a umls-similarity.pl output file though, 
use the --word option described below. 
  
=head1 Optional Arguments:

Displays the quick summary of program options.

=head2 --word

The format of the input files contains words rather than CUIs and/or 
is not a umls-similarity.pl output file.

=head2 --N 

displays N - the number of term pairs the correlation 
is being calculated over. This would be any term pair 
that has a score greater than or equal to zero.

=head2 --precision NUMBER

Displays values up to NUMBER places of decimal. Default is 4. 

=head2 --version

Displays the version information.

=head1 OUTPUT

The Spearman's Rank Correlation between the two files.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Similarity

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :
    
      umls-similarity@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-similarity/
     
  You may also contact us directly if you prefer :
    
      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2011,

 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu


 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd@cs.utah.edu
 
 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

use Getopt::Long;

eval(GetOptions( "version", "help", "word", "N", "precision=s", "t")) or die ("Please check the above mentioned option(s).\n");

#  if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp();
    exit;
}

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

#  check for precision
my $precision = 4;
if(defined $opt_precision) {
    if ($opt_precision !~ /^\d+$/) {
	print STDERR "Value for switch --precision should be integer >= 0\n";
	&minimalUsageNotes();
	exit;
    }
    $precision = $opt_precision;
}
my $floatformat = join '', '%', '.', $precision, 'f';

# At least 2 terms should be given on the command line.
if( scalar(@ARGV) < 2 ) {
    print STDERR "At least 2 terms or CUIs should be given on the \n";
    print STDERR "command line.\n\n";
    &minimalUsageNotes();
    exit;
}

#  initialize variables
my $xfile = shift;
my $yfile = shift;

open(X, $xfile) || die "Could not open file: $xfile\n";
open(Y, $yfile) || die "Could not open file: $yfile\n";


my $ymean = 0;
my $xmean = 0;

my $ycount = 0;
my $xcount = 0;

my %xhash = ();
my %yhash = ();

my %xlist = ();
my %ylist = ();

my $xnegative = 0;
my $ynegative = 0;

my $xtotal = 0;
my $ytotal = 0;

while(<X>) {
    chomp;
    my ($score, $t1, $t2) = split/<>/;
    
    my $c1 = ""; my $c2 = "";
    if(defined $opt_word) { 
	$c1 = $t1; $c2 = $t2;
    }
    else {
	$t1=~/(C[0-9]+)/;
        $c1 = $1;
    
	$t2=~/(C[0-9]+)/;
	$c2 = $1;
    }

 
    if($score == -1.0000) { $xnegative++; next; }

    $xtotal++;
  
    $term = "$c1 $c2"; 
    push @{$xhash{$score}}, $term;
    $xlist{$term}++;
}

while(<Y>) {
    chomp;
    my ($score, $t1, $t2) = split/<>/;


    my $c1 = ""; my $c2 = "";
    if(defined $opt_word) { 
	$t1=~s/\(C[0-9]+\)//g; 
	$t2=~s/\(C[0-9]+\)//g; 
	$c1 = $t1; $c2 = $t2;
    }
    else {
	$t1=~/(C[0-9]+)/;
	$c1 = $1;
    
	$t2=~/(C[0-9]+)/;
	$c2 = $1;
    }

    
    if($score == -1.0000) { $ynegative++; next; }

    $ytotal++;

    $term = "$c1 $c2"; 
    push @{$yhash{$score}}, $term;
    $ylist{$term}++;
}

my %xrank = ();
my %yrank = ();

my $rank = 1; 
foreach my $score (sort {$b<=>$a} keys %xhash) {

    my $count = 0;
    my $computed_rank = 0; my $crank = $rank + 1;
    foreach my $term (@{$xhash{$score}}) {
	if(exists $ylist{$term}) {
	    $computed_rank += $crank;
	    $count++; $crank++;
	}
    } 
    
    if($count == 0) { next; }
    
    $computed_rank = $computed_rank / $count;
    
    foreach my $term (@{$xhash{$score}}) {
	if(! (exists $ylist{$term})) { next; }
	$xrank{$term} = $computed_rank;
	$xmean += $computed_rank;
	$xcount++;
	$rank++;
    } 
}

$rank = 0; 
foreach my $score (sort {$b<=>$a} keys %yhash) {
    
    my $count = 0;
    my $computed_rank = 0; my $crank = $rank + 1;
    foreach my $term (@{$yhash{$score}}) {
	if(exists $xlist{$term}) {
	    $computed_rank += $crank;
	    $count++; $crank++;
	}
    } 
    
    if($count == 0) { next; }
    
    $computed_rank = $computed_rank / $count;
    
    foreach my $term (@{$yhash{$score}}) {
	if(! (exists $xlist{$term})) { next; }
	$yrank{$term} = $computed_rank;
	$ymean += $computed_rank;
	$ycount++;
	$rank++;
    } 
}

print STDERR "$xcount : $ycount\n";

$xmean = $xmean/$xcount;
$ymean = $ymean/$ycount;

my $numerator = 0;
my $xdenom = 0;
my $ydenom = 0;
foreach my $term (sort keys %xrank) {
    my $xi = $xrank{$term};
    my $yi = $yrank{$term};
            
    $numerator += ( ($xi-$xmean) * ($yi-$ymean) );
    
    $xdenom += ( ($xi - $xmean)**2 );
    $ydenom += ( ($yi - $ymean)**2 );
}

my $denominator = sqrt($xdenom * $ydenom);


if($denominator <= 0) { 
    print STDERR "Correlation can not be calculated.\n";
    print STDERR "Files do not contain similar ngrams.\n";
    exit;
}

my $pearsons = $numerator / $denominator;

my $score = sprintf $floatformat, $pearsons;

#  calculate N
my $yN= $ytotal - $ynegative;
my $xN= $xtotal - $xnegative; 
my $N = $yN;
if($xN < $yN){ $N = $xN; }

#  calculate tscore 
#my $t = $score/(sqrt( (1-$score**2)/($N-2) ));

#  calculate z-score
#my $Fr = .5 * log((1+$score)/(1-$score));
#my $z  = sqrt(($N-3)/1.06) * $Fr;

print "Spearman's Rank Correlation: $score "; 
if(defined $opt_N)     { print "(N: $N) "; }
#if(defined $opt_t)     { print "(t: $t) "; }
print "\n";

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: spearmans.pl [OPTIONS] FILE1 FILE2\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input two files and returns\n";
    print "the spearman's rank correlation between the two datsets.\n\n";
  
    print "Usage: spearmans.pl [OPTIONS] FILE1 FILE2\n\n";

    print "Options:\n\n";

    print "--precision NUMBER       Displays values upto NUMBER places of \n";
    print "                         decimal.\n\n";

    print "--N                      Prints the total number of term\n";
    print "                         pairs the correlation metric is\n";
    print "                         using.\n\n";

    print "--word                   The format of the input files contains words \n";
    print "                         rather than CUIs or is not a umls-similarity.pl \n";
    print "                         output file. \n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: spearmans.pl,v 1.13 2015/06/23 13:33:06 btmcinnes Exp $';
    print "\nCopyright (c) 2009-2011, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type spearmans.pl --help for help.\n";
}
    
