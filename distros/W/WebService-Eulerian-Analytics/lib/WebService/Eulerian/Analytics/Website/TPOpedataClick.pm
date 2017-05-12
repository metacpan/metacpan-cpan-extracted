package WebService::Eulerian::Analytics::Website::TPOpedataClick;

# $Id: TPOpedataClick.pm,v 1.3 2008-09-21 23:30:08 cvscore Exp $

use strict;

use WebService::Eulerian::Analytics();

our @ISA        = qw/ WebService::Eulerian::Analytics /;

=pod

=head1	NAME 

WebService::Eulerian::Analytics::Website::TPOpedataClick - access to the TPOpedataClick service for a given website

=head1 DESCRIPTION

This module allow you to access the TPOpedataClick service, which holds
information on all the click generated as outbout traffic.

=head1 SYNOPSIS

	use WebService::Eulerian::Analytics::Website::TPOpedataClick;
	#
	my $api = new WebService::Eulerian::Analytics::Website::TPOpedataClick(
	 apikey	=> 'THE KEY PROVIDED BY YOUR ACCOUNT MANAGER FOR API ACCESS',
	 host	=> 'THE HOST ON WHICH THE API IS HOSTED'
	);

=cut

sub new {
 my $proto      = shift;
 my $class      = ref($proto) || $proto;
 return         $class->SUPER::new(@_, service => 'Website/TPOpedataClick');
}

=pod

=head1 METHODS

=head2 getLogByTPOpeName : return all information on outbound clicks for a given outbound campaign

Note: you can only request data on a day timespan.

=head3 input

=over 4

=item * id of the targetted website

=item * hash reference with the following parameters :

o tpope_name : name of the outbound campaign

o date_from : date from value (dd/mm/yyyy format)

o date_to : date to value (dd/mm/yyyy format) inclusive

o without_channel : provide inbound channel information, optionnal (default: 0), if set to 1 the inbound channel information won't be provided. The response will be faster.

=back

=head3 output

=over 4

=item * array reference containing data on each outbound click

=back

=head3 sample

	my $ra_log = $api->getLogByTPOpeName($my_website_id, {
	  tpope_name	=> 'NAME_OF_TARGETTED_CAMPAIGN',
	  date_from 	=> 'DD/MM/YYYY',
	  date_to	=> 'DD/MM/YYYY',
	});
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	for ( @{ $ra_log } ) {
	 print "date ".localtime($_->{epoch})." | IP : ".$_->{ip}." | Channel Information : level0=".$_->{channel_0}." level1=".$_->{channel_1}." level2=".$_->{channel_2}."\n";
	}

=cut

sub getLogByTPOpeName	{ return shift()->call('getLogByTPOpeName', @_); }

=pod

=head1 METHODS

=head2 getLogByTPMediaName : return all information on outbound clicks for a given outbound media

Note: you can only request data on a day timespan.

=head3 input

=over 4

=item * id of the targetted website

=item * hash reference with the following parameters :

o tpmedia_name : name of the outbound media

o date_from : date from value (dd/mm/yyyy format)

o date_to : date to value (dd/mm/yyyy format) inclusive

o without_channel : provide inbound channel information, optionnal (default: 0), if set to 1 the inbound channel information won't be provided. The response will be faster.

=back

=head3 output

=over 4

=item * array reference containing data on each outbound click

=back

=head3 sample

	my $ra_log = $api->getLogByTPMediaName($my_website_id, {
	  tpmedia_name	=> 'NAME_OF_TARGETTED_TPMEDIA',
	  date_from 	=> 'DD/MM/YYYY',
	  date_to	=> 'DD/MM/YYYY',
	});
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	for ( @{ $ra_log } ) {
	 print "date ".localtime($_->{epoch})." | IP : ".$_->{ip}." | Channel Information : level0=".$_->{channel_0}." level1=".$_->{channel_1}." level2=".$_->{channel_2}." | Outbound Campaign : ".$_->{tpope_name}."\n";
	}

=cut

sub getLogByTPMediaName	{ return shift()->call('getLogByTPMediaName', @_); }

=pod

=head1 METHODS

=head2 getLogByOpeName : return all information on outbound clicks for a given inbound campaign

Note: you can only request data on a day timespan.

=head3 input

=over 4

=item * id of the targetted website

=item * hash reference with the following parameters :

o ope_name : name of the inbound compaign

o date_from : date from value (dd/mm/yyyy format)

o date_to : date to value (dd/mm/yyyy format) inclusive

=back

=head3 output

=over 4

=item * array reference containing data on each outbound click

=back

=head3 sample

	my $ra_log = $api->getLogByOpeName($my_website_id, {
	  ope_name	=> 'NAME_OF_INBOUND_CAMPAIGN',
	  date_from 	=> 'DD/MM/YYYY',
	  date_to	=> 'DD/MM/YYYY',
	});
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	for ( @{ $ra_log } ) {
	 print "date ".localtime($_->{epoch})." | IP : ".$_->{ip}." | Outbound Campaign : ".$_->{tpope_name}."\n";
	}

=cut

sub getLogByOpeName	{ return shift()->call('getLogByOpeName', @_); }

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
