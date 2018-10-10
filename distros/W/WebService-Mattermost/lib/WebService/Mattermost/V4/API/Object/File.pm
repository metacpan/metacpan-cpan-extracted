package WebService::Mattermost::V4::API::Object::File;

use Moo;
use Types::Standard qw(Bool Int Maybe Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::BelongingToPost
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Name
    WebService::Mattermost::V4::API::Object::Role::Timestamps
);

################################################################################

has [ qw(extension mime_type) ] => (is => 'ro', isa => Maybe[Str],  lazy => 1, builder => 1);
has [ qw(size width height)   ] => (is => 'ro', isa => Maybe[Int],  lazy => 1, builder => 1);
has has_preview_image           => (is => 'ro', isa => Maybe[Bool], lazy => 1, builder => 1);

################################################################################

sub _build_extension         { shift->raw_data->{extension}                 }
sub _build_mime_type         { shift->raw_data->{mime_type}                 }
sub _build_size              { shift->raw_data->{size}                      }
sub _build_width             { shift->raw_data->{width}                     }
sub _build_height            { shift->raw_data->{height}                    }
sub _build_has_preview_image { shift->raw_data->{has_preview_image} ? 1 : 0 }

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('file');
    $self->set_available_api_methods([ qw(
        get_thumbnail
        get_preview
        get_link
        get_metadata
    ) ]);

    return 1;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::File

=head1 DESCRIPTION

Details a Mattermost File object.

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::File>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->file->get('ID-HERE')->item->get_thumbnail();

Is the same as:

    my $response = $mattermost->api->file->get_thumbnail('ID-HERE');

=over 4

=item C<get_thumbnail()>

=item C<get_preview()>

=item C<get_link()>

=item C<get_metadata()>

=back

=head2 ATTRIBUTES

=over 4

=item C<extension>

=item C<has_preview_image>

=item C<height>

=item C<mime_type>

=item C<size>

=item C<width>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Resource::File>

=item C<WebService::Mattermost::V4::API::Resource::Files>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToPost>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Name>

=item C<WebService::Mattermost::V4::API::Object::Role::Timestamps>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

