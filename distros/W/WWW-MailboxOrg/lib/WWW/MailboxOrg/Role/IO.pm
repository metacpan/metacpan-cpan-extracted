package WWW::MailboxOrg::Role::IO;

# ABSTRACT: Interface role for pluggable JSON-RPC backends

use Moo::Role;

our $VERSION = '0.001';

requires 'call';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Role::IO - Interface role for pluggable JSON-RPC backends

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package My::AsyncIO;
    use Moo;
    with 'WWW::MailboxOrg::Role::IO';

    sub call {
        my ($self, $req) = @_;
        my $result = $self->_do_rpc($req);
        return WWW::MailboxOrg::JSONRPCResponse->new(%$result);
    }

=head1 DESCRIPTION

This role defines the interface that JSON-RPC backends must implement.
L<WWW::MailboxOrg::Role::HTTP> delegates all RPC communication through this
interface, making it possible to swap out the transport layer.

The default backend is L<WWW::MailboxOrg::LWPIO> (synchronous, using
L<Mojo::UserAgent>). To use an async event loop, implement this role.

=head1 REQUIRED METHODS

=head2 call($req)

Execute a L<WWW::MailboxOrg::JSONRPCRequest>. Receives the request object
with C<method>, C<params>, and C<id> already set.

Must return a L<WWW::MailboxOrg::JSONRPCResponse>.

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/getty/p5-www-mailboxorg/issues>.

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
