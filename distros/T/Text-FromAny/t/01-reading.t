use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec::Functions;
use File::Basename qw(dirname);
my $dataPath;

my %fileToTextMap = (
    'test-basic.txt' => {
        text => "Test file for Text::FromAny\n\nTXT version\n",
        type => 'txt',
    },
    'test-basic.doc' => {
        text => "Test file for Text::FromAny\n\nDOC version",
        type => 'doc',
    },
    'test-basic.docx' => {
        text => "Test file for Text::FromAny\n\nDOCx version\n",
        type => 'docx',
    },
    'test-basic.odt' => {
        text => "Test file for Text::FromAny\n\nODT version",
        type => 'odt',
    },
    'test-basic.sxw' => {
        text => "Test file for Text::FromAny\n\nOOo legacy SXW version",
        type => 'sxw',
    },
    'test-basic.rtf' => {
        text => "Test file for Text::FromAny\n\n RTF  version\n",
        type => 'rtf',
    },
	'test-basic.html' => {
		text => "Test file for Text::FromAny\n\nHTML version",
		type => 'html',
	},
	'test-basic.pdf' => {
		text => "Test file for Text::FromAny\nPDF version\n",
		type => 'pdf',
		needsPdfToText => 0,
	},
	'test-basic-pdftotext.pdf' => {
		text => "Test file for Text::FromAny\n\nPDF version\n",
		type => 'pdf',
		needsPdfToText => 1,
	},
	'test-extraFormat.html' => {
		text => "Test file for Text::FromAny\nWith four spaces: |    |\nAnd a link to our git repo plus our issue tracker and lastly a\nduplicate of the link to our git repo.\n\nhttp://github.com/portu/Text-FromAny\nhttp://github.com/portu/Text-FromAny/issues",
		type => 'html',
	},
);

plan tests => (keys(%fileToTextMap)* 3)+1;
use_ok('Text::FromAny');

foreach my $f (keys %fileToTextMap)
{
    testFromFile($f, $fileToTextMap{$f});
}

sub testFromFile
{
    my $file = shift;
	$file = pathToFile($file);
	if(not defined $file)
	{
		BAIL_OUT("Failed to locate test files");
	}
	elsif(not -e $file)
	{
		BAIL_OUT("$file: does not exist");
	}
    my $info = shift;
	my $allowExternal = $info->{needsPdfToText} ? 1 : 0;
    my $t = Text::FromAny->new(file => $file, allowExternal => $allowExternal);
    isa_ok($t,'Text::FromAny','Ensure Text::FromAny is correct');
    my $typeOK = is($t->detectedType, $info->{type});
    SKIP: {
		if ($info->{needsPdfToText})
		{
			if(not hasPDFToText())
			{
				skip('pdftotext is not installed',1);
			}
		}
        skip('Text loaded properly'.$file,1) if not $typeOK;
        is($t->text, $info->{text}, 'Text loaded properly');
    };
}
sub pathToFile
{
	my $file = shift;
	if ($dataPath)
	{
		return catfile($dataPath,$file);
	}
	my @paths = (dirname(__FILE__), $FindBin::RealBin);
	my @subPaths = (curdir(), 'data', catfile('t/data'));
	foreach my $p (@paths)
	{
		foreach my $e (@subPaths)
		{
			my $try = catfile($p,$e,$file);
			if (-e $try)
			{
				$dataPath = catfile($p,$e);
				return $try;
			}
		}
	}
	return undef;
}
sub hasPDFToText
{
	foreach (split /:/, $ENV{PATH})
	{
		my $f = catfile($_,'pdftotext');
		if (-x $f and not -d $f)
		{
			return 1;
		}
	}
}
