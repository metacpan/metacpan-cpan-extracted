use strict;
use Test::More tests => 105;
use Test::Exception;
use Test::XML; # 
BEGIN {use_ok('XML::Table2XML', qw(parseHeaderForXML addXMLLine commonParent offsetNodesXML))};
my @xmltests = glob('testdir/*.txt');
# 19 internal function tests + ? XML tests:
#plan tests => (28 + @xmltests);

###########################################################
# first test the util functions
## commonParent:
ok(commonParent("/a/b/c", "/a/d/e") eq "/a", "commonParent");
ok(commonParent("/a/b", "/a/b/c") eq "/a/b", "commonParent");
ok(commonParent("/a/b/c", "/a/b") eq "/a/b", "commonParent");
ok(commonParent("/a/b/c", "/x/d/e") eq "", "commonParent");
ok(commonParent("/a/b/c", "/a/b/c") eq "/a/b/c", "commonParent");
ok(commonParent("/a/b/c", "") eq "", "commonParent");
ok(commonParent("", "/a/b/c") eq "", "commonParent");

# offsetNodesXML, openXML:
ok(offsetNodesXML("/a/b/c", "/a/d/e") eq "<b>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "/x/d/e") eq "<a><b>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "/a/b/c") eq "", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "") eq "<a><b>", "offsetNodesXML");
ok(offsetNodesXML("", "/a/b/c") eq "", "offsetNodesXML");

# offsetNodesXML, closeXML:
ok(offsetNodesXML("/a/b/c", "/a/d/e", 1) eq "</c></b>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/a/g/d/e", 1) eq "</c></b>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/t/w/d/e", 1) eq "</c></b></g></a>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/d/e", "/a/g", 1) eq "</e></d>", "offsetNodesXML");
ok(offsetNodesXML("/a/g/b/c", "/a/g/b/c", 1) eq "</c>", "offsetNodesXML");
ok(offsetNodesXML("/a/b/c", "", 1) eq "</c></b></a>", "offsetNodesXML");
ok(offsetNodesXML("/a/z", "/a/b/c", 1, 1) eq "</z></a>", "offsetNodesXML");

###########################################################
# then test invocation params

# first standard invocation
my $outXML = "";
parseHeaderForXML("rootNodeName", ['/@id','/@name2','/a']);
$outXML.=addXMLLine([1,"testName","testA"]);
$outXML.=addXMLLine(undef);
is_xml('<rootNodeName id="1" name2="testName"><a>testA</a></rootNodeName>',$outXML, "invocation test 1, xml correct");
like($outXML, '/^<\?xml version="1\.0"\?>/', "invocation test 1, xmldirective check");
unlike($outXML,'/\n/', "invocation test 1, newline check"); # shouldn't contain newlines...
   
# then modify XMLDIRECTIVE and add newlines for readability
$outXML = "";
# first parse column path headers for attribute names, id columns and special common sibling mark ("//")
parseHeaderForXML("rootNodeName", ['/@id','/@name2','/a'], 1, '<?xml version="1.1"?>');
$outXML.=addXMLLine([1,"testName","testA"]);
$outXML.=addXMLLine(undef);
is_xml('<rootNodeName id="1" name2="testName"><a>testA</a></rootNodeName>',$outXML, "invocation test 2, xml correct");
like($outXML, '/^<\?xml version="1\.1"\?>/', "invocation test 2, xmldirective check");
like($outXML, '/\n/', "invocation test 2, newline check"); # should contain newlines...

dies_ok { parseHeaderForXML();} 'expecting to die without rootnode';
dies_ok { parseHeaderForXML("rootNodeName");} 'expecting to die without headers';
dies_ok { parseHeaderForXML("rootNodeName", ["a","b"]);} 'expecting to die without proper headers';

###########################################################
# finally test the various xml test cases in <TestSheet>Tests<TestRow>_test.txt against
# target XML in <TestSheet>Tests<TestRow>_test.xml (both created with TestSheet.xls)
for my $testfilename (@xmltests) {
	my $rootNodeName; my @headerLine; my @datarows; my $expectedXML;
	readTxtFile($testfilename, \$rootNodeName, \@headerLine, \@datarows);
	readXMLFile($testfilename, \$expectedXML);
	my $testXML = "";
	# first parse the column path headers for attribute names, id columns and special common sibling mark ("//")
	# also resets all global parameters...
	parseHeaderForXML($rootNodeName, \@headerLine);
	# then walk through the whole data to build the actual XML string (in $testxml->{strXML})
	for my $lineData (@datarows) {
		$testXML.=addXMLLine($lineData);
	}
	#finally finish the XML and reset the static vars
	$testXML.=addXMLLine(undef);
	is_xml($expectedXML,$testXML, "XML comparison:".$testfilename);
}


sub readTxtFile {
	my ($testfilename, $rootNodeName, $headerLine, $datarows) = @_;

  open (TXTIN, "<$testfilename");
	$_ = <TXTIN>; chomp;
	$$rootNodeName = $_;
	$_ = <TXTIN>;chomp;
	@$headerLine = split "\t";
	while (<TXTIN>) {
		chomp;
		my @dataline = split "\t";
		push @$datarows, \@dataline;
	}
	close TXTIN;
}

sub readXMLFile {
	my ($testfilename, $expectedXML) = @_;

	$testfilename =~ s/\.txt/\.xml/;
	open (TXTIN, "<$testfilename");
	my $oldRecSep = $/;
	undef $/;
	$$expectedXML = <TXTIN>;
	$/ = $oldRecSep;
	close TXTIN;
}
