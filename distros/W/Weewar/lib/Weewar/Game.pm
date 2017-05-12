# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::Game;
use strict;
use warnings;

use Carp;
require Weewar;
use base 'Weewar::Base';

sub _ATTRIBUTES { qw/id/ }
sub _ELEMENTS { 
    qw/name round state pendingInvites pace type url
       map mapUrl creditsPerBase initialCredits playingSince
      /;
}
sub _LISTS {
    ( players => ['player', 'Weewar::User' => '', 'name', \&_fix_player] )
}

sub _TRANSFORMS {
    ( playingSince   => __PACKAGE__->_TRANSFORM_DATE(),
      pendingInvites => __PACKAGE__->_TRANSFORM_BOOLEAN(),
    )
}

sub _get_xml {
    my $self = shift;
    my $id = $self->{id};
    croak "This game ($self) has no id" unless $id;
    return Weewar->_request("game/$id");
}

sub _root_tag { 'game' }

# adds "result" metadata to player object (when game state = finished)
sub _fix_player {
    my $player = shift;
    my $node   = shift;
    my $result = $node->getAttribute('result');
    $player->{result} = $result;
    return $player;
}

__PACKAGE__->mk_weewar_accessors;

1;

__END__

=head1 NAME

Weewar::Game - a weewar game

=head1 SYNOPSIS

   my $game = WeeWar::game->new({ id => 27093 });
   $game->name;
   
=head1 METHODS

=head2 name

Returns the name of the game

=head2 id

Returns the game's id

=head2 state

Returns the game's state, something like "lobby", "running",
"finished", etc.

=head2 round

Returns the current turn number if the game is in the running state.

=head2 pending_invites

Returns true if the game is still waiting for some players to accept
invites.  False otherwise.

=head2 pace

Returns the number of seconds before an idle player can be kicked.

=head2 type

Returns the game type

=head2 map

Returns the name of the map this game is using

=head2 map_url

Returns the URL of the current map's description page

=head2 credits_per_base

Returns the number of credits a base generates each turn

=head2 initial_credits

Returns the number of credits each player starts with

=head2 playing_since

If the game is in progress, returns a DateTime object representing
the game's start time.

=head2 players

Returns a list of C<Weewar::User>s that are playing this game.

=head1 SEE ALSO

See L<Weewar> for the main docs.

