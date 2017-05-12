#!perl

use Test::More tests => 1;
use Text::NumericData::App::txdmean;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdmean->new();

ok( txdtest([@defcon, '--lineend=UNIX', 2], 'test1.dat', 'test-txdmean1.dat'), 'factor 2');

sub txdtest
{
	my ($args, $infile, $reffile) = @_;
	my $outstr;
	open(my $in, '<', "$prefix/$infile") or die "cannot open input $infile\n";
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	open($out, '<', \$outstr);
	return compare($out, "$prefix/$reffile") == 0;
}
