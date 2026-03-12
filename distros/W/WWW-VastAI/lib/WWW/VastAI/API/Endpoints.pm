package WWW::VastAI::API::Endpoints;
our $VERSION = '0.001';
# ABSTRACT: Serverless endpoint management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Endpoint;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Endpoint->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listEndpoints');
    my $endpoints = ref $result eq 'HASH' ? ($result->{endpoints} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$endpoints} ];
}

sub create {
    my ($self, %params) = @_;
    croak "endpoint_name required" unless $params{endpoint_name};
    croak "min_load required"      unless exists $params{min_load};
    croak "target_util required"   unless exists $params{target_util};

    my $result = $self->client->request_op('createEndpoint', body => \%params);
    my $endpoint = ref $result eq 'HASH' ? ($result->{endpoint} || $result) : $result;
    return $self->_wrap($endpoint);
}

sub delete {
    my ($self, $id) = @_;
    croak "endpoint id required" unless defined $id;
    return $self->client->request_op('deleteEndpoint', path => { id => $id });
}

sub logs {
    my ($self, $endpoint_name, %params) = @_;
    croak "endpoint_name required" unless $endpoint_name;
    my %body = ( endpoint_name => $endpoint_name, %params );
    return $self->client->request_op('getEndpointLogs', body => \%body);
}

sub workers {
    my ($self, $endpoint_id) = @_;
    croak "endpoint id required" unless defined $endpoint_id;
    return $self->client->request_op('getEndpointWorkers', body => { endpoint_id => $endpoint_id });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Endpoints - Serverless endpoint management for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Provides access to Vast.ai serverless endpoint management plus helper calls for
endpoint workers and logs.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::Endpoint> objects.

=head2 create

Creates a new endpoint and returns it as a L<WWW::VastAI::Endpoint> object.

=head2 delete

Deletes the endpoint identified by C<$id>.

=head2 workers

Fetches worker information for a serverless endpoint.

=head2 logs

Fetches logs for a serverless endpoint by endpoint name.

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
