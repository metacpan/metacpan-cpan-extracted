package WebService::TVRage;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.11';



1;

=head1 NAME

WebService::TVRage - Perl extension for using TVRage's XML Service

=head1 SYNOPSIS

	use WebService::TVRage::EpisodeListRequest;
	use WebService::TVRage::ShowSearchRequest;
	my $searchReq =   WebService::TVRage::ShowSearchRequest->new();
	my $searchResults = $searchReq->search('Heroes');
	my $heroFromSearch = $searchResults->getShow('Heroes');
	print $heroFromSearch->getLink(), "\n";
	print $heroFromSearch->getCountry(), "\n";
	print $heroFromSearch->getStatus(), "\n";
	my $heroes =  WebService::TVRage::EpisodeListRequest->new( 'episodeID' => $heroFromSearch->getShowID() );
	my $episodeList = $heroes->getEpisodeList();
	print $episodeList->getNumSeasons(), "\n";
	my $episode = $episodeList->getEpisode(1,3);
	print $episode->getTitle(), "\n";
	print $episode->getAirDate(), "\n";
	foreach my $showtitle ($searchResults->getTitleList()) {
        my $show = $searchResults->getShow($showtitle);
                print $show->getLink();
    	}

=head1 DESCRIPTION

This module itself doesn't do anything, just a place holder so you can install will 'WebService::TVRage' See the objects for their various functions.  The convention of this module is that if requests fail, they return empty strings when strings are requested and undef when objects are requested.

=head1 AUTHOR

Kyle Brandt , kyle@kbrandt.com , http://www.kbrandt.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kyle Brandt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
