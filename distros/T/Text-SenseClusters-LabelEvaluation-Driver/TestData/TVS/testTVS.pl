use Text::SenseClusters::LabelEvaluation::Driver;

%inputOptions = (
		senseClusterLabelFileName => 'TVS.label', 
		labelComparisonMethod => 'direct',
		goldKeyFileName => 'TVSMappingUserData.txt',
		goldKeyDataSource => 'userData',
		weightRatio => 10,
		isClean => 1,
	);

%inputOptions1 = (
		senseClusterLabelFileName => 'TVS.label', 
		labelComparisonMethod => 'direct',
		goldKeyFileName => 'TVSMapping.txt',
		goldKeyDataSource => 'wikipedia',
		weightRatio => 10,
		isClean => 1,
	);
	
%inputOptions2 = (
		senseClusterLabelFileName => 'TVS.label', 
		labelComparisonMethod => 'automate',
		goldKeyFileName => 'TVSUserData.txt',
		goldKeyDataSource => 'userData',
		weightRatio => 10,
		isClean => 1,
	);
	
	
%inputOptions3 = (
		senseClusterLabelFileName => 'TVS.label', 
		labelComparisonMethod => 'automate',
		goldKeyFileName => 'TVSTopic.txt',
		goldKeyDataSource => 'wikipedia',
		weightRatio => 10,
		isClean => 1,
	);	
	
#Case 1			
print "\nDirect Comparison of Cluster's Label with user provided Data:\n";
my $driverObject = Text::SenseClusters::LabelEvaluation::Driver->new (\%inputOptions);
if($driverObject->{"errorCode"}){
	print "Please correct the error before proceeding.\n\n";
	exit();
}
my $accuracyScore = $driverObject->evaluateLabels();

#Case 2
print "\n\n--------------------------------------------------------------------------------------";
print "\n--------------------------------------------------------------------------------------";
print "\nDirect Comparison of Cluster's Label with wikipedia Data:\n";
my $driverObject1 = Text::SenseClusters::LabelEvaluation::Driver->new (\%inputOptions1);
if($driverObject1->{"errorCode"}){
	print "Please correct the error before proceeding.\n\n";
	exit();
}
my $accuracyScore = $driverObject1->evaluateLabels();

#Case 3
print "\n\n--------------------------------------------------------------------------------------";
print "\n--------------------------------------------------------------------------------------";
print "\nDirect Comparison of Cluster's Label with user provided Data using Hungarian algorithm:\n";
my $driverObject2 = Text::SenseClusters::LabelEvaluation::Driver->new (\%inputOptions2);
if($driverObject2->{"errorCode"}){
	print "Please correct the error before proceeding.\n\n";
	exit();
}
my $accuracyScore = $driverObject2->evaluateLabels();

#Case 4
print "\n\n--------------------------------------------------------------------------------------";
print "\n--------------------------------------------------------------------------------------";
print "\nComparison of Cluster's Label with wikipedia Data using Hungarian algorithm:\n";
my $driverObject3 = Text::SenseClusters::LabelEvaluation::Driver->new (\%inputOptions3);
if($driverObject3->{"errorCode"}){
	print "Please correct the error before proceeding.\n\n";
	exit();
}
my $accuracyScore = $driverObject3->evaluateLabels();

$driverObject->printInputParameter();
$driverObject->help();		
