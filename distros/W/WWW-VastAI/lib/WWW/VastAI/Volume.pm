package WWW::VastAI::Volume;
our $VERSION = '0.001';
# ABSTRACT: Volume wrapper for Vast.ai storage resources

use Moo;
extends 'WWW::VastAI::Object';

sub status      { shift->data->{status} }
sub machine_id  { shift->data->{machine_id} }
sub public_ipaddr { shift->data->{public_ipaddr} }

sub delete {
    my ($self) = @_;
    return $self->_client->volumes->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Volume - Volume wrapper for Vast.ai storage resources

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Volume> represents a storage volume returned by
L<WWW::VastAI::API::Volumes>.

=head1 METHODS

=head2 status

Returns the current volume status.

=head2 machine_id

Returns the associated machine ID when present.

=head2 public_ipaddr

Returns the public IP address reported for the volume.

=head2 delete

    $volume->delete;

Deletes the volume through the parent client and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Volumes>

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
