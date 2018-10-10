package WebService::Mattermost::V4::API::Object::Team;

use Moo;
use Types::Standard qw(Bool Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::Name
    WebService::Mattermost::V4::API::Object::Role::Description
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Timestamps
);

################################################################################

has company_name   => (is => 'ro', isa => Str,  lazy => 1, builder => 1);
has display_name   => (is => 'ro', isa => Str,  lazy => 1, builder => 1);
has email          => (is => 'ro', isa => Str,  lazy => 1, builder => 1);
has invite_id      => (is => 'ro', isa => Str,  lazy => 1, builder => 1);
has is_invite_only => (is => 'ro', isa => Bool, lazy => 1, builder => 1);
has open_invite    => (is => 'ro', isa => Bool, lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('team');
    $self->set_available_api_methods([ qw(
        add_member
        add_members
        delete
        get_icon
        invite_by_emails
        members
        members_by_ids
        patch
        remove_icon
        search_posts
        set_icon
        set_scheme
        stats
        update
    ) ]);

    return 1;
}

################################################################################

sub _build_company_name   { shift->raw_data->{company_name}        }
sub _build_display_name   { shift->raw_data->{display_name}        }
sub _build_email          { shift->raw_data->{email}               }
sub _build_invite_id      { shift->raw_data->{invite_id}           }
sub _build_is_invite_only { shift->raw_data->{type} eq 'I' ? 1 : 0 }
sub _build_open_invite    { shift->raw_data->{open_invite} ? 1 : 0 }

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Team

=head1 DESCRIPTION

Object version of a Mattermost team.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::Team>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->team->get('ID-HERE')->item->delete();

Is the same as:

    my $response = $mattermost->api->team->delete('ID-HERE');

=over 4

=item C<add_member()>

=item C<add_members()>

=item C<delete()>

=item C<get_icon()>

=item C<invite_by_emails()>

=item C<members()>

=item C<members_by_ids()>

=item C<patch()>

=item C<remove_icon()>

=item C<search_posts()>

=item C<set_icon()>

=item C<set_scheme()>

=item C<stats()>

=item C<update()>

=back

=head2 ATTRIBUTES

=over 4

=item C<id>

The team's ID.

=item C<name>

The team's name.

=item C<display_name>

=item C<email>

Contact address for the team.

=item C<invite_id>

=item C<is_invite_only>

Boolean.

=item C<open_invite>

Boolean.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Resource::Team>

=item C<WebService::Mattermost::V4::API::Resource::Teams>

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=item C<WebService::Mattermost::V4::API::Object::Role::Description>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

