#!perl

use Test::More tests => 1;
use Text::NumericData::App::txdrecycle;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdrecycle->new();

ok( txdtest([@defcon, '--lineend=UNIX', '-c=1', '-s=5', '-N=.3f'], 'flow.dat', 'flow-cycle.dat'), 'x shift');

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
