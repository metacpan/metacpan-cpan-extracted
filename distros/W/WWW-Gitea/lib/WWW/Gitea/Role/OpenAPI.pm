package WWW::Gitea::Role::OpenAPI;

# ABSTRACT: operationId-based dispatch against a cached operation table

use Moo::Role;
use Carp qw(croak);
use Log::Any qw($log);


requires 'client';
requires 'openapi_operations';

sub get_operation {
    my ($self, $operation_id) = @_;
    my $op = $self->openapi_operations->{$operation_id}
        or croak ref($self) . ": unknown operationId '$operation_id'";
    return $op;
}


sub _resolve_path {
    my ($self, $path, $params) = @_;
    $params ||= {};
    $path =~ s!\{([^}]+)\}!
        defined $params->{$1}
            ? $params->{$1}
            : croak "missing path parameter '$1' for $path"
    !ge;
    return $path;
}

sub call_operation {
    my ($self, $operation_id, %args) = @_;
    my $op = $self->get_operation($operation_id);
    my $path = $self->_resolve_path($op->{path}, $args{path});
    $log->debugf('Gitea op %s -> %s %s', $operation_id, $op->{method}, $path);
    return $self->client->request(
        $op->{method},
        $path,
        (defined $args{body}   ? (body   => $args{body})   : ()),
        (defined $args{query}  ? (query  => $args{query})  : ()),
        (defined $args{upload} ? (upload => $args{upload}) : ()),
        (defined $op->{content_type}
            ? (content_type => $op->{content_type}) : ()),
    );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Role::OpenAPI - operationId-based dispatch against a cached operation table

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    package WWW::Gitea::API::Repos;
    use Moo;

    has client => ( is => 'ro', required => 1, weak_ref => 1 );

    has openapi_operations => (
        is      => 'lazy',
        builder => sub {
            return {
                'repos.get'    => { method => 'GET',    path => '/repos/{owner}/{repo}' },
                'repos.delete' => { method => 'DELETE', path => '/repos/{owner}/{repo}' },
                # ...
            };
        },
    );

    with 'WWW::Gitea::Role::OpenAPI';

    sub get {
        my ($self, $owner, $repo) = @_;
        return $self->call_operation('repos.get',
            path => { owner => $owner, repo => $repo },
        );
    }

=head1 DESCRIPTION

Role for API controllers that dispatch by C<operationId>. The consumer ships a
pre-computed operation table via L</openapi_operations>, avoiding any
YAML/JSON spec parsing at runtime. Modelled on L<WWW::PayPal::Role::OpenAPI>
(itself inspired by L<Langertha::Role::OpenAPI>): no L<OpenAPI::Modern>, no
spec loading, just a cached lookup table.

Path parameters in curly braces (C<{owner}>, C<{repo}>, C<{index}>, C<{id}>,
...) are substituted from the C<path> argument to L</call_operation>.

Consumers must provide:

=over 4

=item * C<client> — a L<WWW::Gitea> instance (used for HTTP).

=item * C<openapi_operations> — HashRef mapping C<operationId> to
C<{ method, path, content_type? }>.

=back

=head2 get_operation

    my $op = $self->get_operation('repos.get');

Returns the operation HashRef (C<method>, C<path>, optional C<content_type>)
for the given C<operationId>.

=head2 call_operation

    my $data = $self->call_operation('repos.get',
        path => { owner => 'getty', repo => 'p5-www-gitea' },
    );

Dispatches an operation by C<operationId>, substitutes path parameters, and
returns the decoded JSON response.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Role::HTTP>

=item * L<https://docs.gitea.com/api/>

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
