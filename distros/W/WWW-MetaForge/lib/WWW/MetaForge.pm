package WWW::MetaForge;
our $VERSION = '0.001';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl client for MetaForge gaming APIs

use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge - Perl client for MetaForge gaming APIs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # ARC Raiders API
  use WWW::MetaForge::ArcRaiders;

  my $api = WWW::MetaForge::ArcRaiders->new;
  my $items = $api->items(search => 'Ferro');

  # Generic Game Map Data API
  use WWW::MetaForge::GameMapData;

  my $maps = WWW::MetaForge::GameMapData->new;
  my $markers = $maps->map_data(map => 'Dam');

=head1 DESCRIPTION

WWW::MetaForge provides Perl interfaces to the MetaForge gaming APIs.

=head2 Available APIs

=over 4

=item * L<WWW::MetaForge::ArcRaiders> - ARC Raiders game data (items, quests, traders, events, maps)

=item * L<WWW::MetaForge::GameMapData> - Generic game map marker data

=back

=head1 CLI

The distribution includes the C<arcraiders> command-line tool:

  arcraiders items --search Ferro
  arcraiders item ferro-i
  arcraiders events --active
  arcraiders traders

=head1 ATTRIBUTION

This module uses the MetaForge API: L<https://metaforge.app>

Data is community-maintained. Please attribute MetaForge when using
this data in public projects.

=head1 SEE ALSO

L<https://metaforge.app/arc-raiders/api>

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
