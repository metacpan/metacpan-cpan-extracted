package Tie::Scalar::Decay;

use strict;

use Time::HiRes qw(time);    # if Time::HiRes isn't available for your
                             # system, then you can comment this out and
                             # it'll still work mostly.  However, test
                             # five will fail for obvious reasons

my $VERSION='1.1.1';

sub TIESCALAR {
	my $class = shift;
	my $self = {
		VALUE    => undef,
		PERIOD   => 5,
		FUNCTION => \&_defaultdecayfunction,
		@_
	};
	$self->{CREATION_TIME}=time;

	die("Tie::Scalar::Decay - invalid PERIOD.\n")
		unless($self->{PERIOD} =~ /^([0-9.]+)([smhd]?)$/);

	return bless $self, $class;
}

sub FETCH {
	my $self = shift;
	my $value=$self->{VALUE};

	return $value if(time < $self->{CREATION_TIME} + $self->_get_period());

	foreach(1..$self->_get_periods()) {
		if(ref($self->{FUNCTION}) eq 'CODE') {
			$value=&{$self->{FUNCTION}}($value);
		} else {
			eval($self->{FUNCTION});
		}
	}
	return $value;
}

sub STORE {
	my $self = shift;
	$self->{VALUE} = shift;
	$self->{CREATION_TIME}=time;
}

sub _defaultdecayfunction {
	my $value=$_[0];
	if($value=~/^-?[0-9\.]+$/) { return $value/2; }
	 else { return $value; }
}

sub _get_periods {
	my $self=shift;
	my $elapsedtime=time-$self->{CREATION_TIME};

	return int($elapsedtime/$self->_get_period());
}

sub _get_period {
	my $self=shift;
	my $period=$self->{PERIOD};
	my %mult = (
		's'=>1,
		'm'=>60,
		'h'=>3600,       # 60*60
		'd'=>86400,      # 60*60*24
	);
	$period=~s/^([0-9\.]+)([smhd]?)$/$1 * (($mult{$2})||1)/e;
	return $period;
}

1;
__END__

=head1 NAME

Tie::Scalar::Decay - Scalar variables that decay

=head1 SYNOPSIS

  use Tie::Scalar::Decay;

  tie my $scalar, 'Tie::Scalar::Decay', (
    VALUE => 32,
    FUNCTION => '$value-=1',
    PERIOD => 1
  );

  while($scalar>0) {
    print "$scalar\n";
    sleep(2);
  }

=head1 DESCRIPTION

This module allows you to tie a scalar variable whose value will change
regularly with time.  The default behaviour is for numeric values to
halve every time period (a la radioactive decay) and for non-numeric
values to be unchanged.

You can specify a custom decay function if you wish.

The following named parameters are supported:

=over 4

=item C<PERIOD>

Use C<PERIOD> to specify the time interval for changes.  This can be
either a numeric value, in which case it is taken to be a number of
seconds, or the following forms are also accepted:

    30s                    every thirty seconds
    10m                    every ten minutes
    1h                     every hour
    1d                     every day

Assigning a value to the variable causes the timer to be reset to zero,
so if at t=0 you set a value of 5 with a timeout of thirty seconds, then
wait twenty seconds and set the value again, then it will not decay
until t=50.  The default is a somewhat arbitrary 5 seconds.

=item C<VALUE>

Using the C<VALUE> hash key, you can specify an initial value for the
variable.  Defaults to undef.

=item C<FUNCTION>

This is how you can define your own custom decay functions.  This can
either be a string (in which case it is evalled as necessary, and should
alter the variable $value as it sees fit) or it can be a coderef, in
which case the subroutine is called as necessary, with the current value
as a parameter.  The sub is expected to return the new value.  If you
don't specify a function, it defaults to one which halves the value if it
is numeric, or leaves it as it is otherwise.

Note that whilst it may appear that your FUNCTION gets called every
PERIOD, it isn't really.  In reality, the value stored in the tied
scalar remains constant, and every time you try to read its value,
a temporary variable is created and FUNCTION gets called the appropriate
number of times before that is returned, thus generating the right
illusion.  Therefore, your FUNCTION should not depend on such things as
the absolute time.

=back

=head1 BUGS

Plenty, no doubt.  Please tell me if you find any.

One caveat is that it relies on Time::HiRes.  If your system doesn't
support this, then you can comment it out of the module and it'll
still mostly work.  You may get hurt by sub-second periods (they
still work but the granularity of the timer is only a second) and
very occasionally by boundary conditions if the load on your machine
is high.  Timing things with 1-second accuracy blows goats.

=head1 AUTHOR

David Cantrell <david@cantrell.org.uk>

This module was inspired by Marcel Grunauer's Tie::Scalar::Timeout.

=head1 COPYRIGHT

Copyright 2001 David Cantrell.

This module is licensed under the same terms as perl itself.

=head1 SEE ALSO

Tie::Scalar(3pm), Tie::Scalar::Timeout(3)

=cut
