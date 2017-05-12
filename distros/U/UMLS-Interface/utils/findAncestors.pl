#!/usr/bin/perl

=head1 NAME

findAncestors.pl - This program returns the ancestors of a given CUI based on the configuration file. 

=head1 SYNOPSIS

This program returns a list of CUIs based on the sources and relations 
specified in the configuration file for a given CUI.

=head1 USAGE

Usage: findAncestors.pl [OPTIONS] CUI

=head1 INPUT

=head2 CUI

A CUI from the UMLS sources specified in the configuration 
file (or default source)

=head1 OUTPUT

List of CUIs that are the ancestors of the given term

=head1 OPTIONAL ARGUMENTS: 

=head2 --config

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

eval(GetOptions( "version", "help", "debug", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s")) or die ("Please check the above mentioned option(s).\n");


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
    print STDERR "CUI was not specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

my $cui = shift; 	

if(defined $opt_config) { 
    $option_hash{"config"} = $opt_config;
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

my $hashref = $umls->findAncestors($cui);

print "The ancestors of $cui are: \n\n";
foreach my $ancestor (sort keys %{$hashref}) {
    print "  $ancestor\n";
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findAncestors.pl [OPTIONS] CUI\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility returns all the CUIs associated with a\n";
    print "configuration file.\n\n";
  
    print "Usage: findAncestors.pl [OPTIONS] CUI\n\n";

    print "Options:\n\n";
    
    print "--config                 Configuration file\n\n";

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
    print '$Id: findAncestors.pl,v 1.2 2015/06/25 14:01:28 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findAncestors.pl --help for help.\n";
}
    
