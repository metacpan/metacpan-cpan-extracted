use strict;
use warnings;

package WWW::XBoxLive::Game;
{
  $WWW::XBoxLive::Game::VERSION = '1.123160';
}

# ABSTRACT: Represents an XBox Live game

use Object::Tiny qw{
  available_achievements
  available_gamerscore
  earned_gamerscore
  earned_achievements
  last_played
  percentage_complete
  title
};

1;


__END__
=pod

=head1 NAME

WWW::XBoxLive::Game - Represents an XBox Live game

=head1 VERSION

version 1.123160

=head1 SYNOPSIS

  my $game = WWW::XBoxLive::Game->new(%data);

=head1 ATTRIBUTES

=head2 available_achievements

The number of available achievements for this game.

=head2 available_gamerscore

The number of available gamerscore for this game.

=head2 earned_achievements

The number of earned achievements for this game.

=head2 earned_gamerscore

The number of earned gamerscore for this game.

=head2 last_played

The date the game was last played, in the format '12/31/2011'

=head2 percentage_complete

The percentage of the game complete, in the format '13%'

=head2 title

The title of the game.

=head1 SEE ALSO

=over 4

=item *

L<WWW::XBoxLive>

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

