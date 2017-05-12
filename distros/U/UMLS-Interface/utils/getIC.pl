#!/usr/bin/perl 

=head1 NAME

getIC.pl - This program returns the information content of a concept or a term.

=head1 SYNOPSIS

This program takes in a CUI or a term and returns its information content.

=head1 USAGE

Usage: getIC.pl [OPTION] [CUI|TERM]

=head1 INPUT

=head2 Required Arguments:

=head3 [CUI|TERM}

Concept Unique Identifier (CUI) or a term from the Unified Medical 
Language System (UMLS)

=head2 Optional Arguments:

=head3 --intrinsic [seco|sanchez]

Uses intrinic information content of the CUIs defined by Sanchez and 
Betet 2011 or Seco, et al 2004.

=head3 --icfrequency

Calculate information content using the frequency information 
in FILE. The file must be in the following format:

    CUI<>freq
    CUI<>freq

See the example files called icfrequency in the samples/ directory. 

=head3 --icpropagation FILE

Calculate information content using the probability information 
in FILE. The file must be in the following format:

    CUI<>prob
    CUI<>prob

See the example files called icpropagation in the samples/ directory. 

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


=head3 --smooth 

Incorporate Laplace smoothing, where the frequency count of each of the 
concepts in the taxonomy is incremented by one. The advantage of 
doing this is that it avoides having a concept that has a probability 
of zero. The disadvantage is that it can shift the overall probability 
mass of the concepts from what is actually seen in the corpus. 


=head3 --realtime

This option will not create a database of the information content 
for all of concepts in the specified set of sources and relations 
in the config file 

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

eval(GetOptions( "version", "help", "debug", "intrinsic=s", "infile=s", "icfrequency=s", "icpropagation=s", "realtime", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "smooth")) or die ("Please check the above mentioned option(s).\n");


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
if(scalar(@ARGV) < 1) {
    print STDERR "No term or file was specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

my $umls = "";
my %option_hash = ();

if(defined $opt_intrinsic) { 
    $option_hash{"intrinsic"} = $opt_intrinsic; 
}
elsif(defined $opt_icfrequency) { 
    $option_hash{"icfrequency"} = $opt_icfrequency;
}
else {
    $option_hash{"icpropagation"} = $opt_icpropagation;
}

if(defined $opt_realtime) {
    $option_hash{"realtime"} = $opt_realtime;
}
if(defined $opt_config) {
    $option_hash{"config"} = $opt_config;
}
if(defined $opt_smooth) {
    $option_hash{"smooth"} = $opt_smooth;
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
	
#  if the icpropagation or icfrequency option is not 
#  defined set the default options for icpropagation
if( (!defined $opt_intrinsic) &&
    (!defined $opt_icpropagation) &&
    (!defined $opt_icfrequency) ) {
    
    print STDERR "Setting default propagation file\n";
	    
    #  get the icfrequency file
    my $icfrequency = ""; foreach my $path (@INC) {
	if(-e $path."/UMLS/icfrequency.default.dat") { 
	    $icfrequency = $path."/UMLS/icfrequency.default.dat";
	}
	elsif(-e $path."\\UMLS\\icfrequency.default.dat") { 
	    $icfrequency =  $path."\\UMLS\\icfrequency.default.dat";
	}
    }
    
    #  set the cuilist
    my $fhash = $umls->getCuiList();
    
    #  load the frequency counts
    open(FILE, $icfrequency) || die "Could not open $icfrequency\n";
    while(<FILE>) { 
	chomp;
	my ($cui, $freq) = split/<>/;
	if(exists ${$fhash}{$cui}) { 
	    ${$fhash}{$cui} = $freq;
	}
    }
    
    #  propagate the counts
    my $phash = $umls->propagateCounts($fhash);
}

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
	if(defined $opt_intrinsic) { 
	    if($opt_intrinsic=~/seco/) { 
		$ic = $umls->getSecoIntrinsicIC($cui); 
	    }
	    else { 
		$ic = $umls->getSanchezIntrinsicIC($cui); 
	    }
	}
	else { 
	    $ic = $umls->getIC($cui); 
	}
	#    my $pic = sprintf $floatformat, $ic;
	#    my $pprob = sprintf $floatformat, $prob;
	
	print "The information content of $term ($cui) is $ic\n";
    }
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: getIC.pl [OPTIONS] [CUI|TERM] \n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input a term \n";
    print "or a CUI and returns its information content (IC).\n\n";
  
    print "Usage: getIC.pl [OPTIONS] IC | FREQUENCY FILE [CUI|TERM]\n\n";

    print "Options:\n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";    

    print "--intrinsic [seco|sanchez] Use the intrinsic IC defined either by\n";
    print "                           Seco et al 2004 or Sanchez et al 2011\n\n"; 

    print "--icfrequency            Flag specifying that a frequency file\n";
    print "                         was specified on the command line\n\n";

    print "--icpropagation          Flag specifiying that a propagation file\n";
    print "                         was specified (this is the DEFAULT)\n\n";

    print "--realtime               This option finds the information content\n";
    print "                         in realtime rather than building an index\n\n";

    print "--config FILE            Configuration file\n\n";

    print "--smooth                 Incorporate Laplace smoothing, when \n";
    print "                         calculating the probability of a concept\n\n";
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
    print '$Id: getIC.pl,v 1.20 2013/04/21 13:20:22 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type getIC.pl --help for help.\n";
}
    
