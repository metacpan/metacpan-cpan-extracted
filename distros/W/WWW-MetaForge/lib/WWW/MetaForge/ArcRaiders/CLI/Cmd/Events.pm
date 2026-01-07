package WWW::MetaForge::ArcRaiders::CLI::Cmd::Events;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Show event timers from the ARC Raiders API

use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

option active => (
  is    => 'ro',
  short => 'a',
  doc   => 'Show only currently active events',
);

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my $events = $app->api->event_timers;

  if ($self->active) {
    $events = [ grep { $_->is_active_now } @$events ];
  }

  # Sort chronologically: active events first (by time until end), then upcoming (by time until start)
  $events = [
    sort {
      my $a_active = $a->is_active_now;
      my $b_active = $b->is_active_now;

      # Active events come first
      return -1 if $a_active && !$b_active;
      return 1 if !$a_active && $b_active;

      # Both active: sort by time until end
      if ($a_active) {
        return ($a->minutes_until_end // 9999) <=> ($b->minutes_until_end // 9999);
      }

      # Both inactive: sort by time until start
      return ($a->minutes_until_start // 9999) <=> ($b->minutes_until_start // 9999);
    } @$events
  ];

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode(
      [ map { $_->_raw } @$events ]
    );
    return;
  }

  if (!@$events) {
    print "No events found.\n";
    return;
  }

  for my $event (@$events) {
    my $name   = $event->name // 'Unknown';
    my $map    = $event->map // '';
    my $status = $event->is_active_now ? '[ACTIVE]' : '';
    my $time_info = '';

    if ($event->is_active_now) {
      my $remaining = $event->time_until_end;
      $time_info = "ends in $remaining" if $remaining;
    } else {
      my $until = $event->time_until_start;
      $time_info = "in $until" if $until;
    }

    printf "%-30s  %-15s  %-10s  %s\n", $name, $map, $status, $time_info;
  }

  printf "\n%d event(s) found.\n", scalar(@$events);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge::ArcRaiders::CLI::Cmd::Events - Show event timers from the ARC Raiders API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  arcraiders events
  arcraiders events --active
  arcraiders events -a

  # JSON output
  arcraiders --json events

=head1 DESCRIPTION

This command displays event timers from the ARC Raiders API. Events are shown
in chronological order: currently active events appear first (sorted by time
remaining until end), followed by upcoming events (sorted by time until start).

For each event, the output displays:

=over 4

=item * Event name

=item * Map name (if available)

=item * Status indicator C<[ACTIVE]> for running events

=item * Time information (either "ends in X" or "in X")

=back

=head1 OPTIONS

=head2 --active, -a

Show only currently active events. This filters out upcoming events that
haven't started yet.

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
