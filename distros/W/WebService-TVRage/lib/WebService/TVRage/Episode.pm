#
#===============================================================================
#         FILE:  Episode.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::Episode;
use Mouse;

has '_episodeHash' => ( is => 'rw' );

sub getTitle {
    my $self = shift;
    return $self->_episodeHash()->{title} // '';
}

sub getEpisodeNo {
    my $self = shift;
    return $self->_episodeHash()->{epnum} // '';
}

sub getAirDate {
    my $self = shift;
    return $self->_episodeHash()->{airdate} // '';
}

sub getWebLink {
	my $self = shift;	
    return $self->_episodeHash()->{link} // '';
}

1;

=head1 NAME

WebService::TVRage::Episode - Object returned by WebService::TVRage::EpisodeList->getEpisode(), Contains a List of episodes for all seasons

=head1 SYNOPSIS
   
    my $episode = $episodeList->getEpisode();
    $episode->getAirDate();

=head1 Methods

=over 1

=item _episodeHash
    
This is populated by WebService::TVRage::EpisodeList->getEpisode(), you shouldn't need to edit this, but you might want to look at it with Data::Dumper
 
=back

=head2 getTitle()

    $episode->getTitle()

Returns the title of the episode as a string

=head2 getEpisodeNo()

    $episode->getEpisodeNo()

Returns the episode number of which episode it is within the season

=head2 getAirDate()

    $episode->getAirDate()

Returns the date that the episode first aired as string like '2006-10-09'

=head2 getWebLink()

	$episode->getWebLink()

Returns a URL to TVRage's website for the particular episode.

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut
