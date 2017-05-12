# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::HQ;
use strict;
use warnings;

use Carp;

=head1 NAME

Weewar::HQ - your weewar "headquarters"

=head1 SYNOPSIS

   my $hq = Weewar::HQ->new({ user => 'username',
                              key  => 'api key',
                           });

   my @games   = $hq->games; # my games
   my @need_me = $hq->in_need_of_attention; # games that need my attention

=head1 METHODS

=head2 new({ user => $username, key => $api_key })

Create a new instance and populate it from the Weewar web service.
user and key are required.

=cut

sub new {
    my ($class, $args) = @_;
    
    croak 'need hashref of args' unless ref $args eq 'HASH';
    croak 'need key'             unless $args->{key};
    croak 'need user'            unless $args->{user};

    my $self = bless $args => $class;

    # get XML
    my $xml = Weewar->_request('headquarters', { username => $args->{user}, 
                                                 password => $args->{key},
                                               });
    my @game_nodes = $xml->findnodes('/games/game');

    my @needs_attention;
    my @games;
    for my $game_node (@game_nodes){
        my $id = [$game_node->getElementsByTagName('id')]->[0]->textContent;
        my $needs_attention = eval { 
            $game_node->getAttributeNode('inNeedOfAttention')->textContent
        };

        my $game = Weewar::Game->new({ id => $id });
        push @games, $game;
        push @needs_attention, $game 
          if $needs_attention && $needs_attention eq 'true';
    }

    $self->{games} = \@games;
    $self->{inNeedOfAttention} = \@needs_attention;
    
    return $self;
}

=head2 games

Returns a list of C<Weewar::Game>s that are in your headquarters.

=cut

sub games { return @{$_[0]->{games}} }

=head2 in_need_of_attention

Returns a list of <Weewar::Game>s that need your attention.

=cut

sub in_need_of_attention { return @{$_[0]->{inNeedOfAttention}} }

=head1 SEE ALSO

See L<Weewar> for more information.

=cut

1;
