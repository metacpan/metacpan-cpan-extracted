#UMLS::Association::Measures::LSA
# Computes the Linking Set Association (LSA) between two sets of terms.
#
# LSA works by first finding the set of linking terms for the A terms
# and C terms to form sets B_A and B_C. It then finds the direct 
# association between sets B_A and B_C
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;

package UMLS::Association::Measures::LSA;

# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using linking set association (LSA)
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

    #get the shared terms pair hash list
    my $newPairHashListRef = &UMLS::Association::StatFinder::getLinkingTermsPairHashList($pairHashListRef, $matrixFileName, $noOrder);

    #Compute and return the direct association for shared 
    # B to C set associations
    return &UMLS::Association::Measures::Direct::getStats($newPairHashListRef, $matrixFileName, $noOrder);
}





1;
