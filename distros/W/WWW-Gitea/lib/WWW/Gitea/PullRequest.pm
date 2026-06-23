package WWW::Gitea::PullRequest;

# ABSTRACT: Gitea pull request entity

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


sub _base_repo { $_[0]->data->{base} ? $_[0]->data->{base}{repo} : undef }

sub _owner {
    my ($self) = @_;
    return $self->owner if defined $self->owner;
    my $r = $self->_base_repo or return undef;
    return $r->{owner} ? $r->{owner}{login} : undef;
}

sub _repo {
    my ($self) = @_;
    return $self->repo if defined $self->repo;
    my $r = $self->_base_repo or return undef;
    return $r->{name};
}

sub id          { $_[0]->data->{id} }
sub number      { $_[0]->data->{number} }
sub title       { $_[0]->data->{title} }
sub body        { $_[0]->data->{body} }
sub state       { $_[0]->data->{state} }
sub merged      { $_[0]->data->{merged} }
sub mergeable   { $_[0]->data->{mergeable} }
sub html_url    { $_[0]->data->{html_url} }
sub created_at  { $_[0]->data->{created_at} }
sub updated_at  { $_[0]->data->{updated_at} }
sub user_login  { my $u = $_[0]->data->{user}; $u ? $u->{login} : undef }
sub head_branch { my $h = $_[0]->data->{head}; $h ? $h->{ref} : undef }
sub base_branch { my $b = $_[0]->data->{base}; $b ? $b->{ref} : undef }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->pulls->get($self->_owner, $self->_repo, $self->number);
    $self->data($fresh->data);
    return $self;
}


sub edit {
    my ($self, %args) = @_;
    my $fresh = $self->_client->pulls->edit(
        $self->_owner, $self->_repo, $self->number, %args);
    $self->data($fresh->data);
    return $self;
}


sub merge {
    my ($self, %args) = @_;
    return $self->_client->pulls->merge(
        $self->_owner, $self->_repo, $self->number, %args);
}


sub is_merged {
    my ($self) = @_;
    return $self->_client->pulls->is_merged(
        $self->_owner, $self->_repo, $self->number);
}


sub close {
    my ($self) = @_;
    return $self->edit(state => 'closed');
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::PullRequest - Gitea pull request entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $pr = $gitea->pulls->get('getty', 'p5-www-gitea', 12);

    print $pr->number, " ", $pr->title, "\n";
    print $pr->head_branch, " -> ", $pr->base_branch, "\n";

    $pr->merge(Do => 'squash') unless $pr->is_merged;

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea pull request.
Lifecycle methods delegate back to the client's
L<WWW::Gitea::API::PullRequests> controller. The owning repository is taken
from the explicit L</owner>/L</repo> passed at construction, falling back to
the C<base.repo> block embedded in the pull-request JSON. The raw decoded data
is always available via L</data>.

=head2 data

Raw decoded JSON for the pull request. Writable so L</refresh> and L</edit>
can update it in place.

=head2 owner

Owner of the repository this pull request belongs to. Optional; falls back to
the embedded C<< data->{base}{repo}{owner}{login} >>.

=head2 repo

Name of the repository this pull request belongs to. Optional; falls back to
the embedded C<< data->{base}{repo}{name} >>.

=head2 id

Global numeric pull-request ID.

=head2 number

Per-repository pull-request index (shared with the issue number space).

=head2 title

Pull-request title.

=head2 body

Pull-request body (Markdown).

=head2 state

C<open> or C<closed>.

=head2 merged

True if the pull request has been merged (from the entity JSON).

=head2 mergeable

True if Gitea considers the pull request mergeable.

=head2 html_url

Web URL of the pull request.

=head2 created_at

ISO-8601 creation timestamp.

=head2 updated_at

ISO-8601 last-update timestamp.

=head2 user_login

Login name of the pull request's author.

=head2 head_branch

The source (head) branch name.

=head2 base_branch

The target (base) branch name.

=head2 refresh

    $pr->refresh;

Re-fetches the pull request and updates L</data> in place.

=head2 edit

    $pr->edit(title => 'New title');

Edits the pull request and updates L</data> in place.

=head2 merge

    $pr->merge(Do => 'squash');

Merges the pull request. Delegates to L<WWW::Gitea::API::PullRequests/merge>.

=head2 is_merged

    if ($pr->is_merged) { ... }

Checks via the API whether the pull request has been merged. Delegates to
L<WWW::Gitea::API::PullRequests/is_merged>.

=head2 close

    $pr->close;

Closes the pull request (shortcut for C<< $pr->edit(state => 'closed') >>).

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::PullRequests>

=item * L<WWW::Gitea::Issue>

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
