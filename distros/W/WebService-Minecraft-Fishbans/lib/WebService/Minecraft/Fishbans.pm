package WebService::Minecraft::Fishbans;

use 5.006;
use strict;
use Moo;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.02';

=head1 NAME

WebService::Minecraft::Fishbans - look for bans for a Minecraft user

=head1 DESCRIPTION

L<Fishbans|http://www.fishbans.com/> is a service that lets you query various
Minecraft "global ban" systems (e.g. MCBouncer, MCBans, Minebans, etc) in one
API call.

This module is a simple wrapper to query the Fishbans API.  It collates the
bans reported by the Fishbans API, flattening the response to present simply an
array/arrayref of hashrefs, one per recorded ban.


=head1 SYNOPSIS

    use WebService::Minecraft::Fishbans;

    my $fishbans = WebService::Minecraft::Fishbans->new();
    if (my @bans = $fishbans->lookup_user($username)) {
        for my $ban (@bans) {
            printf "%s was banned from %s for reason %s (via %s)\n",
                $user, @$ban{ qw(server reason service) };
        }
    }

=cut

# Sensible default for our User-Agent object, but allowing it to be replaced
# or modified at runtime if the user requires, or if we want to mock it for
# testing.
has user_agent => (
    is => 'rw',
    isa => sub { my $val = shift; ref $val && $val->isa('LWP::UserAgent') },
    default => sub {
        LWP::UserAgent->new( agent => __PACKAGE__ . "/$VERSION" );
    },
);

=head1 METHODS

=head2 lookup_user

Given a Minecraft username, queries the Fishbans API and returns a list or
arrayref (depending on context) of hashrefs, each describing a ban.

Each ban hashref will contain:

=over

=item C<server>

The server the user was banned from

=item C<reason>

The reason for the ban, provided by the op who banned them

=item C<service>

The service the ban was found from - e.g. C<mcbouncer>, C<mcbans>, etc.

=back 

=cut

sub lookup_user {
    my ($self, $username) = @_;

    my $response = $self->user_agent->get(
        "http://api.fishbans.com/bans/$username"
    );
    if (!$response->is_success) {
        die "Failed to query Fishbans - " . $response->status_line;
    }
    my $result = JSON::from_json($response->decoded_content)
        or die "Failed to parse Fishbans response";
    if (!$result->{success}) {
        die "Fishbans API response indicated failure - response: "
            . $response->decoded_content;
    }

    my @return;
    service:
    for my $service (keys %{ $result->{bans}{service} }) {
        my $service_data = $result->{bans}{service}{$service};
        next service unless $service_data->{bans};
        while (my ($server, $reason) = each %{ $service_data->{ban_info} }) {
            warn "Found ban via $service from $server - [$reason]";
            push @return, {
                service => $service,
                server  => $server,
                reason  => $reason,
            };
        }
    }

    return wantarray ? @return : \@return;
}


=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS / DEVELOPMENT
 
Bug reports and pull requests are welcomed on GitHub:
 
L<https://github.com/bigpresh/WebService-Minecraft-Fishbans>



=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Minecraft::Fishbans
