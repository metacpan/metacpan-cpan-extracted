use strict;
use warnings;
package WebService::SendGrid::Newsletter::Identity;

use parent 'WebService::SendGrid::Newsletter::Base';


sub new {
    my ($class, %args) = @_;
    
    my $self = {};
    bless($self, $class);
    
    $self->{sgn} = $args{sgn};
    
    return $self;
}



sub add {
    my ($self, %args) = @_;

    $self->_check_required_args([ 
        qw( identity name email address city zip state country )
    ], %args);

    $self->{sgn}->_send_request('identity/add', %args);
}



sub edit {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( identity email ) ], %args);

    $self->{sgn}->_send_request('identity/edit', %args);
}


sub get {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( identity ) ], %args);

    $self->{sgn}->_send_request('identity/get', %args);
}


sub list {
    my ($self, %args) = @_;

    $self->{sgn}->_send_request('identity/list', %args);
}


sub delete {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( identity ) ], %args);

    $self->{sgn}->_send_request('identity/delete', %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Identity

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Identity.

    my $recipients = WebService::SendGrid::Newsletter::Identity->new(sgn => $sgn);

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 add

Creates a new identity.

Parameters:

=over 4

=item * C<identity>

B<(Required)> The name of the new identity.

=item * C<name>

B<(Required)> The name of the sender.

=item * C<email>

B<(Required)> The email address of the sender.

=item * C<address>

B<(Required)> The physical address.

=item * C<city>

B<(Required)> The city name.

=item * C<zip>

B<(Required)> The zip code.

=item * C<state>

B<(Required)> The state.

=item * C<country>

B<(Required)> The country name.

=item * C<replyto>

The email address to be used in the Reply-To field. If not defined, will default
to the C<email> parameter.

=back

=head2 edit

Edits an existing identity.

Parameters:

=over 4

=item * C<identity>

B<(Required)> The identity to be edited.

=item * C<newidentity>

The new name to be used for this identity.

=item * C<name>

The new name of the sender.

=item * C<email>

<(Required)> The email address of the sender.

=item * C<replyto>

The email address to be used in the Reply-To field. If not defined, will default
to the C<email> parameter.

=item * C<address>

The new physical address.

=back

=head2 get

Retrieves information associated with an identity.

=over 4

=item * C<identity>

B<(Required)> The name of the identity to retrieve information for.

=back

=head2 list

Retrieves all identities on the account, or checks if a specified identity exists.

=over 4

=item * C<identity>

The name of the identity to check.

=back

=head2 delete

Removes the specified identity.

=over 4

=item * C<identity>

B<(Required)> The name of the identity to remove.

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
