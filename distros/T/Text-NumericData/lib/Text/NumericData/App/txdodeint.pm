package Text::NumericData::App::txdodeint;

use Text::NumericData::App;
use Text::NumericData::Calc qw(formula_function);

use strict;

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

my $infostring = "integrate a given ordinary differential equation system along a coordinate

Usage:
	pipe | txdodeint [parameters] [<ode> [<initval> [initval ...]]] | pipe

By default, the first column in the data is used as time coordinate for which
the expression(s) of the ODE are defined. The derivative can be a
system of ODEs. The time derivative values shall be stored in the array members
D0 .. Dn, with the current corresponding variable values available in V0 .. Vn
and the corresponding values of the (interpolated) auxilliary timeseries
from the piped data in [1] .. [m]. There are also the auxillary array values
A0 .. Ak (to be used at your leisure to store/load values) and the constants
C0 .. Cl (initialised from program parameters).

For convenience, the basic setup of time column, ODE, and intial values can
be given directly on the command line without mentioning parameter names.
The integrated values are written out at the points in time given by the input
data. For each variable (size of the array V), a column is appended.

Example for a simple system (constant acceleration):

	D0=V1; D1=A0; D2=C0*[1]

Assuming the time in column 1 and the constant acceleration in C0,
this computes the evolution of the covered distance V0 via the numerically
accelerated speed V1 and also directly from the analytically accelerated
speed as variable V2, to give a hint about the accuracy of the numerical
integration.

The employed integration method is a standard Runge-Kutta scheme with up to
4 stages, which should be fine for any application where you consider a
humble Perl script for your numerical integration. A comparison of the fully
numerical with the fully analytical solution can be constructed via the
pipeline

	txdconstruct -n=11 '[1]=C0-1' \\
	| txdodeint --rksteps=1 'D0=V1; D1=3' 0 0 \\
	| txdcalc '[4]=3/2*[1]**2; [5]=[4] ? ([2]-[4])/[4] : 0' \\
	| txdfilter -N=%g 'integration test' 't/s' 's/m' 'v/m' 's_ref/m' 'error'

With rksteps>1, you will not see any difference in this example. In general,
the choice of integration stages, time step and interpolation might have
significant influence on your results. A simple test of the quality of the
chosen integration employs trivial polynomials:

	txdconstruct -n=11 '[1]=C0-1' \\
	| txdodeint --rksteps=2 --timediv=1 \\
	  'D0=1; D1=2*[1]; D2=3*[1]**2; D3=4*[1]**3' \\
	     0     0         0            0 \\
	| txdcalc '[2]-=[1]; [3]-=[1]**2; [4]-=[1]**3; [5]-=[1]**4' \\
	| txdfilter -N=g 'integration order test' x err0 err1 err2 err3

These polynomials can actually be solved exactly to machine precision
(depending on rksteps value) and smaller time steps would introduce
rounding errors here from the summation. Finally, another classic example,
the Lorenz attractor:

	txdconstruct -n=5001 '[1]=(C0-1)/100' | txdodeint --timediv=1 \\
	  'D0=10*(V1-V0); D1=28*V0-V1-V0*V2; D2=-8/3*V2+V0*V1' \\
	  20 -20 1

More practical applications actually have some more data columns besides
the time in the input data (measurements) and involve derivative expressions
that make use of this data-driven time-dependence.";

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;
	my @pars =
	(
		'timecol', 1, 't'
		,	'Column for the (time) coordinate the ODE shall be advanced on.'
		.	' In the ODE, you can access it via [1] if the column is 1 (just like'
		.	' any other variable of the (interpolated) input data).'
	,	'ode', 'D0 = 1', 'e'
		,	'The ordinary differential equation system. The return value of the generated'
		.	' function does not matter, only that you set the values of the D array.'
	,	'varinit', [], 'i'
		,	'array of initial values; must match number of derivatives from ODE'
	,	'vartitle', [], ''
		,	'array of column titles for the integrated variables'
	,	'const', [], 'n'
		,	'array of constants to use in ODE'
	,	'rksteps', '4', 'k'
		,	'steps (stages) of the RK integration scheme, only 4 supported right now'
	,	'timestep', 0, 's'
		,	'desired time step size (see timediv)'
	,	'timediv', 10, ''
		,	'Divide input time intervals by that to get the integration time step. If'
		.	' timestep is set to non-zero, still an integer division is used, but one that'
		.	' yields a step close to the desired one (subject to rounding).'
	,	'interpolate', 'spline', ''
		,	'type of interpolation to use for intermediate points: spline or linear'
	,	'debug', 0, 'd'
		,	'give some info that may help debugging, >1 increasing verbosity'
	,	'plainperl', 0, ''
		,	'Use plain Perl syntax for formula for full force without confusing the'
		.	' intermediate parser.'
	);
	return $class->SUPER::new
	({
		parconf=>{ info=>$infostring }
	,	pardef=>\@pars
	,	filemode=>1
	,	pipemode=>1
	,	pipe_init=>\&prepare
	,	pipe_file=>\&process_file
	});
}

sub prepare
{
	my $self = shift;
	my $p = $self->{param};

	$p->{ode} = shift(@{$self->{argv}})
		if(@{$self->{argv}});
	$p->{varinit} = $self->{argv}
		if(@{$self->{argv}});

	$self->{rk} = {};
	my $rk = $self->{rk};
	$rk->{stages} = 0;
	$rk->{a} = [];
	$rk->{b} = [];
	$rk->{c} = [];

	# The generic rksteps might be something funny (like 33, 45) in case
	# I intend to introduce methods that differ in stages and order.
	if($p->{rksteps} == 1) # Euler
	{
		$rk->{stages} = 1;
		$rk->{a} = [ [0] ];
		$rk->{b} = [ 1 ];
		$rk->{c} = [ 0 ];
	}
	if($p->{rksteps} == 2) # Heun
	{
		$rk->{stages} = 2;
		$rk->{a} =
		[
			[ 0, 0 ]
		,	[ 1, 0 ]
		];
		$rk->{b} = [ 0.5, 0.5 ];
		$rk->{c} = [ 0, 1 ];
	}
	if($p->{rksteps} == 3) # Simpson
	{
		$rk->{stages} = 3;
		$rk->{a} =
		[
			[ 0,   0, 0 ]
		,	[ 0.5, 0, 0 ]
		,	[ -1,  2, 0 ]
		];
		$rk->{b} = [ 1/6, 4/6, 1/6 ];
		$rk->{c} = [ 0, 0.5, 1 ];
	}
	if($p->{rksteps} == 4) # RK44 method
	{
		$rk->{stages} = 4;
		$rk->{a} =
		[
			[0,   0,   0, 0]
		,	[0.5, 0,   0, 0]
		,	[0,   0.5, 0, 0]
		,	[0,   0,   1, 0]
		];
		$rk->{b} = [1./6, 1./3, 1./3, 1./6];
		$rk->{c} = [0, 0.5, 0.5, 1];
	}

	return $self->error("Invalid RK setup (nothing for $p->{rksteps} stages).")
		unless($rk->{stages});
	if($p->{debug})
	{
		print STDERR "Using RK scheme with $rk->{stages} stages, tableau:\n";
		for(my $s=0; $s<$rk->{stages}; ++$s)
		{
			print STDERR sprintf( '%5.3f |'.(' %5.3f' x $rk->{stages})."\n"
			,	$rk->{c}[$s], @{$rk->{a}[$s]} );
		}
		print STDERR '------|'.('------' x $rk->{stages})."\n";
		print STDERR sprintf( '      |'.(' %5.3f' x $rk->{stages})."\n"
		,	@{$rk->{b}} );
	}

	# The ODE stored as sub reference. Work arrays are V and D in addition
	# to A and C.
	$self->{ode} = formula_function( $p->{ode}
	,	{plainperl=>$p->{plainperl}, verbose=>$p->{debug}}
	,	'V', 'D' );
	return $self->error("Failed to compile your ODE.")
		unless defined $self->{ode};

	return 0;
}

sub process_file
{
	my $self = shift;
	my $p = $self->{param};
	my $txd = $self->{txd};

	$self->{A} = [];
	$self->{C} = [];
	@{$self->{C}} = @{$p->{const}};

	my $cols = $txd->columns();
	unless($cols > 0 and @{$txd->{data}})
	{
		print STDERR "No data?\n";
		$txd->write_all($self->{out});
		return;
	}
	my $tc = $p->{timecol}-1;
	if($tc < 0 or $tc >= $cols)
	{
		$txd->{data} = [];
		$txd->{titles} = [];
		print STDERR "Bad time index.\n";
		$txd->write_all($self->{out});
		return;
	}

	# The initial values tell us how many variables to expect,
	# prepare titles for added columns and also set initial
	# values.
	my $vars = @{$p->{varinit}};
	my $vi=0;
	if(@{$txd->{raw_header}}){ $txd->write_header($self->{out}); }
	if(@{$txd->{titles}})
	{
		for(my $vi=0; $vi<$vars; ++$vi)
		{
			$txd->{titles}[$cols+$vi] = defined $p->{vartitle}[$vi]
			?	$p->{vartitle}[$vi]
			:	'var'.($vi+1);
		}
		print {$self->{out}} ${$txd->title_line()};
	}
	# We'll print data on the fly, not bothering to clog memory with
	# storage of the integrated variables. Also might interfere with the
	# interpolation otherwise.
	my @val = @{$p->{varinit}};
	print {$self->{out}} ${$txd->data_line([
		@{$txd->{data}[0]}[0..($cols-1)]
	,	@val ])};
	for(my $mi=1; $mi< @{$txd->{data}}; ++$mi)
	{
		# Integrate from to to t1, using a fixed step that fits into the interval.
		my $t0 = $txd->{data}[$mi-1][$tc];
		my $t1 = $txd->{data}[$mi][$tc];
		my $div = $p->{timestep}
		?	int(abs(($t1-$t0)/$p->{timestep})+0.5)
		:	$p->{timediv};
		$div = 1
			if $div < 1;
		my $step = ($t1-$t0)/$div;
		print STDERR "int $t0 to $t1 div $div step $step\n"
			if $p->{debug};
		for(my $si=0; $si<$div; ++$si)
		{
			$self->rk_step($t0+$si*$step, $step, \@val);
		}
		print {$self->{out}} ${$txd->data_line([
			@{$txd->{data}[$mi]}[0..($cols-1)]
		,	@val ])};
	}
}

# Compute one RK step with given time increment.
sub rk_step
{
	my $self = shift;
	my ($t, $dt, $val) = @_;

	my $rk = $self->{rk};
	my $vars = @{$val};

	my @work; # Storage for the derivatives in the stages.
	my @tmp;  # Storage for the current variables.

	# Initialise them with the correct size.
	for(my $s=0; $s<$rk->{stages}; ++$s)
	{
		for(my $v=0; $v<$vars; ++$v)
		{
			$work[$s][$v] = 0;
		}
	}
	for(my $v=0; $v<$vars; ++$v)
	{
		$tmp[$v] = 0;
	}

	# Collect the stage derivatives.
	$self->eval_ode($t, $val, $work[0]);
	print STDERR "deriv 0: @{$work[0]}\n"
		if $self->{param}{debug} > 1;
	for(my $stage=1; $stage < $rk->{stages}; ++$stage)
	{
		for(@tmp){ $_ = 0 }
		for(my $substage = 0; $substage < $stage; ++$substage)
		{
			if($rk->{a}[$stage][$substage] != 0)
			{ # Does the condition really save work?
				for(my $i=0; $i<$vars; ++$i)
				{
					$tmp[$i] += $rk->{a}[$stage][$substage]*$work[$substage][$i];
				}
			}
		}
		for(my $i=0; $i<$vars; ++$i){ $tmp[$i] *= $dt; $tmp[$i] += $val->[$i]; }
		$self->eval_ode($t+$rk->{c}[$stage]*$dt, \@tmp, $work[$stage]);
		print STDERR "deriv $stage: @{$work[$stage]}\n"
			if $self->{param}{debug} > 1;
	}

	# Compute the definite derivative, apply and be done.
	for(@tmp){ $_ = 0 }
	for(my $stage=0; $stage < $rk->{stages}; ++$stage)
	{
		for(my $i=0; $i<$vars; ++$i)
		{
			$tmp[$i] += $rk->{b}[$stage]*$work[$stage][$i];
		}
	}
	for(my $i=0; $i<$vars; ++$i)
	{
		$val->[$i] += $tmp[$i]*$dt;
	}
}

# Evaluate the ODE once, interpolating in the input data for time-varying
# parameters.
sub eval_ode
{
	my $self = shift;
	my ($t, $var, $deriv) = @_;
	my @fd; # interpolated data set here
	$fd[0] = $self->{txd}->set_of($t, $self->{param}{timecol}-1);
	print STDERR "fd: @{$fd[0]}\n"
		if $self->{param}{debug} > 1;
	print STDERR "V: @{$var}\n"
		if $self->{param}{debug} > 1;
	# @{$deriv} == 0 since rk_step intialised it
	$self->{ode}->(\@fd, $self->{A}, $self->{C}, $var, $deriv);
}

1;
