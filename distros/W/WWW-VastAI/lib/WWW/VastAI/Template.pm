package WWW::VastAI::Template;
our $VERSION = '0.001';
# ABSTRACT: Template wrapper with update and delete helpers

use Moo;
extends 'WWW::VastAI::Object';

sub name    { shift->data->{name} }
sub hash_id { shift->data->{hash_id} }
sub image   { shift->data->{image} }

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->templates->update($self->hash_id, %params)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->templates->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Template - Template wrapper with update and delete helpers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Template> wraps a Vast.ai template payload and delegates updates
and deletion to L<WWW::VastAI::API::Templates>.

=head1 METHODS

=head2 name

Returns the template name.

=head2 hash_id

Returns the template hash identifier.

=head2 image

Returns the template image reference.

=head2 update

    $template->update(%params);

Updates the template using its C<hash_id> and refreshes the local payload.

=head2 delete

Deletes the template and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Templates>

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
