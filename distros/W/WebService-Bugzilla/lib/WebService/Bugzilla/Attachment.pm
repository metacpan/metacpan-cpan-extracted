#!/usr/bin/false
# ABSTRACT: Bugzilla Attachment object and service
# PODNAME: WebService::Bugzilla::Attachment

package WebService::Bugzilla::Attachment 0.001;
use strictures 2;
use Moo;
use Carp qw(croak);
use namespace::clean;

extends 'WebService::Bugzilla::Object';
with 'WebService::Bugzilla::Role::Updatable';

sub _unwrap_key { 'attachments' }

has bug_id           => (is => 'ro', lazy => 1, builder => '_build_bug_id');
has content_type     => (is => 'ro', lazy => 1, builder => '_build_content_type');
has creation_time    => (is => 'ro', lazy => 1, builder => '_build_creation_time');
has creator          => (is => 'ro', lazy => 1, builder => '_build_creator');
has description      => (is => 'ro', lazy => 1, builder => '_build_description');
has filename         => (is => 'ro', lazy => 1, builder => '_build_filename');
has is_obsolete      => (is => 'ro', lazy => 1, builder => '_build_is_obsolete');
has is_patch         => (is => 'ro', lazy => 1, builder => '_build_is_patch');
has is_private       => (is => 'ro', lazy => 1, builder => '_build_is_private');
has last_change_time => (is => 'ro', lazy => 1, builder => '_build_last_change_time');
has size             => (is => 'ro', lazy => 1, builder => '_build_size');

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args = $class->$orig(@args);
    if (exists $args->{file_name}) {
        $args->{filename} = delete $args->{file_name};
    }
    return $args;
};

my @attrs = qw(
    bug_id
    content_type
    creation_time
    creator
    description
    filename
    is_obsolete
    is_patch
    is_private
    last_change_time
    size
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            $self->_fetch_full($self->_mkuri('attachment/' . $self->id));
            return $self->_api_data->{$attr};
        };
    }
}

sub create {
    my ($self, $bug_id, %params) = @_;
    my $res = $self->client->post($self->_mkuri("bug/$bug_id/attachment"), \%params);
    return $self->new(
        client => $self->client,
        _data  => { id => $res->{ids}[0], bug_id => $bug_id },
    );
}

sub get {
    my ($self, $id) = @_;
    my $res = $self->client->get($self->_mkuri("attachment/$id"));
    return unless $res->{attachments} && @{ $res->{attachments} };
    my $data = $res->{attachments}[0];
    if (exists $data->{file_name}) {
        $data->{filename} = delete $data->{file_name};
    }
    return $self->new(
        client => $self->client,
        _data  => $data,
    );
}

sub search {
    my ($self, %params) = @_;
    my $bug_id = $params{bug_id} // croak 'bug_id is required for attachment search';
    my $res = $self->client->get($self->_mkuri("bug/$bug_id/attachment"));
    return [
        map {
            my $data = $_;
            if (exists $data->{file_name}) {
                $data->{filename} = delete $data->{file_name};
            }
            $self->new(
                client => $self->client,
                _data  => $data
            )
        }
        @{ ($res->{bugs} // {})->{"$bug_id"} // [] }
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Attachment - Bugzilla Attachment object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Fetch an attachment by ID
    my $att = $bz->attachment->get(42);
    say $att->filename, ' (', $att->content_type, ')';

    # List attachments on a bug
    my $list = $bz->attachment->search(bug_id => 12345);

    # Create a new attachment
    my $new = $bz->attachment->create(12345,
        file_name    => 'patch.diff',
        content_type => 'text/plain',
        data         => $base64_data,
        summary      => 'Proposed fix',
    );

    # Update metadata
    $att->update(is_obsolete => 1);

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Attachment API|https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html>.
Attachment objects represent file attachments on bugs and expose read-only
attributes about the file plus helper methods to create, fetch, search, and
update attachments.

=head1 ATTRIBUTES

All attributes are read-only and lazy.  Accessing any attribute on a stub
object triggers a single API call that populates every field at once.

=over 4

=item C<bug_id>

The ID of the bug this attachment belongs to.

=item C<content_type>

MIME content type of the attachment (e.g. C<text/plain>).

=item C<creation_time>

ISO 8601 datetime when the attachment was created.

=item C<creator>

Login name of the user who created the attachment.

=item C<description>

Short description / summary of the attachment.

=item C<filename>

The on-disk filename of the attachment.

=item C<is_obsolete>

Boolean.  Whether the attachment has been marked obsolete.

=item C<is_patch>

Boolean.  Whether the attachment is a patch.

=item C<is_private>

Boolean.  Whether the attachment is private (visible only to insiders).

=item C<last_change_time>

ISO 8601 datetime of the most recent change.

=item C<size>

Size of the attachment in bytes.

=back

=head1 METHODS

=head2 BUILDARGS

L<Moo> C<around> modifier.  Normalises the incoming construction arguments
so that the Bugzilla-native C<file_name> key is accepted as an alias for the
C<filename> attribute.

=head2 create

    my $att = $bz->attachment->create($bug_id, %params);

Create a new attachment on the given bug.
See L<POST /rest/bug/{id}/attachment|https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html#create-attachment>.

Returns a stub L<WebService::Bugzilla::Attachment> with the new C<id>.

=head2 get

    my $att = $bz->attachment->get($attachment_id);

Fetch a single attachment by its numeric ID.
See L<GET /rest/bug/attachment/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html#get-attachment>.

Returns a L<WebService::Bugzilla::Attachment>, or C<undef> if not found.

=head2 search

    my $list = $bz->attachment->search(bug_id => $id);

Retrieve all attachments for the specified bug.
See L<GET /rest/bug/{id}/attachment|https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html#get-attachment>.

Returns an arrayref of L<WebService::Bugzilla::Attachment> objects.

=head2 update

    my $updated = $att->update(%params);
    my $updated = $bz->attachment->update($id, %params);

Update attachment metadata.
See L<PUT /rest/attachment/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html#update-attachment>.

Returns a L<WebService::Bugzilla::Attachment> with the updated data.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Bug> - bug objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/attachment.html> - Bugzilla Attachment REST API

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
