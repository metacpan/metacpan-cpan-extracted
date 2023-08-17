#!perl

use Test::More tests => 4;
use Text::NumericData::App::txdcontract;
use File::Compare;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdcontract->new();

# Intentionally using rather trivial input data that should lead to
# accurate values as multiples of 0.5, so exactly preserved in
# binary.
ok( txdtest([@defcon, '--lineend=UNIX', 2], 'test1.dat', 'test-txdcontract1.dat'), 'factor 2');
ok( txdtest([@defcon, '--lineend=UNIX', '--stats=1', 2], 'test1.dat', 'test-txdcontract2.dat'), 'factor 2 stats 1');
ok( txdtest([@defcon, '--lineend=UNIX', '--stats=2', 2], 'test1.dat', 'test-txdcontract3.dat'), 'factor 2 stats 2');
ok( txdtest([@defcon, '--lineend=UNIX', '--stats=3', 2], 'test1.dat', 'test-txdcontract4.dat'), 'factor 2 stats 3');

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
	if(compare($out, "$prefix/$reffile") == 0)
	{
		return 1;
	} else
	{
		print STDERR "Comparison failed.\n";
		print STDERR "ARGS: ".join(' ',(map {"'$_'"} @argscopy))."\n";
		print STDERR "REFERENCE:\n";
		open(my $ref, '<', "$prefix/$reffile");
		while(<$ref>){ print STDERR; }
		close($ref);
		print STDERR "END.\nOUTPUT:\n".$outstr."END.\n";
		return 0;
	}
}
