#!perl

use Test::More qw(no_plan);
use FileHandle;

######################
# Test use
######################
use_ok('Text::PORE');
use_ok('Text::PORE::Object');
use_ok('Text::PORE::Template');

##########################
# Test directives
##########################
my $templateRootDir = "templates";
my $testDataDir = "testData";
my $outputDir = "output";
mkdir $outputDir;

my @tests = (	"render",
				"context",
				"list",
				"cond",
				"complex1",
);

my %testDescr = (	"render"	=>	"<PORE.render> directive",
					"context"	=>	"<PORE.context> directive",
					"list"		=>	"<PORE.list> directive",
					"cond"		=>	"<PORE.cond> directive",
					"complex1"	=>	"the combintion of <PORE.list> and <PORE.cond>",
);

#
# Create an object to be rendered.
#
my $employer = new Text::PORE::Object('name'=>'Perl.com',
	'url'	=>	'http://www.perl.com'
);
my $obj = new Text::PORE::Object('name'=>'Joe Smith',
	'age'			=>	50,
	'employer'		=>	$employer,
);
@chilren = (
	new Text::PORE::Object('name'=>'John Smith', 'age'=>10, 'gender'=>'M'),
	new Text::PORE::Object('name'=>'Jack Smith', 'age'=>15, 'gender'=>'M'),
	new Text::PORE::Object('name'=>'Joan Smith', 'age'=>20, 'gender'=>'F'),
	new Text::PORE::Object('name'=>'Jim Smith', 'age'=>25, 'gender'=>'M'),
);
$obj->{'children'} = \@chilren;

my $test, $tpl, $fileDiff;
my $fh = new FileHandle();
foreach $test (@tests) {
	$tpl = new Text::PORE::Template('file' => "$templateRootDir/$test.tpl");
	$fh->open(" > $outputDir/$test.txt");
	Text::PORE::render($obj, $tpl, $fh);
	$fh->close();
	$fileDiff = fileDiff("$outputDir/$test.txt", "$testDataDir/$test.txt");
	ok($fileDiff == 0, "test $testDescr{$test}");
}


#########################################
# Test new Template('id'=>$id)
#########################################
$test = 'render';
Text::PORE::setTemplateRootDir($templateRootDir);
$tpl = new Text::PORE::Template('id' => $test);
$fh->open(" > $outputDir/$test.txt");
Text::PORE::render($obj, $tpl, $fh);
$fh->close();
$fileDiff = fileDiff("$outputDir/$test.txt", "$testDataDir/$test.txt");
ok($fileDiff == 0, "test new Template('id'=>\$id)");


####################################
# private methods
####################################
sub fileDiff($$) {
	my ($filename1, $filename2) = @_;
	my $fileContent1 = "";
	my $fileContent2 = "";
	my $fh = new FileHandle();
	my $line;
	$fh->open("< $filename1");
	while ($line = $fh->getline) {
		$fileContent1 .= $line;
	}
	$fh->close();
	$fh = new FileHandle();
	$fh->open("< $filename2");
	while ($line = $fh->getline) {
		$fileContent2 .= $line;
	}
	$fh->close();
	return ($fileContent1 eq $fileContent2)? 0 : 1;
}