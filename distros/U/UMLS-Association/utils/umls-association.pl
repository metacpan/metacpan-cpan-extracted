#!/usr/bin/perl

=head1 NAME

umls-association.pl This program calculates the assocation between 
two concepts or sets of concepts

=head1 SYNOPSIS

This utility takes two sets of concepts and returns their assocation 
score

=head1 USAGE

Usage: umls-assocation.pl [OPTIONS] CUI_set1 CUI_set2 --matrix Matrix_File --measure Assoc_Measure

=head1 INPUT

=head2 [CUI_set1] [CUI_set2] 

Two sets of CUIs in the UMLS. Each CUI in the CUI set is comma seperated

[Matrix_File]

File name containing co-occurrence data in sparse matrix format

[Assoc_Measure]

A string specifying the association measure to use
The measure used to calculate the assocation. Recommended = x2 

The package uses the Text::NSP package to do the calculation. 
The measure included within this package are: 

    1.  Frequency
    2.  Random
    3.  Dice Coefficient
    4.  Fishers exact test - left sided
    5.  Fishers exact test - right sided
    6.  Fishers twotailed test - right sided
    7.  Jaccard Coefficient
    8.  Log-likelihood ratio
    9.  Mutual Information
    10.  Odds Ratio
    11.  Pointwise Mutual Information
    12. Phi Coefficient
    13. Pearson's Chi Squared Test
    14. Poisson Stirling Measure
    15. T-score

=head1 OPTIONS

Optional command line arguements

=head2 General Options:

Displays the quick summary of program options.

=head3 --noorder

If selected, the order in which CUIs appear will be disregarded when 
the association score is calculated.

=head3 --lta

Linking Term Association - Calculates the association scores using 
implicit or intermediate relationships between the specified CUIs,
and the count of unique shared co-occurrences.

=head3 --mwa

Minimum Weight Association - Calculates the association scores using 
implicit or intermediate relationships between the specified CUIs, 
and the minimum co-occurrence count between shared co-occurrences.

=head3 --lsa

Linking Set Association - Calculates the association scores using the
association between the sets of co-occurring terms of the original terms

=head3 --sbc

Shared B to C association - Calculates the association scores using
the association between the set of A co-occuring terms, and the 
term C. 

=head3 --wsa

Weighted Set Association - Same as linking set association, but weights
the members of the linking set based on their association with the original
term. The association measure used for weighting is the same as specified
for quantifying association overall (--measure)

=head3 --nonorm

Indicates that the weights in WSA will NOT be normalized between 0 and 1
and instrad the direct association score will be used

=head3 --precision N

Displays values up to N places of decimal. (DEFAULT: 4)
    

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.


=head1 OUTPUT

The association between the two concepts (or terms)

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

 Bridget T. McInnes, Virginia Commonwealth University 
 Alexander D. McQuilkin, Virginia Commonwealth University
 Sam Henry, Virginia Commonwealth University

=head1 COPYRIGHT

Copyright (c) 2015

 Sam Henry, Virginia Commonwealth University 
 henryst at vcu.edu

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
eval(GetOptions( "version", "help", "debug",  "measure=s", "noorder", "lta", "mwa", "lsa", "sbc", "wsa", "matrix=s", "precision=s","nonorm")) or die ("Please check the above mentioned option(s).\n");


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

# At least 1 term should be given on the command line.
if(!(defined $opt_infile) && (scalar(@ARGV) < 1) ) {
    print STDERR "No term was specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

#get required input
my $cuiSet1String = shift;
my $cuiSet2String = shift;

#break the cui sets strings into arrays
my @cuiSet1 = split (/,/,$cuiSet1String);
my @cuiSet2 = split (/,/,$cuiSet2String);


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
if(defined $opt_lsa) {
    $assoc_option_hash{"lsa"} = $opt_lsa;
}
if (defined $opt_sbc){
    $assoc_option_hash{"sbc"} = $opt_sbc;
}
if (defined $opt_wsa){
    $assoc_option_hash{"wsa"} = $opt_wsa;
}
if(defined $opt_noorder){
    $assoc_option_hash{"noorder"} = $opt_noorder;
}
if(defined $opt_matrix) {
    $assoc_option_hash{"matrix"} = $opt_matrix;
}
if(defined $opt_nonorm) {
    $assoc_option_hash{"nonorm"} = $opt_nonorm;
}

#  instantiate instance of UMLS-Assocation
my $association = UMLS::Association->new(\%assoc_option_hash); 
die "Unable to create UMLS::Association object.\n" if(!$association);


#############################################
#  Calculate Association
#############################################

my $score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $assoc_option_hash{"measure"});
print "$score<>$cuiSet1String<>$cuiSet2String\n";

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    print "Usage: umls-association.pl [OPTIONS] [CUI_set1 CUI_set2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input two sets of CUIs \n";
    print "an association matrix, and a string specifying the associaiton\n";
    print " measure to use from the command line and returns \n";
    print "their association.\n";

    print "Usage: umls-assocation.pl [OPTIONS] [CUI_set1] [CUI_set2] --matrix [Matrix_File] --measure [Assoc_Measure]\n\n";

    print "CUI_set1 and CUI_set2 are comma seperated sets of CUIs for which\n";
    print "   the association will be found\n";
    
    print "--matrix FILE            File name containing co-occurrence data in\n";
    print "                         sparse matrix format.\n";

    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         assocation. Valid measures are: \n";
    print "0.  Frequency - just n11 (freq)\n";
    print "1.  Random - a random number between 0 and 1 (random)\n";
    print "2.  Dice Coefficient (dice) \n";
    print "3.  Fishers exact test - left sided (leftFisher)\n";
    print "4.  Fishers exact test - right sided (rightFisher)\n";
    print "5.  Fishers twotailed test - right sided (twotailed)\n";
    print "6.  Jaccard Coefficient (jaccard)\n";
    print "7.  Log-likelihood ratio (ll)\n"; 
    print "8.  Mutual Information (tmi)\n";
    print "9.  Odds Ratio (odds)\n";
    print "10.  Pointwise Mutual Information (pmi)\n";
    print "11. Phi Coefficient (phi)\n";
    print "12. Pearson's Chi Squared Test (x2)\n";
    print "13. Poisson Stirling Measure (ps)\n";
    print "14. T-score (tscore) \n\n";

    print "EXAMPLE:\n";
    print "perl umls-association.pl C0000726,C001554 C0870221 --matrix ../Demos/Datasets/sampleMatrix --measure x2\n\n";


    print "General Options:\n\n";

    print "--precision N            Displays values up to N places of decimal. (DEFAULT: 4)\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "--lta                    Linking Term Association - Calculates the association scores using implicit\n"; 
    print "                         or intermediate relationships between the specified CUIs, and the count\n";
    print "                         of unique shared co-occurrences. \n\n";
    print
    print "--mwa                    Minimum Weight Association - Calculates the association scores using implicit\n";
    print "                         or intermediate relationships between the specified CUIs, and the minimum\n";
    print "                         of co-occurrence count between shared co-occurrences. \n\n";

    print "--lsa                    Linking Set Association - Calculates the association scores using the\n";
    print"                          association between the sets of co-occurring terms of the original terms\n\n";

    print "--sbc                    Shared B to C association - calculates the association scores using the\n"; 
    print "                         association between the set of A co-occuring terms, and the term C\n\n";

    print "--wsa                    Weighted Set Association - Same as linking set association, but weights\n";
    print "                         the members of the linking set based on their association with the original\n";
    print "                         term. The association measure used for weighting is the same as specified\n";
    print "                         for quantifying association overall (--measure)\n\n";

    print "--nonorm                 Indicates that the weights in WSA will NOT be normalized between 0 and 1\n";
    print "                         and instrad the direct association score will be used\n";

    print "--noorder                If selected, the order in which CUIs appear will be disregarded when the association\n"; 
    print "                         score is calculated.\n\n";

}
##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print "current version is ".(Association->version())."\n";
    exit;
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-association.pl --help for help.\n";
}
    
