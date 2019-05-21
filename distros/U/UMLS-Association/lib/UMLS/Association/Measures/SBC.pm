#UMLS::Association::Measures::SBC
#  Computes the shared B to C set association (SBC) between two sets of terms
#  
#  SBC works by first finding the set of linking terms for the A terms
#  and C terms to form sets B_A and B_C. It then finds the overlap 
#  between these sets, the set of shared B terms, B_S. It then finds 
#  the dirst association between sets B_S and C 
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;

package UMLS::Association::Measures::SBC;

# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using shared B to C association (SBC)
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

    #convert the pairHashes to linking term pairHashes
    my $linkingTermsPairHashListRef = &UMLS::Association::StatFinder::getLinkingTermsPairHashList(
	$pairHashListRef, $matrixFileName, $noOrder);
    
    #find the overlapping linking terms, and set
    # the pairHashes to shared B (overlapping linking terms)
    # to C (original set 2 of the pair hash)
    my @sharedBToCPairHashList = ();
    my $start = time();	
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
       
        #grab terms from sets 1 and 2 of this pair hash
	my %set1Terms = ();
	foreach my $cui (@{${${$linkingTermsPairHashListRef}[$i]}{'set1'}}) {
	    $set1Terms{$cui} = 1;
	}

        #find the overlapping B terms and save as an array
	my @sharedBTerms = ();
	foreach my $cui (@{${${$linkingTermsPairHashListRef}[$i]}{'set2'}}) {
	    if (exists $set1Terms{$cui}) {
		push @sharedBTerms, $cui;
	    }
        }

	#create and save the pair hash
	my %pairHash = ();
	$pairHash{'set1'} = \@sharedBTerms;
	$pairHash{'set2'} = ${${$pairHashListRef}[$i]}{'set2'};
	push @sharedBToCPairHashList, \%pairHash;    
    }

    #Compute and return the direct association for shared 
    # B to C set associations
    return &UMLS::Association::Measures::Direct::getStats(\@sharedBToCPairHashList, $matrixFileName, $noOrder);
}


1;
