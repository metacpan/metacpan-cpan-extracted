package WWW::Hetzner::Cloud::API::SSHKeys;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud SSH Keys API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Cloud::SSHKey;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Cloud::SSHKey->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_) } @$list ];
}


sub list {
    my ($self, %params) = @_;

    my $result = $self->client->get('/ssh_keys', params => \%params);
    return $self->_wrap_list($result->{ssh_keys} // []);
}


sub get {
    my ($self, $id) = @_;
    croak "SSH Key ID required" unless $id;

    my $result = $self->client->get("/ssh_keys/$id");
    return $self->_wrap($result->{ssh_key});
}


sub get_by_name {
    my ($self, $name) = @_;
    croak "Name required" unless $name;

    my $keys = $self->list(name => $name);
    return $keys->[0];
}


sub create {
    my ($self, %params) = @_;

    croak "name required" unless $params{name};
    croak "public_key required" unless $params{public_key};

    my $body = {
        name       => $params{name},
        public_key => $params{public_key},
    };

    $body->{labels} = $params{labels} if $params{labels};

    my $result = $self->client->post('/ssh_keys', $body);
    return $self->_wrap($result->{ssh_key});
}


sub update {
    my ($self, $id, %params) = @_;
    croak "SSH Key ID required" unless $id;

    my $body = {};
    $body->{name}   = $params{name}   if exists $params{name};
    $body->{labels} = $params{labels} if exists $params{labels};

    my $result = $self->client->put("/ssh_keys/$id", $body);
    return $self->_wrap($result->{ssh_key});
}


sub delete {
    my ($self, $id) = @_;
    croak "SSH Key ID required" unless $id;

    return $self->client->delete("/ssh_keys/$id");
}


sub ensure {
    my ($self, $name, $public_key) = @_;
    croak "name required" unless $name;
    croak "public_key required" unless $public_key;

    # Check if exists
    my $existing = $self->get_by_name($name);

    if ($existing) {
        # Check if key matches
        my $existing_key = $existing->public_key;
        $existing_key =~ s/\s+$//;
        my $new_key = $public_key;
        $new_key =~ s/\s+$//;

        if ($existing_key ne $new_key) {
            # Delete and recreate
            $self->delete($existing->id);
            return $self->create(name => $name, public_key => $public_key);
        }
        return $existing;
    }

    return $self->create(name => $name, public_key => $public_key);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::API::SSHKeys - Hetzner Cloud SSH Keys API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_API_TOKEN});

    # List all SSH keys
    my $keys = $cloud->ssh_keys->list;

    # Create a new key
    my $key = $cloud->ssh_keys->create(
        name       => 'my-key',
        public_key => 'ssh-ed25519 AAAA...',
    );

    # Key is a WWW::Hetzner::Cloud::SSHKey object
    print $key->fingerprint, "\n";

    # Update key
    $key->name('renamed-key');
    $key->update;

    # Delete key
    $key->delete;

=head1 DESCRIPTION

This module provides the API for managing Hetzner Cloud SSH keys.
All methods return L<WWW::Hetzner::Cloud::SSHKey> objects.

=head2 list

    my $keys = $cloud->ssh_keys->list;

Returns an arrayref of L<WWW::Hetzner::Cloud::SSHKey> objects.

=head2 get

    my $key = $cloud->ssh_keys->get($id);

Returns a L<WWW::Hetzner::Cloud::SSHKey> object.

=head2 get_by_name

    my $key = $cloud->ssh_keys->get_by_name('my-key');

Returns a L<WWW::Hetzner::Cloud::SSHKey> object. Returns undef if not found.

=head2 create

    my $key = $cloud->ssh_keys->create(
        name       => 'my-key',
        public_key => 'ssh-ed25519 AAAA...',
        labels     => { env => 'prod' },  # optional
    );

Creates a new SSH key. Returns a L<WWW::Hetzner::Cloud::SSHKey> object.

=head2 update

    $cloud->ssh_keys->update($id, name => 'new-name');

Updates SSH key name or labels. Returns a L<WWW::Hetzner::Cloud::SSHKey> object.

=head2 delete

    $cloud->ssh_keys->delete($id);

Deletes an SSH key.

=head2 ensure

    my $key = $cloud->ssh_keys->ensure('my-key', $public_key);

Ensures an SSH key exists with the given name and public key content.
If a key with that name exists but has different content, it will be
deleted and recreated. Returns a L<WWW::Hetzner::Cloud::SSHKey> object.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
