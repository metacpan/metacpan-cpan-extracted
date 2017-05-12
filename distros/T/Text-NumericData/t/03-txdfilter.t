#!perl -T

use Test::More tests => 7;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdfilter;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");
my $app = Text::NumericData::App::txdfilter->new();

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;

# Most simple check on empty file, adding titles.
$indata = '';
ok( txdtest([@defcon, '--lineend=UNIX', '--comment=This is a comment.', 'This is a title.', 'column 1', 'column 2'], 'filter1.dat'), 'Adding titles to nothing.');

ok( txdtest([@defcon, '--lineend=UNIX', '--comment=This is a comment.', '--origin', 'This is a title.', 'column 1', 'column 2'], 'filter2.dat'), 'Adding titles to nothing (Origin).');

# nasty file:
# 1. no comment character
# 2. comma and space as separation
$indata = <<EOT;
some random file

ACME Data Aquisition Equipment Co.
Data Sets:
a / A, b / Butterbreadwidth, c / C
23, 1, 345
3, 2.34, 234.
111.222, 45, 7
EOT


ok( txdtest([@defcon, '--outsep=TAB', '--separator=, ', '--comchar=#', '--quote', '--lineend=UNIX', '-N=.3f', '-N.=i', '-N.=06.1f', '--strict'], 'filter3.dat'), 'Reformatting a CSV file.' );

ok( txdtest([@defcon, '--outsep=TAB', '--empty', '-N=.3f', '-N.=i', '-N.=06.1f', '--strict', '++touchhead', '++touchdata'], $indata, 'scalar' ), 'Not changing a CSV file.' );

$indata = <<EOT;
spacy data
1, 2, 3: space comment
"column drum"  "yet a nother"   "bet your mother"
          -33     34234.33440              1.33e7
       +0.001        42.42e-9             12343.3
        232         435.42e-4            -23453.1
EOT

ok( txdtest([@defcon, '++text', '--black', '--outsep=; ', '--comchar=%', '--lineend=UNIX'], 'filter4.dat'), 'Reformatting spacy data.' );

# Test if UNIX and DOS line ends are kept (meaningful when on the other platform).
ok( txdtest([@defcon], 'filter5dos.dat', 'bothfile') );
ok( txdtest([@defcon], 'filter5unix.dat', 'bothfile') );

sub txdtest
{
	my ($args, $reffile, $reftype) = @_;
	$reftype = 'file' unless defined $reftype;
	my $outstr;
	open(my $in, '<', $reftype eq 'bothfile' ? "$prefix/$reffile" : \$indata);
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	open($out, '<', \$outstr);
	my $outthing;
	# opening as handle only works if not initialized already
	if($reftype eq 'scalar'){ open($outthing, '<', \$reffile); }
	else{ $outthing = "$prefix/$reffile" }

	if(compare($out, $outthing) == 0)
	{
		return 1;
	}
	else
	{
		print STDERR "difference in data .. debug\n";
		close($out);
		print STDERR "$outstr";
		print STDERR $reftype eq 'bothfile' ? "[input $prefix/$reffile]\n" : "$indata";
		return 0;
	}
}
