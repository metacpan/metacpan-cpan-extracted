#!/usr/bin/perl

=head1 NAME

getCuiList.pl - This program returns a list of CUIs based on the configuration 
file. 

=head1 SYNOPSIS

This program returns a list of CUIs based on the sources and relations 
specified in the configuration file.

=head1 USAGE

Usage: getCuiList.pl [OPTIONS] CONFIGFILE

=head1 INPUT

=head2 CONFIGFILE

This is the configuration file. The format of the configuration 
file is as follows:

 SAB :: <include|exclude> <source1, source2, ... sourceN>
 REL :: <include|exclude> <relation1, relation2, ... relationN>
 RELA :: <include|exclude> <rela1, rela2, .... relaN> (optional)

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

=head1 OUTPUT

List of CUIs that are associated with the input term

=head1 OPTIONAL ARGUMENTS: 

=head2 --children 

Returns the number of children of a given CUI. The format for just using 
--children is:

 CUI children

=head2 --parents

Returns the number of children of a given CUI. The format for just using 
--parents is:

 CUI parents

The format for using both --parents and --children is:

 CUI children|parents

=head2 --relations REL

Returns the number of relations of a given CUI. The REL input can be 
a list of comma seperated relations. For example:

  --relation "SIB,RO"

This would return the number of SIB and RO relations for a given concept 
in the format : CUI sib|ro

This option current can not be used with the --children and --parent 
option because if you want them just add them to the list. For example: 
--relation "SIB,PAR,CHD"

=head2 --term

Returns the terms associated with the CUI in the following format:

 CUI term1|term2|term3|...

If used with the --parents and/or --children options or the --relation 
options, the following format is returned:

 CUI children|parents|term1|term2|...

Remember children and parents is a number!

=head2 --st <semantic type abbreviation>

Returns only those CUIs with the specified semantic type

=head2 --sg <semantic group name>

Returns only those CUIs with the specified semantic group

=head2 --debug

Sets the debug flag for testing

=head2 --username STRING

Username is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head2 --password STRING

Password is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head2 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head2 --socket STRING

The socket your mysql is using. DEFAULT: /tmp/mysql.sock

=head2 --database STRING        

Database contain UMLS DEFAULT: umls

=head2 --help

Displays the quick summary of program options.

=head2 --version

Displays the version information.

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

eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "term", "st=s", "sg=s", "relations=s", "children", "parents")) or die ("Please check the above mentioned option(s).\n");


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
    print STDERR "Configuration file was not specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

if(defined $opt_relations && $opt_children) { 
    print STDERR "The --relation and --children option can not be used\n";
    print STDERR "together. Just add CHD to your relations. For example:\n";
    print STDERR "    --relations \"SIB,PAR,CHD\"\n";   
    &minimalUsageNotes();
    exit;
}

if(defined $opt_relations && $opt_parents) { 
    print STDERR "The --relation and --parents option can not be used\n";
    print STDERR "together. Just add CHD to your relations. For example:\n";
    print STDERR "    --relations \"SIB,PAR,CHD\"\n";   
    &minimalUsageNotes();
    exit;
}
	

my $config = shift;

my %option_hash = ();

$option_hash{"config"} = $config;

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

my $hashref = $umls->getCuiList();

foreach my $cui (sort keys %{$hashref}) {
    #  flag to determine whether the cui is to be printed
    my $flag = 1;

    #  if --st, check to make certain the cui is of the 
    #  appropriate semantic type
    if(defined $opt_st) {
	$flag = 0;
	my $sts = $umls->getSt($cui);
	foreach my $st (@{$sts}) { 
	    my $abbrev = $umls->getStAbr($st);
	    if($abbrev eq $opt_st) {
		$flag = 1;
	    }
	}
    }

    #  if --sg, check to make certain the cui is of the 
    #  appropriate semantic group
    if(defined $opt_sg) {
	$flag = 0;
	my $sgs = $umls->getSemanticGroup($cui);
	foreach my $sg (@{$sgs}) { 
	    if($sg eq $opt_sg) { 
		$flag = 1;
	    }
	}
    }
    
    if($flag == 0) { next; }

    my @output = ();
    
    if(defined $opt_term) {
	$terms = $umls->getTermList($cui); 
	@output = @{$terms};
    }

    if(defined $opt_parents) { 
	my $array   = $umls->getParents($cui);
	my $parents = $#{$array} + 1;
	unshift @output, $parents;
    }
    
    if(defined $opt_children) { 
	my $array    = $umls->getChildren($cui);
	my $children = $#{$array} + 1;
	unshift @output, $children;
    }
    
    if(defined $opt_relations) { 
	my @relations = split/\,/, $opt_relations;
	foreach my $relation (reverse @relations) {
	    my $array = $umls->getRelated($cui, $relation);
	    my $rel   = $#{$array}+1;
	    unshift @output, $rel;
	}
    }	    
    
    if($#output >= 0) { 
	my $outputstring = join "|", @output;
	print "$cui $outputstring\n";
    }
    else { 
	print "$cui\n";
    }
    
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: getCuiList.pl [OPTIONS] CONFIGFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility returns all the CUIs associated with a\n";
    print "configuration file.\n\n";
  
    print "Usage: getCuiList.pl [OPTIONS] CONFIGFILE\n\n";

    print "Options:\n\n";
    
    print "--term                   Returns CUIs associated terms\n\n";

    print "--parents                Returns number of CUIs parents\n\n";
    
    print "--children               Returns number of CUIs children\n\n";

    print "--relations RELs         Returns the number of CUIs relations\n\n";

    print "--st <semantic type>     Returns CUIs with specified semantic\n";
    print "                         type\n\n";
    
    print "--sg <semantic group>    Returns CUIs with specified semantic\n";
    print "                         group\n\n";

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
    print '$Id: getCuiList.pl,v 1.10 2011/11/02 13:52:58 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type getCuiList.pl --help for help.\n";
}
    
