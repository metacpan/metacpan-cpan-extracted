#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 2;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::SimilarityScore}

# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::SimilarityScore;

# Including the FileHandle module.
use FileHandle;

# File that will contain the label information.
my $labelFileName = "temp_ClusterLabel.txt";

# Defining the file handle for the label file.
our $labelFileHandle = FileHandle->new(">$labelFileName");

# Writing into the label file.
print $labelFileHandle "U S, Al Gore, White House, more than, President 1993, George W,". 
   			"York Times, New York, Prime Minister, New Democrat, National Governors";
   						
# File that will contain the topic information.
my $topicFileName = "temp_TopicData.txt";

# Defining the file handle for the topic file.
our $topicFileHandle = FileHandle->new(">$topicFileName");

# Writing into the Topic file.
# Bill Clinton  ,   Tony  Blair 
print $topicFileHandle "Bill Clinton is an American politician who served as the 42nd President of". 
"the United States from 1993 to 2001. Inaugurated at age 46, he was the third-youngest president.". 
"He took office at the end of the Cold War, and was the first president of the baby boomer generation.". 
"Clinton has been described as a New Democrat. Many of his policies have been attributed to a centrist". 
"Third Way philosophy of governance. He is married to Hillary Rodham Clinton, who has served as the". 
"United States Secretary of State since 2009 and was a Senator from New York from 2001 to 2009.". 
"As Governor of Arkansas, Clinton overhauled the state's education system, and served as Chair ".
"of the National Governors Association.Clinton was elected president in 1992, defeating incumbent". 
"president George H. W. Bush. The Congressional Budget Office reported a budget surplus between ".
"the years 1998 and 2000, the last three years of Clinton's presidency. Since leaving office,".
"Clinton has been rated highly in public opinion polls of U.S. presidents. \n";

# Closing the handles.
close($labelFileHandle);								
close($topicFileHandle);		

my $stopListFileLocation ="";

my $similarityScore = Text::SenseClusters::LabelEvaluation::SimilarityScore::computeOverlappingScores(
						$labelFileName,$topicFileName, $stopListFileLocation);

print "\n Similarity Score for the Cluster-labels and Bill-Clinton-Wiki data is $similarityScore \n";

# Deleting the temporary label and topic files.
unlink $labelFileName or warn "Could not unlink $labelFileName: $!";								
unlink $topicFileName or warn "Could not unlink $topicFileName: $!";

ok( $similarityScore == 12, 'SimilarityScore Module is working properly' );
#cmp_ok($similarityScore, '==', 12);
