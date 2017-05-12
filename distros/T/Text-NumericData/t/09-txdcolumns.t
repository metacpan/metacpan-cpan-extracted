#!perl

use Test::More tests => 3;
use Text::NumericData::App::txdcolumns;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdcolumns->new();

ok( txdtest([@defcon, '--lineend=UNIX', 1, 3], 'test1.dat', 'test-txdcolumns1.dat'), 'simple selection');
ok( txdtest([@defcon, '--lineend=UNIX', '-c=3', 2, 1], 'test1.dat', 'test-txdcolumns2.dat'), 'combo' );
ok( txdtest([@defcon, '--lineend=UNIX', 'z','x'], 'test1.dat', 'test-txdcolumns3.dat'), 'title match' );

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
