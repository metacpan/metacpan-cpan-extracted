package WebService::AbuseIPDB::CheckResponse;
#
#===============================================================================
#         FILE: CheckResponse.pm
#  DESCRIPTION: Response for check endpoint
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 12/08/19 14:51:10
#===============================================================================

use strict;
use warnings;

use parent 'WebService::AbuseIPDB::Response';
our $VERSION = $WebService::AbuseIPDB::Response::VERSION;

sub cc               { return shift->{data}->{countryCode} }
sub score            { return shift->{data}->{abuseConfidenceScore} }
sub report_count     { return shift->{data}->{totalReports} }
sub whitelisted      { return shift->{data}->{isWhitelisted} }
sub isp              { return shift->{data}->{isp} }
sub last_report_time { return shift->{data}->{lastReportedAt} }
sub usage_type       { return shift->{data}->{usageType} }
sub ip               { return shift->{data}->{ipAddress} }
sub ipv              { return shift->{data}->{ipVersion} }
sub public           { return shift->{data}->{isPublic} }
sub domain           { return shift->{data}->{domain} }
sub reporter_count   { return shift->{data}->{numDistinctUsers} }

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::CheckResponse - Specific class for responses to
check method

=head1 SYNOPSIS

The C<check> method of L<WebService::AbuseIPDB>
will return an object of this class. It is a subclass of the generic
L<WebService::AbuseIPDB::Response> class.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->check (ip => '127.0.0.2');
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }
    printf "%s has a score of %i, last reported at %s\n",
        $res->ip, $res->score, $res->last_report_time;

=head1 METHODS

The C<new>, C<successful> and C<errors> methods are inherited from
L<WebService::AbuseIPDB::Response>. All other methods are accessors as
listed here.

=head2 cc

Returns the 2-letter country code of this IP address.

=head2 score

Returns the abuse score as an integer between 0 and 100 inclusive.

=head2 report_count

Returns the total number of reports of this address in the requested
date range as a whole number.

=head2 isp

Returns the ISP of this IP address, according to AbuseIPDB records.

=head2 last_report_time

Returns the time of the last report of this address as
"YYYY-MM-DDTHH:MM:SS+HH:MM".

=head2 usage_type

Returns the usage type of this IP address, according to AbuseIPDB
records.

=head2 whitelisted

Returns true if AbuseIPDB has whitelisted this address for some reason.

=head2 ip

Returns the IP address itself as a string.

=head2 ipv

Returns the version of the IP address as an integer (ie. 6 or 4).

=head2 public

Returns true if the IP address is a public address, otherwise false.

=head2 reporter_count

Returns the number of distinct users who have reported this IP address
in the requested date range.

=head2 domain

Returns the domain of this IP address, according to AbuseIPDB records.

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
