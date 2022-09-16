# Weather::GHCN::TimingStats.pm - class for capturing performance timing statistics

# To Do:
# - prevent stop without matching start
# - prevent start after start
# - add reset($timer) method

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::TimingStats - collect timing statistics for GHCN modules and scripts

=head1 VERSION

version v0.0.002

=head1 SYNOPSIS

  use Weather::GHCN::TimingStats qw(:all);


=head1 DESCRIPTION

The B<Weather::GHCN::TimingStats> module provides a class and methods that are
used to collect timing statistics from within GHCN modules or from
application scripts that use GHCN modules.

The module is primarily for use by module Weather::GHCN::StationTable.

=cut

use v5.18;  # minimum for Object::Pad
use Object::Pad 0.66 qw( :experimental(init_expr) );

package Weather::GHCN::TimingStats;
class   Weather::GHCN::TimingStats;

our $VERSION = 'v0.0.002';

use Carp;
use Const::Fast;
use Time::HiRes;

const my $EMPTY  => q();    # empty string

field $timer_href { {} };

=head1 METHODS

=head2 new ()

Create a new TimingStats object.

=head2 start($timer)

Start a timer labelled $timer.  Timer labels prefixed with underscore
(_) are considered to be internal and not included in the overall
duration.

=cut

method start ($timer) {
    $timer_href->{$timer}->{START} = [Time::HiRes::gettimeofday];
    return;
}

=head2 stop ($timer, $note='')

Stop the timer labelled $timer, with an optional note.

=cut

method stop ($timer, $note=$EMPTY) {
    $timer_href->{$timer}->{DUR} += Time::HiRes::tv_interval($timer_href->{$timer}->{START},[Time::HiRes::gettimeofday]);

    $timer_href->{$timer}->{NOTE} = $note
        if $note;

    return;
}

=head2 get_timers ()

Get a sorted list of all the timer labels that have been created so
far by invoking the start() method.

=cut

method get_timers () {
    return (sort keys $timer_href->%*);
}

=head2 get_duration($timer)

Get the time that has elapsed for the timer labelled $timer.

=cut

method get_duration ($timer) {
    return $timer_href->{$timer}->{DUR};
}

=head2 get_note ($timer)

Get the note associated with the timer labelled $timer.

=cut

method get_note ($timer) {
    return $timer_href->{$timer}->{NOTE};
}

=head2 finish ()

Finish this set of timers and calculate the overall duration, excluding
the duration of any internal timers (those with labels that are prefixed
with '_').  The overall duration is associated with label '_Overall'.

=cut

method finish () {
    my @warnings;
    
    foreach my $k ( keys $timer_href->%* ) {
        if ( $timer_href->{$k}->{START} and not exists $timer_href->{$k}->{DUR} ) {
            push @warnings, '*W* forcing stop of timer ' . $k;
            $self->stop($k);
        }
    }
    
    # calculate the time not captured by other timing categories
    $timer_href->{'_Other'}->{DUR} = $timer_href->{'_Overall'}->{DUR};

    foreach my $k ( keys $timer_href->%* ) {
        next if $k =~ m{ \A ( _ | [(]internal[)] ) }xms;
        $timer_href->{'_Other'}->{DUR} -= $timer_href->{$k}->{DUR};
    }

    return @warnings;
}

=head2 DOES

Defined by Object::Pad.  Included for POD::Coverage.

=head2 META

Defined by Object::Pad.  Included for POD::Coverage.

=cut

1;
