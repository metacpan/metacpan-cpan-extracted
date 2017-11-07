#!perl -T

use Test::More tests => 1;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdodeint;
use lib 't';
use txdtestutil;

my $app = Text::NumericData::App::txdodeint->new();

my @defcon = ("--config=testdata/default.conf");

# Those to should produce about the same data:
#txdconstruct  -n=6 \
#  '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]; [4]=1/3*[1]**3 + 7*[1] + 2.4 - 0.5*[1]**2; [5] = 1/3*[1]**3 - 1/2*[1]**2 - 4.6 + [1]**3'
#txdconstruct -n=6 '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]' \
#| txdodeint --interpolate=spline  --timediv=10 --rksteps=4 \
#   -i=2.4 -i.=-4.6 'D0=[2]-[1]; D1=[3]+3*[1]**2'
# Error should be below 0.1.

my $indata = construct('-n=6', '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]');
# Analytical integrals for comparison.
my $cmpdata = construct(
	'-n=6', '[1] = C0-1;'
.	'[2] = [1]**2 + 7; [3] = [1]**2 - [1];'
.	'[4] = 1/3*[1]**3 + 7*[1] + 2.4 - 0.5*[1]**2;'
.	'[5] = 1/3*[1]**3 - 1/2*[1]**2 - 4.6 + [1]**3'
);

ok( txdtestutil::txdtest( $app
,	[ @defcon
	,	'--interpolate=spline', '--timediv=10', '--rksteps=4'
	,	'-i=2.4', '-i.=-4.6', 'D0=[2]-[1]; D1=[3]+3*[1]**2'
], \$indata, \$cmpdata, 0.1
), 'mixed polynomial' );

sub construct
{
	my $consapp = Text::NumericData::App::txdconstruct->new();
	my $indata;
	open(my $indata_h, '>', \$indata);
	$consapp->run([@defcon, @_], undef, $indata_h);
	close($indata_h);
	return $indata;
}
