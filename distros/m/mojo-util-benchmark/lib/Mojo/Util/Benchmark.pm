package Mojo::Util::Benchmark;
use Mojo::Base -base;

use Exporter 'import';
use Time::HiRes qw(gettimeofday);

our @EXPORT_OK = qw(
    benchmark
);

our $VERSION = '0.0.1';

has 'digits' => 12; # nanoseconds
has 'lastTimer';
has 'output' => 0;
has 'timers' => sub { {} };

=head2 average

    Run a callback a number of times and return the average time.
    If no iterations are given, the default of 10 will be used.
    If no digits are given, the default of 12 will be used.

    Returns the average time.

=cut

sub average {
    my ($self, $callback, $iterations, $digits) = @_;

    $digits ||= $self->digits;

    my @series = $self->series($callback, $iterations, $digits);

    my $sum = 0;
    $sum += $_ for @series;

    return sprintf("%0.${digits}f", $sum / @series);
}

=head2 benchmark

    Create a new benchmark object.

=cut

sub benchmark {
    return Mojo::Util::Benchmark->new(@_);
}

=head2 microseconds

    Set the number of digits to 8.
    Returns the object.

=cut

sub microseconds {
    my $self = shift;

    $self->digits(8);

    return $self;
}

=head2 milliseconds

    Set the number of digits to 4.
    Returns the object.

=cut

sub milliseconds {
    my $self = shift;

    $self->digits(4);

    return $self;
}

=head2 nanoseconds

    Set the number of digits to 12.
    Returns the object.

=cut

sub nanoseconds {
    my $self = shift;

    $self->digits(12);

    return $self;
}

=head2 print

    Print the elapsed time for a timer.

=cut

sub print {
    my ($self, $name, $digits) = @_;

    $digits ||= $self->timers->{$name}->{digits};

    my $duration = $self->timers->{$name}->{stop} - $self->timers->{$name}->{start};

    printf("%s: %0.${digits}f\n", $name, $duration);
}

=head2 seconds

    Set the number of digits to 0.
    Returns the object.

=cut

sub seconds {
    my $self = shift;

    $self->digits(0);

    return $self;
}

=head2 series

    Run a callback a number of times and return the elapsed times.
    If no iterations are given, the default of 10 will be used.
    If no digits are given, the default of 12 will be used.

    Returns an array ref of elapsed times.

=cut

sub series {
    my ($self, $callback, $iterations, $digits) = @_;

    $iterations ||= 10;
    $digits ||= $self->digits;

    my @series;

    for (1 .. $iterations) {
        $self->start("Iteration $_");

        $callback->();

        push @series, sprintf("%0.${digits}f", $self->stop("Iteration $_"));
    }

    return wantarray ? @series : \@series;
}

=head2 start

    Start a timer.
    If no name is given, the timer will be named 'elapsed'.
    If no digits are given, the default of 4 will be used.

    Returns the object.

=cut

sub start {
    my ($self, $name, $digits) = @_;

    $name ||= 'elapsed';
    $digits ||= $self->digits;

    $self->lastTimer($name);

    my $start = gettimeofday();

    $self->timers->{$self->lastTimer} = {
        start => $start,
        digits => $digits,
    };

    return $self;
}

=head2 stop

    Stop a timer.
    If no name is given, the last timer started will be stopped.
    If no digits are given, the default of 5 will be used.
    If output is set, the elapsed time will be printed to STDOUT.

    Returns the elapsed time.

=cut

sub stop {
    my ($self, $name, $digits) = @_;

    $name ||= $self->lastTimer;
    $digits ||= $self->timers->{$self->lastTimer}->{digits};

    my $end = gettimeofday();

    $self->timers->{$name}->{ stop } = $end;

    my $duration = $self->timers->{$name}->{stop} - $self->timers->{$name}->{start};

    if ($self->output) {
        $self->print($name, $digits);
    }

    return $duration;
}

1;
