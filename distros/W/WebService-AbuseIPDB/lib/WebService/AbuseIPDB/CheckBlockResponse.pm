package WebService::AbuseIPDB::CheckBlockResponse;
#
#===============================================================================
#         FILE: CheckBlockResponse.pm
#  DESCRIPTION: Response for check_block endpoint
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 04/07/20 15:23:03
#===============================================================================

use strict;
use warnings;

use parent 'WebService::AbuseIPDB::Response';
our $VERSION = $WebService::AbuseIPDB::Response::VERSION;

use WebService::AbuseIPDB::ReportedAddress;

sub usage_type       { return shift->{data}->{addressSpaceDesc} }
sub network          { return shift->{data}->{networkAddress} }
sub netmask          { return shift->{data}->{netmask} }
sub min_addr         { return shift->{data}->{minAddress} }
sub max_addr         { return shift->{data}->{maxAddress} }
sub num_addr         { return shift->{data}->{numPossibleHosts} }

sub reports {
	my $self = shift;
	return @{$self->{reports}} if exists $self->{reports};
	$self->{reports} = [];
	push @{$self->{reports}}, WebService::AbuseIPDB::ReportedAddress->new ($_)
		for @{$self->{data}->{reportedAddress}};
	return @{$self->{reports}};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::CheckBlockResponse - Specific class for responses to
check_block method

=head1 SYNOPSIS

The C<check_block> method of L<WebService::AbuseIPDB>
will return an object of this class. It is a subclass of the generic
L<WebService::AbuseIPDB::Response> class.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->check_block (ip => '127.0.0.0/24');
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }
    printf "%s/%s has %i possible addresses\n",
        $res->network, $res->netmask, $res->num_addr;

=head1 METHODS

The C<new>, C<successful> and C<errors> methods are inherited from
L<WebService::AbuseIPDB::Response>. All other methods are accessors as
listed here.

=head2 network

Returns the base IP address of this network.

=head2 netmask

Returns the netmask in dotted-quad format.

=head2 min_addr

Returns the address of the first usable address in this subnet.

=head2 max_addr

Returns the address of the last usable address in this subnet.

=head2 num_addr

Returns the maximum number of usable addresses in this subnet.

=head2 usage_type

Returns the usage type of this subnet, according to AbuseIPDB
records.

=head2 reports

Returns an array of L<WebService::AbuseIPDB::ReportedAddress> objects each of
which provides a summary of the reports of one address within the subnet.

=head1 STABILITY

This is currently alpha software. Be aware that both the internals and
the interface are liable to change.

=head1 AUTHOR

Pete Houston, C<< <cpan at openstrike.co.uk> >>

=head1 SEE ALSO

L<WebService::AbuseIPDB> for general use of the client,
L<WebService::AbuseIPDB::Response> for the parent class and
L<Version 2 of the AbuseIPDB API|https://docs.abuseipdb.com/> for API
details/restrictions.

=head1 LICENCE AND COPYRIGHT

Copyright © 2020 Pete Houston

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut
