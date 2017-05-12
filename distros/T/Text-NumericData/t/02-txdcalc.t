#!perl -T

use Test::More tests => 6;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdcalc;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdcalc->new();

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0'], undef, $indata_h);
close($indata_h);

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX', '[1]=sqrt([1]); [2]=[1]**2;'], 'calc1.dat'), 'basic computation' );

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX', '--byrow', '[1]*=0.5*([1,1]+[2,1]); [2]=[1,3]; [3]=[2,2]-[1,2];', "$prefix/calc2a.dat", "$prefix/calc2b.dat"], 'calc2.dat'), 'file juggling by row' );

open($indata_h, '>', \$indata);
$consapp->run([@defcon, '-N=.1f', '-n=100', '[1]=0.1*C0'], undef, $indata_h);
close($indata_h);
ok( txdtest([@defcon, '-N=.1f', '-N.=.4f', '--lineend=UNIX', '--bycol=1', '--interpolate=linear', '[2]=[1,2]', "$prefix/calc3ref.dat"], 'calc3.dat'), 'linear interpolation' );

open($indata_h, '>', \$indata);
$consapp->run([@defcon, '-N=.3f', '-n=100', '[1]=C2'], undef, $indata_h);
close($indata_h);

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1', '--interpolate=0', '[2]=[1,2]', "$prefix/calc4base.dat"], 'calc4noint.dat'), 'sine without interpolation' );

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1', '--interpolate=linear', '[2]=[1,2]', "$prefix/calc4base.dat"], 'calc4linear.dat'), 'sine with linear interpolation' );

ok( txdtest([@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1', '--interpolate=spline', '[2]=[1,2]', "$prefix/calc4base.dat"], 'calc4spline.dat'), 'sine with spline interpolation' );


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
