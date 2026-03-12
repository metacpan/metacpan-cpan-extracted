package WWW::VastAI::API::EnvVars;
our $VERSION = '0.001';
# ABSTRACT: Environment variable and secret management for Vast.ai

use Moo;
use Carp qw(croak);
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listEnvVars');
    return ref $result eq 'HASH' ? ($result->{secrets} || $result->{results} || $result) : $result;
}

sub create {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "value required" unless exists $params{value};
    return $self->client->request_op('createEnvVar', body => \%params);
}

sub update {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "value required" unless exists $params{value};
    return $self->client->request_op('updateEnvVar', body => \%params);
}

sub delete {
    my ($self, $name) = @_;
    croak "name required" unless defined $name;
    return $self->client->request_op('deleteEnvVar', body => { name => $name });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::EnvVars - Environment variable and secret management for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Wraps the Vast.ai secrets/environment-variable endpoints.

=head1 METHODS

=head2 list

Returns the current env-var/secrets structure from the API.

=head2 create

Creates a new environment variable or secret.

=head2 update

Updates an existing environment variable or secret.

=head2 delete

Deletes the named environment variable or secret.

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
