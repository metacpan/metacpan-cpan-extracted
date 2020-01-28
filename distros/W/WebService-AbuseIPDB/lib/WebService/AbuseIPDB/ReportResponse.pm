package WebService::AbuseIPDB::ReportResponse;

#===============================================================================
#         FILE: ReportResponse.pm
#  DESCRIPTION: Reponse for report endpoint
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 17/08/19 12:26:19
#===============================================================================

use strict;
use warnings;

use parent 'WebService::AbuseIPDB::Response';
our $VERSION = $WebService::AbuseIPDB::Response::VERSION;

sub score { return shift->{data}->{abuseConfidenceScore} }
sub ip    { return shift->{data}->{ipAddress} }

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::ReportResponse - Specific class for responses to
the C<report> method of L<WebService::AbuseIPDB>.

=head1 SYNOPSIS

The C<report> method of L<WebService::AbuseIPDB>
will return an object of this class. It is a subclass of the generic
L<WebService::AbuseIPDB::Response> class.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->report (ip => '127.0.0.2', categories => [3],
        comment => 'Over 3000 attacks in the last hour');
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }
    printf "%s has a score of %i\n", $res->ip, $res->score;

=head1 METHODS

The C<new>, C<successful> and C<errors> methods are inherited from
L<WebService::AbuseIPDB::Response>. All other methods are accessors as
listed here.

=head2 score

Returns the abuse score as an integer between 0 and 100 inclusive.

=head2 ip

Returns the IP address itself as a string.

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
