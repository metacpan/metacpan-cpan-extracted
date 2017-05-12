#!perl

use Test::More tests => 4;
use Text::NumericData::App::txdrows;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdrows->new();

ok( txdtest([@defcon, qw(-b=2 -e=3 --lineend=UNIX)], 'test1.dat', 'test-txdrows1.dat'), 'row range');
ok( txdtest([@defcon, '[2]+[3] == 3', '--lineend=UNIX'], 'test1.dat', 'test-txdrows2.dat'), 'expression 1' );
ok( txdtest([@defcon, '-j=0','[1]+[2]==4', '--lineend=UNIX'], 'test1.dat', 'test-txdrows3.dat'), 'expression 2' );
ok( txdtest([@defcon, '[1]-[2]==4', '--lineend=UNIX'], 'test1.dat', 'test-txdrows4.dat'), 'expression 3' );

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
