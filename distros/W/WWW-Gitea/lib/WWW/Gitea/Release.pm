package WWW::Gitea::Release;

# ABSTRACT: Gitea release entity

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);


has owner => ( is => 'ro' );
has repo  => ( is => 'ro' );


sub id           { $_[0]->data->{id} }
sub tag_name     { $_[0]->data->{tag_name} }
sub name         { $_[0]->data->{name} }
sub body         { $_[0]->data->{body} }
sub draft        { $_[0]->data->{draft} }
sub prerelease   { $_[0]->data->{prerelease} }
sub html_url     { $_[0]->data->{html_url} }
sub tarball_url  { $_[0]->data->{tarball_url} }
sub zipball_url  { $_[0]->data->{zipball_url} }
sub created_at   { $_[0]->data->{created_at} }
sub published_at { $_[0]->data->{published_at} }
sub author_login { my $a = $_[0]->data->{author}; $a ? $a->{login} : undef }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->releases->get($self->owner, $self->repo, $self->id);
    $self->data($fresh->data);
    return $self;
}


sub edit {
    my ($self, %args) = @_;
    my $fresh = $self->_client->releases->edit(
        $self->owner, $self->repo, $self->id, %args);
    $self->data($fresh->data);
    return $self;
}


sub delete {
    my ($self) = @_;
    return $self->_client->releases->delete($self->owner, $self->repo, $self->id);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Release - Gitea release entity

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $rel = $gitea->releases->get('getty', 'p5-www-gitea', 5);

    print $rel->tag_name, " ", $rel->name, "\n";
    print $rel->html_url, "\n";

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea release. Lifecycle
methods delegate back to the client's L<WWW::Gitea::API::Releases> controller
and need the owning L</owner>/L</repo> (set automatically when the release
comes from a repository-scoped call). The raw decoded data is always available
via L</data>.

=head2 data

Raw decoded JSON for the release.

=head2 owner

Owner of the repository this release belongs to.

=head2 repo

Name of the repository this release belongs to.

=head2 id

Numeric release ID.

=head2 tag_name

The git tag the release points at.

=head2 name

Release title.

=head2 body

Release notes (Markdown).

=head2 draft

True if the release is a draft.

=head2 prerelease

True if the release is a pre-release.

=head2 html_url

Web URL of the release.

=head2 tarball_url

URL of the source tarball.

=head2 zipball_url

URL of the source zip archive.

=head2 created_at

ISO-8601 creation timestamp.

=head2 published_at

ISO-8601 publish timestamp.

=head2 author_login

Login name of the release author.

=head2 refresh

    $rel->refresh;

Re-fetches the release and updates L</data> in place.

=head2 edit

    $rel->edit(draft => \0);

Edits the release and updates L</data> in place.

=head2 delete

    $rel->delete;

Deletes the release.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Releases>

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
