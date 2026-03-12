package WWW::VastAI::Role::OperationMap;
our $VERSION = '0.001';
# ABSTRACT: Central Vast.ai API operation mapping used by WWW::VastAI

use Moo::Role;
use Carp qw(croak);

requires 'base_url';
requires 'base_url_v1';
requires 'run_url';
requires 'get';
requires 'post';
requires 'put';
requires 'delete';

has operation_map => (
    is      => 'lazy',
    builder => '_build_operation_map',
);

sub _build_operation_map {
    return {
        searchOffers            => { method => 'POST',   base => 'v0', path => '/bundles/' },
        listInstances           => { method => 'GET',    base => 'v0', path => '/instances/' },
        getInstance             => { method => 'GET',    base => 'v0', path => '/instances/{id}/' },
        createInstance          => { method => 'PUT',    base => 'v0', path => '/asks/{id}/' },
        manageInstance          => { method => 'PUT',    base => 'v0', path => '/instances/{id}/' },
        deleteInstance          => { method => 'DELETE', base => 'v0', path => '/instances/{id}/' },
        requestInstanceLogs     => { method => 'PUT',    base => 'v0', path => '/instances/request_logs/{id}' },
        listInstanceSSHKeys     => { method => 'GET',    base => 'v0', path => '/instances/{id}/ssh/' },
        attachInstanceSSHKey    => { method => 'POST',   base => 'v0', path => '/instances/{id}/ssh/' },
        detachInstanceSSHKey    => { method => 'DELETE', base => 'v0', path => '/instances/{id}/ssh/{ssh_key_id}/' },
        searchTemplates         => { method => 'GET',    base => 'v0', path => '/template/' },
        createTemplate          => { method => 'POST',   base => 'v0', path => '/template/' },
        updateTemplate          => { method => 'PUT',    base => 'v0', path => '/template/' },
        deleteTemplate          => { method => 'DELETE', base => 'v0', path => '/template/' },
        listVolumes             => { method => 'GET',    base => 'v0', path => '/volumes/' },
        createVolume            => { method => 'PUT',    base => 'v0', path => '/volumes/' },
        deleteVolume            => { method => 'DELETE', base => 'v0', path => '/volumes/' },
        listSSHKeys             => { method => 'GET',    base => 'v0', path => '/ssh/' },
        createSSHKey            => { method => 'POST',   base => 'v0', path => '/ssh/' },
        updateSSHKey            => { method => 'PUT',    base => 'v0', path => '/ssh/{id}/' },
        deleteSSHKey            => { method => 'DELETE', base => 'v0', path => '/ssh/{id}/' },
        listAPIKeys             => { method => 'GET',    base => 'v0', path => '/auth/apikeys/' },
        createAPIKey            => { method => 'POST',   base => 'v0', path => '/auth/apikeys/' },
        deleteAPIKey            => { method => 'DELETE', base => 'v0', path => '/auth/apikeys/{id}/' },
        getCurrentUser          => { method => 'GET',    base => 'v0', path => '/users/current/' },
        listEnvVars             => { method => 'GET',    base => 'v0', path => '/secrets/' },
        createEnvVar            => { method => 'POST',   base => 'v0', path => '/secrets/' },
        updateEnvVar            => { method => 'PUT',    base => 'v0', path => '/secrets/' },
        deleteEnvVar            => { method => 'DELETE', base => 'v0', path => '/secrets/' },
        listInvoices            => { method => 'GET',    base => 'v1', path => '/invoices/' },
        listEndpoints           => { method => 'GET',    base => 'v0', path => '/endptjobs/' },
        createEndpoint          => { method => 'POST',   base => 'v0', path => '/endptjobs/' },
        deleteEndpoint          => { method => 'DELETE', base => 'v0', path => '/endptjobs/{id}/' },
        listWorkergroups        => { method => 'GET',    base => 'v0', path => '/workergroups/' },
        createWorkergroup       => { method => 'POST',   base => 'v0', path => '/workergroups/' },
        updateWorkergroup       => { method => 'PUT',    base => 'v0', path => '/workergroups/{id}/' },
        deleteWorkergroup       => { method => 'DELETE', base => 'v0', path => '/workergroups/{id}/' },
        getEndpointLogs         => { method => 'POST',   base => 'run', path => '/get_endpoint_logs/' },
        getEndpointWorkers      => { method => 'POST',   base => 'run', path => '/get_endpoint_workers/' },
        getWorkergroupLogs      => { method => 'POST',   base => 'run', path => '/get_workergroup_logs/' },
        getWorkergroupWorkers   => { method => 'POST',   base => 'run', path => '/get_workergroup_workers/' },
    };
}

sub _base_for_operation {
    my ($self, $base) = @_;
    return $self->base_url    if $base eq 'v0';
    return $self->base_url_v1 if $base eq 'v1';
    return $self->run_url     if $base eq 'run';
    croak "Unknown Vast.ai API base '$base'";
}

sub _expand_path {
    my ($self, $path, $vars) = @_;

    $vars ||= {};
    $path =~ s/\{([^}]+)\}/
        exists $vars->{$1}
            ? $vars->{$1}
            : croak "Missing path parameter '$1'"
    /ge;

    return $path;
}

sub request_op {
    my ($self, $name, %args) = @_;

    my $op = $self->operation_map->{$name}
        or croak "Unknown Vast.ai operation '$name'";

    my $path = $self->_expand_path($op->{path}, $args{path});
    my %http_opts = (
        base_url => $self->_base_for_operation($op->{base}),
    );

    if ($op->{method} eq 'GET') {
        return $self->get($path, %http_opts, ($args{query} ? (params => $args{query}) : ()));
    }
    if ($op->{method} eq 'POST') {
        return $self->post($path, ($args{body} || {}), %http_opts);
    }
    if ($op->{method} eq 'PUT') {
        return $self->put($path, ($args{body} || {}), %http_opts);
    }
    if ($op->{method} eq 'DELETE') {
        return $self->delete($path, $args{body}, %http_opts);
    }

    croak "Unsupported HTTP method '$op->{method}'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Role::OperationMap - Central Vast.ai API operation mapping used by WWW::VastAI

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This role keeps the Vast.ai endpoint definitions in one place. It follows the
same broad idea as an OpenAPI-backed client, but uses a lightweight static
operation map instead of loading a full OpenAPI schema at runtime.

=head1 METHODS

=head2 request_op

    my $data = $client->request_op(
        'getInstance',
        path => { id => 12345 },
    );

Dispatches a named API operation using the configured HTTP role. Operations can
target the standard C</api/v0> base, C</api/v1>, or the C<run.vast.ai> service.

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
