#!perl

use Test::More tests => 1;
use Text::NumericData::App::txdsort;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdsort->new();

ok( txdtest([@defcon, '--lineend=UNIX', '-c=3,2', '-d=0,1', '--scan'], 'test1.dat', 'test-txdsort1.dat'), 'one wicked sort');

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
