use strict;
use warnings;

package TokenStore;
use Moose;

sub save_token {
}

sub get_token {
}

sub delete_token {
}

=head1 NAME

com::zoho::api::authenticator::store::TokenStore - This class stores the user token details

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<save_token>

This method is used to store user token details

Param user : A User class instance

Param token : A Token class instance

=item C<get_token>

This method is used to get user token details

Param user : A User class instance

Param token : A Token class instance

Returns A Token class instance representing the user token details

=back

=cut

1;
