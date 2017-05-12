#!/usr/bin/perl -w
#

use XML::Node;

# The following sample script calculates how many test cases there are in 
#   a test suite XML file.
#
# The XML file name can be passed as a parameter. Example:
#   perl test.pl test.xml
#

my $suite_name = "";
my $testcase_name = "";
my $xml_filename = "test.xml";
my $testcase_no = 0;
my $arg1 = shift;

if ($arg1) {
    $xml_filename = $arg1;
}

$p = XML::Node->new();

$p->register(">TestTalk>TestSuite>Name","char" => \$ suite_name);
$p->register(">TestTalk>TestSuite>TestCase>Name","char" => \$testcase_name);
$p->register(">TestTalk>TestSuite>TestCase","end" => \& handle_testcase_end);
$p->register(">TestTalk>TestSuite","end" => \& handle_testsuite_end);

print "\nProcessing file [$xml_filename]...\n\n";
$p->parsefile($xml_filename);


sub handle_testcase_end
{
    print "Found test case [$testcase_name]\n";
    $testcase_name = "";
    $testcase_no ++;
}

sub handle_testsuite_end
{
    print "\n--There are $testcase_no test cases in test suite [$suite_name]\n\n";
    $testcase_name = "";
}




