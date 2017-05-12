package VCI::VCS::Hg::Committable;
use Moose::Role;

use DateTime;

sub _build_time {
    my $self = shift;
    my $text = $self->project->x_get(['raw-rev', $self->revision]);
    $text =~ /^# Date (\d+) (-)?(\d+)$/ms;
    my ($time, $minus, $offset_seconds) = ($1, $2, $3);
    my $offset_hours    = $offset_seconds / 3600;
    my $offset_fraction = $offset_hours - int($offset_hours);
    my $offset_minutes  = $offset_fraction * 60;
    # Minus means plus, and absence of minus means...minus.
    my $direction = $minus ? '+' : '-';
    my $zone = $direction . sprintf('%02u%02u', $offset_hours, $offset_minutes);
    return DateTime->from_epoch(epoch => $time, time_zone => $zone);
}

1;
