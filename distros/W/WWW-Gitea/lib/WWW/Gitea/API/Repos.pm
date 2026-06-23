package WWW::Gitea::API::Repos;

# ABSTRACT: Gitea repositories API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Repo;
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
            'repos.get'               => { method => 'GET',    path => '/repos/{owner}/{repo}' },
            'repos.edit'              => { method => 'PATCH',  path => '/repos/{owner}/{repo}' },
            'repos.delete'            => { method => 'DELETE', path => '/repos/{owner}/{repo}' },
            'repos.search'            => { method => 'GET',    path => '/repos/search' },
            'repos.fork'              => { method => 'POST',   path => '/repos/{owner}/{repo}/forks' },
            'repos.create_current'    => { method => 'POST',   path => '/user/repos' },
            'repos.create_org'        => { method => 'POST',   path => '/orgs/{org}/repos' },
            'repos.list_current'      => { method => 'GET',    path => '/user/repos' },
            'repos.list_user'         => { method => 'GET',    path => '/users/{username}/repos' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Gitea::Repo->new(client => $self->client, data => $data);
}

sub get {
    my ($self, $owner, $repo) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    my $data = $self->call_operation('repos.get',
        path => { owner => $owner, repo => $repo });
    return $self->_wrap($data);
}


sub create {
    my ($self, %args) = @_;
    croak 'name required' unless defined $args{name};
    my $org = delete $args{org};
    my $body = { %args };
    my $data;
    if (defined $org) {
        $data = $self->call_operation('repos.create_org',
            path => { org => $org }, body => $body);
    }
    else {
        $data = $self->call_operation('repos.create_current', body => $body);
    }
    return $self->_wrap($data);
}


sub edit {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    my $data = $self->call_operation('repos.edit',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data);
}


sub delete {
    my ($self, $owner, $repo) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    return $self->call_operation('repos.delete',
        path => { owner => $owner, repo => $repo });
}


sub search {
    my ($self, %query) = @_;
    my $data = $self->call_operation('repos.search', query => \%query);
    return [ map { $self->_wrap($_) } @{ $data->{data} || [] } ];
}


sub fork {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    my $data = $self->call_operation('repos.fork',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data);
}


sub list {
    my ($self, %args) = @_;
    my $username = delete $args{username};
    my $data;
    if (defined $username) {
        $data = $self->call_operation('repos.list_user',
            path => { username => $username }, query => \%args);
    }
    else {
        $data = $self->call_operation('repos.list_current', query => \%args);
    }
    return [ map { $self->_wrap($_) } @{ $data || [] } ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Repos - Gitea repositories API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $repo = $gitea->repos->get('getty', 'p5-www-gitea');

    my $new = $gitea->repos->create(
        name      => 'my-repo',
        private   => 1,
        auto_init => 1,
    );

    my @hits = @{ $gitea->repos->search(q => 'gitea', limit => 5) };

=head1 DESCRIPTION

Controller for the Gitea repositories API. Reached via C<< $gitea->repos >>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 get

    my $repo = $gitea->repos->get('getty', 'p5-www-gitea');

Fetches a repository by owner and name. Returns a L<WWW::Gitea::Repo>.

=head2 create

    # In the authenticated user's namespace
    my $repo = $gitea->repos->create(
        name        => 'my-repo',
        description => '...',
        private     => 1,
        auto_init   => 1,
        default_branch => 'main',
    );

    # In an organization
    my $repo = $gitea->repos->create(org => 'myorg', name => 'my-repo');

Creates a repository. With C<org> it is created under that organization
(C<POST /orgs/{org}/repos>), otherwise under the authenticated user
(C<POST /user/repos>). All other arguments are passed through to Gitea as the
JSON body. Returns a L<WWW::Gitea::Repo>.

=head2 edit

    my $repo = $gitea->repos->edit('getty', 'p5-www-gitea',
        description => 'new description',
        archived    => \1,
    );

Edits a repository. Arguments are passed through as the JSON body. Returns the
updated L<WWW::Gitea::Repo>.

=head2 delete

    $gitea->repos->delete('getty', 'old-repo');

Deletes a repository. Returns a true value on success.

=head2 search

    my $repos = $gitea->repos->search(q => 'gitea', limit => 10);

Searches repositories. Accepts the Gitea query parameters (C<q>, C<topic>,
C<sort>, C<order>, C<private>, C<archived>, C<page>, C<limit>, ...). Returns
an ArrayRef of L<WWW::Gitea::Repo> objects.

=head2 fork

    my $fork = $gitea->repos->fork('getty', 'p5-www-gitea');
    my $fork = $gitea->repos->fork('getty', 'p5-www-gitea',
        organization => 'myorg', name => 'my-fork');

Forks a repository. Optional body arguments (C<organization>, C<name>) are
passed through. Returns the new fork as a L<WWW::Gitea::Repo>.

=head2 list

    my $mine   = $gitea->repos->list;                       # authenticated user
    my $theirs = $gitea->repos->list(username => 'getty');  # another user

Lists repositories. Without C<username> it lists the authenticated user's
repos (C<GET /user/repos>); with C<username> it lists that user's public
repos (C<GET /users/{username}/repos>). Remaining arguments (C<page>,
C<limit>) become query parameters. Returns an ArrayRef of L<WWW::Gitea::Repo>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Repo>

=item * L<WWW::Gitea::API::Orgs>

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
