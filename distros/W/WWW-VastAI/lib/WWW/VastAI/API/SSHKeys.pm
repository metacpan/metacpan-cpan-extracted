package WWW::VastAI::API::SSHKeys;
our $VERSION = '0.001';
# ABSTRACT: Account SSH key management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::SSHKey;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::SSHKey->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listSSHKeys');
    my $keys = ref $result eq 'HASH' ? ($result->{ssh_keys} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$keys} ];
}

sub create {
    my ($self, $ssh_key) = @_;
    croak "ssh key required" unless $ssh_key;
    my $result = $self->client->request_op('createSSHKey', body => { ssh_key => $ssh_key });
    my $key = ref $result eq 'HASH' ? ($result->{ssh_key} || $result) : $result;
    return $self->_wrap($key);
}

sub update {
    my ($self, $id, $ssh_key) = @_;
    croak "ssh key id required" unless defined $id;
    croak "ssh key required" unless $ssh_key;

    my $result = $self->client->request_op(
        'updateSSHKey',
        path => { id => $id },
        body => { ssh_key => $ssh_key },
    );

    my $key = ref $result eq 'HASH' ? ($result->{ssh_key} || $result) : $result;
    return $self->_wrap($key);
}

sub delete {
    my ($self, $id) = @_;
    croak "ssh key id required" unless defined $id;
    return $self->client->request_op('deleteSSHKey', path => { id => $id });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::SSHKeys - Account SSH key management for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Manages the SSH keys stored on the Vast.ai account and returns
L<WWW::VastAI::SSHKey> objects.

=head1 METHODS

=head2 list

Returns an arrayref of L<WWW::VastAI::SSHKey> objects.

=head2 create

Creates a new SSH key and returns it as a L<WWW::VastAI::SSHKey> object.

=head2 update

Updates an existing SSH key and returns the refreshed object.

=head2 delete

Deletes the SSH key identified by C<$id>.

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
