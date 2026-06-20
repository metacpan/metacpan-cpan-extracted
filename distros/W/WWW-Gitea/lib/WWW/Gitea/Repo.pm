package WWW::Gitea::Repo;

# ABSTRACT: Gitea repository entity

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


sub id          { $_[0]->data->{id} }
sub name        { $_[0]->data->{name} }
sub full_name   { $_[0]->data->{full_name} }
sub description { $_[0]->data->{description} }
sub private     { $_[0]->data->{private} }
sub fork        { $_[0]->data->{fork} }
sub html_url    { $_[0]->data->{html_url} }
sub clone_url   { $_[0]->data->{clone_url} }
sub ssh_url     { $_[0]->data->{ssh_url} }
sub default_branch    { $_[0]->data->{default_branch} }
sub stars_count       { $_[0]->data->{stars_count} }
sub forks_count       { $_[0]->data->{forks_count} }
sub open_issues_count { $_[0]->data->{open_issues_count} }

sub owner_login {
    my ($self) = @_;
    my $o = $self->data->{owner};
    return $o ? $o->{login} : undef;
}


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->repos->get($self->owner_login, $self->name);
    $self->data($fresh->data);
    return $self;
}


sub delete {
    my ($self) = @_;
    return $self->_client->repos->delete($self->owner_login, $self->name);
}


sub issues {
    my ($self, %query) = @_;
    return $self->_client->issues->list($self->owner_login, $self->name, %query);
}


sub create_issue {
    my ($self, %args) = @_;
    return $self->_client->issues->create($self->owner_login, $self->name, %args);
}


sub pulls {
    my ($self, %query) = @_;
    return $self->_client->pulls->list($self->owner_login, $self->name, %query);
}


sub labels {
    my ($self) = @_;
    return $self->_client->labels->list($self->owner_login, $self->name);
}


sub milestones {
    my ($self, %query) = @_;
    return $self->_client->milestones->list($self->owner_login, $self->name, %query);
}


sub releases {
    my ($self, %query) = @_;
    return $self->_client->releases->list($self->owner_login, $self->name, %query);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Repo - Gitea repository entity

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $repo = $gitea->repos->get('getty', 'p5-www-gitea');

    print $repo->full_name,   "\n";    # "getty/p5-www-gitea"
    print $repo->clone_url,   "\n";
    print $repo->stars_count, "\n";

    # Convenience delegations scoped to this repo
    my $issues = $repo->issues(state => 'open');
    my $issue  = $repo->create_issue(title => 'Bug');
    my $pulls  = $repo->pulls;

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea repository. Besides
the field accessors it offers convenience methods that delegate to the
client's controllers with this repository's owner and name pre-filled. The
raw decoded data is always available via L</data>.

=head2 data

Raw decoded JSON for the repository. Writable so L</refresh> can update it in
place.

=head2 id

Numeric repository ID.

=head2 name

Repository name (without owner).

=head2 full_name

C<owner/name>.

=head2 description

Repository description.

=head2 private

True if the repository is private.

=head2 fork

True if the repository is a fork.

=head2 html_url

Web URL of the repository.

=head2 clone_url

HTTPS clone URL.

=head2 ssh_url

SSH clone URL.

=head2 default_branch

Name of the default branch.

=head2 stars_count

Number of stars.

=head2 forks_count

Number of forks.

=head2 open_issues_count

Number of open issues.

=head2 owner_login

Login name of the repository owner (from C<< data->{owner}{login} >>).

=head2 refresh

    $repo->refresh;

Re-fetches the repository and updates L</data> in place.

=head2 delete

    $repo->delete;

Deletes this repository.

=head2 issues

    my $issues = $repo->issues(state => 'open');

Lists this repository's issues. Delegates to
L<WWW::Gitea::API::Issues/list>.

=head2 create_issue

    my $issue = $repo->create_issue(title => 'Bug', body => '...');

Creates an issue in this repository. Delegates to
L<WWW::Gitea::API::Issues/create>.

=head2 pulls

    my $pulls = $repo->pulls(state => 'open');

Lists this repository's pull requests. Delegates to
L<WWW::Gitea::API::PullRequests/list>.

=head2 labels

    my $labels = $repo->labels;

Lists this repository's labels. Delegates to
L<WWW::Gitea::API::Labels/list>.

=head2 milestones

    my $milestones = $repo->milestones;

Lists this repository's milestones. Delegates to
L<WWW::Gitea::API::Milestones/list>.

=head2 releases

    my $releases = $repo->releases;

Lists this repository's releases. Delegates to
L<WWW::Gitea::API::Releases/list>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Repos>

=item * L<WWW::Gitea::Issue>, L<WWW::Gitea::PullRequest>

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
