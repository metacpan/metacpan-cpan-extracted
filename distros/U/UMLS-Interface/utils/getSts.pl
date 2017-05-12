#!/usr/bin/perl 

=head1 NAME

getSts.pl - This program returns a concepts semantic type(s).

=head1 SYNOPSIS

This program takes in a CUI or a TERM and returns its semantic type(s).

=head1 USAGE

Usage: getSts.pl [OPTIONS] [TERM|CUI]

=head1 INPUT

=head2 Required Arguments:

=head3 [TERM|CUI]

A Concept Unique Identifier (CUI) or a term from the Unified 
Medical Language System (UMLS)

=head2 Optional Arguments:

=head3 --infile FILE

A file containing a list of concepts or terms. The format requires 
a single concept and/or term per line. For example:
  
  cui1
  term1
  cui2
  term2
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

eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "infile=s", "all", "sg")) or die ("Please check the above mentioned option(s).\n");


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

# At least 1 term or cui  should be given on the command line.
# unless the infile option was specified
if( !(defined $opt_infile) and !(defined $opt_all) and (scalar(@ARGV) < 1) ) {
    print STDERR "At least 1 term or CUI should be given on the \n";
    print STDERR "command line or use the --infile option\n";
    &minimalUsageNotes();
    exit;
}

my $umls = "";
my %option_hash = ();

if(defined $opt_verbose) {
    $option_hash{"verbose"} = $opt_verbose;
}
if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug
}
if(defined $opt_username) {
    $option_hash{"username"} = $opt_username;
}
if(defined $opt_driver) {
    $option_hash{"driver"}   = $opt_driver; #mysql
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

$option_hash{"t"} = 1;
$umls = UMLS::Interface->new(\%option_hash); 
die "Unable to create UMLS::Interface object.\n" if(!$umls);

if(defined $opt_all) { 
    
    my $sts = $umls->getAllSts();
    
    foreach my $st (@{$sts}) {
	my $abr = $umls->getStAbr($st);
	my $string = $umls->getStString($abr);
	print "  $string ($abr) ($st)\n";
    }
    exit; 
}

my @terms = ();
if(defined $opt_infile) { 
    open(INFILE, $opt_infile) || die "Could not open infile ($opt_infile)\n";
    while(<INFILE>) { 
	chomp;
	push @terms, $_;
    } close INFILE;
}
else {
    my $term = shift;
    push @terms, $term;
}

if(defined $opt_sg) { 
    
    foreach my $input (@terms) { 
	
	my $array = $umls->getStsFromSg($input); 

	print "The semantic types associated with $input : \n"; 
	foreach my $abr (@{$array}) {
	    my $string = $umls->getStString($abr);
	    print "  $string ($abr)\n";
	}	
	
    }
    
}
else { 

    foreach my $input (@terms) {
	
	my $c = undef;
	if($input=~/C[0-9]/) {
	    push @{$c}, $input;
	    my $ts = $umls->getTermList($input);
	    $term = shift @{$ts};
	}
	else {
	    $c = $umls->getConceptList($input);
	}
	
	my $printFlag = 0;
	
	foreach my $cui (@{$c}) {
	    
	    my $sts = $umls->getSt($cui);
	    
	    if($#{$sts} < 0) {
		print "There are no semantic types associated with $term ($cui)\n";
	    }
	    else {
		print "The semantic types associated with $term ($cui):\n";
		foreach my $st (@{$sts}) {
		    my $abr = $umls->getStAbr($st);
		    my $string = $umls->getStString($abr);
		    print "  $string ($abr)\n";
		}
	    }
	    $printFlag = 1;
	}
	
	if(! ($printFlag) ) {
	    print "There are no semantic types associated with $input\n";
	}
    }
}
##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: getSts.pl [OPTIONS] [TERM|CUI] \n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input a TERM or\n";
    print "a CUI and returns all of its semantic types.\n\n";
  
    print "Usage: getSts.pl [OPTIONS] [TERM|CUI]\n\n";

    print "Options:\n\n";
    
    print "--infile FILE            A file containing a list of concepts \n";
    print "                         or terms.\n\n";

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
    print '$Id: getSts.pl,v 1.17 2016/07/11 16:36:48 btmcinnes Exp $';
    print "\nCopyright (c) 2011, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type getSts.pl --help for help.\n";
}
    
