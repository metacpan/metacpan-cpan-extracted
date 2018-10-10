package WebService::Mattermost::Role::Returns;

use Moo::Role;

################################################################################

sub error_return {
    my $self  = shift;
    my $error = shift;

    $error = sprintf('%s. No API query was made.', $error);

    return { error => 1, message => $error };
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Role::Returns

=head1 DESCRIPTION

Common structures for return values.

=head2 METHODS

=over 4

=item C<error_return()>

Return an unsuccessful response with an error message.

    return $self->error_return('Error here');

    # \{
    #     error   => 1,
    #     message => 'Error here. No API query was made.',
    # }

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

