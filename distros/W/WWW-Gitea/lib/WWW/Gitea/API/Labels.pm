package WWW::Gitea::API::Labels;

# ABSTRACT: Gitea repository labels API

use Moo;
use Carp qw(croak);
use WWW::Gitea::Label;
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
            'labels.list'   => { method => 'GET',    path => '/repos/{owner}/{repo}/labels' },
            'labels.create' => { method => 'POST',   path => '/repos/{owner}/{repo}/labels' },
            'labels.get'    => { method => 'GET',    path => '/repos/{owner}/{repo}/labels/{id}' },
            'labels.edit'   => { method => 'PATCH',  path => '/repos/{owner}/{repo}/labels/{id}' },
            'labels.delete' => { method => 'DELETE', path => '/repos/{owner}/{repo}/labels/{id}' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data, $owner, $repo) = @_;
    return WWW::Gitea::Label->new(
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
    my $data = $self->call_operation('labels.list',
        path => { owner => $owner, repo => $repo }, query => \%query);
    return [ map { $self->_wrap($_, $owner, $repo) } @{ $data || [] } ];
}


sub create {
    my ($self, $owner, $repo, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'name required'  unless defined $args{name};
    croak 'color required' unless defined $args{color};
    my $data = $self->call_operation('labels.create',
        path => { owner => $owner, repo => $repo }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub get {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('labels.get',
        path => { owner => $owner, repo => $repo, id => $id });
    return $self->_wrap($data, $owner, $repo);
}


sub edit {
    my ($self, $owner, $repo, $id, %args) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    my $data = $self->call_operation('labels.edit',
        path => { owner => $owner, repo => $repo, id => $id }, body => \%args);
    return $self->_wrap($data, $owner, $repo);
}


sub delete {
    my ($self, $owner, $repo, $id) = @_;
    croak 'owner required' unless defined $owner;
    croak 'repo required'  unless defined $repo;
    croak 'id required'    unless defined $id;
    return $self->call_operation('labels.delete',
        path => { owner => $owner, repo => $repo, id => $id });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Labels - Gitea repository labels API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $labels = $gitea->labels->list('getty', 'p5-www-gitea');

    my $label = $gitea->labels->create('getty', 'p5-www-gitea',
        name => 'bug', color => 'ee0701', description => 'Something broke',
    );

=head1 DESCRIPTION

Controller for the Gitea repository labels API. Reached via
C<< $gitea->labels >>. Labels are addressed by their numeric C<id>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 list

    my $labels = $gitea->labels->list('getty', 'p5-www-gitea');
    my $page2  = $gitea->labels->list('getty', 'p5-www-gitea', page => 2, limit => 50);

Lists the labels of a repository. Accepts the Gitea pagination query parameters
(C<page>, C<limit>). Returns an ArrayRef of L<WWW::Gitea::Label>.

=head2 create

    my $label = $gitea->labels->create('getty', 'p5-www-gitea',
        name => 'bug', color => 'ee0701', description => '...');

Creates a label. C<name> and C<color> (a 6-hex-digit RGB string) are
required. Returns a L<WWW::Gitea::Label>.

=head2 get

    my $label = $gitea->labels->get('getty', 'p5-www-gitea', 3);

Fetches a label by id. Returns a L<WWW::Gitea::Label>.

=head2 edit

    $gitea->labels->edit('getty', 'p5-www-gitea', 3, color => '00ff00');

Edits a label (C<name>, C<color>, C<description>). Returns the updated
L<WWW::Gitea::Label>.

=head2 delete

    $gitea->labels->delete('getty', 'p5-www-gitea', 3);

Deletes a label. Returns a true value on success.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Label>

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
