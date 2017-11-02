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

Usage: umls-assocation-runDataSet.pl [OPTIONS] CUI_LIST_FILE OUTPUT_FILE

=head1 INPUT

=head2 CUI_LIST_FILE

the input file containing line seperated cui pairs of the form: "cui1<>cui2"

=head2 OUTPUT_FILE

the output file, where each score and cui pair are output of the form: 
score<>cui1<>cui2

=head1 OPTIONS

Optional command line arguements. These options are identical to 
umls-association.pl. Please see umls-associaton.pl for descriptions.
 
=head1 OUTPUT

The association between the each concept pair of the input file written to 
a new line of the output file.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

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

use UMLS::Interface;
use UMLS::Association;
use Getopt::Long;

my $DEFAULT_MEASURE = "tscore";

#############################################
#  Get Options and params
#############################################
eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "umlsdatabase=s", "assocdatabase=s", "socket=s", "measure=s", "conceptexpansion", "noorder", "lta", "mwa", "vsa", "matrix=s", "config=s","precision=s")) or die ("Please check the above mentioned option(s).\n");

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
#  Set Up UMLS::Interface
#############################################
#  set UMLS-Interface options
my %umls_option_hash = ();

$umls_option_hash{"t"} = 1; 

if(defined $opt_debug) {
    $umls_option_hash{"debug"} = $opt_debug;
}
if(defined $opt_verbose) {
    $umls_option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_username) {
    $umls_option_hash{"username"} = $opt_username;
}
if(defined $opt_driver) {
    $umls_option_hash{"driver"}   = $opt_driver;
}
if(defined $opt_umlsdatabase) {
    $umls_option_hash{"database"} = $opt_umlsdatabase;
}
if(defined $opt_password) {
    $umls_option_hash{"password"} = $opt_password;
}
if(defined $opt_hostname) {
    $umls_option_hash{"hostname"} = $opt_hostname;
}
if(defined $opt_socket) {
    $umls_option_hash{"socket"}   = $opt_socket;
}
if(defined $opt_config){
    $umls_option_hash{"config"} = $opt_config;
}

#  instantiate instance of UMLS-Interface
my $umls = UMLS::Interface->new(\%umls_option_hash); 
die "Unable to create UMLS::Interface object.\n" if(!$umls);

#############################################
#  Set Up UMLS::Association
#############################################
#  set UMLS-Association option hash
my %assoc_option_hash = ();
$assoc_option_hash{'umls'} = $umls;

if(defined $opt_measure) {
    $assoc_option_hash{"measure"} = $opt_measure;
} else {
    $assoc_option_hash{"measure"} = $DEFAULT_MEASURE;
}
if(defined $opt_debug) {
    $assoc_option_hash{"debug"} = $opt_debug;
}
if(defined $opt_verbose) {
    $assoc_option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_username) {
    $assoc_option_hash{"username"} = $opt_username;
}
if(defined $opt_driver) {
    $assoc_option_hash{"driver"}   = $opt_driver;
}
if(defined $opt_assocdatabase) {
    $assoc_option_hash{"database"} = $opt_assocdatabase;
}
if(defined $opt_password) {
    $assoc_option_hash{"password"} = $opt_password;
}
if(defined $opt_hostname) {
    $assoc_option_hash{"hostname"} = $opt_hostname;
}
if(defined $opt_socket) {
    $assoc_option_hash{"socket"}   = $opt_socket;
}
if(defined $opt_conceptexpansion) {
    $assoc_option_hash{"conceptexpansion"}   = $opt_conceptexpansion;
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
if(defined $opt_vsa){
    $assoc_option_hash{"vsa"} = $opt_vsa;
}
if(defined $opt_noorder){
    $assoc_option_hash{"noorder"} = $opt_noorder;
}
if(defined $opt_matrix){
    $assoc_option_hash{"matrix"} = $opt_matrix;
}

#  instantiate instance of UMLS-Assocation
my $association = UMLS::Association->new(\%assoc_option_hash); 
die "Unable to create UMLS::Association object.\n" if(!$association);

#############################################
#  Calculate Association
#############################################

#read in all the first and second cuis
open IN, $cuisFileName 
    or die ("Error: unable to open cui list file: $cuisFileName");
my @cuiPairs = ();
foreach my $line (<IN>) {
    chomp $line;
    (my $cui1, my $cui2) = split('<>',$line);
    push @cuiPairs, "$cui1,$cui2";
}
close IN;

#calculate association scores for each term pair
my $scoresRef = $association->calculateAssociation_termPairList(\@cuiPairs, $assoc_option_hash{"measure"});

#output the results
open OUT, ">$outputFileName" 
    or die ("Error: Unable to open output file: $outputFileName");
for (my $i = 0; $i < scalar @cuiPairs; $i++) {
    (my $cui1, my $cui2) = split(',',$cuiPairs[$i]);
    print OUT "${$scoresRef}[$i]<>$cui1<>$cui2\n";
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
    print "\n";
    print "Please note, the optional parameters are identical to umls-association.pl.\n";
    print "to avoid inconsitencies when adding new features or updating, please see:\n";
    print "umls-association --help\n";
    print "for a complete list of optional arguments"
}

#shows the current version
sub showVersion {
    print "current version is ".(Association->version())."\n";
    exit;
}
