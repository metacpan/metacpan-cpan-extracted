package WWW::VastAI::API::Workergroups;
our $VERSION = '0.001';
# ABSTRACT: Workergroup management for Vast.ai serverless

use Moo;
use Carp qw(croak);
use WWW::VastAI::Workergroup;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Workergroup->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listWorkergroups');
    my $groups = ref $result eq 'HASH' ? ($result->{workergroups} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$groups} ];
}

sub create {
    my ($self, %params) = @_;
    croak "template_hash required" unless $params{template_hash};
    croak "endpoint_name required" unless $params{endpoint_name};

    my $result = $self->client->request_op('createWorkergroup', body => \%params);
    my $group = ref $result eq 'HASH' ? ($result->{workergroup} || $result) : $result;
    return $self->_wrap($group);
}

sub update {
    my ($self, $id, %params) = @_;
    croak "workergroup id required" unless defined $id;

    my $result = $self->client->request_op(
        'updateWorkergroup',
        path => { id => $id },
        body => \%params,
    );

    my $group = ref $result eq 'HASH' ? ($result->{workergroup} || $result) : $result;
    return $self->_wrap($group);
}

sub delete {
    my ($self, $id) = @_;
    croak "workergroup id required" unless defined $id;
    return $self->client->request_op('deleteWorkergroup', path => { id => $id });
}

sub logs {
    my ($self, $id, %params) = @_;
    croak "workergroup id required" unless defined $id;
    my %body = ( workergroup_id => $id, %params );
    return $self->client->request_op('getWorkergroupLogs', body => \%body);
}

sub workers {
    my ($self, $id) = @_;
    croak "workergroup id required" unless defined $id;
    return $self->client->request_op('getWorkergroupWorkers', body => { workergroup_id => $id });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Workergroups - Workergroup management for Vast.ai serverless

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Wraps the Vast.ai workergroup APIs and the associated run-service calls for
worker and log inspection.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::Workergroup> objects.

=head2 create

Creates a workergroup and returns it as a L<WWW::VastAI::Workergroup> object.

=head2 update

Updates the workergroup identified by C<$id>.

=head2 delete

Deletes the workergroup identified by C<$id>.

=head2 workers

Returns worker information for a workergroup.

=head2 logs

Returns workergroup logs.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
