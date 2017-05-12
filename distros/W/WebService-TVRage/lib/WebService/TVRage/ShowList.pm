#===============================================================================
#         FILE:  ShowList.pm
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================

use strict;
use warnings;

package WebService::TVRage::ShowList;
use Mouse;
use WebService::TVRage::Episode;
use Data::Dumper;
use WebService::TVRage::Show;
has '_showListHash' => ( is => 'rw' );

sub getTitleList {
	my $self = shift;	
	my @titles;
	for my $showTitle ( keys(%{ $self->_showListHash()->{show} }) ) { 
		push( @titles, $showTitle );
	}
	return @titles;
}

sub getShow {
	my $self = shift;
	my $showTitle = shift;
	my $object = WebService::TVRage::Show->new();
	return undef unless defined $self->_showListHash()->{show}{$showTitle};
	$object->_showHash( $self->_showListHash()->{show}{$showTitle} );
	return $object;
}
1;


=head1 NAME

WebService::TVRage::ShowList - Object returned by WebService::TVRage::ShowSearchRequest->search(), Contains a List of shows 

=head1 SYNOPSIS
   
	my $heroesSearch = WebService::TVRage::ShowSearchRequest->new( showTitle => 'Heroes' );
    my $showList = $heroesSearch->search();    
    foreach my $showtitle ($showList->getTitleList()) {
		my $show = $showList->getTitle($showtitle);
		print $show->getLink(), "\n";
	}

=head1 Methods

=over 1

=item _showListHash
    
This is populated by WebService::TVRage::ShowSearchRequest->search(), you shouldn't need to edit this, but you might want to look at it with Data::Dumper
 
=back

=head2 getTitleList()

    $showList->getTitleList()

Returns an array of strings where each string is the title of a show that matched the search from ShowSearchRequest

=head2 getShow()

    $showList->getShow('Heroes')

Returns a WebService::TVRage::Show object which represents details of the show with the title that was given as an argument to the method

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut
