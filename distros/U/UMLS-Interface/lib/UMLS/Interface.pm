# UMLS::Interface 
# (Last Updated $Id: Interface.pm,v 1.152 2016/10/18 16:13:28 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2015,
#
# Bridget T. McInnes, University of Minnesota Twin Cities
# bthomson at cs.umn.edu
#
# Siddharth Patwardhan, University of Utah, Salt Lake City
# sidd at cs.utah.edu
# 
# Serguei Pakhomov, University of Minnesota Twin Cities
# pakh0002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota
# liux0935 at umn.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to 
#
# The Free Software Foundation, Inc., 
# 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.

=head1 NAME

UMLS::Interface - Perl interface to the Unified Medical Language System (UMLS)

=head1 SYNOPSIS

 use UMLS::Interface;

 $umls = UMLS::Interface->new(); 

 die "Unable to create UMLS::Interface object.\n" if(!$umls); 

 my $root = $umls->root();

 my $term1    = "skull";

 my $tList1   = $umls->getConceptList($term1);
 my $cui1     = pop @{$tList1};

 my $term2    = "hand";
 my $tList2   = $umls->getDefConceptList($term2);

 my $cui2     = shift @{$tList2};
 my $exists1  = $umls->exists($cui1);
 my $exists2  = $umls->exists($cui2);

 if($exists1) { print "The concept $term1 ($cui1) exists in your UMLS view.\n"; }
 else         { print "The concept $term1 ($cui1) does not exist in your UMLS view.\n"; }

 if($exists2) { print "The concept $term2 ($cui2) exists in your UMLS view.\n"; }
 else         { print "The concept $term2 ($cui2) does not exist in your UMLS view.\n"; }
 print "\n";

 my $cList1   = $umls->getTermList($cui1);
 my $cList2   = $umls->getDefTermList($cui2);

 print "The terms associated with $term1 ($cui1) using the SAB parameter:\n";
 foreach my $c1 (@{$cList1}) {
    print " => $c1\n";
 } print "\n";

 print "The terms associated with $term2 ($cui2) using the SABDEF parameter:\n";
 foreach my $c2 (@{$cList2}) {
    print " => $c2\n";
 } print "\n";

 my $lcs = $umls->findLeastCommonSubsumer($cui1, $cui2);
 print "The least common subsumer between $term1 ($cui1) and ";
 print "$term2 ($cui2) is @{$lcs}\n\n";

 my $shortestpath = $umls->findShortestPath($cui1, $cui2);
 print "The shortest path between $term1 ($cui1) and $term2 ($cui2):\n";
 print "  => @{$shortestpath}\n\n";

 my $pathstoroot   = $umls->pathsToRoot($cui1);
 print "The paths from $term1 ($cui1) and the root:\n";
 foreach  $path (@{$pathstoroot}) {
    print "  => $path\n";
 } print "\n";

 my $mindepth = $umls->findMinimumDepth($cui1);
 my $maxdepth = $umls->findMaximumDepth($cui1);
 print "The minimum depth of $term1 ($cui1) is $mindepth\n";
 print "The maximum depth of $term1 ($cui1) is $maxdepth\n\n";

 my $children = $umls->getChildren($cui2); 
 print "The child(ren) of $term2 ($cui2) are: @{$children}\n\n";

 my $parents = $umls->getParents($cui2);
 print "The parent(s) of $term2 ($cui2) are: @{$parents}\n\n";

 my $relations = $umls->getRelations($cui2);
 print "The relation(s) of $term2 ($cui2) are: @{$relations}\n\n";

 my $rels = $umls->getRelated($cui2, "PAR");
 print "The parents(s) of $term2 ($cui2) are: @{$rels}\n\n";

 my $definitions = $umls->getCuiDef($cui1);
 print "The definition(s) of $term1 ($cui1) are:\n";
 foreach $def (@{$definitions}) {
    print "  => $def\n"; $i++;
 } print "\n";

 my $sabs = $umls->getSab($cui1);

 print "The sources containing $term1 ($cui1) are: @{$sabs}\n\n";

 print "The semantic type(s) of $term1 ($cui1) and the semantic\n";

 print "definition are:\n";
 my $sts = $umls->getSt($cui1);
 foreach my $st (@{$sts}) {

    my $abr = $umls->getStAbr($st);
    my $string = $umls->getStString($abr);
    my $def    = $umls->getStDef($abr);
    print "  => $string ($abr) : @{$def}\n";

 } print "\n";

 $umls->removeConfigFiles();

 $umls->dropConfigTable();

=head1 ABSTRACT

This package provides a Perl interface to the Unified Medical Language 
System. The package is set up to access pre-specified sources of the UMLS
present in a mysql database.  The package was essentially created for use 
with the UMLS::Similarity package for measuring the semantic relatedness 
of concepts.

=head1 INSTALL

To install the module, run the following magic commands:

  perl Makefile.PL
  make
  make test
  make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 DESCRIPTION

This package provides a Perl interface to the Unified Medical 
Language System (UMLS). The UMLS is a knowledge representation 
framework encoded designed to support broad scope biomedical 
research queries. There exists three major sources in the UMLS. 
The Metathesaurus which is a taxonomy of medical concepts, the 
Semantic Network which categorizes concepts in the Metathesaurus, 
and the SPECIALIST Lexicon which contains a list of biomedical 
and general English terms used in the biomedical domain. The 
UMLS-Interface package is set up to access the Metathesaurus
and the Semantic Network present in a mysql database.

=head1 DATABASE SETUP

The interface assumes that the UMLS is present as a mysql database. 
The name of the database can be passed as configuration options at 
initialization. However, if the names of the databases are not 
provided at initialization, then default value is used -- the 
database for the UMLS is called 'umls'. 

The UMLS database must contain six tables: 
	1. MRREL
	2. MRCONSO
	3. MRSAB
	4. MRDOC
        5. MRDEF
        6. MRSTY
        7. SRDEF

All other tables in the databases will be ignored, and any of these
tables missing would raise an error.

A script explaining how to install the UMLS and the mysql database 
are in the INSTALL file.

=head1 INITIALIZING THE MODULE

To create an instance of the interface object, using default values
for all configuration options:

  use UMLS::Interface;
  my $interface = UMLS::Interface->new();

Database connection options can be passed through the my.cnf file. For 
example: 
           [client]
	    user            = <username>
	    password	    = <password>
	    port	    = 3306
	    socket          = /tmp/mysql.sock
	    database        = umls

Or through the by passing the connection information when first 
instantiating an instance. For example:

    $umls = UMLS::Interface->new({"driver" => "mysql", 
				  "database" => "$database", 
				  "username" => "$opt_username",  
				  "password" => "$opt_password", 
				  "hostname" => "$hostname", 
				  "socket"   => "$socket"}); 

  'driver'       -> Default value 'mysql'. This option specifies the Perl 
                    DBD driver that should be used to access the
                    database. This implies that the some other DBMS
                    system (such as PostgresSQL) could also be used,
                    as long as there exist Perl DBD drivers to
                    access the database.
  'umls'         -> Default value 'umls'. This option specifies the name
                    of the UMLS database.
  'hostname'     -> Default value 'localhost'. The name or the IP address
                    of the machine on which the database server is
                    running.
  'socket'       -> Default value '/tmp/mysql.sock'. The socket on which 
                    the database server is using.
  'port'         -> The port number on which the database server accepts
                    connections.
  'username'     -> Username to use to connect to the database server. If
                    not provided, the module attempts to connect as an
                    anonymous user.
  'password'     -> Password for access to the database server. If not
                    provided, the module attempts to access the server
                    without a password.

More information is provided in the INSTALL file Stage 5 Step D (search for 
'Step D' and you will find it).

=head1 PARAMETERS

You can also pass other parameters which controls the functionality 
of the Interface.pm module. 

    $umls = UMLS::Interface->new({"forcerun"      => "1",
				  "realtime"      => "1",
				  "cuilist"       => "file",  
				  "verbose"       => "1", 
                                  "debugpath"     => "file"});

  'forcerun'     -> This parameter will bypass any command prompts such 
                    as asking if you would like to continue with the index 
                    creation. 

  'realtime'     -> This parameter will not create a database of path 
                    information (what we refer to as the index) but obtain
                    the path information about a concept on the fly

  'cuilist'      -> This parameter contains a file containing a list 
                    of CUIs in which the path information should be 
                    store for - if the CUI isn't on the list the path 
                    information for that CUI will not be stored

  'verbose'      -> This parameter will print out the table information 
                    to a config file in the UMLSINTERFACECONFIG directory

  'debugpath'    -> This prints out the path information to a file during
                    any of the realtime runs


You can also reconfigure these options by calling the reConfig 
method. 

    $umls->reConfig({"forcerun"      => "1",
		     "realtime"      => "1",
		     "verbose"       => "1", 
                     "debugpath"     => "file"});


=head1 CONFIGURATION FILE

There exist a configuration files to specify which source and what 
relations are to be used. The default source is the Medical Subject 
Heading (MSH) vocabulary and the default relations are the PAR/CHD 
relation. 

  'config' -> File containing the source and relation parameters

The configuration file can be passed through the instantiation of 
the UMLS-Interface. Similar to passing the connection options. For 
example:

    $umls = UMLS::Interface->new({"driver"      => "mysql", 
				  "database"    => $database, 
				  "username"    => $opt_username,  
				  "password"    => $opt_password, 
				  "hostname"    => $hostname, 
				  "socket"      => $socket,
                                  "config"      => $configfile});

    or

    $umls = UMLS::Interface->new({"config" => $configfile});

The format of the configuration file is as follows:

  SAB :: <include|exclude> <source1, source2, ... sourceN>
  REL :: <include|exclude> <relation1, relation2, ... relationN>
  RELA :: <include|exclude> <rela1, rela2, ... relaN> 
  
  SABDEF :: <include|exclude> <source1, source2, ... sourceN>
  RELDEF :: <include|exclude> <relation1, relation2, ... relationN>

The SAB, REL and RELA are for specifing what sources and relations 
should be used when traversing the UMLS. For example, if we 
wanted to use the MSH vocabulary with only the RB/RN relations 
that have been identified as 'isa' RELAs, then the configuration 
file would be:

  SAB :: include MSH
  REL :: include RB, RN
  RELA :: include inverse_isa, isa

if we did not care what type of RELA the RB/RN relations were the 
configuration would be:

  SAB :: include MSH
  REL :: include RB, RN


if we wanted to use MSH and use any relation except for PAR/CHD, 
the configuration would be:

  SAB :: include MSH
  REL :: exclude PAR, CHD

The SABDEF and RELDEF are for obtaining a definition or extended 
definition of the CUI. SABDEF signifies which sources to extract 
the definition from. For example, 

  SABDEF :: include SNOMEDCT

would only return definitions that exist in the SNOMEDCT source.
where as:

  SABDEF :: exclude SNOMEDCT

would use the definitions from the entire UMLS except for SNOMEDCT.
The default, if you didn't specify SABDEF at all in the configuration 
file, would use the entire UMLS. 

The RELDEF is from the extended definition. It signifies which 
relations should be included when creating the extended definition 
of a given CUI. For example, 

  RELDEF :: include TERM, CUI, PAR, CHD, RB, RN

This would include in the definition the terms associated with 
the CUI, the CUI's definition and the definitions of the concepts 
related to the CUI through either a PAR, CHD, RB or RN relation. 
Similarly, using the exclude as in:

  RELDEF :: exclude TERM, CUI, PAR, CHD, RB, RN

would use all of the relations except for the one's specified. If 
RELDEF is not specified the default uses all of the relations which 
consist of: TERM, CUI, PAR, CHD, RB, RN, RO, SYN, and SIB.

I know that TERM and CUI are not 'relations' but we needed a way to
specify them and this seem to make the most sense at the time.

An example of the configuration file can be seen in the samples/ directory. 

=head1 FUNCTION DESCRIPTIONS

=cut

package UMLS::Interface;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;

use UMLS::Interface::CuiFinder;
use UMLS::Interface::PathFinder;
use UMLS::Interface::ICFinder;
use UMLS::Interface::STFinder;
use UMLS::Interface::ErrorHandler;

my $cuifinder    = "";
my $pathfinder   = "";
my $icfinder     = "";
my $stfinder     = "";
my $errorhandler = "";

my $pkg = "UMLS::Interface";

use vars qw($VERSION);

$VERSION = '1.51';

my $debug = 0;

# UMLS-specific stuff ends ----------

# -------------------- Class methods start here --------------------

#  method to create a new UMLS::Interface object
#  input : $params <- reference to hash containing the parameters 
#  output:
sub new {

    my $self      = {};
    my $className = shift;
    my $params    = shift;

    # bless the object.
    bless($self, $className);

    # initialize error handler
    $errorhandler = UMLS::Interface::ErrorHandler->new();
    if(! defined $errorhandler) {
	print STDERR "The error handler did not get passed properly.\n";
	exit;
    }

    #  check options
    $self->_checkOptions($params);

    # Initialize the object.
    $self->_initialize($params);

    return $self;
}

#  initialize the variables and set the parameters
#  input : $params <- reference to hash containing the parameters 
#  output:
sub _initialize {

    my $self = shift;
    my $params = shift;

    my $function = "_initialize";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  NOTE: The PathFinder and ICFinder require the CuiFinder 
    #        therefore it needs to be initialized the first

    #  set the cuifinder
    $cuifinder = UMLS::Interface::CuiFinder->new($params);
    if(! defined $cuifinder) { 
	my $str = "The UMLS::Interface::CuiFinder object was not created.";
	$errorhandler->_error($pkg, $function, $str, 8);
    }
    
    #  set the pathfinder
    $pathfinder = UMLS::Interface::PathFinder->new($params, $cuifinder);
    if(! defined $pathfinder) { 
	my $str = "The UMLS::Interface::PathFinder object was not created.";
	$errorhandler->_error($pkg, $function, $str, 8);
    }
    
    #  set the icfinder
    $icfinder = UMLS::Interface::ICFinder->new($params, $cuifinder, $pathfinder);
    if(! defined $icfinder) { 
	my $str = "The UMLS::Interface::ICFinder object was not created.";
	$errorhandler->_error($pkg, $function, $str, 8);
    }

    #  set the stfinder
    $stfinder = UMLS::Interface::STFinder->new($params, $cuifinder);
    if(! defined $stfinder) { 
	my $str = "The UMLS::Interface::STFinder object was not created.";
	$errorhandler->_error($pkg, $function, $str, 8);
    }
    
}

#  method checks the parameters based to the UMLS::Interface package
#  input : $params <- reference to hash containing the parameters 
#  output:
sub _checkOptions {

    my $self = shift;
    my $params = shift;

    my $function = "_checkOptions";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  database options
    my $database     = $params->{'database'};
    my $hostname     = $params->{'hostname'};
    my $socket       = $params->{'socket'};
    my $port         = $params->{'port'};
    my $username     = $params->{'username'};
    my $password     = $params->{'password'};
   
    #  cuifinder options
    my $config       = $params->{'config'};
    
    #  pathfinder options
    my $forcerun     = $params->{'forcerun'};
    my $realtime     = $params->{'realtime'};
    my $debugpath    = $params->{'debugpath'};

    #  general options
    my $debugoption  = $params->{'debug'};
    my $verbose      = $params->{'verbose'};
    my $cuilist      = $params->{'cuilist'};

    if( (defined $username) && (!defined $password) ) {
	my $str = "The --password option must be defined when using --username.";
	$errorhandler->_error($pkg, $function, $str, 10);
    }

    if( (!defined $username) && (defined $password) ) {
	my $str = "The --username option must be defined when using --password.";
	$errorhandler->_error($pkg, $function, $str, 10);
    }

    if( (defined $forcerun) && (defined $realtime) ) {
	my $str = "The --forcerun and --realtime option ";
	$str   .= "can not be set at the same time.";
	$errorhandler->_error($pkg, $function, $str, 10);
    }
	
}

=head2 Configuration Functions

=head3 returnTableNames

description:

 returns the table names in both human readable and hex form

input:    

 None  
	 
output:

 $hash <- reference to a hash containin the table names 
          in human readable and hex form

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $hash = $umls->returnTableNames();
 foreach my $table (sort keys %{$hash}) { print "$table\n"; }

=cut
sub returnTableNames {

    my $self = shift;
    
    my $hash = $cuifinder->_returnTableNames();

    return $hash;

}

=head3 dropConfigTable

description:

 removes the configuration tables

input:    

 None  
	 
output:   

 None

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 $umls->dropConfigTable();

=cut
sub dropConfigTable {
    
    my $self    = shift;

    $cuifinder->_dropConfigTable();

    return;
    
}

=head3 removeConfigFiles

description:

  removes the configuration files

input:    

 None  
	
output:   

 None
 
example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 $umls->removeConfigFiles();

=cut
sub removeConfigFiles {

    my $self = shift;

    $cuifinder->_removeConfigFiles();

    return; 
}

=head3 reConfig

description:

  function to re-initialize the interface configuration parameters

input:
   
 $hash -> reference to hash containing parameters 

output:   

 None

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my %parameters = ();
 $parameters{"verbose"} = 1;
 $umls->reConfig(\%parameters);

=cut
sub reConfig
{
    my $self = shift;
    my $params = shift;

    $cuifinder->_reConfig($params);
}

#  check that the parameters in config file match
#  input : $string1 <- string containing parameter
#          $string2 <- string containing configuratation parameter
#  output: 0|1      <- true or false
sub checkParameters {
    my $self = shift;
    my $string1 = shift;
    my $string2 = shift;
    
    return $icfinder->_checkParameters($string1, $string2);
}

#  check that the parameters in config file match
#  input : $string <- string containing relation configuration parameter
#  output: 0|1      <- true or false
sub checkHierarchicalRelations {
    my $self   = shift;
    my $string = shift;
    
    return $icfinder->_checkHierarchicalRelations($string);
}

=head2 UMLS Functions

=head3 root 

description:

  returns the root

input:    

 None  
	
output:

 $string -> string containing the root

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $root = $umls->root();
 print "The root is: $root\n";
 
=cut
sub root {

    my $self = shift;

    my $root = $cuifinder->_root();

    return $root;
}


=head3 version

description:

 returns the version of the UMLS currently being used

input:    

 None  
	 
output:

 $version -> string containing the version

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $version = $umls->version();
 print "The version of the UMLS is: $version\n";
      
=cut
sub version {

    my $self = shift;

    my $version = $cuifinder->_version();

    return $version;
}

=head2 Parameter Functions

=head3 getConfigParameters

description:

 returns the SAB/REL or SABDEF/RELDEF parameters set in the configuration file

input:    

 None  
	 
output:

 $hash <- reference to hash containing parameters in the 
          configuration file - if there was not config
          file the hash is empty and defaults are being
          use

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $hash = $umls->getConfigParameters;
 print "The configuration parameters are: \n";
 foreach my $param (sort keys %{$hash}) { 
    print "  $param\n";
 }

=cut
sub getConfigParameters {
    my $self = shift;

    my $function = "getConfigParameters";

    return $cuifinder->_getConfigParameters();
}

=head3 getSabString

description:

 returns the sab (SAB) information from the configuration file

input:    

 None  
	 
output:

 $string <- containing the SAB line from the config file

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $string = $umls->getSabString();
 print "The SAB parameter is: $string\n";

=cut
sub getSabString {
    
    my $self = shift;
    
    my $function = "getSabString";
    
    return $cuifinder->_getSabString();
}

=head3 getRelString

description:

 returns the relation (REL) information from the configuration file

input:    

 None  
	 
output:

 $string <- containing the REL line from the config file

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $string = $umls->getRelString();
 print "The REL parameter is: $string\n";

=cut
sub getRelString {
    
    my $self = shift;
    
    my $function = "getRelString";
    
    return $cuifinder->_getRelString();
}

=head3 getRelaString

description:

 returns the rela (RELA) information from the configuration file

input:    

 None  
	 
output:

 $string <- containing the RELA line from the config fil

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $string = $umls->getRelaString();
 print "The RELA parameter is: $string\n";

=cut
sub getRelaString {
    
    my $self = shift;
    
    my $function = "getRelaString";
    
    return $cuifinder->_getRelaString();
}

=head2 Metathesaurus Concept Functions

=head3 exists

description:

 function to check if a concept ID exists in the database.

input:   

 $concept <- string containing a cui

output:

 1 | 0    <- integers indicating if the cui exists

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	 
 my $concept = "C0018563";	
 if($umls->exists($concept)) { 
    print "$concept exists\n";
 }

=cut
sub exists() {
    
    my $self = shift;
    my $concept = shift;
    
    my $bool = $cuifinder->_exists($concept);

    return $bool;
}   

=head3 getRelated

description:

 function that returns a list of concepts (@concepts) related 
 to a concept $concept through a relation $rel

input:   

 $concept <- string containing cui
 $rel     <- string containing a relation

output:

 $array   <- reference to an array of cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	 
 my $concept = "C0018563";
 my $rel     = "SIB";
 my $array   = $umls->getRelated($concept, $rel);
 print "The concepts related to $concept using the $rel relation are: \n";
 foreach my $related_concept (@{$array}) { 
	  print "$related_concept\n";
 }

=cut
sub getRelated {

    my $self    = shift;
    my $concept = shift;
    my $rel     = shift;

    my $array = $cuifinder->_getRelated($concept, $rel);

    return $array;
}

=head3 getPreferredTerm

description:

 function that returns the preferred term of a cui from the sources 
 specified in the configuration file

input:   

 $concept <- string containing cui

output:

 $string  <- string containing the preferred term

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	 
 my $concept = "C0018563";
 my $string  = $umls->getPreferredTerm($concept);
 print "The preferred term of $concept is $string\n";

=cut
sub getPreferredTerm {
    my $self    = shift;
    my $concept = shift;
    
    return $cuifinder->_getPreferredTerm($concept);
}


=head3 getAllPreferredTerm

description:

 function that returns the preferred term of a cui from entire umls

input:   

 $concept <- string containing cui

output:

 $string  <- string containing the preferred term

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";
 my $string  = $umls->getAllPreferredTerm($concept);
 print "The preferred term of $concept is $string\n";
 
=cut
sub getAllPreferredTerm {
    my $self    = shift;
    my $concept = shift;
    
    return $cuifinder->_getAllPreferredTerm($concept);
}

=head3 getTermList

description:

 function to map terms to a given cui from the sources 
 specified in the configuration file using SAB

input:   

 $concept <- string containing cui

output:

 $array   <- reference to an array of terms (strings)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	
 my $concept = "C0018563";
 my $array   = $umls->getTermList($concept);
 print "The terms associated with $concept are:\n";
 foreach my $term (@{$array}) { print "  $term\n"; }

=cut
sub getTermList {

    my $self    = shift;
    my $concept = shift;
    
    my $array = $cuifinder->_getTermList($concept);

    return $array;
}

=head3 getDefTermList

description:

 function to map terms to a given cui from the sources 
 specified in the configuration file using SABDEF

input:   

 $concept <- string containing cui

output:

 $array   <- reference to an array of terms (strings)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	
 my $concept = "C0018563";
 my $array   = $umls->getDefTermList($concept);
 print "The terms associated with $concept are:\n";
 foreach my $term (@{$array}) { print "  $term\n"; }

=cut
sub getDefTermList {

    my $self    = shift;
    my $concept = shift;
    
    my $array = $cuifinder->_getDefTermList($concept);

    return $array;
}

=head3 getAllTerms

description:

 function to map terms from the entire UMLS to a given cui

input:   

 $concept <- string containing cui

output:

 $array   <- reference to an array containing terms (strings)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	
 my $concept = "C0018563";
 my $array   = $umls->getAllTerms($concept);
 print "The terms associated with $concept are:\n";
 foreach my $term (@{$array}) { print "  $term\n"; }

=cut
sub getAllTerms {

    my $self = shift;
    my $concept = shift;

    my $array = $cuifinder->_getAllTerms($concept);

    return $array;
}

=head3 getConceptList

description:

 function to maps a given term to a set cuis in the sources
 specified in the configuration file by SAB

input:   

 $term  <- string containing a term

output:

 $array <- reference to an array containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $term   = "hand";
 my $array  = $umls->getConceptList($term);
 print "The concept associated with $term are:\n";
 foreach my $concept (@{$array}) { print "  $concept\n"; }

=cut
sub getConceptList {

    my $self = shift;
    my $term = shift;

    my $array = $cuifinder->_getConceptList($term);

    return $array;
}

=head3 getDefConceptList

description:

 function to maps a given term to a set cuis in the sources
 specified in the configuration file by SABDEF

input:   

 $term  <- string containing a term

output:

 $array <- reference to an array containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $term   = "hand";
 my $array  = $umls->getDefConceptList($term);
 print "The concept associated with $term are:\n";
 foreach my $concept (@{$array}) { print "  $concept\n"; }

=cut
sub getDefConceptList {

    my $self = shift;
    my $term = shift;

    my $array = $cuifinder->_getDefConceptList($term);

    return $array;
}

=head3 getAllConcepts

description:

 function to maps a given term to a set cuis all the sources

input:   

 $term  <- string containing a term

output:

 $array <- reference to an array containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $term   = "hand";
 my $array  = $umls->getAllConcepts($term);
 print "The concept associated with $term are:\n";
 foreach my $concept (@{$array}) { print "  $concept\n"; }

=cut
sub getAllConcepts {

    my $self = shift;
    my $term = shift;

    my $array = $cuifinder->_getAllConcepts($term);

    return $array;
}

#  method to maps a given term to a set cuis in the sources
#  specified in the configuration file by SABDEF
#  input : $term  <- string containing a term
#  output: $array <- reference to an array containing cuis
sub getSabDefConcepts {

    my $self = shift;
    my $term = shift;

    my $array = $cuifinder->_getSabDefConcepts($term);

    return $array;
}


=head3 getCompounds

description:

 function returns all the compounds in the sources 
 specified in the configuration file

input:    

 None  
	
output:

 $hash <- reference to a hash containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $hash = $umls->getCompounds();
 foreach my $term (sort keys %{$hash}) {
   print "$term\n";
 }

=cut
sub getCompounds {

    my $self = shift;

    my $hash = $cuifinder->_getCompounds();

    return $hash;
}

=head3 getCuiList    

description:

 returns all of the cuis in the sources specified in the configuration file

input:    

 None  
	 
output:

 $hash <- reference to a hash containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $hash = $umls->getCuiList();
 foreach my $concept (sort keys %{$hash}) { 
    print "$concept\n";
 }

=cut
sub getCuiList {    

    my $self = shift;

    my $hash = $cuifinder->_getCuiList();

    return $hash;
}

=head3 getCuisFromSource

description:

 returns the cuis from a specified source 

input:   

 $sab   <- string contain the sources abbreviation

output:

 $array <- reference to an array containing cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	 
 my $sab   = "MSH";
 my $array = $umls->getCuisFromSource($sab);
 foreach my $concept (@{$array}) { 
   print "$concept\n";
 }

=cut
sub getCuisFromSource {
    
    my $self = shift;
    my $sab = shift;
    
    my $array = $cuifinder->_getCuisFromSource($sab);

    return $array;
}

=head3 getSab

description:

 takes as input a cui and returns all of the sources in which it originated 
 from 

input:   

 $concept <- string containing the cui 

output:

 $array   <- reference to an array contain the sources (abbreviations)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	 
 my $concept = "C0018563";	
 my $array   = $umls->getSab($concept);
 print "The concept ($concept) exists in sources:\n";
 foreach my $sab (@{$array}) { print "  $sab\n"; }

=cut
sub getSab {

    my $self = shift;
    my $concept = shift;

    my $array = $cuifinder->_getSab($concept);

    return $array;
}

=head3 getChildren

description:

 returns the children of a concept - the relations that are considered children 
 are predefined by the user in the configuration file. The default is the CHD 
 relation.

input:   

 $concept <- string containing cui

output:

 $array   <- reference to an array containing a list of cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";	
 my $children = $umls->getChildren($concept);
 print "The children of $concept are:\n";
 foreach my $child (@{$children}) { print "  $child\n"; }

=cut
sub getChildren {

    my $self    = shift;
    my $concept = shift;

    my $array = $cuifinder->_getChildren($concept);

    return $array;
}

=head3 getParents

description:

 returns the parents of a concept - the relations that are considered parents 
 are predefined by the user in the configuration file.The default is the PAR 
 relation.

input:   

 $concept <- string containing cui

output:

 $array   <- reference to an array containing a list of cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";	
 my $parents  = $umls->getParents($concept);
 print "The parents of $concept are:\n";
 foreach my $parent (@{$parents}) { print "  $parent\n"; }

=cut
sub getParents {

    my $self    = shift;
    my $concept = shift;

    my $array = $cuifinder->_getParents($concept);

    return $array;
    
}

=head3 getRelations

description:

 returns the relations of a concept in the source specified by the user in the 
 configuration file

input:   

 $concept <- string containing a cui

output:

 $array   <- reference to an array containing strings of relations

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $concept  = "C0018563";	
 my $array    = $umls->getRelations($concept);
 print "The relations associated with $concept are:\n";
 foreach my $relation (@{$array}) { print "  $relation\n"; }


=cut
sub getRelations {

    my $self    = shift;
    my $concept = shift;
    
    my $array = $cuifinder->_getRelations($concept);

    return $array;
}

=head3 getRelationsBetweenCuis

description:

 returns the relations and its source between two concepts

input:   

 $concept1 <- string containing a cui
 $concept2 <- string containing a cui

output:

 $array    <- reference to an array containing the relations

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept1  = "C0018563";
 my $concept2  = "C0016129";
 my $array     = $umls->getRelationsBetweenCuis($concept1,$concept2);
 print "The relations between $concept1 and $concept2 are:\n";
 foreach my $relation (@{$array}) { print "  $relation\n"; }

=cut
sub getRelationsBetweenCuis {

    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $array = $cuifinder->_getRelationsBetweenCuis($concept1, $concept2);

    return $array;
}


=head2 Metathesaurus Concept Definition Fuctions

=head3 getExtendedDefinition

description:

 returns the extended definition of a cui given the relation and source 
 information in the configuration file 

input:   

 $concept <- string containing a cui

output:

 $array   <- reference to an array containing the definitions

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";	
 my $array   = $umls->getExtendedDefinition($concept);
 print "The extended definition of $concept is:\n";
 foreach my $def (@{$array}) { print "  $def\n"; }

=cut
sub getExtendedDefinition {

    my $self    = shift;
    my $concept = shift;

    my $array = $cuifinder->_getExtendedDefinition($concept);

    return $array;
}

=head3 getCuiDef

description:

 returns the definition of the cui 

input:   

 $concept <- string containing a cui
 $sabflag <- 0 | 1 whether to include the source in with the definition 

output:

 $array   <- reference to an array of definitions (strings)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";	
 my $array   = $umls->getCuiDef($concept);
 print "The definition of $concept is:\n";
 foreach my $def (@{$array}) { print "  $def\n"; }

=cut
sub getCuiDef {

    my $self    = shift;
    my $concept = shift;
    my $sabflag = shift;

    my $array = $cuifinder->_getCuiDef($concept, $sabflag);

    return $array;
}

=head2 Metathesaurus Concept Path Functions

=head3 depth

description:

 function to return the maximum depth of a taxonomy.

input:    

 None  
	 
output:

 $string <- string containing the depth

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $string = $umls->depth();
	   
=cut
sub depth {
    my $self = shift;

    my $depth = $pathfinder->_depth();

    return $depth;
}

=head3 pathsToRoot

description:

 function to find all the paths from a concept to the root node of the is-a taxonomy.

input:   

 $concept <- string containing cui

output:

 $array   <- array reference containing the paths

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";	
 my $array   = $umls->pathsToRoot($concept);
 print "The paths to the root for $concept are:\n";
 foreach my $path (@{$array}) { print "  $path\n"; }

=cut
sub pathsToRoot
{
    my $self    = shift;
    my $concept = shift;

    my $array = $pathfinder->_pathsToRoot($concept);

    return $array;
}

=head3 findMinimumDepth

description:

 
 function returns the minimum depth of a concept given the
 sources and relations specified in the configuration file

input:   

 $concept <- string containing the cui

output:

 $int     <- string containing the depth of the cui

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";	
 my $int     = $umls->findMinimumDepth($concept);
 print "The minimum depth of $concept is $int\n";

=cut
sub findMinimumDepth {

    my $self     = shift;
    my $concept  = shift;
    
    my $depth = $pathfinder->_findMinimumDepth($concept);

    return $depth;
}
  
=head3 findMaximumDepth

description:

 returns the maximum depth of a concept given the sources and relations 
 specified in the configuration file

input:   

 $concept <- string containing the cui

output:

 $int     <- string containing the depth of the cui

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";	
 my $int     = $umls->findMaximumDepth($concept);
 print "The maximum depth of $concept is $int\n";

=cut
sub findMaximumDepth {

    my $self    = shift;
    my $concept = shift;
    
    my $depth = $pathfinder->_findMaximumDepth($concept);

    return $depth;
}    


=head3 findNumberOfCloserConcepts

description:

 function that finds the DUI of a given CUI

input:   

 $concept  <- the concept

output:

 $dui <- the MSH DUI

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $cui       = $umls->getDUI($concept); 
 print "The DUI for $concept is $dui\n";

=cut
sub getDUI {
    my $self = shift;
    my $concept = shift; 

    my $dui = $cuifinder->_getDUI($concept);

    return $dui;
}

=head3 findNumberOfCloserConcepts

description:

 function that finds the number of cuis closer to concept1 than concept2

input:   

 $concept1  <- the first concept
 $concept2  <- the second concept

output:

 $int <- number of cuis closer to concept1 than concept2

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept1  = "C0018563";
 my $concept2  = "C0016129";
 my $int       = $umls->findNumberOfCloserConcepts($concept1,$concept2);
 print "The number of closer concepts to $concept1 than $concept2 is $int\n";

=cut
sub findNumberOfCloserConcepts {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $length = $pathfinder->_findNumberOfCloserConcepts($concept1, $concept2);
    
    return $length;
}

=head3 findClosenessCentrality

description:

 function that closeness centrality of a concept 

input:   

 $concept  <- the concept

output:

 $double <- the closeness centrality 

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   =  $umls->findClosenessCentrality($concept);
 print "The Closeness Centrality for $concept is $double\n";

=cut
sub findClosenessCentrality {

    my $self = shift;
    my $concept = shift;
    
    my $closeness = $pathfinder->_findClosenessCentrality($concept);
    
    return $closeness;
}

=head3 findAncestors

description:

 function that returns all the ancestors of a concept 

input:   

 $concept  <- the concept

output:

 %hash <- reference to hash containing ancestors

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";
 my $hash =  $umls->findAncestors($concept); 

=cut
sub findAncestors {

    my $self = shift;
    my $concept = shift;
    
    my $hash = $pathfinder->_findAncestors($concept);
    
    return $hash;
}

=head3 findDescendents

description:

 function that returns all the ancestors of a concept 

input:   

 $concept  <- the concept

output:

 %hash <- reference to hash containing ancestors

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept = "C0018563";
 my $hash =  $umls->findDescendents($concept); 

=cut
sub findDescendants {

    my $self = shift;
    my $concept = shift;
    
    my $hash = $pathfinder->_findDescendants($concept);
    
    return $hash;
}

=head3 findShortestPathLength

description:

 function that finds the length of the shortest path

input:   

 $concept1  <- the first concept
 $concept2  <- the second concept

output:

 $int <- the length of the shortest path between them

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept1  = "C0018563";
 my $concept2  = "C0016129";
 my $int       =  $umls->findShortestPathLength($concept1,$concept2);
 print "The shortest path length between $concept1 than $concept2 is $int\n";

=cut
sub findShortestPathLength {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $length = $pathfinder->_findShortestPathLength($concept1, $concept2);
    
    return $length;
}

=head3 findShortestPath

description:

 returns the shortest path between two concepts given the sources and 
 relations specified in the configuration file

input:   

 $concept1 <- string containing the first cui
 $concept2 <- string containing the second

output:

 $array    <- reference to an array containing the shortest path(s)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept1  = "C0018563";
 my $concept2  = "C0016129";
 my $array     = $umls->findShortestPath($concept1,$concept2);
 print "The shortest path(s) between $concept1 than $concept2 are:\n";
 foreach my $path (@{$array}) { print "  $path\n"; }

=cut
sub findShortestPath {

    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $array = $pathfinder->_findShortestPath($concept1, $concept2);

    return $array;
}
   
=head3 findLeastCommonSubsumer   

description:

 
 returns the least common subsummer between two concepts given the sources 
 and relations specified in the configuration file

input:   
	
 $concept1 <- string containing the first cui
 $concept2 <- string containing the second

output:

 $array    <- reference to an array containing the lcs(es)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept1  = "C0018563";
 my $concept2  = "C0016129";
 my $array     = $umls->findLeastCommonSubsumer($concept1,$concept2);
 print "The LCS(es) between $concept1 than $concept2 iare:\n";
 foreach my $lcs (@{$array}) { print "  $lcs\n"; }

=cut
sub findLeastCommonSubsumer {   

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $array = $pathfinder->_findLeastCommonSubsumer($concept1, $concept2);

    return $array;
}    

=head3 setUndirectedPath

description:
 
 function set the undirected option for the path on or off

input:   

 $option <- 1 (true) 0 (false)

output:

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 $umls->setUndirectedOption(1); 

=cut
sub setUndirectedOption { 

    my $self     = shift;
    my $option  = shift;
    
    $pathfinder->_setUndirectedOption($option); 
}

=head3 setRealtimePath

description:
 
 function set the realtime option for the path on or off

input:   

 $option <- 1 (true) 0 (false)

output:

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 $umls->setRealtimeOption(1); 

=cut
sub setRealtimeOption { 

    my $self     = shift;
    my $option  = shift;
    
    $pathfinder->_setRealtimeOption($option); 
    $icfinder->_setRealtimeOption($option); 
}

=head2 Metathesaurus Concept Propagation Functions

=head3 setPropagationParameters

description:

 sets the propagation counts 

input:   

 $hash <- reference to hash containing parameters
          debug         -> turn debug option on 
          icpropagation -> file containing icpropagation counts
          icfrequency   -> file containing icfrequency counts
          smooth        -> whether you want to smooth the frequency counts
          realtime      -> calculate the intrinsic ic in realtime         

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 $umls->setPropagationParameters(\%hash);

=cut
sub setPropagationParameters {
    
    my $self       = shift;
    my $parameters = shift;
    
    $icfinder->_setPropagationParameters($parameters);
}

=head3 getIC

description:

 returns the information content of a given cui

input:   

 $concept <- string containing a cui

output:

 $double  <- double containing its IC

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   = $umls->getIC($concept);
 print "The IC of $concept is $double\n";

=cut
sub getIC {
    my $self     = shift;
    my $concept  = shift;
    
    my $ic = $icfinder->_getIC($concept);

    return $ic;    
}

=head3 getSecoIntrinsicIC

description:

 returns the intrinsic information content of a given cui using 
 the formula proposed by Seco, Veale and Hayes 2004

input:   

 $concept <- string containing a cui

output:

 $double  <- double containing its IC

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   = $umls->getSecoIntrinsicIC($concept);
 print "The Intrinsic IC of $concept is $double\n";

=cut
sub getSecoIntrinsicIC {
    my $self     = shift;
    my $concept  = shift;
    
    my $ic = $icfinder->_getSecoIntrinsicIC($concept);

    return $ic;    
}
=head3 getSanchezIntrinsicIC

description:

 returns the intrinsic information content of a given cui using 
 the formula proposed by Sanchez and Batet 2011

input:   

 $concept <- string containing a cui

output:

 $double  <- double containing its IC

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   = $umls->getSanchezIntrinsicIC($concept);
 print "The Intrinsic IC of $concept is $double\n";

=cut
sub getSanchezIntrinsicIC {
    my $self     = shift;
    my $concept  = shift;
    
    my $ic = $icfinder->_getSanchezIntrinsicIC($concept);

    return $ic;    
}

=head3 getProbability

description:

 returns the probability of a given cui

input:   

 $concept <- string containing a cui

output:

 $double  <- double containing its probability

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   = $umls->getProbability($concept);
 print "The probability of $concept is $double\n";

=cut
sub getProbability {
    my $self     = shift;
    my $concept  = shift;
    
    my $prob = $icfinder->_getProbability($concept);

    return $prob;
}

=head3 getN

description:

 returns the total number of CUIs (N)

input:    

 None  
	 
output:

 $int  <- integer containing frequency

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 my $int = $umls->getN();

=cut
sub getN {
    my $self     = shift;
    
    my $n = $icfinder->_getN();

    return $n;
}

=head3 getFrequency

description:

 returns the propagation count (frequency) of a given cui

input:   

 $concept <- string containing a cui

output:

 $double  <- double containing its frequency

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $concept  = "C0018563";
 my $double   = $umls->getFrequency($concept);
 print "The frequency of $concept is $double\n";

=cut
sub getFrequency {
    my $self     = shift;
    my $concept  = shift;
    
    my $ic = $icfinder->_getFrequency($concept);

    return $ic;    
}

=head3 getPropagationCuis

description:

 returns all of the cuis to be propagated given the sources 
 and relations specified by the user in the configuration file

input:    

 None  
	
output:

 $hash <- reference to hash containing the cuis

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 my $hash = $umls->getPropagationCuis();

=cut
sub getPropagationCuis
{
    my $self = shift;
    
    my $hash = $icfinder->_getPropagationCuis();

    return $hash;
    
}

=head3 propagateCounts

description:

 propagates the given frequency counts

input:   
	 
 $hash <- reference to the hash containing the frequency counts

output:
 
 $hash <- containing the propagation counts of all the cuis 
          given the sources and relations specified in the 
          configuration file

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 my $phash = $umls->propagateCounts(\%fhash);

=cut
sub propagateCounts
{

    my $self = shift;
    my $fhash = shift;
    
    my $hash = $icfinder->_propagateCounts($fhash);

    return $hash;
}


=head2 Semantic Network Functions

=head3 getSemanticRelation

description: 

 subroutine to get the relation(s) between two semantic types

input:   

 $st1   <- semantic type abbreviation
 $st2   <- semantic type abbreviation

output:

 $array <- reference to an array of semantic relation(s)

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $st1   = "blor";
 my $st2   = "bpoc";
 my $array = $umls->getSemanticRelation($st1,$st2);
 print "The relations between $st1 and $st2 are:\n";
 foreach my $relation (@{$array}) { print "  $relation\n"; }

=cut 
sub getSemanticRelation {
    
    my $self = shift;
    my $st1  = shift;
    my $st2  = shift;

    my $array = $cuifinder->_getSemanticRelation($st1, $st2);

    return $array;
}

 
=head3 getSt

description:

 returns the semantic type(s) of a given concept

input:   

 $concept <- string containing a concept

output:

 $array   <- reference to an array containing the semantic type's TUIs
             associated with the concept

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $concept  = "C0018563";	
 my $array    = $umls->getSts($concept);
 print "The semantic types associated with $concept are:\n";
 foreach my $st (@{$array}) { print "  $st\n"; }

=cut
sub getSt {

    my $self = shift;
    my $concept   = shift;

    my $array = $cuifinder->_getSt($concept);
    
    return $array;
}

 
=head3 getSt

description:

 returns the semantic type(s) of a given concept

input:   

output:

 $array   <- reference to an array containing all the semantic type's TUIs
             

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $concept  = "C0018563";	
 my $array    = $umls->getAllSts(); 
 print "The semantic types in the UMLS are: \n"; 
 foreach my $st (@{$array}) { print "  $st\n"; }

=cut
sub getAllSts {

    my $self = shift;
    my $concept   = shift;

    my $array = $cuifinder->_getAllSts(); 
    
    return $array;
}

=head3 getSemanticGroup

description:

 function returns the semantic group(s) associated with the concept

input:   

 $concept <- string containing cuis

output:

 $array   <- $array reference containing semantic groups

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $concept  = "C0018563";	
 my $array    = $umls->getSemanticGroup($concept);
 print "The semantic group associated with $concept are:\n";
 foreach my $sg (@{$array}) { print "  $sg\n"; }

=cut
sub getSemanticGroup {

    my $self = shift;
    my $cui  = shift;
    
    my $array = $cuifinder->_getSemanticGroup($cui);

    return $array;
}

=head3 getAllSemanticGroups

description:

 function returns all the semantic groups

input:   

output:

 $array   <- $array reference containing semantic groups

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $concept  = "C0018563";	
 my $array    = $umls->getAllSemanticGroups(); 
 print "The semantic groups are:\n";
 foreach my $sg (@{$array}) { print "  $sg\n"; }

=cut
sub getAllSemanticGroups {

    my $self = shift;
    
    my $array = $cuifinder->_getAllSemanticGroups(); 

    return $array;
}

=head3 getStsFromSg

description:

 function returns all the semantic types of a given semantic group

input:   

 $string <- semantic group code

output:

 $array   <- $array reference containing semantic types

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $sg  = "PROC";	
 my $array    = $umls->getStsFromSg($sg); 
 print "The semantic types are:\n";
 foreach my $st (@{$array}) { print "  $st\n"; }

=cut
sub getStsFromSg { 

    my $self = shift;
    my $sg  = shift;
    
    my $array = $cuifinder->_getStsFromSg($sg); 

    return $array;
}

=head3 stGetSemanticGroup

description:

 function returns the semantic group(s) associated with a semantic type

input:   

 $st <- string containing semantic type abbreviations

output:

 $array   <- $array reference containing semantic groups

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $st  = "pboc";
 my $array    = $umls->stGetSemanticGroup($st);
 print "The semantic group associated with $st are:\n";
 foreach my $sg (@{$array}) { print "  $sg\n"; }

=cut
sub stGetSemanticGroup {
 
   my $self = shift;
   my $st = shift;

   my $array = $cuifinder->_stGetSemanticGroup($st);
   
   return $array;
}

=head3 getStString

description:

 returns the full name of a semantic type given its abbreviation

input:   

 $st     <- string containing the abbreviation of the semantic type

output:

 $string <- string containing the full name of the semantic type

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $st     = "bpoc";
 my $string = $umls->getStString($st);
 print "The abbreviation $st stands for $string\n";

=cut
sub getStString {

    my $self = shift;
    my $st   = shift;

    my $string = $cuifinder->_getStString($st);

    return $string;
} 

=head3 getStAbr

description:

 returns the abreviation of a semantic type given its TUI (UI)

input:   

 $tui    <- string containing the semantic type's TUI

output:

 $string <- string containing the semantic type's abbreviation

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $tui    = "T023"
 my $string = $umls->getStAbr($tui);
 print "The abbreviation of $tui is $string\n";

=cut
sub getStAbr {

    my $self = shift;
    my $tui   = shift;

    my $abr = $cuifinder->_getStAbr($tui);

    return $abr;
} 

=head3 getStTui

description:

 function to get the name of a semantic type's TUI given its abbrevation

input:   

 $string <- string containing the semantic type's abbreviation

output:

 $tui    <- string containing the semantic type's TUI

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $string = "bpoc"
 my $tui     = $umls->getStAbr($tui);
 print "The tui of $string is $tui\n";

=cut
sub getStTui {
    my $self   = shift;
    my $abbrev = shift;

    my $tui = $cuifinder->_getStTui($abbrev);

    return $tui;
} 

=head3 getStDef

description:

 returns the definition of the semantic type - expecting abbreviation

input:   

 $st     <- string containing the semantic type's abbreviation

output:

 $string <- string containing the semantic type's definition

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
	
 my $st     = "bpoc"
 my $string = $umls->getStDef($st);
 print "The definition of $st is $string\n";

=cut
sub getStDef {

    my $self = shift;
    my $st   = shift;

    my $definition = $cuifinder->_getStDef($st);

    return $definition;
} 


=head2 Semantic Network Path Functions

=head3 stPathsToRoot

description:

 This function to find all the paths from a semantic type (tui)  
 to the root node of the is-a taxonomy in the semantic network

input:   

 $tui     <- string containing tui

output:

 $array   <- array reference containing the paths

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 	

 my $tui   = "T023"
 my $array = $umls->stPathsToRoot($tui);
 print "The paths from $tui to the root are:\n";
 foreach my $path (@{$array}) { print "  $path\n";

=cut
sub stPathsToRoot
{
    my $self  = shift;
    my $tui   = shift;

    my $array = $stfinder->_pathsToRoot($tui);

    return $array;  
}

=head3 stFindShortestPath 


description:

 This function returns the shortest path between two semantic type TUIs.

input: 

 $st1   <- string containing the first tui
 $st2   <- string containing the second tui

output:

 $array <- reference to an array containing paths

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

  my $st1  = "T023";
  my $st2  = "T029";
  my $array     = $umls->stFindShortestPath($st1,$st2);
  print "The shortest path(s) between $st1 than $st2 are:\n";
  foreach my $path (@{$array}) { print "  $path\n"; }

=cut
sub stFindShortestPath 
{
    my $self = shift;
    my $st1  = shift;
    my $st2  = shift;
    
    my $array = $stfinder->_findShortestPath($st1, $st2);
    
    return $array;
}


#  returns the minimum depth of a semantic type in the network
#  input : $st  <- string containing the semantic type
#  output: $int <- minimum depth of hte semantic type
#sub getMinStDepth {
#    my $self = shift;
#    my $st   = shift;
#    
#    my $depth = $stfinder->_getMinDepth($st);
#
#    return $depth;
#}

#  returns the maximum depth of a semantic type in the network
#  input : $st  <- string containing the semantic type
#  output: $int <- maximum depth of hte semantic type
#sub getMaxStDepth {
#    my $self = shift;
#    my $st   = shift;
#    
#    my $depth = $stfinder->_getMaxDepth($st);
#
#    return $depth;
#}

=head2 Semantic Network Propagation Functions

=head3 loadStPropagationHash

description:

 load the propagation hash for the semantic network

input:   

 $hash  <- reference to a hash containing probability counts

output:   

 None
 
example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 $umls->loadStPropagationHash(\%hash);

=cut
sub loadStPropagationHash {
    my $self = shift;
    my $hash = shift;
    
    $stfinder->_loadStPropagationHash($hash);
}

=head3 propagateStCounts

description:

 propagates the given frequency counts of the semantic types

input:   

 $hash <- reference to the hash containing the frequency counts

output:

 $hash <- containing the propagation counts of all the semantic types

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 

 my $phash = $umls->propagateStCounts(\%fhash);

=cut
sub propagateStCounts
{

    my $self = shift;
    my $fhash = shift;
    
    my $hash = $stfinder->_propagateStCounts($fhash);

    return $hash;
}

=head3 getStIC

description:

 returns the information content of a given semantic type

input:   

 $st      <- string containing a semantic type

output:

 $double  <- double containing its IC

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $st = "bpoc";
 my $double = $umls->getStIC($st);
 print "The IC of $st is $double\n";
 
=cut
sub getStIC {
    my $self = shift;
    my $st   = shift;
    
    my $ic = $stfinder->_getStIC($st);

    return $ic;    
}

=head3 getStProbability

description:

 returns the probability of a given semantic type

input:   

 $st      <- string containing a semantic type

output:

 $double  <- double containing its probabilit

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $st = "bpoc";
 my $double = $umls->getStProbability($st);
 print "The Probability of $st is $double\n";

=cut
sub getStProbability {
    my $self     = shift;
    my $st       = shift;
    
    my $prob = $stfinder->_getStProbability($st);

    return $prob;
}

=head3 getStN

description:

 returns the total number of semantic types (N)

input:   
	 
output:

 $int  <- double containing frequency

example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 my $int = $umls->getStN();

=cut
sub getStN {
    my $self     = shift;
    
    my $n = $stfinder->_getStN();

    return $n;
}

=head3 setStSmoothing

description:

 function to set the smoothing parameter

input:   

 None
	  
output:   

 None
  
example:

 use UMLS::Interface;
 my $umls = UMLS::Interface->new(); 
 $umls->setStSmoothing();

=cut
sub setStSmoothing
{
    my $self      = shift;
    
    $stfinder->_setStSmoothing();
    
}

1;

__END__

=head1 REFERENCING

If you write a paper that has used UMLS-Interface in some way, we'd 
certainly be grateful if you sent us a copy and referenced UMLS-Interface. 
We have a published paper that provides a suitable reference:

    @inproceedings{McInnesPP09,
       title={{UMLS-Interface and UMLS-Similarity : Open Source 
               Software for Measuring Paths and Semantic Similarity}}, 
       author={McInnes, B.T. and Pedersen, T. and Pakhomov, S.V.}, 
       booktitle={Proceedings of the American Medical Informatics 
                  Association (AMIA) Symposium},
       year={2009}, 
       month={November}, 
       address={San Fransico, CA}
    }

This paper is also found in

http://www-users.cs.umn.edu/~bthomson/publications/pubs.html

or

http://www.d.umn.edu/~tpederse/Pubs/amia09.pdf

=head1 SEE ALSO

http://tech.groups.yahoo.com/group/umls-similarity/

http://search.cpan.org/dist/UMLS-Similarity/

=head1 AUTHOR

Bridget T McInnes <bthomson@cs.umn.edu>
Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT

 Copyright (c) 2007-2009
 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd at cs.utah.edu

 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota
 liux0935 at umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to 

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut
