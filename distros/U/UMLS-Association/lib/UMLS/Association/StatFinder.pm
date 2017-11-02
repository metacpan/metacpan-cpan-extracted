#UMLS::Association
#
# Perl module for scoring the semantic association of terms in the Unified
# Medical Language System (UMLS).
#
# Copyright (c) 2015
#
# Bridget T. McInnes, Virginia Commonwealth University
# btmcinnes at vcu.edu
#
# Keith Herbert, Virginia Commonwealth University
# herbertkb at vcu.edu
#
# Alexander D. McQuilkin, Virginia Commonwealth University 
# alexmcq99 at yahoo.com
#
# Sam Henry, Virginia Commonwealth University
# henryst at vcu.edu
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

package UMLS::Association::StatFinder;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;
use File::Spec;

#  error handling variables
my $errorhandler = "";

my $pkg = "UMLS::Association::StatFinder";

#  debug variables
#local(*DEBUG_FILE);

#NOTE: every global variable is followed by a _G with the 
# exception of debug error handler, and constants which are all caps
#  global variables
my $debug     = 0; #in debug mode or not

#global options variables
my $assocDB_G;
my $lta_G = 0; #1 or 0 is using lta or not
my $mwa_G = 0; #1 or 0 if using mwa or not
my $vsa_G = 0; #1 or 0 if using vsa or not
my $noOrder_G = 0; #1 or 0 if noOrder is enabled or not
my $matrix_G = 0; #matrix file name is using a matrix file rather than DB

######################################################################
#                 Initialization Functions
######################################################################
#  method to create a new UMLS::Association::StatFinder object
#  input : $params <- reference to hash of database parameters
#  output: $self
sub new {
    #grab params and create self
    my $self = {};
    my $className = shift;
    my $params = shift;

    #bless the object.
    bless($self, $className);

    #initialize error handler
    $errorhandler = UMLS::Association::ErrorHandler->new();
    if(! defined $errorhandler) {
        print STDERR "The error handler did not get passed properly.\n";
        exit;
    }

    # initialize the object.
    $debug = 0; 
    $self->_initialize($params);
    return $self;
}

#  method to initialize the UMLS::Association::StatFinder object.
#  input : $parameters <- reference to a hash of database parameters
#  output: none, but $self is initialized
sub _initialize {
    #grab parameters
    my $self = shift;
    my $paramsRef = shift;
    my %params = %{$paramsRef};

    #set global variables using option hash
    $lta_G = $params{'lta'};
    $mwa_G = $params{'mwa'};
    $vsa_G = $params{'vsa'};
    $noOrder_G = $params{'noorder'};
    $matrix_G = $params{'matrix'};

    #connect to the database of association scores
    if (!$matrix_G) {
	$self->_setDatabase($paramsRef);
    }
    
    #error checking
    my $function = "_initialize";
    &_debug($function);
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }    

    #TODO, remove this once I have DB implemented
    #check that a matrix is specified for options (need to implement DB mode)
    if (!$matrix_G && $mwa_G) {
	$errorhandler->_error($pkg, $function, "MWA requires the --matrix option", 12);
    }
     if (!$matrix_G && $vsa_G) {
	$errorhandler->_error($pkg, $function, "VSA requires the --matrix option", 12);
    }
}

sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Association::StatFinder::$function\n"; }
}

#  method to set the association database
#  input : $params <- reference to a hash
#  output: none, but association database is set and initialized
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
    if(! defined $database) { $database = "cuicounts";            }
    if(! defined $socket)   { $socket   = "/var/run/mysqld/mysqld.sock"; }
    if(! defined $hostname) { $hostname = "localhost";       }

    #  initialize the database handler
    $assocDB_G  = "";

    #  create the database object...
    if(defined $username and defined $password) {
        if($debug) { print STDERR "Connecting with username and password\n"; }
        $assocDB_G = DBI->connect("DBI:mysql:database=$database;mysql_socket=$socket;host=$hostname",$username, $password, {RaiseError => 0});
    }
    else {
        if($debug) { print STDERR "Connecting using the my.cnf file\n"; }
        my $dsn = "DBI:mysql:umls;mysql_read_default_group=client;database=$database";
        $assocDB_G = DBI->connect($dsn);
    }

    #  check if there is an error
    $errorhandler->_checkDbError($pkg, $function, $assocDB_G);

    #  check that the db exists
    if(!$assocDB_G) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  set database parameters
    $assocDB_G->{'mysql_enable_utf8'} = 1;
    $assocDB_G->do('SET NAMES utf8');
    $assocDB_G->{mysql_auto_reconnect} = 1;
}

######################################################################
#           public interface to get observed counts
######################################################################

# Gets observed counts (n11, n1p, np1, npp) of the cui sets
# input: $pairHashListRef - a ref to an array of pairHashes
# output: \@allStatsRef - a ref to an array of observed counts 4-tuples
#                         each 4-tuple consists of in order:
#                         $n11, $n1p, $np1, and $npp
#                         and they correspond to the observed counts of
#                         each of the pairHashes passed in
sub getObservedCounts {   
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift; 

    #error checking
    my $function = "getObservedCounts"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #calculate n11, n1p, np1, npp using a matrix or DB
    # and according to the method of various other options
    my $allStatsRef = -1;
    if ($lta_G) {
	$allStatsRef = $self->_getStats_LTA($pairHashListRef);	
    }
    elsif ($mwa_G) {
	$allStatsRef = $self->_getStats_MWA($pairHashListRef);
    }
    elsif ($vsa_G) {
	$allStatsRef = $self->_getStats_VSA($pairHashListRef);
    }
    else {
	if ($matrix_G) {
	    $allStatsRef = $self->_getStats_matrix($pairHashListRef);
	}
	else {
	    $allStatsRef = $self->_getStats_DB($pairHashListRef);
	}
    }

    #return a reference to a list of stats for each pairHash
    return $allStatsRef;
}


######################################################################
# functions to get statistical information about the cuis using a DB
######################################################################

# gets N11, N1P, NP1, NPP for a pairHashList using a database
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- array ref containing array refs of four values
#                      for each pair Hash, $n11, $n1p, $np1, and $npp
sub _getStats_DB {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;
    
    #error checking
    my $function = "_getStats_DB"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #compute observed counts for each pair hash
    my @data = ();
    my $npp = $self->_getNpp_DB();
    foreach my $pairHashRef(@{$pairHashListRef}) {

	#grab the data from a DB
	my $n11 = $self->_getN11_DB(${$pairHashRef}{'set1'}, ${$pairHashRef}{'set2'}); 
	my $n1p = $self->_getN1p_DB(${$pairHashRef}{'set1'});  
	my $np1 = $self->_getNp1_DB(${$pairHashRef}{'set2'}); 

	#store the data
	my @values = ($n11, $n1p, $np1, $npp);
	push @data, \@values;	
    }

    #return the data
    return  \@data;
}

#  Gets N11 of the cui pair using a database
#  input:  $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#  output: $n11  <- n11 of cui sets 
sub _getN11_DB {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;

    #error checking
    my $function = "_getN11";
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #build a query string for n11
    my $firstCui = shift @{$cuis1Ref};
    my $queryString = "select SUM(n_11) from N_11 where ((cui_1 = '$firstCui' ";
    foreach my $cui (@{$cuis1Ref}) {
	$queryString .= "or cui_1 = '$cui' ";
    }
    unshift @{$cuis1Ref}, $firstCui;

    #set all cui2's
    $firstCui = shift @{$cuis2Ref};
    $queryString .= ") and (cui_2 = '$firstCui' ";
    foreach my $cui (@{$cuis2Ref}) {
	$queryString .= "or cui_2 = '$cui' ";
    }
    unshift @{$cuis2Ref}, $firstCui;

    #finalize the query string
    if ($noOrder_G) {
	#swap the positions of the cuis
	$firstCui = shift @{$cuis2Ref};
	$queryString .= ")) or ((cui_1 = '$firstCui' ";
	foreach my $cui (@{$cuis2Ref}) {
	    $queryString .= "or cui_1 = '$cui' ";
	}
	unshift @{$cuis2Ref}, $firstCui;

	$firstCui = shift @{$cuis1Ref};
	$queryString .= ") and (cui_2 = '$firstCui' ";
	foreach my $cui (@{$cuis1Ref}) {
	    $queryString .= "or cui_2 = '$cui' ";
	}
	unshift @{$cuis1Ref}, $firstCui;
    }
    $queryString .= "));";
    
    #query the DB and return n11
    my $n11 = shift @{$assocDB_G->selectcol_arrayref($queryString)};
    if (!defined $n11) {
	$n11 = 0;
    }
    return $n11;
}

#  Method to return the np1 of a concept using a database
#  input : $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#  output: $np1 <- number of times the cuis2Ref set occurs in second bigram position
sub _getNp1_DB {
    my $self = shift;
    my $cuis2Ref = shift; 
    
    #error checking
    my $function = "_getNp1_DB";
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #build a query string for all where cui2's are in the second position
    my $firstCui = shift @{$cuis2Ref};
    my $queryString = "select SUM(n_11) from N_11 where (cui_2 = '$firstCui' ";
    foreach my $cui (@{$cuis2Ref}) {
	$queryString .= "or cui_2 = '$cui' ";
    }
    unshift @{$cuis2Ref}, $firstCui;

    #finalize the query string
    if ($noOrder_G) {
	#add where cui2 is in the first position
	$firstCui = shift @{$cuis2Ref};
	$queryString .= ") or (cui_1 = '$firstCui' ";
	foreach my $cui (@{$cuis2Ref}) {
	    $queryString .= "or cui_1 = '$cui' ";
	}
	unshift @{$cuis2Ref}, $firstCui;
    }
    $queryString .= ");";

    #query the db to retrive np1
    my $np1 = shift @{$assocDB_G->selectcol_arrayref($queryString)};
    if (!defined $np1) {
	$np1 = -1;
    }
    return $np1;
}

#  Method to return the n1p of a concept from a database
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#  output: $n1p <- number of times cuis in cuis1 set occurs in first bigram position
sub _getN1p_DB {
    my $self = shift;
    my $cuis1Ref = shift; 

    #error checking
    my $function = "_getN1p";
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #build the query string for all where cui1's are in the first position
    my $firstCui = shift @{$cuis1Ref};
    my $queryString = "select SUM(n_11) from N_11 where (cui_1 = '$firstCui' ";
    foreach my $cui (@{$cuis1Ref}) {
	$queryString .= "or cui_1 = '$cui' ";
    }
    unshift @{$cuis1Ref}, $firstCui;

    #finalize the query string
    if ($noOrder_G) {
	#add where cui1 is in the second position
	$firstCui = shift @{$cuis1Ref};
	$queryString .= ") or (cui_2 = '$firstCui' ";
	foreach my $cui (@{$cuis1Ref}) {
	    $queryString .= "or cui_2 = '$cui' ";
	}
	unshift @{$cuis1Ref}, $firstCui;
    }
    $queryString .= ");";

    #query the db to retrive n1p
    my $n1p = shift @{$assocDB_G->selectcol_arrayref($queryString)};
    if (!defined $n1p) {
        $n1p = -1;
    }
    return $n1p;
}

#  Method to calculate npp from a DB
#  input : none
#  output: $npp
sub _getNpp_DB {
    my $self = shift;
    
    #error checking
    my $function = "getNpp_DB";
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #get npp, the number of co-occurrences
    my $npp = shift @{$assocDB_G->selectcol_arrayref("select sum(N_11) from N_11")}; 

    #update $npp for noOrder, since Cuis can be trailing or leading its 2x ordered npp
    if ($noOrder_G) {
	$npp *= 2;
    }

    #return npp
    if($npp <= 0) { $errorhandler->_error($pkg, $function, "", 5); } 
    return $npp; 
}

########################################################################
# functions to get statistical information about the cuis using a matrix 
########################################################################


# Gets arrays of all first (leading) and second (trailing) cuis
# This is used when retreiving data from a matrix flat file
# input:  $pairHashListRef - a ref to an array of pairHashes
# output: (\@cuis1, \@cuis2) - two array refs, the first contains
#                              all leading cuis in the dataset, the
#                              second contains all trailing cuis in 
#                              the dataset.
sub _getAllLeadingAndTrailingCuis {
    my $self = shift;
    my $pairHashListRef = shift;

    #create a list of all possible cuis in the first and second positions
    my @cuis1 = ();
    my @cuis2 = ();
    foreach my $pairHashRef(@{$pairHashListRef}) {
	foreach my $cui(@{${$pairHashRef}{'set1'}}) {
	    push @cuis1, $cui;
	}
	foreach my $cui(@{${$pairHashRef}{'set2'}}) {
	    push @cuis2, $cui;
	}
    }
    return (\@cuis1, \@cuis2);
}


# gets N11, N1P, NP1, NPP for a pairHashList using a matrix
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- array ref containing array refs of four values
#                      for each pair Hash, $n11, $n1p, $np1, and $npp
sub _getStats_matrix {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;

    #error checking
    my $function = "_getStats_matrix"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #get all observed counts for all possible cuis in the term pairs
    (my $cuis1Ref, my $cuis2Ref) = $self->_getAllLeadingAndTrailingCuis($pairHashListRef);
    my $countsRef = $self->_getObservedCounts_matrix($cuis1Ref, $cuis2Ref);
    my $n11AllRef = ${$countsRef}[0];
    my $n1pAllRef = ${$countsRef}[1];
    my $np1AllRef = ${$countsRef}[2];
    my $npp = ${$countsRef}[3];

    #update $npp for noOrder, since Cuis can be trailing or leading its 2x ordered npp
    if ($noOrder_G) {
	$npp *= 2;
    }

    #get values for each pairHash based on what was retreived from the matrix
    my @data = ();
    foreach my $pairHashRef (@{$pairHashListRef}) {
	my $n11 = $self->_getN11_matrix(${$pairHashRef}{'set1'}, ${$pairHashRef}{'set2'}, $n11AllRef); 
	my $n1p = $self->_getN1p_matrix(${$pairHashRef}{'set1'}, $n11AllRef, $n1pAllRef, $np1AllRef); 
	my $np1 = $self->_getNp1_matrix(${$pairHashRef}{'set2'}, $n11AllRef, $n1pAllRef, $np1AllRef); 
	
	my @vals = ($n11, $n1p, $np1, $npp);
	push @data, \@vals;
    }
    
    #return the data
    return \@data;
}

#computes the observed counts for all combinations of the cuis passed in
#doing this in a single function makes it so all values can be computed with a 
#single pass of the input file, making execution time much faster
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#  output: $\@counts  <- array ref containing four sets of values: 
#                      \%n11, \%n1p, \%np1, and $npp for the cui pairs
#                      hashes are indexed: $n11{"$cui1,$cui2"}, $n1p{$cui},
#                                          $np1{$cui}
sub _getObservedCounts_matrix {
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;

    #convert cui arrays to hashes, makes looping thru
    # the file faster
    my %cuis1 = ();
    foreach my $cui(@{$cuis1Ref}) {
	$cuis1{$cui} = 1;
    }
    my %cuis2 = ();
    foreach my $cui(@{$cuis2Ref}) {
	$cuis2{$cui} = 1;
    }

    #precalculate values for all cuis and cui pairs
    my %n11 = ();
    my %n1p = ();
    my %np1 = ();
    my $npp = 0;
    open IN, $matrix_G or die "Cannot open $matrix_G for input: $!\n";
    while (my $line = <IN>) {
	#get cuis and value from the line
	chomp $line;
	my ($cui1, $cui2, $num) = split /\t/, $line;

	#record any occurrence of any cui1 or 2, in case order is ignored
	if (exists $cuis1{$cui1} || exists $cuis1{$cui2}
	    || exists $cuis2{$cui1} || exists $cuis2{$cui2}) {
	    $n1p{$cui1} += $num;
	    $np1{$cui2} += $num;
	    $n11{"$cui1,$cui2"} = $num;
	}

	#update npp
	$npp += $num;
    }
    close IN;

    #return counts
    my @counts = (\%n11, \%n1p, \%np1, $npp);
    return \@counts;
}

#  Gets N11 of the cui pair using a matrix
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#          $n11AllRef <- ref to an array containing n11 values for all possible
#                        cui pairs of the cuis1 and cuis2, of the form
#                        n11All{"$cui1,$cui2"}=value. See _getObservedCounts_matrix
#  output: $n11      <- frequency of co-occurrences of the cuis in the cui sets
sub _getN11_matrix {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    my $n11AllRef = shift;

    #error checking
    my $function = "_getN11_matrix"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #calculate n11 as the sum n11s for all combinations of 
    # cuis1, cuis2 (order matters, cui1 must be first)
    my $n11 = 0;
    foreach my $cui1 (@{$cuis1Ref}) {
	foreach my $cui2 (@{$cuis2Ref}) {
	    my $num = ${$n11AllRef}{"$cui1,$cui2"};
	    if(defined $num) {
		$n11 += $num;
	    }
	}
    }

    #update values if ignoring word order
    if($noOrder_G) {
	#add all n11's, now with the order reversed
	foreach my $cui1 (@{$cuis1Ref}) {
	    foreach my $cui2 (@{$cuis2Ref}) {
		my $num = ${$n11AllRef}{"$cui2,$cui1"};
		if(defined $num) {
		    $n11 += $num;
		}
	    }
	}
    }

    return $n11;
}

#  gets N1P for a concept using a matrix
#  input : $cuis1Ref <- reference to an array containing the first cuis in a set of cui pairs
#          $countsRef <- ref to an array containing n11, n1p, np1, and npp counts
#                        for the cui combinations. See _getObservedCounts_matrix()
#          $n1pAllRef <- ref to an array containing n1p values for all cuis of cuis1 and cuis2, 
#                        of the form n1pAll{$cui} = value. See _getObservedCounts_matrix
#          $np1AllRef <- ref to an array containing n1p values for all cuis of cuis1 and cuis2, 
#                        of the form np1All{$cui} = value. See _getObservedCounts_matrix
#  output: $n1p      <- the number of times the set of concepts occurs in first position
sub _getN1p_matrix {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $n11AllRef = shift;
    my $n1pAllRef = shift;
    my $np1AllRef = shift;

    #error checking
    my $function = "_getN1P_matrix"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #calculate n1p as the sum of n1p's for all cuis1
    my $n1p = 0;
    foreach my $cui (@{$cuis1Ref}) {
	my $num = ${$n1pAllRef}{$cui};
	if(defined $num) {
	    $n1p += $num;
	}
    }

    #update values if ignoring word order
    if ($noOrder_G) {
	#add all np1's to n1p
	foreach my $cui (@{$cuis1Ref}) {
	    my $num = ${$np1AllRef}{$cui};
	    if(defined $num) {
		$n1p += $num;
	    }
	}

	#avoid double counting occurrences with self, subtract them
	foreach my $cui1(@{$cuis1Ref}) {
	    foreach my $cui2(@{$cuis1Ref}) {
		my $val = ${$n11AllRef}{"$cui1,$cui2"};
		if (defined $val) {
		    $n1p -= $val;
		}
	    }
	}
    }

    #set n1p to -1 if there are no values for it since this indicates
    # there is not enough information to calculate the score
    if ($n1p == 0) {
	$n1p = -1;
    }

    #return the value
    return $n1p;
}

#  gets NP1 for a concept using a matrix
#  input : $cuis2Ref <- reference to an array containing the first cuis in a set of cui pairs
#          $countsRef <- ref to an array containing n11, n1p, np1, and npp counts
#                        for the cui combinations. See _getObservedCounts_matrix()
#          $n1pAllRef <- ref to an array containing n1p values for all cuis of cuis1 and cuis2, 
#                        of the form n1pAll{$cui} = value. See _getObservedCounts_matrix
#          $np1AllRef <- ref to an array containing n1p values for all cuis of cuis1 and cuis2, 
#                        of the form np1All{$cui} = value. See _getObservedCounts_matrix
#  output: $np1      <- the number of times the set of concepts occurs in second position
sub _getNp1_matrix {
    #grab parameters
    my $self = shift;
    my $cuis2Ref = shift;
    my $n11AllRef = shift;
    my $n1pAllRef = shift;
    my $np1AllRef = shift;

    #calculate np1 as the sum of np1's for all cuis2
    my $np1 = 0;
    foreach my $cui (@{$cuis2Ref}) {
	my $num = ${$np1AllRef}{$cui};
	if (defined $num) {
	    $np1 += $num;
	}
    }

    #update values if ignoring word order
    if ($noOrder_G) {
	#add all n1p's to np1s
	foreach my $cui (@{$cuis2Ref}) {
	    my $num = ${$n1pAllRef}{$cui};
	    if (defined $num) {
		$np1 += $num;
	    }
	}

	#avoid double counting occurrences with self, subtract them
	foreach my $cui1(@{$cuis2Ref}) {
	    foreach my $cui2(@{$cuis2Ref}) {
		my $val = ${$n11AllRef}{"$cui1,$cui2"};
		if (defined $val) {
		    $np1 -= $val;
		}
	    }
	}
    }

    #set n1p to -1 if there are no values for it since this indicates
    # there is not enough information to calculate the score
    if ($np1 == 0) {
	$np1 = -1;
    }

    #return the value
    return $np1;
}


########################################################################
# functions to get statistical information about the cuis LTA, MWA, VSA
########################################################################
#  Gets contingency table values for Linking Term Association (LTA)
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- valuesarray ref containing array refs of four values
#                      for each pairHash in the pairHash list. The 
#                      values are $n11, $n1p, $np1, and $npp
sub _getStats_LTA {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;
    
    #error checking
    my $function = "_getStats_LTA"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
     #get data from the matrix
    (my $cooccurrences1ListRef, my $cooccurrences2ListRef,  
     my $numCooccurrences, my $numUniqueCuis) 
	= $self->_readMatrixValues_Linking($pairHashListRef); 

    #for LTA, npp= num unique cuis in the dataset
    my $npp = $numUniqueCuis;

    #calculate stats for each pairHash based on the co-occurrences data
    my @data = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
  
	#calculate n1p and np1 as the number of co-occurring terms
	my $n1p = scalar keys %{${$cooccurrences1ListRef}[$i]};
	my $np1 = scalar keys %{${$cooccurrences2ListRef}[$i]};

	#calculate n11
	my $n11 = 0;
	#Find number of CUIs that co-occur with both CUI 1 and CUI 2
	foreach my $cui (keys %{${$cooccurrences1ListRef}[$i]}) {
	    if (exists ${${$cooccurrences2ListRef}[$i]}{$cui}) {
		$n11++;
	    }
	}

	#store the data for this pairHash
	my @vals = ($n11, $n1p, $np1, $npp);
	push @data, \@vals;
    }

    #return the data
    return  \@data;
}


#  Gets contingency table values for Minimum Weight Association (MWA)
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- array ref containing array refs of four values
#                      for each pairHash in the pairHash list. The 
#                      values are $n11, $n1p, $np1, and $npp
sub _getStats_MWA {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;
    
    #error checking
    my $function = "_getStats_MWA"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #get data from the matrix
    (my $cooccurrences1ListRef, my $cooccurrences2ListRef,
     my $numCooccurrences, my $numUniqueCuis) 
	= $self->_readMatrixValues_Linking($pairHashListRef); 

    #for MWA, npp= numCooccurrences in the dataset
    my $npp = $numCooccurrences;

    #calculate stats for each pairHash based on the co-occurrences data
    my @data = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	my $set1CoRef = ${$cooccurrences1ListRef}[$i];
	my $set2CoRef = ${$cooccurrences2ListRef}[$i];

	#calculate n1p and np1 as the number of co-occurrences for the term
	my $n1p = 0;
	foreach my $cui (keys %{$set1CoRef}) {
	    $n1p += ${$set1CoRef}{$cui};
	}
	my $np1 = 0;
	foreach my $cui (keys %{$set2CoRef}) {
	    $np1 += ${$set2CoRef}{$cui};
	}

	#Find $n11, the min co-occurrence value of the pair
	my $n11 = 0;
	foreach my $cui (keys %{$set1CoRef}) {
	    #if this cui co-occurs with both sets, then increment n11
	    if (exists ${$set2CoRef}{$cui}) {
		#increment n11 by the minimum of the co-occurrences
		my $min = ${$set1CoRef}{$cui};
		if (${$set2CoRef}{$cui} < $min) {
		    $min = ${$set2CoRef}{$cui};
		}
		$n11+=$min;
	    }
	}

	#store the data for this pairHash
	my @vals = ($n11, $n1p, $np1, $npp);
	push @data, \@vals;
    }

    #return the data
    return  \@data;
}


#  Gets contingency table values for Vector Set Association (VSA)
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- array ref containing array refs of four values
#                      for each pairHash in the pairHash list. The 
#                      values are $n11, $n1p, $np1, and $npp
sub _getStats_VSA {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;
    
    #error checking
    my $function = "_getStats_VSA"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
     #get data from the matrix
    (my $cooccurrences1ListRef, my $cooccurrences2ListRef,  
     my $numCooccurrences, my $numUniqueCuis) 
	= $self->_readMatrixValues_Linking($pairHashListRef); 

    #convert the cooccurrence lists to pairHashLists
    my @newPairHashList = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	my %pairHash = ();
	
	#make set 1 an array
	my @set1 = ();
	foreach my $key (keys %{${$cooccurrences1ListRef}[$i]}) {
	    push @set1, $key;
	}
	$pairHash{'set1'} = \@set1;

	#make set 2 an array
	my @set2 = ();
	foreach my $key (keys %{${$cooccurrences2ListRef}[$i]}) {
	    push @set2, $key;
	}
	$pairHash{'set2'} = \@set2;

	#add the pairHash to the pairHashList
	push @newPairHashList, \%pairHash;
    }
    #So, at this point we have converted the sets of B terms
    # into a pairhashlist.
    #Next we find the stats for each of those pair hashes and
    # use that as the stats for the original pair.
    # in this way we are finding the assocaition between
    # sets of co-occurring terms of the original terms
    my $allStatsRef;
    if ($matrix_G) {
	$allStatsRef = $self->_getStats_matrix(\@newPairHashList);
    }
    else {
	$allStatsRef = $self->_getStats_DB(\@newPairHashList);
    }
    #all stats ref contains n11, np1, n1p, and npp for 
    # each of the pair hashes
    return $allStatsRef;
}



#  Gets co-occurrence data for each of the pairHashes in the pairHashList
#  and gets global stats, total number of co-occurrences in the dataset, 
#  and the number of unique cuis in the dataset. The co-occurrences data
#  is returned in the form of a co-occurrences hash for cuis1 and cuis2 
#  of the pairHash. Each co-occurrences hash is:
#              $cooccurrences1{$cui2} = $val
#  There is no distinction between different cuis of cuis1
#  input : $pairHashListRef <- ref to a pairHashList
#  output: $\@data  <- array ref containing array refs of four values
sub _readMatrixValues_Linking {
    #grab parameters
    my $self = shift;
    my $pairHashListRef = shift;
    
    #error checking
    my $function = "_readMatrixValues_Linking"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #Get co-occurrences with each set of CUIs
    # for each set of cuis we find a list of cuis that co-occur with that set
    # this is done for cuis1 and cuis2. Once retreiving these two lists
    # of co-occurring cuis, we can calculate LTA based on the overlap of 
    # co-occurrences.
    my @cooccurrences1List;
    my @cooccurrences2List;
    my $totalCooccurrences = 0;
    my $totalUniqueCuis = 0;
    if ($matrix_G) {
	#get observed counts for all data
	(my $cuis1Ref, my $cuis2Ref) = $self->_getAllLeadingAndTrailingCuis($pairHashListRef);
	(my $n1pAllRef, my $np1AllRef, $totalCooccurrences, $totalUniqueCuis) 
	    = $self->_getObserved_matrix_Linking($cuis1Ref, $cuis2Ref);

	#get co-occurrence data for each pairHash
	foreach my $pairHashRef(@{$pairHashListRef}) {
	    (my $cooccurrences1Ref, my $cooccurrences2Ref) = $self
		->_getCUICooccurrences_matrix(${$pairHashRef}{'set1'}, ${$pairHashRef}{'set2'}, 
					      $n1pAllRef, $np1AllRef);

	    push @cooccurrences1List, $cooccurrences1Ref;
	    push @cooccurrences2List, $cooccurrences2Ref;
	}
    }
    else {
	#get total co-occurrences and total unique cuis
	$totalCooccurrences = $self->_getNpp_DB();

	#get npp, the number of unique cuis
	#TODO, query is slightly wrong. If the there are cuis that occur in the second position ONLY this will be wrong. I need to merge the CUI 1 and CUI2 tables then select distinct elements
	$totalUniqueCuis = shift @{$assocDB_G->selectcol_arrayref("SELECT COUNT(cui_1) FROM (SELECT DISTINCT cui_1 FROM N_11) AS names")};

	#TODO, check this with MWA now ...will need to code it
	#get co-occurrence data for each pair hash
	foreach my $pairHashRef(@{$pairHashListRef}) {
	    (my $cooccurrences1Ref, my $cooccurrences2Ref) = $self
		->_getCUICooccurrences_DB(${$pairHashRef}{'set1'}, ${$pairHashRef}{'set2'});
	    push @cooccurrences1List, $cooccurrences1Ref;
	    push @cooccurrences2List, $cooccurrences2Ref;
	}
    }

    return (\@cooccurrences1List, \@cooccurrences2List, $totalCooccurrences, $totalUniqueCuis);
}


# computes the observed co-occurrences for all combinations of the cuis passed in
# doing this in a single function makes it so all values can be computed with a 
# single pass of the input file, making execution time much faster
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#  output: $n1pAllRef <- a ref to a hash of hashes that contains co-occurence 
#                        data organized as:
#                        matrix{leadingCUI}{trailingCUI} = cooccurrencecount
#          $np1AllRef <- a ref to a hash of hashes that contains co-occurence 
#                        data organized as:
#                        matrix{trailingCUI}{leadingCUI} = cooccurrencecount
#          $cooccurrenceCount <- the total number of co-occurrences in 
#                                the dataset
#          $numUniquCuis <- the number of unique cuis in the dataset
sub _getObserved_matrix_Linking {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;

    #convert cui arrays to hashes, makes looping thru
    # the file faster
    my %cuis1 = ();
    foreach my $cui(@{$cuis1Ref}) {
	$cuis1{$cui} = 1;
    }
    my %cuis2 = ();
    foreach my $cui(@{$cuis2Ref}) {
	$cuis2{$cui} = 1;
    }

    #get stats
    my %n1pAll = ();
    my %np1All = ();
    my %uniqueCuis = ();
    my $cooccurrenceCount = 0;
    open IN, $matrix_G or die "Cannot open matrix_G for input: $matrix_G\n";
    while (my $line = <IN>) {
	#get cuis and value fro mthe line
	chomp $line;
	my ($cui1, $cui2, $num) = split /\t/, $line;

	#update unique cui lists
	$uniqueCuis{$cui1} = 1;
	$uniqueCuis{$cui2} = 1;

	#update co-occurrence count
	$cooccurrenceCount += $num;

	#update n1pAll and np1All. These just record data
	# so we record any possible co-occurrence that matters
	# with or without order mattering so just check
	# if a CUI of interest is anywhere on the line
	if (exists $cuis1{$cui1} || exists $cuis2{$cui2} 
	    || exists $cuis1{$cui2} || exists $cuis2{$cui1}) {

	    #update n1pAll
	    #create n1p{$cui1} hash if needed
	    if (!defined $n1pAll{$cui1}) {
		my %newHash = ();
		$n1pAll{$cui1} = \%newHash;
	    }

	    #add cui2 and value
	    ${$n1pAll{$cui1}}{$cui2} = $num;

	    #update np1All
	    #create np1{$cui2} hash if needed
	    if (!defined $np1All{$cui2}) {
		my %newHash = ();
		$np1All{$cui2} = \%newHash;
	    }

	    #add cui1 and value
	    ${$np1All{$cui2}}{$cui1} = $num;

	}
    }
    close IN;

    #return the observed values
    return (\%n1pAll, \%np1All, $cooccurrenceCount, (scalar keys %uniqueCuis));
}


# Gets hashes of CUIs that co-occurr with the sets of cuis1 and cuis 2 using
# a matrix. This is the first step in computing linking term associations
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
#          $n1pAllRef <- a ref to a hash of hashes that contains co-occurence 
#                        data organized as:
#                        matrix{leadingCUI}{trailingCUI} = cooccurrencecount
#          $np1AllRef <- a ref to a hash of hashes that contains co-occurence 
#                        data organized as:
#                        matrix{trailingCUI}{leadingCUI} = cooccurrencecount
# output: \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 1, 
#                             values are the co-occurrence count
#         \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 2, 
#                             values are the co-occurrence count
sub _getCUICooccurrences_matrix {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    my $n1pAllRef = shift;
    my $np1AllRef = shift;

    #error checking
    my $function = "_getCUICooccurrences"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #get lists of explicitly co-occurring CUIs for each concept
    #add trailing cui co-occurrences to cui1Data
    my %cooccurrences1;
    foreach my $cui1 (@{$cuis1Ref}){
	if (defined ${$n1pAllRef}{$cui1}) {
	    foreach my $cui2 (keys %{${$n1pAllRef}{$cui1}}) {
		$cooccurrences1{$cui2} = ${${$n1pAllRef}{$cui1}}{$cui2};
	    }
	}
    }

    #add leading cui co-occurrences to cui2Data
    my %cooccurrences2;
    foreach my $cui2 (@{$cuis2Ref}){
	if (defined ${$np1AllRef}{$cui2}) {
	    foreach my $cui1 (keys %{${$np1AllRef}{$cui2}}) {
		$cooccurrences2{$cui1} = ${${$np1AllRef}{$cui2}}{$cui1};
	    }
	}
    }
    
    #add more CUIs if order doesn't matter
    if ($noOrder_G) {
	#add leading cui co-occurrences to cui1Data
	foreach my $cui1 (@{$cuis1Ref}){
	    if (defined ${$np1AllRef}{$cui1}) {
		foreach my $cui2 (keys %{${$np1AllRef}{$cui1}}) {
		    $cooccurrences1{$cui2} = ${${$np1AllRef}{$cui1}}{$cui2};
		}
	    }
	}
	#add trailing cui co-occurrences to cui2Data
	foreach my $cui2 (@{$cuis2Ref}){
	    if (defined ${$n1pAllRef}{$cui2}) {
		foreach my $cui1 (keys %{${$n1pAllRef}{$cui2}}) {
		    $cooccurrences2{$cui1} = ${${$n1pAllRef}{$cui2}}{$cui1};
		}
	    }
	}
    }
	
    return (\%cooccurrences1, \%cooccurrences2);
}


# Gets hashes of CUIs that co-occurr with the sets of cuis1 and cuis 2 using
# a database. This is the first step in computing linking term associations
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
# output: \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 1, 
#                             values are 1
#         \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 2, 
#                             values are 1
sub _getCUICooccurrences_DB {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    
    #error checking
    my $function = "_getCUICooccurrences_DB"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #get hashes of co-occurring CUIs
    my %cooccurrences1 = ();
    my %cooccurrences2 = ();

    #query DB to get cuis, where concept 1 is the leading cui
    my $firstCui = shift @{$cuis1Ref};
    my $query = "SELECT N_11.cui_2 FROM N_11 WHERE (N_11.cui_1 = '$firstCui' ";
    foreach my $cui (@{$cuis1Ref}) {
	$query .= "OR N_11.cui_1 = '$cui' ";
    }
    $query .= ") AND N_11.n_11 > 0;";
    my @cuis = @{$assocDB_G->selectcol_arrayref($query)};
    unshift @{$cuis1Ref}, $firstCui;

    #turn CUIs into a hash of cui1's cooccurrences
    foreach my $cui (@cuis) {
	$cooccurrences1{$cui} = 1;
    }

    #query DB to get cuis, where concept 2 is the trailing cui
    $firstCui = shift @{$cuis2Ref};
    $query =  "SELECT N_11.cui_1 FROM N_11 WHERE (N_11.cui_2 = '$firstCui' ";
    foreach my $cui (@{$cuis2Ref}) {
	$query .= "OR N_11.cui_2 = '$cui' ";
    }
    $query .= ") AND N_11.n_11 > 0;";
    @cuis = @{$assocDB_G->selectcol_arrayref($query)};
    unshift @{$cuis2Ref}, $firstCui;

    #turn CUIs into a hash of cui2's co-occurrences
    foreach my $cui (@cuis) {
	$cooccurrences2{$cui} = 1;
    }

    #add additional cuis if order doesn't matter
    if($noOrder_G) {
	#get cuis, where concept 1 is the trailing cui
	$firstCui = shift @{$cuis1Ref};
	my $query = "SELECT N_11.cui_1 FROM N_11 WHERE (N_11.cui_2 = '$firstCui' ";
	foreach my $cui (@{$cuis1Ref}) {
	    $query .= "OR N_11.cui_2 = '$cui' ";
	}
	$query .= ") AND N_11.n_11 > 0;";
	@cuis = @{$assocDB_G->selectcol_arrayref($query)};
	unshift @{$cuis1Ref}, $firstCui;

	#add cuis to the hash of cui1's co-occurrences
	foreach my $cui (@cuis) {
	    $cooccurrences1{$cui} = 1;
	}

	#get cuis, where concept 2 is the leading cui
	$firstCui = shift @{$cuis2Ref};
	$query =  "SELECT N_11.cui_2 FROM N_11 WHERE (N_11.cui_1 = '$firstCui' ";
	foreach my $cui (@{$cuis2Ref}) {
	    $query .= "OR N_11.cui_1 = '$cui' ";
	}
	$query .= ") AND N_11.n_11 > 0;";
	@cuis = @{$assocDB_G->selectcol_arrayref($query)};
	unshift @{$cuis2Ref}, $firstCui;

	#add cuis to the hash of cui2's co-occurrences
	foreach my $cui (@cuis) {
	    $cooccurrences2{$cui} = 1;
	}
    }

    #return the cui co-occurrences
    return (\%cooccurrences1, \%cooccurrences2);
}


=comment
# Gets hashes of CUIs that co-occurr with the sets of cuis1 and cuis 2 using
# a database. This is the first step in computing linking term associations
#  input : $cuis1Ref <- ref to an array of the first cuis in a set of cui pairs
#          $cuis2Ref <- ref to an array of the second cuis in a set of cui pairs
# output: \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 1, 
#                             values are 1
#         \%cooccurrences1 <- hash ref, keys are co-occurring cuis with cui 2, 
#                             values are 1
sub _getCUICooccurrences_DB {
    #grab parameters
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    
    #error checking
    my $function = "_getCUICooccurrences_DB"; 
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #get hashes of co-occurring CUIs
    my %cooccurrences1 = ();
    my %cooccurrences2 = ();

    #query DB to get cuis, where concept 1 is the leading cui
    my $firstCui = shift @{$cuis1Ref};
    my $query = "SELECT * FROM N_11 WHERE (N_11.cui_1 = '$firstCui' ";
    foreach my $cui (@{$cuis1Ref}) {
	$query .= "OR N_11.cui_1 = '$cui' ";
    }
    $query .= ") AND N_11.n_11 > 0;";
    my $sth = $assocDB_G->prepare($query);
    $sth->execute();   
    my @rows = @{$sth->fetchall_arrayref()};
    unshift @{$cuis1Ref}, $firstCui;

    #turn CUIs into a hash of cui1's cooccurrences
    foreach my $rowRef (@rows) {
	print STDERR join(' ', @{$rowRef})."\n";
    }
    #TODO - this is done, it works ... it gets back the whole relevant table. Now fill up as needed.


    my @cuis;
    #query DB to get cuis, where concept 2 is the trailing cui
    $firstCui = shift @{$cuis2Ref};
    $query =  "SELECT N_11.cui_1 FROM N_11 WHERE (N_11.cui_2 = '$firstCui' ";
    foreach my $cui (@{$cuis2Ref}) {
	$query .= "OR N_11.cui_2 = '$cui' ";
    }
    $query .= ") AND N_11.n_11 > 0;";
    @cuis = @{$assocDB_G->selectcol_arrayref($query)};
    unshift @{$cuis2Ref}, $firstCui;

    #turn CUIs into a hash of cui2's co-occurrences
    foreach my $cui (@cuis) {
	$cooccurrences2{$cui} = 1;
    }

    #add additional cuis if order doesn't matter
    if($noOrder_G) {
	#get cuis, where concept 1 is the trailing cui
	$firstCui = shift @{$cuis1Ref};
	my $query = "SELECT N_11.cui_1 FROM N_11 WHERE (N_11.cui_2 = '$firstCui' ";
	foreach my $cui (@{$cuis1Ref}) {
	    $query .= "OR N_11.cui_2 = '$cui' ";
	}
	$query .= ") AND N_11.n_11 > 0;";
	@cuis = @{$assocDB_G->selectcol_arrayref($query)};
	unshift @{$cuis1Ref}, $firstCui;

	#add cuis to the hash of cui1's co-occurrences
	foreach my $cui (@cuis) {
	    $cooccurrences1{$cui} = 1;
	}

	#get cuis, where concept 2 is the leading cui
	$firstCui = shift @{$cuis2Ref};
	$query =  "SELECT N_11.cui_2 FROM N_11 WHERE (N_11.cui_1 = '$firstCui' ";
	foreach my $cui (@{$cuis2Ref}) {
	    $query .= "OR N_11.cui_1 = '$cui' ";
	}
	$query .= ") AND N_11.n_11 > 0;";
	@cuis = @{$assocDB_G->selectcol_arrayref($query)};
	unshift @{$cuis2Ref}, $firstCui;

	#add cuis to the hash of cui2's co-occurrences
	foreach my $cui (@cuis) {
	    $cooccurrences2{$cui} = 1;
	}
    }

    #return the cui co-occurrences
    return (\%cooccurrences1, \%cooccurrences2);
}
=cut

1;

__END__

=head1 NAME

UMLS::Association::StatFinder - provides the statistical association information 
of the concept pairs in the UMLS 

=head1 DESCRIPTION
    For more information please see the UMLS::Association.pm documentation.

=head1 SYNOPSIS

use UMLS::Association::StatFinder;
use UMLS::Association::ErrorHandler;

%params = ();

$statfinder = UMLS::Association::StatFinder->new(\%params);
die "Unable to create UMLS::Association::StatFinder object.\n" if(!$statfinder);

my $cui1 = C0018563;   
my $cui2 = C0446516; 

# calculate measure assocation
my $measure = "ll"; 
my $score = $statfinder->calculateStatistic($cui1, $cui2, $measure); 

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

    perl Makefile.PL PREFIX=/home/bridget

    It is possible to modify other parameters during installation. The
    details of these can be found in the ExtUtils::MakeMaker
    documentation. However, it is highly recommended not messing around
    with other parameters, unless you know what you're doing.

    =head1 SEE ALSO

    <http://tech.groups.yahoo.com/group/umls-similarity/>

    =head1 AUTHOR

    Bridget T McInnes <bmcinnes@vcu.edu>
    Andriy Y. Mulyar  <andriy.mulyar@gmail.com>
    Alexander D. McQuilkin <alexmcq99@yahoo.com>
    Alex McQuilken <alexmcq99@yahoo.com>
    Sam Henry <henryst@vcu.edu>

    =head1 COPYRIGHT

    Copyright (c) 2015
    Bridget T. McInnes, Virginia Commonwealth University
    btmcinnes at vcu.edu

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
