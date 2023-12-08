package WWW::Suffit::Server::ServerInfo;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::ServerInfo - The Mojolicious ServerInfo controller for the suffit projects

=head1 DESCRIPTION

The Mojolicious ServerInfo controller for the suffit projects

=head1 METHODS

API methods

=head2 info

The route to show server information

=head1 SEE ALSO

L<WWW::Suffit::Plugin::ServerInfo>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

our $VERSION = '1.01';

sub info { shift->serverinfo }

1;

__END__
