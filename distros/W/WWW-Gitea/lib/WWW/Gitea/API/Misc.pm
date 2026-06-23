package WWW::Gitea::API::Misc;

# ABSTRACT: Instance-level Gitea endpoints (version, current user)

use Moo;
use WWW::Gitea::User;
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
            'misc.version'  => { method => 'GET', path => '/version' },
            'user.current'  => { method => 'GET', path => '/user' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub version {
    my ($self) = @_;
    my $data = $self->call_operation('misc.version');
    return $data->{version};
}


sub current_user {
    my ($self) = @_;
    my $data = $self->call_operation('user.current');
    return WWW::Gitea::User->new(client => $self->client, data => $data);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Misc - Instance-level Gitea endpoints (version, current user)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $version = $gitea->misc->version;          # "1.22.0"
    my $me      = $gitea->misc->current_user;     # WWW::Gitea::User

=head1 DESCRIPTION

Controller for instance-level Gitea endpoints that are not tied to a specific
repository or organization. Reached via C<< $gitea->misc >>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 version

    my $v = $gitea->misc->version;

Returns the Gitea server version string.

=head2 current_user

    my $me = $gitea->misc->current_user;

Returns the authenticated user as a L<WWW::Gitea::User>.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::User>

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
