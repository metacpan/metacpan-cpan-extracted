package WWW::MetaForge::ArcRaiders::CLI::Cmd::Event;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Show details for a single event timer
our $VERSION = '0.002';
use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

option map => (
  is     => 'ro',
  format => 's',
  short  => 'm',
  doc    => 'Filter by map name (e.g., dam, spaceport)',
);

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my $event_name = $args->[0];
  unless ($event_name) {
    print "Usage: arcraiders event <name> [--map <map>]\n";
    print "Example: arcraiders event \"Cold Snap\" --map dam\n";
    return;
  }

  # Events don't have IDs, so search by name (and optionally map)
  my $events = $app->api->event_timers;

  # Filter by name first
  my @matches = grep {
    $_->name && lc($_->name) eq lc($event_name)
  } @$events;

  # Try partial match if exact fails
  if (!@matches) {
    @matches = grep {
      $_->name && $_->name =~ /\Q$event_name\E/i
    } @$events;
  }

  # Filter by map if specified
  if ($self->map && @matches) {
    @matches = grep {
      $_->map && lc($_->map) eq lc($self->map)
    } @matches;
  }

  my $event;
  if (@matches == 1) {
    $event = $matches[0];
  } elsif (@matches > 1) {
    print "Multiple events match '$event_name':\n";
    for my $m (@matches) {
      printf "  %s (%s)\n", $m->name // 'Unknown', $m->map // 'all';
    }
    print "\nUse --map to specify: arcraiders event \"$event_name\" --map <map>\n";
    return;
  }

  unless ($event) {
    print "Event '$event_name' not found.\n";
    return;
  }

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($event->_raw);
    return;
  }

  _print_event_details($event);
}

sub _print_event_details {
  my ($event) = @_;

  print "=" x 60, "\n";
  printf "%s\n", $event->name // 'Unknown';
  print "=" x 60, "\n";

  _print_field("Map",  $event->map // 'All Maps');
  _print_field("Icon", $event->icon);

  # Current status
  my $status = $event->is_active_now ? "ACTIVE" : "Inactive";
  _print_field("Status", $status);

  if ($event->is_active_now) {
    my $ends_in = $event->time_until_end;
    _print_field("Ends in", $ends_in) if $ends_in;
  } else {
    my $starts_in = $event->time_until_start;
    _print_field("Starts in", $starts_in) if $starts_in;
  }

  if ($event->times && @{$event->times}) {
    print "\nSchedule (UTC):\n";
    my @sorted = sort { $a->start <=> $b->start } @{$event->times};
    for my $slot (@sorted) {
      printf "  %s - %s\n", $slot->start->strftime('%H:%M'), $slot->end->strftime('%H:%M');
    }
  }
}

sub _print_field {
  my ($label, $value) = @_;
  return unless defined $value;
  printf "%-15s %s\n", "$label:", $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Event - Show details for a single event timer

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # Show details for an event by name
  arcraiders event "Cold Snap"

  # Filter by specific map
  arcraiders event "Cold Snap" --map dam

  # Partial name matching
  arcraiders event "Cold"

  # JSON output
  arcraiders --json event "Cold Snap"

=head1 DESCRIPTION

Display detailed information about a single event timer. Searches for events by
name using exact match first, falling back to partial/case-insensitive match if
no exact match is found.

The detail view shows:

=over 4

=item * Event name and map

=item * Current status (active/inactive)

=item * Time until start or end

=item * Description with word wrapping

=item * Complete schedule with time slots

=item * Active days of the week

=back

If multiple events match the search criteria, displays a list of matches and
suggests using C<--map> to narrow results.

=head1 OPTIONS

=head2 --map, -m

Filter results by map name. Useful when the same event appears on multiple maps.

  arcraiders event "Cold Snap" --map dam
  arcraiders event "Cold Snap" -m spaceport

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
