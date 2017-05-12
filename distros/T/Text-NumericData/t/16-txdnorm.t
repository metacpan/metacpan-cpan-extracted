#!perl

use Test::More tests => 1;
use Text::NumericData::App::txdnorm;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdnorm->new();

ok( txdtest([@defcon, '--lineend=UNIX', '-N=.3f'], 'test1.dat', 'test-txdnorm1.dat'), 'y norm');

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
