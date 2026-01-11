package WWW::MetaForge;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Perl client for MetaForge gaming APIs
our $VERSION = '0.002';
use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MetaForge - Perl client for MetaForge gaming APIs

=head1 VERSION

version 0.002

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
