package WebService::Eulerian::Analytics::Website::TPPublisher;

# $Id: TPPublisher.pm,v 1.1 2008-09-07 23:31:00 cvscore Exp $

use strict;

use WebService::Eulerian::Analytics();

our @ISA        = qw/ WebService::Eulerian::Analytics /;

=pod

=head1	NAME 

WebService::Eulerian::Analytics::Website::TPPublisher - access to the TPPublisher service for a given website : partners for outbound traffic.

=head1 DESCRIPTION

This module allow you to access the TPPublisher service holding information 
about all the partners for your outbound traffic.

=head1 SYNOPSIS

	use WebService::Eulerian::Analytics::Website::TPPublisher;
	#
	my $api = new WebService::Eulerian::Analytics::Website::TPPublisher(
	 apikey	=> 'THE KEY PROVIDED BY YOUR ACCOUNT MANAGER FOR API ACCESS',
	 host	=> 'THE HOST ON WHICH THE API IS HOSTED'
	);

=cut

sub new {
 my $proto      = shift;
 my $class      = ref($proto) || $proto;
 return         $class->SUPER::new(@_, service => 'Website/TPPublisher');
}

=pod

=head1 METHODS

=head2 getById : return a tppublisher given it's id

=head3 input

=over 4

=item * id of the targetted website

=item * id of the tppublisher 

=back

=head3 output

=over 4

=item * hash reference containing the attributes of the tppublisher

=back

=head3 sample

	my $rh_tppublisher = $api->getById($my_website_id, 1);
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	foreach ( keys %{ $rh_tppublisher } ) {
	 print $_." => ".$rh_tppublisher->{$_}."\n";
	}

=cut

sub getById	{ return shift()->call('getById', @_);		}

=pod

=head2 getByName : return a tppublisher given it's name

=head3 input

=over 4

=item * id of the targetted website

=item * name of the tppublisher 

=back

=head3 output

=over 4

=item * hash reference containing the attributes of the tppublisher

=back

=head3 sample

	my $rh_tppublisher = $api->getByName($my_website_id, 'test');
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	foreach ( keys %{ $rh_tppublisher } ) {
	 print $_." => ".$rh_tppublisher->{$_}."\n";
	}

=cut

sub getByName	{ return shift()->call('getByName', @_);	}

=pod

=head2 search : search for a tppublisher

=head3 input

=over 4

=item * id of the targetted website

=item * hash of search parameters

=item * hash of optionnal search parameters

o sortkey : key on which the sorting can be done, defaults to tppublisher_name

o sortdir : direction of the sorting, defaults to asc

o start : for paging, indicate the start index, defaults to 0

o limit : for paging, indicate the numer of results requested, default to 30

=back

=head3 output

=over 4

=item * hash reference containing the following keys 

o results : array of hash containing the list of tppublisher matching the search

o totalcount : total number of items matching the search, used for paging.

=back

=head3 sample

	my $rh_result = $api->search($my_website_id, { }, { limit => 20 });
	print "Total count : ".($rh_result->{totalcount} || 0)."<\n";
	for ( @{ $rh_result->{results} || [] } ) {
	  print "\t name=".$_->{tppublisher_name}." | id=".$_->{tppublisher_id}."<\n";
	}

=cut

sub search	{ return shift()->call('search', @_);		}

=pod

=head1 SEE ALSO

L<WebService::Eulerian::Analytics|WebService::Eulerian::Analytics>

=head1 AUTHOR

Mathieu Jondet <mathieu@eulerian.com>

=head1 COPYRIGHT

Copyright (c) 2008 Eulerian Technologies Ltd L<http://www.eulerian.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

1;
__END__
