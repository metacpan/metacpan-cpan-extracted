package WWW::VastAI::SSHKey;
our $VERSION = '0.001';
# ABSTRACT: Account SSH key wrapper with update and delete helpers

use Moo;
extends 'WWW::VastAI::Object';

sub key {
    my ($self) = @_;
    return $self->data->{key} // $self->data->{public_key};
}
sub created_at { shift->data->{created_at} }

sub update {
    my ($self, $ssh_key) = @_;
    return $self->_replace_data($self->_client->ssh_keys->update($self->id, $ssh_key)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->ssh_keys->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::SSHKey - Account SSH key wrapper with update and delete helpers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::SSHKey> represents an SSH key managed by
L<WWW::VastAI::API::SSHKeys>.

=head1 METHODS

=head2 key

    my $public_key = $ssh_key->key;

Returns the public key text, normalizing either C<key> or C<public_key> from
the API payload.

=head2 created_at

Returns the payload creation timestamp when available.

=head2 update

    $ssh_key->update($new_public_key);

Updates the SSH key and refreshes the local payload.

=head2 delete

Deletes the SSH key and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::SSHKeys>

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
