package WebService::Mojang::Minecraft::UUIDLookup;

use 5.006;
use strict;
use Data::UUID;
use Moo;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.05';

=head1 NAME

WebService::Mojang::Minecraft::UUIDLookup - look up Minecraft usernames/UUIDs

=head1 DESCRIPTION

A simple module to use Mojang's API to look up a Minecraft user's UUID from
their username (and provide any previous names they've had), or given a UUID,
return all names that account has had.


=head1 SYNOPSIS


    use WebService::Mojang::Minecraft::UUIDLookup;

    my $mojang_lookup = WebService::Mojang::Minecraft::UUIDLookup->new();

    # Look up a username and get their UUID and previous names
    if (my $user_details = $mojang_lookup->lookup_user($username)) {
        say "$username's UUID is " . $user_details->{uuid};
        if ($user_details->{previous_names}) {
             say "Previous names for $username: " 
                . join ',', @{ $user_details->{previous_names} };
        }
    } else {
        warn "Username $username not found";
    }

    # Or lookup a UUID and find the current username, and any previous ones
    if (my $user_details = $mojang_lookup->lookup_uuid($user_uuid)) {
        say "$user_uuid is $user_details->{username}";
        if ($user_details->{previous_names}) {
            say "Previous names for $user_details_>{username}: "
                . join ',', @{ $user_details->{previous_names} };
        }
    } else {
        warn "UUID $user_uuid not found";
    }

=cut

has user_agent => (
    is  => 'rw',
    isa => sub { my $val = shift; ref $val && $val->isa('LWP::UserAgent') },
    default => sub {
        LWP::UserAgent->new( agent => __PACKAGE__ . "/$VERSION" ),
    },
);
has lookup_previous_usernames => (
    is => 'rw',
    default => 1,
);

=head1 Methods

=head2 lookup_user

Given a username, return their UUID and any previous usernames they had (unless
the lookup_previous_usernames option is set to a false value; it defaults to
enabled, but if you don't care about previous usernames and want to save an API
call you can disable it.

Returns undef if Mojang indicated no match, otherwise a hash (in list context)
or hashref (in scalar context) with the keys:

=over

=item C<uuid>

The UUID for this username; this identifies the Mojang account, and does not
change, even if the user renames their account.

=item C<formatted_uuid>

The UUID for this username - as C<uuid>, but formatted using L<Data::UUID>'s
C<to_string> method (e.g. C<85d699cb21774d538366f2cdf9dc93cd> as returned by
Mojang becomes C<36643538-3939-6263-3231-373734643533>).

=item C<username>

The current username for this account

=item C<previous_usernames>

An arrayref of previous usernames this account has been known by, unless the
C<lookup_previous_usernames> attribute is set to a false value.

=back

If the account wasn't found, returns undef.  Dies if it wasn't possible to
retrieve a response from Mojang.

=cut

sub lookup_user {
    my ($self, $username) = @_;

    my $response = $self->user_agent->get(
        "https://api.mojang.com/users/profiles/minecraft/$username"
    );
    if (!$response->is_success) {
        die "Failed to query Mojang API: " . $response->status_line;
    }

    # If there's no such user, Mojang return status 204 with an empty body
    if ($response->code == 204) {
        return;
    }

    my $result = JSON::from_json($response->decoded_content)
        or die "Failed to parse Mojang API response";
    
    my %return = (
        uuid     => $result->{id},
        username => $result->{name},
    );

    # Provide padded uuid too
    $return{formatted_uuid} = Data::UUID->new->to_string(
        Data::UUID->new->from_string($result->{id})
    );

    if ($result->{id} && $self->lookup_previous_usernames) {
        my $uuid_lookup = $self->lookup_uuid($result->{id});
        $return{previous_usernames} = $uuid_lookup->{previous_usernames};
    }
    return wantarray ? %return : \%return;
}
        


=head2 lookup_uuid

Given a Mojang account UUID, returns a hash (in list context) or a hashref (in 
scalar context) with the following keys:

=over

=item C<uuid>

The account's UUID (as you supplied)

=item C<username>

The account's current username

=item C<previous_usernames>

Any previous usernames this account has used.

=back

If the account wasn't found, returns undef.  Dies if it wasn't possible to
retrieve a response from Mojang.

=cut

sub lookup_uuid {
    my ($self, $uuid) = @_;

    my $response = $self->user_agent->get(
        "https://api.mojang.com/user/profiles/$uuid/names"
    );
    if (!$response->is_success) {
        die "Failed to query Mojang API: " . $response->status_line;
    }
    my $result = JSON::from_json($response->decoded_content)
        or die "Failed to parse Mojang API response";
    
    my $primary_username = pop @$result;
    my %return = (
        uuid => $uuid,
        username => $primary_username->{name},
        previous_usernames => [ map { $_->{name} } @$result ],
    );

    return wantarray ? %return : \%return;
}

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>


=head1 BUGS / CONTRIBUTING

Bug reports and pull requests are welcomed on GitHub:

L<https://github.com/bigpresh/WebService-Mojang-Minecraft-UUIDLookup>


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

1; # End of WebService::Mojang::Minecraft::UUIDLookup
