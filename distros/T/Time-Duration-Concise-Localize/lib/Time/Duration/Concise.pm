package Time::Duration::Concise;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Time::Seconds;
use POSIX qw(ceil);
use Carp;
use Tie::Hash::LRU;

our $VERSION = '2.61';    ## VERSION

our %popular;
our $lru = tie %popular, 'Tie::Hash::LRU', 100;

=head1 NAME

Time::Duration::Concise

=head1 DESCRIPTION

Time::Duration::Concise is an improved approach to convert concise time duration to string representation.

=cut

our %LENGTH_TO_PERIOD = (
    86400 => 'day',
    3600  => 'hour',
    60    => 'minute',
    1     => 'second',
);

our %PERIOD_SIZES = (
    'd' => 86400,
    'h' => 3600,
    'm' => 60,
    's' => 1,
);

our @KNOWN_UNITS = qw[d h m s];

our $KNOWN_UNITS_ = 'dhms';

=head1 SYNOPSIS

    use Time::Duration::Concise;

    my $duration = Time::Duration::Concise->new(
        interval => '1h20m'
    );

    # Intervals can have decimal values
    # 1.5h etc

    $duration = Time::Duration::Concise->new(
        interval => '1.5h'
    );

=head1 FIELDS

=head2 interval (REQUIRED)

Concise Format

The format is an integer followed immediatley by its duration
identifier.  White-space will be ignored.

The following table explains the format.

  identifier   duration
  ----------   --------
           d   day
           h   hour
           m   minute
           s   second

# Intervals can have decimal values
Example : 1.5h

=cut

=head1 METHODS

=head2 interval

Returns the given time interval.

=cut

sub interval {
    my ($self) = @_;
    return $self->{'_interval'};
}

=head2 seconds

The number of seconds represented by this time interval.

=cut

sub seconds {
    my ($self) = @_;

    return $self->{'_seconds'} if $self->{'_seconds'};

    my $interval    = $self->{'_interval'};
    my $known_units = $KNOWN_UNITS_;

    my $seconds = 0;

    # These should be integers, but we might need to have 0.5m
    while ($interval =~ s/([+-]?\d*\.?\d+)([$known_units])//) {
        my $amount = $1;
        my $units  = $2;
        $seconds += $amount * $PERIOD_SIZES{$units};
    }

    if ($interval ne '') {

        # We had something which didn't match the above, which renders this unparseable
        Carp::croak("Bad format supplied [" . $interval . "]: unknown key.");
    }
    $self->{'_seconds'} = int $seconds;
    return $self->{'_seconds'};
}

=head2 minutes

The number of minutes represented by this time interval.

=cut

sub minutes {
    my ($self) = @_;
    return $self->duration->{'minutes'};
}

=head2 hours

The number of hours represented by this time interval.

=cut

sub hours {
    my ($self) = @_;
    return $self->duration->{'hours'};
}

=head2 days

The number of days represented by this time interval.

=cut

sub days {
    my ($self) = @_;
    return $self->duration->{'days'};
}

=head2 weeks

The number of week represented by this time interval.

=cut

sub weeks {
    my ($self) = @_;
    return $self->duration->{'weeks'};
}

=head2 months

The number of months represented by this time interval.

=cut

sub months {
    my ($self) = @_;
    return $self->duration->{'months'};
}

=head2 as_string

Concise time druation to string representation.

=cut

sub as_string {
    my ($self, $precision) = @_;
    my $time_frames = $self->_duration_array($precision);
    return join(' ', @$time_frames);
}

=head2 as_concise_string

Concise time druation to conscise string representation.

=cut

sub as_concise_string {
    my ($self, $precision) = @_;
    $precision ||= 10;
    my $time_frames         = $self->_duration_array($precision);
    my @concise_time_frames = map {
        s/\s+//rg =~ /([-|\+]?\d+[A-Za-z]{1})/ig;
        $1;
    } @$time_frames;
    $self->{"_duration_array_$precision"} = undef;
    return join('', @concise_time_frames);
}

=head2 normalized_code

The largest division of Duration

=cut

sub normalized_code {
    my ($self) = @_;
    my @keys = sort @KNOWN_UNITS;

    my $entry_code = '0s';
    while ($entry_code eq '0s' and my $period = shift @keys) {
        my $period_length = $PERIOD_SIZES{$period};
        if (not $self->seconds % $period_length) {
            my $period_size = $self->seconds / $period_length;
            $entry_code = $period_size . $period;
        }
    }
    return $entry_code;
}

=head2 duration_array

Concise time druation to array

[ { value => 1, unit => 'day' }, { value => 2, unit => 'hours' } ]

=cut

sub duration_array {
    my ($self, $precision) = @_;
    my $durations = $self->_duration_array($precision);
    my @duration_distribution;
    foreach my $d (@$durations) {
        my @d_value_unit = split(' ', $d);
        push(
            @duration_distribution,
            {
                'value' => $d_value_unit[0],
                'unit'  => $d_value_unit[1]});
    }
    return \@duration_distribution;
}

sub _duration_array {
    my ($self, $precision) = @_;

    $precision ||= 10;

    return $self->{"_duration_array_$precision"}
        if $self->{"_duration_array_$precision"};

    my $pretty_format = $self->duration->{'time'}->pretty;
    $pretty_format =~ s/minus /-/ig;

    my @time_frame;
    my $precision_counter = 1;
    foreach my $frame (split(',', $pretty_format)) {
        next if $precision_counter > $precision;
        chomp $frame;
        $frame =~ s/^\s+|\s+$//g;
        $frame =~ s/s$//ig;
        $frame =~ /^([-|\+]?\d+\s)/ig;

        # Make sure we gets the number
        # to avoid Use of uninitialized warning
        my $value = $1;
        if (defined $value && $value) {

            $value =~ s/\s+//ig;

            $frame = '' if $value == 0;
            $frame .= 's' if $value > 1;

            if ($frame) {
                push(@time_frame, $frame);
                $precision_counter++;
            }
        }
    }
    if (!scalar @time_frame) {
        push(@time_frame, '0 second');
    }
    $self->{"_duration_array_$precision"} = \@time_frame;
    return \@time_frame;
}

=head2 multiple_units_of

Shorthand to call time methods

=cut

sub multiple_units_of {
    my ($self, $unit) = @_;
    # two is multiple!
    return ($self->_minimum_number_of($unit) >= 2) ? 1 : 0;
}

=head2 minimum_number_of

Returns the minimum number of the given period.

=cut

sub minimum_number_of {
    my ($self, $unit) = @_;
    return ceil($self->_minimum_number_of($unit));
}

sub _minimum_number_of {
    my ($self, $unit) = @_;
    my $orig_unit = $unit;
    $unit =~ s/s$// if (length($unit) > 1);    # Chop plurals, but not 's' itself
    $unit = substr($unit, 0, 1);
    $unit = 'mo' if $orig_unit =~ /^months|^mo/ig;

    my %unit_maps = (
        'mo' => 'months',
        'w'  => 'weeks',
        'd'  => 'days',
        'h'  => 'hours',
        'm'  => 'minutes',
        's'  => 'seconds',
    );
    my $method = $unit_maps{$unit};
    confess "Cannot determine period for $orig_unit" unless ($method);

    return $self->$method;
}

=head2 duration

Returns HASH of duration with the following keys

	    'time'    # Time::Seconds object
	    'years'
	    'months'
	    'weeks'
	    'days'
	    'hours'
	    'minutes'
	    'seconds'

=cut

sub duration {
    my ($self) = @_;
    return $self->{'_duration'} if $self->{'_duration'};
    my $time_    = Time::Seconds->new($self->seconds);
    my $duration = {
        'time'    => $time_,
        'years'   => $time_->years,
        'months'  => $time_->months,
        'weeks'   => $time_->weeks,
        'days'    => $time_->days,
        'hours'   => $time_->hours,
        'minutes' => $time_->minutes,
        'seconds' => $time_->seconds
    };
    $self->{'_duration'} = $duration;
    return $duration;
}

=head2 get_time_layout

Return the duration hash with regards to precision

=cut

sub get_time_layout {
    my ($self, $precision) = @_;
    my $duration    = $self->duration;
    my $time_layout = {
        duration       => $self->seconds,
        day            => $duration->{'day'},
        hour           => $duration->{'hour'},
        second         => $duration->{'seconds'},
        display_string => $self->as_string($precision)};
    return $time_layout;
}

=head2 new

Object constructor

=cut

sub new {    ## no critic (RequireArgUnpacking)
    my $class = shift;
    my %params_ref = ref($_[0]) ? %{$_[0]} : @_;

    my $interval = $params_ref{'interval'};

    confess "Missing required arguments"
        unless defined $interval;

    if ($popular{$interval}) {
        ## Helps in multiple calling, it would really save the time
        return $popular{$interval};
    }

    if (defined $interval) {
        Carp::croak("Invalid time interval") if $interval eq '';
    }

    # Try our best to make it parseable.
    $interval =~ s/\s//g;
    $interval = lc $interval;

    # All numbers implies a number of seconds.
    if ($interval !~ /[A-Za-z]/) {
        $interval .= 's';
    }

    my $self = {
        _interval => $interval,
    };
    my $obj = bless $self, $class;
    $popular{$interval} = $obj;
    return $obj;
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-duration-concise-localize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Duration-Concise-Localize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Time::Duration::Concise


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Duration-Concise-Localize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Time-Duration-Concise-Localize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Time-Duration-Concise-Localize>

=item * Search CPAN

L<http://search.cpan.org/dist/Time-Duration-Concise-Localize/>

=back

=cut

1;    # End of Time::Duration::Concise
