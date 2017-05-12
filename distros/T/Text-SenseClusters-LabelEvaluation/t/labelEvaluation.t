#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 8;

# Testing whether the dependent package are presents in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::ReadingFilesData}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::PrintingHashData}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::Wikipedia::GetWikiData}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::SimilarityScore}
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::ConfusionMatrixTotalCalc}

# Testing whether LabelEvaluation module is present or not.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::LabelEvaluation}

# Including the FileHandle module.
use FileHandle;

# File that will contain the label information.
my $labelFileName = "temp_label.txt";

# Defining the file handle for the label file.
our $labelFileHandle = FileHandle->new(">$labelFileName");

# Writing into the label file.
print $labelFileHandle "Cluster 0 (Descriptive): George Bush, Al Gore, White House,". 
   			" COMMENTARY k, Cox News, George W, BRITAIN London, U S, ".
  			"Prime Minister, New York \n\n";
print $labelFileHandle "Cluster 0 (Discriminating): George Bush, COMMENTARY k, Cox ".
   			"News, BRITAIN London \n\n";
print $labelFileHandle "Cluster 1 (Descriptive): U S, Al Gore, White House, more than,". 
   			"George W, York Times, New York, Prime Minister, President ".
   			"<head>B_T</head>, the the \n\n";
	print $labelFileHandle "Cluster 1 (Discriminating): more than, York Times, President ".
   			"<head>B_T</head>, the the \n";
   						
# File that will contain the topic information.
my $topicFileName = "temp_topic.txt";

# Defining the file handle for the topic file.
our $topicFileHandle = FileHandle->new(">$topicFileName");

# Writing into the Topic file.
# Bill Clinton  ,   Tony  Blair 
print $topicFileHandle "Bill Clinton  ,   Tony  Blair \n";

# Closing the handles.
close($labelFileHandle);								
close($topicFileHandle);								

# Creating the Optionshash by specifying the mandatory options.
%inputOptions = (

		labelFile => $labelFileName, 
		labelKeyFile => $topicFileName
);	


# Calling the LabelEvaluation modules by passing the name of the 
# label and topic files.
my $score = Text::SenseClusters::LabelEvaluation::LabelEvaluation->
		new (\%inputOptions);
		

# Printing the score.			
#print "\nScore of label evaluation is :: $score \n";

# Deleting the temporary label and topic files.
unlink $labelFileName or warn "Could not unlink $labelFileName: $!";								
unlink $topicFileName or warn "Could not unlink $topicFileName: $!";
	
# For correct run. It should return value between 0 to 1.
cmp_ok($score, '>', 0.0);
cmp_ok($score, '<', 1.0);

# For BT.label and BT.txt, it should return the value as 0.326
#cmp_ok($score, '==', 0.07134);



