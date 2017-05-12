#===============================================================================
#         FILE:  ShowSearchRequest.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#      COMPANY:  Home
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::ShowSearchRequest;

use Mouse;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use WebService::TVRage::ShowList;
has 'showTitle' => ( is => 'rw');
has 'URL' => ( is => 'rw',
               default => 'http://www.tvrage.com/feeds/search.php?show=');

sub search {
	my $self = shift;
	my $showTitle = shift;
	$self->showTitle($showTitle);
	my $uA = LWP::UserAgent->new( timeout => 20);
	my $showSearchReq = HTTP::Request->new(GET => $self->URL . $self->showTitle);
	my $showSearchResponse = $uA->request($showSearchReq);
	print $showSearchResponse->error_as_HTML unless $showSearchResponse->is_success;
	my $xml = new XML::Simple;
	my $processedXML = $xml->XMLin( $showSearchResponse->decoded_content, (ForceArray => ['show']));
	return undef if $processedXML == 0;
	my $object = WebService::TVRage::ShowList->new();
	$object->_showListHash($processedXML);
    return $object;
}

1;

=head1 NAME

WebService::TVRage::ShowSearchRequest - Requests A List of shows using TVRage's XML Service

=head1 SYNOPSIS
   
    my $heroesSearch = WebService::TVRage::ShowSearchRequest->new( showTitle => 'Heroes' );
	$heroesSearch->search();

=head1 Methods

=head2 new()

    my $heroesSearch = WebService::TVRage::ShowSearchRequest->new( showTitle => 'Heroes' );

Constructor object for creating a request to search for Shows by title. 

=over 1

=item showTitle
    
Set this to the title of the show you are searching for.
 
=back

=head2 search()

    $heroes->search()

Sends a request to TVRage for which ever show you specified with the showTitle attribute and returns a WebService::TVRage::ShowList object

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut
