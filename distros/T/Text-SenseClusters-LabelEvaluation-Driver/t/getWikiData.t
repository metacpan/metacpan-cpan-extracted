#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 2;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData}


# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData;

# Defining the topic name for which we will create the file containing their detail
# data from the wikipedia.
$topicName ="BillClinton";

# This tells to not to create the temp files (which will held the data feteched from 
# wikipedia). To keep this file make it 0.
my $isClean = 1;

# The following code will call the getWikiDataForTopic() function from the 
# GetWikiData modules. It will create the file containing the wikipedia 
# information about the topic.
$fileName = 
	Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData::getWikiDataFileForTopic(
						$topicName, $isClean);


$expectedFileName = "temp_BillClinton.txt";

ok( $fileName eq $expectedFileName, 'GetWikiData Module is working properly' );

# Deleting the temporary topic file.
unlink $fileName or warn "Could not unlink $fileName: $!";	
