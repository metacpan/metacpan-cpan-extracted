package WWW::VastAI::User;
our $VERSION = '0.001';
# ABSTRACT: Current-user payload wrapper for Vast.ai accounts

use Moo;
extends 'WWW::VastAI::Object';

sub email   { shift->data->{email} }
sub balance { shift->data->{balance} }
sub ssh_key { shift->data->{ssh_key} }
sub sid     { shift->data->{sid} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::User - Current-user payload wrapper for Vast.ai accounts

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::User> wraps the current-user profile returned by
L<WWW::VastAI::API::User>.

=head1 METHODS

=head2 email

Returns the account email address.

=head2 balance

Returns the current account balance.

=head2 ssh_key

Returns the primary SSH key string when present.

=head2 sid

Returns the Vast.ai user SID.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::User>

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
