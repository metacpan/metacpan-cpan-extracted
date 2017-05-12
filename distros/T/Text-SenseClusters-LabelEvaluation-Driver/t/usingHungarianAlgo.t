#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 3;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo}

use Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo;

# Defining the matrix which contains the similarity scores for labels and clusters.
@mat = ( [ 2, 4, 7 ], [ 3, 9, 5 ], [ 8, 2, 9 ], );

# Defining the header for these matrix.
@topicHeader = ("BillClinton", "TonyBlair", "EhudBarak");
@clusterHeader = ("Cluster0", "Cluster1", "Cluster2");

# Creating the Hungarian object.
$hungrainObject = Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo
					->new(\@mat, \@topicHeader, \@clusterHeader);

# Assigning the labels to clusters using Hungarian algorithm.
$accuracy = $hungrainObject->reAssigningWithHungarianAlgo();


# For correct run. It should return value between 0 to 1.
cmp_ok($accuracy, '>', 0.0);
cmp_ok($accuracy, '<', 1.0);


# For above example, it should return the value as 0.489795918367347
#cmp_ok($accuracy, '==',0.489795918367347);


