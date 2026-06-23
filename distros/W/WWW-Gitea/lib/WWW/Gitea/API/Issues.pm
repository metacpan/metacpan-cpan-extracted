package WWW::Gitea::API::Issues;

# ABSTRACT: Gitea issues API (issues and issue comments)

use Moo;
use Carp qw(croak);
use WWW::Gitea::Issue;
use WWW::Gitea::Comment;
use WWW::Gitea::Attachment;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);


has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'issues.list'           => { method => 'GET',   path => '/repos/{owner}/{repo}/issues' },
            'issues.create'         => { method => 'POST',  path => '/repos/{owner}/{repo}/issues' },
            'issues.get'            => { method => 'GET',   path => '/repos/{owner}/{repo}/issues/{index}' },
            'issues.edit'           => { method => 'PATCH', path => '/repos/{owner}/{repo}/issues/{index}' },
            'issues.search'         => { method => 'GET',   path => '/repos/issues/search' },
            'issues.list_comments'  => { method => 'GET',   path => '/repos/{owner}/{repo}/issues/{index}/comments' },
            'issues.create_comment' => { method => 'POST',  path => '/repos/{owner}/{repo}/issues/{index}/comments' },
            'issues.list_attachments'          => { method => 'GET',    path => '/repos/{owner}/{repo}/issues/{index}/assets' },
            'issues.create_attachment'         => { method => 'POST',   path => '/repos/{owner}/{repo}/issues/{index}/assets' },
            'issues.get_attachment'            => { method => 'GET',    path => '/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}' },
            'issues.edit_attachment'           => { method => 'PATCH',  path => '/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}' },
            'issues.delete_attachment'         => { method => 'DELETE', path => '/repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}' },
            'issues.list_comment_attachments'  => { method => 'GET',    path => '/repos/{owner}/{repo}/issues/comments/{id}/assets' },
            'issues.create_comment_attachment' => { method => 'POST',   path => '/repos/{owner}/{repo}/issues/comments/{id}/assets' },
            'issues.get_comment_attachment'    => { method => 'GET',    path => '/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}' },
            'issues.edit_comment_attachment'   => { method => 'PATCH',  path => '/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}' },
            'issues.delete_comment_attachment' => { method => 'DELETE', path => '/repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data, $owner, $repo) = @_;
    return WWW::Gitea::Issue->new(
        client => $self->client,
        data   => $data,
        (defined $owner ? (owner => $owner) : ()),
        (defined $repo  ? (repo  => $repo)  : ()),
    );
}

sub list {
    my ($self, $owner, $repo, %query) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    my $data = $self->call_operation('issues.list',
        path => { owner => $owner, repo => $repo }, query => \%query);
    return [ map { $self->_wrap($_, $owner, $repo) } @{ $data || [] } ];
}


sub create {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'title required' unless defined $args{title};
    my $data = $self->call_operation('issues.create',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub get {
    my ($self, $owner, $repo, $index) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('issues.get',
        path => { owner => $owner, repo => $repo, index => $index });
    return $self->_wrap($data, $owner, $repo);
}


sub edit {
    my ($self, $owner, $repo, $index, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('issues.edit',
        path => { owner => $owner, repo => $repo, index => $index },
        body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub search {
    my ($self, %query) = @_;
    my $data = $self->call_operation('issues.search', query => \%query);
    return [ map { $self->_wrap($_) } @{ $data || [] } ];
}


sub comments {
    my ($self, $owner, $repo, $index, %query) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('issues.list_comments',
        path => { owner => $owner, repo => $repo, index => $index }, query => \%query);
    return [ map {
        WWW::Gitea::Comment->new(client => $self->client, data => $_)
    } @{ $data || [] } ];
}


sub create_comment {
    my ($self, $owner, $repo, $index, $body) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    croak 'body required'  unless defined $body;
    my $data = $self->call_operation('issues.create_comment',
        path => { owner => $owner, repo => $repo, index => $index },
        body => { body => $body });
    return WWW::Gitea::Comment->new(client => $self->client, data => $data);
}


sub _wrap_attachment {
    my ($self, $data) = @_;
    return WWW::Gitea::Attachment->new(client => $self->client, data => $data);
}

sub _build_upload {
    my ($self, %args) = @_;
    croak 'file or content required'
        unless defined $args{file} || defined $args{content};
    return defined $args{file}
        ? { field => 'attachment', file => $args{file},
            (defined $args{filename} ? (filename => $args{filename}) : ()) }
        : { field => 'attachment', content => $args{content},
            filename => ($args{filename} // $args{name} // 'attachment') };
}

# --- issue attachments ----------------------------------------------------

sub attachments {
    my ($self, $owner, $repo, $index, %query) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('issues.list_attachments',
        path => { owner => $owner, repo => $repo, index => $index },
        query => \%query);
    return [ map { $self->_wrap_attachment($_) } @{ $data || [] } ];
}


sub create_attachment {
    my ($self, $owner, $repo, $index, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $upload = $self->_build_upload(%args);
    my %query = defined $args{name} ? (name => $args{name}) : ();
    my $data = $self->call_operation('issues.create_attachment',
        path => { owner => $owner, repo => $repo, index => $index },
        (%query ? (query => \%query) : ()),
        upload => $upload);
    return $self->_wrap_attachment($data);
}


sub get_attachment {
    my ($self, $owner, $repo, $index, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'index required'         unless defined $index;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('issues.get_attachment',
        path => { owner => $owner, repo => $repo, index => $index,
            attachment_id => $attachment_id });
    return $self->_wrap_attachment($data);
}


sub edit_attachment {
    my ($self, $owner, $repo, $index, $attachment_id, %args) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'index required'         unless defined $index;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('issues.edit_attachment',
        path => { owner => $owner, repo => $repo, index => $index,
            attachment_id => $attachment_id },
        body => \%args);
    return $self->_wrap_attachment($data);
}


sub delete_attachment {
    my ($self, $owner, $repo, $index, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'index required'         unless defined $index;
    croak 'attachment_id required' unless defined $attachment_id;
    return $self->call_operation('issues.delete_attachment',
        path => { owner => $owner, repo => $repo, index => $index,
            attachment_id => $attachment_id });
}


# --- comment attachments --------------------------------------------------

sub comment_attachments {
    my ($self, $owner, $repo, $comment_id, %query) = @_;
    croak 'owner required'      unless defined $owner;
    croak 'repo required'       unless defined $repo;
    croak 'comment_id required' unless defined $comment_id;
    my $data = $self->call_operation('issues.list_comment_attachments',
        path => { owner => $owner, repo => $repo, id => $comment_id },
        query => \%query);
    return [ map { $self->_wrap_attachment($_) } @{ $data || [] } ];
}


sub create_comment_attachment {
    my ($self, $owner, $repo, $comment_id, %args) = @_;
    croak 'owner required'      unless defined $owner;
    croak 'repo required'       unless defined $repo;
    croak 'comment_id required' unless defined $comment_id;
    my $upload = $self->_build_upload(%args);
    my %query = defined $args{name} ? (name => $args{name}) : ();
    my $data = $self->call_operation('issues.create_comment_attachment',
        path => { owner => $owner, repo => $repo, id => $comment_id },
        (%query ? (query => \%query) : ()),
        upload => $upload);
    return $self->_wrap_attachment($data);
}


sub get_comment_attachment {
    my ($self, $owner, $repo, $comment_id, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'comment_id required'    unless defined $comment_id;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('issues.get_comment_attachment',
        path => { owner => $owner, repo => $repo, id => $comment_id,
            attachment_id => $attachment_id });
    return $self->_wrap_attachment($data);
}


sub edit_comment_attachment {
    my ($self, $owner, $repo, $comment_id, $attachment_id, %args) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'comment_id required'    unless defined $comment_id;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('issues.edit_comment_attachment',
        path => { owner => $owner, repo => $repo, id => $comment_id,
            attachment_id => $attachment_id },
        body => \%args);
    return $self->_wrap_attachment($data);
}


sub delete_comment_attachment {
    my ($self, $owner, $repo, $comment_id, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'comment_id required'    unless defined $comment_id;
    croak 'attachment_id required' unless defined $attachment_id;
    return $self->call_operation('issues.delete_comment_attachment',
        path => { owner => $owner, repo => $repo, id => $comment_id,
            attachment_id => $attachment_id });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Issues - Gitea issues API (issues and issue comments)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $issues = $gitea->issues->list('getty', 'p5-www-gitea', state => 'open');

    my $issue = $gitea->issues->create('getty', 'p5-www-gitea',
        title => 'Bug', body => '...', labels => [1, 2],
    );

    my $c = $gitea->issues->create_comment('getty', 'p5-www-gitea',
        $issue->number, 'thanks for the report');

=head1 DESCRIPTION

Controller for the Gitea issues API, including issue comments. Reached via
C<< $gitea->issues >>. Issues are addressed by their per-repository C<index>
(the number you see in the UI).

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 list

    my $issues = $gitea->issues->list('getty', 'p5-www-gitea',
        state => 'open', labels => 'bug', limit => 50);

Lists issues in a repository. Accepts the Gitea query parameters (C<state> —
C<open>/C<closed>/C<all>, C<labels>, C<q>, C<type> — C<issues>/C<pulls>,
C<milestones>, C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Issue>.

=head2 create

    my $issue = $gitea->issues->create('getty', 'p5-www-gitea',
        title    => 'Bug report',
        body     => 'It broke',
        labels   => [1, 2],          # label IDs
        assignees => ['getty'],
        milestone => 42,
    );

Creates an issue. C<title> is required; other arguments are passed through as
the JSON body. Returns a L<WWW::Gitea::Issue>.

=head2 get

    my $issue = $gitea->issues->get('getty', 'p5-www-gitea', 7);

Fetches an issue by its repository index. Returns a L<WWW::Gitea::Issue>.

=head2 edit

    $gitea->issues->edit('getty', 'p5-www-gitea', 7, state => 'closed');

Edits an issue (title, body, C<state> — C<open>/C<closed>, assignees,
milestone, ...). Arguments are passed through as the JSON body. Returns the
updated L<WWW::Gitea::Issue>.

=head2 search

    my $issues = $gitea->issues->search(q => 'crash', state => 'open');

Searches issues across all accessible repositories
(C<GET /repos/issues/search>). Accepts the Gitea query parameters (C<state>,
C<labels>, C<milestones>, C<q>, C<type>, C<owner>, C<team>, C<page>,
C<limit>). Returns an ArrayRef of L<WWW::Gitea::Issue>.

=head2 comments

    my $comments = $gitea->issues->comments('getty', 'p5-www-gitea', 7);
    my $page2    = $gitea->issues->comments('getty', 'p5-www-gitea', 7, page => 2, limit => 50);

Lists the comments on an issue. Accepts the Gitea query parameters (C<page>,
C<limit>, C<since>, C<before>). Returns an ArrayRef of L<WWW::Gitea::Comment>.

=head2 create_comment

    my $comment = $gitea->issues->create_comment(
        'getty', 'p5-www-gitea', 7, 'thanks!');

Adds a comment to an issue. Returns the new L<WWW::Gitea::Comment>.

=head2 attachments

    my $attachments = $gitea->issues->attachments('getty', 'p5-www-gitea', 7);

Lists the attachments on an issue. Accepts the Gitea query parameters
(C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Attachment>.

=head2 create_attachment

    my $a = $gitea->issues->create_attachment('getty', 'p5-www-gitea', 7,
        file => '/path/to/log.txt', name => 'log.txt');

    my $a = $gitea->issues->create_attachment('getty', 'p5-www-gitea', 7,
        content => $bytes, name => 'log.txt');

Uploads an attachment to an issue via C<multipart/form-data>. Pass B<either>
C<file> (a path on disk) B<or> C<content> (raw bytes); C<name> sets the display
name (C<name> query parameter), C<filename> the multipart part filename.
Returns a L<WWW::Gitea::Attachment>.

=head2 get_attachment

    my $a = $gitea->issues->get_attachment('getty', 'p5-www-gitea', 7, 12);

Fetches a single issue attachment by its numeric attachment id. Returns a
L<WWW::Gitea::Attachment>.

=head2 edit_attachment

    $gitea->issues->edit_attachment('getty', 'p5-www-gitea', 7, 12,
        name => 'renamed.txt');

Edits an issue attachment (only C<name> is editable). Arguments are passed
through as the JSON body. Returns the updated L<WWW::Gitea::Attachment>.

=head2 delete_attachment

    $gitea->issues->delete_attachment('getty', 'p5-www-gitea', 7, 12);

Deletes an issue attachment by its numeric attachment id. Returns a true value
on success.

=head2 comment_attachments

    my $attachments =
        $gitea->issues->comment_attachments('getty', 'p5-www-gitea', 99);

Lists the attachments on a comment (addressed by comment id). Accepts the Gitea
query parameters (C<page>, C<limit>). Returns an ArrayRef of
L<WWW::Gitea::Attachment>.

=head2 create_comment_attachment

    my $a = $gitea->issues->create_comment_attachment('getty', 'p5-www-gitea',
        99, file => '/path/to/log.txt', name => 'log.txt');

Uploads an attachment to a comment via C<multipart/form-data>. Same C<file> /
C<content> / C<name> / C<filename> arguments as L</create_attachment>. Returns
a L<WWW::Gitea::Attachment>.

=head2 get_comment_attachment

    my $a = $gitea->issues->get_comment_attachment('getty', 'p5-www-gitea',
        99, 12);

Fetches a single comment attachment by its numeric attachment id. Returns a
L<WWW::Gitea::Attachment>.

=head2 edit_comment_attachment

    $gitea->issues->edit_comment_attachment('getty', 'p5-www-gitea', 99, 12,
        name => 'renamed.txt');

Edits a comment attachment (only C<name> is editable). Arguments are passed
through as the JSON body. Returns the updated L<WWW::Gitea::Attachment>.

=head2 delete_comment_attachment

    $gitea->issues->delete_comment_attachment('getty', 'p5-www-gitea', 99, 12);

Deletes a comment attachment by its numeric attachment id. Returns a true value
on success.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Issue>

=item * L<WWW::Gitea::Comment>

=item * L<WWW::Gitea::Attachment>

=item * L<WWW::Gitea::API::PullRequests>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://codeberg.org/getty/p5-www-gitea/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
