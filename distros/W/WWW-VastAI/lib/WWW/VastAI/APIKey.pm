package WWW::VastAI::APIKey;
our $VERSION = '0.001';
# ABSTRACT: API key wrapper for Vast.ai account credentials

use Moo;
extends 'WWW::VastAI::Object';

sub key         { shift->data->{key} }
sub rights      { shift->data->{rights} }
sub permissions { shift->data->{permissions} }

sub delete {
    my ($self) = @_;
    return $self->_client->api_keys->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::APIKey - API key wrapper for Vast.ai account credentials

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::APIKey> wraps an API key record returned by
L<WWW::VastAI::API::APIKeys>.

=head1 METHODS

=head2 key

Returns the API key token string.

=head2 rights

Returns the legacy rights value when the API includes it.

=head2 permissions

Returns the permission list from the API payload.

=head2 delete

Deletes the API key and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::APIKeys>

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
