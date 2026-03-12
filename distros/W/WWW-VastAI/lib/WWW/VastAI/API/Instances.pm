package WWW::VastAI::API::Instances;
our $VERSION = '0.001';
# ABSTRACT: Instance lifecycle and helper methods for Vast.ai

use Moo;
use Carp qw(croak);
use LWP::UserAgent;
use WWW::VastAI::Instance;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Instance->new(
        client => $self->client,
        data   => $data,
    );
}

sub _extract_instance {
    my ($self, $result) = @_;

    return $result unless ref $result eq 'HASH';
    return $result->{instance} if ref $result->{instance} eq 'HASH';
    return $result->{instances} if ref $result->{instances} eq 'HASH';
    return $result->{instances}[0] if ref $result->{instances} eq 'ARRAY';
    return $result->{new_contract} if ref $result->{new_contract} eq 'HASH';

    return;
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listInstances');
    my $instances = ref $result eq 'HASH' ? ($result->{instances} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$instances} ];
}

sub get {
    my ($self, $id) = @_;
    croak "instance id required" unless defined $id;

    my $result = $self->client->request_op('getInstance', path => { id => $id });
    my $instance = $self->_extract_instance($result) || $result;
    return $self->_wrap($instance);
}

sub create {
    my ($self, $offer_id, %params) = @_;
    croak "offer_id required" unless defined $offer_id;
    croak "image or template_hash_id required"
        unless $params{image} || $params{template_hash_id};

    my $result = $self->client->request_op(
        'createInstance',
        path => { id => $offer_id },
        body => \%params,
    );

    my $instance = $self->_extract_instance($result);
    return $self->_wrap($instance) if $instance;

    my $new_id = ref $result eq 'HASH' ? $result->{new_contract} : $result;
    return $self->get($new_id) if defined $new_id && !ref $new_id;

    croak 'create instance did not return an instance payload or contract id';
}

sub update {
    my ($self, $id, %params) = @_;
    croak "instance id required" unless defined $id;

    my $result = $self->client->request_op(
        'manageInstance',
        path => { id => $id },
        body => \%params,
    );

    my $instance = $self->_extract_instance($result);
    return $self->_wrap($instance) if $instance;

    return $self->get($id);
}

sub start {
    my ($self, $id) = @_;
    return $self->update($id, state => 'running');
}

sub stop {
    my ($self, $id) = @_;
    return $self->update($id, state => 'stopped');
}

sub label {
    my ($self, $id, $label) = @_;
    return $self->update($id, label => $label);
}

sub delete {
    my ($self, $id) = @_;
    croak "instance id required" unless defined $id;
    return $self->client->request_op('deleteInstance', path => { id => $id });
}

sub logs {
    my ($self, $id, %params) = @_;
    croak "instance id required" unless defined $id;

    my %body = (
        tail       => 100,
        timestamps => 0,
        %params,
    );

    my $result = $self->client->request_op(
        'requestInstanceLogs',
        path => { id => $id },
        body => \%body,
    );

    if (ref $result eq 'HASH' && $result->{result_url}) {
        my $ua = LWP::UserAgent->new(
            agent   => 'WWW-VastAI',
            timeout => 30,
        );
        my $response = $ua->get($result->{result_url});
        croak 'Failed to fetch instance logs: ' . $response->status_line
            unless $response->is_success;
        return $response->decoded_content;
    }

    return ref $result eq 'HASH' ? ($result->{logs} || $result->{result} || $result) : $result;
}

sub ssh_keys {
    my ($self, $id) = @_;
    croak "instance id required" unless defined $id;
    my $result = $self->client->request_op('listInstanceSSHKeys', path => { id => $id });
    return ref $result eq 'HASH' ? ($result->{ssh_keys} || $result->{results} || []) : ($result || []);
}

sub attach_ssh_key {
    my ($self, $id, $ssh_key) = @_;
    croak "instance id required" unless defined $id;
    croak "ssh key required" unless defined $ssh_key;

    return $self->client->request_op(
        'attachInstanceSSHKey',
        path => { id => $id },
        body => { ssh_key => $ssh_key },
    );
}

sub detach_ssh_key {
    my ($self, $id, $ssh_key_id) = @_;
    croak "instance id required" unless defined $id;
    croak "ssh key id required" unless defined $ssh_key_id;

    return $self->client->request_op(
        'detachInstanceSSHKey',
        path => {
            id         => $id,
            ssh_key_id => $ssh_key_id,
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Instances - Instance lifecycle and helper methods for Vast.ai

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $instances = $vast->instances->list;
    my $instance  = $vast->instances->get($id);

    my $created = $vast->instances->create(
        $offer_id,
        image   => 'nginx:alpine',
        disk    => 16,
        runtype => 'args',
    );

    $vast->instances->stop($created->id);
    $vast->instances->delete($created->id);

=head1 DESCRIPTION

This module wraps the main Vast.ai instance APIs. It handles both the
documented response style where create/update endpoints only return success or
an ID, and the richer response style used in mocks or compatibility layers.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::Instance> objects.

=head2 get

Fetches a single instance by ID.

=head2 create

    my $instance = $vast->instances->create($offer_id, %params);

Creates an instance from a marketplace ask/offer ID. Requires either
C<image> or C<template_hash_id>.

=head2 update

    my $instance = $vast->instances->update($id, %params);

Sends an instance update and returns a refreshed object.

=head2 start

Starts the instance identified by C<$id>.

=head2 stop

Stops the instance identified by C<$id>.

=head2 label

Updates the instance label via C<update>.

=head2 delete

Deletes an instance.

=head2 logs

Requests instance logs. If Vast.ai returns a C<result_url>, this method fetches
that URL and returns the decoded log content.

=head2 ssh_keys

Returns the SSH keys attached to the instance.

=head2 attach_ssh_key

Attaches a public SSH key to the instance.

=head2 detach_ssh_key

Detaches an SSH key from the instance.

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
