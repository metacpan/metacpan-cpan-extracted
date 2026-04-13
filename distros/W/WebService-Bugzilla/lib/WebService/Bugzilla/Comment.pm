#!/usr/bin/false
# ABSTRACT: Bugzilla Comment object and service
# PODNAME: WebService::Bugzilla::Comment

package WebService::Bugzilla::Comment 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

has attachment_id => (is => 'ro');
has bug_id        => (is => 'ro');
has count         => (is => 'ro');
has creation_time => (is => 'ro');
has creator       => (is => 'ro');
has is_markdown   => (is => 'ro');
has is_private    => (is => 'ro');
has raw_text      => (is => 'ro');
has reactions     => (is => 'ro');
has tags          => (is => 'ro');
has text          => (is => 'ro');
has time          => (is => 'ro');

sub create {
    my ($self, $bug_id, %params) = @_;
    my $res = $self->client->post($self->_mkuri("bug/$bug_id/comment"), \%params);
    return $self->new(
        client => $self->client,
        id     => $res->{id},
        bug_id => $bug_id,
        %params
    );
}

sub get {
    my ($self, $bug_id) = @_;
    my $res = $self->client->get($self->_mkuri("bug/$bug_id/comment"));
    return [
        map {
            $self->new(
                client => $self->client,
                %{ $_ }
            )
        }
        @{ $res->{bugs}{$bug_id}{comments} // [] }
    ];
}

sub get_by_id {
    my ($self, $comment_id) = @_;
    my $res = $self->client->get($self->_mkuri("bug/comment/$comment_id"));
    return unless $res->{comments} && %{ $res->{comments} };
    my ($data) = values %{ $res->{comments} };
    return $self->new(
        client => $self->client,
        %{ $data }
    );
}

sub get_reactions {
    my ($self, $comment_id) = @_;
    $comment_id //= $self->id;
    require WebService::Bugzilla::UserDetail;
    my $res = $self->client->get($self->_mkuri("bug/comment/$comment_id/reactions"));
    my %inflated;
    for my $emoji (keys %{ $res }) {
        $inflated{$emoji} = [
            map { WebService::Bugzilla::UserDetail->new(%{ $_ }) } @{ $res->{$emoji} }
        ];
    }
    return \%inflated;
}

sub render {
    my ($self, %params) = @_;
    $params{id} //= $self->id if $self->has_id;
    my $res = $self->client->post($self->_mkuri('bug/comment/render'), \%params);
    return $res->{html};
}

sub search_tags {
    my ($self, $query, %params) = @_;
    my $res = $self->client->get($self->_mkuri("bug/comment/tags/$query"), \%params);
    return $res;
}

sub update_reactions {
    my ($self, $comment_id, %params) = @_;
    $comment_id //= $self->id;
    require WebService::Bugzilla::UserDetail;
    my $res = $self->client->put($self->_mkuri("bug/comment/$comment_id/reactions"), \%params);
    my %inflated;
    for my $emoji (keys %{ $res }) {
        $inflated{$emoji} = [
            map { WebService::Bugzilla::UserDetail->new(%{ $_ }) } @{ $res->{$emoji} }
        ];
    }
    return \%inflated;
}

sub update_tags {
    my ($self, $comment_id, %params) = @_;
    $comment_id //= $self->id;
    my $res = $self->client->put($self->_mkuri("bug/comment/$comment_id/tags"), \%params);
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Comment - Bugzilla Comment object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Get comments for a bug
    my $comments = $bz->comment->get(12345);
    for my $c (@{$comments}) {
        say $c->creator, ': ', $c->text;
    }

    # Add a comment
    $bz->comment->create(12345, comment => 'See also bug 67890.');

    # Fetch a single comment by ID
    my $c = $bz->comment->get_by_id(98765);

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Comment API|https://bmo.readthedocs.io/en/latest/api/core/v1/comment.html>.
Comment objects represent comments on bugs and provide helpers to create,
fetch, render, and manage comment reactions and tags.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<attachment_id>

Attachment ID associated with this comment, if any.

=item C<bug_id>

ID of the bug this comment belongs to.

=item C<count>

Zero-based index of this comment within the bug.

=item C<creation_time>

ISO 8601 datetime when the comment was created.

=item C<creator>

Login name of the user who wrote the comment.

=item C<is_markdown>

Boolean.  Whether the comment body is Markdown.

=item C<is_private>

Boolean.  Whether the comment is private (visible only to insiders).

=item C<raw_text>

Original comment text before any rendering.

=item C<reactions>

Hashref mapping emoji names to arrayrefs of
L<WebService::Bugzilla::UserDetail> objects.

=item C<tags>

Arrayref of tag strings attached to this comment.

=item C<text>

Rendered comment text.

=item C<time>

ISO 8601 datetime when the comment was recorded.

=back

=head1 METHODS

=head2 create

    my $c = $bz->comment->create($bug_id, %params);

Add a comment to a bug.
See L<POST /rest/bug/{id}/comment|https://bmo.readthedocs.io/en/latest/api/core/v1/comment.html#create-comment>.

=head2 get

    my $comments = $bz->comment->get($bug_id);

Fetch all comments for a bug.
See L<GET /rest/bug/{id}/comment|https://bmo.readthedocs.io/en/latest/api/core/v1/comment.html#get-comments>.

Returns an arrayref of L<WebService::Bugzilla::Comment> objects.

=head2 get_by_id

    my $c = $bz->comment->get_by_id($comment_id);

Fetch a single comment by its numeric ID.
See L<GET /rest/bug/comment/{id}|https://bmo.readthedocs.io/en/latest/api/core/v1/comment.html#get-comments>.

Returns a L<WebService::Bugzilla::Comment>, or C<undef> if not found.

=head2 get_reactions

    my $reactions = $bz->comment->get_reactions($comment_id);

Fetch reactions for a comment.  Returns a hashref mapping emoji names to
arrayrefs of L<WebService::Bugzilla::UserDetail> objects.

=head2 render

    my $html = $bz->comment->render(id => $comment_id);
    my $html = $comment->render;

Render comment text (Markdown to HTML) via the server.

=head2 search_tags

    my $tags = $bz->comment->search_tags($query, %params);

Search for comment tags matching a query string.

=head2 update_reactions

    my $reactions = $bz->comment->update_reactions($comment_id, %params);

Add or remove reactions on a comment.

=head2 update_tags

    my $tags = $bz->comment->update_tags($comment_id, %params);

Add or remove tags on a comment.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::UserDetail> - lightweight user objects in reactions

L<https://bmo.readthedocs.io/en/latest/api/core/v1/comment.html> - Bugzilla Comment REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
