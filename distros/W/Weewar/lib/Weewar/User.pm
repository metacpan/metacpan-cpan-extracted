# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::User;
use strict;
use warnings;

use Carp;
require Weewar;
use base 'Weewar::Base';

# my own mini WSDL, i guess
sub _ATTRIBUTES { 
    qw/name id/ 
}
sub _ELEMENTS { 
    qw/points profile
       draws victories losses
       accountType readyToPlay gamesRunning lastLogin
       basesCaptured creditsSpent/;
}
sub _LISTS { 
    ( favoriteUnits    => ['unit',   'Weewar::Unit' => 'code',      ],
      preferredPlayers => ['player', 'Weewar::User' => 'name',      ],
      preferredBy      => ['player', 'Weewar::User' => 'name',      ],
      games            => ['game',   'Weewar::Game' => ''    , 'id' ],
    );
}

sub get {
    my ($self, $what) = @_;
    return $self->{rating} if($self->{rating} && $what eq 'points');
    return $self->{points} if($self->{points} && $what eq 'rating');
    return $self->SUPER::get($what);
}

sub _TRANSFORMS {
    ( lastLogin   => __PACKAGE__->_TRANSFORM_DATE(),
      readyToPlay => __PACKAGE__->_TRANSFORM_BOOLEAN(),
    )
}

sub _get_xml {
    my $self = shift;
    my $name = $self->{name};
    croak "This user ($self) has no name" unless $name;
    return Weewar->_request("user/$name");
}

sub _root_tag { 'user' }

__PACKAGE__->mk_weewar_accessors;
__PACKAGE__->mk_ro_accessors('rating', 'result');

package Weewar::Unit; # no need to bless units
sub new { return $_[1]->{code} }

1;

__END__

=head1 NAME

Weewar::User - a user of weewar

=head1 SYNOPSIS

   # make a user
   my $user = WeeWar::User->new({ name => 'jrockway' });

   # then get their data
   my $points = $user->points;
   my @units = $user->favorite_units
   my @games = $user->games;
   # etc.
   
=head1 METHODS

=head2 name

Returns the user's username.

=head2 id

Returns the user's id.

=head2 points

=head2 rating

Returns the player's score, usually around 1500.

=head2 profile

Returns the URL of the user's profile page.

=head2 draws

Returns the number of times the user has ended a game with a draw.

=head2 victories

Returns the number of times the user has won.

=head2 losses

Returns the number of times the user has lost.

=head2 account_type

Returns the user's account type.

=head2 ready_to_play

Returns a boolean (undef or "true) indicating whether or not the
user is "ready to play".

=head2 games_running

Returns the number of games the user is currently playing.

=head2 last_login

Returns a DateTime object representing the last time the user logged in.

=head2 bases_captured

Returns the number of basses the user has captured.

=head2 credits_spent

Returns the number of credits the user has spent.

=head2 favorite_units

Returns a list of the user's favorite units.

=head2 preferred_players

Returns a list of C<Weewar::User> objects representing the user's
preferred players.

=head2 preferred_by

Returns a list of C<Weewar::User> objects representing players that
prefer this user.

=head2 games

Returns a list of C<Weewar::Game> objects representing games that the
user has played or is playing.

=head2 result

If this User object was returned from C<< Weewar::Game->players >> and
the game is finished, this field will contain the win/loss status of
the game.  

For example, the C<result> of the user that won will be C<victory>.

=head1 INTERNAL METHODS

=head2 get

If you call this method, you will die.

=head1 SEE ALSO

See L<Weewar> for the main docs.

