package WebService::AbuseIPDB::Response;

#===============================================================================
#         FILE: Response.pm
#  DESCRIPTION: Generic Response Object - See POD for details
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 12/08/19 14:38:21
#===============================================================================

use strict;
use warnings;

use WebService::AbuseIPDB;

our $VERSION = $WebService::AbuseIPDB::VERSION;

sub new {
	my ($class, $res) = @_;
	my $self =
	  ref $res
	  ? $res
	  : {
		errors => [
			{   status => 500,
				detail => 'Client could not connect'
			}
		]
	  };
	bless ($self, $class);
	return $self;
}

# Accessors

sub successful { return not exists shift->{errors} }
sub errors     { return shift->{errors} }

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::Response - Generic class for API responses

=head1 SYNOPSIS

Any of the WebService::AbuseIPDB methods which send a request to the
server will return an object of this class (or its children).

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->check (ip => '127.0.0.2');
    unless ($res->successful) {
        for my $err (@{$res->errors}) {
            warn "Error $err->{status}: $err->{detail}\n";
        }
        die "Cannot continue.\n";
    }

=head1 SUBROUTINES/METHODS

=head2 new

	my $res = WebService::AbuseIPDB::Response->new ($href);

The constructor takes a hashref constructed from the JSON returned by
the API. If the argument is missing or not a reference it assumes a
catastrophic problem and sets the generic error code and message (500,
"Client could not connect");

=head2 successful

	my $ok = $res->successful;

Returns true if there were no errors, otherwise false.

=head2 errors

	my $err = $res->errors;

Returns a ref to an AoH of errors exactly as returned by the API.

=head1 STABILITY

This is currently alpha software. Be aware that both the internals and
the interface are liable to change.

=head1 AUTHOR

Pete Houston, C<< <cpan at openstrike.co.uk> >>

=head1 SEE ALSO

L<WebService::AbuseIPDB> for general use of the client,
L<Version 2 of the AbuseIPDB API|https://docs.abuseipdb.com/> for API
details/restrictions and L<WebService::AbuseIPDB::ReportResponse> and
L<WebService::AbuseIPDB::CheckResponse> for specific subclasses.

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
