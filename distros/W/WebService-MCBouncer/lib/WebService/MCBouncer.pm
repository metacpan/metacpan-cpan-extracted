package WebService::MCBouncer;

use 5.010;
use strict;

use LWP::UserAgent;
use JSON;
use Moo;

our $VERSION = '0.03';

=head1 NAME

WebService::MCBouncer - Query MCBouncer API for Minecraft bans

=head1 SYNOPSIS

A simple module for interacting with the MCBouncer API to query for bans / notes
for Minecraft users.


    my $mcbouncer = WebService::MCBouncer->new(
        api_key => '...your MCBouncer API key...',
    );

    if (my $bans = $mcbouncer->bans($player_name)) {
        for my $ban (@$bans) {
            printf "Player %s was banned from %s on %s by %s (%s)\n",
                @ban{ qw(username server issuer time reason) };
        }
    }

    if (my $notes = $mcbouncer->notes($player_name)) {
        for my $note (@$notes) {
            say "Note: $note->{text};
        }
    }


=head1 DESCRIPTION

L<MCBouncer|http://mcbouncer.com/> is a service allowing Minecraft server
administrators to share details of bans and notes about abusive users.

MCBouncer provides a server mod to use with the service, but also provides
an API to query for bans / notes using an API key, obtained when you
add a server to the list via the website.

This module uses the API to allow you to fetch details of bans or notes about
users.

=cut

has api_key => (
    is => 'rw',
);
has user_agent => (
    is => 'rw',
    isa => sub { my $val = shift; ref $val && $val->isa('LWP::UserAgent') },
    default => sub {
        LWP::UserAgent->new( agent => __PACKAGE__ . "/$VERSION" );
    },
);

=head1 Methods

=head2 bans

Given a username, returns details of any bans for that user.

Returns a list or arrayref of ban details, each of which 
at the current time will contain:

=over

=item username

The username banned

=item reason

The reason for the ban

=item server

The ban this server is from

=item time

The date and time the ban was recorded, e.g. C<2015-04-10T00:59:31.280>

=item issuer

The username of the person who placed this ban.

=back

=cut

sub bans {
    my ($self, $username) = @_;
    my $response = $self->user_agent->get(
        "http://mcbouncer.com/api/getBans/"
        . $self->api_key . "/$username"
    );
    if (!$response->is_success) {
        die "Failed to query getBans for $username - " . $response->status_line;
    }

    my $result = JSON::from_json($response->decoded_content);

    if (!$result->{success}) {
        die "mcbouncer response indicated error";
    }
    return unless $result->{totalcount};
    return wantarray ? @{ $result->{data} } : $result->{data};
}

=head2 notes

Given a username, returns details of any notes recorded for that user.

Returns an array or arrayref of hashrefs describing each note, each
of which at the current time includes:

=over

=item username

The username the note applies to

=item note

The text of the note

=item server

The ban this note is from

=item time

The date and time the note was added, e.g. C<2015-04-10T00:59:31.280>

=item issuer

The username of the person who added this note

=item noteid

The ID of this note

=back

=cut

sub notes {
    my ($self, $username) = @_;
    my $response = $self->user_agent->get(
        "http://mcbouncer.com/api/getNotes/"
        . $self->api_key . "/$username"
    );
    if (!$response->is_success) {
        die "Failed to query getBans for $username - " . $response->status_line;
    }

    my $result = JSON::from_json($response->decoded_content);
    if (!$result->{success}) {
        die "mcbouncer response indicated error";
    }
    return unless $result->{totalcount};
    return wantarray ? @{ $result->{data} } : $result->{data};
}

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS / DEVELOPMENT

Bug reports and pull requests are welcomed on GitHub:

L<https://github.com/bigpresh/WebService-MCBouncer>





=head1 ACKNOWLEDGEMENTS

Deaygo for creating MCBouncer.


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

1; # End of WebService::MCBouncer
