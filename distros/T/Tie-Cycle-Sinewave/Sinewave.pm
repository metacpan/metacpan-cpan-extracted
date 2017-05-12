package Tie::Cycle::Sinewave;

use strict;

=head1 NAME

Tie::Cycle::Sinewave - Cycle through a series of values on a sinewave

=head1 VERSION

This document describes version 0.05 of Tie::Cycle::Sinewave, released
2007-11-07.

=cut

use vars '$VERSION';

$VERSION = '0.05';

=head1 SYNOPSIS

This module allows you to make a scalar iterate through the values
on a sinewave. You set the maximum and minimum values and the number
of steps and you're set.

    use strict;
    use Tie::Cycle::Sinewave;

    tie my $cycle, 'Tie::Cycle::Sinewave', {
        min    => 10,
        max    => 50,
        period => 12,
    };
    printf("%0.2f\n", $cycle) for 1..10;

=head1 PARAMETERS

A number of parameters can be passed in to the creation of the tied
object. They are as follows (in order of likely usefulness):

=over 4

=item min

Sets the minimum value. If not specified, 0 will be used as a
default minimum.

=item max

Sets the maximum value. Should be higher than min, but the values
will be swapped if necessary. If not specified, 100 will be used
as a default maximum.

=item period

Sets the period of the curve. The cycle will go through this many
values from min to max. If not specified, 20 will be used as a
default. If period is set to 0, it will be silently changed to 1,
to prevent internal calculations from attempting to divide by 0.

=item start_max

Optional. When set to 1 (or anything), the cyle will start at the
maximum value. (C<startmax> exists as a an alias).

=item start_min

Optional. When set to 1 (or anything), the cyle will start at the
minimum value. (C<startmin> exists as a an alias). If neither
C<start_max> nor C<start_min> are specified, it will at the origin
(thus, mid-way between min and max and will move to max).

=item at_max

Optional. When set to a coderef, will be executed when the cycle
reaches the maximum value. This allows the modification of the
cycle, I<e.g.> modifying the minimum value or the period. (The key
C<atmax> exists as an alias).

=item at_min

Optional. When set to a coderef, will be executed when the cycle
reaches the minimum value. This allows the modification of the
cycle, I<e.g.> modifying the maximum value or the period. (The key
C<atmin> exists as an alias).

=back

=cut

use constant PI   => 3.1415926535_8979323846_2643383280;
use constant PI_2 => 2 * PI;

sub TIESCALAR {
    my $class = shift;
    my %param = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

    my $min    = exists $param{min}    ? +$param{min}    : 0;
    my $max    = exists $param{max}    ? +$param{max}    : 100;
    my $period = exists $param{period} ? +$param{period} : 20;

    $period = 1 if $period == 0;

    $param{start_max} = delete $param{startmax} if exists $param{startmax};
    $param{start_min} = delete $param{startmin} if exists $param{startmin};

    $param{at_max} = delete $param{atmax} if exists $param{atmax};
    $param{at_min} = delete $param{atmin} if exists $param{atmin};

    my $start =
          exists $param{start_max} ? PI / 2
        : exists $param{start_min} ? PI / 2 * 3
        : 0
    ;

    my $self = {
        min    => $min,
        max    => $max,
        angle  => $start,
        prev   => $start,
        period => $period,
    };

    $self->{at_max} = $param{at_max} if exists $param{at_max} and ref($param{at_max}) eq 'CODE';
    $self->{at_min} = $param{at_min} if exists $param{at_min} and ref($param{at_min}) eq 'CODE';

    $self = bless $self, $class;

    $self->_validate_min_max();
    $self;
}

sub FETCH {
    my $self     = shift;
    my $sin_prev = sin( $self->{prev} );
    my $sin      = sin( $self->{angle}  );
    my $delta    = PI_2 / $self->{period};

    $self->{prev}  = $self->{angle};
    $self->{angle} += $delta;
    my $sin_next   = sin( $self->{angle} );

    my $prev_vs_curr = $sin_prev <=> $sin;
    my $curr_vs_next = $sin      <=> $sin_next;

    if( -1 == $prev_vs_curr and 1 == $curr_vs_next ) {
        # the previous is smaller than the current,
        # and the current is greater than the next,
        # therefore we must be at the top of the wave.
        exists $self->{at_max} and $self->{at_max}->($self);

        # Clamp the value to 0 < x < 2PI. For long running cycles this
        # should improve accuracy (if P.J. Plauger it to be believed).
        if( $self->{prev} > PI_2 ) {
            $self->{prev} -= PI_2;
            $self->{angle} -= PI_2;
        }
    }
    elsif( 1 == $prev_vs_curr and -1 == $curr_vs_next ) {
        # at the bottom (trough) of the wave
        exists $self->{at_min} and $self->{at_min}->($self);
    }

    (($sin + 1) / 2) * ($self->{max} - $self->{min}) + $self->{min};
}

sub STORE {
    my $self = shift;
    $self->{angle} = $self->{prev} = $_[0];
}

=head1 OBJECT METHODS

You can call methods on the underlying object (which you access with the
C<tied()> function). Have a look at the file C<eg/callback> for an
example on what you might want to do with these.

=over 4

=item min

When called without a parameter, returns the current minimum value. When
called with a (numeric) parameter, sets the new current minimum value.
The previous value is returned.

  my $min = (tied $cycle)->min();
  (tied $cycle)->min($min - 20);

=cut

sub min {
    my $self = shift;
    my $old = $self->{min};
    if( @_ ) {
        $self->{min} = shift;
        $self->_validate_min_max();
    }
    $old;
}

=item max

When called without a parameter, returns the current maximum value. When
called with a (numeric) parameter, sets the new current maximum value.
The previous value is returned.

  my $max = (tied $cycle)->max();
  (tied $cycle)->max($max * 10);

When C<min> or C<max> are modified, a consistency check is run to ensure
that C<min <= max>. If this check fails, the two values are quietly swapped
around.

=cut

sub max {
    my $self = shift;
    my $old = $self->{max};
    if( @_ ) {
        $self->{max} = shift;
        $self->_validate_min_max();
    }
    $old;
}

=item period

When called without a parameter, returns the current period. When
called with a (numeric) parameter, sets the new current period.
The previous value is returned.

=cut

sub period {
    my $self = shift;
    my $old = $self->{period};
    if( @_ ) {
        $self->{period} = shift;
        $self->{period} = 1 if $self->{period} == 0;
    }
    $old;
}

sub _validate_min_max {
    ($_[0]->{min}, $_[0]->{max}) = ($_[0]->{max}, $_[0]->{min}) if $_[0]->{max} < $_[0]->{min};
}

=item angle

Returns the current angle of the sine, which is guaranteed to be
in the range C< 0 <= angle <= 2*PI>.

=back

=cut

sub angle {
    my $self = shift;
    if( $self->{prev} > PI_2 ) {
        $self->{prev} -= PI_2;
        $self->{angle} -= PI_2;
    }
    $self->{angle}
}

=head1 AUTHOR

David Landgren.

=head1 SEE ALSO

 L<Tie::Cycle>
 L<HTML::Rainbow>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-cycle-sinewave@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Cycle-Sinewave>.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2007 David Landgren, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Tie::Cycle::Sinewave
