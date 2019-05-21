#UMLS::Association
#
# Perl module for scoring the semantic association of terms in the Unified
# Medical Language System (UMLS).
#
# Copyright (c) 2015
#
# Sam Henry, Virginia Commonwealth University
# henryst at vcu.edu
#
# Bridget McInnes, Virginia Commonwealth University
# btmcinnes at vcu.edu
#
# Keith Herbert, Virginia Commonwealth University
# herbertkb at vcu.edu
#
# Alexander D. McQuilkin, Virginia Commonwealth University 
# alexmcq99 at yahoo.com
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
use lib '/home/henryst/UMLS-Association/lib';

package UMLS::Association::StatFinder;

use Fcntl;
use strict;
use warnings;
use bytes;
use File::Spec;

use UMLS::Association::Measures::Direct;
use UMLS::Association::Measures::LTA;
use UMLS::Association::Measures::MWA;
use UMLS::Association::Measures::SBC;
use UMLS::Association::Measures::LSA;
use UMLS::Association::Measures::WSA;

#  error handling variables
my $errorhandler = "";
my $pkg = "UMLS::Association::StatFinder";

#NOTE: every global variable is followed by a _G with the 
# exception of debug error handler, and constants which are all caps
#  global variables
my $debug     = 0; #in debug mode or not

#global options variables
my $lta_G = 0; #1 or 0 is using lta or not
my $mwa_G = 0; #1 or 0 if using mwa or not
my $lsa_G = 0; #1 or 0 if using lsa or not
my $sbc_G = 0; #1 or 0 if using sbc or not
my $wsa_G = 0; #1 or 0 if using wsa or not
my $noOrder_G = 0; #1 or 0 if noOrder is enabled or not
my $matrix_G = 0; #matrix file name is using a matrix file rather than DB   
my $params_G; #stores all params (if needed)

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
    $lsa_G = $params{'lsa'};
    $sbc_G = $params{'sbc'};
    $wsa_G = $params{'wsa'};
    $noOrder_G = $params{'noorder'};
    $matrix_G = $params{'matrix'};
    $params_G = $paramsRef;
    
    #error checking
    my $function = "_initialize";
    &_debug($function);
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    if (!defined $matrix_G) {
	die ("ERROR: co-occurrence matrix must be defined\n");
    }
}

sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Association::StatFinder::$function\n"; }
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

    #calculate n11, n1p, np1, npp
    my $allStatsRef = -1;
    if ($lta_G) {
        $allStatsRef = &UMLS::Association::Measures::LTA::getStats($pairHashListRef, $matrix_G, $noOrder_G);
    }
    elsif ($mwa_G) {
        $allStatsRef = &UMLS::Association::Measures::MWA::getStats($pairHashListRef, $matrix_G, $noOrder_G);
    }
    elsif ($lsa_G) {
        $allStatsRef = &UMLS::Association::Measures::LSA::getStats($pairHashListRef, $matrix_G, $noOrder_G);
    }
    elsif ($sbc_G) {
	$allStatsRef = &UMLS::Association::Measures::SBC::getStats($pairHashListRef, $matrix_G, $noOrder_G);
    }
    elsif ($wsa_G) {
        $allStatsRef = &UMLS::Association::Measures::WSA::getStats($pairHashListRef, $matrix_G, $noOrder_G, $params_G);
    }
    else {
        $allStatsRef = &UMLS::Association::Measures::Direct::getStats($pairHashListRef, $matrix_G, $noOrder_G);
    }

    #return a reference to a list of stats for each pairHash
    return $allStatsRef;
}

####NOTE: fine for direct, LTA, and MWA
#NOT for SBC and LSA
#Reads in the matrix values that are needed
# anything not in the pairHashListRef is counted
# towards a universal source and/or universal sink node
# Input:  $pairHashListRef - reference to the pairHashList
#         $matrixFileName - fileName of the matrix
# Output: \%matrix - matrix as read in. Matrix is stored
#              as a hash of hashes, where hash{node} 
#              contains all a hash of all outgoing edges
#              from that node, such that:
#              ${$hash{$source}}{$target} = $weight
sub readInMatrix {
    my $pairHashListRef = shift;
    my $matrixFileName = shift;

    #convert the pairhash list to a list of leading and 
    # trailing cuis
    my %leadingCuis = ();
    my %trailingCuis = ();
    my %allCuis = ();
    foreach my $pairHashRef(@{$pairHashListRef}) {
        foreach my $cui(@{${$pairHashRef}{'set1'}}) {
            $leadingCuis{$cui} = 1;
	    $allCuis{$cui} = 1;
        }
        foreach my $cui(@{${$pairHashRef}{'set2'}}) {
            $trailingCuis{$cui} = 1;
	    $allCuis{$cui} = 1;
        }
    }
    
    #Initalize the matrix, and ensure there is a source node
    my %matrix = ();
    my %sourceHash = ();
    $matrix{'source'} = \%sourceHash;
    ${$matrix{'source'}}{'sink'} = 0;
    
    #also get a count of vocabulary when reading
    my %vocabulary = ();

#### Read in matrix, longest execution time, so keep this fast
    #read in all matrix values associated with all
    # cuis needed. For co-occurrences outside of the 
    # needed set, created a universal source and sink
    open IN, $matrix_G or die "Cannot open $matrix_G for input: $!\n";
    while (my $line = <IN>) {
	#get cuis and value from the line
	chomp $line;
	my ($cui1, $cui2, $num) = split /\t/, $line;
    
	#update the vocabulary
        $vocabulary{$cui1} = 1;
	$vocabulary{$cui2} = 1;

	#if cui1 or cui2 are not cuis of interest, replace
	# them with universal source/sink
	if (!exists $allCuis{$cui1} && !exists $allCuis{$cui2}) {
	    $cui1 = 'source';
	    $cui2 = 'sink';	    
	}

	#record the co-occurrence as a directed weighted
	# weighted edge list ${hash{n1}}{n2}=$val;
	if (!exists $matrix{$cui1}) {
	    my %emptyHash = ();
	    $matrix{$cui1} = \%emptyHash;
	}
	${$matrix{$cui1}}{$cui2} += $num;
    }
    close IN;
##### END reading in matrix

    return \%matrix, (scalar keys %vocabulary); 
}


#gets a new pair hash list, that is the linking terms of the
# original pair hashes
# Input:
#  $pairHashListRef - ref to an array of pairHashes
#  $matrixFileName - the fileName of the co-occurrence matrix
#  $noOrder - 1 if order is enforced, 0 if not
#  $recordStats - 1 if stats are to be recorded (n1p for all, np1 for all, npp)
#  $recordCounts - 1 if unique counts are to be used rather than co-occurrence
#                  counts (i.e. npp = vocab size, n1p = count of co-occurring 
#                  terms rather than npp = all co-occurrences, n1p = sum of 
#                  co-occurrences for a term).
# Output:
#  output varies whether or not stats are recorded.
#  If stats are not recorded:
#     \@newPairHashList - an array of pair hashes, where each pairHash is
#         the linking terms, B_A and B_C of the original pair hash at that
#         index (order/NoOrder is accounted for in this list)
#  If stats are recorded:
#     \%n1p - n1p{cui} = n1p for that term (order enforced
#     \%np1 - np1{cui} = np1 for that term (order enforced
#     $npp - npp for this dataset (term counts or co-occurrence counts)
#     \%matrix - the co-occurrence matrix for all A, B_A, B_C, and C terms
#        this is essentially all possibly N11's (order enforced)
#    \@newPairHashList - same as above
#NOTE: LSA and SBC do not need anything but newPairHashList
#      LTA needs npp (with counts), newPairHashList
#      MWA needs n1p, np1, npp, matrix, newPairHashList
#   ...I kept everything in this method because calculating the newPairHashList
#     of linking terms is fairly complicated and I didn't want to replicate code
#    to make bug fixes/updates easier. For minor speed iprovements, and 
#    understandability, we could create 3 seperate methods, one for each of the
#    required sets of info needed
sub getLinkingTermsPairHashList {
    my $pairHashListRef = shift;
    my $matrixFileName = shift;
    my $noOrder = shift;
    my $recordStats = shift;
    my $recordCounts = shift;

#####################################
#create data structures to make line reading fast
#####################################
    my %allCuis = (); #a hash of all cuis we need to grab hash{cui}=1
    my %set1Cuis = (); #hash{cui} = list of pairHash indeces containing the cui in set1
    my %set2Cuis = (); #hash{cui} = list of pairHash indeces containing the cui in set2
    my @newPairHashList = (); #the linking term pairHashList
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	my $pairHashRef = ${$pairHashListRef}[$i];

	#initialize set1 index
        my %set1Hash = ();
	foreach my $cui(@{${$pairHashRef}{'set1'}}) {
	    if (!exists $set1Cuis{$cui}) {
		my @emptyArray = ();
		$set1Cuis{$cui} = \@emptyArray;
		$allCuis{$cui} = 1;
	    }
	    push @{$set1Cuis{$cui}}, $i;    
	}
	#initialize set2 index
        my %set2Hash = ();
	foreach my $cui(@{${$pairHashRef}{'set2'}}) {
	    if (!exists $set2Cuis{$cui}) {
		my @emptyArray = ();
		$set2Cuis{$cui} = \@emptyArray;
		$allCuis{$cui}=1;
	    }
	    push @{$set2Cuis{$cui}}, $i;    
	}

	#initialize the parallel linking set pairHash
	my %newPairHash = ();
	my @set1Array = ();
	$newPairHash{'set1'} = \@set1Array;
	my @set2Array = ();
	$newPairHash{'set2'} = \@set2Array;
	push @newPairHashList, \%newPairHash;
    }

##################################
##### Initialize values for recording stats while reading the matrix
##################################
    my %n1p = ();
    my %np1 = ();
    my $npp = 0;
    my %vocab = ();
    my %matrix = ();
    # We want to make sure that n1p and np1 have a value for 
    # all set1 and set2 terms, so initialize to 0
    # ...and we want to do this here, so that it is only done once
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	my $pairHashRef = ${$pairHashListRef}[$i];
	foreach my $cui(@{${$pairHashRef}{'set1'}}) {
	    $n1p{$cui}=0
	}
	foreach my $cui(@{${$pairHashRef}{'set2'}}) {
	    $np1{$cui}=0;
	}
    }

####################################
#### File Read in, where most execution time is spent, keep this fast
####################################
    #read in the linking sets from the matrix
    open IN, $matrixFileName or die "Cannot open $matrixFileName for input: $!\n";
    my @vals;
    while (my $line = <IN>) {
        #get cuis and value from the line
        @vals = (split /\t/, $line);
	#$cui1 = $vals[0]
	#$cui2 = $vals[1]
	#$num  = $vals[2]
	chomp $vals[2];

        #update npp and vocab if needed
	if ($recordStats) {
	    if ($recordCounts) {
		$vals[2] = 1;
		$vocab{$vals[0]} = 1;
		$vocab{$vals[1]} = 1;
	    }
	    $npp += $vals[2];
	}

	#If either of the CUIs are in the pairHashList, then record
	# their co-occurrences, and additional stats if needed
	if (exists $allCuis{$vals[0]} || exists $allCuis{$vals[1]}) {
            #add any cui1 linking terms if needed
	    if (exists $set1Cuis{$vals[0]}) {
		#cui1 is in one more or more set1s
		# add to the linking term (cui2) to each pairhash
		# that cui1 is in
	        foreach my $index (@{$set1Cuis{$vals[0]}}) {
		    push @{${$newPairHashList[$index]}{'set1'}}, $vals[1];
		}
	    }

	    #add any cui2 linking terms if needed
	    if (exists $set2Cuis{$vals[1]}) {
		#cui2 is in one more or more set2s
		# add to the linking term (cui1) to each pairhash
		# that cui2 is in
		foreach my $index (@{$set2Cuis{$vals[1]}}) {
		    push @{${$newPairHashList[$index]}{'set2'}}, $vals[0];
		}
	    }
   
	    #record n1p and np1 and npp if needed
	    if ($recordStats) {
	        #n1p and np1 are recorded for MWA only
		$n1p{$vals[0]} += $vals[2];
		$np1{$vals[1]} += $vals[2];

		#The matrix must be recorded to calculate MWA
		if (exists $set1Cuis{$vals[0]} || exists $set2Cuis{$vals[1]}) {
		    if (!defined $matrix{$vals[0]}) {
			my %emptyHash = ();
			$matrix{$vals[0]} = \%emptyHash;
		    }
		    ${$matrix{$vals[0]}}{$vals[1]} = $vals[2];
		}
	    }      

	    #add cuis if order doesnt matter
	    if ($noOrder) {
	        #NOTE: this is the same as above, but with cui1 
		# and cui2 swapped. I didn't make this a seperate
		# method becuase method calls are slow, and
		# iterating thru lines should be fast
		my $temp = $vals[0];
		$vals[0] = $vals[1];
		$vals[1] = $temp;
		# ...literally copy and paste below
		
		#add any cui1 linking terms if needed
		if (exists $set1Cuis{$vals[0]}) {
		    #cui1 is in one more or more set1s
		    # add to the linking term (cui2) to each pairhash
		    # that cui1 is in
		    foreach my $index (@{$set1Cuis{$vals[0]}}) {
			push @{${$newPairHashList[$index]}{'set1'}}, $vals[1];
		    }
		}

		#add any cui2 linking terms if needed
		if (exists $set2Cuis{$vals[1]}) {
		    #cui2 is in one more or more set2s
		    # add to the linking term (cui1) to each pairhash
		    # that cui2 is in
		    foreach my $index (@{$set2Cuis{$vals[1]}}) {
			push @{${$newPairHashList[$index]}{'set2'}}, $vals[0];
		    }
		}
	    }	
	}
    }
###### DONE reading in the file and constructing linking term sets

#################################
#   Remove Duplicates
##################################
    #due to how cuis are added to the pair hashes 
    # it is possible to have duplicate cuis in each
    # remove any duplicates
    for (my $i = 0; $i < scalar @newPairHashList; $i++) {
	my $set1Ref = ${$newPairHashList[$i]}{'set1'};
	my $set2Ref = ${$newPairHashList[$i]}{'set2'};

	#remove duplicates from set1
	my %set1 = ();
	foreach my $term (@{$set1Ref}) {
	    $set1{$term} = 1;
	}
	my @set1Terms = keys %set1;
	${$newPairHashList[$i]}{'set1'} = \@set1Terms;
        
	#remove duplicates from set2
	my %set2 = ();
	foreach my $term (@{$set2Ref}) {
	    $set2{$term} = 1;
	}
	my @set2Terms = keys %set2;
	${$newPairHashList[$i]}{'set2'} = \@set2Terms;
    }

#################################
#   Return values
##################################
    #return the pair hash list of linking sets
    if ($recordStats) {
	if ($recordCounts) {
	    $npp = scalar keys %vocab;
	}
	return \%n1p, \%np1, $npp, \%matrix, \@newPairHashList;
    }
    else {
	return \@newPairHashList;
    }
}


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
    Sam Henry, Virginia Commonwealth University
    henrystat vcu.edu

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






