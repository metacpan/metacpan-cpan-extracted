# UMLS::Interface::PathFinder
# (Last Updated $Id: PathFinder.pm,v 1.68 2016/10/18 16:10:06 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2010,
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

package UMLS::Interface::PathFinder;

use Fcntl;
use strict;
use warnings;
use bytes;

my $pkg = "UMLS::Interface::PathFinder";

my $debug = 0;

my $max_depth = -1;

my $root = "";

my $option_verbose     = 0;
my $option_forcerun    = 0;
my $option_realtime    = 0;
my $option_t           = 0;
my $option_debugpath   = 0;
my $option_cuilist     = 0;
my $option_undirected  = 0;

my $errorhandler = "";
my $cuifinder    = "";

my %maximumDepths = ();

local(*DEBUG_FILE);

# UMLS-specific stuff ends ----------

# -------------------- Class methods start here --------------------

#  method to create a new UMLS::Interface::PathFinder object
sub new {

    my $self = {};
    my $className = shift;
    my $params    = shift;
    my $handler   = shift;
    
    # bless the object.
    bless($self, $className);

    #  initialize the global variables
    $self->_initializeGlobalVariables();

    # initialize error handler
    $errorhandler = UMLS::Interface::ErrorHandler->new();
        if(! defined $errorhandler) {
	print STDERR "The error handler did not get passed properly.\n";
	exit;
    }

    #  initialize the cuifinder
    $cuifinder = $handler;
    if(! (defined $handler)) { 
	$errorhandler->_error($pkg, 
			      "new", 
			      "The CuiFinder handler did not get passed properly", 
			      8);
    }

    #iInitialize the object.
    $self->_initialize($params);   

    return $self;
}

sub _initializeGlobalVariables {

    $debug = 0;
    
    $max_depth = -1;
    
    $root = "";
    
    $option_verbose     = 0;
    $option_forcerun    = 0;
    $option_realtime    = 0;
    $option_t           = 0;
    $option_debugpath   = 0;
    $option_cuilist     = 0;
    $option_undirected  = 0;
    
    $errorhandler = "";
    $cuifinder    = "";
    
    %maximumDepths = ();
}    

# Method to initialize the UMLS::Interface::PathFinder object.
sub _initialize {

    my $self      = shift;
    my $params    = shift;

    #  set function name
    my $function = "_initialize";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
        
    #  get the umlsinterfaceindex database from CuiFinder
    my $sdb = $cuifinder->_getIndexDB();
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
    $self->{'sdb'} = $sdb;
    
    #  get the root
    $root = $cuifinder->_root();

    #  set up the options
    $self->_setOptions($params);
}

#  method to set the realtime global parameter options
#  input : bool <- 1 (turn on) 0 (turn off)
#  output: 
sub _setRealtimeOption { 

    my $self = shift;
    my $option = shift;

    my $function = "_setRealtimeOption";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    if($option == 1) { 
	$option_realtime = 1; 
    }
    else { 
	$option_realtime = 0; 
    }
}

#  method to set the undirected global parameter options
#  input : bool <- 1 (turn on) 0 (turn off)
#  output: 
sub _setUndirectedOption { 

    my $self = shift;
    my $option = shift;

    my $function = "_setUndirectedOption";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    if($option == 1) { 
	$option_undirected = 1; 
    }
    else { 
	$option_undirected = 0; 
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

    #  get all the parameters
    my $forcerun     = $params->{'forcerun'};
    my $verbose      = $params->{'verbose'};
    my $realtime     = $params->{'realtime'};
    my $debugoption  = $params->{'debug'};
    my $t            = $params->{'t'};
    my $debugpath    = $params->{'debugpath'};
    my $cuilist      = $params->{'cuilist'};
    my $undirected   = $params->{'undirected'};

    my $output = "";
    if(defined $forcerun    || defined $verbose   || defined $realtime || 
       defined $debugoption || defined $debugpath || defined $cuilist) { 
	$output .= "\nPathFinder User Options:\n";
    }

    #  check if the debug option has been been defined
    if(defined $debugoption) { 
	$debug = 1; 
	$output .= "   --debug option set\n";
    }
    
    #  print debug if it has been set
    &_debug($function);

    if(defined $t) {
	$option_t = 1;
    }

    #  check if the undirected option is set for shortest path
    if(defined $undirected) { 
	$option_undirected = 1;
	$output .= "  --undirected option set\n";
    }
    
    #  check if the cuilist option has been defined
    if(defined $cuilist) { 
	$option_cuilist = 1;
	$output .= "  --cuilist option set\n";
    }
    
    
    #  check if debugpath option 
    if(defined $debugpath) {
	$option_debugpath = 1;
	$output .= "   --debugpath $debugpath\n";
	open(DEBUG_FILE, ">$debugpath") || 
	    die "Could not open depthpath file $debugpath\n";
    }

    #  check if the realtime option has been identified
    if(defined $realtime) {
	$option_realtime = 1;
	
	$output .= "  --realtime option set\n";
    }

    #  check if verbose run has been identified
    if(defined $verbose) { 
	$option_verbose = 1;
	
	$output .= "   --verbose option set\n";
    }

    #  check if a forced run has been identified
    if(defined $forcerun) {
	$option_forcerun = 1;
	
	$output .= "   --forcerun option set\n";
    }

    if($option_t == 0) {
	print STDERR "$output\n";
    }
}

#  method to return the maximum depth of a taxonomy.
#  input :
#  output: $int <- string containing the max depth
sub _depth {

    my $self = shift;
    
    my $function = "_depth";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the depth and set the path information
    if($max_depth >= 0) { 
	return $max_depth;
    }

    #  check if it is in the info table and if it is return 
    #  that otherwise we need to find the maximum depth and
    #  then store it here

    #  get the info table name
    my $infoTableName = $cuifinder->_getInfoTableName();
    
    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  get maximum depth from the info table
    my $arrRef = $sdb->selectcol_arrayref("select INFO from $infoTableName where ITEM=\'DEPTH\'");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  get the depth from the array
    my $depth = shift @{$arrRef};

    #  if the depth was there set the maximum depth and return it
    #  otherwise we are off to find it either in realtime or through
    #  the database depending on the user options
    if(defined $depth) { 
	$max_depth = $depth; 
	return $max_depth;
    }

    #  find the depth in realtime
    if($option_realtime) {
	my @array = ();
	my %visited = ();

      	$self->_getMaxDepth($root, 0, \@array, \%visited);
	
	#  the _getMaxDepth method does a DFS over the entire 
	#  heirarchy - I am not certain a way around this yet 
	#  but while we were add I stored the maximum depth 
	#  of each of the CUIs in a hash since there is not a 
	#  quick way of determining this in realtime as of yet
	
	#  we are going to store them in the info table. This is 
	#  hopefully a temporary solution until I can figure out 
	#  a way to speed up getMaximumDepthInRealTime - if we 
	#  run out of room with this, I will just keep the hash 
	#  and then have to go through the
	foreach my $cui (sort keys %maximumDepths) { 
	    my $d = $maximumDepths{$cui};
	    $sdb->do("INSERT INTO $infoTableName (ITEM, INFO) VALUES ('$cui', '$d')");
	    $errorhandler->_checkDbError($pkg, $function, $sdb);
	}
    }
    #  otherwise find it in the database
    else {
	$self->_setIndex();
    }

    #  at this point we have the max depth and the variable has been set
    #  so we are going to insert this into the info table and then return it
    $sdb->do("INSERT INTO $infoTableName (ITEM, INFO) VALUES ('DEPTH', '$max_depth')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  return the maximum depth
    return $max_depth;
}

#  recursive method to obtain the maximum depth in realtime
#  input : $concept <- string containing cui
#          $d       <- string containing the depth of the cui
#          $array   <- reference to an array containing the current path
#  output: $concept <- string containing cui
#          $int     <- string containing the depth of the cui
#          $array   <- reference to an array containing the current path
sub _getMaxDepth {

    my $self    = shift;
    my $concept = shift;
    my $d       = shift;
    my $array   = shift;
    my $hash    = shift;

    my $function = "_getMaxDepth";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check concept was obtained
    if(!$concept) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }

    #  check that the concept is not a forbidden concept
    if($cuifinder->_forbiddenConcept($concept) == 1) { return; }

    #  set up the new path
    my @path = @{$array};
    push @path, $concept;
    my $series = join " ", @path;

    #  if have already been here -  leave
    if(exists ${$hash}{$concept}{$series}) { return; }
    else { ${$hash}{$concept}{$series}++; }

   
    #  check to see if it is the max depth
    if(($d) > $max_depth) { $max_depth = $d; }

    #  increment the depth
    $d++;
    
    #  add to the depths hash - if we are going to go through the trouble 
    #  of having to do a depth first search - we might as well find the 
    #  the maximum depths of all the cuis and store these in the database
    #  I am going to see if I can store them in a hash and then dump the 
    #  hash in the database when I am finished. This way we don't have
    #  to continually access the database which is really not an acceptable
    #  solution
    if(! (exists $maximumDepths{$concept}) ) { $maximumDepths{$concept} = $d; }
    elsif($maximumDepths{$concept} < $d)     { $maximumDepths{$concept} = $d; }

    #  get all the children
    my $children = $cuifinder->_getChildren($concept);
       
    #  search through the children
    foreach my $child (@{$children}) {
	
	#  check if child cui has already in the path
	if($series=~/$child/)  { next; }
	if($child eq $concept) { next; }
	
	#  if it isn't continue on with the depth first search
	$self->_getMaxDepth($child, $d, \@path, $hash);
    }
}

#  method to find all the paths from a concept to
#  the root node of the is-a taxonomy.
#  input : $concept <- string containing cui
#  output: $array   <- array reference containing the paths
sub _pathsToRoot {

    my $self = shift;
    my $concept = shift;

    my $function = "_pathsToRoot";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }

    #  get the relations from the configuration file
    my $configrel = $cuifinder->_getRelString();
    $configrel=~/(REL) (\:\:) (include|exclude) (.*?)$/;
    my $relationstring = $4; 

    #  check to make certain the configuration file only contains
    #  heirarchical relations (PAR/CHD or RB/RN).
    #my @relations = split/\s*\,\s*/, $relationstring; 
    #foreach my $rel (@relations) { 
	#if(! ($rel=~/(PAR|CHD|RB|RN)/) ) { 
	    #$errorhandler->_error($pkg, $function, "Method only supports heirarhical relations (PAR/CHD or RB/RN).", 10);
	#} 
    #}
         
    #  if the realtime option is set get the paths otherwise 
    #  they are or should be stored in the database 
    my $paths = ""; 
    if($option_realtime) {
	$paths = $self->_getPathsToRootInRealtime($concept);
    }
    else {
	$paths = $self->_getPathsToRootFromIndex($concept);
    }
    
    return $paths    
}

#  returns all the paths to the root from the concept 
#  this information is stored in the index - if it is
#  not then the index is created
#  input : $string <- string containing the cui (assumed correct)
#  output: $array  <- reference to an array containing the paths
sub _getPathsToRootFromIndex {
    my $self    = shift;
    my $concept = shift;

    my $function = "_getPathsToRootFromIndex";
  
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  if the concept is the root then return root
    if($concept eq $root) { 
	my @array = (); push @array, $root;
	return \@array;
    }

    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
    
    #  create the index if it hasn't been created
    $self->_setIndex();

    #  get the table name
    my $tableName = $cuifinder->_getTableName();
    
    #  get the paths from the database
    my $paths = $sdb->selectcol_arrayref("select PATH from $tableName where CUI=\'$concept\'");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
    
    return $paths;
}

#  check the index to make certain it is load properly
#  input : 
#  outupt: 
sub _checkIndex {


    my $self           = shift;
    my $tableFile      = shift;
    my $tableName      = shift;
    my $tableNameHuman = shift;

    my $function = "_checkIndex";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check the input variables
    if(!$tableFile || !$tableName || !$tableNameHuman)      { 
	$errorhandler->_error($pkg, $function, "Error with input variables.", 4);
    }

    #  set the auxillary database that holds the path information
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  extract the check
    my $arrRef = $sdb->selectcol_arrayref("select CUI from $tableName where CUI=\'CHECK\'");
    
    my $count = $#{$arrRef};
    
    if($count != 0) {
	my $str = "Index did not complete. Remove using the removeConfigData.pl program and re-run.";
	$errorhandler->_error($pkg, $function, $str, 9);
    }
    
}

#  load the index in realtime
#  input : 
#  outupt: 
sub _createIndex {


    my $self           = shift;
    my $tableFile      = shift;
    my $tableName      = shift;
    my $tableNameHuman = shift;

    my $function = "_createIndex";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check the input variables
    if(!$tableFile || !$tableName || !$tableNameHuman)      { 
	$errorhandler->_error($pkg, $function, "Error with input variables.", 4);
    }

    #  set the auxillary database that holds the path information
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    print STDERR "You have requested path information about a concept. In\n"; 
    print STDERR "order to obtain this information we need to create an \n";
    print STDERR "index or resubmit this command using --realtime. Creating\n";
    print STDERR "an index can be very time-consuming, but once it is built\n";
    print STDERR "your commands will run faster than with --realtime.\n\n";    

    if($option_forcerun == 0) {
	print STDERR "Do you want to continue with index creation (y/n)";
	    
	my $answer = <STDIN>; chomp $answer;
	
	if($answer=~/(N|n)/) {
	    print STDERR "Exiting program now.\n\n";
	    exit;
	}
    }
    else {
	print "Running index ... \n";
    }
    
	    
    #  create the table in the umls database
    $sdb->do("CREATE TABLE IF NOT EXISTS $tableName (CUI char(8), DEPTH int, PATH varchar(450))");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
	    
    #  insert the name into the index
    $sdb->do("INSERT INTO tableindex (TABLENAME, HEX) VALUES ('$tableNameHuman', '$tableName')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  for each root - this is for when we allow multiple roots
    #  right now though we only have one - the umlsRoot
    $self->_initializeDepthFirstSearch($root, 0, $root);

    #  add a check that the DFS has finished
    $sdb->do("INSERT INTO $tableName (CUI, DEPTH, PATH) VALUES(\'CHECK\', '0', \'\')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  create index on the newly formed table
    my $indexname = "$tableName" . "_CUIINDEX";
    my $index = $sdb->do("create index $indexname on $tableName (CUI)");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    print "Index created.\n\n";
}

#  creates the index containing all of the path to root information 
#  for each concept in the sources and relations specified in the 
#  configuration file
#  input : 
#  output:
sub _setIndex {

    my $self = shift;

    my $function = "_setIndex";
    &_debug($function);
           
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    my $tableName      = $cuifinder->_getTableName();
    my $tableFile      = $cuifinder->_getTableFile();
    my $tableNameHuman = $cuifinder->_getTableNameHuman();

    #  if the path infomration has not been stored
    if(! ($cuifinder->_checkTableExists($tableName))) {
	
	#  otherwise create the tableFile and put the information in the 
	#  file and the database
	$self->_createIndex($tableFile, $tableName, $tableNameHuman);
	
    }

    #  check Index
    $self->_checkIndex($tableFile, $tableName, $tableNameHuman);

    #  set the maximum depth
    $self->_setMaximumDepth();
}    

#  set the maximum depth variable
#  input :
#  output: 
sub _setMaximumDepth {
    my $self = shift;

    my $function = "_setMaximumDepth";
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the auxillary database that holds the path information
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  get the table name
    my $tableName = $cuifinder->_getTableName();

    #  set the maximum depth
    my $d = $sdb->selectcol_arrayref("select max(DEPTH) from $tableName");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    $max_depth = shift @{$d}; 
}

#  print out the function name to standard error
#  input : $function <- string containing function name
#  output: 
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Interface::PathFinder::$function\n"; }
}

#  A Depth First Search (DFS) in order to determine 
#  the maximum depth of the taxonomy and obtain 
#  all of the path information
#  input : 
#  output: 
sub _initializeDepthFirstSearch {

    my $self    = shift;
    my $concept = shift;
    my $d       = shift;
    my $root    = shift;
    
    my $function = "_initializeDepthFirstSearch";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
   
    #  check the parameters are defined
    if(!(defined $concept) || !(defined $d) || !(defined $root)) {
	$errorhandler->_error($pkg, $function, "Error with input variables.", 4);
    }

    #  check valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
	$errorhandler->_error($pkg, $function, "Incorrect input value ($concept).", 6);
    }
       
    my $tableFile = $cuifinder->_getTableFile();

    #  check if verbose mode
    if($option_verbose) {
	open(TABLEFILE, ">$tableFile") || die "Could not open $tableFile";
    }
    
    #  get the children
    my $children = $cuifinder->_getChildren($concept);
    
    my $subsumers; my $leafs; my $s = 0; my $l = 0; 
    #  foreach of the children continue down the taxonomy
    foreach my $child (@{$children}) {
	my @array = (); 
	push @array, $concept; 
	my $path  = \@array;
	($subsumers, $leafs) = $self->_depthFirstSearch($child, $d,$path,*TABLEFILE); 
	$s += keys %{$subsumers}; $l += keys %{$leafs}; 
    }
    
    #  get the database
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
        
    #  get the table name of the intrinsic index and insert the leaves and subsumers
    my $intrinsicTableName = $cuifinder->_getIntrinsicTableName();    
    my $arrRef = $sdb->do("INSERT INTO $intrinsicTableName (CUI, LEAVES, SUBSUMERS) VALUES(\'$concept\', '$l', \'$s\')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  close the table file if in verbose mode
    if($option_verbose) {
	close TABLEFILE;
    
	#  set the table file permissions
	my $temp = chmod 0777, $tableFile;
    }
}

#  This is like a reverse DFS only it is not recursive
#  due to the stack overflow errors I received when it was
#  input :
#  output: 
sub _getPathsToRootInRealtime {

    my $self    = shift;
    my $concept = shift;

    return () if(!defined $self || !ref $self);

    my $function = "_getPathsToRootInRealtime($concept)";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check concept was obtained
    if(!$concept) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }

    #  set the  storage
    my @path_storage = ();

    #  set the stack
    my @stack = ();
    push @stack, $concept;

    #  set the count
    my %visited = ();

    #  set the paths
    my @paths = ();
    my @empty = ();
    push @paths, \@empty;

    #  now loop through the stack
    while($#stack >= 0) {
	
	my $concept = $stack[$#stack];
	my $path    = $paths[$#paths];

	#  set up the new path
	my @intermediate = @{$path};
	push @intermediate, $concept;
	my $series = join " ", @intermediate;
	        
	#  check that the concept is not one of the forbidden concepts
	if($cuifinder->_forbiddenConcept($concept)) { 
	    pop @stack; pop @paths;
	    next;
	}

	#  check if concept has been visited already
	if(exists $visited{$series}) { 
	    pop @stack; pop @paths;
	    next; 
	}
	else { $visited{$series}++; }
	
	#  print information into the file if debugpath option is set
	if($option_debugpath) { 
	    my $d = $#intermediate+1;
	    print DEBUG_FILE "$concept\t$d\t@intermediate\n"; 
	}
	
	#  if the concept is the umls root - we are done
	if($concept eq $root) { 
	    #  this is a complete path to the root so push it on the paths 
	    my @reversed = reverse(@intermediate);
	    my $rseries  = join " ", @reversed;
	    push @path_storage, $rseries;
	    next;
	}
	
	#  get all the parents
	my $parents = $cuifinder->_getParents($concept);
	
	#  if there are no children we are finished with this concept
	if($#{$parents} < 0) {
	    pop @stack; pop @paths;
	    next;
	}

	#  search through the children
	my $stackflag = 0;
	foreach my $parent (@{$parents}) {
	    
	    #  check if concept is already in the path
	    if($series=~/$parent/)  { next; }
	    if($concept eq $parent) { next; }

	    #  if it isn't continue on with the depth first search
	    push @stack, $parent;
	    push @paths, \@intermediate;
	    $stackflag++;
	}
	
	#  check to make certain there were actually children
	if($stackflag == 0) {
	    pop @stack; pop @paths;
	}
    }

    return \@path_storage;
}

#  Depth First Search (DFS) recursive function to collect the path 
#  information and store it in the umlsinterfaceindex database
#  input : $concept <- string containing the cui 
#          $depth   <- depth of the cui
#          $array   <- reference to an array containing the path
#  output: $concept <- string containing the cui 
#          $depth   <- depth of the cui
#          $array   <- reference to an array containing the path
sub _depthFirstSearch {

    my $self      = shift;
    my $concept   = shift;
    my $d         = shift;
    my $array     = shift;
    local(*F)     = shift;
        
    my $function = "_depthFirstSearch";
    
      #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters are defined
    if(!(defined $concept) || !(defined $d)) {
	$errorhandler->_error($pkg, $function, "Error with input variables.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }
    
    #  check that the concept is not a forbidden concept
    if($cuifinder->_forbiddenConcept($concept)) { return; }
    
    #  get the database
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
    
    #  get the table name of the index
    my $tableName = $cuifinder->_getTableName();
    
    #  increment the depth
    $d++;

    #  set up the new path
    my @path = @{$array};
    push @path, $concept;
    my $series = join " ", @path;
    
    #  load path information into the table
    #  check if only a specified set of cui information is required
    if($option_cuilist) {
    
	#  check if it is in the cuilist - and if so insert it the cui
	if($cuifinder->_inCuiList($concept)) { 
	    my $arrRef = $sdb->do("INSERT INTO $tableName (CUI, DEPTH, PATH) VALUES(\'$concept\', '$d', \'$series\')");
	    $errorhandler->_checkDbError($pkg, $function, $sdb);
	}
    } 
    #  otherwise we are loading all of it
    else {
	my $arrRef = $sdb->do("INSERT INTO $tableName (CUI, DEPTH, PATH) VALUES(\'$concept\', '$d', \'$series\')");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
    }
    
    #  print information into the file if verbose option is set
    if($option_verbose) { 
	if($option_cuilist) {
	    if($cuifinder->_inCuiList($concept)) { 
		print F "$concept\t$d\t$series\n"; 
	    }
	} 
	else { print F "$concept\t$d\t$series\n"; }
    }
    
    #  get all the children
    my $children = $cuifinder->_getChildren($concept);

    my %totalLeaves = (); my %totalSubsumers = (); 
    #  search through the children
    foreach my $child (@{$children}) {
	
	#  check if child cui has already in the path
	if($series=~/$child/)  { next; }
	if($child eq $concept) { next; }
	
	#  if it isn't continue on with the depth first search
	my ($subsumers, $leafs) = $self->_depthFirstSearch($child, $d, \@path,*F);
	
	if(defined $leafs) { 
	    if(%{$leafs}) {
		%totalLeaves = (%totalLeaves, %{$leafs}); 
	    }
	}
	if(defined $subsumers) { 
	    if(%{$subsumers}) { 
		%totalSubsumers = (%totalSubsumers, %{$subsumers}); 
	    }
	}
    }
    my $l = keys %totalLeaves; my $s = keys %totalSubsumers; 
    
    #  get the table name of the intrinsic index and insert the leaves and subsumers
    my $intrinsicTableName = $cuifinder->_getIntrinsicTableName();    
    
    #  check if CUI is already there
    my $ex = $sdb->selectcol_arrayref("select count(*) from $intrinsicTableName where CUI=\'$concept\'");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
    
    #  return the minimum depth
    my $count = shift @{$ex}; 
    if($count == 0) { 
	my $arrRef = $sdb->do("INSERT INTO $intrinsicTableName (CUI, LEAVES, SUBSUMERS) VALUES(\'$concept\', '$l', \'$s\')");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
    }

    if($#{$children} < 0) { $totalLeaves{$concept}++; } $totalSubsumers{$concept}++; 

    return (\%totalSubsumers, \%totalLeaves);
}

#  function returns the minimum depth of a concept
#  input : $concept <- string containing the cui
#  output: $int     <- string containing the depth of the cui
sub _findMinimumDepth {

    my $self = shift;
    my $cui  = shift;

    my $function = "_findMinimumDepth";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check concept was obtained
    if(!$cui) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$cui.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($cui)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($cui) in not valid.", 6);
    }
    
    #  get the database
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
    
    #  if it is in the parent taxonomy 
    if($cuifinder->_inParentTaxonomy($cui)) { return 1; }
    
    my $min = 0;
    if($option_realtime) {
	$min = $self->_findMinimumDepthInRealTime($cui); 
    }
    else {
	
	#  set the depth
	$self->_setIndex();

	#  get the table name
	my $tableName = $cuifinder->_getTableName();

	#  get the minimum depth from the table
	my $d = $sdb->selectcol_arrayref("select min(DEPTH) from $tableName where CUI=\'$cui\'");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
	
	#  return the minimum depth
	$min = shift @{$d}; $min++;
    }
    
    return $min;
}

#  function returns maximum depth of a concept
#  input : $concept <- string containing the cui
#  output: $int     <- string containing the depth of the cui
sub _findMaximumDepth {

    my $self = shift;
    my $cui  = shift;

    my $function = "_findMaximumDepth";
    &_debug($function);
        
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check concept was obtained
    if(!$cui) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$cui.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($cui)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($cui) in not valid.", 6);
    }
    
    #  get the database
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }
    
    #  initialize max
    my $max = 0;
    #  if realtime option is set
    if($option_realtime) {
	#  get the info table name
	my $infoTableName = $cuifinder->_getInfoTableName();
    
	#  set the index DB handler
	my $sdb = $self->{'sdb'};
	if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

	#  get maximum depth from the info table
	my $arrRef = $sdb->selectcol_arrayref("select INFO from $infoTableName where ITEM=\'$cui\'");
	$errorhandler->_checkDbError($pkg, $function, $sdb);
	
	#  get the depth from the array
	my $depth = shift @{$arrRef};

	if(defined $depth) { 
	    $max = $depth;
	}
	else {
	    #  get the maximum depth
	    $max = $self->_findMaximumDepthInRealTime($cui); 
	    
	    #  insert it in the info table - this is caching over multipe runs of 
	    #  the program. I don't really like this solution but until I can 
	    #  figure out how to speed up findMaximumDepthInRealTime then 
	    #  this is going to have to do. 
	    $sdb->do("INSERT INTO $infoTableName (ITEM, INFO) VALUES ('$cui', '$max')");
	    $errorhandler->_checkDbError($pkg, $function, $sdb);

	}
    }
    
    #  otherwise
    else {
	#  set the depth
	$self->_setIndex();
	
	#  get the table name
	my $tableName = $cuifinder->_getTableName();
		
	#  get the depth from the table
	my $d = $sdb->selectcol_arrayref("select max(DEPTH) from $tableName where CUI=\'$cui\'");
	$errorhandler->_checkDbError($pkg, $function, $sdb);

	$max = shift @{$d}; $max++;
    }

    #  return the maximum depth
    return $max;    
}

#  find the shortest path between two concepts
#  input : $concept1 <- string containing the first cui
#          $concept2 <- string containing the second
#  output: $array    <- reference to an array containing the shortest path(s)
sub _findShortestPath {

    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $function = "_findShortestPath";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    

    #  if realtime option is set find the shortest path in realtime 
    if($option_realtime) {
       	return $self->_findShortestPathInRealTime($concept1, $concept2);
    }
    else {
	return $self->_findShortestPathThroughLCS($concept1, $concept2);
    }
}


#  this function returns the shortest path between two concepts
#  input : $concept1 <- string containing the first cui
#          $concept2 <- string containing the second
#  output: $array    <- reference to an array containing the lcs(es)
sub _findShortestPathThroughLCS {
    
    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathThroughLCS";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    

    #  find the shortest path(s) and lcs - there may be more than one
    my $hash = $self->_shortestPath($concept1, $concept2);
    
    #  remove the blanks from the paths
    my @paths = (); my $output = "";
    foreach my $path (sort keys %{$hash}) {
	if($path=~/C[0-9]+/) {
	    push @paths, $path;
	}
    } 
        
    #  return the shortest paths (all of them)
    return \@paths;
}


#  this function returns the least common subsummer between two concepts
#  input : $concept1 <- string containing the first cui
#          $concept2 <- string containing the second
#  output: $array    <- reference to an array containing the lcs(es)
sub _findLeastCommonSubsumer {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findLeastCommonSubsumer";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    
    
    #  get the relations from the configuration file
    my $configrel = $cuifinder->_getRelString();
    $configrel=~/(REL) (\:\:) (include|exclude) (.*?)$/;
    my $relationstring = $4; 

    #  check to make certain the configuration file only contains
    #  heirarchical relations (PAR/CHD or RB/RN).
    my @relations = split/\s*\,\s*/, $relationstring; 
    foreach my $rel (@relations) { 
	if(! ($rel=~/(PAR|CHD|RB|RN)/) ) { 
	    $errorhandler->_error($pkg, $function, "Method only supports heirarhical relations (PAR/CHD or RB/RN).", 10);
	} 
    }

    #  get the LCSes
    if($option_realtime) {
	return $self->_findLeastCommonSubsumerInRealTime($concept1, $concept2);
    }
    else {

	#  initialize the array that will contain the lcses
	my @lcses = (); 
	
	#  get the lcs using the index
	my $hash = $self->_shortestPath($concept1, $concept2);
	if($debug) { print STDERR "done with _shortestPath\n"; }
	my %lcshash = ();
	if(defined $hash) {
	    foreach my $path (sort keys %{$hash}) { 
		my $c = ${$hash}{$path};
		if($c=~/C[0-9]+/) { $lcshash{$c}++; }
	    }
	}
	foreach my $lcs (sort keys %lcshash) { push @lcses, $lcs; }
    
	#  return the lcses
	return \@lcses;
    }
}

#  this function returns the least common subsummer between two concepts
#  input : $concept1 <- string containing the first cui
#          $concept2 <- string containing the second
#  output: $array    <- reference to an array containing the lcs(es)
sub _findLeastCommonSubsumerInRealTime {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findLeastCommonSubsumerInRealTime";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    
    
    #  get the shorest paths
    my $paths = $self->_findShortestPathInRealTime($concept1, $concept2);
    
    #  get the child relations
    my $childstring = $cuifinder->_getChildRelations();

    #  initialize the lcses array
    my %lcses = ();
 
   #  check for the lcs in each of the paths
    foreach my $p (@{$paths}) {
	#  get the path and the first concept
	my @path     = split/\s+/, $p;
	my $concept1 = shift @path;
	my $flag     = 0;
	my $counter  = 0;
	my $children = 0;
	my $parent   = 0;
	my @lcsarray = ();
	
	my $firstconcept = $concept1;

	#  loop through the rest of the concepts looking for the first child relation
	foreach my $concept2 (@path) {
	    my $relations = $cuifinder->_getRelationsBetweenCuis($concept1, $concept2);
	    foreach my $item (@{$relations}) {
		$item=~/([A-Z]+) \([A-Z0-9\.]+\)/;
		my $rel = $1;

		#  if the relation is a child we have the LCS - it is concept1 
		#  this is for the typical case
		if($childstring=~/($rel)/ && $flag == 0) {
		    push @lcsarray, $concept1; $flag++; 
		}
		
		if($childstring=~/($rel)/) { $children++; }
		else                       { $parent++;   }
		$counter++;
	    }
	    $concept1 = $concept2;
	}
	
	#  string of children
	if($counter == $children)  { $lcses{$firstconcept}++; }
	#  string of parents
	elsif($counter == $parent) { $lcses{$concept1}++; }
	#  typical case
	else { foreach my $l (@lcsarray) { $lcses{$l}++; } }
}
    
    #  get the unique lcses - note a single lcs may have more than one path
    my @unique = ();
    foreach my $lcs (sort keys %lcses) { push @unique, $lcs; }

    #  return the unique lcses
    return \@unique;
}

#  method to get the Least Common Subsumer of two 
#  paths to the root of a taxonomy
#  input : $array1 <- reference to an array containing 
#                     the paths to the root for cui1
#          $array2 <- same thing for cui2
#  output: $hash   <- reference to a hash containing the
#                     lcs as the key and the path as the hash
sub _getLCSfromTrees {

    my $self      = shift;
    my $arrayref1 = shift;
    my $arrayref2 = shift;
        
    my $function = "_getLCSfromTrees";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $arrayref1) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$arrayref1.", 4);
    }
    if(!defined $arrayref2) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$arrayref2.", 4);
    }

    #  get the arrays
    my @array1 = split/\s+/, $arrayref1;
    my @array2 = split/\s+/, $arrayref2;

    #  reverse them
    my @tree1 = reverse @array1;
    my @tree2 = reverse @array2;
    my $tmpString = " ".join(" ", @tree2)." ";

    #  find the lcs
    foreach my $element (@tree1) {
	if($tmpString =~ / $element /) {
	    return $element;
	}
    }
    
    return undef;
}

#  method to find the shortest path between two concepts in realtime
#  input : $concept1 <- first concept
#          $concept2 <- second concept
#  output: $array    <- reference to an array containing the shortest paths
sub _findShortestPathInRealTime {
    
    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathInRealTime";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    

    #  get the length of the shortest path
    my $length = $self->_findShortestPathLengthInRealTime($concept1, $concept2);
   
    #  initialize the paths array that will be returned
    my @paths = ();
    
    #  if the length is two then the cuis are related in some way
    #  so just return them
    if($length == 2) {
	push @paths, "$concept1 $concept2";
    }
    else {

	#  set split to get the beginning paths
	my $split1 = int($length/2);

	#  we need the cui itself so, if the split is zero setting the
	#  split to one will just return the cuis
	if($split1 == 0) { $split1 = 1; }
	
	#  set split to get the last set of paths
	my $split2 = $length - $split1 -1; 
	
	#  initial the hash to hold the ends
	my %ends = ();
	
	#  get all the paths from concept1 of length split1
	my @paths1 = $self->_findPathsToCenter($concept1, $split1, 1, \%ends );
	
	my $endkey = keys %ends;

	#  get all the paths from concept2 of length split2
	my @paths2 = $self->_findPathsToCenter($concept2, $split2, 2, \%ends );

	#  join the two sets of paths to find all of the full paths
	@paths = $self->_joinPathsToCenter(\@paths1, \@paths2);
    }

     
    return \@paths;
}

#  method that takes two partial paths nad joins them
#  input : $array1 <- reference to paths for first concept
#          $arrat2 <- reference to paths for second concept
#  output: @paths  <- array containing the combined paths
sub _joinPathsToCenter {
    my $self   = shift;
    my $paths1 = shift;
    my $paths2 = shift;

    my $function = "_joinPathsToCenter";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $paths1) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$paths1.", 4);
    }
  if(!defined $paths2) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$paths2.", 4);
    }

    my $childstring  = $cuifinder->_getChildRelations();
    my $parentstring = $cuifinder->_getParentRelations();
    
    my @shortestpaths = ();
    foreach my $p1 (@{$paths1}) {
	
	#  get the path to the center, the center and the number
	#  of direction changes that existed in the path
	my @array1 = split/\s+/, $p1;
	my $dchange1 = pop @array1;
	my $c1       = pop @array1;
	
	foreach my $p2 (@{$paths2}) {

	    #  now get the paths to the center coming from the other direction, 
	    #  its direction changes and the center
	    my @array2 = split/\s+/, $p2;	    
	    my $dchange2 = pop @array2;
	    my $c2       = $array2[$#array2];
	    
	    #  if the two centers are equal we have path
	    if($c1 eq $c2) { 
		
		#  if undirected make certain that their is at 
		#  most one direction change
		if(!($option_undirected)) { 

		    #  check on basic direction changes
		    my $totalchanges = $dchange1 + $dchange2;
		    if($totalchanges > 1)               { next; } 
		    if($dchange1 > 0 && $dchange2 > 0)  { next; }

		    #  set the path
		    my @rarray2 = reverse @array2;
		    my @path = (@array1, @rarray2);
		    
		    #  check for complicated embedded direction changes
		    my $direction = 0; my $previous = ""; my $cflag = 0; 
		    for my $i (0..($#path-1)) { 
			my $cc1 = $path[$i];
			my $cc2 = $path[$i+1];

			#  get the relationships the concepts
			my $ccr = $cuifinder->_getRelationsBetweenCuis($cc1, $cc2);

			#  determine whether that relation is a 
			#  parent or a child relation
			my $pr = 0; my $cr = 0;
			foreach my $item (@{$ccr}) {
			    $item=~/([A-Z]+) \([A-Za-z0-9\.]+\)/;
			    my $rel = $1; 
			    if($childstring=~/($rel)/)  { $cr++; }
			    if($parentstring=~/($rel)/) { $pr++; }


			    #  determine that the first relationship in the 
			    #  in the path is not a child relation 
			    if($i == 0) { 
				if($childstring=~/($rel)/) { $cflag = 1; }
			    }
			}
		
			#  sometimes there are two directions
			if($cr > 0 && $pr > 0) { 
			    # if this is the case we are just going to move on
			    #  and not worry about right now. There isn't a 
			    #  loop exactly
			}
			else {
			    #  determine if there has been a direction change
			    if($previous ne "") { 
				if( ($previous eq "CHD") && ($pr > 0)) { $direction++; }
				if( ($previous eq "PAR") && ($cr > 0)) { $direction++; }
			    }

			    #  set the previous relation
			    if($pr > 0){ $previous = "PAR"; }
			    if($cr > 0){ $previous = "CHD"; }
			}
		    }

		    #  if the path starts out with a child relation and then 
		    #  moves to a parent we don't want it
		    if($cflag == 1 && $direction >= 1) { next; }

		    #  if there is more than a single direction change 
		    #  we don't want the path
		    if($direction > 1) { next; }

		    #  add the path to the list of shortest paths
		    my $string = join " ", @path;
		    push @shortestpaths, $string;
		}
		else {

		    #  we have one or less changes if the undirectoption
		    #  was not set so we can add the path to the shortest
		    #  path array
		    my @rarray2 = reverse @array2;
		    my @path = (@array1, @rarray2);
		    my $string = join " ", @path;

		    push @shortestpaths, $string;
		}
	    }
	}
    }
     
    return @shortestpaths;
}
    

#  method that finds all the paths from a concept of a specified length
#  input : $start  <- the concept
#          $length <- the length of the path
#  output: @paths  <- array containing the paths
sub _findPathsToCenter {

    my $self    = shift;
    my $start   = shift;
    my $length  = shift;
    my $flag   = shift;
    my $ends   = shift;
    
    my $function = "_findPathsToCenter";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check parameter exists
    if(!defined $start) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$start.", 4);
    }
    
    #  check if valid concept
    if(! ($errorhandler->_validCui($start)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($start) in not valid.", 6);
    }    
    
    #  set the  storage
    my @path_storage= ();

    #  set the count
    my %visited = ();
    
    #  set the stack with the parents because 
    #  we want to start going up inorder to 
    #  have an LCS
    my @directions = ();
    my @relations  = ();
    my @paths      = ();
    
    my $parentstack = $cuifinder->_getParents($start);
    foreach my $element (@{$parentstack}) {
	my @array      = (); 
	push @paths, \@array;
	push @directions, 0;
	push @relations, "PAR";
    }
    
    my $childrenstack = $cuifinder->_getChildren($start);
    my @stack = (@{$parentstack}, @{$childrenstack});
    foreach my $element (@{$childrenstack}) {
	my @array      = (); 
	push @paths, \@array;
	push @directions, 0;
	push @relations, "CHD";
    }
    
    #  now loop through the stack
    while($#stack >= 0) {
	
	my $concept    = pop @stack;
	my $path       = pop @paths;
	my $direction  = pop @directions;
	my $relation   = pop @relations;
	

        #  set up the new path
	my @intermediate = @{$path};
	my $series = join " ", @intermediate;
	push @intermediate, $concept;
	my $distance = $#intermediate + 1;

	#  check if the distance is greater than what we 
	#  already have - if so we are done
	if($distance > $length) { 
	    @stack = (); 
	    next;
	}

	#  check that the concept is not one of the forbidden concepts
	if($cuifinder->_forbiddenConcept($concept)) { next; }	

        #  check if concept has been visited already through that path
	my $v = "$concept : $series";
	if(exists $visited{$v}) { next; }	
	else { $visited{$v}++; }

        #  check if we have a path of approrpiate length
	#  if so add it to the storage
	if($distance == $length) { 
	    my $element = $intermediate[$#intermediate];
	    
	    push @intermediate, $direction;

	    if($flag == 1) {
		${$ends}{$element}++;
		push @path_storage, \@intermediate;
	    }
	    elsif($flag == 2) { 
		if(exists ${$ends}{$element}) {
		    push @path_storage, \@intermediate;
		}
		
	    }
	    next;
	}
	
        #  print information into the file if debugpath option is set
	if($option_debugpath) { 
	    my $d = $#intermediate+1;
	    print DEBUG_FILE "$concept\t$d\t@intermediate\n"; 
	}
	

	#  we are going to start with the parents here; the code 
	#  for both is similar except for the relation/direction
	#  which is why I have the seperate right now - currently 
	
	#  if the previous direction was a child we have a change in direction
	my $dchange = $direction;
      
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation eq "CHD") { $dchange = $direction + 1; }
	}

	#  if we have not had more than a single direction change
	if($dchange < 2) {
	    #  search through the parents
	    my $parents  = $cuifinder->_getParents($concept);		
	    foreach my $parent (@{$parents}) {
		
		#  check if concept is already in the path
		if($series=~/$parent/)  { next; }
		if($parent eq $concept) { next; }
		
		#  if it isn't add it to the stack
		unshift @stack, $parent;
		unshift @paths, \@intermediate;
		unshift @relations, "PAR";
		unshift @directions, $dchange;
	    }
	}
	
	#  now with the chilcren if the previous direction was a parent we have
	#  have to change the direction
	$dchange = $direction;
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation eq "PAR") { $dchange = $direction + 1; }
	}

	#  if we have not had more than a single direction change
	if($dchange < 2) {
	    #  now search through the children
	    my $children = $cuifinder->_getChildren($concept);
	    foreach my $child (@{$children}) {
		
		#  check if child cui has already in the path
		if($series=~/$child/)  { next; }
		if($child eq $concept) { next; }

		#  if it isn't add it to the stack
		unshift @stack, $child;
		unshift @paths, \@intermediate;
		unshift @relations, "CHD";
		unshift @directions, $dchange;
	    }
	}
    }
        #  set the return
    my @return_paths = ();
    foreach my $p (@path_storage) {
	unshift @{$p}, $start;
	my $string = join " " , @{$p};
	push @return_paths, $string;
    }

    return @return_paths;
}
    

#  method that finds the minimum depth
#  input : $concept  <- the first concept
#  output: $int      <- the minimum depth
sub _findMinimumDepthInRealTime {

    my $self = shift;
    my $concept = shift;
    
    my $function = "_findMinimumDepthInRealTime";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }    
       
    #  set the count
    my %visited = ();
    
    #  set the stack with the roots children
    my @paths      = ();
    my $rstack = $cuifinder->_getChildren($root);
    my @stack  = @{$rstack};

    foreach my $element (@stack) {
	my @array      = (); 
	push @paths, \@array;
    }
    
    #  now loop through the stack
    while($#stack >= 0) {
	
	my $cui    = pop @stack;
	my $path   = pop @paths;
	
        #  set up the new path
	my @intermediate = @{$path};
	my $series = join " ", @intermediate;
	push @intermediate, $cui;
	my $distance = $#intermediate;

	#  check that the concept is not one of the forbidden concepts
	if($cuifinder->_forbiddenConcept($cui)) { next; }	

        #  check if concept has been visited already through that path
	if(exists $visited{$cui}) { next; }	
	else { $visited{$cui}++; }
	
        #  check if it is our concept2
	if($cui eq $concept) { 
	    my $path_length = $distance + 2;
	    return $path_length;
	}
	
	#  now search through the children
	my $children = $cuifinder->_getChildren($cui);
	foreach my $child (@{$children}) {
	    #  check if child cui has already in the path
	    if($series=~/$child/)  { next; }
	    if($child eq $cui) { next; }

	    #  if it isn't add it to the stack
	    unshift @stack, $child;
	    unshift @paths, \@intermediate;
	}
    }
    #  no path was found return -1
    return -1;
}


#  method that finds the maximum depth
#  input : $concept  <- the first concept
#  output: $int      <- the minimum depth
sub _findMaximumDepthInRealTime {

    my $self    = shift;
    my $concept = shift;

    return () if(!defined $self || !ref $self);

    my $function = "_findMaximumDepthInRealtime($concept)";
    &_debug($function);
    
    #  set the  storage
    my $maximum_path_length = -1;

  #  set the stack
    my @stack = ();
    push @stack, $concept;

    #  set the count
    my %visited = ();

    #  set the paths
    my @paths = ();
    my @empty = ();
    push @paths, \@empty;

    #  now loop through the stack
    while($#stack >= 0) {
	
	my $cui = $stack[$#stack];
	my $path    = $paths[$#paths];

	#  set up the new path
	my @intermediate = @{$path};
	my $series = join " ", @intermediate;
	push @intermediate, $cui;
	
        #  print information into the file if debugpath option is set
	if($option_debugpath) { 
	    my $d = $#intermediate+1;
	    print DEBUG_FILE "$cui\t$d\t@intermediate\n"; 
	}
        
	#  check that the cui is not one of the forbidden concepts
	if($cuifinder->_forbiddenConcept($cui)) { 
	    pop @stack; pop @paths;
	    next;
	}

	#  check if concept has been visited already
	if(exists $visited{$cui}{$series}) { 
	    pop @stack; pop @paths;
	    next;
	}
	else { $visited{$cui}{$series}++; }
	
	#  if the concept is the umls root - we are done
	if($cui eq $root) { 
	    my $length = $#intermediate + 1;
	    if($length > $maximum_path_length) { 
		$maximum_path_length = $length;
	    }
	    next;
	}
	
	#  get all the parents
	my $parents = $cuifinder->_getParents($cui);

	#  if there are no children we are finished with this concept
	if($#{$parents} < 0) {
	    pop @stack; pop @paths;
	    next;
	}

	#  search through the children
	my $stackflag = 0;
	foreach my $parent (@{$parents}) {
	
	    #  check if concept has already in the path
	    if($series=~/$parent/)  { next; }
	    if($cui eq $parent) { next; }

	    #  if it isn't continue on with the depth first search
	    push @stack, $parent;
	    push @paths, \@intermediate;
	    $stackflag++;
	}
	
	#  check to make certain there were actually children
	if($stackflag == 0) { pop @stack; pop @paths; }
    }

    return $maximum_path_length;
}

#  method that finds all the ancestors of a given concept
#  input : $concept1  <- the concept
#  output: %ancestors <- hash containing the ancestors
sub _findAncestors { 
    my $self = shift;
    my $concept = shift; 
    
    my $function = "_findAncestors";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    my @paths = $self->_pathsToRoot($concept);
    
    my %ancestors = (); 
    foreach my $path (@paths) { 
	foreach my $string (@{$path}) { 
	    my @cuis = split/\s+/, $string; 
	    foreach my $cui (@cuis) { 
		$ancestors{$cui} = 1; 
	    }
	}
    }
    
    return \%ancestors; 

}
#  method that finds the closeness centrality of a concept 
#  input : $concept1  <- the concept
#  output: $double    <- the closeness
sub _findClosenessCentrality { 
    my $self = shift;
    my $concept = shift; 
    
    my $function = "_findClosenessCentrality";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the cuis associated with the config file
    my $hashref= $cuifinder->_getCuiList(); 

    #  calculate the length of the shortest path for each cui
    my $sum = 0; 
    foreach my $cui (sort keys %{$hashref}) {
	if($cui eq $concept) { next; } 
	my $d = $self->_findShortestPathLength($concept, $cui); 
	if($d > 0) { 
	    $sum += $d; 
	}
    }
    
    #  return closeness
    return (1/$sum); 
}    

#  method that finds the length of the shortest path
#  input : $concept1  <- the first concept
#          $concept2  <- the second concept
#  output: $int       <- the length of the shortest path between them
sub _findShortestPathLength {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathLength";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    if($option_realtime) {

	#my $length = $self->_findShortestPathLengthInCache($concept1, $concept2);
	#if(defined $length) { return $length; }
	#else { 
	my $length = $self->_findShortestPathLengthInRealTime($concept1, $concept2);
	    #if(!$option_undirected) { 
		#$self->_storeShortestPathLengthInCache($concept1, $concept2, $length);
	    #}
	return $length;
        #}
    }
    else {
	my $paths = $self->_findShortestPathThroughLCS($concept1, $concept2);
	my $path = shift @{$paths};
	if(defined $path) { 
	    my @cuis = split/\s+/, $path;
	    my $length = $#cuis + 1;
	    return $length;
	}
	else { return -1; }
    }
}


sub _storeShortestPathLengthInCache
{
    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    my $length   = shift;

    my $function = "_storeShortestPathLengthInCache";
    &_debug($function);
         
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the info table name
    my $cacheTableName = $cuifinder->_getCacheTableName();
    
    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  store the length in the cache table
    my $arrRef = $sdb->do("INSERT INTO $cacheTableName (CUI1, CUI2, LENGTH) VALUES ('$concept1', '$concept2', '$length')");
    $errorhandler->_checkDbError($pkg, $function, $sdb);
 }

sub _findShortestPathLengthInCache
{
    my $self     = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathLengthInCache";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    

    #  get the info table name
    my $cacheTableName = $cuifinder->_getCacheTableName();
    
    #  set the index DB handler
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  get length from the cache table if it exists
    my $arrRef = $sdb->selectcol_arrayref("select LENGTH from $cacheTableName where CUI1=\'$concept1\' and CUI2=\'$concept2\'");
    $errorhandler->_checkDbError($pkg, $function, $sdb);

    #  get the depth from the array
    my $length = shift @{$arrRef};
    
    return $length;
}

#  method that finds the length of the shortest path
#  input : $concept1  <- the first concept
#          $concept2  <- the second concept
#  output: $length    <- the length of the shortest path between them
sub _findShortestPathLengthInRealTime {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathLengthInRealTime";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    
    
    #  we need to check this in both directions because the BFS
    #  the direction matters and with the undirected option
    #  we always want to go up and the problem arrises in the 
    #  cases in which we continue down in a straight line such 
    #  that CUI1 is the LCS. Maybe there is a better way to 
    #  do this but I am not certain quite yet
    #my $l1 = $self->_findShortestPathLengthInRealTimeBFS($concept1, $concept2, -1);

    #  now swap
    #my $l2 = $self->_findShortestPathLengthInRealTimeBFS($concept2, $concept1, $l1);
    
    #  return the other if it is -1
    #if($l1 < 0) { return $l2; }
    #if($l2 < 0) { return $l1; }
    
    #  return the lowest
    #return $l1 < $l2 ? $l1 : $l2;

    my $length = $self->_findShortestPathLengthInRealTimeBFS2($concept1, $concept2);

    return $length;
}
	

#  method that finds the length of the shortest path
#  input : $concept1  <- the first concept
#          $concept2  <- the second concept
#  output: $length    <- the length of the shortest path between them
sub _findShortestPathLengthInRealTimeBFS2 {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findShortestPathLengthInRealTimeBFS2($concept1, $concept2)";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  base case
    if($concept1 eq $concept2) { return 2; }

    #  set the count
    my %visited1 = ();    my %visited2 = ();
    
    #  set the stack
    my $rstack1 = $cuifinder->_getParents($concept1);
    my $rstack2 = $cuifinder->_getParents($concept2);
    my @stack1 = @{$rstack1}; my @stack2 = @{$rstack2};

    my @directions1  = ();    my @directions2  = ();
    my @relations1   = ();    my @relations2   = ();
    my @paths1       = ();    my @paths2       = ();
    my $path_length1 = -1;    my $path_length2 = -1;

    #  get the parents 
    foreach my $element (@stack1) {
	my @array1      = (); 
	push @paths1, \@array1;
	push @directions1, 0;
	push @relations1, "PAR";
    }
    foreach my $element (@stack2) {
	my @array2      = (); 
	push @paths2, \@array2;
	push @directions2, 0;
	push @relations2, "PAR";
    }

    #  now loop through the stack
    while($#stack1 >= 0 || $#stack2 >= 0) {
	
	my $c1            = "";	my $c2            = "";
	my $path1         = "";	my $path2         = "";
	my $direction1    = "";	my $direction2    = "";
	my $relation1     = "";	my $relation2     = "";
	my @intermediate1 = (); my @intermediate2 = ();
	my $series1       = "";	my $series2       = "";
	my $distance1     = -1;	my $distance2     = -1;
	my $cui1flag      = 0;  my $cui2flag      = 0;

	if($#stack1 >=0)  {
	    $c1          = pop @stack1;
	    $path1       = pop @paths1;
	    $direction1  = pop @directions1;
	    $relation1   = pop @relations1;

	    @intermediate1 = @{$path1};
	    $series1 = join " ", @intermediate1;
	    push @intermediate1, $c1;
	    $distance1 = $#intermediate1;
	    $cui1flag++;
	}
	
	if($#stack2 >=0)  {
	    $c2          = pop @stack2;
	    $path2       = pop @paths2;
	    $direction2  = pop @directions2;
	    $relation2   = pop @relations2;
	    
	    @intermediate2 = @{$path2};
	    $series2 = join " ", @intermediate2;
	    push @intermediate2, $c2;
	    $distance2 = $#intermediate2;
	    $cui2flag++;
	}

	#  check if it is our concept2
	if($c1 eq $concept2) { 
	    $path_length1 = $distance1 + 2;
	    if($#stack2 < 0) { return $path_length1; }
	}

	
	#  check if it is our concept2
	if($c2 eq $concept1) { 
	    $path_length2 = $distance2 + 2;
	    if($#stack1 < 0) { return $path_length2; }
	}

	#  if both paths have been set return the shortest
	if($path_length1 > -1 && $path_length2 > -1) { 
	    return $path_length1 < $path_length2 ? $path_length1 : $path_length2; 
	}

	#  if path length1 is set and is distance2 is greater then what
	#  ever path we find for distance2 is going to be more than 
	#  for pathlength1 so return (this also works for pathlength2)
	if($path_length1 > -1 && $path_length1 <= ($distance2+2)) { return $path_length1; }
	if($path_length2 > -1 && $path_length2 <= ($distance1+2)) { return $path_length2; }
	

	#  check if concept has been visited already through that path
	my $flag1 = 0; my $flag2 = 0;
	if(exists $visited1{$c1}) { $flag1++; }	
	else { $visited1{$c1}++; }

	if(exists $visited2{$c2}) { $flag2++; }	
	else { $visited2{$c2}++; }

	#  set the flags if nothing exists
	if($cui1flag == 0) { $flag1++; }
	if($cui2flag == 0) { $flag2++; }

	#  check that the concept is not one of the forbidden concepts
	if($cui1flag > 0 && $cuifinder->_forbiddenConcept($c1)) { $flag1++; }
	if($cui2flag > 0 && $cuifinder->_forbiddenConcept($c2)) { $flag2++; }

	#  if both concepts have been flagged - next
	if($flag1 > 0 && $flag2 > 0) { next; }

	#  if the previous direction was a child we have a change in direction
	my $dchange1 = $direction1;
	my $dchange2 = $direction2;
	
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation1 eq "CHD") { $dchange1 = $direction1 + 1; }
	    if($relation2 eq "CHD") { $dchange2 = $direction2 + 1; }
	}
	
	#  if we have not had more than a single direction change
	my $parents1; my $parents2;
	if($flag1 == 0 && $dchange1 < 2)  {
	    $parents1  = $cuifinder->_getParents($c1);		
	}
	if($flag2 == 0 && $dchange2 < 2)  {
	    $parents2  = $cuifinder->_getParents($c2);		
	}
	
	foreach my $parent1 (@{$parents1}) {
	    #  check if concept has already in the path
	    if($series1=~/$parent1/) { next; }
	    if($parent1 eq $c1)      { next; }
	    unshift @stack1, $parent1;
	    unshift @paths1, \@intermediate1;
	    unshift @relations1, "PAR";
	    unshift @directions1, $dchange1;
	}

	foreach my $parent2 (@{$parents2}) {
	    #  check if concept has already in the path
	    if($series2=~/$parent2/) { next; }
	    if($parent2 eq $c2)      { next; }

	    unshift @stack2, $parent2;
	    unshift @paths2, \@intermediate2;
	    unshift @relations2, "PAR";
	    unshift @directions2, $dchange2;
	}
	
	
	#  now with the chilcren if the previous direction was a parent we have
	#  have to change the direction
	$dchange1 = $direction1;
	$dchange2 = $direction2;

	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation1 eq "PAR") { $dchange1 = $direction1 + 1; }
	    if($relation2 eq "PAR") { $dchange2 = $direction2 + 1; }
	}

	

	#  if we have not had more than a single direction change
	#  now search through the children
	my $children1 = undef; my $children2 = undef;
	if($flag1 == 0 && $dchange1 < 2) {
	    $children1 = $cuifinder->_getChildren($c1);
	}

	if($flag2 == 0 && $dchange2 < 2) {
	    $children2 = $cuifinder->_getChildren($c2);
	}
	
	foreach my $child1 (@{$children1}) {
	    #  check if child cui has already in the path
	    if($series1=~/$child1/)  { next; }
	    if($child1 eq $c1) { next; }
	    
	    #  if not continue 
	    unshift @stack1, $child1;
	    unshift @paths1, \@intermediate1;
	    unshift @relations1, "CHD";
	    unshift @directions1, $dchange1;
	}

	foreach my $child2 (@{$children2}) {
	    #  check if child cui has already in the path
	    if($series2=~/$child2/)  { next; }
	    if($child2 eq $c2) { next; }
	    
	    #  if not continue 
	    unshift @stack2, $child2;
	    unshift @paths2, \@intermediate2;
	    unshift @relations2, "CHD";
	    unshift @directions2, $dchange2;
	}
    }
    #  no path was found return -1
    return -1;
}


#  method that finds the length of the shortest path
#  input : $concept1  <- the first concept
#          $concept2  <- the second concept
#  output: $length    <- the length of the shortest path between them
sub _findShortestPathLengthInRealTimeBFS {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    my $length   = shift;
    
    my $function = "_findShortestPathLengthInRealTimeBFS($concept1, $concept2, $length)";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the count
    my %visited = ();
    
    #  set the stack
    my $rstack     = $cuifinder->_getParents($concept1);
    my @stack      = @{$rstack};
    my @directions = ();
    my @relations  = ();
    my @paths      = ();
    
    #  get the parents 
    foreach my $element (@stack) {
	my @array      = (); 
	push @paths, \@array;
	push @directions, 0;
	push @relations, "PAR";
    }
   
    #  now loop through the stack
    while($#stack >= 0) {
	
	my $concept    = pop @stack;
	my $path       = pop @paths;
	my $direction  = pop @directions;
	my $relation   = pop @relations;
	
	#  set up the new path
	my @intermediate = @{$path};
	my $series = join " ", @intermediate;
	push @intermediate, $concept;
	my $distance = $#intermediate;

	#  if we are going in the other direction and we
	#  have already found a shorter path the other way
	if( ($length) > 0 && ( ($distance+2) >= $length) ) {
	    return $length; 
	}

	#  check if it is our concept2
	if($concept eq $concept2) { 
	    my $path_length = $distance + 2;
	    return $path_length;
	}

	#  check if concept has been visited already through that path
	if(exists $visited{$concept}) { next; }	
	else { $visited{$concept}++; }

	#  check that the concept is not one of the forbidden concepts
	if($cuifinder->_forbiddenConcept($concept)) { next; }	
	
	#  print information into the file if debugpath option is set
	if($option_debugpath) { 
	    my $d = $#intermediate+1;
	    print DEBUG_FILE "$concept\t$d\t@intermediate\n"; 
	}
	
	#  if the previous direction was a child we have a change in direction
	my $dchange = $direction;
	
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation eq "CHD") { $dchange = $direction + 1; }
	}
	
	#  if we have not had more than a single direction change
	if($dchange < 2) {
	    #  search through the parents
	    my $parents  = $cuifinder->_getParents($concept);		
	    foreach my $parent (@{$parents}) {
		#  check if concept has already in the path
		if($series=~/$parent/) { next; }
		if($parent eq $concept) { next; }
		unshift @stack, $parent;
		unshift @paths, \@intermediate;
		unshift @relations, "PAR";
		unshift @directions, $dchange;
	    }
	}
	
	#  now with the chilcren if the previous direction was a parent we have
	#  have to change the direction
	$dchange = $direction;
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation eq "PAR") { $dchange = $direction + 1; }
	}
	
	#  if we have not had more than a single direction change
	if($dchange < 2) {
	    #  now search through the children
	    my $children = $cuifinder->_getChildren($concept);
	    foreach my $child (@{$children}) {
		
		#  check if child cui has already in the path
		if($series=~/$child/)  { next; }
		if($child eq $concept) { next; }
		
		#  if not continue 
		unshift @stack, $child;
		unshift @paths, \@intermediate;
		unshift @relations, "CHD";
		unshift @directions, $dchange;
	    }
	}
    }
	
    #  no path was found return -1
    return -1;
}


#  this function finds the shortest path between 
#  two concepts and returns the path. in the process 
#  it determines the least common subsumer for that 
#  path so it returns both
#  input : $concept1 <- string containing the first cui
#          $concept2 <- string containing the second
#  output: $hash     <- reference to a hash containing the 
#                       lcs as the key and the path as the
#                       value
sub _shortestPath {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $function = "_shortestPath";
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
	$errorhandler->_error($pkg, $function, "Concept ($concept1) in not valid.", 6);
    }    
    if(! ($errorhandler->_validCui($concept2)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept2) in not valid.", 6);
    }    

    # Get the paths to root for each ofhte concepts
    my $lTrees = $self->_pathsToRoot($concept1);

    my $rTrees = $self->_pathsToRoot($concept2);
   
    # Find the shortest path in these trees.
    my %lcsLengths = ();
    my %lcsPaths   = ();
    my $lcs        = "";
    foreach my $lTree (@{$lTrees}) {
	foreach my $rTree (@{$rTrees}) {
	    $lcs = $self->_getLCSfromTrees($lTree, $rTree);
	    if(defined $lcs) {
		
		my $lCount  = 0;
		my $rCount  = 0;
		my $length  = 0;
		my $concept = "";
		
		my @lArray  = ();
		my @rArray  = ();
		
		my @lTreeArray = split/\s+/, $lTree;
		my @rTreeArray = split/\s+/, $rTree;
		
		foreach $concept (reverse @lTreeArray) {
		    $lCount++;
		    push @lArray, $concept;
		    last if($concept eq $lcs);

		}
		foreach $concept (reverse @rTreeArray) {
		    $rCount++;
		    last if($concept eq $lcs);
		    push @rArray, $concept;
		    
		}

		#  length of the path
		if(exists $lcsLengths{$lcs}) {
		    if($lcsLengths{$lcs} >= ($rCount + $lCount - 1)) {
			$lcsLengths{$lcs} = $rCount + $lCount - 1;
			my @fullpath = (@lArray, (reverse @rArray));
			push @{$lcsPaths{$lcs}}, \@fullpath;
		    }
		}
		else {
		    $lcsLengths{$lcs} = $rCount + $lCount - 1;
		    my @fullpath = (@lArray, (reverse @rArray));
		    push @{$lcsPaths{$lcs}}, \@fullpath;
		}
	    }
	}
    }
    
    # If no paths exist 
    if(!scalar(keys(%lcsPaths))) {
	return undef;
    }

    #  get the lcses and their associated path(s)
    my %rhash    = ();
    my $prev_len = -1;
    foreach my $lcs (sort {$lcsLengths{$a} <=> $lcsLengths{$b}} keys(%lcsLengths)) {
	if( ($prev_len == -1) or ($prev_len == $lcsLengths{$lcs}) ) {
	    foreach my $pathref (@{$lcsPaths{$lcs}}) { 
		if( ($#{$pathref}+1) == $lcsLengths{$lcs}) {
		    my $path = join " ", @{$pathref};
		    $rhash{$path} = $lcs;
		}
	    }
	}
	else { last; }
	$prev_len = $lcsLengths{$lcs};
    }
    
    #  return a reference to the hash containing the lcses and their path(s)
    return \%rhash;
}


#  method that finds the length of the shortest path
#  input : $concept1  <- the first concept
#          $concept2  <- the second concept
#  output: $int       <- number cuis closer to concept1 than concept2
sub _findNumberOfCloserConcepts {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_findNumberOfCloserConcepts($concept1, $concept2)";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    if($concept1 eq $concept2) { return 0; }

    my %closerConceptHash = ();

    #  set the count
    my %visited1 = ();    my %visited2 = ();
    
    #  set the stack
    my $rstack1 = $cuifinder->_getParents($concept1);
    my $rstack2 = $cuifinder->_getParents($concept2);
    my @stack1 = @{$rstack1}; my @stack2 = @{$rstack2};

    my @directions1  = ();    my @directions2  = ();
    my @relations1   = ();    my @relations2   = ();
    my @paths1       = ();    my @paths2       = ();
    my $path_length1 = -1;    my $path_length2 = -1;

    #  get the parents 
    foreach my $element (@stack1) {
	my @array1      = (); 
	push @paths1, \@array1;
	push @directions1, 0;
	push @relations1, "PAR";
    }
    foreach my $element (@stack2) {
	my @array2      = (); 
	push @paths2, \@array2;
	push @directions2, 0;
	push @relations2, "PAR";
    }
   
    #  now loop through the stack
    while($#stack1 >= 0 || $#stack2 >= 0) {
	
	my $c1            = "";	my $c2            = "";
	my $path1         = "";	my $path2         = "";
	my $direction1    = "";	my $direction2    = "";
	my $relation1     = "";	my $relation2     = "";
	my @intermediate1 = (); my @intermediate2 = ();
	my $series1       = "";	my $series2       = "";
	my $distance1     = -1;	my $distance2     = -1;
	my $cui1flag      = 0;  my $cui2flag      = 0;

	if($#stack1 >=0)  {
	    $c1          = pop @stack1;
	    $path1       = pop @paths1;
	    $direction1  = pop @directions1;
	    $relation1   = pop @relations1;

	    @intermediate1 = @{$path1};
	    $series1 = join " ", @intermediate1;
	    push @intermediate1, $c1;
	    $distance1 = $#intermediate1;
	    $cui1flag++;
	}
	
	if($#stack2 >=0)  {
	    $c2          = pop @stack2;
	    $path2       = pop @paths2;
	    $direction2  = pop @directions2;
	    $relation2   = pop @relations2;
	    
	    @intermediate2 = @{$path2};
	    $series2 = join " ", @intermediate2;
	    push @intermediate2, $c2;
	    $distance2 = $#intermediate2;
	    $cui2flag++;
	}
	

	
	#  check if it is our concept2
	if($c1 eq $concept2) { 
	    $path_length1 = $distance1 + 2;
	    if($#stack2 < 0) { last; }
	}

	
	#  check if it is our concept2
	if($c2 eq $concept1) { 
	    $path_length2 = $distance2 + 2;
	    if($#stack1 < 0) { last; }
	}

	#  if both paths have been set return the shortest
	if($path_length1 > -1 && $path_length2 > -1) { last; }

	#  if path length1 is set and is distance2 is greater then what
	#  ever path we find for distance2 is going to be more than 
	#  for pathlength1 so return (this also works for pathlength2)
	if($path_length1 > -1 && $path_length1 <= ($distance2+2)) { last; }
	if($path_length2 > -1 && $path_length2 <= ($distance1+2)) { last; }
	

	#  check if concept has been visited already through that path
	my $flag1 = 0; my $flag2 = 0;
	if(exists $visited1{$c1}) { $flag1++; }	
	else { $visited1{$c1}++; }

	if(exists $visited2{$c2}) { $flag2++; }	
	else { $visited2{$c2}++; }

	#  set the flags if nothing exists
	if($cui1flag == 0) { $flag1++; }
	if($cui2flag == 0) { $flag2++; }

	#  check that the concept is not one of the forbidden concepts
	if($cui1flag > 0 && $cuifinder->_forbiddenConcept($c1)) { $flag1++; }
	if($cui2flag > 0 && $cuifinder->_forbiddenConcept($c2)) { $flag2++; }

	#  if both concepts have been flagged - next
	if($flag1 > 0 && $flag2 > 0) { next; }

	#  add concepts to the closest hash if closer
	if($flag1 <= 0) { 
	    if(! (exists $closerConceptHash{$c1}) ) {
		$closerConceptHash{$c1} = $distance1 + 2; 
	    }
	}
	if($flag2 <= 0) { 
	    if(! (exists $closerConceptHash{$c2}) ) {
		$closerConceptHash{$c2} = $distance2 + 2; 
	    }
	}

	#  if the previous direction was a child we have a change in direction
	my $dchange1 = $direction1;
	my $dchange2 = $direction2;
	
	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation1 eq "CHD") { $dchange1 = $direction1 + 1; }
	    if($relation2 eq "CHD") { $dchange2 = $direction2 + 1; }
	}
	
	#  if we have not had more than a single direction change
	my $parents1 = undef; my $parents2 = undef;
	if($flag1 == 0 && $dchange1 < 2)  {
	    $parents1  = $cuifinder->_getParents($c1);		
	}
	if($flag2 == 0 && $dchange2 < 2)  {
	    $parents2  = $cuifinder->_getParents($c2);		
	}
	
	foreach my $parent1 (@{$parents1}) {
	    #  check if concept has already in the path
	    if($series1=~/$parent1/) { next; }
	    if($parent1 eq $c1)      { next; }
	    unshift@stack1, $parent1;
	    unshift @paths1, \@intermediate1;
	    unshift @relations1, "PAR";
	    unshift @directions1, $dchange1;
	}

	foreach my $parent2 (@{$parents2}) {
	    #  check if concept has already in the path
	    if($series2=~/$parent2/) { next; }
	    if($parent2 eq $c2)      { next; }

	    unshift @stack2, $parent2;
	    unshift @paths2, \@intermediate2;
	    unshift @relations2, "PAR";
	    unshift @directions2, $dchange2;
	}
	
	
	#  now with the chilcren if the previous direction was a parent we have
	#  have to change the direction
	$dchange1 = $direction1;
	$dchange2 = $direction2;

	#  if the undirected option is set the dchange doesn't matter
	#  otherwise we need to check
	if(!$option_undirected) { 
	    if($relation1 eq "PAR") { $dchange1 = $direction1 + 1; }
	    if($relation2 eq "PAR") { $dchange2 = $direction2 + 1; }
	}

	

	#  if we have not had more than a single direction change
	#  now search through the children
	my $children1 = undef; my $children2 = undef;
	if($flag1 == 0 && $dchange1 < 2) {
	    $children1 = $cuifinder->_getChildren($c1);
	}

	if($flag2 == 0 && $dchange2 < 2) {
	    $children2 = $cuifinder->_getChildren($c2);
	}
	
	foreach my $child1 (@{$children1}) {
	    #  check if child cui has already in the path
	    if($series1=~/$child1/)  { next; }
	    if($child1 eq $c1) { next; }
	    
	    #  if not continue 
	    unshift @stack1, $child1;
	    unshift @paths1, \@intermediate1;
	    unshift @relations1, "CHD";
	    unshift @directions1, $dchange1;
	}

	foreach my $child2 (@{$children2}) {
	    #  check if child cui has already in the path
	    if($series2=~/$child2/)  { next; }
	    if($child2 eq $c2) { next; }
	    
	    #  if not continue 
	    unshift @stack2, $child2;
	    unshift @paths2, \@intermediate2;
	    unshift @relations2, "CHD";
	    unshift @directions2, $dchange2;
	}
    }

    if($path_length1 < 0 && $path_length2 < 0) { return -1; }
    
    my $length = $path_length1 < $path_length2 ? $path_length1 : $path_length2;
    
    if($path_length1 < 0) { $length = $path_length2; }
    if($path_length2 < 0) { $length = $path_length1; }

    my $counter = 0;
    foreach my $cui (sort keys %closerConceptHash) { 
	if($closerConceptHash{$cui} < $length) { 
	    $counter++; 
	}
    }

    #  no path was found return -1
    return $counter;
}

sub _findDescendants { 
    my $self = shift; 
    my $concept = shift; 
    
    my $function = "_findDescendants";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    #  check parameter exists
    if(!defined $concept) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$concept1.", 4);
    }
    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
	$errorhandler->_error($pkg, $function, "Concept ($concept) in not valid.", 6);
    }    
    
    my %decendents = (); 
    
    my $children = $cuifinder->_getChildren($concept); 

    foreach my $child (@{$children}) {
	my @array = (); 
	push @array, $root;
	my $path  = \@array;

	&_descendentSearch($child, $path, \%decendents, *F);
	
    }
    
    return \%decendents; 
}

sub _descendentSearch
{
    my $concept = shift;
    my $array   = shift;
    my $decendents = shift; 
    local(*F)   = shift;

    #  set the new path
    my @path = @{$array};
    push @path, $concept;
    
    my $series = join " ", @path;
    
    #  print information into the file if debugpath option is set
    if($option_debugpath) { print F "$concept\t$series\n"; }
    
    #  get all the children
    my $children = $cuifinder->_getChildren($concept);

    #  search through the children
    foreach my $child (@{$children}) {
	
	#  check if child cui has already in the path
	my $flag = 0;
	foreach my $cui (@path) {
	    if($cui eq $child) { 
		$flag = 1; 
	    }
	}

	#  if it isn't continue on with the depth first search
	if($flag == 0) {
	    #  check that the concept is not a forbidden concept
	    if($cuifinder->_forbiddenConcept($child) == 1) { return; }

	    #  store the decendents
	    $decendents->{$child} = 1; 
	
	    &_descendentSearch($child, \@path, $decendents, *F);
	}
    }
}

1;

__END__

=head1 NAME

UMLS::Interface::PathFinder - provides the path information 
for the modules in the UMLS::Interface package.

=head1 DESCRIPTION

This package provides the path information about the CUIs in 
the UMLS for the modules in the UMLS::Interface package.

For more information please see the UMLS::Interface.pm 
documentation. 

=head1 SYNOPSIS

 use UMLS::Interface::CuiFinder;
 use UMLS::Interface::PathFinder;
 use UMLS::Interface::ErrorHandler;

 %params = ();

 $params{'realtime'} = 1;

 $cuifinder = UMLS::Interface::CuiFinder->new(\%params);
 die "Unable to create UMLS::Interface::CuiFinder object.\n" if(!$cuifinder);

 $pathfinder = UMLS::Interface::PathFinder->new(\%params, $cuifinder); 
 die "Unable to create UMLS::Interface::PathFinder object.\n" if(!$pathfinder);

 $concept = "C0037303";

 $depth = $pathfinder->_depth();
 print "The depth of the taxonomy is $depth\n";

 $array = $pathfinder->_pathsToRoot($concept);
 print "The paths from $concept to root: \n";
 foreach my $p (@{$array}) { 
    print "  => $p\n";
 }

 $mindepth = $pathfinder->_findMinimumDepth($concept);
 $maxdepth = $pathfinder->_findMaximumDepth($concept);
 print "The minimum depth of $concept is $mindepth\n";
 print "The maximum depth of $concept is $maxdepth\n";


 $concept1 = "C0037303"; $concept2 = "C0018563";

 $length = $pathfinder->_findShortestPathLength($concept1, $concept2);
 print "The length of the shortest path between $concept1 and $concept2 is $length\n";

 $array = $pathfinder->_findLeastCommonSubsumer($concept1, $concept2);
 print "The LCS(es) between $concept1 and $concept2 are: \n";
 foreach my $lcs (@{$array}) { 
    print "  => $lcs \n";
 }
 
 $array  = $pathfinder->_findShortestPath($concept1, $concept2);
 print "The shortest paths between $concept1 and $concept2 are:\n";
 foreach my $path (@{$array}) { 
    print "  => $path\n";
 }

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
