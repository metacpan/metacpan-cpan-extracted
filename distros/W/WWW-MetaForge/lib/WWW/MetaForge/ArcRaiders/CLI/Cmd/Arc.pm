package WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Show details for a single arc

use Moo;
use MooX::Cmd;
use MooX::Options;
use JSON::MaybeXS;

sub execute {
  my ($self, $args, $chain) = @_;
  my $app = $chain->[0];

  my $arc_id = $args->[0];
  unless ($arc_id) {
    print "Usage: arcraiders arc <id>\n";
    print "Example: arcraiders arc minor-storm\n";
    return;
  }

  # Try fetching by ID first (API supports id= query param)
  my $result = $app->api->arcs_paginated(id => $arc_id);
  my $arcs = $result->{data};

  # If not found by ID, search all arcs
  if (!@$arcs) {
    $arcs = $app->api->arcs_all;
    my ($match) = grep {
      ($_->id && lc($_->id) eq lc($arc_id)) ||
      ($_->name && lc($_->name) eq lc($arc_id))
    } @$arcs;
    $arcs = $match ? [$match] : [];
  }

  unless (@$arcs) {
    print "Arc '$arc_id' not found.\n";
    return;
  }

  my $arc = $arcs->[0];

  if ($app->json) {
    print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($arc->_raw);
    return;
  }

  _print_arc_details($arc);
}

sub _print_arc_details {
  my ($arc) = @_;

  print "=" x 60, "\n";
  printf "%s\n", $arc->name // 'Unknown';
  print "=" x 60, "\n";

  _print_field("ID",   $arc->id);
  _print_field("Type", $arc->type);

  if ($arc->maps && @{$arc->maps}) {
    _print_field("Maps", join(", ", @{$arc->maps}));
  }

  if ($arc->duration) {
    my $mins = int($arc->duration / 60);
    my $secs = $arc->duration % 60;
    my $duration_str = $mins > 0 ? "${mins}m ${secs}s" : "${secs}s";
    _print_field("Duration", $duration_str);
  }

  if ($arc->cooldown) {
    my $mins = int($arc->cooldown / 60);
    _print_field("Cooldown", "${mins} minutes");
  }

  if ($arc->description) {
    print "\nDescription:\n";
    my $desc = $arc->description;
    $desc =~ s/(.{1,58})\s/$1\n  /g;  # Word wrap
    print "  $desc\n";
  }

  my @reward_parts;
  push @reward_parts, $arc->xp_reward . " XP" if $arc->xp_reward;
  push @reward_parts, $arc->coin_reward . " Coins" if $arc->coin_reward;

  if (@reward_parts) {
    print "\nRewards:\n";
    print "  ", join(", ", @reward_parts), "\n";
  }

  if ($arc->loot && @{$arc->loot}) {
    print "\nLoot Drops:\n";
    for my $loot (@{$arc->loot}) {
      if (ref $loot eq 'HASH') {
        my $name = $loot->{item} // $loot->{name} // next;
        my $chance = $loot->{chance};
        if (defined $chance) {
          printf "  %-40s %d%%\n", $name, int($chance * 100);
        } else {
          printf "  %s\n", $name;
        }
      }
    }
  }

  if ($arc->last_updated) {
    print "\nLast Updated: ", $arc->last_updated, "\n";
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

WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc - Show details for a single arc

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # Show arc details by ID
  arcraiders arc minor-storm

  # Show arc details by name
  arcraiders arc "Salvage Run"

  # Output as JSON
  arcraiders --json arc minor-storm

=head1 DESCRIPTION

This command displays detailed information about a single ARC (mission/activity)
in Arc Raiders. You can search by either the arc's ID or name.

The command first attempts to find the arc by ID. If no match is found, it
searches through all arcs by both ID and name (case-insensitive).

Output includes:

=over 4

=item * Name and ID

=item * Type (mission category)

=item * Available maps

=item * Duration (time limit)

=item * Cooldown period

=item * Description text

=item * Rewards (XP and Coins)

=item * Loot drop table with drop chances

=item * Last updated timestamp

=back

If the C<--json> flag is used, outputs the raw API response as JSON instead of
the formatted display.

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
