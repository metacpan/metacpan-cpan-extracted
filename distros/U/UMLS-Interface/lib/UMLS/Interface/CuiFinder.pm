# UMLS::Interface::CuiFinder
# (Last Updated $Id: CuiFinder.pm,v 1.84 2016/09/13 17:15:51 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2011,
#
# Bridget T. McInnes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
#
# Siddharth Patwardhan, University of Utah, Salt Lake City
# sidd at cs.utah.edu
#
# Serguei Pakhomov, University of Minnesota, Twin Cities
# pakh0002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota, Twin Cities
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

package UMLS::Interface::CuiFinder;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

#  error handling variables
my $errorhandler = "";
my $pkg = "UMLS::Interface::CuiFinder";

#  debug variables
local(*DEBUG_FILE);

#  global variables
my $debug     = 0;
my $umlsRoot  = "C0000000";
my $version   = "";

#  list of allowable sources
my $sources      = "";
my %sabHash      = ();
my %sabnamesHash = ();
my $sabstring    = "";

#  list of allowable relations
my $relations       = "";
my $childRelations  = "";
my $parentRelations = "";
my $relstring       = "";
my $relastring      = "";

#  upper level taxonomy
my %parentTaxonomyArray = ();
my %childTaxonomyArray  = ();

#  list of interested cuis - default is
#  all given the specified set of sources
#  and relations.
my %cuiListHash    = ();

#  initialize the semantic groups and relations hash
my %semanticGroups = ();
my %semanticRelations = ();
my %sgConversion = (); 
my %sgConversion1 = (); 

#  database
my $indexDB        = "umlsinterfaceindex";
my $umlsinterface   = $ENV{UMLSINTERFACE_CONFIGFILE_DIR};

#  table names
my $tableName          = "";
my $intrinsicTable     = "";
my $parentTable        = "";
my $childTable         = "";
my $tableFile          = "";
my $intrinsicTableHuman= "";
my $parentTableHuman   = "";
my $childTableHuman    = "";
my $tableNameHuman     = "";
my $configFile         = "";
my $childFile          = "";
my $parentFile         = "";
my $infoTable          = "";
my $infoTableHuman     = "";
my $cacheTable         = "";
my $cacheTableHuman    = "";

#  flags and options
my $umlsall            = 0;
my $sabdef_umlsall     = 0;
my $option_verbose     = 0;
my $option_cuilist     = 0;
my $option_t           = 0;
my $option_config      = 0;
my $defflag            = 0;

#  definition containers
my $sabdefsources      = "";
my %relDefHash         = ();
my %sabDefHash         = ();
my $reldefstring       = "";
my $sabdefstring       = "";
my $reladefchildren    = "";
my $reladefparents     = "";

my %parameters         = ();

######################################################################
#  functions to initialize the package
######################################################################

#  method to create a new UMLS::Interface object
#  input : $parameters <- reference to a hash
#  output: $self
sub new {

    my $self = {};
    my $className = shift;
    my $params = shift;

    # bless the object.
    bless($self, $className);

    $self->_initializeGlobalVariables();

    # initialize error handler
    $errorhandler = UMLS::Interface::ErrorHandler->new();
    if(! defined $errorhandler) {
        print STDERR "The error handler did not get passed properly.\n";
        exit;
    }

    # initialize the object.
    $self->_initialize($params);

    #  set the semantic groups
    $self->_setSemanticGroups();

    return $self;
}

#  method to re-initialize the UMLS::Interface parameters
sub _reConfig {

    my $self = shift;
    my $params = shift;

    my $function = "_reConfig";
    &_debug($function);

    #  re initialize the global variables
    $self->_initializeGlobalVariables();

    # initialize the object.
    $self->_initialize($params);

    return $self;
    
    
}
# method to initialize the UMLS::Interface global variables
sub _initializeGlobalVariables {
    
    my $self = shift;

    my $function = "_initializeGlobalVariables";
    &_debug($function);
    
    #  global variables
    $debug     = 0;
    $version   = "";

    #  list of allowable sources
    $sources      = "";
    %sabHash      = ();
    %sabnamesHash = ();
    $sabstring    = "";

    #  list of allowable relations
    $relations       = "";
    $childRelations  = "";
    $parentRelations = "";
    $relstring       = "";
    $relastring      = "";

    #  upper level taxonomy
    %parentTaxonomyArray = ();
    %childTaxonomyArray  = ();

    #  list of interested cuis - default is
    #  all given the specified set of sources
    #  and relations.
    %cuiListHash    = ();


    #  table names
    $tableName          = "";
    $parentTable        = "";
    $intrinsicTable     = "";
    $childTable         = "";
    $tableFile          = "";
    $intrinsicTableHuman= "";
    $parentTableHuman   = "";
    $childTableHuman    = "";
    $tableNameHuman     = "";
    $configFile         = "";
    $childFile          = "";
    $parentFile         = "";
    $infoTable          = "";
    $infoTableHuman     = "";
    $cacheTable         = "";
    $cacheTableHuman    = "";

    #  flags and options
    $umlsall            = 0;
    $option_verbose     = 0;
    $option_cuilist     = 0;
    $option_t           = 0;
    $option_config      = 0;

    #  definition containers
    $sabdefsources      = "";
    %relDefHash         = ();
    %sabDefHash         = ();
    $reldefstring       = "";
    $sabdefstring       = "";
    $reladefchildren    = "";
    $reladefparents     = "";
    %parameters         = ();

}

#  method to initialize the UMLS::Interface object.
#  input : $parameters <- reference to a hash
#  output:
sub _initialize {

    my $self = shift;
    my $params = shift;

    my $function = "_initialize";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }


    $params = {} if(!defined $params);

    #  get some of the parameters
    my $config       = $params->{'config'};
    my $cuilist      = $params->{'cuilist'};
    my $database     = $params->{'database'};

    #  to store the database object
    my $db = $self->_setDatabase($params);
    
    #  set up the options
    $self->_setOptions($params);

    #  check that all of the tables required exist in the db
    $self->_checkTablesExist();

    #  set the version information
    $self->_setVersion();

    #  set the configuration
    $self->_config($config);
    
    #  set the umls interface configuration variable
    $self->_setEnvironmentVariable();

    #  set the table and file names for indexing
    $self->_setConfigurationFile();

    #  set the configfile
    $self->_setConfigFile();

    #  load the cuilist if it has been defined
    $self->_loadCuiList($cuilist);

    #  create the index database
    $self->_createIndexDB();

    #  connect to the index database
    $self->_connectIndexDB();

    #  set the upper level taxonomy
    $self->_setUpperLevelTaxonomy();

    #  set the cache tables
    $self->_setCacheTable();
}

#  this function returns the umls root
#  input :
#  output: $string <- string containing the root
sub _root {

    return $umlsRoot;
}

#  this function sets the upper level taxonomy between
#  the sources and the root UMLS node
#  input :
#  output:
sub _setCacheTable {

    my $self = shift;

    my $function = "_setCacheTable";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the sourceDB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  check if the cache table exists 
    #  if does just return otherwise create it
    if($self->_checkTableExists($cacheTable)) { 
        return;
    }
    else {
	#  create cache table
	$sdb->do("CREATE TABLE IF NOT EXISTS $cacheTable (CUI1 char(8), CUI2 char(8), LENGTH char(8))");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
	#  store the name in the table index
	$sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$cacheTableHuman', '$cacheTable')");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
    }
}

#  this function sets the upper level taxonomy between
#  the sources and the root UMLS node
#  input :
#  output:
sub _setUpperLevelTaxonomy  {

    my $self = shift;

    my $function = "_setUpperLevelTaxonomy";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the sourceDB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  check if the taxonomy is already set
    my $ckeys = keys %childTaxonomyArray;
    my $pkeys = keys %parentTaxonomyArray;
    if($pkeys > 0) { return; }

    #  check if the parent and child tables exist and
    #  if they do just return otherwise create them
    if($self->_checkTableExists($childTable) and
       $self->_checkTableExists($parentTable)) {
        $self->_loadTaxonomyArrays();
        return;
    }
    else {
        $self->_createTaxonomyTables();
    }

    #  if the parent and child files exist just load them into the database
    if( (-e $childFile) and (-e $parentFile) ) {
        $self->_loadTaxonomyTables();
    }
    #  otherwise we need to create them
    else {
        $self->_createUpperLevelTaxonomy();
    }
}

#  this function creates the upper level taxonomy between the
#  the sources and the root UMLS node
#  this function creates the upper level taxonomy between the
#  the sources and the root UMLS node
#  input :
#  output:
sub _createUpperLevelTaxonomy {

    my $self = shift;

    my $function = "_createUpperLevelTaxonomy";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    # open the parent and child files to store the upper level
    #  taxonomy information if the verbose option is defined
    if($option_verbose) {
        open(CHD, ">$childFile")  || die "Could not open $childFile\n";
        open(PAR, ">$parentFile") || die "Could not open $parentFile\n";
    }

    foreach my $sab (sort keys %sabnamesHash) {

        #  get the sab's cui
        my $sab_cui = $self->_getSabCui($sab);
	
        #  select all the CUIs from MRREL
        my $allCuis = $self->_getCuis($sab);

        #  select all the CUI1s from MRREL that have a parent link
        #  if a parent relation exists
        my $parCuis = "";
        my %parCuisHash = ();
        if( !($parentRelations=~/\(\)/) ) {
            $parCuis = $db->selectcol_arrayref("select CUI1 from MRREL where ($parentRelations) and (SAB=\'$sab\') and SUPPRESS='N'");
            $errorhandler->_checkDbError($pkg, $function, $db);

            #  load the cuis that have a parent into a temporary hash
            foreach my $cui (@{$parCuis}) { $parCuisHash{$cui}++; }
        }

        #  load the cuis that do not have a parent into the parent
        #  and chilren taxonomy for the upper level
        foreach my $cui (@{$allCuis}) {

            #  if the cui has a parent move on
            if(exists $parCuisHash{$cui})    { next; }

            #  already seen this cui so move on
            if(exists $parentTaxonomyArray{$cui}) { next; }


            if($sab_cui eq $cui) { next; }

            push @{$parentTaxonomyArray{$cui}}, $sab_cui;
            push @{$childTaxonomyArray{$sab_cui}}, $cui;

            $sdb->do("INSERT INTO $parentTable (CUI1, CUI2) VALUES ('$cui', '$sab_cui')");
            $errorhandler->_checkDbError($pkg, $function, $sdb);

            $sdb->do("INSERT INTO $childTable (CUI1, CUI2) VALUES ('$sab_cui', '$cui')");
            $errorhandler->_checkDbError($pkg, $function, $sdb);

            #  print this information to the parent and child
            #  file is the verbose option has been set
            if($option_verbose) {
                print PAR "$cui $sab_cui\n";
                print CHD "$sab_cui $cui\n";
            }
        }

        #  add the sab cuis to the parent and children Taxonomy
        push @{$parentTaxonomyArray{$sab_cui}}, $umlsRoot;
        push @{$childTaxonomyArray{$umlsRoot}}, $sab_cui;

        #  print it to the table if the verbose option is set
        if($option_verbose) {
            print PAR "$sab_cui  $umlsRoot\n";
            print CHD "$umlsRoot $sab_cui\n";
        }

        #  store this information in the database
        $sdb->do("INSERT INTO $parentTable (CUI1, CUI2) VALUES ('$sab_cui', '$umlsRoot')");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("INSERT INTO $childTable (CUI1, CUI2) VALUES ('$umlsRoot', '$sab_cui')");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }

    #  close the parent and child tables if opened
    if($option_verbose) { close PAR; close CHD; }

    #  print out some information
    my $pkey = keys %parentTaxonomyArray;
    my $ckey = keys %childTaxonomyArray;

    if($debug) {
        print STDERR "Taxonomy is set:\n";
        print STDERR "  parentTaxonomyArray: $pkey\n";
        print STDERR "  childTaxonomyArray: $ckey\n\n";
    }
}

#  this function creates the taxonomy tables if they don't
#  already exist in the umlsinterfaceindex database
#  input :
#  output:
sub _createTaxonomyTables {

    my $self = shift;

    my $function = "_createTaxonomyTables";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  create intrinsic table
    $sdb->do("CREATE TABLE IF NOT EXISTS $intrinsicTable (CUI char(8), LEAVES int, SUBSUMERS int, INDEX(CUI))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  create parent table
    $sdb->do("CREATE TABLE IF NOT EXISTS $parentTable (CUI1 char(8), CUI2 char(8))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  create child table
    $sdb->do("CREATE TABLE IF NOT EXISTS $childTable (CUI1 char(8), CUI2 char(8))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  create info table
    $sdb->do("CREATE TABLE IF NOT EXISTS $infoTable (ITEM char(8), INFO char(8))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  create the index table if it doesn't already exist
    $sdb->do("CREATE TABLE IF NOT EXISTS tableindex (TABLENAME blob(1000000), HEX char(41))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  add them to the index table
    $sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$intrinsicTableHuman', '$intrinsicTable')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
    $sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$parentTableHuman', '$parentTable')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
    $sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$childTableHuman', '$childTable')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
    $sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$infoTableHuman', '$infoTable')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
}

#  this function loads the taxonomy tables if the
#  configuration files exist for them
#  input :
#  output:
sub _loadTaxonomyTables {

    my $self = shift;

    my $function = "_loadTaxonomyTables";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    open(PAR, $parentFile) || die "Could not open $parentFile\n";
    open(CHD, $childFile)  || die "Could not open $childFile\n";

    #  load parent table
    while(<PAR>) {
        chomp;
        if($_=~/^\s*$/) { next; }
        my ($cui1, $cui2) = split/\s+/;

        my $arrRef = $sdb->do("INSERT INTO $parentTable (CUI1, CUI2) VALUES ('$cui1', '$cui2')");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }

    #  load child table
    while(<CHD>) {
        chomp;
        if($_=~/^\s*$/) { next; }
        my ($cui1, $cui2) = split/\s+/;
        my $arrRef = $sdb->do("INSERT INTO $childTable (CUI1, CUI2) VALUES ('$cui1', '$cui2')");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    close PAR; close CHD;
}

#  this function sets the taxonomy arrays
#  input :
#  output:
sub _loadTaxonomyArrays {

    my $self = shift;

    my $function = "_loadTaxonomyArrays";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  set the parent taxonomy
    my $sql = qq{ SELECT CUI1, CUI2 FROM $parentTable};
    my $sth = $sdb->prepare( $sql );
    $sth->execute();
    my($cui1, $cui2);
    $sth->bind_columns( undef, \$cui1, \$cui2 );
    while( $sth->fetch() ) {
        push @{$parentTaxonomyArray{$cui1}}, $cui2;
    }
    $errorhandler->_checkDbError($pkg, $function, $sth);
    $sth->finish();

    #  set the child taxonomy
    $sql = qq{ SELECT CUI1, CUI2 FROM $childTable};
    $sth = $sdb->prepare( $sql );
    $sth->execute();
    $sth->bind_columns( undef, \$cui1, \$cui2 );
    while( $sth->fetch() ) {
        push @{$childTaxonomyArray{$cui1}}, $cui2;
    }
    $errorhandler->_checkDbError($pkg, $function, $sth);
    $sth->finish();
}

#  function checks to see if a given table exists
#  input : $table <- string
#  output: 0 | 1  <- integers
sub _checkTableExists {

    my $self  = shift;
    my $table = shift;

    my $function = "_checkTableExists";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if(!defined $table) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$table.", 4);
    }

    #  check that the database exists
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  set an execute the query to show all of the tables
    my $sth = $sdb->prepare("show tables");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    my $t      = "";
    my %tables = ();
    while(($t) = $sth->fetchrow()) {
        $tables{lc($t)} = 1;
    }
    $sth->finish();

    if(! (exists$tables{lc($table)})) { return 0; }
    else                              { return 1; }

}

#  connect the database to the source db that holds
#  the path tables for user specified source(s) and
#  relation(s)
#  input :
#  output: $sdb <- reference to the database
sub _connectIndexDB {

    my $self = shift;

    my $function = "_connectIndexDB";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    my $sdb = "";
    if(defined $self->{'username'}) {

        my $username = $self->{'username'};
        my $password = $self->{'password'};
        my $hostname = $self->{'hostname'};
        my $socket   = $self->{'socket'};

        eval{$sdb = DBI->connect("DBI:mysql:database=$indexDB;mysql_socket=$socket;host=$hostname",
                                 $username, $password,
                                 {RaiseError => 1, PrintError => 1, AutoCommit => 0 });};

        if($@) { $errorhandler->_error($pkg, $function, "No database to connect to", 1); }
    }
    else {
        my $dsn = "DBI:mysql:$indexDB;mysql_read_default_group=client;";
        eval{$sdb = DBI->connect($dsn);};
        if($@) { $errorhandler->_error($pkg, $function, "No database to connect to", 1); }
    }

    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  set database parameters
    $sdb->{'mysql_enable_utf8'} = 1;
    $sdb->do('SET NAMES utf8');
    $sdb->{mysql_auto_reconnect} = 1;

    $self->{'sdb'} = $sdb;

    return $sdb;
}

#  return the database connection to the umlsinterfaceindex
#  input :
#  output: $sdb <- database handler
sub _getIndexDB {
    my $self = shift;

    my $function = "_getIndexDB";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the databawse
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  return the database
    return $sdb;
}

#  return the database connection to the umls database
#  input :
#  output: $db <- database handler
sub _getDB {
    my $self = shift;

    my $function = "_getDB";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the databawse
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  return the database
    return $db;
}

#  this function creates the umlsinterfaceindex database connection
#  input :
#  output:
sub _createIndexDB {

    my $self = shift;

    my $function = "_createIndexDB";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check that the database exists
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  show all of the databases
    my $sth = $db->prepare("show databases");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the databases in mysql
    my $database  = "";
    my %databases = ();
    while(($database) = $sth->fetchrow()) {
        $databases{$database}++;
    }
    $sth->finish();

    #  removing any spaces that may have been
    #  introduced in while creating its name
    $indexDB=~s/\s+//g;

    #  if the database doesn't exist create it
    if(! (exists $databases{$indexDB})) {
        $db->do("create database $indexDB");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
}

#  gets the DUI of a given CUI
#  input: $concept -> string containing the cui
#  output: $dui -> string containing the dui
sub _getDUI { 
    
    my $self    = shift;
    my $concept = shift;
    
    my $function = "_getDUI";
    
    #  check input values
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check parameters
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }
    
    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my $duis = $db->selectcol_arrayref("select SDUI from MRCONSO where CUI=\'$concept\' and SAB=\'MSH\'"); 
    
    my $dui = shift @{$duis}; 

    return $dui; 
}


#  checks to see if a concept is in the CuiList
#  input : $concept -> string containing the cui
#  output: 1|0      -> indicating if the cui is in the cuilist
sub _inCuiList {

    my $self    = shift;
    my $concept = shift;

    my $function = "_inCuiList";

    #  check input vluaes
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameters
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    if(exists $cuiListHash{$concept}) { return 1; }
    else                              { return 0; }
}


#  if the cuilist option is specified load the information
#  input : $cuilist <- file containing the list of cuis
#  output:
sub _loadCuiList {

    my $self    = shift;
    my $cuilist = shift;

    my $function = "_loadCuiList";

    #  check the input values
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if(defined $cuilist) {
        open(CUILIST, $cuilist) || die "Could not open the cuilist file: $cuilist\n";
        while(<CUILIST>) {
            chomp;

            if(! ($errorhandler->_validCui($_)) ) {
                $errorhandler->_error($pkg, $function, "Incorrect input value ($_) in cuilist.", 6);
            }

            $cuiListHash{$_}++;
        }
    }
}

#  create the configuration file
#  input :
#  output:
sub _setConfigFile {

    my $self   = shift;

    if($option_verbose) {

        my $function = "_setConfigFile";
        &_debug($function);

        if(!defined $self || !ref $self) {
            $errorhandler->_error($pkg, $function, "", 2);
        }

        if(! (-e $configFile)) {

            open(CONFIG, ">$configFile") ||
                die "Could not open configuration file: $configFile\n";

            my @sarray = ();
            my @rarray = ();

            print CONFIG "SAB :: include ";
            while($sources=~/=\'(.*?)\'/g)   { push @sarray, $1; }
            my $slist = join ", ", @sarray;
            print CONFIG "$slist\n";

            print CONFIG "REL :: include ";
            while($relations=~/=\'(.*?)\'/g) { push @rarray, $1; }
            my $rlist = join ", ", @rarray;
            print CONFIG "$rlist\n";

            close CONFIG;

            my $temp = chmod 0777, $configFile;
        }
    }
}


#  set the table and file names that store the upper level taxonomy and path information
#  input :
#  output:
sub _setConfigurationFile {

    my $self = shift;

    my $function = "_setConfigurationFile";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the database name that we are using
    my $database = $self->{'database'};

    #  set appropriate version output
    my $ver = $version;
    $ver=~s/-/_/g;

    #  set table and upper level relations files as well the 
    #  output of the configuration information for the user
    $childFile  = "$umlsinterface/$ver";
    $parentFile = "$umlsinterface/$ver";
    $tableFile  = "$umlsinterface/$ver";

    $configFile = "$umlsinterface/$ver";

    $tableName     = "$ver";
    $intrinsicTable= "$ver";
    $parentTable   = "$ver";
    $childTable    = "$ver";
    $infoTable     = "$ver";
    $cacheTable    = "$ver";

    my $output = "";
    $output .= "UMLS-Interface Configuration Information\n";

    my $saboutput = "";
    my %sabs = ();
    if($defflag == 1) {
        $output .= "  Sources (SABDEF):\n";
	foreach my $sab (sort keys %sabDefHash) { $saboutput .= "    $sab\n"; }
    }
    else {
        $output .= "  Sources (SAB):\n";
	foreach my $sab (sort keys %sabnamesHash) { $saboutput .= "    $sab\n"; }
    }
    

    foreach my $sab (sort keys %sabnamesHash) {
        $tableFile     .= "_$sab";
        $childFile     .= "_$sab";
        $parentFile    .= "_$sab";
        $configFile    .= "_$sab";
        $tableName     .= "_$sab";
        $intrinsicTable.= "_$sab";
        $parentTable   .= "_$sab";
        $childTable    .= "_$sab";
	$cacheTable    .= "_$sab";
        $infoTable     .= "_$sab";
    }

    if($umlsall) {
        $output .= "    UMLS_ALL\n";
    }
    else {
        $output .= $saboutput;
    }

    #  seperate the RELs and the RELAs from $relations
    my %rels = (); my %relas = ();


    if($defflag == 1) {
        $output .= "  Relations (RELDEF):\n";
	foreach my $rel (sort keys %relDefHash) { $rels{$rel}++; }
    }
    else {
	$output .= "  Relations (REL):\n";
	while($relations=~/=\'(.*?)\'/g) {
	    my $rel = $1;
	    if($rel=~/[a-z\_]+/) { $relas{$rel}++; }
	    else                 { $rels{$rel}++; }
	}
    }

    foreach my $rel (sort keys %rels) {
        $tableFile     .= "_$rel";
        $childFile     .= "_$rel";
        $parentFile    .= "_$rel";
        $configFile    .= "_$rel";
        $tableName     .= "_$rel";
        $intrinsicTable.= "_$rel";
        $parentTable   .= "_$rel";
        $childTable    .= "_$rel";
	$cacheTable    .= "_$rel";
        $infoTable     .= "_$rel";

        $output .= "    $rel\n";
    }

    my $rak = keys %relas;
    if($rak > 0) {
        if($defflag == 1) { 
            $output .= "  Relations (RELADEF):\n";
        }
        else {
            $output .= "  Relations (RELA):\n";
        }
    }
    foreach my $rel (sort keys %relas) {
        $tableFile     .= "_$rel";
        $childFile     .= "_$rel";
        $parentFile    .= "_$rel";
        $configFile    .= "_$rel";
        $tableName     .= "_$rel";
        $intrinsicTable.= "_$rel";
        $parentTable   .= "_$rel";
        $childTable    .= "_$rel";
	$cacheTable    .= "_$rel";
        $infoTable     .= "_$rel";

        $output .= "    $rel\n";
    }

    $tableFile     .= "_table";
    $childFile     .= "_child";
    $parentFile    .= "_parent";
    $configFile    .= "_config";
    $tableName     .= "_table";
    $intrinsicTable.= "_intrinsic";
    $parentTable   .= "_parent";
    $childTable    .= "_child";
    $cacheTable    .= "_cache";
    $infoTable     .= "_info";

    #  convert the databases to the hex name
    #  and store the human readable form
    $tableNameHuman      = $tableName;
    $intrinsicTableHuman = $intrinsicTable;
    $childTableHuman     = $childTable;
    $cacheTableHuman     = $cacheTable;
    $parentTableHuman    = $parentTable;
    $infoTableHuman      = $infoTable;

    $tableName      = "a" . sha1_hex($tableNameHuman);
    $intrinsicTable = "a" . sha1_hex($intrinsicTableHuman);
    $childTable     = "a" . sha1_hex($childTableHuman);
    $parentTable    = "a" . sha1_hex($parentTableHuman);
    $infoTable      = "a" . sha1_hex($infoTableHuman);
    $cacheTable     = "a" . sha1_hex($cacheTableHuman);

    if($option_verbose) {
        $output .= "  Configuration file:\n";
        $output .= "    $configFile\n";
    }

    $output .= "  Database: \n";
    $output .= "    $database ($version)\n\n";

    if($option_t == 0) {
        if($option_config) {
            print STDERR "$output\n";
        }
        else {
            print STDERR "UMLS-Interface Configuration Information:\n";
            print STDERR "(Default Information - no config file)\n\n";
            print STDERR "  Sources (SAB):\n";
            print STDERR "     MSH\n";
            print STDERR "  Relations (REL):\n";
            print STDERR "     PAR\n";
            print STDERR "     CHD\n\n";
            print STDERR "  Sources (SABDEF):\n";
            print STDERR "     UMLS_ALL\n";
            print STDERR "  Relations (RELDEF):\n";
            print STDERR "     UMLS_ALL\n";
        }
    }
}

#  set the configuration environment variable
#  input :
#  output:
sub _setEnvironmentVariable {

    my $self = shift;

    my $function = "_setEnvironmentVariable";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if($option_verbose) {
        if(! (defined $umlsinterface) ) {
            my $answerFlag    = 0;
            my $interfaceFlag = 0;

            while(! ($interfaceFlag) ) {

                print STDERR "The UMLSINTERFACE_CONFIGFILE_DIR environment\n";
                print STDERR "variable has not been defined yet. Please \n";
                print STDERR "enter a location that the UMLS-Interface can\n";
                print STDERR "use to store its configuration files:\n";

                $umlsinterface = <STDIN>; chomp $umlsinterface;

                while(! ($answerFlag)) {
                    print STDERR "  Is $umlsinterface the correct location? ";
                    my $answer = <STDIN>; chomp $answer;
                    if($answer=~/[Yy]/) {
                        $answerFlag    = 1;
                        $interfaceFlag = 1;
                    }
                    else {
                        print STDERR "Please entire in location:\n";
                        $umlsinterface = <STDIN>; chomp $umlsinterface;
                    }
                }

                if(! (-e $umlsinterface) ) {
                    system "mkdir -m 777 $umlsinterface";
                }

                print STDERR "Please set the UMLSINTERFACE_CONFIGFILE_DIR variable:\n\n";
                print STDERR "It can be set in csh as follows:\n\n";
                print STDERR " setenv UMLSINTERFACE_CONFIGFILE_DIR $umlsinterface\n\n";
                print STDERR "And in bash shell:\n\n";
                print STDERR " export UMLSINTERFACE_CONFIGFILE_DIR=$umlsinterface\n\n";
                print STDERR "Thank you!\n\n";
            }
        }
    }
    else {
        $umlsinterface = "";
    }
}

#  sets the relations, parentRelations and childRelations
#  variables from the information in the config file
#  input : $includerelkeys <- integer
#        : $excluderelkeys <- integer
#        : $includerel     <- reference to hash
#        : $excluderel     <- reference to hash
#  output:
sub _setRelations {

    my $self           = shift;
    my $includerelkeys = shift;
    my $excluderelkeys = shift;
    my $includerel     = shift;
    my $excluderel     = shift;

    my $function = "_setRelations";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters
    if(!(defined $includerelkeys) || !(defined $excluderelkeys) ||
       !(defined $includerel)     || !(defined $excluderel)) {
        $errorhandler->_error($pkg, $function, "REL variables not defined.", 4);
    }

    if($includerelkeys <= 0 && $excluderelkeys <=0) { return; }

    #  if the umls all option is set clear out the the includerel hash and
    #  add the umlsall to the exclude. This way all should be included since
    #  there will never be a source called UMLS_ALL - this is a bit of a dirty
    #  swap but I think it will simplify the code and work
    if(exists ${$includerel}{"UMLS_ALL"}) {
        $includerel = "";             $includerelkeys = 0;
        ${$excluderel}{"UMLS_ALL"} = 1; $excluderelkeys = 1;

    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    $parentRelations = "(";
    $childRelations  = "(";
    $relations       = "(";

    #  get the relations
    my @array = ();
    if($includerelkeys > 0) {
        @array = keys %{$includerel};
    }
    else {

        my $arrRef = $db->selectcol_arrayref("select distinct REL from MRREL");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
    }


    my $relcount = 0;
    my @parents  = ();
    my @children = ();
    foreach my $rel (@array) {

        $relcount++;

        #  if we are excluding check to see if this one should be excluded
        if( ($excluderelkeys > 0) and (exists ${$excluderel}{$rel}) ) { next; }

        #  otherwise store the relation in the relations variable
        if($relcount == ($#array+1)) { $relations .= "REL=\'$rel\'";     }
        else                         { $relations .= "REL=\'$rel\' or "; }

        #  put it in its proper parent or child array
        if   ($rel=~/(PAR|RB)/) { push @parents, $rel;    }
        elsif($rel=~/(CHD|RN)/) { push @children, $rel;   }
        else { push @parents, $rel; push @children, $rel; }

    }

    #  set the parentRelations and childRelations variables
    if($#parents >= 0) {
        for my $i (0..($#parents-1)) {
            $parentRelations .= "REL=\'$parents[$i]\' or ";
        } $parentRelations .= "REL=\'$parents[$#parents]\'";
    }
    if($#children >= 0) {
        for my $i (0..($#children-1)) {
            $childRelations .= "REL=\'$children[$i]\' or ";
        } $childRelations .= "REL=\'$children[$#children]\'";
    }

    $parentRelations .= ") ";
    $childRelations  .= ") ";
    $relations       .= ") ";

}

#  sets the source variables from the information in the config file
#  input : $includesabdefkeys <- integer
#        : $excludesabdefkeys <- integer
#        : $includedefsab     <- reference to hash
#        : $excludedefsab     <- reference to hash
#  output:
sub _setSabDef {

    my $self              = shift;
    my $includesabdefkeys = shift;
    my $excludesabdefkeys = shift;
    my $includesabdef     = shift;
    my $excludesabdef     = shift;

    my $function = "_setSabDef";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $includesabdefkeys) || !(defined $excludesabdefkeys) ||
       !(defined $includesabdef)     || !(defined $excludesabdef)) {
        $errorhandler->_error($pkg, $function, "SAB variables not defined", 4);
    }

    if($includesabdefkeys <= 0 && $excludesabdefkeys <=0) { return; }

    $sabdef_umlsall = 0;

    #  if the umls all option is set clear out the the includesabdef hash and
    #  add the umlsall to the exclude. This way all should be included since
    #  there will never be a source called UMLS_ALL - this is a bit of a dirty
    #  swap but I think it will simplify the code and work
    if(exists ${$includesabdef}{"UMLS_ALL"}) {
        $includesabdef = "";               $includesabdefkeys = 0;
        ${$excludesabdef}{"UMLS_ALL"} = 1; $excludesabdefkeys = 1;
        $sabdef_umlsall = 1;
    }

    #  check that the db is defined
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the sabs
    my @array = ();
    if($includesabdefkeys > 0) {
        @array = keys %{$includesabdef};
    }
    else {
        my $arrRef = $db->selectcol_arrayref("select distinct SAB from MRREL");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
    }

    #  get the sabs
    my $sabcount = 0; my @sabarray = ();
    foreach my $sab (@array) {
        $sabcount++;

        #  if we are excluding check to see if this sab can be included
        if(($excludesabdefkeys > 0) and (exists ${$excludesabdef}{$sab})) { next; }

        #  otherwise store it in the sabdef hash and store it in the array
        push @sabarray, "SAB=\'$sab\'";

        $sabDefHash{$sab}++;
    }

    if(!$sabdef_umlsall) {
        my $string = join " or ", @sabarray;
        $sabdefsources = "( $string )";
    }
}

#  sets the relations, parentRelations and childRelations
#  variables from the information in the config file
#  input : $includereldefkeys <- integer
#        : $excludereldefkeys <- integer
#        : $includereldef     <- reference to hash
#        : $excludereldef     <- reference to hash
#  output:
sub _setRelDef {

    my $self           = shift;
    my $includereldefkeys = shift;
    my $excludereldefkeys = shift;
    my $includereldef     = shift;
    my $excludereldef     = shift;

    my $function = "_setRelDef";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $includereldefkeys) || !(defined $excludereldefkeys) ||
       !(defined $includereldef)     || !(defined $excludereldef)) {
        $errorhandler->_error($pkg, $function, "RELDEF variables not defined.", 4);
    }

    if($includereldefkeys <= 0 && $excludereldefkeys <=0) { return; }

    #  if the umls all option is set clear out the the includereldef hash and
    #  add the umlsall to the exclude. This way all should be included since
    #  there will never be a source called UMLS_ALL - this is a bit of a dirty
    #  swap but I think it will simplify the code and work
    if(exists ${$includereldef}{"UMLS_ALL"}) {
        $includereldef = "";               $includereldefkeys = 0;
        ${$excludereldef}{"UMLS_ALL"} = 1; $excludereldefkeys = 1;
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the relations
    my @array = ();
    if($includereldefkeys > 0) {
        @array = keys %{$includereldef};
    }
    else {

        my $arrRef = $db->selectcol_arrayref("select distinct REL from MRREL");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
    }

    my $relcount = 0;

    foreach my $rel (@array) {

        $relcount++;

        #  if we are excluding check to see if this one should be excluded
        if( ($excludereldefkeys > 0) and (exists ${$excludereldef}{$rel}) ) { next; }

        #  otherwise store the relation in the reldef hash
        $relDefHash{$rel}++;
    }


    #  now add the TERM and CUI which are not actual relations but should be in
    #  the relDefHash if in the includereldef or not in the excludereldef or
    #  nothing has been defined
    if($includereldefkeys > 0) {
        if(exists ${$includereldef}{"TERM"}) { $relDefHash{"TERM"}++; }
        if(exists ${$includereldef}{"CUI"})  { $relDefHash{"CUI"}++;  }
        if(exists ${$includereldef}{"ST"})   { $relDefHash{"ST"}++;  }
    }
    elsif($excludereldefkeys > 0) {
        if(! exists ${$excludereldef}{"TERM"}) { $relDefHash{"TERM"}++; }
        if(! exists ${$excludereldef}{"CUI"})  { $relDefHash{"CUI"}++;  }
        if(! exists ${$excludereldef}{"ST"})  { $relDefHash{"ST"}++;  }
    }
    else {
        $relDefHash{"TERM"}++; $relDefHash{"CUI"}++; $relDefHash{"ST"}++;
    }
}

#  sets the variables for using the entire umls rather than just a subset
#  input :
#  output:
sub _setSabUmlsAll {

    my $self = shift;

    my $function = "_setSabUmlsAll";
    &_debug($function);

    #  check input value
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my $arrRef = $db->selectcol_arrayref("select distinct SAB from MRREL where $relations");
    $errorhandler->_checkDbError($pkg, $function, $db);

    foreach my $sab (@{$arrRef}) {
        my $cui = $self->_getSabCui($sab);

        $sabnamesHash{$sab}++;
        $sabHash{$cui}++;
    }
}

#  sets the source variables from the information in the config file
#  input : $includesabkeys <- integer
#        : $excludesabkeys <- integer
#        : $includesab     <- reference to hash
#        : $excludesab     <- reference to hash
#  output:
sub _setSabs {

    my $self           = shift;
    my $includesabkeys = shift;
    my $excludesabkeys = shift;
    my $includesab     = shift;
    my $excludesab     = shift;

    my $function = "_setSabs";
    &_debug($function);

    #  check input value
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $includesabkeys) || !(defined $excludesabkeys) ||
       !(defined $includesab)     || !(defined $excludesab)) {
        $errorhandler->_error($pkg, $function, "SAB variables not defined.", 4);
    }

    #  return if no sab or rel options were in the config file
    if($includesabkeys <= 0 && $excludesabkeys <=0) { return; }

    #  initialize the sources
    $sources = "";

    #  if the umls all option is set clear out the the includesab hash and
    #  add the umlsall to the exclude. This way all should be included since
    #  there will never be a source called UMLS_ALL - this is a bit of a dirty
    #  swap but I think it will simplify the code and work
    if(exists ${$includesab}{"UMLS_ALL"}) {
        $includesab = "";             $includesabkeys = 0;
        ${$excludesab}{"UMLS_ALL"} = 1; $excludesabkeys = 1;
        $umlsall = 1;
        $sources = "UMLS_ALL";
    }

    #  check that the db is defined
    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the sabs
    my @array = ();
    if($includesabkeys > 0) {
        @array = keys %{$includesab};
    }
    else {
        my $arrRef = $db->selectcol_arrayref("select distinct SAB from MRREL where $relations");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
    }

    my $sabcount = 0;
    foreach my $sab (@array) {

        $sabcount++;

        #  if we are excluding check to see if this sab can be included
        if(($excludesabkeys > 0) and (exists ${$excludesab}{$sab})) { next; }

        #  include the sab in the sources variable
        if($sabcount == ($#array+1)) { $sources .="SAB=\'$sab\'";     }
        else                         { $sources .="SAB=\'$sab\' or "; }

        #  get the sabs cui
        my $cui = $self->_getSabCui($sab);

        #  store the sabs cui and name information
        $sabnamesHash{$sab}++;
        $sabHash{$cui}++;
    }
}

#  sets the rela variables from the information in the config file
#  input : $includerelakeys <- integer
#        : $excluderelakeys <- integer
#        : $includerela     <- reference to hash
#        : $excluderela     <- reference to hash
#  output:
sub _setRelas {

    my $self           = shift;
    my $includerelakeys = shift;
    my $excluderelakeys = shift;
    my $includerela     = shift;
    my $excluderela     = shift;

    my $function = "_setRelas";
    &_debug($function);

    #  check the input values
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $includerelakeys) || !(defined $excluderelakeys) ||
       !(defined $includerela)     || !(defined $excluderela)) {
        $errorhandler->_error($pkg, $function, "RELA variables not defined.", 4);
    }

    #  if no relas were specified just return
    if($includerelakeys <= 0 && $excluderelakeys <=0) { return }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  initalize the hash tables that will hold children and parent relas
    my %childrelas  = ();
    my %parentrelas = ();

    #  set the parent relations
    my $prelations = "";
    if($relations=~/PAR/) {
        if($relations=~/RB/) {
            $prelations = "(REL='PAR') or (REL='RB')";
        } else { $prelations = "(REL='PAR')"; }
    } elsif($relations=~/RB/) { $prelations = "(REL='RB')"; }

    #  set the child relations
    my $crelations = "";
    if($relations=~/CHD/) {
        if($relations=~/RN/) {
            $crelations = "(REL='CHD') or (REL='RN')";
        } else { $crelations = "(REL='CHD')"; }
    } elsif($relations=~/RB/) { $crelations = "(REL='RN')"; }

    #  get the rela relations that exist for the given set of sources and
    #  relations for the children relations that are specified in the config
    my $sth = "";
    if($umlsall) {
        $sth = $db->prepare("select distinct RELA from MRREL where $crelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    else {
        $sth = $db->prepare("select distinct RELA from MRREL where $crelations and ($sources)");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the relas for the children
    my $crela = "";
    while(($crela) = $sth->fetchrow()) {
        if(defined $crela) {
            if($crela ne "NULL") {
                $childrelas{$crela}++;
            }
        }
    }
    $sth->finish();

    my $crelakeys = keys %childrelas;
    if($crelakeys <= 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "There are no RELA relations for the given sources/relations.",
                              5);
    }


    #  get the rela relations that exist for the given set of sources and
    #  relations for the children relations that are specified in the config
    if($umlsall) {
        $sth = $db->prepare("select distinct RELA from MRREL where $prelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    else {
        $sth = $db->prepare("select distinct RELA from MRREL where $prelations and ($sources)");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the relas for the parents
    my $prela = "";
    while(($prela) = $sth->fetchrow()) {
        if(defined $prela) {
            if($prela ne "NULL") {
                $parentrelas{$prela}++;
            }
        }
    }
    $sth->finish();

    my $prelakeys = keys %parentrelas;
    if($prelakeys <= 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "There are no RELA relations for the given sources.",
                              5);
    }

    #  uses the relas that are set in the includrelakeys or excluderelakeys
    my @array = ();
    if($includerelakeys > 0) {
        @array = keys %{$includerela};
    }
    else {

        my $arrRef =
            $db->selectcol_arrayref("select distinct RELA from MRREL where ($sources) and $prelations and $crelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
        shift @array;
    }

    my @crelas = ();
    my @prelas = ();
    my $relacount = 0;

    my @newrelations = ();

    foreach my $r (@array) {

        $relacount++;

        if( ($excluderelakeys > 0) and (exists ${$excluderela}{$r}) ) { next; }

        push @newrelations, "RELA=\'$r\'";

        if(exists $childrelas{$r})     { push @crelas, "RELA=\'$r\'";  }
        elsif(exists $parentrelas{$r}) { push @prelas, "RELA=\'$r\'";  }
        else {
            my $errorstring = "RELA relation ($r) does not exist for the given sources/relations.";
            $errorhandler->_error($pkg, $function, $errorstring, 5);
        }
    }

    if($#newrelations >= 0) {
        my $string = join " or ", @newrelations;

        $relations .= "and ( $string )";

        my $crelasline = join " or ", @crelas;
        my $prelasline = join " or ", @prelas;

        #  set the parent relations
        if($parentRelations=~/PAR/) {
            $parentRelations=~s/REL='PAR'/\(REL='PAR' and \($prelasline\)\)/g;
            $relations=~s/REL='PAR'/\(REL='PAR' and \($prelasline\)\)/g;
        }
        if($parentRelations=~/RB/) {
            $parentRelations=~s/REL='RB'/\(REL='RB' and \($prelasline\)\)/g;
            $relations=~s/REL='RB'/\(REL='RB' and \($prelasline\)\)/g;
        }
        #  set the child relations
        if($childRelations=~/CHD/) {
            $childRelations=~s/REL='CHD'/\(REL='CHD' and \($crelasline\)\)/g;
            $relations=~s/REL='CHD'/\(REL='CHD' and \($crelasline\)\)/g;
        }
        if($childRelations=~/RN/) {
            $childRelations=~s/REL='RN'/\(REL='RN' and \($crelasline\)\)/g;
            $relations=~s/REL='RN'/\(REL='RN' and \($crelasline\)\)/g;
        }
    }
}

#  sets the reladef variables from the information in the config file
#  input : $includereladefkeys <- integer
#        : $excludereladefkeys <- integer
#        : $includereladef     <- reference to hash
#        : $excludereladef     <- reference to hash
#  output:
sub _setRelaDef {

    my $self               = shift;
    my $includereladefkeys = shift;
    my $excludereladefkeys = shift;
    my $includereladef     = shift;
    my $excludereladef     = shift;

    my $function = "_setRelaDef";
    &_debug($function);

    #  check the input values
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $includereladefkeys) || !(defined $excludereladefkeys) ||
       !(defined $includereladef)     || !(defined $excludereladef)) {
        $errorhandler->_error($pkg, $function, "RELADEF variables not defined.", 4);
    }

    #  if no relas were specified just return
    if($includereladefkeys <= 0 && $excludereladefkeys <=0) { return; }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  initalize the hash tables that will hold children and parent relas
    my %childrelas  = ();
    my %parentrelas = ();

    #  set the parent relations
    my $prelations = "";
    if($reldefstring=~/PAR/) {
        if($reldefstring=~/RB/) {
            $prelations = "(REL='PAR') or (REL='RB')";
        } else { $prelations = "(REL='PAR')"; }
    } elsif($reldefstring=~/RB/) { $prelations = "(REL='RB')"; }

    #  set the child relations
    my $crelations = "";
    if($reldefstring=~/CHD/) {
        if($reldefstring=~/RN/) {
            $crelations = "(REL='CHD') or (REL='RN')";
        } else { $crelations = "(REL='CHD')"; }
    } elsif($reldefstring=~/RB/) { $crelations = "(REL='RN')"; }

    #  get the rela relations that exist for the given set of sources and
    #  relations for the children relations that are specified in the config
    my $sth = "";
    if($umlsall) {
        $sth = $db->prepare("select distinct RELA from MRREL where $crelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    else {
        $sth = $db->prepare("select distinct RELA from MRREL where $crelations and ($sabdefsources)");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the relas for the children
    my $crela = "";
    while(($crela) = $sth->fetchrow()) {
        if(defined $crela) {
            if($crela ne "NULL") {
                $childrelas{$crela}++;
            }
        }
    }
    $sth->finish();

    my $crelakeys = keys %childrelas;
    if($crelakeys <= 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "There are no RELA relations for the given sources/relations.",
                              5);
    }

    #  get the rela relations that exist for the given set of sources and
    #  relations for the children relations that are specified in the config
    if($umlsall) {
        $sth = $db->prepare("select distinct RELA from MRREL where $prelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    else {
        $sth = $db->prepare("select distinct RELA from MRREL where $prelations and ($sabdefsources)");
        $errorhandler->_checkDbError($pkg, $function, $db);
    }
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the relas for the parents
    my $prela = "";
    while(($prela) = $sth->fetchrow()) {
        if(defined $prela) {
            if($prela ne "NULL") {
                $parentrelas{$prela}++;
            }
        }
    }
    $sth->finish();

    my $prelakeys = keys %parentrelas;
    if($prelakeys <= 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "There are no RELA relations for the given sources.",
                              5);
    }

    #  uses the relas that are set in the includrelakeys or excludereladefkeys
    my @array = ();
    if($includereladefkeys > 0) {
        @array = keys %{$includereladef};
    }
    else {

        my $arrRef =
            $db->selectcol_arrayref("select distinct RELA from MRREL where ($sources) and $prelations and $crelations");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @array = @{$arrRef};
        shift @array;
    }

    my @crelas = ();
    my @prelas = ();
    my $relacount = 0;

    my @newrelations = ();

    foreach my $r (@array) {

        $relacount++;

        if( ($excludereladefkeys > 0) and (exists ${$excludereladef}{$r}) ) { next; }

        push @newrelations, "RELA=\'$r\'";

        if(exists $childrelas{$r})     { push @crelas, "RELA=\'$r\'";  }
        elsif(exists $parentrelas{$r}) { push @prelas, "RELA=\'$r\'";  }
        else {
            my $errorstring = "RELA relation ($r) does not exist for the given sources/relations.";
            $errorhandler->_error($pkg, $function, $errorstring, 5);
        }
    }

    if($#newrelations >= 0) {
        my $string = join " or ", @newrelations;

        $relations .= "and ( $string )";

        $reladefchildren = join " or ", @crelas;
        $reladefparents  = join " or ", @prelas;
    }
}

#  This sets the sources that are to be used. These sources
#  are found in the config file. The defaults are:
#  input : $file <- string
#  output:
sub _config {

    my $self = shift;
    my $file = shift;

    my $function = "_config";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    my %includesab     = ();    my %excludesab     = ();
    my %includerel     = ();    my %excluderel     = ();
    my %includerela    = ();    my %excluderela    = ();
    my %includereldef  = ();    my %excludereldef  = ();
    my %includesabdef  = ();    my %excludesabdef  = ();
    my %includereladef = ();    my %excludereladef = ();

    my %check = ();

    if(defined $file) {
        open(FILE, $file) || die "Could not open configuration file: $file\n";
        while(<FILE>) {
            chomp;
	    #  if blank line skip
            if($_=~/^\s*$/) { next; }

            if($_=~/([A-Z]+)\s*\:\:\s*(include|exclude)\s+(.*)/) {

                my $type = $1;
                my $det  = $2;
                my $list = $3;

                #  catch what types are in the config file for checking
                #  right now the checking is pretty simple but I think
                #  in the future as others get added it might be more
                #  extensive
                $check{$type}++;

                my @array = split/\s*\,\s*/, $list;
                foreach my $element (@array) {

                    $element=~s/^\s+//g; $element=~s/\s+$//g;
                    if(   $type eq "SAB"    and $det eq "include") { $includesab{$element}++;
                                                                     $sabstring  = $_;
                                                                     $parameters{"SAB"}++;
                    }
                    elsif($type eq "SAB"    and $det eq "exclude") { $excludesab{$element}++;
                                                                     $sabstring  = $_;
                                                                     $parameters{"SAB"}++;
                    }
                    elsif($type eq "REL"    and $det eq "include") { $includerel{$element}++;
                                                                     $relstring  = $_;
                                                                     $parameters{"REL"}++;
                    }
                    elsif($type eq "REL"    and $det eq "exclude") { $excluderel{$element}++;
                                                                     $relstring  = $_;
                                                                     $parameters{"REL"}++;
                    }
                    elsif($type eq "RELA"   and $det eq "include") { $includerela{$element}++;
                                                                     $relastring = $_;
                                                                     $parameters{"RELA"}++;
                    }
                    elsif($type eq "RELA"   and $det eq "exclude") { $excluderela{$element}++;
                                                                     $relastring = $_;
                                                                     $parameters{"RELA"}++;
                    }
                    elsif($type eq "RELDEF" and $det eq "include") { $includereldef{$element}++;
                                                                     $reldefstring = $_;
                                                                     $parameters{"RELDEF"}++;
                    }
                    elsif($type eq "RELDEF" and $det eq "exclude") { $excludereldef{$element}++;
                                                                     $reldefstring = $_;
                                                                     $parameters{"RELDEF"}++;
                    }
                    elsif($type eq "SABDEF" and $det eq "include") { $includesabdef{$element}++;
                                                                     $sabdefstring = $_;
                                                                     $parameters{"SABDEF"}++;
                    }
                    elsif($type eq "SABDEF" and $det eq "exclude") { $excludesabdef{$element}++;
                                                                     $sabdefstring = $_;
                                                                     $parameters{"SABDEF"}++;
                    }
                    elsif($type eq "RELADEF" and $det eq "include"){ $includereladef{$element}++;
                                                                     $parameters{"RELADEF"}++;
                    }
                    elsif($type eq "RELADEF" and $det eq "exclude"){ $excludereladef{$element}++;
                                                                     $parameters{"RELADEF"}++;
                    }
                }
            }
            else {
                $errorhandler->_error($pkg, $function, "Format not correct ($_)", 5);
            }
        }
    }


    
    #  check about the UMLS_ALL option in RELA and RELADEF
    #  this is the default so just remove them - it is here
    #  for the user not really for us
    if(exists $includerela{"UMLS_ALL"})    { %includerela    = (); }
    if(exists $includereladef{"UMLS_ALL"}) { %includereladef = (); }

    my $includesabkeys     = keys %includesab;
    my $excludesabkeys     = keys %excludesab;
    my $includerelkeys     = keys %includerel;
    my $excluderelkeys     = keys %excluderel;
    my $includerelakeys    = keys %includerela;
    my $excluderelakeys    = keys %excluderela;
    my $includereldefkeys  = keys %includereldef;
    my $excludereldefkeys  = keys %excludereldef;
    my $includesabdefkeys  = keys %includesabdef;
    my $excludesabdefkeys  = keys %excludesabdef;
    my $includereladefkeys = keys %includereladef;
    my $excludereladefkeys = keys %excludereladef;

    #  check for errors
    if( (!exists $check{"SAB"} && exists $check{"REL"}) ||
        (!exists $check{"REL"} && exists $check{"SAB"}) ) {
        $errorhandler->_error($pkg,
                              $function,
                              "Configuration file must include both REL and SAB information.",
                              5);
    }
    if( (!exists $check{"SABDEF"} && exists $check{"RELDEF"}) ||
        (!exists $check{"RELDEF"} && exists $check{"SABDEF"}) ) {
        $errorhandler->_error($pkg,
                              $function,
                              "Configuration file must include both RELDEF and SABDEF information.",
                              5);
    }
    if($includesabkeys > 0 && $excludesabkeys > 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "Configuration file can not have an include and exclude list of sources.",
                              5);
    }
    if($includerelkeys > 0 && $excluderelkeys > 0) {
        $errorhandler->_error($pkg,
                              $function,
                              "Configuration file can not have an include and exclude list of relations.",
                              5);
    }
    if( ($includerelkeys <= 0 && $excluderelkeys <= 0) &&
        ($includerelakeys > 0 || $excluderelakeys > 0) ) {
        $errorhandler->_error($pkg,
                              $function,
                              "The relations (REL) must be specified if using the rela relations (RELA).",
                              5);
    }
    if( ($includereldefkeys <= 0 && $excludereldefkeys <= 0) &&
        ($includereladefkeys > 0 || $excludereladefkeys > 0) ) {
        $errorhandler->_error($pkg,
                              $function,
                              "The relations (RELDEF) must be specified if using the rela relations (RELADEF).",
                              5);
    }


    #  set the defaults
    if($includerelkeys <= 0 && $excluderelkeys <= 0) { 
	$includesab{"MSH"}++;
        $includerel{"PAR"}++;
        $includerel{"CHD"}++;

        $sabstring = "SAB :: include MSH";
        $relstring = "REL :: include CHD, PAR";

	$includerelkeys = keys %includerel;
	$includesabkeys = keys %includesab;
    }

    #  set the defaults
    if($includereldefkeys <= 0 && $excludereldefkeys <= 0) { 
	
	$includesabdef{"UMLS_ALL"}++;
        $includereldef{"UMLS_ALL"}++;

        $sabdefstring = "SAB :: include UMLS_ALL";
        $reldefstring = "REL :: include UMLS_ALL";

	$includereldefkeys = keys %includereldef;
	$includesabdefkeys = keys %includesabdef;
	
    }
    else {
	$defflag = 1;
    }

    #  The order matters here so don't mess with it! The relations have to be set
    #  prior to the sabs and both need to be set prior to the relas.

    #  set the relations
    $self->_setRelations($includerelkeys, $excluderelkeys, \%includerel, \%excluderel);

    #  set the sabs
    $self->_setSabs($includesabkeys, $excludesabkeys, \%includesab, \%excludesab);

    #  set the relas as long as there exists a PAR/CHD or RB/RN relation
    if($relations=~/(PAR|CHD|RB|RN)/) {
        $self->_setRelas($includerelakeys, $excluderelakeys, \%includerela, \%excluderela);
    }
    else {
        if(($includerelkeys > 0  || $excluderelkeys > 0) &&
           ($includerelakeys > 0 || $excluderelakeys > 0) ) {
            $errorhandler->_error($pkg,
                                  $function,
                                  "The rela relations (RELA) can only be used with the PAR/CHD or RB/RN relations (REL).",
                                  5);
        }
    }

    #  set the sabs for the CUI and extended definitions
    $self->_setSabDef($includesabdefkeys, $excludesabdefkeys, \%includesabdef, \%excludesabdef);

    #  set the rels for the extended definition
    $self->_setRelDef($includereldefkeys, $excludereldefkeys, \%includereldef, \%excludereldef);

    #  set the relas for the extended definition
    if($reldefstring=~/(PAR|CHD|RB|RN)/) {
        $self->_setRelaDef($includereladefkeys, $excludereladefkeys, \%includereladef, \%excludereladef);
    }
    else {
        if(($includereldefkeys > 0  || $excludereldefkeys > 0) &&
           ($includereladefkeys > 0 || $excludereladefkeys > 0) ) {
            $errorhandler->_error($pkg,
                                  $function,
                                  "The rela relations (RELADEF) can only be used with the PAR/CHD or RB/RN relations (RELDEF).",
                                  5);
        }
    }

    #  now at this point everything that is set with the names are set
    #  if though SABDEF has been set without SAB then use SABDEF
    #  similarity if SABREL has been set without REL then use SABREL
    #  set the relations - this is done right now to extract terms and
    #  and such from the umls - I don't really like how this is done but
    #  it will be okay for right now. It would be nice to have them
    #  completely seperate. Doing it this way though allows for the REL,
    #  SAB, RELDEF and SABDEF to all be specified - again order matters here.

    #if($includerelkeys == 0 && $excluderelkeys == 0) {
    #    $self->_setRelations($includereldefkeys, $excludereldefkeys, \%includereldef, \%excludereldef);
    #}
    #if($includesabkeys == 0 && $excludesabkeys == 0) {
     #   $self->_setSabs($includesabdefkeys, $excludesabdefkeys, \%includesabdef, \%excludesabdef);
    #}
    #if($includerelkeys == 0 && $excluderelkeys == 0) {
    #    if($relations=~/(PAR|CHD|RB|RN)/) {
    #        $self->_setRelas($includereladefkeys, $excludereladefkeys, \%includereladef, \%excludereladef);
    #    }
    #}

    if($debug) {
        if($umlsall) { print STDERR "SOURCE   : UMLS_ALL\n"; }
        else         { print STDERR "SOURCE   : $sources\n"; }
        print STDERR "RELATIONS: $relations\n";
        print STDERR "PARENTS  : $parentRelations\n";
        print STDERR "CHILDREN : $childRelations\n\n";
	if($sabdefsources eq "") { 
	    print STDERR "SABDEF   : UMLS_ALL\n";
	}
	else {
	    print STDERR "SABDEF   : $sabdefsources\n";
	}
	my $reldefrelations = "UMLS_ALL";
	if($reldefstring ne "") { 
	    $reldefstring=~/RELDEF :: include ([A-Z0-9\, ]+)/; 
	    $reldefrelations = $1;
	}
        print STDERR "RELDEF   : $reldefrelations\n";
	print STDERR "SAB : $sources\n";
	print STDERR "REL : $relations\n";
    }
}

#  returns the SAB from the configuratino file
#  input :
#  output: $string <- containing SAB line from config file
sub _getSabString {
    my $self = shift;

    return $sabstring;
}

#  returns the REL from the configuratino file
#  input :
#  output: $string <- containing REL line from config file
sub _getRelString {
    my $self = shift;

    return $relstring;
}

#  returns the RELA from the configuratino file
#  input :
#  output: $string <- containing RELA line from config file
sub _getRelaString {
    my $self = shift;

    return $relastring;
}

#  returns the SABDEF from the configuratino file
#  input :
#  output: $string <- containing SABDEF line from config file
sub _getSabDefString {
    my $self = shift;

    return $sabdefstring;
}

#  returns the RELDEF from the configuratino file
#  input :
#  output: $string <- containing RELDEF line from config file
sub _getRelDefString {
    my $self = shift;

    return $reldefstring;
}



#  set the version
#  input :
#  output:
sub _setVersion {

    my $self = shift;

    my $function = "_setVersion";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the verstion information
    my $arrRef = $db->selectcol_arrayref("select EXPL from MRDOC where VALUE = \'mmsys.version\'");
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  check that it was returned
    if(scalar(@{$arrRef}) < 1) {
        $errorhandler->_error($pkg, $function, "No version info in table MRDOC.", 7);
    }

    ($version) = @{$arrRef};
}


#  check if the UMLS tables required all exist
#  input :
#  output:
sub _checkTablesExist {

    my $self = shift;

    my $function = "_checkTablesExist";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  check if the tables exist...
    my $sth = $db->prepare("show tables");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    my $table = "";
    my %tables = ();
    while(($table) = $sth->fetchrow()) {
        $tables{$table} = 1;
    }
    $sth->finish();

    if(!defined $tables{"MRCONSO"} and !defined $tables{"mrconso"}) {
        $errorhandler->_error($pkg, $function, "Table MRCONSO not found in database", 7);
    }
    if(!defined $tables{"MRDEF"} and !defined $tables{"mrdef"}) {
        $errorhandler->_error($pkg, $function, "Table MRDEF not found in database", 7);
    }
    if(!defined $tables{"SRDEF"} and !defined $tables{"srdef"}) {
        $errorhandler->_error($pkg, $function, "Table SRDEF not found in database", 7);
    }
    if(!defined $tables{"MRREL"} and !defined $tables{"mrrel"}) {
        $errorhandler->_error($pkg, $function, "Table MRREL not found in database", 7);
    }
    if(!defined $tables{"MRDOC"} and !defined $tables{"mrdoc"}) {
        $errorhandler->_error($pkg, $function, "Table MRDEC not found in database", 7);
    }
    if(!defined $tables{"MRSAB"} and !defined $tables{"mrsab"}) {
        $errorhandler->_error($pkg, $function, "Table MRSAB not found in database", 7);
    }
}

#  method to set the global parameter options
#  input : $params <- reference to a hash
#  output:
sub _setOptions  {
    my $self = shift;
    my $params = shift;

    my $function = "_setOptions";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the params
    $params = {} if(!defined $params);

    #  get all the parameters
    my $verbose      = $params->{'verbose'};
    my $cuilist      = $params->{'cuilist'};
    my $t            = $params->{'t'};
    my $debugoption  = $params->{'debug'};
    my $config       = $params->{'config'};

    if(defined $t) {
        $option_t = 1;
    }

    my $output = "";

    if(defined $verbose || defined $cuilist ||
       defined $debugoption || defined $config)  {
        $output  .= "\nCuiFinder User Options: \n";
    }

    #  check the debug option
    if(defined $debugoption) {
        $debug = 1;
        $output .= "  --debug";
    }

    #  check if verbose run has been identified
    if(defined $verbose) {
        $option_verbose = 1;
        $output .= "   --verbose option set\n";
    }


    #  check if the cuilist option has been set
    if(defined $cuilist) {
        $option_cuilist = 1;
        $output .= "   --cuilist option set\n";
    }

    #  check if the config file is set
    if(defined $config) {
        $option_config = 1;
        $output .= "   --config option set\n";
    }

    if($option_t == 0) {
        print STDERR "$output\n\n";
    }
}

#  method to set the umlsinterface index database
#  input : $params <- reference to a hash
#  output:
sub _setDatabase  {

    my $self   = shift;
    my $params = shift;

    my $function = "_setDatabase";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the params
    $params = {} if(!defined $params);

    #  get the database connection parameters
    my $database     = $params->{'database'};
    my $hostname     = $params->{'hostname'};
    my $socket       = $params->{'socket'};
    my $port         = $params->{'port'};
    my $username     = $params->{'username'};
    my $password     = $params->{'password'};

    #  set up defaults if the options were not passed
    if(! defined $database) { $database = "umls";            }
    if(! defined $socket)   { $socket   = "/var/run/mysqld/mysqld.sock"; }
    if(! defined $hostname) { $hostname = "localhost";       }

    #  initialize the database handler
    my $db = "";

    #  create the database object...
    if(defined $username and defined $password) {
        if($debug) { print STDERR "Connecting with username and password\n"; }
        $db = DBI->connect("DBI:mysql:database=$database;mysql_socket=$socket;host=$hostname",$username, $password, {RaiseError => 0});
    }
    else {
        if($debug) { print STDERR "Connecting using the my.cnf file\n"; }
        my $dsn = "DBI:mysql:umls;mysql_read_default_group=client;";
        $db = DBI->connect($dsn);
    }

    #  check if there is an error
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  check that the db exists
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  set database parameters
    $db->{'mysql_enable_utf8'} = 1;
    $db->do('SET NAMES utf8');
    $db->{mysql_auto_reconnect} = 1;

    #  set the self parameters
    $self->{'db'}           = $db;
    $self->{'username'}     = $username;
    $self->{'password'}     = $password;
    $self->{'hostname'}     = $hostname;
    $self->{'socket'}       = $socket;
    $self->{'database'}     = $database;

    #  return the database handler
    return $db;
}

#  returns the parameters set in the configuration file
#  input:
#  output : $hash <- reference to hash containing parameters in the
#                    configuration file - if there was not config
#                    file the hash is empty and defaults are being
#                    use
sub _getConfigParameters {
    my $self = shift;

    my $function = "_getConfigParameters";

    return \%parameters;
}

#  returns all of the cuis given the specified set of sources
#  and relations defined in the configuration file
#  input : $sab   <- string containing a source
#  output: $array <- reference to array of cuis
sub _getCuis {

    my $self = shift;
    my $sab  = shift;

    my $function = "_getCuis";
    #&_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check input variables
    if(!$sab) { $errorhandler->_error($pkg, $function, "Error with input variable \$sab.", 4); }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  NOTE: it is quicker to get all the CUI1s and then all of the CUI2 and then merge
    #        rather than try to get them all together in a single query.
    #  get all of the CUI1s
    my $allCui1 = $db->selectcol_arrayref("select CUI1 from MRREL where ($relations) and (SAB=\'$sab\') and SUPPRESS='N'\;");
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  get all of the CUI1s
    my $allCui2 = $db->selectcol_arrayref("select CUI2 from MRREL where ($relations) and (SAB=\'$sab\')and SUPPRESS='N'");
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  merge and return them
    my @allCuis = (@{$allCui1}, @{$allCui2});

    return \@allCuis;
}

#  Takes as input a SAB and returns its corresponding
#  UMLS CUI. Keep in mind this is the root cui not
#  the version cui that is returned. The information
#  for this is obtained from the MRSAB table
#  input : $sab <- string containing source
#  output: $cui <- string containing cui
sub _getSabCui {
    my $self = shift;
    my $sab  = shift;

    my $function = "_getSabCui";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check input variables
    if(!$sab) { $errorhandler->_error($pkg, $function, "Error with input variable \$sab.", 4); }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  if the sab is umls all
    if($sab eq "UMLS_ALL") {
        return $umlsRoot;
    }

    my $arrRef = $db->selectcol_arrayref("select distinct RCUI from MRSAB where RSAB='$sab' and SABIN='Y'");
    $errorhandler->_checkDbError($pkg, $function, $db);

    if(scalar(@{$arrRef}) < 1) {
        $errorhandler->_error($pkg, $function, "SAB ($sab) does not exist in your current UMLS view.", 7);
    }

    if(scalar(@{$arrRef}) > 1) {
        $errorhandler->_error($pkg, $function, "Internal error: Duplicate concept rows.", 7);
    }

    return (pop @{$arrRef});
}


#  method to destroy the created object.
#  input :
#  output:
sub _disconnect {
    my $self = shift;

    my $function = "_disconnect";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if($self) {
        my $db = $self->{'db'};
        $db->disconnect() if($db);
    }
}

#  returns the version of the UMLS currently being used
#  input :
#  output: $version <- string containing version
sub _version {

    return $version;
}

#  print out the function name to standard error
#  input : $function <- string containing function name
#  output:
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Interface::CuiFinder::$function\n"; }
}

######################################################################
#  functions to obtain information about the cuis
######################################################################

#  Method to check if a concept ID exists in the database.
#  input : $concept <- string containing a cui
#  output: $bool    <- string indicating if the cui exists
sub _exists {

    my $self = shift;
    my $concept = shift;

    my $function = "_exists";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  check if root
    if($concept eq $umlsRoot) { return 1; }

    #  check if a sab
    if(exists $sabHash{$concept}) { return 1; }

    #  set up database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the concept
    my $arrRef = "";
    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where CUI='$concept'");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where CUI='$concept' and $sources");
    }

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  get the count
    my $count = scalar(@{$arrRef});

    return 1 if($count); return 0;
}

#  method that returns a list of concepts (@concepts) related
#  to a concept $concept through a relation $rel
#  input : $concept <- string containing cui
#          $rel     <- string containing a relation
#  output: $array   <- reference to an array of cuis
sub _getRelated {

    my $self    = shift;
    my $concept = shift;
    my $rel     = shift;

    my $function = "_getRelated";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    if(!defined $rel) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$rel.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set up database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  return all the relations 'rel' for cui 'concept'
    my $arrRef = "";
    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and REL='$rel' and CUI2!='$concept'");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and REL='$rel' and ($sources) and CUI2!='$concept'");
    }

    #  check for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  method that returns the preferred term of a cui from the UMLS
#  input : $concept <- string containing cui
#  output: $string  <- string containing the preferred term
sub _getAllPreferredTerm {
    my $self = shift;
    my $concept = shift;

    my $function = "_getAllPreferredTerm";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
        my @array = keys(%retHash);
	return \@array;
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the strings associated to the CUI
    my $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept' and TS='P' and LAT='ENG'");

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  clean up the strings a bit and lower case them
    my $term = "";
    foreach my $tr (@{$arrRef}) {
        $tr =~ s/^\s+//;
        $tr =~ s/\s+$//;
        $tr =~ s/\s+/ /g;
        $term = $tr;
    }

    #  return the strings
    return $term;
}

#  method that returns the preferred term of a cui from
#  sources specified in the configuration file
#  input : $concept <- string containing cui
#  output: $string  <- string containing the preferred term
sub _getPreferredTerm {
    my $self = shift;
    my $concept = shift;

    my $function = "_getPreferredTerm";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
	my @array =  keys(%retHash);
	return \@array;
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the strings associated to the CUI
    my $arrRef = "";
    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept' and TS='P' and LAT='ENG'");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept' and TS='P' and ($sources or SAB='SRC') and LAT='ENG'");
    }

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);


    #  clean up the strings a bit and lower case them
    my $term = "";
    foreach my $tr (@{$arrRef}) {
        $tr =~ s/^\s+//;
        $tr =~ s/\s+$//;
        $tr =~ s/\s+/ /g;
        $term = $tr;
    }
    
    #  return the strings
    return $term;
}



#  method that maps terms to cuis in the sources specified in
#  in the configuration file by the user using the SAB parameter
#  input : $concept <- string containing cui
#  output: $array   <- reference to an array of terms (strings)
sub _getTermList {
    my $self = shift;
    my $concept = shift;

    my $function = "_getTermList";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
	my @array = keys(%retHash);
        return \@array;
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the strings associated to the CUI
    my $arrRef = "";
    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept'");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept' and ($sources or SAB='SRC')");
    }

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  clean up the strings a bit and lower case them
    foreach my $tr (@{$arrRef}) {
        $tr =~ s/^\s+//;
        $tr =~ s/\s+$//;
        $tr =~ s/\s+/ /g;
        $retHash{lc($tr)} = 1;
    }

    my @array = keys(%retHash);

    #  return the strings
    return \@array;
}

#  method that maps terms to cuis in the sources specified in
#  in the configuration file by the user using the SABDEF parameter
#  input : $concept <- string containing cui
#  output: $array   <- reference to an array of terms
sub _getDefTermList {
    my $self = shift;
    my $concept = shift;

    my $function = "_getTermList";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
        my @array =  keys(%retHash);
	return \@array;
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the strings associated to the CUI
    my $arrRef = "";
    if($sabdef_umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept'");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct STR from MRCONSO where CUI='$concept' and ($sabdefsources or SAB='SRC')");
    }

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  clean up the strings a bit and lower case them
    foreach my $tr (@{$arrRef}) {
        $tr =~ s/^\s+//;
        $tr =~ s/\s+$//;
        $tr =~ s/\s+/ /g;
        $retHash{lc($tr)} = 1;
    }

    #  return the strings
    my @array = keys(%retHash);
    return \@array;
}

#  method that maps terms to cuis in the sources specified in
#  in the configuration file by the user
#  input : $concept <- string containing cui
#  output: $array   <- reference to an array of terms and their sources 
sub _getTermSabList {
    my $self = shift;
    my $concept = shift;

    my $function = "_getTermSabList";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  initialize the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
        my @array =  keys(%retHash);
	return \@array;
    }

    #  otherwise, set up the db
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }
    #  get all of the strings with their corresponding sab
    my %strhash = (); my $sql = "";
    if($sabdef_umlsall) {
        $sql = qq{ select STR, SAB from MRCONSO where CUI='$concept' };
    }
    else {
        $sql = qq{select STR, SAB from MRCONSO where CUI='$concept' and ($sabdefsources or SAB='SRC') };
    }
    my $sth = $db->prepare( $sql );
    $sth->execute();
    my($str, $sab);
    $sth->bind_columns( undef, \$str, \$sab );
    while( $sth->fetch() ) {
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        $str =~ s/\s+/ /g;
        $str = lc($str);
        my $item = "$sab : $str";
        $retHash{$item}++;
    }

    $errorhandler->_checkDbError($pkg, $function, $sth);
    $sth->finish();

    #  return keys
    my @array = keys(%retHash);
    return \@array;
}


#  method to map terms to any concept in the umls
#  input : $concept <- string containing cui
#  output: $array   <- reference to an array containing terms (strings)
sub _getAllTerms {
    my $self = shift;
    my $concept = shift;

    my $function = "_getAllTerms";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  initialize the return hash
    my %retHash = ();

    #  if the concept is the root return the root string
    if($concept eq $umlsRoot) {
        $retHash{"**UMLS ROOT**"}++;
        my @array =  keys(%retHash);
	return \@array;
    }

    #  otherwise, set up the db
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get all of the strings with their corresponding sab
    my %strhash = ();
    my $sql = qq{ select STR, SAB from MRCONSO where CUI='$concept' };
    my $sth = $db->prepare( $sql );
    $sth->execute();
    my($str, $sab);
    $sth->bind_columns( undef, \$str, \$sab );
    while( $sth->fetch() ) {
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        $str =~ s/\s+/ /g;
        $str = lc($str);
        push @{$strhash{$str}}, $sab;
    }
    $errorhandler->_checkDbError($pkg, $function, $sth);
    $sth->finish();

    #  set the output
    foreach my $str (sort keys %strhash) {
        my $sabs = join ", ", @{$strhash{$str}};
        my $index = "$str - $sabs";
        $retHash{$index}++;
    }

    my @array = keys(%retHash);
    
    return \@array;
}

#  method to map CUIs to a terms in the sources and the relations
#  specified in the configuration file by SAB and REL
#  input : $term  <- string containing a term
#  output: $array <- reference to an array containing cuis
sub _getConceptList {

    my $self = shift;
    my $term = shift;

    my $function = "_getConceptList";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $term) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$term.", 4);
    }

    #  check that the ' are escaped if exist
    $term=~s/\\?\'/\\\'/;

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the cuis
    my $arrRef = "";

    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where STR='$term'");
    }
    elsif($sources ne "") {

        $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where STR='$term' and ($sources)");
    }
    else {
        $errorhandler->_error($pkg, $function, "Error with sources from configuration file.", 5);
    }
    #  check for database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  method to map CUIs to a terms in the sources and the relations
#  specified in the configuration file by SABDEF and RELDEF
#  input : $term  <- string containing a term
#  output: $array <- reference to an array containing cuis
sub _getDefConceptList {

    my $self = shift;
    my $term = shift;

    my $function = "_getDefConceptList";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $term) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$term.", 4);
    }

    #  check that the ' are escaped if exist
    $term=~s/\\?\'/\\\'/;

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the cuis
    my $arrRef = "";
    
    if($sabdef_umlsall) {
	$arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where STR='$term'");
    }
    elsif($sabdefsources ne "") {
        $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where STR='$term' and ($sabdefsources)");
    }
    else {
        $errorhandler->_error($pkg, $function, "Error with sources from configuration file.", 5);
    }
    #  check for database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  method to map CUIs to a terms using the CUIs in the
#  entire UMLS not just the sources in the config file
#  input : $term  <- string containing a term
#  output: $array <- reference to an array containing cuis
sub _getAllConcepts {

    my $self = shift;
    my $term = shift;

    my $function = "_getAllConcepts";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $term) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$term.", 4);
    }

    #  check that the ' are escaped if exist
    $term=~s/\\?\'/\\\'/;

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the cuis
    my $arrRef = $db->selectcol_arrayref("select distinct CUI from MRCONSO where STR='$term'");

    #  check for database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  method returns all the compounds in the sources 
#  specified in the configuration file
#  input:
#  output: $hash <- reference to a hash containing cuis
sub _getCompounds {

    my $self = shift;

    my $function = "_getCompounds";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  initialize return hash
    my %compounds = ();

    #  get strings in the MRCONSO table
    if($umlsall) {
	#  get all the terms from the MRCONSO table
        my $strs = $db->selectcol_arrayref("select distinct STR from MRCONSO");
        $errorhandler->_checkDbError($pkg, $function, $db);

	#  loop through the terms and add the ones that have more than one word to the hash
        foreach my $str (@{$strs}) { 
	    my @array = split/\s+/, $str;
	    if($#array > 0) { 
		$compounds{$str} = 0; 
	    }
	}
    }
    else {

	#  for each of the sabs in the configuratinon file get strings
        foreach my $sab (sort keys %sabnamesHash) { 
    
	    #  get the cuis for that sab
	    my $strs = $db->selectcol_arrayref("select distinct STR from MRCONSO where SAB=\'$sab\'");
	    $errorhandler->_checkDbError($pkg, $function, $db);
	    
	    #  loop through the terms and add the ones that have more than one word to the hash
	    foreach my $str (@{$strs}) { 
		my @array = split/\s+/, $str;
		if($#array > 0) { 
		    $compounds{$str} = 0; 
		}
	    }
	}
    }
    
    return \%compounds;
}


#  method returns all of the cuis in the sources
#  specified in the configuration file
#  input :
#  output: $hash <- reference to a hash containing cuis
sub _getCuiList {

    my $self = shift;

    my $function = "_getCuiList";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  if this has already been done just return the stored cuiListHash
    my $elements = keys %cuiListHash;
    if($elements > 0) {
        return \%cuiListHash;
    }

    #  otherwise, set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the sabs in the config file
    my @sabs = ();
    if($umlsall) {
        my $s = $db->selectcol_arrayref("select distinct SAB from MRREL");
        $errorhandler->_checkDbError($pkg, $function, $db);
        @sabs = @{$s};
    }
    else {
        foreach my $sab (sort keys %sabnamesHash) { push @sabs, $sab; }
    }

    #  initialize the cui list hash
    %cuiListHash = ();

    #  for each of the sabs in the configuratino file
    foreach my $sab (@sabs) {

        #  get the cuis for that sab
        my $cuis = $self->_getCuis($sab);

        #  add the cuis to the hash
        foreach my $cui (@{$cuis}) { $cuiListHash{$cui} = 0 };
    }

    #  add upper level taxonomy
    foreach my $cui (sort keys %parentTaxonomyArray) { $cuiListHash{$cui} = 0; }
    foreach my $cui (sort keys %childTaxonomyArray)  { $cuiListHash{$cui} = 0; }

    return \%cuiListHash;
}

#  returns the cuis from a specified source
#  input : $sab   <- string contain the sources abbreviation
#  output: $array <- reference to an array containing cuis
sub _getCuisFromSource {

    my $self = shift;
    my $sab = shift;

    my $function = "_getCuisFromSource";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the cuis from the specified source
    my $arrRef = $self->_getCuis($sab);

    return ($arrRef);
}

#  returns all of the sources specified that contain the given cui
#  input : $concept <- string containing the cui
#  output: $array   <- reference to an array contain the sources (abbreviations)
sub _getSab {

    my $self = shift;
    my $concept = shift;

    my $function = "_getSab";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  connect to the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  select all the sources from the mrconso table
    my $arrRef = $db->selectcol_arrayref("select distinct SAB from MRCONSO where CUI='$concept'");

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  returns the child relations
#  input :
#  output: $string <- containing the child relations
sub _getChildRelations {
    my $self = shift;

    return $childRelations;
}
#  returns the parent relations
#  input :
#  output: $string <- containing the parent relations
sub _getParentRelations {
    my $self = shift;

    return $parentRelations;
}


#  returns the children of a concept - the relations that
#  are considered children are predefined by the user.
#  the default are the RN and CHD relations
#  input : $concept <- string containing a cui
#  output: $array   <- reference to an array containing a list of cuis
sub _getChildren {

    my $self    = shift;
    my $concept = shift;

    my $function = "_getChildren";
    #&_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  connect to the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  if the concept is the umls root node cui return
    #  the source's cuis
    if($concept eq $umlsRoot) {
	my @array = (keys %sabHash);
        return \@array;
    }

    #  otherwise everything is normal so return its children
    else {
        my $arrRef = "";
        if($umlsall) {
            $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and ($childRelations) and CUI2!='$concept' and SUPPRESS='N'");
        }
        else {
            $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and ($childRelations) and ($sources) and CUI2!='$concept' and SUPPRESS='N'");
        }

        #  check the database for errors
        $errorhandler->_checkDbError($pkg, $function, $db);

        #  add the children in the upper taxonomy
        my @array = ();
        if(exists $childTaxonomyArray{$concept}) {
            @array = (@{$childTaxonomyArray{$concept}}, @{$arrRef});
        }
        else {
            @array = @{$arrRef};
        }
        return \@array;
    }
}


#  returns the parents of a concept - the relations that
#  are considered parents are predefined by the user.
#  the default are the PAR and RB relations.
#  input : $concept <- string containing cui
#  outupt: $array   <- reference to an array containing a list of cuis
sub _getParents {

    my $self    = shift;
    my $concept = shift;

    my $function = "_getParents";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  connect to the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  if the cui is a root return an empty array
    if($concept eq $umlsRoot) {
        my @returnarray = ();
        return \@returnarray;  # empty array
    }
    #  if the cui is a source cui but not a root return the umls root
    elsif( (exists $sabHash{$concept}) and ($concept ne $umlsRoot)) {
	my @returnarray = ();
	push @returnarray, $umlsRoot;
        return \@returnarray;
    }
    #  otherwise everything is normal so return its parents
    else {
        my $arrRef = "";
        if($umlsall) {
            $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and ($parentRelations) and CUI2!='$concept' and SUPPRESS='N'");
        }
        else {
            $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and ($parentRelations) and ($sources) and CUI2!='$concept' and SUPPRESS='N'");
        }

        #  check the database for errors
        $errorhandler->_checkDbError($pkg, $function, $db);

        #  add the parents in the upper taxonomy
        my @array = ();
        if(exists $parentTaxonomyArray{$concept}) {
            @array = (@{$parentTaxonomyArray{$concept}}, @{$arrRef});
        }
        else {
            @array = @{$arrRef};
        }
        return \@array;
    }
}

#  returns the relations of a concept given a specified source
#  input : $concept <- string containing a cui
#  output: $array   <- reference to an array containing strings of relations
sub _getRelations {

    my $self    = shift;
    my $concept = shift;

    my $function = "_getRelations";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  connect to the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the relations
    my $arrRef = "";
    if($umlsall) {
        $arrRef = $db->selectcol_arrayref("select distinct REL from MRREL where (CUI1='$concept' or CUI2='$concept') and CUI1!=CUI2");
    }
    else {
        $arrRef = $db->selectcol_arrayref("select distinct REL from MRREL where (CUI1='$concept' or CUI2='$concept') and ($sources) and CUI1!=CUI2");
    }

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  returns the relations and its source between two concepts
#  input : $concept1 <- string containing a cui
#        : $concept2 <- string containing a cui
#  output: $array    <- reference to an array containing the relations
sub _getRelationsBetweenCuis {

    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $function = "_getRelationBetweenCuis";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept1) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept1.", 4);
    }
    if(!defined $concept2) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept2.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept1)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept1) is not valid.", 6);
    }
    if(! ($errorhandler->_validCui($concept2)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept2) is not valid.", 6);
    }
    #  connect to the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my @array = ();

    if($concept1 eq $umlsRoot) {
        push @array, "CHD (source)";
        return \@array;
    }

    #  get the relations
    my $sql = "";
    if($umlsall) {
        $sql = qq{ select distinct REL, SAB from MRREL where (CUI1='$concept1' and CUI2='$concept2') and ($relations)};
    }
    else {
        $sql = qq{ select distinct REL, SAB from MRREL where (CUI1='$concept1' and CUI2='$concept2') and ($sources) and ($relations)};
    }

    my $sth = $db->prepare( $sql );
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    my($rel, $sab);
    $sth->bind_columns( undef, \$rel, \$sab );
    while( $sth->fetch() ) {
        my $str = "$rel ($sab)";
        push @array, $str;
    } $sth->finish();

    return \@array;
}

#  checks to see a concept is forbidden
#  input : $concept <- string containing a cui
#  output: $string  <- integer indicating true or false
sub _forbiddenConcept  {

    my $self = shift;
    my $concept = shift;

    my $function = "_forbiddenConcept";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  if concept is one of the following just return
    #C1274012|Ambiguous concept (inactive concept)
    if($concept=~/C1274012/) { return 1; }
    #C1274013|Duplicate concept (inactive concept)
    if($concept=~/C1274013/) { return 1; }
    #C1276325|Reason not stated concept (inactive concept)
    if($concept=~/C1276325/) { return 1; }
    #C1274014|Outdated concept (inactive concept)
    if($concept=~/C1274014/) { return 1; }
    #C1274015|Erroneous concept (inactive concept)
    if($concept=~/C1274015/) { return 1; }
    #C1274021|Moved elsewhere (inactive concept)
    if($concept=~/C1274021/) { return 1; }
    #C1443286|unapproved attribute
    if($concept=~/C1443286/) { return 1; }
    #C1274012|non-current concept - ambiguous
    if($concept=~/C1274012/) { return 1; }
    #C2733115|limited status concept
    if($concept=~/C2733115/) { return 1; }

    return 0;
}

# Subroutine to get the semantic type's tui of a concept
# input : $cui   <- string containing a concept
# output: $array <- reference to an array containing the semantic 
#                   type's TUIs associated with the concept
sub _getSt {

    my $self = shift;
    my $concept   = shift;

    my $function = "_getSt";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the TUI
    my $arrRef = $db->selectcol_arrayref("select TUI from MRSTY where CUI=\'$concept\'");

    #  check for database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

# Subroutine to get the semantic type's tui of a semantic group
# input : $sg   <- string containing a semantic group
# output: $array <- reference to an array containing the semantic 
#                   type's TUIs associated with the concept
sub _getStsFromSg {

    my $self = shift;
    my $sg   = shift;

    my $function = "_getSt";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }


    my $string = ""; 
    if(exists $sgConversion{$sg}) { 
	$string = $sgConversion{$sg}; 
    }
    else { 
	$errorhandler->_error($pkg, $function, "Semantic Group ($sg) is not valid.", 6);
    }
    
    my @sts = (); 
    foreach my $st (sort keys %semanticGroups) { 
	foreach my $group (@{$semanticGroups{$st}}) { 
	    if($string eq $group) { 
		my $arrRef = $db->selectcol_arrayref("select ABR from SRDEF where STY_RL=\'$st\'");
		my $el = shift @{$arrRef}; 
		push @sts, $el; 
	    }
	}
    }

    return \@sts;         
}


# Subroutine to get the semantic type's tui of a concept
# input : 
# output: $array <- reference to an array containing all the semantic 
#                   type's TUIs 
sub _getAllSts {

    my $self = shift;

    my $function = "_getAllSt";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the TUI
    my $arrRef = $db->selectcol_arrayref("select distinct(TUI) from MRSTY");
    
    #  check for database errors
    $errorhandler->_checkDbError($pkg, $function, $db);
    
    return $arrRef;
}

#  subroutine to get the relation(s) between two semantic types
#  input : $st1   <- semantic type abbreviation
#          $st2   <- semantic type abbreviation
#  output: $array <- reference to an array of semantic relation(s)
sub _getSemanticRelation {

    my $self = shift;
    my $st1  = shift;
    my $st2  = shift;

    my $function = "_getSemanticRelation";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check input
    if(!defined $st1) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$st1.", 4);
    }
    if(!defined $st2) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$st2.", 4);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my $string1 = $self->_getStString($st1);
    my $string2 = $self->_getStString($st2);

    #  get the string associated with the semantic type
    my $arrRef = $db->selectcol_arrayref("select distinct RL from SRSTR where STY_RL1=\'$string1\' and STY_RL2=\'$string2\'");

    #  check database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    my @rarray = shift @{$arrRef};
    return \@rarray;;
}

#  subroutine to get the name of a semantic type given its abbreviation
#  input : $st     <- string containing the abbreviation of the semantic type
#  output: $string <- string containing the full name of the semantic type
sub _getStString {

    my $self = shift;
    my $st   = shift;

    my $function = "_getStString";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $st) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the string associated with the semantic type
    my $arrRef = $db->selectcol_arrayref("select STY_RL from SRDEF where ABR=\'$st\'");

    #  check database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return (shift @{$arrRef});
}


# subroutine to get the name of a semantic type given its TUI (UI)
#  input : $tui    <- string containing the semantic type's TUI
#  output: $string <- string containing the semantic type's abbreviation
sub _getStAbr {

    my $self = shift;
    my $tui   = shift;

    my $function = "_getStAbr";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $tui) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$tui.", 4);
    }

    #  if tui is the root return ROOT
    if($tui eq "T000") { 
	return "ST ROOT";
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  obtain the abbreviation
    my $arrRef = $db->selectcol_arrayref("select ABR from SRDEF where UI=\'$tui\'");

    #  check database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return (shift @{$arrRef});
}


# subroutine to get the name of a semantic type's TUI given its abbrevation
#  input : $string <- string containing the semantic type's abbreviation
#  output: $tui    <- string containing the semantic type's TUI
sub _getStTui {

    my $self   = shift;
    my $abbrev = shift;

    my $function = "_getStTui";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $abbrev) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$abbrev.", 4);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  obtain the abbreviation
    my $arrRef = $db->selectcol_arrayref("select UI from SRDEF where ABR=\'$abbrev\'");

    #  check database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return (shift @{$arrRef});
}


#  subroutine to get the definition of a given TUI
#  input : $st     <- string containing the semantic type's abbreviation
#  output: $string <- string containing the semantic type's definition
sub _getStDef {

    my $self = shift;
    my $st   = shift;

    my $function = "_getStDef";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $st) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }

    #  set the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  get the definition
    my $arrRef = $db->selectcol_arrayref("select DEF from SRDEF where ABR=\'$st\'");

    #  check database errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  method returns the semantic group(s) associated with the concept
#  input : $concept <- string containing a cui
#  output: $array   <- reference to an array containing semantic groups
sub _getSemanticGroup {
    my $self = shift;
    my $concept = shift;

   my $function = "_getSemanticGroup";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    my $sts = $self->_getSt($concept);
	
    my %groups = ();
    foreach my $st (@{$sts}) {
	my $abr = $self->_getStAbr($st);
	my $string = $self->_getStString($abr);
	foreach my $group (@{$semanticGroups{$string}}) { 
	    $groups{$group}++;
	}
    }
    
    my @array = ();
    foreach my $group (sort keys %groups) { 
	push @array, $group; 
    }
    
    return \@array;
}

#  method returns the semantic groups
#  input :
#  output: $array   <- reference to an array containing semantic groups
sub _getAllSemanticGroups {
    my $self = shift;

   my $function = "_getSemanticGroup";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    my %groups = ();
    foreach my $st (sort keys %semanticGroups) { 
	foreach my $group (@{$semanticGroups{$st}}) { 
	    $groups{$group}++;
	}
    }    

    my @array = ();
    foreach my $group (sort keys %groups) { 
	my $code = $sgConversion1{$group}; 
	push @array, $code; 
    }
    
    return \@array;
}

#  method returns the semantic group(s) associated with a semantic type
#  input : $st      <- string containing a st
#  output: $array   <- reference to an array containing semantic groups
sub _stGetSemanticGroup {
    my $self = shift;
    my $st = shift;

   my $function = "_stGetSemanticGroup";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    my %groups = ();

    my $string = $self->_getStString($st);

    foreach my $group (@{$semanticGroups{$string}}) { 
	$groups{$group}++;
    }
    
    my @array = ();
    foreach my $group (sort keys %groups) { push @array, $group; }
    
    return \@array;
}


#  method returns the semantic group(s) associated with the concept
#  input : $st      <- string containing a semantic type abbreviation
#  output: $array   <- reference to an array containing semantic groups
sub _getSemanticGroupOfSt {
    my $self = shift;
    my $st   = shift;

   my $function = "_getSemanticGroupOfSt";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $st) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }
    
    my $string = $self->_getStString($st);

    my %groups = ();
    foreach my $group (@{$semanticGroups{$string}}) { 
	$groups{$group}++;
    }
    
    my @array = ();
    foreach my $group (sort keys %groups) { push @array, $group; }
    
    return \@array;
}

	    
#  method that returns a list of concepts (@concepts) related
#  to a concept $concept through a relation $rel
#  input : $concept <- string containing cui
#          $rel     <- string containing a relation
#  output: $array   <- reference to an array of cuis
sub _getExtendedRelated {

    my $self    = shift;
    my $concept = shift;
    my $rel     = shift;

    my $function = "_getExtendedRelated";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    if(!defined $rel) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$rel.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  set up database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  check if sources are specified and it is not umlsall
    my $optional = "";
    if(!$umlsall) {
        if($sabdefsources ne "") {
            $optional = " and ($sabdefsources)";
        }
    }
    #  if the relations is either a parent or a child add the reladefparents if specified
    if( ($rel=~/PAR|RB/) && ($reladefparents ne "") ) {
        $optional .= " and ($reladefparents)";
    }
    if( ($rel=~/CHD|RN/) && ($reladefchildren ne "") ) {
        $optional .= " and ($reladefchildren)";
    }
    #  return all the relations 'rel' for cui 'concept'
    my $arrRef = $db->selectcol_arrayref("select distinct CUI2 from MRREL where CUI1='$concept' and REL='$rel' and CUI2!='$concept' $optional");

    #  check for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    return $arrRef;
}

#  subroutine to get the extended definition of a concept from
#  the concept and its surrounding relations as specified in the
#  the configuration file.
#  input : $concept <- string containing a cui
#  output: $array   <- reference to an array containing the definitions
sub _getExtendedDefinition {

    my $self    = shift;
    my $concept = shift;

    my $function = "_getExtendedDefinition";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  get database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my $sabflag = 1;

    my @defs = ();

    my $dkeys = keys %relDefHash;

    if( ($dkeys <= 0) or (exists $relDefHash{"ST"}) ) {
        my $sts = $self->_getSt($concept);
        foreach my $st (@{$sts}) {
            my $abr = $self->_getStAbr($st);
            my $def = $self->_getStDef($abr);
            my $str = "$concept ST $abr STDEF : @{$def}";
            push @defs, $str;
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"PAR"}) ) {
        my $parents   = $self->_getExtendedRelated($concept, "PAR");
        foreach my $parent (@{$parents}) {
            my $odefs = $self->_getCuiDef($parent, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept PAR $parent $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"CHD"}) ) {
        my $children   = $self->_getExtendedRelated($concept, "CHD");
        foreach my $child (@{$children}) {
            my $odefs = $self->_getCuiDef($child, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept CHD $child $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"SIB"}) ) {
        my $siblings   = $self->_getExtendedRelated($concept, "SIB");
        foreach my $sib (@{$siblings}) {
            my $odefs = $self->_getCuiDef($sib, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept SIB $sib $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"SYN"}) ) {
        my $syns   = $self->_getExtendedRelated($concept, "SYN");
        foreach my $syn (@{$syns}) {
            my $odefs = $self->_getCuiDef($syn, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept SYN $syn $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"RB"}) ) {
        my $rbs    = $self->_getExtendedRelated($concept, "RB");
        foreach my $rb (@{$rbs}) {
            my $odefs = $self->_getCuiDef($rb, $sabflag);
            foreach my $d (@{$odefs}) {
		my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept RB $rb $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"RN"}) ) {
        my $rns    = $self->_getExtendedRelated($concept, "RN");
        foreach my $rn (@{$rns}) {
            my $odefs = $self->_getCuiDef($rn, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept RN $rn $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"RO"}) ) {
        my $ros    = $self->_getExtendedRelated($concept, "RO");
        foreach my $ro (@{$ros}) {
            my $odefs = $self->_getCuiDef($ro, $sabflag);
            foreach my $d (@{$odefs}) {
                my @darray = split/\s+/, $d;
                my $sab = shift @darray;
                my $def = "$concept RO $ro $sab : " . (join " ", @darray);
                push @defs, $def;
            }
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"CUI"}) ) {
        my $odefs   = $self->_getCuiDef($concept, $sabflag);
        foreach my $d (@{$odefs}) {
            my @darray = split/\s+/, $d;
            my $sab = shift @darray;
            my $def = "$concept CUI $concept $sab : " . (join " ", @darray);
            push @defs, $def;
        }
    }
    if( ($dkeys <= 0) or (exists $relDefHash{"TERM"}) ) {
        my $odefs = $self->_getTermSabList($concept);
        foreach my $item (@{$odefs}) {
            my ($sab, $term) = split/\s*\:\s*/, $item;
            my $def = "$concept TERM $concept $sab : $term";
            push @defs, $def;
        }
    }
    return \@defs;
}

#  subroutine to get a CUIs definition
#  input : $concept <- string containing a cui
#  output: $array   <- reference to an array of definitions (strings)
sub _getCuiDef {

    my $self    = shift;
    my $concept = shift;
    my $sabflag = shift;

    my $function = "_getCuiDef";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    #  get database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  set the query
    my $sql = "";

    if($sabdefsources ne "") {
        $sql = qq{ SELECT DEF, SAB FROM MRDEF WHERE CUI=\'$concept\' and ($sabdefsources) };
    }
    else {
        $sql = qq{ SELECT DEF, SAB FROM MRDEF WHERE CUI=\'$concept\' };
    }

    #  get the information from the database
    my $sth = $db->prepare( $sql );
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  set the output variable
    my($def, $sab);
    my @defs = ();
    $sth->bind_columns( undef, \$def, \$sab );
    while( $sth->fetch() ) {
        if(defined $sabflag) { push @defs, "$sab $def"; }
        else                 { push @defs, $def; }
    } $sth->finish();

    return \@defs;
}


#  returns the table names in both human readable and hex form
#  input :
#  output: $hash <- reference to a hash containin the table 
#                   names in human readable and hex form
sub _returnTableNames {
    my $self = shift;

    my $function = "_returnTableNames";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the output variable
    my %hash = ();
    $hash{$parentTableHuman}    = $parentTable;
    $hash{$childTableHuman}     = $childTable;
    $hash{$intrinsicTableHuman} = $intrinsicTable;
    $hash{$tableNameHuman}      = $tableName;
    $hash{$cacheTableHuman}     = $cacheTable;

    return \%hash;
}

#  sets the semantic groups
#  input: 
#  output: 
sub _setSemanticGroups {

    %semanticGroups = ();

    push @{$semanticGroups{"Activity"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Behavior"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Daily or Recreational Activity"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Event"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Governmental or Regulatory Activity"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Individual Behavior"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Machine Activity"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Occupational Activity"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Social Behavior"}}, "Activities & Behaviors";
    push @{$semanticGroups{"Anatomical Structure"}}, "Anatomy";
    push @{$semanticGroups{"Body Location or Region"}}, "Anatomy";
    push @{$semanticGroups{"Body Part, Organ, or Organ Component"}}, "Anatomy";
    push @{$semanticGroups{"Body Space or Junction"}}, "Anatomy";
    push @{$semanticGroups{"Body Substance"}}, "Anatomy";
    push @{$semanticGroups{"Body System"}}, "Anatomy";
    push @{$semanticGroups{"Cell"}}, "Anatomy";
    push @{$semanticGroups{"Cell Component"}}, "Anatomy";
    push @{$semanticGroups{"Embryonic Structure"}}, "Anatomy";
    push @{$semanticGroups{"Fully Formed Anatomical Structure"}}, "Anatomy";
    push @{$semanticGroups{"Tissue"}}, "Anatomy";
    push @{$semanticGroups{"Amino Acid, Peptide, or Protein"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Antibiotic"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Biologically Active Substance"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Biomedical or Dental Material"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Carbohydrate"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Chemical"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Chemical Viewed Functionally"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Chemical Viewed Structurally"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Clinical Drug"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Eicosanoid"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Element, Ion, or Isotope"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Enzyme"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Hazardous or Poisonous Substance"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Hormone"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Immunologic Factor"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Indicator, Reagent, or Diagnostic Aid"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Inorganic Chemical"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Lipid"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Neuroreactive Substance or Biogenic Amine"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Nucleic Acid, Nucleoside, or Nucleotide"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Organic Chemical"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Organophosphorus Compound"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Pharmacologic Substance"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Receptor"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Steroid"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Vitamin"}}, "Chemicals & Drugs";
    push @{$semanticGroups{"Classification"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Conceptual Entity"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Functional Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Group Attribute"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Idea or Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Intellectual Product"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Language"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Qualitative Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Quantitative Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Regulation or Law"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Spatial Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Temporal Concept"}}, "Concepts & Ideas";
    push @{$semanticGroups{"Drug Delivery Device"}}, "Devices";
    push @{$semanticGroups{"Medical Device"}}, "Devices";
    push @{$semanticGroups{"Research Device"}}, "Devices";
    push @{$semanticGroups{"Acquired Abnormality"}}, "Disorders";
    push @{$semanticGroups{"Anatomical Abnormality"}}, "Disorders";
    push @{$semanticGroups{"Cell or Molecular Dysfunction"}}, "Disorders";
    push @{$semanticGroups{"Congenital Abnormality"}}, "Disorders";
    push @{$semanticGroups{"Disease or Syndrome"}}, "Disorders";
    push @{$semanticGroups{"Experimental Model of Disease"}}, "Disorders";
    push @{$semanticGroups{"Finding"}}, "Disorders";
    push @{$semanticGroups{"Injury or Poisoning"}}, "Disorders";
    push @{$semanticGroups{"Mental or Behavioral Dysfunction"}}, "Disorders";
    push @{$semanticGroups{"Neoplastic Process"}}, "Disorders";
    push @{$semanticGroups{"Pathologic Function"}}, "Disorders";
    push @{$semanticGroups{"Sign or Symptom"}}, "Disorders";
    push @{$semanticGroups{"Amino Acid Sequence"}}, "Genes & Molecular Sequences";
    push @{$semanticGroups{"Carbohydrate Sequence"}}, "Genes & Molecular Sequences";
    push @{$semanticGroups{"Gene or Genome"}}, "Genes & Molecular Sequences";
    push @{$semanticGroups{"Molecular Sequence"}}, "Genes & Molecular Sequences";
    push @{$semanticGroups{"Nucleotide Sequence"}}, "Genes & Molecular Sequences";
    push @{$semanticGroups{"Geographic Area"}}, "Geographic Areas";
    push @{$semanticGroups{"Age Group"}}, "Living Beings";
    push @{$semanticGroups{"Amphibian"}}, "Living Beings";
    push @{$semanticGroups{"Animal"}}, "Living Beings";
    push @{$semanticGroups{"Archaeon"}}, "Living Beings";
    push @{$semanticGroups{"Bacterium"}}, "Living Beings";
    push @{$semanticGroups{"Bird"}}, "Living Beings";
    push @{$semanticGroups{"Eukaryote"}}, "Living Beings";
    push @{$semanticGroups{"Family Group"}}, "Living Beings";
    push @{$semanticGroups{"Fish"}}, "Living Beings";
    push @{$semanticGroups{"Fungus"}}, "Living Beings";
    push @{$semanticGroups{"Group"}}, "Living Beings";
    push @{$semanticGroups{"Human"}}, "Living Beings";
    push @{$semanticGroups{"Mammal"}}, "Living Beings";
    push @{$semanticGroups{"Organism"}}, "Living Beings";
    push @{$semanticGroups{"Patient or Disabled Group"}}, "Living Beings";
    push @{$semanticGroups{"Plant"}}, "Living Beings";
    push @{$semanticGroups{"Population Group"}}, "Living Beings";
    push @{$semanticGroups{"Professional or Occupational Group"}}, "Living Beings";
    push @{$semanticGroups{"Reptile"}}, "Living Beings";
    push @{$semanticGroups{"Vertebrate"}}, "Living Beings";
    push @{$semanticGroups{"Virus"}}, "Living Beings";
    push @{$semanticGroups{"Entity"}}, "Objects";
    push @{$semanticGroups{"Food"}}, "Objects";
    push @{$semanticGroups{"Manufactured Object"}}, "Objects";
    push @{$semanticGroups{"Physical Object"}}, "Objects";
    push @{$semanticGroups{"Substance"}}, "Objects";
    push @{$semanticGroups{"Biomedical Occupation or Discipline"}}, "Occupations";
    push @{$semanticGroups{"Occupation or Discipline"}}, "Occupations";
    push @{$semanticGroups{"Health Care Related Organization"}}, "Organizations";
    push @{$semanticGroups{"Organization"}}, "Organizations";
    push @{$semanticGroups{"Professional Society"}}, "Organizations";
    push @{$semanticGroups{"Self-help or Relief Organization"}}, "Organizations";
    push @{$semanticGroups{"Biologic Function"}}, "Phenomena";
    push @{$semanticGroups{"Environmental Effect of Humans"}}, "Phenomena";
    push @{$semanticGroups{"Human-caused Phenomenon or Process"}}, "Phenomena";
    push @{$semanticGroups{"Laboratory or Test Result"}}, "Phenomena";
    push @{$semanticGroups{"Natural Phenomenon or Process"}}, "Phenomena";
    push @{$semanticGroups{"Phenomenon or Process"}}, "Phenomena";
    push @{$semanticGroups{"Cell Function"}}, "Physiology";
    push @{$semanticGroups{"Clinical Attribute"}}, "Physiology";
    push @{$semanticGroups{"Genetic Function"}}, "Physiology";
    push @{$semanticGroups{"Mental Process"}}, "Physiology";
    push @{$semanticGroups{"Molecular Function"}}, "Physiology";
    push @{$semanticGroups{"Organism Attribute"}}, "Physiology";
    push @{$semanticGroups{"Organism Function"}}, "Physiology";
    push @{$semanticGroups{"Organ or Tissue Function"}}, "Physiology";
    push @{$semanticGroups{"Physiologic Function"}}, "Physiology";
    push @{$semanticGroups{"Diagnostic Procedure"}}, "Procedures";
    push @{$semanticGroups{"Educational Activity"}}, "Procedures";
    push @{$semanticGroups{"Health Care Activity"}}, "Procedures";
    push @{$semanticGroups{"Laboratory Procedure"}}, "Procedures";
    push @{$semanticGroups{"Molecular Biology Research Technique"}}, "Procedures";
    push @{$semanticGroups{"Research Activity"}}, "Procedures";
    push @{$semanticGroups{"Therapeutic or Preventive Procedure"}}, "Procedures";

    $sgConversion{"ACTI"} = "Activities & Behaviors"; 
    $sgConversion{"ANAT"} = "Anatomy"; 
    $sgConversion{"CHEM"} = "Chemicals & Drugs"; 
    $sgConversion{"CONC"} = "Concepts & Ideas"; 
    $sgConversion{"DEVI"} = "Devices"; 
    $sgConversion{"DISO"} = "Disorders"; 
    $sgConversion{"GENE"} = "Genes & Molecular Sequences"; 
    $sgConversion{"GEOG"} = "Geographic Areas"; 
    $sgConversion{"LIVB"} = "Living Beings"; 
    $sgConversion{"OBJC"} = "Objects"; 
    $sgConversion{"OCCU"} = "Occupations"; 
    $sgConversion{"ORGA"} = "Organizations"; 
    $sgConversion{"PHEN"} = "Phenomena"; 
    $sgConversion{"PHYS"} = "Physiology"; 
    $sgConversion{"PROC"} = "Procedures"; 

    $sgConversion1{"Activities & Behaviors"} =  "ACTI"; 
    $sgConversion1{"Anatomy"} =  "ANAT"; 
    $sgConversion1{"Chemicals & Drugs"} =  "CHEM";  
    $sgConversion1{"Concepts & Ideas"} =  "CONC"; 
    $sgConversion1{"Devices"} =  "DEVI"; 
    $sgConversion1{"Disorders"} =  "DISO"; 
    $sgConversion1{"Genes & Molecular Sequences"} =  "GENE"; 
    $sgConversion1{"Geographic Areas"} =  "GEOG"; 
    $sgConversion1{"Living Beings"} =  "LIVB"; 
    $sgConversion1{"Objects"} =  "OBJ"; 
    $sgConversion1{"Occupations"} =  "OCCU"; 
    $sgConversion1{"Organizations"} =  "ORGA"; 
    $sgConversion1{"Phenomena"} =  "PHEN"; 
    $sgConversion1{"Physiology"} =  "PHYS"; 
    $sgConversion1{"Procedures"} =  "PROC"; 
}

#  removes the configuration tables
#  input :
#  output:
sub _dropConfigTable {

    my $self    = shift;

    my $function = "_dropConfigTable";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  connect to the database
    my $sdb = $self->_connectIndexDB();
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  show all of the tables
    my $sth = $sdb->prepare("show tables");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    #  get all the tables in mysql
    my $table  = "";
    my %tables = ();
    while(($table) = $sth->fetchrow()) {
        $tables{$table}++;
    }
    $sth->finish();

    if(exists $tables{$intrinsicTable}) {
        $sdb->do("drop table $intrinsicTable");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{$parentTable}) {
        $sdb->do("drop table $parentTable");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{$childTable}) {
        $sdb->do("drop table $childTable");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{$cacheTable}) {
        $sdb->do("drop table $cacheTable");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{$tableName}) {
        $sdb->do("drop table $tableName");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{$infoTable}) {
        $sdb->do("drop table $infoTable");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    if(exists $tables{"tableindex"}) {

        $sdb->do("delete from tableindex where HEX='$intrinsicTable'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("delete from tableindex where HEX='$parentTable'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("delete from tableindex where HEX='$childTable'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("delete from tableindex where HEX='$cacheTable'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("delete from tableindex where HEX='$tableName'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);

        $sdb->do("delete from tableindex where HEX='$infoTable'");
        $errorhandler->_checkDbError($pkg, $function, $sdb);
    }
}

#  removes the configuration files
#  input :
#  output:
sub _removeConfigFiles {

    my $self = shift;

    my $function = "_removeConfigFiles";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  remove the files
    if(-e $tableFile) {
        system "rm $tableFile";
    }
    if(-e $childFile) {
        system "rm $childFile";
    }
    if(-e $parentFile) {
        system "rm $parentFile";
    }
    if(-e $configFile) {
        system "rm $configFile";
    }

}

#  checks to see if the cui is in the parent taxonomy
#  input : $concept <- string containing a cui
#  output: $bool    <- indicating if the cui exists in
#                      the upper level taxonamy
sub _inParentTaxonomy {

    my $self = shift;
    my $concept = shift;

    my $function = "_inParentTaxonomy";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    if(exists $parentTaxonomyArray{$concept}) { return 1; }
    else                                 { return 0; }
}

#  checks to see if the cui is in the child taxonomy
#  input : $concept <- string containing a cui
#  output: $bool    <- indicating if the cui exists in
#                      the upper level taxonamy
sub _inChildTaxonomy {

    my $self = shift;
    my $concept = shift;

    my $function = "_inChildTaxonomy";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }

    if(exists $childTaxonomyArray{$concept}) { return 1; }
    else                                 { return 0; }
}


#  function to create a timestamp
#  input :
#  output: $string <- containing the time stamp
sub _timeStamp {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    $year += 1900;
    $mon++;
    my $d = sprintf("%4d%2.2d%2.2d",$year,$mon,$mday);
    my $t = sprintf("%2.2d%2.2d%2.2d",$hour,$min,$sec);

    my $stamp = $d . $t;

    return $stamp;
}

#  function to get the time
#  input :
#  output: $string <- containing the time
sub _printTime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    $year += 1900;
    $mon++;

    my $d = sprintf("%4d%2.2d%2.2d",$year,$mon,$mday);
    my $t = sprintf("%2.2d%2.2d%2.2d",$hour,$min,$sec);

    print STDERR "$t\n";

}

#  return the file name containing the index table
sub _getTableFile {

    return $tableFile;
}


#  return the table name in the index - this is the hex
sub _getTableName {

    return $tableName;
}

#  return the table name in the index in human form
sub _getTableNameHuman {

    return $tableNameHuman;
}

sub _getCacheTableName {
    return $cacheTable;
}

sub _getCacheTableNameHuman{ 
    return $cacheTableHuman;
}

sub _getInfoTableName {
    return $infoTable;
}

sub _getInfoTableNameHuman {
    return $infoTableHuman;
}

sub _getIntrinsicTableName {
    return $intrinsicTable;
}

sub _getIntrinsicTableNameHuman {
    return $intrinsicTableHuman;
}

1;




__END__

=head1 NAME

UMLS::Interface::CuiFinder - provides the information about CUIs 
in the UMLS for the modules in the UMLS::Interface package.

=head1 DESCRIPTION

This package provides the information about CUIs in the
UMLS for the modules in the UMLS::Interface package.

For more information please see the UMLS::Interface.pm documentation.

=head1 SYNOPSIS

 use UMLS::Interface::CuiFinder;
 use UMLS::Interface::ErrorHandler;

 %params = ();

 $params{"realtime"} = 1;

 $cuifinder = UMLS::Interface::CuiFinder->new(\%params);
 die "Unable to create UMLS::Interface::CuiFinder object.\n" if(!$cuifinder);

 $root = $cuifinder->_root();
 print "The root is: $root\n";

 $version = $cuifinder->_version();
 print "The UMLS version is: $version\n";

 $concept = "C0018563"; $rel = "SIB";
 $array = $cuifinder->_getRelated($concept, $rel);
 print "The sibling(s) of $concept is:\n";
 foreach my $s (@{$array}) { print "  => $s\n"; }
 print "\n";

 $array = $cuifinder->_getTermList($concept);
 $array = $cuifinder->_getDefTermList($concept);
 $array = $cuifinder->_getAllTerms($concept);
 print "The terms of $concept are: @{$array}\n";

 $term = shift @{$array};
 $array = $cuifinder->_getConceptList($term);
 $array = $cuifinder->_getDefConceptList($term);
 $array = $cuifinder ->_getAllConcepts($term);
 print "The possible CUIs of the $term are: @{$array}\n";

 $hash = $cuifinder->_getCuiList();

 $sab = "MSH";
 $array = $cuifinder->_getCuisFromSource($sab);

 $array = $cuifinder->_getSab($concept);
 print "$concept exists in the following sources:\n";
 foreach my $sab (@{$array}) {  print "  => $sab\n"; }
 print "\n";

 $array = $cuifinder->_getChildren($concept);
 print "Children of $concept @{$array}\n";

 $array = $cuifinder->_getParents($concept);
 print "Parents of $concept: @{$array}\n\n";

 $array = $cuifinder->_getRelations($concept);
 print "The relations of $concept: @{$array}\n";

 $concept1 = "C0018563"; $concept2 = "C0037303";

 $array = $cuifinder->_getSt($concept);
 print "The semantic type of $concept: @{$array}\n";

 $abr = "bpoc";
 $string = $cuifinder->_getStString($abr);

 $tui = "T12";
 $string = $cuifinder->_getStAbr($tui);

 $definition = $cuifinder->_getStDef($abr);
 print "Definition of semantic type ($abr): @{$definition}\n\n";


 $array = $cuifinder->_getCuiDef($concept, $sabflag);
 print "Definition of $concept: \n";
 foreach my $el (@{$array}) {
    print "  =>$el\n";
 } 
 print "\n";

 my $concept = "C0376209";
 $array = $cuifinder->_getExtendedDefinition($concept);
 print "Extended definition of $concept: \n";
 foreach my $el (@{$array}) {
    print "  => $el\n";
 } 
 print "\n";

 $bool = $cuifinder->_exists($concept);

 $hash = $cuifinder->_returnTableNames();
 print "The tables currently in the index are: \n";
 foreach my $t (sort keys %{$hash}) { print "  => $t\n"; }

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

=head1 SEE ALSO

L<http://tech.groups.yahoo.com/group/umls-similarity/>

L<http://search.cpan.org/dist/UMLS-Similarity/>

=head1 AUTHOR

    Bridget T McInnes <bthomson@cs.umn.edu>
    Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT

    Copyright (c) 2007-2011
    Bridget T. McInnes, University of Minnesota
    bthomson at cs.umn.edu

    Ted Pedersen, University of Minnesota Duluth
    tpederse at d.umn.edu

    Siddharth Patwardhan, University of Utah, Salt Lake City
    sidd at cs.utah.edu

    Serguei Pakhomov, University of Minnesota Twin Cities
    pakh0002 at umn.edu

    Ying Liu, University of Minnesota Twin Cities
    liux0395 at umn.edu

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
