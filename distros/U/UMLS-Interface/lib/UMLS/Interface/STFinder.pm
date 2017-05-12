# UMLS::Interface::STFinder
# (Last Updated $Id: STFinder.pm,v 1.5 2011/05/12 17:21:24 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2010,
#
# Bridget T. McInnes, University of Minnesota Twin Cities
# bthomson at cs.umn.edu
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

package UMLS::Interface::STFinder;

use Fcntl;
use strict;
use warnings;
use bytes;

my $pkg = "UMLS::Interface::STFinder";

my $debug = 0;

my $root = "T000";

my $stN       = 0;
my $smooth    = 0;

my $option_verbose     = 0;
my $option_debugpath   = 0;
my $option_t           = 0;

my %children         = ();
my %parents          = ();
my %propagationFreq  = ();
my %propagationHash  = ();

my %maxDepth         = ();
my %minDepth         = ();

my $errorhandler = "";
my $cuifinder    = "";

local(*DEBUG_FILE);

# UMLS-specific stuff ends ----------

# -------------------- Class methods start here --------------------

#  method to create a new UMLS::Interface::STFinder object
sub new {

    my $self = {};
    my $className = shift;
    my $params    = shift;
    my $handler   = shift;

    my $function = "new";

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

    #  set up the options
    $self->_setOptions($params);
    
    #  get the umls database from CuiFinder
    my $db = $cuifinder->_getDB();
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }
    $self->{'db'} = $db;

    #  load the semantic network
    $self->_loadSemanticNetwork();

    return $self;
}


#  returns the information content (IC) of a semantic type
#  input : $semantic type <- string containing a semantic type
#  output: $double        <- double containing its IC
sub _getStIC
{
    my $self     = shift;
    my $st       = shift;

    my $function = "_getIC";
    &_debug($function);

     #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check st was obtained
    if(!$st) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }

    #  check if valid semantic type
    if(! ($errorhandler->_validTui($st)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($st) in not valid.", 6);
    }

    my $prob = $propagationHash{$st};

    if(!defined $prob) { return 0; }

    my $ic = 0;
    if($prob > 0 and $prob < 1) { $ic = -1 * (log($prob) / log(10)); }    
    return $ic;
}


#  returns the probability of the semantic type
#  input : $semantic type <- string containing a semantic type
#  output: $double        <- double containing its probability
sub _getStProbability
{
    my $self   = shift;
    my $st     = shift;

    my $function = "_getStProbability";
    &_debug($function);

     #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
     
    #  check st was obtained
    if(!$st) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }
    
    #  check if valid semantic type
    if(! ($errorhandler->_validTui($st)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($st) in not valid.", 6);
    }

    my $prob = $propagationHash{$st};

    if(!defined $prob) { return 0; }

    return $prob;
}

#  method to set the smoothing parameter and increments the frequency
#  count to one
#  input : 
#  output: 
sub _setStSmoothing
{
    my $self      = shift;

    #  set function name
    my $function = "_setSmoothing";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    foreach my $st (sort keys %propagationFreq) { 
	$propagationFreq{$st} = 1;
    }

    $smooth = 1;
}

#  propagates the given frequency counts of the semantic types
#  input : $hash <- reference to the hash containing 
#                   the frequency counts
#  output: $hash <- containing the propagation counts of all
#                   the semantic types
sub _propagateStCounts
{
    my $self = shift;
    my $hash = shift;

    my $function = "_propagateStCounts";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the parameters
    if(!defined $hash) { 
	$errorhandler->_error($pkg, $function, "Input variable \%hash  not defined.", 4);
    }
    
    #  load the propagation frequency hash
    $self->_loadStPropagationFreq($hash);

    #  propagate the counts
    my @array = ();
    $self->_propagation($root, \@array);

    #  tally up the propagation counts
    $self->_tallyCounts();
    
    #  return the propagation counts
    return \%propagationHash;
}


#  method that tallys up the probability counts of the
#  cui and its decendants and then calculates the ic
#  input :
#  output: 
sub _tallyCounts {

    my $self = shift;
    
    my $function = "_tallyCounts";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    foreach my $st (sort keys %propagationHash) {
	my $set    = $propagationHash{$st};
	my $pcount = $propagationFreq{$st};
	
	if(defined $set) { 
	    print "$st : $set\n";
	    my %hash = ();
	    while($set=~/(T[0-9][0-9][0-9])/g) {
		my $s = $1;
		if(! (exists $hash{$s}) ) {
		    $pcount += $propagationFreq{$s};
		    $hash{$s}++;
		}
	    }	
	}
	$propagationHash{$st} = $pcount;
    }
}

#  returns the maximum depth of a semantic type in the network
#  input : $st  <- string containing the semantic type
#  output: $int <- maximum depth of hte semantic type
sub _getMaxStDepth {
    
    my $self = shift;
    my $st   = shift;

    my $function = "_getMaxStDepth";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check st was obtained
    if(!$st) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }
    
    #  check if valid semantic type
    if(! ($errorhandler->_validTui($st)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($st) in not valid.", 6);
    }

    if(exists $maxDepth{$st}) { return $maxDepth{$st}; }
    else                      { return -1;             }
}

#  returns the minimum depth of a semantic type in the network
#  input : $st  <- string containing the semantic type
#  output: $int <- minimum depth of hte semantic type
sub _getMinStDepth {
    
    my $self = shift;
    my $st   = shift;

    my $function = "_getMinStDepth";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check st was obtained
    if(!$st) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }
    
    #  check if valid semantic type
    if(! ($errorhandler->_validTui($st)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($st) in not valid.", 6);
    }

    if(exists $minDepth{$st}) { return $minDepth{$st}; }
    else                      { return -1;             }
}


#  recursive method that actually performs the propagation
#  input : $st      <- string containing the semantic type
#          $array   <- reference to the array containing
#                      the semantic type's decendants
#  output: $st      <- string containing the semantic type
#          $array   <- reference to the array containing
#                      the semantic type's decendants
sub _propagation {
    my $self    = shift;
    my $st      = shift;
    my $array   = shift;

    my $function = "_propagation";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check st was obtained
    if(!$st) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st.", 4);
    }
    
    #  check if valid semantic type
    if(! ($errorhandler->_validTui($st)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($st) in not valid.", 6);
    }
    
    #  set up the new path
    my @intermediate = @{$array};
    push @intermediate, $st;

    #  get depth
    my $depth = $#intermediate;
    
    #  set the maximum depth
    if(exists $maxDepth{$st}) { 
	if($maxDepth{$st} < $depth) { $maxDepth{$st} = $depth; }
    } else { $maxDepth{$st} = $depth; }
    
    #  set the minimum depth
    if(exists $minDepth{$st}) { 
	if($minDepth{$st} > $depth) { $minDepth{$st} = $depth; }
    } else { $minDepth{$st} = $depth; }
    

    #  initialize the set
    my $set = $propagationHash{$st};
    
    #  if the propagation hash already contains a list of CUIs it
    #  is from its decendants so it has been here before so all we 
    #  have to do is return the list of ancestors with it added
    if(defined $set) { 
	if(! ($set=~/^\s*$/)) { 
	    $set .= " $st";
	    return $set; 
	}
    }
    
    #  search through the children   
    foreach my $child (@{$children{$st}}) {

	my $flag = 0;
		
	#  check if child semantic type has already in the path
	foreach my $s (@intermediate) {
	    if($s eq $child) { $flag = 1; }
	}
	
	#  if it isn't continue on with the depth first search
	if($flag == 0) {  
	    $set .= " ";
	    $set .= $self->_propagation($child, \@intermediate);    
	}
    }
    
    #  remove duplicates from the set
    my $rset;
    if(defined $set) { 
	$rset = _breduce($set); 
    }
    #  store the set in the propagation hash
    $propagationHash{$st} = $rset;
    
    #  add the concept to the set
    $rset .= " $st";
    
    #  return the set
    return $rset;
}

#  removes duplicates in an array
#  input : $array <- reference to an array
#  output: 
sub _breduce {
    
    local($_)= @_;
    my (@words)= split;
    my (%newwords);
    for (@words) { $newwords{$_}=1 }
    join ' ', keys(%newwords);
}

#  load the propagation frequency has with the frequency counts
#  input : $hash <- reference to hash containing frequency counts
#  output:
sub _loadStPropagationFreq {

    my $self = shift;
    my $fhash = shift;
    
    my $function = "_loadStPropagationFreq";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  loop through and set the frequency count
    my $N = 0;    
    foreach my $st (sort keys %{$fhash}) {
	if($st=~/^\s*$/) { next; }
	my $freq = ${$fhash}{$st};
	if(exists $propagationFreq{$st}) {
	    $propagationFreq{$st} += $freq;
	}
	$N = $N + $freq;
    }
        
    if($smooth == 1) { 
	my $k = keys %propagationFreq;
	$N += $k;
    }

    #  set N for the config file
    $stN = $N;
    
    #  loop through again and set the probability
    foreach my $st (sort keys %propagationFreq) { 
	$propagationFreq{$st} = ($propagationFreq{$st}) / $N;
    }
}
#  load the propagation hash has with the probability counts
#  input : $hash <- reference to hash containing the probability counts
#  output:
sub _loadStPropagationHash {

    my $self = shift;
    my $fhash = shift;
    
    my $function = "_loadStPropagationHash";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  load the propagation hash with the probabilities
    %propagationHash = ();
    foreach my $st (sort keys %{$fhash}) {
	if($st=~/^\s*$/) { next; }
	my $prob = ${$fhash}{$st};
	$propagationHash{$st} = $prob;
    }
}

#  returns the stN - the total number of semantic types
#  input : 
#  output: integer <- total number of semantic types
sub _getStN
{
    my $self = shift;

    my $function = "_getStN";
    &_debug($function);

    return $stN;
}

#  method to load the semantic network
#  input : 
#  output: 
sub _loadSemanticNetwork {
    
    my $self = shift;

    my $function = "_loadSemanticNetwork";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  set the index DB handler
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    my %upper = ();
    #  get the is-a relations (T186) between the semantic types
    #  set the parent taxonomy
    my $sql = qq{ SELECT UI1, UI3 FROM SRSTRE1 where UI2='T186'};
    my $sth = $db->prepare( $sql );
    $sth->execute();
    my($st1, $st2);
    $sth->bind_columns( undef, \$st1, \$st2 );
    while( $sth->fetch() ) {
	push @{$children{$st2}}, $st1;
	push @{$parents{$st1}}, $st2;
	$upper{$st1}++;
	$propagationFreq{$st1} = 0;
	$propagationFreq{$st2} = 0;
    }
    $errorhandler->_checkDbError($pkg, $function, $sth);
    $sth->finish();
    
    #  set the upper level taxonomy
    foreach my $st (sort keys %propagationFreq) { 
	if(! (exists $upper{$st})) {
	    push@{$children{$root}}, $st;
	    push@{$parents{$st}}, $root;
	}
    }
    #  add the root to the propagationFreq 
    $propagationFreq{$root} = 0; 
}

#  initialize package variables
#  input : 
#  output: 
sub _initializeGlobalVariables {

    $debug = 0;
        
    $option_verbose     = 0;
    $option_debugpath   = 0;
    $option_t           = 0;
    
    $errorhandler = "";
    $cuifinder    = "";

    %propagationFreq = ();
    %propagationHash = ();
    %children        = ();
    %parents         = ();

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
    my $verbose      = $params->{'verbose'};
    my $t            = $params->{'t'};
    my $debugoption  = $params->{'debug'};
    my $debugpath    = $params->{'debugpath'};

    if(defined $debugoption) { 
	$debug = 1;
    }

    my $output = "";

    #  check if debugpath option 
    if(defined $debugpath) {
	$option_debugpath = 1;
	$output .= "   --debugpath $debugpath\n";
	open(DEBUG_FILE, ">$debugpath") || 
	    die "Could not open depthpath file $debugpath\n";
    }

    #  check verbose option
    if(defined $verbose) { 
	$output .= "\nSTFinder User Options:\n";
    }
    
    #  check that this is not a test case
    if(defined $t) { $option_t = 1; }

    #  check if verbose run has been identified
    if(defined $verbose) { 
	$option_verbose = 1;
	
	$output .= "   --verbose option set\n";
    }

    if($option_t == 0) {
	print STDERR "$output\n";
    }
}

#  This is like a reverse DFS only it is not recursive
#  due to the stack overflow errors I received when it was
#  input : $tui   <- string containing the semantic type TUI
#  output: $array <- reference to an array containing the path information
sub _pathsToRoot {

    my $self  = shift;
    my $tui   = shift;

    return () if(!defined $self || !ref $self);

    my $function = "_pathsToRoot($tui)";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check st was obtained
    if(!$tui) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$tui.", 4);
    }
    
    #  check if valid semantic type
    if(! ($errorhandler->_validTui($tui)) ) {
	$errorhandler->_error($pkg, $function, "Semantic Type ($tui) in not valid.", 6);
    }

    #  set the  storage
    my @path_storage = ();

    #  set the stack
    my @stack = ();
    push @stack, $tui;

    #  set the count
    my %visited = ();

    #  set the paths
    my @paths = ();
    my @empty = ();
    push @paths, \@empty;

    #  now loop through the stack
    while($#stack >= 0) {
	
	my $st   = $stack[$#stack];
	my $path = $paths[$#paths];

	#  set up the new path
	my @intermediate = @{$path};
	push @intermediate, $st;
	my $series = join " ", @intermediate;
	        
	#  check if st has been visited already
	if(exists $visited{$series}) { 
	    pop @stack; pop @paths;
	    next; 
	}
	else { $visited{$series}++; }
	
	#  print information into the file if debugpath option is set
	if($option_debugpath) { 
	    my $d = $#intermediate+1;
	    print DEBUG_FILE "$st\t$d\t@intermediate\n"; 
	}
	
	#  if the st is the umls root - we are done
	if($st eq $root) { 
	    #  this is a complete path to the root so push it on the paths 
	    my @reversed = reverse(@intermediate);
	    my $rseries  = join " ", @reversed;
	    push @path_storage, $rseries;
	    next;
	}
	
	#  if there are no parents we are finished with this semantic type
	if($#{$parents{$st}} < 0) {
	    pop @stack; pop @paths;
	    next;
	}
	
	#  search through the parents
	my $stackflag = 0;
	foreach my $parent (@{$parents{$st}}) {
	    
	    #  check if concept is already in the path
	    if($series=~/$parent/)  { next; }
	    if($st eq $parent)      { next; }

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

#  this function finds the shortest path between two semantic types and returns the 
#  path. in the process it determines the least common subsumer for that path so it 
#  returns both
#  input : $st1      <- string containing the first TUI
#          $st2      <- string containing the second TUI
#  output: $hash     <- reference to a hash containing the 
#                       lcs as the key and the path as the
#                       value
sub _shortestPath {

    my $self = shift;
    my $st1  = shift;
    my $st2  = shift;

    my $function = "_shortestPath";
    &_debug($function);
      
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $st1) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st1.", 4);
    }
    if(!defined $st2) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st2.", 4);
    }

    #  check if valid semantic type TUI
    if(! ($errorhandler->_validTui($st1)) ) {
	$errorhandler->_error($pkg, $function, "TUI ($st1) in not valid.", 12);
    }    
    if(! ($errorhandler->_validTui($st2)) ) {
	$errorhandler->_error($pkg, $function, "TUI ($st2) in not valid.", 12);
    }    

    # Get the paths to root for each ofhte concepts
    my $lTrees = $self->_pathsToRoot($st1);

    my $rTrees = $self->_pathsToRoot($st2);
   
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
		my $st = "";
		
		my @lArray  = ();
		my @rArray  = ();
		
		my @lTreeArray = split/\s+/, $lTree;
		my @rTreeArray = split/\s+/, $rTree;
		
		foreach $st (reverse @lTreeArray) {
		    $lCount++;
		    push @lArray, $st;
		    last if($st eq $lcs);

		}
		foreach $st (reverse @rTreeArray) {
		    $rCount++;
		    last if($st eq $lcs);
		    push @rArray, $st;
		    
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

#  method to get the Least Common Subsumer of two 
#  paths to the root of a taxonomy
#  input : $array1 <- reference to an array containing 
#                     the paths to the root for tui1
#          $array2 <- same thing for tui2
#  output: $hash   <- reference to a hash containing the
#                     lcs as the key and the path as the hash
sub _getLCSfromTrees {

    my $self      = shift;
    my $arrayref1 = shift;
    my $arrayref2 = shift;
        
    my $function = "_getLCSfromTrees";
    &_debug($function);

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


#  this function returns the shortest path between two semantic type TUIs
#  input : $st1   <- string containing the first cui
#          $st2   <- string containing the second
#  output: $array <- reference to an array containing the lcs(es)
sub _findShortestPath { 
    
    my $self = shift;
    my $st1 = shift;
    my $st2 = shift;
    
    my $function = "_findShortestPath";
    &_debug($function);
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $st1) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st1.", 4);
    }
    if(!defined $st2) { 
	$errorhandler->_error($pkg, $function, "Error with input variable \$st2.", 4);
    }

    #  check if valid semantic type TUI
    if(! ($errorhandler->_validTui($st1)) ) {
	$errorhandler->_error($pkg, $function, "TUI ($st1) in not valid.", 12);
    }    
    if(! ($errorhandler->_validTui($st2)) ) {
	$errorhandler->_error($pkg, $function, "TUI ($st2) in not valid.", 12);
    }    

    #  find the shortest path(s) and lcs - there may be more than one
    my $hash = $self->_shortestPath($st1, $st2);
    
    #  remove the blanks from the paths
    my @paths = (); my $output = "";
    foreach my $path (sort keys %{$hash}) {
	if($path=~/T[0-9]+/) {
	    push @paths, $path;
	}
    } 
        
    #  return the shortest paths (all of them)
    return \@paths;
}


#  print out the function name to standard error
#  input : $function <- string containing function name
#  output:
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Interface::STFinder::$function\n"; }
}

1;

__END__

=head1 NAME

UMLS::Interface::STFinder - provides the semantic type path information 
for the modules in the UMLS::Interface package.

=head1 DESCRIPTION

This package provides the path information about semantic types in 
the UMLS Semantic Network for the modules in the UMLS::Interface 
package.

For more information please see the UMLS::Interface.pm 
documentation. 

=head1 SYNOPSIS

 use UMLS::Interface::CuiFinder;
 use UMLS::Interface::STFinder;
 use UMLS::Interface::ErrorHandler;

 %params = ();

 $params{'realtime'} = 1;

 $cuifinder = UMLS::Interface::CuiFinder->new(\%params);
 die "Unable to create UMLS::Interface::CuiFinder object.\n" if(!$cuifinder);

 $stfinder = UMLS::Interface::STFinder->new(\%params, $cuifinder); 
 die "Unable to create UMLS::Interface::STFinder object.\n" if(!$stfinder);

 my $cell = "T025";
 my $bpoc = "T023";

 my $paths = $stfinder->_pathsToRoot($cell);
 print "The paths between cell ($cell) and the root:\n"; 
 foreach my $path (@{$paths}) { 
    print " => $path\n";
 }

 print "\n\n";
 my $spaths = $stfinder->_findShortestPath($cell, $bpoc);
 print "The paths between cell ($cell) and bpoc ($bpoc): \n";
 foreach my $path (@{$spaths}) { 
    print " => $path\n";
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
