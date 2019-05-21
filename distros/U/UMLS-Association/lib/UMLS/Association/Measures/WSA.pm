#UMLS::Association::Measures::WSA
#  Computes the Weighted Set Association (WSA) between two sets of terms.
#  WSA finds the shared linking terms between A and C and weights those 
#  terms based on their association to A. Each B term therefore has a 
#  weight relative to its association with A, which is multiplied by
#  its n11,n1p,np1 to make more associated terms more or less important.
#  The shared B to C set associaiton is then found using the weighted B
#  terms to produce the final association score.
use lib '/home/henryst/UMLS-Association/lib';

use strict;
use warnings;

package UMLS::Association::Measures::WSA;


# Gets stats (n11,n1p,np1,npp) for each pairHash in the pairHashList
# using linking set association (LSA)
# Input:
#  $pairHashListRef - ref to an array of pairHashes
#  $matrixFileName - the fileName of the co-occurrence matrix
#  $noOrder - 1 if order is enforced, 0 if not
#  $paramsRef - the params used to create UMLS::Association which
#               are used when finding the A to B weights
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
    my $paramsRef = shift;

################## STEP 1 #######################
#########  Find the linking (B) terms ###########
#################################################
    #read in the matrix   - FILE READ ONE
    my ($matrixRef, $vocabSize) = &UMLS::Association::StatFinder::readInMatrix($pairHashListRef, $matrixFileName);
     
    #construct A to shared B pair hashListRef
    my @newPairHashList = ();
    my @sharedCoocs = ();
    foreach my $pairHashRef (@{$pairHashListRef}) {
	#get the linking terms and shared linking terms
	#MATRIX PASS 1
	my ($set1CoocRef, $set2CoocRef) = &_getLinkingTermSets(
	    $pairHashRef, $matrixRef, $noOrder);
	my $sharedCoocRef = &_getSharedLinkingTerms(
	    $set1CoocRef, $set2CoocRef);
	my @sharedTerms = keys %{$sharedCoocRef};
	push @sharedCoocs, \@sharedTerms;

        #construct pair hashes
	foreach my $term (keys %{$sharedCoocRef}) {
	    my %newPairHash = ();
	    $newPairHash{'set1'} = ${$pairHashRef}{'set1'};

	    my @set2 = ();
	    push @set2, $term;
	    $newPairHash{'set2'} = \@set2;
	    push @newPairHashList, \%newPairHash;
	}
    }
    #Now we have a new pair hash ref which we will get associations 
    # for. This is setA to each B linking term. It is arranged
    # such that you iterate over the shared terms of each pair hash
    # to get A to each B for that term (e.g. pairHash1 has 10 linking
    # terms, the first 10 pairHashes are A a single B. The B terms
    # are ordered in the sharedCoocs Array of Arrays
    #Doing it in this manner allows for WSA to be calculated in 3 
    # file reads and number pair hashes + 2 passes of the matrix 

################## STEP 2 #######################
#######  Find the Weight of each B term  ########
#################################################
    #get A to shared B associations for all possible linking B terms
    # FILE READ 2 - MATRIX PASS 2 (calculateAssociation_pairHashList)
    my %optionsHash = ();
    if (defined $noOrder && $noOrder > 0) { $optionsHash{'noorder'} = 1; }
    $optionsHash{'measure'} = ${$paramsRef}{'measure'};
    $optionsHash{'matrix'} = ${$paramsRef}{'matrix'};
    my $assoc = UMLS::Association->new(\%optionsHash);
    my $aToBScoresRef = $assoc->_calculateAssociation_pairHashList(\@newPairHashList, ${$paramsRef}{'measure'});

    #Normalize the weights unless told not to
    my $weightIterator = 0;
    my $reweightIterator = 0;
    if (!$paramsRef->{'nonorm'}) {
	#normalize the weights for each pairhash
	for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	    #get all set  B term weights as a hash{term}=weight
	    my %pairWeights = ();
	    foreach my $term (@{$sharedCoocs[$i]}) {
		$pairWeights{$term} = ${$aToBScoresRef}[$weightIterator];
		$weightIterator++;
	    }
	    
	    #scale the weights between 0 and 1 (weight/sum), so weight
	    # becomes a percentage of the total weights 
	    # I need to keep weights <= 1 to maintain correctness
	    # of stats (npp in particular, but others as well?)
	    my $sum = 0;
	    foreach my $cui (keys %pairWeights) {
		$sum += $pairWeights{$cui};
	    }
	    foreach my $cui (keys %pairWeights) {
		${$aToBScoresRef}[$reweightIterator] /= $sum;
		$reweightIterator++;
	    }
	}
	##### Now we have the normalized weights
    }

    #So now we have the weights for all B terms and for each pair hash. Next 
    # step is to weight the subgraph using these weights for each
    # pairhash and then calculate the B to C direct assocition
    # using each of those re-weighted sub graphs

################## STEP 3 #######################
#######  Find the WSA between B and C  ##########
#################################################
    # Create the B to C pair hash and read in the matrix of B to C terms
    # MATRIX READ 3 - reqiured because of links between the linking set terms
    # (e.g. edge 3->4 in sample4. This becomes a source sink if matrix isnt 
    # read in again
    my @bToCPairHashList = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
	#construct the B to C pair Hash
	my %pairHash = ();
	$pairHash{'set1'} = $sharedCoocs[$i];
	$pairHash{'set2'} = ${${$pairHashListRef}[$i]}{'set2'};
	push @bToCPairHashList, \%pairHash;
    }
    ($matrixRef, $vocabSize) = &UMLS::Association::StatFinder::readInMatrix(\@bToCPairHashList, $matrixFileName);

    # MATRIX PASS +numPairHashes - to calculate WSA we need to 
    #   reweight the matrix differently for each pairHash
    #get WSA Stats (n11,n1p,np1,npp) for each pairHash
    $weightIterator = 0;
    my @statsList = ();
    for (my $i = 0; $i < scalar @{$pairHashListRef}; $i++) {
        #get all set  B term weights as a hash{term}=weight
	my %weights = ();
	foreach my $term (@{$sharedCoocs[$i]}) {
	    $weights{$term} = ${$aToBScoresRef}[$weightIterator];
	    $weightIterator++;
        }

	#get the weighted subgraph
	my $weightedSubGraphRef = &_constructWeightedSubGraph($matrixRef, $bToCPairHashList[$i], \%weights);

	#calculate n11, n1p, np1, npp, using the weights specific to
	# this pair hash, and save the results
	my ($n1pRef, $np1Ref, $npp) = &UMLS::Association::Measures::Direct::_getAllCounts($weightedSubGraphRef);
	push @statsList, &UMLS::Association::Measures::Direct::_statsFromAllCounts(
	    $weightedSubGraphRef, $n1pRef, $np1Ref, $npp, $noOrder, $bToCPairHashList[$i], \%weights); 
    }
    
    #return the stats list, an array of array refs
    # each array ref conatins four values:
    # n11, n1p, np1, and npp for the pair hash at
    # the corresponding index in the pairHashList
    return \@statsList;
}



##################################################
#   Sub Graph Construction
##################################################
#builds a subgraph relevant to this pair hash this includes adding 
# cuis in other pair hashes to the universal source/sink, and collapsing 
# edges to create set-nodes rather than cui nodes This also takes care of
#  noOrder weights contains - hash{term} = weight
# Input:  
#    $matrixRef - ref to a matrix from which we construct a subgraph
#    $pairHashRef - ref to a pairHash
#    $weightsRef - ref to a hash{cui} = weight of that cui
# Output:
#    \%subGraph - a weighted subgraph for this pairHash
sub _constructWeightedSubGraph {
    my $matrixRef = shift;
    my $pairHashRef = shift;
    my $weightsRef = shift;

    #convert the pair hash to two hashes of cuis
    my %set1 = ();
    foreach my $key (@{${$pairHashRef}{'set1'}}) {
	$set1{$key} = 1;
    }
    my %set2 = ();
    foreach my $key (@{${$pairHashRef}{'set2'}}) {
	$set2{$key} = 1;
    }
    
    # Restrict graph to nodes in this pairhash. That is,  
    # set any nodes outside of sets1 and 2 to be the 
    # universal source and sink
    #initalize the sub graph
    my %subGraph = ();
    my %emptyHash = ();
    $subGraph{'source'} = \%emptyHash;

    #loop through all source and targets, and if not in 
    # either of the sets, replace with the universal 
    # sink or source 
    foreach my $source (keys %{$matrixRef}) {
        #convert source to the universal source 
	# node if it is not in this pair hash
	my $newSource = $source;
	if (!exists $set1{$source} && !exists $set2{$source}) {
	    $newSource = 'source';
	}
	
	#go through all targets for this source
	foreach my $target (keys %{${$matrixRef}{$source}}) {
	    #convert to universal sink if node is 
	    # not in this pair hash
	    my $newTarget = $target;
	    if (!exists $set1{$target} && !exists $set2{$target}) {
		$newTarget = 'sink';
	    }
	    
	    #weights the value (if both source and target 
	    # have weights, then weight is the their product)
	    my $value = ${${$matrixRef}{$source}}{$target};
	    if (defined ${$weightsRef}{$source}){
		$value *= ${$weightsRef}{$source};
	    }
	    if (defined ${$weightsRef}{$target}) {
		$value *= ${$weightsRef}{$target};
	    }
	    
	    #add the value to the subgraph
	    ${$subGraph{$newSource}}{$newTarget} += $value;  	    
	}
    }
    #At this point, the sub graph has been converted, such that
    # it contains only the nodes in this pair hash. All other nodes
    # have been converted to the universal source and univerals sink

    #return the subgraph
    return \%subGraph;
}


##################################################
#   Linking Set Acquisition
##################################################
# Find the linking terms (direct co-occurrences) between sets 1 and 
# sets 2 and outputs them as co-occurrence hashes (hash{cui}=1)
# Input:
#  $pairHashRef - ref to a pairHash
#  $matrixRef - ref to the read in co-occurrence matrix
#  $noOrder - 1 if order is enforced, 0 if not
# Output:
#  \%set1Cooc - a hash{cui}=1 of all of set 1's direct co-occurrences 
#               (order/noOrder is accounted for)
#  \%set2Cooc - a hash{cui}=1 of all of set 2's direct co-occurrences
#               (order/noOrder is accounted for) 
sub _getLinkingTermSets {
    my $pairHashRef = shift;
    my $matrixRef = shift;
    my $noOrder = shift;

    #convert pair hash to sets 1 and 2 hashes
    my %set1 = ();
    foreach my $node (@{${$pairHashRef}{'set1'}}) {
	$set1{$node} = 1;
    }
    my %set2 = ();
    foreach my $node (@{${$pairHashRef}{'set2'}}) {
	$set2{$node} = 1;
    }

    #get all co-occurring terms with set1 and set2
    my %set1Cooc = ();
    my %set2Cooc = ();
    #check all nodes in the dataset
    foreach my $source (keys %{$matrixRef}) {
	foreach my $target (keys %{${$matrixRef}{$source}}) {
	    #add co-occurrences to set1 and set2
	    if (exists $set1{$source}) {
		$set1Cooc{$target} = 1;
	    }    
	    if (exists $set2{$target}) {
		$set2Cooc{$source} = 1;
	    }

	    #if noorder, add co-occurrences 
	    # to set1 and set2
	    if ($noOrder) {
		if (exists $set1{$target}) {
		    $set1Cooc{$source} = 1;
		}
		if (exists $set2{$source}) {
		    $set2Cooc{$target} = 1;
		}
	    }
	}
    }

    #return the two co-occurring sets
    return (\%set1Cooc, \%set2Cooc);
}

# Finds the shared co-occurrences between the two input co-occurrence hashes
# Input:
#  \%set1Cooc - a hash{cui}=1 of all of set 1's direct co-occurrences 
#               (order/noOrder is accounted for)
#  \%set2Cooc - a hash{cui}=1 of all of set 2's direct co-occurrences
#               (order/noOrder is accounted for) 
# Output:
#  \%sharedCooc - a hash{cui}=1 of the shared co-occurrences between 
#                 the input co-occurrence hashes
sub _getSharedLinkingTerms {
    my $set1CoocRef = shift;
    my $set2CoocRef = shift;
    
    #get the shared linking terms between 
    # set1 and set2 co-occurrences
    my %sharedCooc = ();
    foreach my $node (keys %{$set1CoocRef}) {
        if (defined ${$set2CoocRef}{$node}) {
            $sharedCooc{$node} = 1;
        }
    }
    return \%sharedCooc;
}


1;
