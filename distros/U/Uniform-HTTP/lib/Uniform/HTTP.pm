package Uniform::HTTP;

use strict;
use warnings;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Uniform::HTTP - Framework-neutral HTTP messages and authentication

=head1 VERSION

Version 0.02.

=head1 DESCRIPTION

Uniform::HTTP provides small HTTP domain objects and authentication mechanics
without choosing a client, server, transport, framework, or event loop.

The distribution contains canonical mutable message implementations and a
contract that separately distributed framework adapters can implement.

=head1 MODULES

=over 4

=item * L<Uniform::HTTP::Message>

=item * L<Uniform::HTTP::Request>

=item * L<Uniform::HTTP::Response>

=item * L<Uniform::HTTP::Auth>

=back

=head1 BOUNDARY

This distribution represents HTTP message semantics and authentication data.
It does not parse or serialize wire messages, perform I/O, own connections,
retry requests, or expose framework lifecycle APIs.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
