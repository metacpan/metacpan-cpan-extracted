package WWW::MailboxOrg::Role::API;

# ABSTRACT: Shared API controller behavior (client, _rpc)

use Moo::Role;
use Carp qw(croak);


sub _rpc {
    my ( $self, $method, @params ) = @_;
    my $client = $self->client or croak "No client set";
    return $client->call( $method, @params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Role::API - Shared API controller behavior (client, _rpc)

=head1 VERSION

version 0.100

=head1 DESCRIPTION

This role provides the C<_rpc> method used by all API controllers
to make JSON-RPC calls via the client.

=head1 METHODS

=head2 _rpc

    $self->_rpc('method.name', \%params);

Make a JSON-RPC call via the client. The C<client> attribute must
be set. Returns the result from the RPC call.

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-mailboxorg/issues>.

=head2 IRC

Join C<#perl-help> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
