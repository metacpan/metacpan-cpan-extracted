package WebService::Eulerian::Analytics::Website;

# $Id: Website.pm,v 1.2 2008-09-03 15:22:48 cvscore Exp $

use strict;

use WebService::Eulerian::Analytics();

our @ISA        = qw/ WebService::Eulerian::Analytics /;

=pod

=head1	NAME 

WebService::Eulerian::Analytics::Website - access the Website service

=head1 DESCRIPTION

This module allow you to access the Website service holding information about
the websites defined in your Eulerian Analytics account.

=head1 SYNOPSIS

	use WebService::Eulerian::Analytics::Website;
	#
	my $api = new WebService::Eulerian::Analytics::Website(
	 apikey	=> 'THE KEY PROVIDED BY YOUR ACCOUNT MANAGER FOR API ACCESS',
	 host	=> 'THE HOST ON WHICH THE API IS HOSTED'
	);

=cut

sub new {
 my $proto      = shift;
 my $class      = ref($proto) || $proto;
 return         $class->SUPER::new(@_, service => 'Website');
}

=pod

=head1 METHODS

=head2 getById : return a website given it's id

=head3 input

=over 4

=item * id of the website as defined in Eulerian Analytics

=back

=head3 output

=over 4

=item * hash reference containing the attributes of the website

=back

=head3 sample

	my $rh_website = $api->getById(1);
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	foreach ( keys %{ $rh_website } ) {
	 print $_." => ".$rh_website->{$_}."\n";
	}

=cut

sub getById	{ return shift()->call('getById', shift()); }

=pod

=head2 getByName : return a website given it's name

=head3 input

=over 4

=item * name of the website as defined in Eulerian Analytics

=back

=head3 output

=over 4

=item * hash reference containing the attributes of the website

=back

=head3 sample

	my $rh_website = $api->getByName('my-tracked-website');
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	foreach ( keys %{ $rh_website } ) {
	 print $_." => ".$rh_website->{$_}."\n";
	}

=cut

sub getByName	{ return shift()->call('getByName', shift()); }

=pod

=head2 getAll : return all the websites you are allowed to access with current apikey

=head3 input

=over 4

=item * none

=back

=head3 output

=over 4

=item * array reference containg hash reference of the websites

=back

=head3 sample

	my $ra_website = $api->getAll();
	#
	if ( $api->fault ) {
	 die $api->faultstring();
	}
	#
	foreach my $rh_website ( @{ $ra_website } ) {
	 foreach ( keys %{ $rh_website } ) {
	  print $_." => ".$rh_website->{$_}."\n";
	 }
	 print "\n";
	}

=cut

sub getAll	{ 
 my $self       = shift;
 my @a_data	= $self->call('getAll');
 return         $a_data[0] || [];
}

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
