#http://search.cpan.org/dist/Test-Simple/lib/Test/Tutorial.pod
use Test::More tests => 1;

# Testing whether the package is present in the package.
BEGIN {use_ok Text::SenseClusters::LabelEvaluation::ReadingFilesData}


# Including the LabelEvaluation Module.
use Text::SenseClusters::LabelEvaluation::ReadingFilesData;

# Including the FileHandle module.
use FileHandle;


# The following block-of-code, create a file and write the data into it.
# At the end of this test program, we will delete that file.
   						
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

# Closing file handle.
close($topicFileHandle);		

# END OF file creation block.


# The following code will call the readLinesFromTopicFile() function from the 
# ReadingFilesData modules. It will return the content of the file in a string.
my $fileData = Text::SenseClusters::LabelEvaluation::ReadingFilesData::readLinesFromTopicFile(
						$topicFileName);

# Printing the content of the file.
print "\n Data of the input file is $fileData \n";


# Deleting the temporary label and topic files.
unlink $topicFileName or warn "Could not unlink $topicFileName: $!";


