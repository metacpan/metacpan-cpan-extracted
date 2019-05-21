#!/usr/bin/perl

=head1 NAME

umls-association-runDataSet.pl This program calculates the assocation a 
dataset of term pairs

=head1 SYNOPSIS

This utility takes a file of line seperated term pairs as input. The file is 
of the form: "cui1<>cui2\n" with each line containing a new cui pair. It
outputs a line seperated list of association score and term pair of the 
form: "score<>cui1<>cui2". Each line contains a different cui pair and their 
score

=head1 USAGE

Usage: umls-assocation-runDataSet.pl [OPTIONS] CUI_LIST_FILE OUTPUT_FILE --measure Assoc_Measure --matrix Matrix_FileName

=head1 INPUT

=head2 CUI_LIST_FILE

the input file containing line seperated cui pairs of the form: "cui1<>cui2"

=head2 OUTPUT_FILE

the output file, where each score and cui pair are output of the form: 
score<>cui1<>cui2

[Matrix_File]                                                                                                       

File name containing co-occurrence data in sparse matrix format
 
[Assoc_Measure]

A string specifying the association measure to use
The measure used to calculate the assocation. Recommended = x2

The package uses the Text::NSP package to do the calculation.
The measure included within this package are: 
    1.  Dice Coefficient 
    2.  Fishers exact test - left sided
    3.  Fishers exact test - right sided
    4.  Fishers twotailed test - right sided
    5.  Jaccard Coefficient
    6.  Log-likelihood ratio
    7.  Mutual Information
    8.  Odds Ratio
    9.  Pointwise Mutual Information
    10. Phi Coefficient
    11. Pearson's Chi Squared Test
    12. Poisson Stirling Measure
    13. T-score  

=head1 OPTIONS

Optional command line arguements. These options are identical to 
umls-association.pl. Please see umls-associaton.pl for descriptions.
 
=head1 OUTPUT

The association between the each concept pair of the input file written to 
a new line of the output file.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * Text::NSP - http://search.cpan.org/dist/Text-NSP

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Assocation, 
  please contact us via the users mailing list :
    
      umls-association@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-assocation/
     
  You may also contact us directly if you prefer :
    
      Sam Henry: henryst at vcu.edu 

=head1 AUTHOR

 Sam Henry, Virginia Commonwealth University
 Bridget T. McInnes, Virginia Commonwealth University 
 Alexander D. McQuilkin, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2015

 Bridget T. McInnes, Virginia Commonwealth University 
 btmcinnes at vcu.edu

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
use lib '/home/henryst/UMLS-Association/lib/';

use UMLS::Association;
use Getopt::Long;

#############################################
#  Get Options and params
#############################################
eval(GetOptions( "version", "help", "measure=s", "noorder", "lta", "mwa", "sbc", "lsa", "wsa", "matrix=s","precision=s","nonorm")) or die ("Please check the above mentioned option(s).\n");

#get required input
my $cuisFileName = shift;
my $outputFileName = shift;

#############################################
#  Check help, version, minimal usage notes
#############################################
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

# a single input file and output file must be passed in 
if(!(defined $cuisFileName)) {
    print STDERR "No CUI Pair Input File provided\n";
    &minimalUsageNotes();
    exit;
}
if(!(defined $outputFileName)) {
    print STDERR "No Output File provided\n";
    &minimalUsageNotes();
    exit;
}

#############################################
#  Set Up UMLS::Association
#############################################
#  set UMLS-Association option hash
my %assoc_option_hash = ();

if(defined $opt_measure) {
    $assoc_option_hash{"measure"} = $opt_measure;
} 
if(defined $opt_debug) {
    $assoc_option_hash{"debug"} = $opt_debug;
}
if(defined $opt_verbose) {
    $assoc_option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_precision){
    $assoc_option_hash{"precision"} = $opt_precision;
}
if(defined $opt_lta){
    $assoc_option_hash{"lta"} = $opt_lta;
}
if(defined $opt_mwa){
    $assoc_option_hash{"mwa"} = $opt_mwa;
}
if(defined $opt_sbc){
    $assoc_option_hash{"sbc"} = $opt_sbc;
}
if(defined $opt_lsa){
    $assoc_option_hash{"lsa"} = $opt_lsa;
}
if(defined $opt_wsa){
    $assoc_option_hash{"wsa"} = $opt_wsa;
}
if(defined $opt_noorder){
    $assoc_option_hash{"noorder"} = $opt_noorder;
}
if(defined $opt_matrix){
    $assoc_option_hash{"matrix"} = $opt_matrix;
}
if(defined $opt_nonorm){
    $assoc_option_hash{"nonorm"} = $opt_nonorm;
}


#  instantiate instance of UMLS-Assocation
my $association = UMLS::Association->new(\%assoc_option_hash); 
die "Unable to create UMLS::Association object.\n" if(!$association);

#############################################
#  Calculate Association
#############################################

#read in all the first and second cui sets
# two comma seperated sets seperated by <> (E.G. c1,c2<>c3,c4,c5)
open IN, $cuisFileName 
    or die ("Error: unable to open cui list file: $cuisFileName");
my @sets1 = ();
my @sets2 = ();
foreach my $line (<IN>) {
    #read the cui sets from the line
    chomp $line;
    (my $cuiSet1String, my $cuiSet2String) = split('<>',$line);
    my @cuiSet1 = split(/,/,$cuiSet1String);
    my @cuiSet2 = split(/,/,$cuiSet2String);

    #add to the cui sets
    push @sets1, \@cuiSet1;
    push @sets2, \@cuiSet2;
}
close IN;

#calculate association scores for each term pair
my $scoresRef = $association->calculateAssociation_setPairList(\@sets1, \@sets2, $assoc_option_hash{"measure"});

#output the results
open OUT, ">$outputFileName" 
    or die ("Error: Unable to open output file: $outputFileName");
for (my $i = 0; $i < scalar @{$scoresRef}; $i++) {
    print OUT "${$scoresRef}[$i]<>".(join(',',@{$sets1[$i]}))."<>".(join(',',@{$sets2[$i]}))."\n";
} 
close OUT;



###########################
# Help Functions
###########################
#shows the minimal usage notes
sub minimalUsageNotes {
    print "Usage: umls-association-runDataSet.pl [OPTIONS] CUI_LIST_FILE OUTPUT_FILE\n";
    print "Type umls-association-runDataSet.pl --help for help.\n";
    exit;
}

#shows help to the user
sub showHelp {
    print "This utility takes a file of line seperated term pairs as input.\n";
    print " The file is of the form: \"cui1<>cui2\n\" with each line containing\n";
    print " a new cui pair. It outputs a line seperated list of association\n";
    print "score and term pair of the form: \"score<>cui1<>cui2\". Each line \n";
    print "contains a different cui pair and their score\n";
    print "\n";
    print "Usage: umls-association-runDataSet.pl [OPTIONS] CUI_LIST_FILE OUTPUT_FILE\n";
    print "  --measure Assoc_Measure --matrix Matrix_File\n";
    print "\n";
    print "Please note, the optional parameters are identical to umls-association.pl.\n";
    print "to avoid inconsitencies when adding new features or updating, please see:\n";
    print "umls-association --help\n";
    print "for a complete list of optional arguments\n\n";
}

#shows the current version
sub showVersion {
    print "current version is ".(Association->version())."\n";
    exit;
}
