#!perl -T

use Test::More tests => 1;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdodeint;

my $app = Text::NumericData::App::txdodeint->new();

my @defcon = ("--config=testdata/default.conf");

# Those to should produce the same data (heavy rounding needed because
# of interpolation error).
#txdconstruct -N=.0f -n=6 \
#  '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]; [4]=1/3*[1]**3 + 7*[1] + 2.4 - 0.5*[1]**2; [5] = 1/3*[1]**3 - 1/2*[1]**2 - 4.6 + [1]**3'
#txdconstruct -n=6 '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]' \
#| txdodeint --interpolate=spline -N=.0f --timediv=10 --rksteps=4 \
#   -i=2.4 -i.=-4.6 'D0=[2]-[1]; D1=[3]+3*[1]**2'

my $indata = construct('-n=6', '[1]=C0-1; [2] = [1]**2 + 7; [3] = [1]**2 - [1]');
# Analytical integrals for comparison.
my $cmpdata = construct(
	'-N=.0f', '-n=6', '[1] = C0-1;'
.	'[2] = [1]**2 + 7; [3] = [1]**2 - [1];'
.	'[4] = 1/3*[1]**3 + 7*[1] + 2.4 - 0.5*[1]**2;'
.	'[5] = 1/3*[1]**3 - 1/2*[1]**2 - 4.6 + [1]**3'
);


ok( txdtest( [ @defcon
,	'-N=.0f', '--interpolate=spline', '--timediv=10', '--rksteps=4'
,	'-i=2.4', '-i.=-4.6', 'D0=[2]-[1]; D1=[3]+3*[1]**2' ]
,	$cmpdata ), 'mixed polynomial' );

sub txdtest
{
	my ($args, $cmpdata) = @_;
	my $outstr;
	open(my $in, '<', \$indata);
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	# For two strings, I don't need file comparison, but whatever.
	if($outstr eq $cmpdata)
	{
		return 1;
	}
	else
	{
		print STDERR "difference in data .. debug";
		print STDERR "expected:\n$cmpdata\n";
		print STDERR "got:\n$outstr\n";
		return 0;
	}
}

sub construct
{
	my $consapp = Text::NumericData::App::txdconstruct->new();
	my $indata;
	open(my $indata_h, '>', \$indata);
	$consapp->run([@defcon, @_], undef, $indata_h);
	close($indata_h);
	return $indata;
}
