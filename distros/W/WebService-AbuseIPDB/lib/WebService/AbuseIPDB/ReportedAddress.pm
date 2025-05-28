package WebService::AbuseIPDB::ReportedAddress;
#
#===============================================================================
#         FILE: ReportedAddress.pm
#  DESCRIPTION: Report of one address resulting from a check_block
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 04/07/20 15:05:53
#===============================================================================

use strict;
use warnings;

our $VERSION = $WebService::AbuseIPDB::Response::VERSION;
sub new {
	my ($class, $data) = @_;
	bless $data, $class;
	return $data;
}
sub cc               { return shift->{countryCode} }
sub score            { return shift->{abuseConfidenceScore} }
sub report_count     { return shift->{numReports} }
sub last_report_time { return shift->{mostRecentReport} }
sub ip               { return shift->{ipAddress} }

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::ReportedAddress - Data on one address from a range
as a result of check_block

=head1 SYNOPSIS

The C<reports> method of L<WebService::AbuseIPDB::CheckBlockResponse>
will return an array of objects of this class. It consists only of a
constructor and 5 getters.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->check_block (ip => '127.0.0.0/24');
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }

    for my $rep ($res->reports) {
        printf "%s has a score of %i, last reported at %s\n",
            $res->ip, $res->score, $res->last_report_time;
    }

=head1 METHODS

=head2 new

Takes a hashref of data and returns the immutable object.

=head2 cc

Returns the 2-letter country code of this IP address.

=head2 score

Returns the abuse score as an integer between 0 and 100 inclusive.

=head2 report_count

Returns the total number of reports of this address in the requested
date range as a whole number.

=head2 last_report_time

Returns the time of the last report of this address as
"YYYY-MM-DDTHH:MM:SS+HH:MM".

=head2 ip

Returns the IP address itself as a string.

=head1 STABILITY

This is currently alpha software. Be aware that both the internals and
the interface are liable to change.

=head1 AUTHOR

Pete Houston, C<< <cpan at openstrike.co.uk> >>

=head1 SEE ALSO

L<WebService::AbuseIPDB> for general use of the client
and
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
