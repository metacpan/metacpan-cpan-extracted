package WWW::MetaForge::ArcRaiders::Result::EventTimer;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Event timer/schedule result object

use Moo;
use Types::Standard qw(Str ArrayRef HashRef Maybe InstanceOf);
use DateTime;
use WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot;
use namespace::clean;

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has map => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has icon => (
  is  => 'ro',
  isa => Maybe[Str],
);

# Schedule times - array of TimeSlot objects
has times => (
  is      => 'ro',
  isa     => ArrayRef[InstanceOf['WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot']],
  default => sub { [] },
);

has _raw => (
  is  => 'ro',
  isa => HashRef,
);

sub from_hashref {
  my ($class, $data) = @_;

  my @slots = map {
    WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_hashref($_)
  } @{ $data->{times} // [] };

  return $class->new(
    name   => $data->{name},
    map    => $data->{map},
    icon   => $data->{icon},
    times  => \@slots,
    _raw   => $data,
  );
}

# Build from grouped API data (array of raw event entries with same name+map)
sub from_grouped {
  my ($class, $name, $map, $events) = @_;

  my @slots = map {
    WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot->from_epoch_ms(
      $_->{startTime}, $_->{endTime}
    )
  } @$events;

  # Sort slots by start time
  @slots = sort { $a->start <=> $b->start } @slots;

  return $class->new(
    name   => $name,
    map    => $map,
    icon   => $events->[0]{icon},
    times  => \@slots,
    _raw   => { name => $name, map => $map, events => $events },
  );
}

# Check if event is currently active based on current UTC time
sub is_active_now {
  my ($self) = @_;
  my $now = DateTime->now(time_zone => 'UTC');

  for my $slot ($self->times->@*) {
    return 1 if $slot->contains($now);
  }
  return 0;
}

# Get next scheduled time slot (returns TimeSlot object)
sub next_time {
  my ($self) = @_;
  my $now = DateTime->now(time_zone => 'UTC');

  my @sorted = sort { $a->start <=> $b->start } $self->times->@*;

  # Find next slot that starts after now
  for my $slot (@sorted) {
    return $slot if $slot->start > $now;
  }

  # Wrap around to first slot tomorrow
  return $sorted[0] if @sorted;
  return undef;
}

# Get current active time slot (returns TimeSlot object)
sub current_slot {
  my ($self) = @_;
  my $now = DateTime->now(time_zone => 'UTC');

  for my $slot ($self->times->@*) {
    return $slot if $slot->contains($now);
  }
  return undef;
}

# Format minutes as human-readable duration
sub _format_duration {
  my ($self, $minutes) = @_;
  return undef unless defined $minutes && $minutes >= 0;

  if ($minutes < 60) {
    return "${minutes}m";
  }
  my $hours = int($minutes / 60);
  my $mins = $minutes % 60;
  return $mins > 0 ? "${hours}h ${mins}m" : "${hours}h";
}

# Time until next event start
sub time_until_start {
  my ($self) = @_;
  my $minutes = $self->minutes_until_start;
  return defined $minutes ? $self->_format_duration($minutes) : undef;
}

# Minutes until next event start (for sorting)
sub minutes_until_start {
  my ($self) = @_;
  my $next = $self->next_time or return undef;
  return $next->minutes_until_start;
}

# Time until current active slot ends
sub time_until_end {
  my ($self) = @_;
  my $minutes = $self->minutes_until_end;
  return defined $minutes ? $self->_format_duration($minutes) : undef;
}

# Minutes until current active slot ends (for sorting)
sub minutes_until_end {
  my ($self) = @_;
  my $slot = $self->current_slot or return undef;
  return $slot->minutes_until_end;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::Result::EventTimer - Event timer/schedule result object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $events = $api->event_timers;
  for my $event (@$events) {
      say $event->name;
      say "  Active!" if $event->is_active_now;
      if (my $next = $event->next_time) {
          say "  Next: ", $next->start, " - ", $next->end;
      }
  }

=head1 DESCRIPTION

Represents an event timer/schedule from the ARC Raiders game.

=head1 ATTRIBUTES

=head2 name

Event name.

=head2 map

Map where event occurs.

=head2 icon

URL to event icon image.

=head2 times

ArrayRef of L<WWW::MetaForge::ArcRaiders::Result::EventTimer::TimeSlot> objects.

=head1 METHODS

=head2 from_hashref

  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_hashref(\%data);

Construct from API response (legacy format with times array).

=head2 from_grouped

  my $event = WWW::MetaForge::ArcRaiders::Result::EventTimer->from_grouped(
    $name, $map, \@events
  );

Construct from grouped API data. Takes an array of raw event entries
(with startTime/endTime timestamps) that share the same name and map.

=head2 is_active_now

  if ($event->is_active_now) { ... }

Returns true if current time is within a scheduled time slot.

=head2 next_time

  my $slot = $event->next_time;
  say "Starts at ", $slot->start if $slot;

Returns next upcoming TimeSlot object, or undef if none scheduled.

=head2 current_slot

  my $slot = $event->current_slot;
  say "Ends at ", $slot->end if $slot;

Returns currently active TimeSlot object, or undef if not active.

=head2 time_until_start

  my $duration = $event->time_until_start;
  say "Event starts in $duration" if $duration;

Returns human-readable duration until next event start (e.g., "2h 30m", "45m").
Returns undef if no upcoming events.

=head2 minutes_until_start

  my $minutes = $event->minutes_until_start;

Returns numeric minutes until next event start. Useful for sorting events.
Returns undef if no upcoming events.

=head2 time_until_end

  my $duration = $event->time_until_end;
  say "Event ends in $duration" if $duration;

Returns human-readable duration until current event ends (e.g., "1h 15m").
Returns undef if event is not currently active.

=head2 minutes_until_end

  my $minutes = $event->minutes_until_end;

Returns numeric minutes until current active event ends. Useful for sorting.
Returns undef if event is not currently active.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-metaforge>

  git clone https://github.com/Getty/p5-www-metaforge.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
