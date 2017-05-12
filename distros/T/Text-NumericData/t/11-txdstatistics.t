#!perl -T

use Test::More tests => 1;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdstatistics;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdstatistics->new();

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0; [2]=42'], undef, $indata_h);
close($indata_h);

ok( txdtest([@defcon, '-N=d', '-N.=s', '-N.=0.2f', '-N.=0.2f', '--lineend=UNIX'], 'statistics.dat'), 'statistics 1' );


sub txdtest
{
	my ($args, $reffile) = @_;
	my $outstr;
	open(my $in, '<', \$indata);
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	open($out, '<', \$outstr);
	return compare($out, "$prefix/$reffile") == 0;
}
