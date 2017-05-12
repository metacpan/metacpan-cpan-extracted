#!/usr/bin/perl

=head1 NAME

create-icfrequency.pl - This program sums the frequency counts 
of the CUIs from a specified set of sources in plain text.

=head1 SYNOPSIS

This program sums the frequency counts of the CUIs from a specified 
set of sources in plain text. The CUIs are determined by mapping 
the words in the text to CUIs in the UMLS using the strings in 
the MRCONSO table or MetaMap. 

=head1 USAGE

Usage: create-icfrequency.pl.pl [OPTIONS] OUTPUTFILE INPUTFILE

=head2 OUTPUTFILE

The output file contains frequency counts for CUIs in the following 
format: 

    SAB :: (include|exclude) <sources>
    REL :: (include|exclude) <relations>
    N :: NUMBER
    CUI<>freq
    CUI<>freq
    ...

=head2 INPUTFILE

File containing plain text. 

=head2 Optional Arguments:

=head3 --st

Output the semantic type of the CUIs and their frequency counts.
The concepts are determined based on the source/relations in 
the configuration file so I would recommend using UMLS_ALL with 
the PAR/CHD/RB/RN relations unless you are certain of your 
source. 

=head3 --compoundify

The text contains compounds depicted by an underscore. For example,
the term blood_pressure would be counted as a single term rather 
than blood and then pressure. 

=head3 --term

Obtains the CUI counts using the term counts. This is the default.

=head3 --metamap TWO_DIGIT_YEAR

This option takes the two digit year of the version of metamap that 
is being used. For example, --metamap 10 would use ./metamap10 to 
call metamap to tag the text. 

This obtains the CUI counts using MetaMap. This requires that you have 
MetaMap installed on your system. You can obtain this package:

L<http://mmtx.nlm.nih.gov/>

These frequency counts are used to obtain the propagation counts.
The format is similar to the output of count.pl from Text::NSP
using the unigram option.

=head3 --config FILE

This is the configuration file. The format of the configuration 
file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

For example, if we wanted to include on those CUIs in the 
MSH vocabulary: 

SAB :: include MSH
REL :: include RB, RN

or maybe use all the CUIs except those in MSH:

SAB :: exclude MSH


If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

=head3 --username STRING

Username is required to access the umls database on MySql
Note: if --username is specified the --password is also 
required.

=head3 --password STRING

Password is required to access the umls database on MySql
Note: if --password is specified the --username is also 
required. 

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head3 --debug

Sets the UMLS-Interface debug flag on for testing

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 PROPAGATION

The Information Content (IC) is  defined as the negative log 
of the probability of a concept. The probability of a concept, 
c, is determine by summing the probability of the concept 
ocurring in some text plus the probability its decendants 
occuring in some text:

For more information on how this is calculated please see 
the README file or the perldoc for create-icpropagation.pl

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Similarity

=item * Text::NSP - http://search.cpan.org/dist/Text-NSP

=item * MetaMap - http://mmtx.nlm.nih.gov/

=back

=head1 CONTACT US

  If you have any trouble installing and using CreatePropagationFile, 
  please contact us via the users mailing list :
    
      umls-similarity@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-similarity/
     
  You may also contact us directly if you prefer :
    
      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2011,

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
use File::Path;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "debug", "t", "metamap=s", "term", "compoundify", "st")) or die ("Please check the above mentioned option(s).\n");

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

# At least 2 terms should be given on the command line.
if( scalar(@ARGV) < 2) { 
    print STDERR "At least 2 files should be specified on the command line.\n";
    &minimalUsageNotes();
    exit;
}

#  get the input and output files
my $outputfile = shift;
my $inputfile = shift;

# check to see if output file exists, and if so, if we should overwrite...
if ( -e $outputfile )
{
    print "Output file $outputfile already exists! Overwrite (Y/N)? ";
    $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}

#  initialize variables
my $database    = "";
my $hostname    = "";
my $socket      = "";    
my $umls        = "";

#  initialize the total number of unigrams
my $N = 0;

#  check the options 
&checkOptions       ();
&setOptions         ();

#  load the UMLS
&loadUMLS           ();

my $sabstring = $umls->getSabString();
my $relstring = $umls->getRelString();
my $relastring = $umls->getRelaString();

#  get the frequency counts
my $cuilist = $umls->getCuiList();

if(defined $opt_metamap) { 
    
    if(! ($opt_metamap=~/[0-9][0-9]/) ) {
	print STDERR "The --metamap option requires a two digit year.\n";
	&minimalUsageNotes();
	exit;
    }
    &getMetaMapCounts($inputfile);
}
else {
    &getTermCounts($inputfile);
}

if(defined $opt_st) {
    &printStPropagationCounts();
}
else { 
    &printCuiPropagationCounts();
}

sub printStPropagationCounts { 

    my %stlist = (); my $N = 0;
    foreach my $cui (sort keys %{$cuilist}) {
	my $freq = ${$cuilist}{$cui};    
	my $sts   = $umls->getSt($cui);
	
	foreach my $st (@{$sts}) { 
	    if(exists $stlist{$st}) { $stlist{$st} += $freq; }
	    else                    { $stlist{$st}  = $freq; }
	    $N+= $freq;
	}
    }		

    open(OUTPUT, ">$outputfile") || die "Could not open $outputfile\n";
    print OUTPUT "$sabstring\n";
    print OUTPUT "$relstring\n";
    if($relastring ne "") {
	print OUTPUT "$relastring\n";
    }
    print OUTPUT "N :: $N\n";
    foreach my $st (sort keys %stlist) { 
	my $freq = $stlist{$st};    
	print OUTPUT "$st<>$freq\n";
    }
    close OUTPUT;
}

sub printCuiPropagationCounts { 
    
    open(OUTPUT, ">$outputfile") || die "Could not open $outputfile\n";
    print OUTPUT "$sabstring\n";
    print OUTPUT "$relstring\n";
    if($relastring ne "") {
	print OUTPUT "$relastring\n";
    }
    print OUTPUT "N :: $N\n";
    foreach my $cui (sort keys %{$cuilist}) {
	my $freq = ${$cuilist}{$cui};    
	print OUTPUT "$cui<>$freq\n";
    }
    close OUTPUT;
}

sub getTermCounts {

    my $text = shift;

    my $countfile = "tmp.count";
    
    system "count.pl --ngram 1 $countfile $text";
    
    open(COUNT, $countfile) || die "Could not open the count file : $countfile\n";
    my %hash = ();

    my $header = <COUNT>;
    while(<COUNT>) {
	chomp;
	my ($term, $freq) = split/<>/;

	if(defined $opt_compoundify) { 
	    $term=~s/_/ /g;
	}

	my $cuis = $umls->getConceptList($term); 

	foreach my $cui (@{$cuis}) {
	    if(exists ${$cuilist}{$cui}) {
		${$cuilist}{$cui} += $freq;
		$N += $freq;
	    }
	}
    }
    close COUNT;
    
    File::Path->remove_tree("tmp.count");
    
    return \%hash;
}



sub getMetaMapCounts {

    my $text = shift;
    open(TEXT, $text) || die "Could not open $text for processing\n";
    
    my %hash = ();
    while(<TEXT>) {
	chomp;
	my $output = &callMetaMap($_);
	
	my %temp = ();
	while($output=~/\'(C[0-9]+)\'\,(.*?)\,(.*?)\,/g) {
	    my $cui = $1; my $str = $3;
	    $str=~s/[\'\"]//g;
	    $temp{$cui}++;
	}
	foreach my $cui (sort keys %temp) {
	    if(exists ${$cuilist}{$cui}) {
		${$cuilist}{$cui}++;
		$N++;
	    }
	}
    }
    
    return \%hash;
}

sub callMetaMap 
{
    my $line = shift;
    
    my $output = "";
	
    my $timestamp = &timeStamp();
    my $metamapInput  = "tmp.metamap.input.$timestamp";
    my $metamapOutput = "tmp.metamap.output.$timestamp";
    
    open(METAMAP_INPUT, ">$metamapInput") || die "Could not open file: $metamapInput\n";
    
    print METAMAP_INPUT "$line\n"; 
    close METAMAP_INPUT;
    
    my $metamap = "metamap" . $opt_metamap;
    print "$metamap -q $metamapInput $metamapOutput\n";
    system("$metamap -q $metamapInput $metamapOutput");

    open(METAMAP_OUTPUT, $metamapOutput) || die "Could not open file: $metamapOutput\n";
    
    while(<METAMAP_OUTPUT>) { 
	if($_=~/mappings\(/) {
	    $output .= $_; 
	}
    }
    close METAMAP_OUTPUT;
    
    File::Path->remove_tree($metamapInput);
    File::Path->remove_tree($metamapOutput);

    return $output;
}
sub timeStamp {
    my ($stamp);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    
    $year += 1900;
    $mon++;
    $d = sprintf("%4d%2.2d%2.2d",$year,$mon,$mday);
    $t = sprintf("%2.2d%2.2d%2.2d",$hour,$min,$sec);
    
    $stamp = $d . $t;
    return($stamp);
}


#  checks the user input options
sub checkOptions {

    if( (defined $opt_metamap) && (defined $opt_term) ) { 
	print STDERR "The --metamap and --term options can\n";
	print STDERR "not both be specified at the same time.\n\n";
	&minimalUsageNotes();
	exit;
    }

    if( (defined  $opt_username && !defined $opt_password) || 
	(!defined $opt_username && defined  $opt_password) ) {
	print STDERR "The --username and --password options\n";
	print STDERR "must both be specified if you are using\n";
	print STDERR "one of them.\n\n";
	&minimalUsageNotes();
	exit;
    }	
}

#  set user input and default options
sub setOptions {

    if($debug) { print STDERR "In setOptions\n"; }

    my $default = "";
    my $set     = "";

    #  check config file
    if(defined $opt_config) {
	$config = $opt_config;
	$set .= "  --config $config\n";
    }

    if(defined $opt_metamap) { 
	$set .= "  --metamap $opt_metamap\n";
    }
    elsif(defined $opt_term) {
	$set .= "  --term\n";
    }
    else {
	$default .= "  --term\n";
    }
    
    if(defined $opt_compoundify) { 
	$set .= "  --compoundify\n";
    }
    
    if(defined $opt_st) { 
	$set .= "  --st\n";
    }

    #  set database options
    if(defined $opt_username) {

	if(defined $opt_username) {
	    $set     .= "  --username $opt_username\n";
	}
	if(defined $opt_password) {
	    $set     .= "  --password XXXXXXX\n";
	}
	if(defined $opt_database) {
	    $database = $opt_database;
	    $set     .= "  --database $database\n";
	}
	else {
	    $database = "umls";
	    $default .= "  --database $database\n";
	}

	if(defined $opt_hostname) {
	    $hostname = $opt_hostname;
	    $set     .= "  --hostname $hostname\n";
	}
	else {
	    $hostname = "localhost";
	    $default .= "  --hostname $hostname\n";
	}
	
	if(defined $opt_socket) {
	    $socket = $opt_socket;
	    $set   .= "  --socket $socket\n";
	}
	else {
	    $socket   = "/tmp/mysql.sock\n";
	    $default .= "  --socket $socket\n";
	}
    } 
    
    
    if(defined $opt_debug) { 
	$set .= "  --debug\n";
    }
    
    #  check settings
    if($default eq "") { $default = "  No default settings\n"; }
    if($set     eq "") { $set     = "  No user defined settings\n"; }
    
    #  print options
    print STDERR "Default Settings:\n";
    print STDERR "$default\n";
    
    print STDERR "User Settings:\n";
    print STDERR "$set\n";
}

#  load the UMLS
sub loadUMLS {
 
    if(defined $opt_t) { 
	$option_hash{"t"} = 1;
    }
    if(defined $opt_config) {
	$option_hash{"config"} = $opt_config;
    }
    if(defined $opt_debug) {
	$option_hash{"debug"} = $opt_debug;
    }
    
    if(defined $opt_username and defined $opt_password) {
	$option_hash{"driver"}   = "mysql";
	$option_hash{"database"} = $database;
	$option_hash{"username"} = $opt_username;
	$option_hash{"password"} = $opt_password;
	$option_hash{"hostname"} = $hostname;
	$option_hash{"socket"}   = $socket;
    }
    
    $option_hash{"realtime"} = 1;

    $umls = UMLS::Interface->new(\%option_hash); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: create-icfrequency.pl.pl [OPTIONS] OUTPUTFILE INPUTFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input an output and input\n";
    print "file and determines the frequency counts of the CUIs in\n";
    print "a specified set of sources and relation using the frequency\n";
    print "information from the inputfile\n\n";
  
    print "Usage: create-icfrequency.pl.pl [OPTIONS] OUTPUTFILE INPUTFILE\n\n";

    print "Options:\n\n";

    print "--config FILE            Configuration file\n\n";

    print "--st                     Output the semantic type of the CUIs \n";
    print "                         and their frequency counts.\n\n";

    print "--compoundify            The input text contains compounds\n";
    print "                         depicted by an underscore. \n\n";

    print "--term                   Calculates the frequency counts using\n";
    print "                         the words in the input file. (DEFAULT)\n\n";

    print "--metamap TWO_DIGIT_YEAR Calculates the frequency counts using\n";
    print "                         the CUIs assigned to terms by MetaMap.\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";

    print "--debug                  Sets the UMLS-Interface debug flag on\n";
    print "                         for testing purposes\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: create-icfrequency.pl,v 1.17 2015/10/04 14:35:59 btmcinnes Exp $';
    print "\nCopyright (c) 2008-2011, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type create-icfrequency.pl.pl --help for help.\n";
}
    
