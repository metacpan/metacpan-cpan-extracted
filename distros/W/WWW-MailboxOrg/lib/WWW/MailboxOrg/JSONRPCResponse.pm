package WWW::MailboxOrg::JSONRPCResponse;

# ABSTRACT: JSON-RPC 2.0 response object

use Moo;

our $VERSION = '0.001';


has result => (
    is       => 'ro',
    predicate => 'has_result',
);


has error => (
    is       => 'ro',
    predicate => 'has_error',
);


has id => (
    is       => 'ro',
    predicate => 'has_id',
);


sub is_success {
    my ($self) = @_;
    return $self->has_result && !$self->has_error;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::JSONRPCResponse - JSON-RPC 2.0 response object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::MailboxOrg::JSONRPCResponse;

    my $res = WWW::MailboxOrg::JSONRPCResponse->new(
        result => { account => 'test@example.tld' },
        id     => 1,
    );

=head1 DESCRIPTION

JSON-RPC 2.0 response object.

=head2 result

The response result (absent on error).

=head2 error

Error object with C<code> and C<message> keys.

=head2 id

Request ID this response corresponds to.

=head2 is_success

Returns true if the response is successful.

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
