package WebService::Mattermost::V4::API::Object::User;

use Moo;
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Int Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Roles
    WebService::Mattermost::V4::API::Object::Role::Timestamps
    WebService::Mattermost::V4::API::Object::Role::APIMethods
);

################################################################################

has [ qw(
    allow_marketing
    is_system_admin
    is_system_user
) ] => (is => 'ro', isa => Bool, lazy => 1, builder => 1);

has [ qw(
    auth_data
    auth_service
    email
    first_name
    last_name
    locale
    nickname
    position
    username
) ] => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

has [ qw(
    password_updated_at
    picture_updated_at
) ] => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('user');
    $self->set_available_api_methods([ qw(
        generate_mfa_secret
        get_profile_image
        get_status
        patch
        set_profile_image
        set_status
        teams
        update
        update_active_status
        update_authentication_method
        update_mfa
        update_password
        update_roles
    ) ]);

    return 1;
}

################################################################################

sub _build_allow_marketing {
    my $self = shift;

    return $self->raw_data->{allow_marketing} ? 1 : 0;
}

sub _build_is_system_admin {
    my $self = shift;

    return $self->roles =~ /system_admin/ ? 1 : 0;
}

sub _build_is_system_user {
    my $self = shift;

    return $self->roles =~ /system_user/ ? 1 : 0;
}

sub _build_password_updated_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{last_password_update});
}

sub _build_picture_updated_at {
    my $self = shift;

    return $self->_from_epoch($self->raw_data->{last_picture_update});
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::User

=head1 DESCRIPTION

Object version of a Mattermost user.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::User> for
full documentation.

ID parameters are not required:

    my $response = $mattermost->api->user->get('ID-HERE')->item->get_status();

Is the same as:

    my $response = $mattermost->api->user->get_status('ID-HERE');

=over 4

=item C<generate_mfa_secret()>

=item C<get_profile_image()>

=item C<get_status()>

=item C<patch()>

=item C<set_profile_image()>

=item C<set_status()>

=item C<teams()>

=item C<update()>

=item C<update_active_status()>

=item C<update_authentication_method()>

=item C<update_mfa()>

=item C<update_password()>

=item C<update_roles()>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Resource::User>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Roles>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

