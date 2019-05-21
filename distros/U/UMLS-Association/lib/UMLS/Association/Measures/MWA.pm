#UMLS::Association::Measures::MWA
# Computes the Minimum Weight Association between two sets of terms
#
# MWA works by first finding the sets of linking terms for the A terms 
# and C terms to form stes B_A and B_C. It then uses these sets to 
# compute N1P - the count of co-occurrences with A (same as direct
# association), NP1 - the count of co-occurrences with C (same as direct
# association), NPP - the total count of co-occurrences in the dataset
# (same as direct association), and N11 - the average minimum of A to B 
# and B to C co-occurrences for each A to B to C connection. In other words, 
# to find N11, we find sum A_i to B_j to form ABj and sum B_j to C_k to form 
# BjC. We then take the minimum between ABj and BjC for each Bj and average 
# over all BjC. This imitates the average of minimum information flow between 
# A and C between each shared linking term, Bj. 
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;

package UMLS::Association::Measures::MWA;

# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using minimum weight association (MWA)
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

    #Read in all stats
    my ($n1pRef, $np1Ref, $npp, $matrixRef, $linkingPairHashListRef) = &UMLS::Association::StatFinder::getLinkingTermsPairHashList($pairHashListRef, $matrixFileName, $noOrder, 1, 0);

    #compute stats for each pairHash
    my @statsList = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
        my $pairHashRef = ${$pairHashListRef}[$i];
        my $linkingPairHashRef = ${$linkingPairHashListRef}[$i];

	#get the stats for this pair hash
	push @statsList, &_statsFromAllLinkingInfo($pairHashRef, $linkingPairHashRef, $n1pRef, $np1Ref, $npp, $matrixRef, $noOrder);
    }

    return \@statsList;
}


# Gets stats (n11,n1p,np1,npp) for a single pairHash using the 
# precomputed linkingPairHash (from StatFinder::getLinkingTermsPairHashList)
# Input:
#  $pairHashRef - ref to a pairHash
#  $linkingPairHashRef - ref to the linking terms pair hash for this pairHash
#  $n1pRef - ref to a hash{$cui}=n1p for that cui, order enforced
#  $np1Ref - ref to a hash{$cui}=np1 for that cui, order enforced
#  $npp -  npp for the subGraphRef
#  $subGraphRef -  ref to the subgraph or matrix read in
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#   \@stats - ref to an array of (n11,n1p,np1,npp)
sub _statsFromAllLinkingInfo {
    my $pairHashRef = shift;
    my $linkingPairHashRef = shift;
    my $n1pRef = shift;
    my $np1Ref = shift;
    my $npp = shift;
    my $subGraphRef = shift;
    my $noOrder = shift;

###############################
# Find Shared B Terms
###
    # Find the overlapping (shared) Co-occurrences
    #grab terms from set1
    my %set1Terms = ();
    foreach my $cui (@{${$linkingPairHashRef}{'set1'}}) {
	$set1Terms{$cui} = 1;
    }

    #find the overlapping B terms and save as an array
    my %sharedBTerms = ();
    foreach my $cui (@{${$linkingPairHashRef}{'set2'}}) {
	if (exists $set1Terms{$cui}) {
	    $sharedBTerms{$cui} = 1;
	}
    }

###############################
# Calculate Stats
###
    my $n11 = &_calculateN11($subGraphRef, $pairHashRef, \%sharedBTerms, $noOrder);
    my $n1p = &_calculateN1P($subGraphRef, $pairHashRef, $n1pRef, $noOrder);
    my $np1 = &_calculateNP1($subGraphRef, $pairHashRef, $np1Ref, $noOrder);

    #pack and save the stats for this pair hash
    my @stats = ($n11, $n1p, $np1, $npp);
    return \@stats;	
}


# Calculates N11 for a pairHash
# Input:
#  $subGraphRef -  ref to the subgraph or matrix read in
#  $pairHashRef - ref to a pairHash
#  $sharedCoocRef - ref to hash{cui} = 1 of all shared B terms
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#  $n11 - n11 for this pairHash
sub _calculateN11 {
    #grab params
    my $subGraphRef = shift;
    my $pairHashRef = shift;
    my $sharedCoocRef = shift;
    my $noOrder = shift;
   
    #calculate n11 as the minimum average weight
    my $n11 = 0;
    #my $count = 0;  
    foreach my $bNode (keys %{$sharedCoocRef}) {
	#get the a to b value, which is the sum of all a_i to b
	my $abVal = 0;
	my $counted = 0;
	foreach my $aNode (@{${$pairHashRef}{'set1'}}) {
	    my $counted = 0;
	    if (exists ${${$subGraphRef}{$aNode}}{$bNode}) {
		$abVal += ${${$subGraphRef}{$aNode}}{$bNode};
	    }
	    if ($noOrder) {
		#avoid double counting either self references
		# or overlapping set references
		if ($counted == 0) {
		    #increment for noorder
		    if (exists ${${$subGraphRef}{$bNode}}{$aNode}) {
			$abVal += ${${$subGraphRef}{$bNode}}{$aNode};
		    }
		}
	    }
	}
	
	#get the b to C value, which is the sum of all b to c_i
	my $bcVal = 0;
	foreach my $cNode (@{${$pairHashRef}{'set2'}}) {
  	    my $counted = 0;
            #get the c to b value
	    if (exists ${${$subGraphRef}{$bNode}}{$cNode}) {
		$bcVal += ${${$subGraphRef}{$bNode}}{$cNode};
		$counted = 1;
	    }
	    if ($noOrder) {
		#avoid double counting either self references
		# or overlapping set references
		if ($counted == 0) {
		    if (exists ${${$subGraphRef}{$cNode}}{$bNode}) {
			$bcVal += ${${$subGraphRef}{$cNode}}{$bNode};
		    }
		}
	    }		  
	}

	#get the mininum value and increment n11 
	#find the min
        my $min = $abVal;
	if ($bcVal < $min) {
	    $min = $bcVal;
	}
	#increment n11
	$n11 += $min;
	#$count++;	
    }
  
    #NOTE - can delete count completely from this, but  
    # this re-enable divide by count if you want to compute AMW (then just return n11)
    #if ($count > 0) {
#	$n11 /= $count;
 #   }
    
    return $n11;
}


#calculates N1P for a pairHash
# Input:
#  $subGraphRef -  ref to the subgraph or matrix read in
#  $pairHashRef - ref to a pairHash
#  $n1pRef - ref to a hash{$cui}=n1p for that cui, order enforced
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#   $n1p - n1p for this pairHash
sub _calculateN1P {
    my $subGraphRef = shift;
    my $pairHashRef = shift;
    my $n1pRef = shift;
    my $noOrder = shift;
    
#NOTE - two methods, one if we record n1p, one if we dont
    #calculate $n1p as the sum of all set1 cooc
=comment
    my $n1p = 0;
    #find all a to b co-occurrences
    foreach my $aNode (@{${$pairHashRef}{'set1'}}) {
        foreach my $bNode (keys @{$linkingTermsRef}) {
            $n1p += ${${$subGraphRef}{$aNode}}{$bNode};
	}
    }
=cut
    my $n1p = 0;
    #find all a to b co-occurrences
    foreach my $aNode (@{${$pairHashRef}{'set1'}}) {
	$n1p += ${$n1pRef}{$aNode};
    }
    if ($noOrder) {
	#convert the pair hash array to a hash
	my %set1 = ();
	foreach my $key (@{${$pairHashRef}{'set1'}}) {
	    $set1{$key} = 1;
	}

	#find all b to c co-occurrences
	foreach my $bNode (keys %{$subGraphRef}) {
	    foreach my $aNode (@{${$pairHashRef}{'set1'}}) {		
		#avoid double counting self co-occurrences
		if (exists $set1{$aNode} && exists $set1{$bNode}) { 
		    next;
		}

		#increment n1p 
		if (defined ${${$subGraphRef}{$bNode}}{$aNode}) {
		    $n1p += ${${$subGraphRef}{$bNode}}{$aNode};
		}
	    }
	}
    }

    return $n1p;
}

# Calculates NP1 for a pair hash
# Input:
#  $subGraphRef -  ref to the subgraph or matrix read in
#  $pairHashRef - ref to a pairHash
#  $np1Ref - ref to a hash{$cui}=np1 for that cui, order enforced
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#   \@stats - ref to an array of (n11,n1p,np1,npp)
sub _calculateNP1 {
    my $subGraphRef = shift;
    my $pairHashRef = shift;
    my $np1Ref = shift;
    my $noOrder = shift;
    
#NOTE - two methods, one if we record np1, one if we dont
    #calculate $n1p as the sum of all set2 cooc
=comment
    my $np1 = 0;
    #find all b to c co-occurrences
    foreach my $cNode (@{${$pairHashRef}{'set2'}}) {
        foreach my $bNode (keys @{$linkingTermsRef}) {
            $np1 += ${${$subGraphRef}{$bNode}}{$cNode};
	}
    }
=cut
    my $np1 = 0;
    #find all b to c co-occurrences
    foreach my $cNode (@{${$pairHashRef}{'set2'}}) {
	$np1 += ${$np1Ref}{$cNode};
    }
    if ($noOrder) {
	#convert the pair hash array to a hash
	my %set2 = ();
	foreach my $key (@{${$pairHashRef}{'set2'}}) {
	    $set2{$key} = 1;
	}

	#find all c to b co-occurrences
	foreach my $cNode (@{${$pairHashRef}{'set2'}}) {
	    foreach my $bNode (keys %{${$subGraphRef}{$cNode}}) {

		#avoid double counting pointing to self
		if (exists $set2{$bNode} && exists $set2{$cNode}) { 
		    next;
		}
		
		#increment $np1
		$np1 += ${${$subGraphRef}{$cNode}}{$bNode};
	    }
	}
    }

    return $np1;
}


# Calculates NPP for a subGraph (dataset)
# Input:
#  $subGraphRef -  ref to the subgraph or matrix read in
# Output:
#   $npp - npp for this dataset
sub _calculateNPP {
    my $subGraphRef = shift;

    #calculate npp as the total number of cooccurrences
    my $npp = 0;
    foreach my $key1 (keys %{$subGraphRef}) {
	foreach my $key2 (keys %{${$subGraphRef}{$key1}}) {
	    $npp += ${${$subGraphRef}{$key1}}{$key2};
	}
    }
    return $npp;
}

1;
