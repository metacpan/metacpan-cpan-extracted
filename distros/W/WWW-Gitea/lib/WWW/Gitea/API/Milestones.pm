package WWW::Gitea::API::Milestones;

# ABSTRACT: Gitea repository milestones API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Milestone;
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
            'milestones.list'   => { method => 'GET',    path => '/repos/{owner}/{repo}/milestones' },
            'milestones.create' => { method => 'POST',   path => '/repos/{owner}/{repo}/milestones' },
            'milestones.get'    => { method => 'GET',    path => '/repos/{owner}/{repo}/milestones/{id}' },
            'milestones.edit'   => { method => 'PATCH',  path => '/repos/{owner}/{repo}/milestones/{id}' },
            'milestones.delete' => { method => 'DELETE', path => '/repos/{owner}/{repo}/milestones/{id}' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data, $owner, $repo) = @_;
    return WWW::Gitea::Milestone->new(
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
    my $data = $self->call_operation('milestones.list',
        path => { owner => $owner, repo => $repo }, query => \%query);
    return [ map { $self->_wrap($_, $owner, $repo) } @{ $data || [] } ];
}


sub create {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'title required' unless defined $args{title};
    my $data = $self->call_operation('milestones.create',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub get {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('milestones.get',
        path => { owner => $owner, repo => $repo, id => $id });
    return $self->_wrap($data, $owner, $repo);
}


sub edit {
    my ($self, $owner, $repo, $id, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('milestones.edit',
        path => { owner => $owner, repo => $repo, id => $id }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub delete {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    return $self->call_operation('milestones.delete',
        path => { owner => $owner, repo => $repo, id => $id });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Milestones - Gitea repository milestones API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $milestones = $gitea->milestones->list('getty', 'p5-www-gitea');

    my $ms = $gitea->milestones->create('getty', 'p5-www-gitea',
        title => 'v1.0', description => 'First stable release',
    );

=head1 DESCRIPTION

Controller for the Gitea repository milestones API. Reached via
C<< $gitea->milestones >>. Milestones are addressed by their numeric C<id>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 list

    my $milestones = $gitea->milestones->list('getty', 'p5-www-gitea',
        state => 'open');

Lists milestones. Accepts the Gitea query parameters (C<state> —
C<open>/C<closed>/C<all>, C<name>, C<page>, C<limit>). Returns an ArrayRef of
L<WWW::Gitea::Milestone>.

=head2 create

    my $ms = $gitea->milestones->create('getty', 'p5-www-gitea',
        title => 'v1.0', description => '...', due_on => '2026-12-31T00:00:00Z');

Creates a milestone. C<title> is required. Returns a
L<WWW::Gitea::Milestone>.

=head2 get

    my $ms = $gitea->milestones->get('getty', 'p5-www-gitea', 1);

Fetches a milestone by id. Returns a L<WWW::Gitea::Milestone>.

=head2 edit

    $gitea->milestones->edit('getty', 'p5-www-gitea', 1, state => 'closed');

Edits a milestone (C<title>, C<description>, C<state>, C<due_on>). Returns the
updated L<WWW::Gitea::Milestone>.

=head2 delete

    $gitea->milestones->delete('getty', 'p5-www-gitea', 1);

Deletes a milestone. Returns a true value on success.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Milestone>

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
