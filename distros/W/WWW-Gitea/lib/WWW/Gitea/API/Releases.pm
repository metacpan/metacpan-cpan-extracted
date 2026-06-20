package WWW::Gitea::API::Releases;

# ABSTRACT: Gitea repository releases API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Release;
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
            'releases.list'        => { method => 'GET',    path => '/repos/{owner}/{repo}/releases' },
            'releases.create'      => { method => 'POST',   path => '/repos/{owner}/{repo}/releases' },
            'releases.get'         => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/{id}' },
            'releases.get_by_tag'  => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/tags/{tag}' },
            'releases.edit'        => { method => 'PATCH',  path => '/repos/{owner}/{repo}/releases/{id}' },
            'releases.delete'      => { method => 'DELETE', path => '/repos/{owner}/{repo}/releases/{id}' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data, $owner, $repo) = @_;
    return WWW::Gitea::Release->new(
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
    my $data = $self->call_operation('releases.list',
        path => { owner => $owner, repo => $repo }, query => \%query);
    return [ map { $self->_wrap($_, $owner, $repo) } @{ $data || [] } ];
}


sub create {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required'    unless defined $owner;
    croak 'repo required'     unless defined $repo;
    croak 'tag_name required' unless defined $args{tag_name};
    my $data = $self->call_operation('releases.create',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub get {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('releases.get',
        path => { owner => $owner, repo => $repo, id => $id });
    return $self->_wrap($data, $owner, $repo);
}


sub get_by_tag {
    my ($self, $owner, $repo, $tag) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'tag required'   unless defined $tag;
    my $data = $self->call_operation('releases.get_by_tag',
        path => { owner => $owner, repo => $repo, tag => $tag });
    return $self->_wrap($data, $owner, $repo);
}


sub edit {
    my ($self, $owner, $repo, $id, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('releases.edit',
        path => { owner => $owner, repo => $repo, id => $id }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub delete {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    return $self->call_operation('releases.delete',
        path => { owner => $owner, repo => $repo, id => $id });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Releases - Gitea repository releases API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $releases = $gitea->releases->list('getty', 'p5-www-gitea');

    my $rel = $gitea->releases->create('getty', 'p5-www-gitea',
        tag_name => 'v1.0.0', name => 'First release', body => 'Changelog',
    );

    my $same = $gitea->releases->get_by_tag('getty', 'p5-www-gitea', 'v1.0.0');

=head1 DESCRIPTION

Controller for the Gitea repository releases API. Reached via
C<< $gitea->releases >>. Releases are addressed by their numeric C<id>, or by
tag via L</get_by_tag>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 list

    my $releases = $gitea->releases->list('getty', 'p5-www-gitea');

Lists releases. Accepts the Gitea query parameters (C<draft>, C<pre-release>,
C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Release>.

=head2 create

    my $rel = $gitea->releases->create('getty', 'p5-www-gitea',
        tag_name         => 'v1.0.0',
        name             => 'First release',
        body             => 'Changelog ...',
        target_commitish => 'main',
        draft            => \0,
        prerelease       => \0,
    );

Creates a release. C<tag_name> is required; other arguments are passed
through as the JSON body. Returns a L<WWW::Gitea::Release>.

=head2 get

    my $rel = $gitea->releases->get('getty', 'p5-www-gitea', 5);

Fetches a release by numeric id. Returns a L<WWW::Gitea::Release>.

=head2 get_by_tag

    my $rel = $gitea->releases->get_by_tag('getty', 'p5-www-gitea', 'v1.0.0');

Fetches a release by its tag name. Returns a L<WWW::Gitea::Release>.

=head2 edit

    $gitea->releases->edit('getty', 'p5-www-gitea', 5, draft => \0);

Edits a release. Arguments are passed through as the JSON body. Returns the
updated L<WWW::Gitea::Release>.

=head2 delete

    $gitea->releases->delete('getty', 'p5-www-gitea', 5);

Deletes a release by numeric id. Returns a true value on success.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Release>

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
