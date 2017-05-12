#===============================================================================
#         FILE:  EpisodeListRequest.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#      COMPANY:  Home
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::EpisodeListRequest;
use Mouse;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use WebService::TVRage::EpisodeList;
has 'episodeID' => ( is => 'rw');
has 'URL' => ( is => 'rw',
               default => 'http://www.tvrage.com/feeds/episode_list.php?sid=');

sub getEpisodeList {
	my $self = shift;
	my $uA = LWP::UserAgent->new( timeout => 20);
	my $episodeListReq = HTTP::Request->new(GET => $self->URL . $self->episodeID);
	my $episodeListResponse = $uA->request($episodeListReq);
	print $episodeListResponse->error_as_HTML unless $episodeListResponse->is_success;
	my $xml = new XML::Simple;
	my $processedXML = $xml->XMLin( $episodeListResponse->decoded_content, (ForceArray => ['Season', 'episode']));
	#return undef if ref $processedXML->{name};
    return undef unless defined $processedXML->{Episodelist};
	my $object = WebService::TVRage::EpisodeList->new();
	$object->_episodeListHash($processedXML);
    return $object;
}

1;

=head1 NAME

WebService::TVRage::EpisodeListRequest - Requests A List of Episodes for a show using TVRage's XML Service

=head1 SYNOPSIS
   
	my $heroes = WebService::TVRage::EpisodeListRequest->new();
	$heroes->episodeID('8172'); 
	my $episodeList = $heroes->getEpisodeList();

=head1 Methods

=head2 new()

    my $heroes = WebService::TVRage::EpisodeListRequest->new( episodeID => '8172');

Constructor object for creating a request to get episode information for the specified show. 

=over 1

=item episodeID
    
This is the TVRage's ID for ths show.  Use WebService::TVRage::ShowSearchRequest to find out what the id of your show is.
 
=item URL
    
This is the TVRage URL that the request gets sent to, you shouldn't need to edit this. 
 
=back

=head2 getEpisodeList()

	$heroes->getEpisodeList()

Sends a request to TVRage for which ever show you specified with episodeID and returns a WebService::TVRage::EpisodeList object

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut


