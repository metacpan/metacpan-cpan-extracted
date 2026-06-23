package WWW::Gitea::API::PullRequests;

# ABSTRACT: Gitea pull requests API

use Moo;
use Carp qw(croak);
use WWW::Gitea::PullRequest;
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
            'pulls.list'      => { method => 'GET',   path => '/repos/{owner}/{repo}/pulls' },
            'pulls.create'    => { method => 'POST',  path => '/repos/{owner}/{repo}/pulls' },
            'pulls.get'       => { method => 'GET',   path => '/repos/{owner}/{repo}/pulls/{index}' },
            'pulls.edit'      => { method => 'PATCH', path => '/repos/{owner}/{repo}/pulls/{index}' },
            'pulls.merge'     => { method => 'POST',  path => '/repos/{owner}/{repo}/pulls/{index}/merge' },
            'pulls.is_merged' => { method => 'GET',   path => '/repos/{owner}/{repo}/pulls/{index}/merge' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data, $owner, $repo) = @_;
    return WWW::Gitea::PullRequest->new(
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
    my $data = $self->call_operation('pulls.list',
        path => { owner => $owner, repo => $repo }, query => \%query);
    return [ map { $self->_wrap($_, $owner, $repo) } @{ $data || [] } ];
}


sub create {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'head required'  unless defined $args{head};
    croak 'base required'  unless defined $args{base};
    croak 'title required' unless defined $args{title};
    my $data = $self->call_operation('pulls.create',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub get {
    my ($self, $owner, $repo, $index) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('pulls.get',
        path => { owner => $owner, repo => $repo, index => $index });
    return $self->_wrap($data, $owner, $repo);
}


sub edit {
    my ($self, $owner, $repo, $index, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $data = $self->call_operation('pulls.edit',
        path => { owner => $owner, repo => $repo, index => $index },
        body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub merge {
    my ($self, $owner, $repo, $index, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    $args{Do} //= 'merge';
    return $self->call_operation('pulls.merge',
        path => { owner => $owner, repo => $repo, index => $index },
        body => \%args);
}


sub is_merged {
    my ($self, $owner, $repo, $index) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'index required' unless defined $index;
    my $op   = $self->get_operation('pulls.is_merged');
    my $path = $self->_resolve_path($op->{path},
        { owner => $owner, repo => $repo, index => $index });
    my $code = $self->client->request_status($op->{method}, $path);
    return $code == 204 ? 1 : 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::PullRequests - Gitea pull requests API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $pulls = $gitea->pulls->list('getty', 'p5-www-gitea', state => 'open');

    my $pr = $gitea->pulls->create('getty', 'p5-www-gitea',
        head => 'feature', base => 'main', title => 'Add feature',
    );

    $gitea->pulls->merge('getty', 'p5-www-gitea', $pr->number, Do => 'squash');
    my $merged = $gitea->pulls->is_merged('getty', 'p5-www-gitea', $pr->number);

=head1 DESCRIPTION

Controller for the Gitea pull requests API. Reached via C<< $gitea->pulls >>.
Pull requests are addressed by their per-repository C<index> (they share the
issue number space).

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 list

    my $pulls = $gitea->pulls->list('getty', 'p5-www-gitea',
        state => 'open', sort => 'recentupdate');

Lists pull requests. Accepts the Gitea query parameters (C<state> —
C<open>/C<closed>/C<all>, C<sort>, C<milestone>, C<labels>, C<poster>,
C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::PullRequest>.

=head2 create

    my $pr = $gitea->pulls->create('getty', 'p5-www-gitea',
        head  => 'feature-branch',     # or 'user:branch' for cross-fork
        base  => 'main',
        title => 'Add the feature',
        body  => '...',
    );

Creates a pull request. C<head>, C<base> and C<title> are required; other
arguments are passed through as the JSON body. Returns a
L<WWW::Gitea::PullRequest>.

=head2 get

    my $pr = $gitea->pulls->get('getty', 'p5-www-gitea', 12);

Fetches a pull request by its repository index. Returns a
L<WWW::Gitea::PullRequest>.

=head2 edit

    $gitea->pulls->edit('getty', 'p5-www-gitea', 12, state => 'closed');

Edits a pull request. Arguments are passed through as the JSON body. Returns
the updated L<WWW::Gitea::PullRequest>.

=head2 merge

    $gitea->pulls->merge('getty', 'p5-www-gitea', 12);                  # plain merge
    $gitea->pulls->merge('getty', 'p5-www-gitea', 12, Do => 'squash');

Merges a pull request. The merge style is given by C<Do>
(C<merge>/C<rebase>/C<rebase-merge>/C<squash>/C<manually-merged>), defaulting
to C<merge>. Other arguments (C<MergeTitleField>, C<MergeMessageField>,
C<delete_branch_after_merge>, ...) are passed through. Returns a true value on
success.

=head2 is_merged

    if ($gitea->pulls->is_merged('getty', 'p5-www-gitea', 12)) { ... }

Checks whether a pull request has been merged. Gitea answers this status-only
endpoint with C<204> (merged) or C<404> (not merged), so this returns a plain
boolean rather than a body. Returns C<1> if merged, C<0> otherwise.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::PullRequest>

=item * L<WWW::Gitea::API::Issues>

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
