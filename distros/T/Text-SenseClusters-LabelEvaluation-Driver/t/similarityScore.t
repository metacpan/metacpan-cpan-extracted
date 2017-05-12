#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 3;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::SimilarityScore}

# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::SimilarityScore;

# Defining the two strings for testing.
my $firstString = "IBM::: vice president, million dollars, Wall Street, Deep Blue, ".
					"International Business, Business Machines, International Machines, ".
					"United States, Justice Department, personal computers";
my $secondString = "vice president, million dollars, Deep Blue, International Business, ".
					"Business Machines, International Machines, United States, Justice Department";

my $stopListFileLocation ="";					 
my $similarityObject = Text::SenseClusters::LabelEvaluation::SimilarityScore->new($firstString,$secondString, $stopListFileLocation);
my ($score, %allScores) = $similarityObject->computeOverlappingScores();
print "Score:: $score \n";
print "Raw Lesk Score :: $allScores{'raw_lesk'} \n";

ok( $score == 16, 'SimilarityScore Module is working properly for simiple score.' );
ok( $allScores{'raw_lesk'} == 160, 'SimilarityScore Module is working properly for lesk score.' );
	
