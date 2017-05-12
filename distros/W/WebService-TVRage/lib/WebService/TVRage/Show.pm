#===============================================================================
#         FILE:  Show.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::Show;
use Mouse;
use Data::Dumper;
has '_showHash' => ( is => 'rw' );

sub getShowID {
    my $self = shift;
    return $self->_showHash()->{showid} // '';
}

sub getLink {
    my $self = shift;
    return $self->_showHash()->{link} // '';
}

sub getCountry {
    my $self = shift;
    return $self->_showHash()->{country} // '';
}

sub getStatus {
    my $self = shift;
    return $self->_showHash()->{status} // '';
}

sub getYearStarted {
    my $self = shift;
    return $self->_showHash()->{started} // '';
}

sub getYearEnded {
    my $self = shift;
    return $self->_showHash()->{ended} // '';
}

sub getGenres {
	my $self = shift;
	my @genres;
	my %genreHash = %{$self->_showHash()->{genres}};
	foreach my $genre ( keys(%genreHash) ) {
		push(@genres, $genreHash{$genre});
	}
	#print Dumper($self->_showHash()->{genres});
	return @genres;
}
1;

=head1 NAME

WebService::TVRage::Show Object returned by WebService::TVRage::ShowList->getShow(), Contains details for the requested show title 

=head1 SYNOPSIS
   
    my $heroesSearch = WebService::TVRage::ShowSearchRequest->new( showTitle => 'Heroes' );
    my $showList = $heroesSearch->search();    
    foreach my $showtitle ($showList->getTitleList()) {
        my $show = $showList->getTitle($showtitle);
        print $show->getLink(), "\n";
    }

=head1 Methods

=over 1

=item _showHash
    
This is populated by WebService::TVRage::ShowList->getShow(), you shouldn't need to edit this, but you might want to look at it with Data::Dumper
 
=back

=head2 getShowID()

    $show->getShowID()

Returns TVRage's ID number for the show which you can use to make a WebService::TVRage::EpisodeListRequest

=head2 getLink()

    $show->getLink()

Returns TVRage's URL for the show

=head2 getCountry()

    $show->getCountry()

Returns the country where the show was made (aired?)

=head2 getStatus()

    $show->getStatus()

Returns which indicates if the show is still active or if has been cancelled

=head2 getYearStarted()

    $show->getYearStarted()

Returns a 4 digit year as a string, the year the show first aired

=head2 getYearEnded()

    $show->getYearEnded()

Returns a 4 digit year as a string, the year the show ended, or 0 if still active

=head2 getGenres()

    $show->getGenres()

Returns an array of strings, the strings are the genres that TVRage has classified the show as being.

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut
