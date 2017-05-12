#!/usr/bin/perl 

=head1 NAME

findNumberOfCloserConcepts.pl - This program finds the number of concepts 
closer to the first concept than the second.

=head1 SYNOPSIS

This program takes two terms or CUIs and returns the number of concepts 
closer to the first concept than the second.

=head1 USAGE

Usage: findNumberOfCloserConcepts.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]

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

=head3 --infile FILE

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

=head3 --verbose

This option will print out the table information to the 
config directory that you specified.

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 OUTPUT

The path(s) between the two given CUIs or terms

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

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "infile=s","verbose", "debug")) or die ("Please check the above mentioned option(s).\n");


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

#  get the input either on the command line or through the 
#  --infile option and store them in the fileArray
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
    if(scalar(@ARGV) < 2) {
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
my %option_hash = ();

if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug;
}
if(defined $opt_config) {
    $option_hash{"config"} = $opt_config;
}
if(defined $opt_verbose) {
    $option_hash{"verbose"} = $opt_verbose;
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
    
    my $flag1 = "cui";
    my $flag2 = "cui";

    my $c1 = undef;
    my $c2 = undef;

    #  check if the input are CUIs or terms
    if( ($input1=~/C[0-9]+/)) {
	push @{$c1}, $input1;
    }
    else {
	$c1 = $umls->getConceptList($input1); 
	$flag1 = "term";
    }
    if( ($input2=~/C[0-9]+/)) {
	push @{$c2}, $input2; 
    }
    else {
	$c2 = $umls->getConceptList($input2); 
	$flag2 = "term";
    }
    
    
    my $printFlag = 0;
    my $precision = 4;      
    my $floatformat = join '', '%', '.', $precision, 'f';    
    foreach $cui1 (@{$c1}) {
	foreach $cui2 (@{$c2}) {
	   
	    if(! ($umls->exists($cui1)) ) { next; }
	    if(! ($umls->exists($cui2)) ) { next; }
		    
	    my $t1 = $input1;
	    my $t2 = $input2;
	    
	    if($flag1 eq "cui") { 
		my $ts1 = $umls->getTermList($cui1); $t1 = shift @{$ts1};
	    }
	    if($flag2 eq "cui") { 
		my $ts2 = $umls->getTermList($cui2); $t2 = shift @{$ts2}; 
	    }

	    my $number = $umls->findNumberOfCloserConcepts($cui1, $cui2);
	    
	    print "\nThe number of concepts closer to $t1 ($cui1) then $t2 ($cui2) is $number\n";
	}
    }
}
 
##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findNumberOfCloserConcepts.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input two Terms or\n";
    print "CUIs and returns the number of concepts closer to the\n";
    print "first concept than the second.\n\n";
  
    print "Usage: findNumberOfCloserConcepts.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n\n";

    print "Options:\n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";
    
    print "--debug                  Sets the debug flag for testing\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--socket STRING          Socket used by mysql (DEFAULT: /tmp.mysql.sock)\n\n";

    print "--config FILE            Configuration file\n\n";
    
    print "--debugpath FILE         This option prints out the path\n";
    print "                         information for debugging purposes\n\n";

    print "--verbose                This option prints out the path information\n";
    print "                         to a file in your config directory.\n\n";    
    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: findNumberOfCloserConcepts.pl,v 1.3 2011/08/29 16:37:03 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findNumberofCloserConcepts.pl --help for help.\n";
}
    
