package WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A time slot with start and end DateTime objects
our $VERSION = '0.002';

use Moo;
use Types::Standard qw(InstanceOf);
use DateTime;
use namespace::clean;


has start => (
  is       => 'ro',
  isa      => InstanceOf['DateTime'],
  required => 1,
);


has end => (
  is       => 'ro',
  isa      => InstanceOf['DateTime'],
  required => 1,
);


sub from_hashref {
  my ($class, $data) = @_;

  # New API format: startTime/endTime as millisecond timestamps
  if (exists $data->{startTime}) {
    return $class->from_epoch_ms($data->{startTime}, $data->{endTime});
  }

  # Legacy format: start/end as HH:MM strings
  my $now = DateTime->now(time_zone => 'UTC');
  my $today = $now->clone->truncate(to => 'day');

  my ($start_h, $start_m) = split /:/, $data->{start};
  my ($end_h, $end_m) = split /:/, $data->{end};

  my $start = $today->clone->set(hour => $start_h, minute => $start_m);
  my $end = $today->clone->set(hour => $end_h, minute => $end_m);

  # Handle overnight slots (e.g., 23:00 - 01:00)
  if ($end <= $start) {
    # Slot crosses midnight - determine which day based on current time
    if ($now < $end) {
      # Early morning (after midnight, before slot end) - start was yesterday
      $start->subtract(days => 1);
    } else {
      # Before midnight or after slot end - end is tomorrow
      $end->add(days => 1);
    }
  }

  return $class->new(
    start => $start,
    end   => $end,
  );
}


sub from_epoch_ms {
  my ($class, $start_ms, $end_ms) = @_;

  my $start = DateTime->from_epoch(
    epoch     => int($start_ms / 1000),
    time_zone => 'UTC',
  );
  my $end = DateTime->from_epoch(
    epoch     => int($end_ms / 1000),
    time_zone => 'UTC',
  );

  return $class->new(
    start => $start,
    end   => $end,
  );
}


sub contains {
  my ($self, $dt) = @_;
  $dt //= DateTime->now(time_zone => 'UTC');
  return $dt >= $self->start && $dt < $self->end;
}


sub minutes_until_start {
  my ($self, $dt) = @_;
  $dt //= DateTime->now(time_zone => 'UTC');
  my $delta = $self->start->epoch - $dt->epoch;
  return int($delta / 60);
}


sub minutes_until_end {
  my ($self, $dt) = @_;
  $dt //= DateTime->now(time_zone => 'UTC');
  my $delta = $self->end->epoch - $dt->epoch;
  return int($delta / 60);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot - A time slot with start and end DateTime objects

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $slot = WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_hashref({
      start => '14:00',
      end   => '15:00',
    });

    say $slot->start;  # DateTime object
    say $slot->end;    # DateTime object

    if ($slot->contains) {
      say "Event is active now!";
    }

=head1 DESCRIPTION

Represents a scheduled time slot with DateTime objects for start and end times.
All times are in UTC.

=head2 start

DateTime object for slot start time.

=head2 end

DateTime object for slot end time.

=head2 from_hashref

    my $slot = TimeSlot->from_hashref({ start => "HH:MM", end => "HH:MM" });

Construct from API response hash with HH:MM strings or millisecond timestamps.

=head2 from_epoch_ms

    my $slot = TimeSlot->from_epoch_ms($start_ms, $end_ms);

Construct from epoch milliseconds timestamps.

=head2 contains

    if ($slot->contains) { ... }
    if ($slot->contains($datetime)) { ... }

Returns true if the given DateTime (or now) is within this slot.

=head2 minutes_until_start

    my $mins = $slot->minutes_until_start;

Returns minutes until this slot starts.

=head2 minutes_until_end

    my $mins = $slot->minutes_until_end;

Returns minutes until this slot ends.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-metaforge/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
