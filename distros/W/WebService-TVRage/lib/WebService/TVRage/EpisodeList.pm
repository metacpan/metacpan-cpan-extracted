#===============================================================================
#         FILE:  EpisodeList.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#      COMPANY:  Home
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::EpisodeList;
use Mouse;
use WebService::TVRage::Episode;
use Data::Dumper;
has '_episodeListHash' => ( is => 'rw' );

sub getNumSeasons {
	my $self = shift;	
	my $noSeasons = $self->_episodeListHash()->{totalseasons} // '';
	return $noSeasons;
}

sub getNumEpsInSeason {
	my $self = shift;
	my $season = shift;
	$season -= 1;
	return 0 unless defined $self->_episodeListHash()->{Episodelist}{Season}[$season];
	my $noEps =  @{$self->_episodeListHash()->{Episodelist}{Season}[$season]{episode}} // '';
	return $noEps;
}

sub getEpisode {
	my $self = shift;
	my $season = shift;
	my $episode = shift;
	$episode--; $season--;
	my $object =  WebService::TVRage::Episode->new();
	return undef unless defined $self->_episodeListHash()->{Episodelist}{Season}[$season]{episode}[$episode];	
	$object->_episodeHash($self->_episodeListHash()->{Episodelist}{Season}[$season]{episode}[$episode]);
	return $object;
}

1;

=head1 NAME

WebService::TVRage::EpisodeList - Object returned by WebService::TVRage::EpisodeListRequest, Contains a List of episodes for all seasons

=head1 SYNOPSIS
   
    my $heroes = WebService::TVRage::EpisodeListRequest->new();
    $heroes->episodeID('8172'); 
    my $episodeList = $heroes->getEpisodeList();
	$episodeList->getNumSeasons();

=head1 Methods

=over 1

=item _episodeListHash
    
This is populated by WebService::TVRage::EpisodeListRequest, you shouldn't need to edit this, but you might want to look at it with Data::Dumper
 
=back

=head2 getNumSeasons()

    $episodeList->getNumSeasons()

Returns the number of Seasons there have been for the show.

=head2 getNumEpsInSeasons()

    $episodeList->getNumSeasons('2')

Returns the number of episodes for whatever season is specified as an argument.

=head2 getEpisode()

    $episodeList->getEpisode(1,3)

Takes two arguments, season then Episode number and returns a WebService::TVRage::Episode object for that episode.

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com


=cut
