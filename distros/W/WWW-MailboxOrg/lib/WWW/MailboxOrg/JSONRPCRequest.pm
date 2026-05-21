package WWW::MailboxOrg::JSONRPCRequest;

# ABSTRACT: JSON-RPC 2.0 request object

use Moo;

our $VERSION = '0.001';


has jsonrpc => (
    is      => 'ro',
    default => '2.0',
);


has method => (
    is       => 'ro',
    required => 1,
);


has params => (
    is      => 'ro',
    default => sub { [] },
);


has id => (
    is       => 'ro',
    predicate => 'has_id',
);


has url => (
    is       => 'ro',
    required => 1,
);


has headers => (
    is      => 'ro',
    default => sub { {} },
);


sub to_hash {
    my ($self) = @_;
    my %hash = (
        jsonrpc => $self->jsonrpc,
        method  => $self->method,
        id      => $self->id,
    );
    my $params = $self->params;
    $hash{params} = $params if $params && (ref($params) eq 'ARRAY' ? @$params : %$params);
    return \%hash;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::JSONRPCRequest - JSON-RPC 2.0 request object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::MailboxOrg::JSONRPCRequest;

    my $req = WWW::MailboxOrg::JSONRPCRequest->new(
        method => 'account.get',
        params => { account => 'test@example.tld' },
        id     => 1,
        url    => 'https://api.mailbox.org/v1',
        headers => { 'HPLS-AUTH' => 'session123' },
    );

=head1 DESCRIPTION

Transport-independent JSON-RPC 2.0 request object.

=head2 jsonrpc

JSON-RPC version. Defaults to "2.0".

=head2 method

The RPC method name, e.g. "account.get".

=head2 params

ArrayRef of positional parameters or HashRef of named parameters.

=head2 id

Request ID for correlating responses. Undef for notifications.

=head2 url

The endpoint URL for the request.

=head2 headers

Hashref of HTTP headers (e.g. HPLS-AUTH).

=head2 to_hash

Returns a hashref representation for JSON encoding.

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
