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

=head3 --measure

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

=head3 --infile FILE

A file containing pairs of concepts or terms in the following format:

    term1<>term2 
    
    or 

    cui1<>cui2

    or 

    cui1<>term2

    or 

    term1<>cui2

Unless the --matrix option is chosen then it is just a list of CUIS:
    cui1
    cui2
    cui3 
    ...

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

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================


use UMLS::Interface; 
use UMLS::Association; 
use Getopt::Long;

eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "umlsdatabase=s", "assocdatabase=s", "socket=s", "infile=s", "measure=s", "getdescendants", "config=s","precision=s")) or die ("Please check the above mentioned option(s).\n");


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
    #&minimalUsageNotes();
    exit;
}

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

#  set UMLS-Association option hash
my %assoc_option_hash = ();

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
if(defined $opt_getdescendants) {
    $assoc_option_hash{"getdescendants"}   = $opt_getdescendants;
}
if(defined $opt_precision){
    $assoc_option_hash{"precision"} = $opt_precision;
}
$assoc_option_hash{"umls"} = $umls;


#  instantiate instance of UMLS-Assocation
my $mmb = UMLS::Association->new(\%assoc_option_hash); 
die "Unable to create UMLS::Association object.\n" if(!$mmb);

#  if --infile option defined calculate assocation over pairs in 
#  the input file
if(defined $opt_infile) { 
    open(FILE, $opt_infile) || die "Could not open file ($opt_infile)\n";
    while(<FILE>) { 
	chomp;
	my ($i1, $i2) = split/<>/;
	calculateStat($i1, $i2); 
    }
}
#  otherwise calculate the assocation over the two input terms
else { 
    my $input1 = shift; my $input2 = shift; 
    calculateStat($input1, $input2); 
}

sub calculateStat { 

    my $input1 = shift;
    my $input2 = shift; 
    
    my $term1 = $input1; 
    my $term2 = $input2; 
    
    my $c1 = undef;
    if($input1=~/C[0-9]+/) {
	push @{$c1}, $input1;
	$term1 = $umls->getAllPreferredTerm($input1);
    }
    else {
	$c1 = $umls->getConceptList($input1);
    }
    
    my $c2 = undef;
    if($input2=~/C[0-9]+/) {
	push @{$c2}, $input2;
	$term2 = $umls->getAllPreferredTerm($input2);
    }
    else {
	$c2 = $umls->getConceptList($input2);
    }
    
    my $measure = "tscore"; 
    if(defined $opt_measure) { 
	$measure = $opt_measure; 
	
	if(! ($measure=~/(ll|pmi|tmi|ps|x2|phi|leftFisher|rightFisher|twotailed|dice|jaccard|odds|tscore)/)) { 
	    print STDER "That measure is not defined for this program\n";
	    &showHelp();
	    exit;
	}
    }

    my $max = -1.000; my $mc1 = ""; my $mc2 = ""; 
    foreach my $cui1 (@{$c1}) { 
	foreach my $cui2 (@{$c2}) { 
	    my $stat = $mmb->calculateStatistic($cui1, $cui2, $measure); 
	    #my $stat2 = $mmb->calculateStatistic($cui2, $cui1, $measure); 
	   # my $stat = $stat1 + $stat2 / 2; 
	    if($stat > $max) { 
		$max = $stat; $mc1 = $cui1; $mc2 = $cui2; 
	    }
	}
    }
    if($max == 0) { $max = -1; }
    print "$max<>$term1($mc1)<>$term2($mc2)\n";
}

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

    print "--precision N            Displays values upto N places of decimal. (DEFAULT: 4)\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "--getdescendants         Calculates the association score taking into account
                         the occurrences of descendants of the specified CUIs\n\n";

    print "--config FILE            Configuration file\n\n";    

    print "\n\nInput Options: \n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";  

    print "\n\nGeneral Database Options:\n\n"; 

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";
    print "--socket STRING          Socket for mysql (DEFAULT: /tmp/mysql.sock\n\n";

    print "\n\nUMLS-Interface Database Options: \n\n";

    print "--umlsdatabase STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "\n\nUMLS-Association Database Options: \n\n";

    print "--assocdatabase STRING        Database containing CUI bigrams 
                              (DEFAULT: CUI_BIGRAMS)\n\n";
    
    

}
##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-assocation.pl,v 0.01 2015/06/24 19:25:05 btmcinnes Exp $';
    print "\nCopyright (c) 2015, Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-association.pl --help for help.\n";
}
    
