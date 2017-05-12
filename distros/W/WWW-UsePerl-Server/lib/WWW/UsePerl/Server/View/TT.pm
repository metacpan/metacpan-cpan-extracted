package WWW::UsePerl::Server::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
    WRAPPER            => 'lib/wrapper.tt',
);

=head1 NAME

WWW::UsePerl::Server::View::TT - TT View for WWW::UsePerl::Server

=head1 DESCRIPTION

TT View for WWW::UsePerl::Server.

=head1 SEE ALSO

L<WWW::UsePerl::Server>

=head1 AUTHOR

Leon Brocard,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
