#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 7;

# Testing whether the dependent package are presents in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::ReadingFilesData}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::SimilarityScore}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::AssigningLabelUsingHungarianAlgo}

# Testing whether LabelEvaluation module is present or not.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::Driver}

# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::Driver;

my $labelFileName  = 'TestData/TVS/TVS.label';
my $topicFileName	= 'TestData/TVS/TVSMapping.txt';	

# Calling the LabelEvaluation modules by passing the following options
%inputOptions = (
	senseClusterLabelFileName => $labelFileName, 
	labelComparisonMethod => 'direct',
	goldKeyFileName => $topicFileName,
	goldKeyDataSource => 'wikipedia',
	weightRatio => 10,
	isClean => 1,
);

# Calling the LabelEvaluation modules by passing the name of the 
# label and topic files.
my $driverObject = Text::SenseClusters::LabelEvaluation::Driver->
		new (\%inputOptions);
	
if($driverObject->{"errorCode"}){
	print "Please correct the error before proceeding.\n\n";
	exit();
}
my $accuracyScore = $driverObject->evaluateLabels();
	
# For correct run. It should return value between 0 to 1.
cmp_ok($accuracyScore, '>', 0.0);
cmp_ok($accuracyScore, '<', 100.0);



