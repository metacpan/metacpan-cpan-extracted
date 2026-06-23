package WWW::Gitea::API::Releases;

# ABSTRACT: Gitea repository releases API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Release;
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
            'releases.list'        => { method => 'GET',    path => '/repos/{owner}/{repo}/releases' },
            'releases.create'      => { method => 'POST',   path => '/repos/{owner}/{repo}/releases' },
            'releases.get'         => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/{id}' },
            'releases.get_by_tag'  => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/tags/{tag}' },
            'releases.edit'        => { method => 'PATCH',  path => '/repos/{owner}/{repo}/releases/{id}' },
            'releases.delete'      => { method => 'DELETE', path => '/repos/{owner}/{repo}/releases/{id}' },
            'releases.list_assets'  => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/{id}/assets' },
            'releases.create_asset' => { method => 'POST',   path => '/repos/{owner}/{repo}/releases/{id}/assets' },
            'releases.get_asset'    => { method => 'GET',    path => '/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}' },
            'releases.edit_asset'   => { method => 'PATCH',  path => '/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}' },
            'releases.delete_asset' => { method => 'DELETE', path => '/repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}' },
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


sub _wrap_asset {
    my ($self, $data) = @_;
    return WWW::Gitea::Attachment->new(client => $self->client, data => $data);
}

sub assets {
    my ($self, $owner, $repo, $id, %query) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('releases.list_assets',
        path => { owner => $owner, repo => $repo, id => $id }, query => \%query);
    return [ map { $self->_wrap_asset($_) } @{ $data || [] } ];
}


sub create_asset {
    my ($self, $owner, $repo, $id, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    croak 'file or content required'
        unless defined $args{file} || defined $args{content};
    my %query = defined $args{name} ? (name => $args{name}) : ();
    my %upload = defined $args{file}
        ? (field => 'attachment', file => $args{file},
            (defined $args{filename} ? (filename => $args{filename}) : ()))
        : (field => 'attachment', content => $args{content},
            filename => ($args{filename} // $args{name} // 'attachment'));
    my $data = $self->call_operation('releases.create_asset',
        path => { owner => $owner, repo => $repo, id => $id },
        (%query ? (query => \%query) : ()),
        upload => \%upload);
    return $self->_wrap_asset($data);
}


sub get_asset {
    my ($self, $owner, $repo, $id, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'id required'            unless defined $id;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('releases.get_asset',
        path => { owner => $owner, repo => $repo, id => $id,
            attachment_id => $attachment_id });
    return $self->_wrap_asset($data);
}


sub edit_asset {
    my ($self, $owner, $repo, $id, $attachment_id, %args) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'id required'            unless defined $id;
    croak 'attachment_id required' unless defined $attachment_id;
    my $data = $self->call_operation('releases.edit_asset',
        path => { owner => $owner, repo => $repo, id => $id,
            attachment_id => $attachment_id },
        body => \%args);
    return $self->_wrap_asset($data);
}


sub delete_asset {
    my ($self, $owner, $repo, $id, $attachment_id) = @_;
    croak 'owner required'         unless defined $owner;
    croak 'repo required'          unless defined $repo;
    croak 'id required'            unless defined $id;
    croak 'attachment_id required' unless defined $attachment_id;
    return $self->call_operation('releases.delete_asset',
        path => { owner => $owner, repo => $repo, id => $id,
            attachment_id => $attachment_id });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Releases - Gitea repository releases API

=head1 VERSION

version 0.003

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

=head2 assets

    my $assets = $gitea->releases->assets('getty', 'p5-www-gitea', 5);

Lists the assets attached to a release. Accepts the Gitea query parameters
(C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Attachment>.

=head2 create_asset

    my $asset = $gitea->releases->create_asset('getty', 'p5-www-gitea', 5,
        file => '/path/to/dist.tar.gz', name => 'dist.tar.gz');

    my $asset = $gitea->releases->create_asset('getty', 'p5-www-gitea', 5,
        content => $bytes, name => 'notes.txt');

Uploads a release asset via C<multipart/form-data>. Pass B<either> C<file>
(a path on disk) B<or> C<content> (raw bytes). C<name> sets the asset's display
name (sent as the C<name> query parameter); C<filename> overrides the multipart
part filename (defaulting to C<name> for in-memory content). Returns a
L<WWW::Gitea::Attachment>.

=head2 get_asset

    my $asset = $gitea->releases->get_asset('getty', 'p5-www-gitea', 5, 12);

Fetches a single release asset by its numeric attachment id. Returns a
L<WWW::Gitea::Attachment>.

=head2 edit_asset

    $gitea->releases->edit_asset('getty', 'p5-www-gitea', 5, 12,
        name => 'renamed.tar.gz');

Edits a release asset (only C<name> is editable). Arguments are passed through
as the JSON body. Returns the updated L<WWW::Gitea::Attachment>.

=head2 delete_asset

    $gitea->releases->delete_asset('getty', 'p5-www-gitea', 5, 12);

Deletes a release asset by its numeric attachment id. Returns a true value on
success.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Release>

=item * L<WWW::Gitea::Attachment>

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
