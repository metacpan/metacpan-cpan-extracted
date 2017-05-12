#!/usr/bin/perl 

=head1 NAME

findShortestPath.pl - This program finds the shoretest path between two 
concepts.

=head1 SYNOPSIS

This program takes two terms or CUIs and returns the shortest 
path between them.

=head1 USAGE

Usage: findShortestPath.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]

=head1 INPUT

=head2 Required Arguments:

=head3 [CUI1|TERM1|ST1] [CUI2|TERM2|ST2]

A TERM or CUI (or some combination), or two semantic types (with the --st option) 
from the Unified Medical Language System

=head2 Optional Arguments:

=head3 --st 

The input is two seamntic types and the shortest path between them comes 
from the semantic network. This can either be a TUI or the Abbreviation 
of the semantic type.    

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

=head3 --undirected

The path between the concepts is not required to be directed such 
that an LCS can be obtained. This means that we can obtain a path 
from CUI1 to CUI2 by meandering through the graph rather than 
finding the CUI that subsumes both of them and then finding the 
shortest path between those points. 

=head3 --info

This prints out the relation and source information between the 
CUIs in the path

=head3 --icpropagation FILE

Takes in a propagation file and then outputs the information 
content of the CUIs in the shortest path

=head3 --length

Prints out the length of the shortest path for ease of counting

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
config directory that you specified.

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

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "cui", "infile=s", "forcerun", "verbose", "debugpath=s", "cuilist=s", "realtime", "debug", "icpropagation=s", "length", "info", "undirected", "st")) or die ("Please check the above mentioned option(s).\n");


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

#  the --info option is only available for the CUI heirarchy
if( (defined $opt_st) && (defined $opt_info) ) {
    print STDERR "The --info option is not available for the semantic network.\n";
    &minimalUsageNotes();
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

if(defined $opt_icpropagation) {
    $option_hash{"icpropagation"} = $opt_icpropagation;
}
if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug;
}
if(defined $opt_realtime) {
    $option_hash{"realtime"} = $opt_realtime;
}
if(defined $opt_undirected) {
    $option_hash{"undirected"} = $opt_undirected;
    $option_hash{"realtime"} = 1; 
}
if(defined $opt_config) {
    $option_hash{"config"} = $opt_config;
}
if(defined $opt_forcerun) {
    $option_hash{"forcerun"} = $opt_forcerun;
}
if(defined $opt_debugpath) {
    $option_hash{"debugpath"} = $opt_debugpath;
}
if(defined $opt_verbose) {
    $option_hash{"verbose"} = $opt_verbose;
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
    
    my $flag1 = "cui";
    my $flag2 = "cui";
    
    my $c1 = undef; my $c2 = undef;

    if(defined $opt_st) { 
	if($input1=~/T[0-9]+/) { push @{$c1}, $input1; }
       	else { push @{$c1}, $umls->getStTui($input1); $flag1 = "term"; }

	if($input2=~/T[0-9]+/) { push @{$c2}, $input2; }
	else { push @{$c2}, $umls->getStTui($input2); $flag2 = "term"; }
    }
    else {
	if( ($input1=~/C[0-9]+/)) { push @{$c1}, $input1; }
	else { $c1 = $umls->getConceptList($input1); $flag1 = "term"; }

	if( ($input2=~/C[0-9]+/)) { push @{$c2}, $input2; }
	else { $c2 = $umls->getConceptList($input2); $flag2 = "term"; }
    }
    
    
    my $printFlag = 0;
    my $precision = 4;      
    my $floatformat = join '', '%', '.', $precision, 'f';    
    foreach $cui1 (@{$c1}) {
	foreach $cui2 (@{$c2}) {
	   
	    my $t1 = $input1;
	    my $t2 = $input2;
	    
	    if($flag1 eq "cui") { 
		if($opt_st) { $t1 = $umls->getStAbr($cui1); }
		else { my $ts1 = $umls->getTermList($cui1); $t1 = shift @{$ts1}; }
	    }
	    if($flag2 eq "cui") { 
		if($opt_st) { $t2 = $umls->getStAbr($cui2); }
		else { my $ts2 = $umls->getTermList($cui2); $t2 = shift @{$ts2}; }
	    }
	    
	    my @shortestpaths = ();
	    if($cui1 eq $cui2) { 
		my $path = "$cui1 $cui2";
		push @shortestpaths, $path;
	    }
	    else {
		if(defined $opt_st) { $shortestpaths = $umls->stFindShortestPath($cui1, $cui2); }
		else                { $shortestpaths = $umls->findShortestPath($cui1, $cui2); }
	    }
	    
	    foreach my $path (@{$shortestpaths}) {
		my @shortestpath = split/\s+/, $path;
		
		
		my $length = $#shortestpath + 1;
		print "\nThe shortest path ";
		if(defined $opt_length) {
		    print "(length: $length) ";
		}
		print "between $t1 ($cui1) and $t2 ($cui2):\n";
		print "  => ";
		foreach my $i (0..$#shortestpath) {
		    #  get the concept
		    my $concept = $shortestpath[$i];
		
		    #  get one of the terms associated with the concept/st
		    my $t = "";
		    if(defined $opt_st) { $t = $umls->getStAbr($concept); }
		    else { $t = $umls->getAllPreferredTerm($concept); }
		    
		    #  print out the concept
		    print "$concept ($t) "; 
		    
		    #  if the propagation option was defined print out 
		    #  the propagation count and IC count
		    if(defined $opt_icpropagation) { 
			my $value = "";
			if(defined $opt_st) { $value = $umls->getStIC($concept); }
			else                { $value = $umls->getIC($concept);   }
       
			my $ic = sprintf $floatformat, $value;
			print "($ic) ";
		    }     
		    
		    #  if the info option was defined print out 
		    #  the relation and source information
		    if(!defined $opt_st) { 
			if( (defined $opt_info) and ($i < $#shortestpath) ) {
			    my $second = $shortestpath[$i+1];
			    my $relations = $umls->getRelationsBetweenCuis($concept, $second);
			    print " => @{$relations} => ";
			}
		    }
		}
		print "\n";
		
		$printFlag = 1;
	    }
	}
    }
    
    if( !($printFlag) ) {
	print "\n";
	print "There is not a path between $input1 and $input2\n";
	print "given the current view of the UMLS.\n\n";
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findShortestPath.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input two Terms or\n";
    print "CUIs and returns the shortest path between them.\n\n";
  
    print "Usage: findShortestPath.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]\n\n";

    print "Options:\n\n";

    print "--undirected             The path between the concepts is not \n";
    print "                         required to be directed.\n\n";

    print "--info                   Outputs the source and relation information\n";
    print "                         between the concepts in the path\n\n";

    print "--icpropagation FILE     Outputs the information content (IC) of\n";
    print "                         the CUIs in the path\n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";
    
    print "--debug                  Sets the debug flag for testing\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--socket STRING          Socket used by mysql (DEFAULT: /tmp.mysql.sock)\n\n";

    print "--config FILE            Configuration file\n\n";
    
    print "--realtime
               This option will not create a database of the\n";
    print "                         path information for all of concepts but just\n"; 
    print "                         obtain the information for the input concept\n\n";
    print "--forcerun               This option will bypass any command \n";
    print "                         prompts such as asking if you would \n";
    print "                         like to continue with the index \n";
    print "                         creation. \n\n";

    print "--debugpath FILE         This option prints out the path\n";
    print "                         information for debugging purposes\n\n";

    print "--verbose                This option prints out the path information\n";
    print "                         to a file in your config directory.\n\n";    
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
    print '$Id: findShortestPath.pl,v 1.26 2014/06/27 00:18:32 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findShortestPath.pl --help for help.\n";
}
    
