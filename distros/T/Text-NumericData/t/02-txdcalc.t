#!perl

use Test::More tests => 6;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdcalc;
use lib 't';
use txdtestutil;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdcalc->new();

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0'], undef, $indata_h);
close($indata_h);

ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--lineend=UNIX', '[1]=sqrt([1]); [2]=[1]**2;']
,	\$indata, "$prefix/calc1.dat", 1.1e-3
), 'basic computation' );

ok( txdtestutil::txdtest( $app
,	[
		@defcon
	,	'-N=.3f', '--lineend=UNIX', '--byrow'
	,	'[1]*=0.5*([1,1]+[2,1]); [2]=[1,3]; [3]=[2,2]-[1,2];'
	,	"$prefix/calc2a.dat"
	,	"$prefix/calc2b.dat"
	]
,	\$indata, "$prefix/calc2.dat", 1.1e-3
), 'file juggling by row' );

open($indata_h, '>', \$indata);
$consapp->run([@defcon, '-N=.1f', '-n=100', '[1]=0.1*C0'], undef, $indata_h);
close($indata_h);
ok( txdtestutil::txdtest( $app
,	[
		@defcon, '-N=.1f', '-N.=.4f', '--lineend=UNIX'
	,	'--bycol=1', '--interpolate=linear', '[2]=[1,2]'
	,	"$prefix/calc3ref.dat"
	]
, \$indata, "$prefix/calc3.dat", 1.1e-4
), 'linear interpolation' );

open($indata_h, '>', \$indata);
$consapp->run([@defcon, '-N=.3f', '-n=100', '[1]=C2'], undef, $indata_h);
close($indata_h);

ok( txdtestutil::txdtest( $app
,	[
		@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1'
	,	'--interpolate=0', '[2]=[1,2]'
	,	"$prefix/calc4base.dat"
	]
,	\$indata, "$prefix/calc4noint.dat", 1.1e-3
), 'sine without interpolation' );

ok( txdtestutil::txdtest( $app
,	[
		@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1'
	,	'--interpolate=linear', '[2]=[1,2]'
	,	"$prefix/calc4base.dat"
	]
, \$indata, "$prefix/calc4linear.dat", 1.1e-3
), 'sine with linear interpolation' );

ok( txdtestutil::txdtest( $app
,	[
		@defcon, '-N=.3f', '--lineend=UNIX', '--bycol=1'
	,	'--interpolate=spline', '[2]=[1,2]'
	,	"$prefix/calc4base.dat"
	]
, \$indata, "$prefix/calc4spline.dat", 1.1e-3
), 'sine with spline interpolation' );
