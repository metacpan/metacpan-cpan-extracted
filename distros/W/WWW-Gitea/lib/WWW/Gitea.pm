package WWW::Gitea;

# ABSTRACT: Perl client for the Gitea REST API

use Moo;
use Carp qw(croak);
use WWW::Gitea::API::Misc;
use WWW::Gitea::API::Users;
use WWW::Gitea::API::Repos;
use WWW::Gitea::API::Issues;
use WWW::Gitea::API::PullRequests;
use WWW::Gitea::API::Labels;
use WWW::Gitea::API::Milestones;
use WWW::Gitea::API::Releases;
use WWW::Gitea::API::Orgs;
use namespace::clean;

our $VERSION = '0.003';


has url => (
    is      => 'ro',
    default => sub { $ENV{GITEA_URL} },
);


has token => (
    is      => 'ro',
    default => sub { $ENV{GITEA_TOKEN} },
);


has username => (
    is      => 'ro',
    default => sub { $ENV{GITEA_USERNAME} },
);

has password => (
    is      => 'ro',
    default => sub { $ENV{GITEA_PASSWORD} },
);


has api_url => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $url = $self->url
            or croak 'url required (e.g. https://gitea.example.com)';
        $url =~ s{/+$}{};
        $url =~ s{/api/v1$}{};
        return $url . '/api/v1';
    },
);


with 'WWW::Gitea::Role::HTTP';

has misc => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Misc->new(client => $_[0]) },
);


has users => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Users->new(client => $_[0]) },
);


has repos => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Repos->new(client => $_[0]) },
);


has issues => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Issues->new(client => $_[0]) },
);


has pulls => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::PullRequests->new(client => $_[0]) },
);


has labels => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Labels->new(client => $_[0]) },
);


has milestones => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Milestones->new(client => $_[0]) },
);


has releases => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Releases->new(client => $_[0]) },
);


has orgs => (
    is      => 'lazy',
    builder => sub { WWW::Gitea::API::Orgs->new(client => $_[0]) },
);


sub version {
    my ($self) = @_;
    return $self->misc->version;
}


sub current_user {
    my ($self) = @_;
    return $self->misc->current_user;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea - Perl client for the Gitea REST API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WWW::Gitea;

    my $gitea = WWW::Gitea->new(
        url   => 'https://gitea.example.com',     # instance root, no /api/v1
        token => $ENV{GITEA_TOKEN},               # personal access token
    );

    # Who am I, and which Gitea version is this?
    my $me      = $gitea->current_user;           # WWW::Gitea::User
    my $version = $gitea->version;                 # e.g. "1.22.0"

    # Repositories
    my $repo = $gitea->repos->get('getty', 'p5-www-gitea');
    print $repo->full_name, " ", $repo->stars_count, "\n";

    my $new = $gitea->repos->create(
        name        => 'my-new-repo',
        description => 'created via WWW::Gitea',
        private     => 1,
        auto_init   => 1,
    );

    # Issues
    my $issue = $gitea->issues->create('getty', 'p5-www-gitea',
        title => 'Something is broken',
        body  => 'Steps to reproduce ...',
        labels => [1, 2],
    );
    $issue->add_comment('on it!');
    $issue->close;

    # Pull requests
    my $pr = $gitea->pulls->create('getty', 'p5-www-gitea',
        head  => 'feature-branch',
        base  => 'main',
        title => 'Add the thing',
    );
    $gitea->pulls->merge('getty', 'p5-www-gitea', $pr->number, Do => 'squash');

    # Releases
    $gitea->releases->create('getty', 'p5-www-gitea',
        tag_name => 'v1.0.0',
        name     => 'First release',
        body     => 'Changelog ...',
    );

=head1 DESCRIPTION

L<WWW::Gitea> is a lightweight L<Moo> client for the Gitea REST API
(C<api/v1>). It covers the resources you reach for day to day —
repositories, issues, pull requests, labels, milestones, releases,
organizations and users — and exposes them through resource controllers
hanging off the main client object.

Operation dispatch uses pre-computed operation tables (see
L<WWW::Gitea::Role::OpenAPI>), so there is no OpenAPI spec parsing at runtime.
Each call returns a small entity object wrapping the decoded JSON, with the
raw data always available on C<< $entity->data >>.

Gitea is self-hosted, so unlike a single-vendor SaaS client there is no
built-in base URL — you always pass L</url> (and usually a L</token>).

=head2 url

The Gitea instance root URL, e.g. C<https://gitea.example.com> (B<without>
the C</api/v1> suffix — that is added for you). Defaults to the C<GITEA_URL>
environment variable. A trailing slash or an accidental C</api/v1> suffix is
tolerated.

=head2 token

Personal access token. Sent as C<Authorization: token ...>. Defaults to the
C<GITEA_TOKEN> environment variable. When set, it takes precedence over
L</username> / L</password>.

=head2 username

Username for HTTP Basic auth (used only when no L</token> is set). Defaults to
the C<GITEA_USERNAME> environment variable.

=head2 password

Password (or token) for HTTP Basic auth. Defaults to the C<GITEA_PASSWORD>
environment variable.

=head2 api_url

The fully-qualified C<api/v1> base URL, derived from L</url>. All request
paths are appended to this.

=head2 misc

A L<WWW::Gitea::API::Misc> controller for instance-level endpoints (version,
the authenticated user).

=head2 users

A L<WWW::Gitea::API::Users> controller for looking up and searching users.

=head2 repos

A L<WWW::Gitea::API::Repos> controller for repositories.

=head2 issues

A L<WWW::Gitea::API::Issues> controller for issues and issue comments.

=head2 pulls

A L<WWW::Gitea::API::PullRequests> controller for pull requests.

=head2 labels

A L<WWW::Gitea::API::Labels> controller for repository labels.

=head2 milestones

A L<WWW::Gitea::API::Milestones> controller for repository milestones.

=head2 releases

A L<WWW::Gitea::API::Releases> controller for repository releases.

=head2 orgs

A L<WWW::Gitea::API::Orgs> controller for organizations.

=head2 version

    my $v = $gitea->version;

Returns the Gitea server version string. Shortcut for
C<< $gitea->misc->version >>.

=head2 current_user

    my $me = $gitea->current_user;

Returns the authenticated L<WWW::Gitea::User>. Shortcut for
C<< $gitea->misc->current_user >>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea::Role::HTTP> — transport and authentication

=item * L<WWW::Gitea::Role::OpenAPI> — operationId dispatch

=item * L<WWW::Gitea::API::Repos>, L<WWW::Gitea::API::Issues>,
L<WWW::Gitea::API::PullRequests>, L<WWW::Gitea::API::Labels>,
L<WWW::Gitea::API::Milestones>, L<WWW::Gitea::API::Releases>,
L<WWW::Gitea::API::Orgs>, L<WWW::Gitea::API::Users>,
L<WWW::Gitea::API::Misc>

=item * L<https://docs.gitea.com/api/> — Gitea API documentation

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
