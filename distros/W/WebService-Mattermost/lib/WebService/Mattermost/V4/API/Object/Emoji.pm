package WebService::Mattermost::V4::API::Object::Emoji;

use Moo;
use Types::Standard qw(Str Int);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::Timestamps
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Name
);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('emoji');
    $self->set_available_api_methods([ qw(
        delete
        get_image
    ) ]);

    return 1;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Emoji

=head1 DESCRIPTION

Details a Mattermost Emoji object.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::Emoji>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->emoji->get('ID-HERE')->item->get_image();

Is the same as:

    my $response = $mattermost->api->emoji->get_image('ID-HERE');

=over 4

=item C<delete()>

=item C<get_image()>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Emoji>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

