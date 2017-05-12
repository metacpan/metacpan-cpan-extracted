#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 1;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::ReadingFilesData}

use Text::SenseClusters::LabelEvaluation::ReadingFilesData;

# Reading the cluster's labels file.
my $clusterFileName = "TestData/TVS/TVS.label";

# Creating the read file object and reading the label examples.
my $readClusterFileObject = 
		Text::SenseClusters::LabelEvaluation::ReadingFilesData->new ($clusterFileName);
		
my %labelSenseClustersHash = ();
my $labelSenseClustersHashRef = 
		$readClusterFileObject->readLinesFromClusterFile(\%labelSenseClustersHash);
%labelSenseClustersHash = %$labelSenseClustersHashRef;
			
# Iterating the Hash to print the value.
foreach my $key (sort keys %labelSenseClustersHash){
	foreach my $innerkey (sort keys %{$labelSenseClustersHash{$key}}){
		print "$key :: $innerkey :: $labelSenseClustersHash{$key}{$innerkey} \n";
	}
}	


