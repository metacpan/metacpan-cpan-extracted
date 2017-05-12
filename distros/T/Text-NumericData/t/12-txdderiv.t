#!perl -T

use Test::More tests => 7;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdderiv;

my $app = Text::NumericData::App::txdderiv->new();


my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0; [2] = [1]**2 + 7; [3] = sqrt([@defcon, 1]);'], undef, $indata_h);
close($indata_h);

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX'], 'deriv1.dat'), 'central diff in-place' );
ok( txdtest([@defcon, '-N=.3f', '--append', '--lineend=UNIX'], 'deriv2.dat'), 'central diff append' );
ok( txdtest([@defcon, '-N=.3f', '--dualgrid', '--lineend=UNIX'], 'deriv3.dat'), 'dualgrid in-place' );
# test title modification, hack for now (or forever) since txdfilter is not yet in place
$indata = "#data\n#\"x\"	\"y\"	\"z\"\n".$indata;
ok( txdtest([@defcon, '-N=.3f'], 'deriv4.dat', '--lineend=UNIX'), 'central diff in-place title' );
ok( txdtest([@defcon, '-N=.3f', '--append', '--lineend=UNIX'], 'deriv5.dat'), 'central diff append title' );
# also non-default columns
ok( txdtest([@defcon, '-N=.3f', '--append', '-x=3', '-y=1', '--lineend=UNIX'], 'deriv6.dat'), 'central diff cols append' );
ok( txdtest([@defcon, '-N=.3f', '--dualgrid', '-x=2', '-y=3', '-y.=1', '--lineend=UNIX'], 'deriv7.dat'), 'dualgrid in-place cols' );

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
	if(compare($out, "$prefix/$reffile") == 0)
	{
		return 1;
	}
	else
	{
		print STDERR "difference in data .. debug";
		close($out);
		print STDERR "$outstr";
		return 0;
	}
}
