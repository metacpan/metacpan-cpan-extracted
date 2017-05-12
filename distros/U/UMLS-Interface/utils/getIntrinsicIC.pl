#!/usr/bin/perl 

=head1 NAME

getIntrinsicIC.pl - This program returns the intrinsic information content of a concept or a term.

=head1 SYNOPSIS

This program takes in a CUI or a term and returns its intrinsic information
content. 

=head1 USAGE

Usage: getIntrinsicIC.pl [OPTION] [CUI|TERM]

=head1 INPUT

=head2 Required Arguments:

=head3 [CUI|TERM}

Concept Unique Identifier (CUI) or a term from the Unified Medical 
Language System (UMLS)

=head2 Optional Arguments:

=head3 --sanchez

Use the formula proposed by Sanchez and Betet 2011

=head3 --seco [default]

Use the formula proposed by Seco, Veale and Hayes 2005

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

Takes a file of CUIs (one per line) and returns their information 
content.

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

=head4 --help

Displays the quick summary of program options.

=head4 --version

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

eval(GetOptions( "version", "help", "debug", "infile=s", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "sanchez", "seco")) or die ("Please check the above mentioned option(s).\n");


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

# At least 1 CUI should be given on the command line.
if(!(defined $opt_infile) && scalar(@ARGV) < 1) {
    print STDERR "No term or file was specified on the command line\n";
    &minimalUsageNotes();
    exit;
}


my $umls = "";
my %option_hash = ();

if(defined $opt_config) {
    $option_hash{"config"} = $opt_config;
}
if(defined $opt_verbose) {
    $option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug;
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

$umls->setPropagationParameters(\%option_hash);

my @array = ();
if(defined $opt_infile) { 
    open(FILE, $opt_infile) || die "Could not open $opt_infile\n";
    while(<FILE>) {
	chomp;
	push @array, $_;
    }
}
else {
    my $input = shift;
    push @array, $input;
}

foreach my $input (@array) { 
    my $term  = $input;
    my $c     = undef;

    if($input=~/C[0-9]+/) {
	push @{$c}, $input;
	my $terms = $umls->getConceptList($input);
	$term = shift @{$terms};
    }
    else {
	$c = $umls->getConceptList($input);
    }
    
    my $printFlag = 0;
    my $precision = 4;
    my $floatformat = join '', '%', '.', $precision, 'f';
    foreach my $cui (@{$c}) {
	#  make certain cui exists in this view
	if($umls->exists($cui) == 0) { print STDERR "$cui\n"; next; }	
	
	my $ic = 0; 

	if(defined $opt_sanchez) { 
	    $ic = $umls->getSanchezIntrinsicIC($cui); 
	}
	else { 
	    $ic = $umls->getSecoIntrinsicIC($cui); 
	}
	#    my $pic = sprintf $floatformat, $ic;
	#    my $pprob = sprintf $floatformat, $prob;
	
	print "The intrinsic information content of $term ($cui) is $ic\n";
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: getIntrinsicIC.pl [OPTIONS] [CUI|TERM] \n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input a term \n";
    print "or a CUI and returns its intrinsic information content (IC).\n\n";
  
    print "Usage: getIntrinsicIC.pl [OPTIONS] [CUI|TERM]\n\n";

    print "Options:\n\n";

    print "--config FILE            Configuration file\n\n";

    print "--debug                  Sets the debug flag for testing\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--socket STRING          Socket used by mysql (DEFAULT: /tmp.mysql.sock)\n\n";

    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: getIntrinsicIC.pl,v 1.2 2013/04/08 11:35:23 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type getIntrinsicIC.pl --help for help.\n";
}
    
