package WebService::AbuseIPDB::BlacklistMember;
#
#===============================================================================
#         FILE: BlacklistMember.pm
#  DESCRIPTION: Member of blacklist response
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 11/02/20 14:05:32
#===============================================================================

use strict;
use warnings;

use WebService::AbuseIPDB::Response;
our $VERSION = $WebService::AbuseIPDB::Response::VERSION;

sub new {
	my ($class, $data) = @_;
	bless $data, $class;
	return $data;
}

sub score            { return shift->{abuseConfidenceScore} }
sub ip               { return shift->{ipAddress} }

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::BlacklistMember - Class for one item of the
returned blacklist

=head1 SYNOPSIS

The C<blacklist> API endpoint is designed to return a list of bad
addresses. Each address is represeted by this class.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->blacklist (limit => 5);
    for my $member ($res->list) {
        printf "%s has a score of %i\n",
        $member->ip, $member->score;

=head1 METHODS

=head2 new

Takes one hashref and returns the object from it. Does no validation because
it is only called internally.

=head2 ip

A getter which returns the ip address as a scalar string.

=head2 score

A getter which returns the abuse confidence score as an integer between
0 and 100 inclusive.

=head1 SEE ALSO

L<WebService::AbuseIPDB> for general use of the client,
L<WebService::AbuseIPDB::BlacklistResponse> for the calling code and
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
