#UMLS::Association::Measures::LTA
#  Computes the Linking Term Association (LTA) between two sets of terms.
#  
#  LTA works by first finding the sets of linking terms for the A terms
#  and C terms to form sets B_A and B_C. It then uses these sets to 
#  compute N11 - the count of unique shared linking terms, N1P, the count
#  of unique terms in B_A, NP1, the count of unique terms in B_C, and NPP, 
#  the total number of unique terms in the dataset (the vocabulary size).  
#  The association is then found using these counts.
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;
package UMLS::Association::Measures::LTA;

# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using linking term association (LTA)
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
    
    # get the linking term info
    my ($n1pRef, $np1Ref, $npp, $matrixRef, $linkingPairHashListRef) = &UMLS::Association::StatFinder::getLinkingTermsPairHashList($pairHashListRef, $matrixFileName, $noOrder, 1, 1);
    
    #compute n11,n1p,np1, and npp for all pair hashes
    # and place into the statsList, a parallel array
    # of stats for that pair hash
    my @statsList = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	my $pairHashRef = ${$pairHashListRef}[$i];
	my $linkingPairHashRef = ${$linkingPairHashListRef}[$i];
	push @statsList, &_statsFromAllLinkingInfo($pairHashRef, $linkingPairHashRef, $npp);
    }

    #return the stats list, an array of array refs
    # each array ref contains four values:
    # n11, n1p, np1, and npp for the pair hash at
    # the corresponding index in the pairHashList
    return \@statsList;
}


# Gets stats (n11,n1p,np1,npp) for a single pairHash using the 
# precomputed linkingPairHash (from StatFinder::getLinkingTermsPairHashList)
# Input:
#  $pairHashListRef - ref to pairHash
#  $linkingPairHashRef - ref to the linking terms pair hash for this pairHash
#  $npp -  npp for the subGraphRef
# Output:
#   \@stats - ref to an array of (n11,n1p,np1,npp)
sub _statsFromAllLinkingInfo {
    my $pairHashRef = shift;
    my $linkingPairHashRef = shift;
    my $npp = shift;

##################################
############## calculate n11
    #find n11, the count of shared linking terms
    # NOTE: noorder is taken care of when constructing the linking set
    my $n11 = 0;
    #Find the B to C linking terms
    my %bToCLinkingTerms = ();
    foreach my $key (@{${$linkingPairHashRef}{'set2'}}) {
	$bToCLinkingTerms{$key} = 1;
    }
    #iterate over all A to B terms and increment for each
    # term that is also a B to C shared linking term
    foreach my $key (@{${$linkingPairHashRef}{'set1'}}) {
        if (defined $bToCLinkingTerms{$key}) {
	    $n11++;
	}
    }

##################################
############## calculate n1p and np1
    my $n1p = scalar @{${$linkingPairHashRef}{'set1'}};
    my $np1 = scalar @{${$linkingPairHashRef}{'set2'}};

############################## 
#pack and return the stats
    my @stats = ($n11, $n1p, $np1, $npp);
    return \@stats;
}

1;

