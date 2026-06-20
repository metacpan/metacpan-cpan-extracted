package WWW::Gitea::API::Orgs;

# ABSTRACT: Gitea organizations API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Org;
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
            'orgs.get'          => { method => 'GET',    path => '/orgs/{org}' },
            'orgs.create'       => { method => 'POST',   path => '/orgs' },
            'orgs.edit'         => { method => 'PATCH',  path => '/orgs/{org}' },
            'orgs.delete'       => { method => 'DELETE', path => '/orgs/{org}' },
            'orgs.list_repos'   => { method => 'GET',    path => '/orgs/{org}/repos' },
            'orgs.list_current' => { method => 'GET',    path => '/user/orgs' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Gitea::Org->new(client => $self->client, data => $data);
}

sub get {
    my ($self, $org) = @_;
    croak 'org required' unless defined $org;
    my $data = $self->call_operation('orgs.get', path => { org => $org });
    return $self->_wrap($data);
}


sub create {
    my ($self, %args) = @_;
    croak 'username required' unless defined $args{username};
    my $data = $self->call_operation('orgs.create', body => \%args);
    return $self->_wrap($data);
}


sub edit {
    my ($self, $org, %args) = @_;
    croak 'org required' unless defined $org;
    my $data = $self->call_operation('orgs.edit',
        path => { org => $org }, body => \%args);
    return $self->_wrap($data);
}


sub delete {
    my ($self, $org) = @_;
    croak 'org required' unless defined $org;
    return $self->call_operation('orgs.delete', path => { org => $org });
}


sub repos {
    my ($self, $org, %query) = @_;
    croak 'org required' unless defined $org;
    my $data = $self->call_operation('orgs.list_repos',
        path => { org => $org }, query => \%query);
    return [ map {
        WWW::Gitea::Repo->new(client => $self->client, data => $_)
    } @{ $data || [] } ];
}


sub list {
    my ($self, %query) = @_;
    my $data = $self->call_operation('orgs.list_current', query => \%query);
    return [ map { $self->_wrap($_) } @{ $data || [] } ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Orgs - Gitea organizations API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $org   = $gitea->orgs->get('perl-modules');
    my $repos = $gitea->orgs->repos('perl-modules');
    my $mine  = $gitea->orgs->list;          # authenticated user's orgs

=head1 DESCRIPTION

Controller for the Gitea organizations API. Reached via C<< $gitea->orgs >>.
Organizations are addressed by their C<org> name.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 get

    my $org = $gitea->orgs->get('perl-modules');

Fetches an organization by name. Returns a L<WWW::Gitea::Org>.

=head2 create

    my $org = $gitea->orgs->create(
        username => 'my-org', full_name => 'My Organization',
        visibility => 'public',
    );

Creates an organization. C<username> (the org name) is required; other
arguments are passed through as the JSON body. Returns a L<WWW::Gitea::Org>.

=head2 edit

    $gitea->orgs->edit('my-org', description => 'Now with more Perl');

Edits an organization. Arguments are passed through as the JSON body. Returns
the updated L<WWW::Gitea::Org>.

=head2 delete

    $gitea->orgs->delete('my-org');

Deletes an organization. Returns a true value on success.

=head2 repos

    my $repos = $gitea->orgs->repos('perl-modules');

Lists an organization's repositories. Accepts pagination query parameters
(C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Repo>.

=head2 list

    my $orgs = $gitea->orgs->list;

Lists the organizations the authenticated user belongs to
(C<GET /user/orgs>). Returns an ArrayRef of L<WWW::Gitea::Org>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Org>

=item * L<WWW::Gitea::API::Repos>

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
