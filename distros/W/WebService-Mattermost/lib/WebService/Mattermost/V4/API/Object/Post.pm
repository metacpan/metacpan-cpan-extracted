package WebService::Mattermost::V4::API::Object::Post;

use Moo;
use Types::Standard qw(ArrayRef Maybe Str InstanceOf);

use WebService::Mattermost::Helper::Alias 'view';

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::BelongingToChannel
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Message
    WebService::Mattermost::V4::API::Object::Role::Props
    WebService::Mattermost::V4::API::Object::Role::Timestamps
);

################################################################################

has [ qw(
    hashtag
    original_id
    parent_id
    pending_post_id
    root_id
) ] => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

has [ qw(
    original_post
    parent_post
    pending_post
    root_post
) ] => (is => 'ro', isa => Maybe[InstanceOf[view 'Post']], lazy => 1, builder => 1);

has [ qw(
    filenames
    file_ids
) ] => (is => 'ro', isa => Maybe[ArrayRef], lazy => 1, builder => 1);

has files => (is => 'ro', lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('post');
    $self->available_api_methods([ qw(
        delete
        update
        patch
        thread
        files
        pin
        inpin
        reactions
        perform_action
    ) ]);

    return 1;
}       

################################################################################

sub _get_related_post {
    my $self = shift;
    my $id   = shift;

    return unless $id;
    return $self->api->post->get($id)->item;
}

################################################################################

sub _build_hashtag         { shift->raw_data->{hashtag}         }
sub _build_original_id     { shift->raw_data->{original_id}     }
sub _build_parent_id       { shift->raw_data->{parent_id}       }
sub _build_pending_post_id { shift->raw_data->{pending_post_id} }
sub _build_root_id         { shift->raw_data->{root_id}         }
sub _build_filenames       { shift->raw_data->{filenames}       }
sub _build_file_ids        { shift->raw_data->{file_ids}        }

sub _build_original_post {
    my $self = shift;

    return $self->_get_related_post($self->original_id);
}

sub _build_parent_post {
    my $self = shift;

    return $self->_get_related_post($self->parent_id);
}

sub _build_pending_post {
    my $self = shift;

    return $self->_get_related_post($self->pending_post_id);
}

sub _build_root_post {
    my $self = shift;

    return $self->_get_related_post($self->root_id);
}

sub _build_files {
    my $self = shift;

    return [] unless $self->file_ids;
    return [ map { $self->api->file->get($_) } @{$self->file_ids} ];
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Post

=head1 DESCRIPTION

Describes a Mattermost post.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::Post>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->post->get('ID-HERE')->item->delete();

Is the same as:

    my $response = $mattermost->api->post->delete('ID-HERE');

=over 4

=item C<delete()>

=item C<update()>

=item C<patch()>

=item C<thread()>

=item C<files()>

=item C<pin()>

=item C<inpin()>

=item C<reactions()>

=item C<perform_action()>

=back

=head2 ATTRIBUTES

=over 4

=item C<hashtag>

A string containing any hashtags in the message.

=item C<original_id>

=item C<parent_id>

=item C<pending_post_id>

=item C<root_id>

=item C<filenames>

A list of filenames attached to the post.

=item C<file_ids>

A list of file IDs attached to the post.

=item C<original_post>

Related original post object.

=item C<parent_post>

Related parent post object.

=item C<pending_post>

Related pending post object.

=item C<root_post>

Related root post object.

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Post>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToChannel>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Message>

=item C<WebService::Mattermost::V4::API::Object::Role::Props>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

