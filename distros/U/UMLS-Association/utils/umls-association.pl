#!/usr/bin/perl

=head1 NAME

umls-association.pl This program calculates the assocation between 
two concepts (or terms)

=head1 SYNOPSIS

This utility takes two concepts (or terms) and returns their assocation 
score

=head1 USAGE

Usage: umls-assocation.pl [OPTIONS] CUI1|TERM CUI2|TERM

=head1 INPUT

=head2 [CUI1|TERM1] [CUI2|TERM2]

The input are two terms or two CUIs associated to concepts in the UMLS. 

=head1 OPTIONS

Optional command line arguements

=head2 General Options:

Displays the quick summary of program options.

=head3 --conceptexpansion

Calculates the association score taking into account the occurrences of 
descendants of the specified CUIs.

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

=head3 --vsa

Vector Set Association - Calculates the association scores using the
association between the sets of co-occurring terms of the original terms

=head3 --precision N

Displays values up to N places of decimal. (DEFAULT: 4)
    
=head3 --measure STRING

The measure used to calculate the assocation. Default = tscore. 

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
    13. T-score (DEFAULT)

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head2 Input Options:

=head2 General Database Options:

=head3 --username STRING

Username is required to access the umls database on mysql

=head3 --password STRING

Password is required to access the umls database on mysql

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --socket STRING

Socket where the mysql.sock or mysqld.sock is located. 
DEFAULT: mysql.sock

=head2 UMLS::Interface Database Options:

=head3 --umlsdatabase STRING        

Database contain UMLS DEFAULT: umls

=head3 --matrix FILE

File name containing co-occurrence data in sparse matrix format
This is an alternative to storing in a database, but will be 
slower for single queries, but much faster for multiple queries
File should should be sparse format of the form CUI1\tCUI2\tvalue\\n \n\n";

=head2 UMLS::Association Database Options:

=head3 --assocdatabase STRING        

The UMLS-Association database containing the CUI bigrams and their
associated frequency information.  DEFAULT: CUI_BIGRAMS

=head1 OUTPUT

The association between the two concepts (or terms)

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
    
      Bridget T. McInnes: btmcinnes at vcu.edu 

=head1 AUTHOR

 Bridget T. McInnes, Virginia Commonwealth University 
 Alexander D. McQuilkin, Virginia Commonwealth University
 Sam Henry, Virginia Commonwealth University

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
eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "umlsdatabase=s", "assocdatabase=s", "socket=s",  "measure=s", "conceptexpansion", "noorder", "lta", "mwa", "vsa", "matrix=s", "config=s","precision=s")) or die ("Please check the above mentioned option(s).\n");


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
my $cui1 = shift;
my $cui2 = shift;


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
}
else {
    $assoc_option_hash = $DEFAULT_MEASURE;
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
if(defined $opt_vsa) {
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

my $score = $association->calculateAssociation_termPair($cui1, $cui2, $assoc_option_hash{"measure"});
print "$score<>$cui1<>$cui2\n";

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    print "Usage: umls-association.pl [OPTIONS] [TERM1 TERM2] [CUI1 CUI2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input either two terms \n";
    print "or two CUIs from the command line or a file and returns \n";
    print "their association using one of the following measures: \n";

    print "1.  Dice Coefficient (dice) \n";
    print "2.  Fishers exact test - left sided (left)\n";
    print "3.  Fishers exact test - right sided (right)\n";
    print "4.  Fishers twotailed test - right sided (twotailed)\n";
    print "5.  Jaccard Coefficient (jaccard)\n";
    print "6.  Log-likelihood ratio (ll)\n"; 
    print "7.  Mutual Information (tmi)\n";
    print "8.  Odds Ratio (oods)\n";
    print "9.  Pointwise Mutual Information (pmi)\n";
    print "10. Phi Coefficient (phi)\n";
    print "11. Pearson's Chi Squared Test (chi)\n";
    print "12. Poisson Stirling Measure (ps)\n";
    print "13. T-score (tscore) DEFAULT\n\n";

    print "Usage: umls-assocation.pl [OPTIONS] TERM1 TERM2\n\n";

    print "General Options:\n\n";

    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         assocation. (DEFAULT: tscore)\n\n";

    print "--precision N            Displays values up to N places of decimal. (DEFAULT: 4)\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "--conceptexpansion       Calculates the association score taking into account
                                    the occurrences of descendants of the specified CUIs.\n\n";

    print "--lta                    Linking Term Association - Calculates the association scores using implicit 
                                    or intermediate relationships between the specified CUIs, and the count
                                    of unique shared co-occurrences. \n\n";

    print "--mwa                    Minimum Weight Association - Calculates the association scores using implicit 
                                    or intermediate relationships between the specified CUIs, and the minimum
                                    of co-occurrence count between shared co-occurrences. \n\n";

    print "--vsa                    Vector Set Association - Calculates the association scores using the
                                    association between the sets of co-occurring terms of the original terms\n\n";

    print "--noorder                If selected, the order in which CUIs appear will be disregarded when the association 
                                    score is calculated.\n\n";

    print "--config FILE            Configuration file\n\n";    

    print "\n\nInput Options: \n\n";

    print "\n\nGeneral Database Options:\n\n"; 

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";
    print "--socket STRING          Socket for mysql (DEFAULT: /tmp/mysql.sock\n\n";

    print "\n\nUMLS-Interface Database Options: \n\n";

    print "--matrix FILE            File name containing co-occurrence data in sparse matrix format
                                    This is an alternative to storing in a database, but will be 
                                    slower for single queries, but much faster for multiple queries.
                                    File should should be sparse format of the form CUI1\tCUI2\tvalue\\n \n\n";

    print "--umlsdatabase STRING    Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "\n\nUMLS-Association Database Options: \n\n";

    print "--assocdatabase STRING        Database containing CUI bigrams 
                                         (DEFAULT: CUI_BIGRAMS)\n\n";
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
    
