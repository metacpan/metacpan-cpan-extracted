
package Datum;
use threads::tbb;
use constant DEBUG => 0;

sub new {
	my $class = shift;
	tie my @array, "threads::tbb::concurrent::array";
	my $self = bless {
		state => tied(@array),
		@_
	}, $class;
	return $self;
}

sub end {
	my $self = shift;
	return $self->{state}->FETCHSIZE;
}

sub fetch {
	my $self = shift;
	return $self->{state}->FETCH(@_);
}

use Time::HiRes qw(sleep);

sub callback {
	my $self = shift;
	my $range = shift;

	my $w = $threads::tbb::worker||0;
	warn("I am worker $w, self = %{( @{[%$self]} )}\n") if DEBUG;
	$self->{state}->PUSH( [$range->begin(), $range->end(), $w, $self->{x} ] );
	sleep 0.1;
}

1;
