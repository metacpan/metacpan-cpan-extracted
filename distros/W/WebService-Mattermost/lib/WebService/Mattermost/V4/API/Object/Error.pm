package WebService::Mattermost::V4::API::Object::Error;

use Moo;
use Types::Standard qw(Str Maybe);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Message
    WebService::Mattermost::V4::API::Object::Role::RequestID
    WebService::Mattermost::V4::API::Object::Role::StatusCode
);

################################################################################

has detailed_error => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

################################################################################

sub _build_detailed_error {
    my $self = shift;

    return $self->raw_data->{detailed_error};
}

sub _build_id {
    my $self = shift;

    return $self->raw_data->{id};
}

sub _build_request_id {
    my $self = shift;

    return $self->raw_data->{request_id};
}

sub _build_status_code {
    my $self = shift;

    return $self->raw_data->{status_code};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Error

=head1 DESCRIPTION

Details an error response from the API.

=head2 ATTRIBUTES

=over 4

=item C<detailed_error>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Message>

=item C<WebService::Mattermost::V4::API::Object::Role::RequestID>

=item C<WebService::Mattermost::V4::API::Object::Role::StatusCode>

=item L<Error documentation|https://api.mattermost.com/#tag/errors>

Official documentation for API errors.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

