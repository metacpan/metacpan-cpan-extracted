#UMLS::Association::Measures::Direct
# Computes the association between two sets of terms 
# using Direct association, which is the association 
# between sets A and C using direct co-occurrences
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;

package UMLS::Association::Measures::Direct;


# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using direct association
# Input:
#  $pairHashListRef - ref to an array of pairHashes
#  $matrixFileName - the fileName of the co-occurrence matrix
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#   \@statsList - ref to an array of \@stats, refs to arrays
#                 containing the ordered values: n11, n1p, np1, npp
#                 for each of the pair hashes. The index of the 
#                 \@statsList corresponds to the index of the pairHash
#                 in the input $pairHashListRef
sub getStats {
    my $pairHashListRef = shift;
    my $matrixFileName = shift;
    my $noOrder = shift;

    #read in the matrix of all values needed for all
    # pair sets in the pair hash list
    my ($matrixRef, $vocabSize) = &UMLS::Association::StatFinder::readInMatrix($pairHashListRef, $matrixFileName);

    #compute n1p,np1, and npp for all values
    my ($n1pRef, $np1Ref, $npp) = &_getAllCounts($matrixRef);

    #compute n11,n1p,np1,npp for all pair hashes
    # and place into the statsList, a parallel array
    # of stats for that pair hash
    my @statsList = ();
    foreach my $pairHashRef (@{$pairHashListRef}) {
	push @statsList, &_statsFromAllCounts($matrixRef, $n1pRef, $np1Ref, $npp, $noOrder, $pairHashRef);
    }

    #return the stats list, an array of array refs
    # each array ref contains four values:
    # n11, n1p, np1, and npp for the pair hash at
    # the corresponding index in the pairHashList
    return \@statsList;
}


# Computes n1p, np1, and npp for every CUI in the subgraph
# Input:
#   $subGraphRef - ref to the subgraph or matrix read in
# Output:
#   \%n1p - ref to a hash{$cui}=n1p for that cui, order enforced
#   \%np1 - ref to a hash{$cui}=np1 for that cui, order enforced
#   $npp - npp for the subGraphRef
sub _getAllCounts {
    my $subGraphRef = shift;

    #find stats by iterating over all keys 
    my %n1p = ();
    my %np1 = ();
    my $npp = 0;
    foreach my $key1 (keys %{$subGraphRef}) {
	foreach my $key2 (keys %{${$subGraphRef}{$key1}}) {
	    #grab the value from the sub graph
	    my $value = ${${$subGraphRef}{$key1}}{$key2};
	    
	    $n1p{$key1} += $value;
	    $np1{$key2} += $value;
	    $npp += $value;
	}
    }

    return \%n1p, \%np1, $npp;
}

# Computes n11, n1p, np1,and npp for the pairHash using
# the allCounts calculated from the _getAllCounts function
# Input:
#   $subGraphRef - ref to the subgraph or matrix read in
#   $n1pRef - ref to a hash{$cui}=n1p for that cui, order enforced
#   $np1Ref - ref to a hash{$cui}=np1 for that cui, order enforced
#   $npp - npp for the subGraphRef
#   $noOrder - 0 if order is enforced, 1 if not
#   $pairHashRef - ref to a pairHash
# Output:
#   \@stats - ref to an array of (n11,n1p,np1,npp)
sub _statsFromAllCounts {
    my $subGraphRef = shift;
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;
    my $noOrder = shift;
    my $pairHashRef = shift;
  

#NOTE: finding N11 is the bottleneck, but I don't think there is much I can do about it
    #find stats by iterating over all keys 
############ calculate n11
    my $n11 = 0;
    foreach my $key1 (@{${$pairHashRef}{'set1'}}) {
        foreach my $key2 (@{${$pairHashRef}{'set2'}}) {
	   if (defined ${${$subGraphRef}{$key1}}{$key2}) {
		$n11 += ${${$subGraphRef}{$key1}}{$key2};
	    }
	    if ($noOrder && defined ${${$subGraphRef}{$key2}}{$key1}) {
		$n11 += ${${$subGraphRef}{$key2}}{$key1};
	    }
	}
    }

    #remove noorder double counts (nodes pointing at themselves)
    if ($noOrder) {
	foreach my $key1 (@{${$pairHashRef}{'set1'}}) {
	    if (exists ${${$subGraphRef}{$key1}}{$key1}) {
		#remove double counts, only if the key is in key2's set
		foreach my $key2 (@{${$pairHashRef}{'set2'}}) {
		    if ($key1 eq $key2) {
			$n11 -= ${${$subGraphRef}{$key1}}{$key1};
		    }
		}
	    }
	}
    }
    
##################################
############## calculate n1p
    my $n1p = 0;
    foreach my $key1 (@{${$pairHashRef}{'set1'}}) {
	#calculate n1p
	if (defined ${$n1pRef}{$key1}) {
	    $n1p += ${$n1pRef}{$key1};
        }
	if ($noOrder && defined ${$np1Ref}{$key1}) {
	    $n1p += ${$np1Ref}{$key1};   
	}
    }
    #remove noorder double counts
    if ($noOrder) {
	foreach my $key1 (@{${$pairHashRef}{'set1'}}) {
	    foreach my $key2 (@{${$pairHashRef}{'set1'}}) {
		if (defined ${${$subGraphRef}{$key1}}{$key2}) {
		    $n1p -= ${${$subGraphRef}{$key1}}{$key2};
		}
	    }
	}
    }

#####################################
############## #calculate np1
    my $np1 = 0;
    foreach my $key2 (@{${$pairHashRef}{'set2'}}) {
        #calculate np1
	if (defined ${$np1Ref}{$key2}) {
	    $np1 += ${$np1Ref}{$key2};
        }
	if ($noOrder && defined ${$n1pRef}{$key2}) {
	    $np1 += ${$n1pRef}{$key2};
	}
    }
    #remove noorder double counts
    if ($noOrder) {
	foreach my $key1 (@{${$pairHashRef}{'set2'}}) {
	    foreach my $key2 (@{${$pairHashRef}{'set2'}}) {
		if (defined ${${$subGraphRef}{$key1}}{$key2}) {
		    $np1 -= ${${$subGraphRef}{$key1}}{$key2};
		}
	    }
	}
    }
##############################
    
    #pack and return the stats 
    my @stats = ($n11, $n1p, $np1, $npp);
    return \@stats;
}

1;
