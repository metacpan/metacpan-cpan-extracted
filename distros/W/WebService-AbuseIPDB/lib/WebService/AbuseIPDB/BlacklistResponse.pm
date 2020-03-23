package WebService::AbuseIPDB::BlacklistResponse;
#
#===============================================================================
#         FILE: BlacklistResponse.pm
#  DESCRIPTION: Response for blacklist endpoint
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 11/02/20 13:46:02
#===============================================================================

use strict;
use warnings;

use parent 'WebService::AbuseIPDB::Response';
use WebService::AbuseIPDB::BlacklistMember;
our $VERSION = $WebService::AbuseIPDB::Response::VERSION;

sub as_at { return shift->{meta}->{generatedAt} }
sub list {
	return
		map { WebService::AbuseIPDB::BlacklistMember->new ($_) }
		@{shift->{data}};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::BlacklistResponse - Specific class for responses to
blacklist method

=head1 SYNOPSIS

The C<blacklist> method of L<WebService::AbuseIPDB>
will return an object of this class. It is a subclass of the generic
L<WebService::AbuseIPDB::Response> class.

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->blacklist (limit => 5);
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }
    my $when = $res->as_at;
    my @list = $res->list;
    print "As at $when\n";
    for my $item (@list) {
        printf "%s has a score of %i\n",
            $item->ip, $item->score;
    }

=head1 METHODS

The C<new>, C<successful> and C<errors> methods are inherited from
L<WebService::AbuseIPDB::Response>. All other methods are accessors as
listed here.

=head2 as_at

Returns the time at which this list was generated in the format
YYYY-MM-DDTHH:MM:SS+HH:MM as a scalar string.

=head2 list

Returns the payload as an array of
L<WebService::AbuseIPDB::BlacklistMember> objects

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
