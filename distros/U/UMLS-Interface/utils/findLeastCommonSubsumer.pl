#!/usr/bin/perl 

=head1 NAME

findLeastCommonSubsumer.pl - This program finds the least common subsumer 
between two concepts.

=head1 SYNOPSIS

This program takes two terms or CUIs and returns the least common
subsumer between them.

=head1 USAGE

Usage: findLeastCommonSubsumer.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]

=head1 INPUT

=head2 Required Arguments:

=head3 [CUI1|TERM1] [CUI2|TERM2]

A TERM or CUI (or some combination) from the Unified 
Medical Language System

=head2 Optional Arguments:

=head3 --config FILE

This is the configuration file. The format of the configuration 
file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

RELA :: <include|exclude> <rela1, rela2, ... relaN>  (optional)

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

SAB :: include MSH
REL :: include RB, RN
RELA :: include inverse_isa, isa

or 

SAB :: include MSH
REL :: exclude PAR, CHD

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

=head3 --depth

The minimum and maximum depth of the least common subsummer

=head3 --propagation

The Information Content of the least common subsumer

=head3 --infile

   A file containing pairs of concepts or terms in the following format:

    term1<>term2 
    
    or 

    cui1<>cui2
 
    or 
    
    cui1<>term2

    or 

    term1<>cui2

=head3 --debug

Sets the debug flag for testing

=head3 --username STRING

Username is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head3 --password STRING

Password is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --socket STRING

The socket your mysql is using. DEFAULT: /tmp/mysql.sock

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head3 --realtime

This option will not create a database of the path information
for all of concepts in the specified set of sources and relations 
in the config file but obtain the information for just the 
input concept

=head3 --forcerun

This option will bypass any command prompts such as asking 
if you would like to continue with the index creation. 

=head3 --debugpath FILE

This option prints out the path information for debugging 
purposes. This option is only really available with the 
--reatime option because otherwise the path information is 
stored in the database. You can get this information in a 
file if you use the --verbose option while creating the index. 

=head3 --verbose

This option will print out the table information to the 
config file that you specified.

=head3 --cuilist FILE

This option takes in a file containing a list of CUIs (one CUI 
per line) and stores only the path information for those CUIs 
rather than for all of the CUIs given the specified set of 
sources and relations

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 OUTPUT

List of CUIs that are associated with the input term

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2009,

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


use UMLS::Interface;
use Getopt::Long;

eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "forcerun", "verbose", "debugpath=s", "cuilist=s", "realtime", "infile=s", "depth", "propagation=s")) or die ("Please check the above mentioned option(s).\n");


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

my @fileArray = ();
if(defined $opt_infile) {
    open(FILE, $opt_infile) || die "Could not open infile: $opt_infile\n";
    while(<FILE>) {
	chomp;
	if($_=~/^\s*$/) { next; }
	push @fileArray, $_;
    }
    close FILE;
}
else {
    # At least 2 terms and/or cuis should be given on the command line.
    if( scalar(@ARGV) < 2 ) {
	print STDERR "Two terms and/or CUIs are required\n";
	&minimalUsageNotes();
	exit;
    }
    
    my $i1 = shift;
    my $i2 = shift;
    
    my $string = "$i1<>$i2";
    push @fileArray, $string;
}

my $umls = "";

my $precision   = 4;    
my $floatformat = join '', '%', '.', $precision, 'f';   

my %option_hash = ();

#$option_hash{"debug"} = 1;

if(defined $opt_propagation) {
    $option_hash{"propagation"} = $opt_propagation;
}
if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug;
}
if(defined $opt_realtime) {
    $option_hash{"realtime"} = $opt_realtime;
}
if(defined $opt_config) {
    $option_hash{"config"} = $opt_config;
}
if(defined $opt_forcerun) {
    $option_hash{"forcerun"} = $opt_forcerun;
}
if(defined $opt_verbose) {
    $option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_debugpath) {
    $option_hash{"debugpath"} = $opt_debugpath;
}
if(defined $opt_cuilist) {
    $option_hash{"cuilist"} = $opt_cuilist;
}
if(defined $opt_username) {
    $option_hash{"username"} = $opt_username;
}
if(defined $opt_driver) {
    $option_hash{"driver"}   = $opt_driver;
}
if(defined $opt_database) {
    $option_hash{"database"} = $opt_database;
}
if(defined $opt_password) {
    $option_hash{"password"} = $opt_password;
}
if(defined $opt_hostname) {
    $option_hash{"hostname"} = $opt_hostname;
}
if(defined $opt_socket) {
    $option_hash{"socket"}   = $opt_socket;
}


$umls = UMLS::Interface->new(\%option_hash); 
die "Unable to create UMLS::Interface object.\n" if(!$umls);

foreach my $element (@fileArray) {
    
    my ($input1, $input2) = split/<>/, $element;
    
    my $c1; my $c2;

    #  check if the input are CUIs or terms
    if( ($input1=~/C[0-9]+/)) {
	push @{$c1}, $input1; 
    }
    else {
	$c1 = $umls->getConceptList($input1); 
    }
    if( ($input2=~/C[0-9]+/)) {
	push @{$c2}, $input2; 
    }
    else {
	$c2 = $umls->getConceptList($input2); 
    }
    
    my $printFlag = 0;
    
    foreach $cui1 (@{$c1}) {
	foreach $cui2 (@{$c2}) {

	    my $t1 = $input1;
	    my $t2 = $input2;
	    
	    if($t1=~/C[0-9]+/) { 
		($t1) = $umls->getAllPreferredTerm($cui1); 
	    }
	    
	    if($t2=~/C[0-9]+/) { 
		($t2) = $umls->getAllPreferredTerm($cui2); 
	    }

	    if(($umls->exists($cui1) == 0) or
	       ($umls->exists($cui2) == 0) ) { next; }
	    
	    if($cui1 eq $cui2) { 
		print "\nThe least common subsumer between $t1 ($cui1) and $t2 ($cui2) is $t1 ($cui1) ";
		if(defined $opt_depth) { 
		    my $min = $umls->findMinimumDepth($cui1);
		    my $max = $umls->findMaximumDepth($cui1);
		    print "with a min and max depth of $min and $max ";
		}
		if(defined $opt_propagation) {
		    my $ic = sprintf $floatformat, $umls->getIC($cui1);
		    print "with an IC of $ic ";
		}
		print "\n";
		
		$printFlag = 1;
		next;
	    }
	    
	    
	    my $lcses = $umls->findLeastCommonSubsumer($cui1, $cui2);
	    	    
	    foreach my $lcs (@{$lcses}) {
		
		my ($t) = $umls->getAllPreferredTerm($lcs);
		
		print "\nThe least common subsumer between $t1 ($cui1) and $t2 ($cui2) is $t ($lcs) ";
		if(defined $opt_depth) {
		    my $min = $umls->findMinimumDepth($lcs);
		    my $max = $umls->findMaximumDepth($lcs);
		    print "with a min and max depth of $min and $max ";
		}
		if(defined $opt_propagation) {
		    my $ic = sprintf $floatformat, $umls->getIC($lcs);
		    print "with an IC of $ic ";
		}
		print "\n";
		
		$printFlag = 1;
	    }
	}
    }
    if( !($printFlag) ) {
	print "\n";
	print "There is not a least common subsumer between $input1 and $input2 given the current view of the UMLS.\n\n";
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findLeastCommonSubsumer.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input two Terms or CUIs\n";
    print "and returns the Least Common Subsumer between the two.\n\n";
  
    print "Usage: findLeastCommonSubsumer.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n\n";

    print "Options:\n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";

    print "--depth                  Outputs the depth of the lcs\n\n";

    print "--propagation FILE       Outputs the IC of the lcs\n\n";

    print "--debug                  Sets the debug flag for testing.\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--socket STRING          Socket used by mysql (DEFAULT: /tmp.mysql.sock)\n\n";

    print "--config FILE            Configuration file\n\n";


    print "--realtime               This option will not create a database of the\n";
    print "                         path information for all of concepts but just\n"; 
    print "                         obtain the information for the input concept\n\n";


    print "--forcerun               This option will bypass any command \n";
    print "                         prompts such as asking if you would \n";
    print "                         like to continue with the index \n";
    print "                         creation. \n\n";

    print "--debugpath FILE         This option prints out the path\n";
    print "                         information for debugging purposes\n\n";

    print "--verbose                This option prints out table information\n";
    print "                         to a directory in your config directory.\n\n";
    print "--cuilist FILE           This option takes in a file containing a \n";
    print "                         list of CUIs (one CUI per line) and stores\n";
    print "                         only the path information for those CUIs\n"; 
    print "                         rather than for all of the CUIs\n\n";

    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: findLeastCommonSubsumer.pl,v 1.21 2011/08/29 16:37:03 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findLeastCommonSubsumer.pl --help for help.\n";
}
    
