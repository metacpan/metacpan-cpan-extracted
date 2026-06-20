package WWW::Gitea::API::Issues;

# ABSTRACT: Gitea issues API (issues and issue comments)

use Moo;
use Carp qw(croak);
use WWW::Gitea::Issue;
use WWW::Gitea::Comment;
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
    my ($self, $owner, $repo, $index) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('issues.list_comments',
        path => { owner => $owner, repo => $repo, index => $index });
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



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Issues - Gitea issues API (issues and issue comments)

=head1 VERSION

version 0.001

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

Lists the comments on an issue. Returns an ArrayRef of L<WWW::Gitea::Comment>.

=head2 create_comment

    my $comment = $gitea->issues->create_comment(
        'getty', 'p5-www-gitea', 7, 'thanks!');

Adds a comment to an issue. Returns the new L<WWW::Gitea::Comment>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Issue>

=item * L<WWW::Gitea::Comment>

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
