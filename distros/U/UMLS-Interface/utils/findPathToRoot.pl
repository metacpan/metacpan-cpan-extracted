#!/usr/bin/perl 

=head1 NAME

findPathToRoot.pl - This program returns all possible paths 
from a given CUI to the root.

=head1 SYNOPSIS

This program takes a CUI or a term and returns all of possible 
paths to the root.

=head1 USAGE

Usage: findPathToRoot.pl [OPTIONS] [CUI|TERM|ST]

=head1 INPUT

=head2 Required Arguments:

=head3 [CUI|TERM|ST]

A concept (CUI), a term or a semantic type (using the --st option) from the 
Unified Medical Language System. 

=head2 Optional Arguments:

=head3 --st 

The input is a semantic type and the path to root information is obtained 
from the semantic network. This can either be a TUI or the Abbrevation of 
the semantic type. 

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

=head3 --infile

File containing a list of CUIs or terms. Each CUI or term 
is required to be on its own line. For example:

CUI1
term1
CUI2
CUI3
...

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

=head3 --verbose

This option will print out the table information to the 
config file that you specified.

=head3 --cuilist FILE

This option takes in a file containing a list of CUIs (one CUI 
per line) and stores only the path information for those CUIs 
rather than for all of the CUIs given the specified set of 
sources and relations

=head3 --info

This prints out the relation and source information between the 
CUIs in the path. This option is only available for the CUI 
network. 

=head3 --icpropagation FILE

Takes in a propagation file and then outputs the information 
content of the CUIs in the shortest path

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 OUTPUT

Path(s) from given CUIor term to the root

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

eval(GetOptions( "version", "help", "forcerun", "debug", "infile=s", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "verbose", "debugpath=s", "cuilist=s", "realtime", "icpropagation=s", "info", "st")) or die ("Please check the above mentioned option(s).\n");


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
if( (!(defined $opt_infile)) and (scalar(@ARGV) < 1) ) {
    print STDERR "No term was specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

if( (defined $opt_info) && (defined $opt_st) ) {
    print STDERR "The --info option is not available for the semantic network.\n";
    &minimalUsageNotes();
    exit;
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

my @inputarray = ();
if(defined $opt_infile) {
    open(FILE, $opt_infile) || die "Could not open infile $opt_infile\n";
    while(<FILE>) { 
	chomp; 
	$_=~s/^\s+//g;
	$_=~s/\s+$//g;
	push @inputarray, $_;
    }
}
else {
    my $input = shift;
    push @inputarray, $input;
}

foreach my $input (@inputarray) {
    my $term  = $input;
    
    my $c = undef;
    if(defined $opt_st) { 
	if($input=~/T[0-9]+/) { 
	    push @{$c}, $input;
	    $term = $umls->getStAbr($input);
	}
	else { 
	    push @{$c}, $umls->getStTui($input);
	}
    }
    else {
	if($input=~/C[0-9]+/) {
	    push @{$c}, $input;
	    $term = shift @{$umls->getTermList($input)};
	}
	else {
	    $c = $umls->getConceptList($input);
	}
    }
    
    my $printFlag = 0; 
    my $precision = 4;
    my $floatformat = join '', '%', '.', $precision, 'f';
   
    foreach my $cui (@{$c}) {
		
	#  make certain cui exists in this view
	
	if( (!defined $opt_st) && ($umls->exists($cui) == 0) ) { next; }
	
	my $paths = "";
	if(defined $opt_st) { 
	    $paths = $umls->stPathsToRoot($cui);
	}
	else {
	    $paths = $umls->pathsToRoot($cui);
	}
	
	if($#{$paths} < 0) {
	    print "There are no paths between $term ($cui) and the root.\n";
	    $printFlag = 1;
	}
	else {
	    print "The paths between $term ($cui) and the root:\n";
	    foreach  $path (@{$paths}) {
	    my @array = split/\s+/, $path;
	    print "  => ";
	    foreach my $i (0..$#array){
		my $element = $array[$i];
		my $t = "";
		if(defined $opt_st) { 
		    $t = $umls->getStAbr($element);
		}
		else {
		    ($t) = shift @{$umls->getTermList($element)}; 
		}
		print "$element ($t) ";
		if(defined $opt_icpropagation) {
		    my $value = $umls->getIC($element);
		    my $ic = sprintf $floatformat, $value;
		    print "($ic) ";
		}
		if( (defined $opt_info) and ($i < $#array) ) {
		    my $second = $array[$i+1];
		    my $relations = $umls->getRelationsBetweenCuis($element, $second);
		    print " => @{$relations} => ";
		}
	    } print "\n";
	    
	    $printFlag = 1;
	    }
	}
    }
    
    if(! ($printFlag) ) {
	print "There are no paths from the given $input to the root.\n";
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findPathToRoot.pl [OPTIONS] [CUI|TERM]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input a CUI or a \n";
    print "term and returns all possible paths to the root.\n\n";
  
    print "Usage: findPathToRoot.pl [OPTIONS] [CUI|TERM]\n\n";

    print "Options:\n\n";
                                     
    print "--st                     The input is a semantic type\n\n";

    print "--debug                  Sets the debug flag for testing\n\n";

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

    print "--verbose                This option prints out the table information\n";
    print "                         to a file in your config directory.\n\n";    

    print "--cuilist FILE           This option takes in a file containing a \n";
    print "                         list of CUIs (one CUI per line) and stores\n";
    print "                         only the path information for those CUIs\n"; 
    print "                         rather than for all of the CUIs\n\n";

    print "--info                   This prints out the relation and source \n";
    print "                         information between the CUIs in the path\n\n";

    print "--icpropagation FILE     This option returns the information content\n";
    print "                         of the CUIs in the path based on the counts\n";
    print "                         from the propogation file\n\n";

    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: findPathToRoot.pl,v 1.25 2011/08/29 16:37:03 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findPathToRoot.pl --help for help.\n";
}
    
