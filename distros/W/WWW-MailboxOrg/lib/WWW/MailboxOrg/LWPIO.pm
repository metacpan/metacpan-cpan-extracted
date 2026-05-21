package WWW::MailboxOrg::LWPIO;

# ABSTRACT: Synchronous JSON-RPC backend using Mojo::UserAgent

use Moo;
use Mojo::UserAgent;
use WWW::MailboxOrg::JSONRPCRequest;
use WWW::MailboxOrg::JSONRPCResponse;
use JSON::MaybeXS qw(decode_json encode_json);

with 'WWW::MailboxOrg::Role::IO';

our $VERSION = '0.001';


has timeout => (
    is      => 'ro',
    default => 30,
);


has ua => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        Mojo::UserAgent->new(
            timeout => $self->timeout,
        );
    },
);


sub call {
    my ($self, $req) = @_;

    my $url = $req->url;

    my %headers = (
        'Content-Type' => 'application/json',
    );
    $headers{'HPLS-AUTH'} = $req->headers->{'HPLS-AUTH'}
        if $req->headers && $req->headers->{'HPLS-AUTH'};

    my $payload = encode_json($req->to_hash);

    my $tx = $self->ua->post($url, \%headers, json => $req->to_hash);

    if (my $err = $tx->error) {
        return WWW::MailboxOrg::JSONRPCResponse->new(
            error => {
                code    => -32300,
                message => $err->{message},
            },
            id => $req->id,
        );
    }

    my $data = $tx->res->json;

    if (!$data) {
        return WWW::MailboxOrg::JSONRPCResponse->new(
            error => {
                code    => -32603,
                message => 'Empty or invalid JSON response',
            },
            id => $req->id,
        );
    }

    return WWW::MailboxOrg::JSONRPCResponse->new(%$data);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::LWPIO - Synchronous JSON-RPC backend using Mojo::UserAgent

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::MailboxOrg::LWPIO;

    my $io = WWW::MailboxOrg::LWPIO->new(timeout => 60);

=head1 DESCRIPTION

Default synchronous JSON-RPC backend using L<Mojo::UserAgent>. Implements
L<WWW::MailboxOrg::Role::IO>.

=head2 timeout

Timeout in seconds for HTTP requests. Defaults to 30.

=head2 ua

L<Mojo::UserAgent> instance. Built lazily.

=head2 call($req)

Execute a L<WWW::MailboxOrg::JSONRPCRequest> via Mojo::UserAgent and return a
L<WWW::MailboxOrg::JSONRPCResponse>.

=head1 SEE ALSO

L<WWW::MailboxOrg::Role::IO>, L<WWW::MailboxOrg::Role::HTTP>,
L<Mojo::UserAgent>

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
