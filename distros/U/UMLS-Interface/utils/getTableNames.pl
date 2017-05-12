#!/usr/bin/perl 

=head1 NAME

getTableNames.pl - This program returns the table names associated 
with a specified configuration file or all that have been created

=head1 SYNOPSIS

This program returns the table names associated with a specified 
configuration file or all that have been created

=head1 USAGE

Usage: getTableNames.pl [OPTIONS] 

=head1 INPUT

=head2 Optional Arguments:

=head3 --config FILE

This is the configuration file. The format of the configuration 
file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

SAB :: include MSH
REL :: include RB, RN

or 

SAB :: include MSH
REL :: exclude PAR, CHD

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

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

my $umls = "";                          
my %option_hash = ();     
           
if(defined $opt_config) { 
    $option_hash{"config"} = $opt_config;
}   
if(defined $opt_debug) { 
    $option_hash{"debug"} = $opt_debug;
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

if(defined $opt_config) {
    my $hashRef = $umls->returnTableNames();
    
    my $hashkeys = keys %{$hashRef};
    if($hashkeys > 0) {
	print "\nThe tables associated with the given configuration file are as follows:\n\n";
	print "    Table\t\t\t\t\tTable Name\n";
	foreach my $name (sort keys %{$hashRef}) {
	    print "    ${$hashRef}{$name}\t$name\n";
	}
    }
    else {
	print "There are no tables created for this configuration\n";
    }
}
else {
    my $database = "umlsinterfaceindex";    
    my $sdb = "";    
    
    if(defined $self->{'username'}) {       
	$sdb = DBI->connect("DBI:mysql:database=$database;mysql_socket=$socket;host\=$hostname",$username, $password, {RaiseError => 1});  
    }                
    else {           
	my $dsn = "DBI:mysql:$database;mysql_read_default_group=client;";  
	$sdb = DBI->connect($dsn);          
    }                
    
    print "\nTable\t\t\t\t\t\tTable Name\n";
    my $sql = qq{ select TABLENAME, HEX from tableindex};    
    my $sth = $sdb->prepare( $sql );        
    $sth->execute(); 
    my($name, $hex); 
    $sth->bind_columns( undef, \$name, \$hex);               
    while( $sth->fetch() ) {                
	print "$hex\t$name\n";              
    } $sth->finish();
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: getTableNames.pl [OPTIONS]\n\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that returns the table names\n";
    print "created for a given configuration file\n\n";
  
    print "Usage: getTableNames.pl [OPTIONS] \n\n";

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
    print '$Id: getTableNames.pl,v 1.7 2011/08/29 16:37:03 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type getTableNames.pl --help for help.\n";
}
    
