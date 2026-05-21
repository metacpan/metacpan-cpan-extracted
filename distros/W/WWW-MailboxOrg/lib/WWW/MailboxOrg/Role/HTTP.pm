package WWW::MailboxOrg::Role::HTTP;

# ABSTRACT: JSON-RPC HTTP client role

use Moo::Role;
use WWW::MailboxOrg::JSONRPCRequest;
use WWW::MailboxOrg::JSONRPCResponse;
use JSON::MaybeXS qw(decode_json encode_json);
use Carp qw(croak);
use Log::Any qw($log);

our $VERSION = '0.001';


requires 'token';
requires 'base_url';

has io => (
    is      => 'lazy',
    builder => sub { require WWW::MailboxOrg::LWPIO; WWW::MailboxOrg::LWPIO->new },
);


sub call {
    my ($self, $method, @params) = @_;

    my $req = $self->_build_jsonrpc_request($method, @params);
    my $res = $self->io->call($req);
    return $self->_parse_response($res);
}


sub notification {
    my ($self, $method, @params) = @_;
    my $req = $self->_build_jsonrpc_request($method, @params, 1);
    return $self->io->call($req);
}


sub _build_jsonrpc_request {
    my ($self, $method, @params) = @_;
    my $is_notification = pop @params if @params && $_[-1] == 1;
    $is_notification //= 0;

    my $params_ref = @params == 1 && ref($params[0]) eq 'HASH' ? $params[0] : \@params;

    my %headers;
    $self->_set_auth_header(\%headers) if $self->can('_set_auth_header');

    return WWW::MailboxOrg::JSONRPCRequest->new(
        method  => $method,
        params  => $params_ref,
        id      => $is_notification ? undef : $self->_next_id,
        url     => $self->base_url,
        headers => \%headers,
    );
}

sub _set_auth_header {
    my ($self, $headers) = @_;
    $headers->{'HPLS-AUTH'} = $self->token if $self->token;
}

sub _parse_response {
    my ($self, $res) = @_;

    if ($res->has_error) {
        my $err = $res->error;
        $log->errorf("RPC error: %s (code=%s)", $err->{message} // 'unknown', $err->{code} // -1);
        croak "Mailbox.org API error: " . ($err->{message} // 'unknown');
    }

    return $res->result;
}

my $_id = 0;
sub _next_id { ++$_id }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::Role::HTTP - JSON-RPC HTTP client role

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package WWW::MailboxOrg;
    use Moo;

    has token => ( is => 'ro' );
    has base_url => ( is => 'ro', default => 'https://api.mailbox.org/v1' );

    with 'WWW::MailboxOrg::Role::HTTP';

=head1 DESCRIPTION

This role provides JSON-RPC 2.0 call and notification methods. It handles
JSON encoding/decoding, authentication, and error handling.

HTTP transport is delegated to a pluggable L<WWW::MailboxOrg::Role::IO> backend
(default: L<WWW::MailboxOrg::LWPIO>), making it possible to use async HTTP
clients.

Uses L<Log::Any> for logging.

=head1 REQUIRED ATTRIBUTES

Classes consuming this role must provide:

=over 4

=item * C<token> - Session ID for HPLS-AUTH header

=item * C<base_url> - Base URL for the API

=back

=head2 io

Pluggable JSON-RPC backend implementing L<WWW::MailboxOrg::Role::IO>.
Defaults to L<WWW::MailboxOrg::LWPIO>.

=head2 call

    my $result = $self->call('account.get', account => 'test@example.tld');

Execute a JSON-RPC call and return the result. Croaks on error.

=head2 notification

    $self->notification('mail.send', %params);

Send a fire-and-forget notification (no response ID expected).

=head1 SEE ALSO

L<WWW::MailboxOrg>, L<WWW::MailboxOrg::Role::IO>, L<WWW::MailboxOrg::LWPIO>,
L<Log::Any>

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
