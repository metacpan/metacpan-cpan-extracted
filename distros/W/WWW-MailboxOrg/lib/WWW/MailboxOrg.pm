package WWW::MailboxOrg;

# ABSTRACT: Perl client for Mailbox.org API

use Moo;
use Carp qw(croak);
use WWW::MailboxOrg::API::Base;
use WWW::MailboxOrg::API::Account;
use WWW::MailboxOrg::API::Domain;
use WWW::MailboxOrg::API::Mail;
use WWW::MailboxOrg::API::Mailinglist;
use WWW::MailboxOrg::API::Blacklist;
use WWW::MailboxOrg::API::Spamprotect;
use WWW::MailboxOrg::API::Videochat;
use WWW::MailboxOrg::API::Backup;
use WWW::MailboxOrg::API::Invoice;
use WWW::MailboxOrg::API::Passwordreset;
use WWW::MailboxOrg::API::Validate;
use WWW::MailboxOrg::API::Utils;
use WWW::MailboxOrg::API::System;
use namespace::clean;

our $VERSION = '0.001';


has user => (
    is       => 'ro',
    required => 1,
);


has password => (
    is       => 'ro',
    required => 1,
);


has token => (
    is      => 'rwp',
    clearer => 1,
);


has base_url => (
    is      => 'ro',
    default => 'https://api.mailbox.org/v1',
);


with 'WWW::MailboxOrg::Role::HTTP';

sub _set_auth_header {
    my ($self, $headers) = @_;
    $headers->{'HPLS-AUTH'} = $self->token if $self->token;
}


sub login {
    my ($self) = @_;

    my $result = $self->call('auth', {
        user => $self->user,
        pass => $self->password,
    });

    if (ref $result && $result->{session}) {
        $self->_set_token($result->{session});
        return $result;
    }

    croak "Login failed: " . ($result // 'no session returned');
}


sub logout {
    my ($self) = @_;

    $self->call('deauth') if $self->token;
    $self->_clear_token;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->logout if $self->token;
}

# Resource accessors
has base => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Base->new(client => shift) },
);


has account => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Account->new(client => shift) },
);


has domain => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Domain->new(client => shift) },
);


has mail => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Mail->new(client => shift) },
);


has mailinglist => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Mailinglist->new(client => shift) },
);


has blacklist => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Blacklist->new(client => shift) },
);


has spamprotect => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Spamprotect->new(client => shift) },
);


has videochat => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Videochat->new(client => shift) },
);


has backup => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Backup->new(client => shift) },
);


has invoice => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Invoice->new(client => shift) },
);


has passwordreset => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Passwordreset->new(client => shift) },
);


has validate => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Validate->new(client => shift) },
);


has utils => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::Utils->new(client => shift) },
);


has system => (
    is      => 'lazy',
    builder => sub { WWW::MailboxOrg::API::System->new(client => shift) },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg - Perl client for Mailbox.org API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::MailboxOrg;

    my $api = WWW::MailboxOrg->new(
        user     => 'test@example.tld',
        password => 'secret123',
    );

    # Authenticate and get session
    $api->login;

    # List accounts
    my $accounts = $api->account->list;

    # Get domain info
    my $domain = $api->domain->get(domain => 'example.com');

=head1 DESCRIPTION

WWW::MailboxOrg provides a Perl interface to the Mailbox.org API.
Uses JSON-RPC 2.0 over HTTPS with session-based authentication.

=head2 user

Mailbox.org username or email address.

=head2 password

Mailbox.org password.

=head2 token

Session token (HPLS-AUTH). Set after successful login.

=head2 base_url

Base URL for the API. Defaults to C<https://api.mailbox.org/v1>.

=head2 login

    $api->login;

Authenticate with username/password and store session token.

=head2 logout

    $api->logout;

End the current session.

=head2 base

Returns L<WWW::MailboxOrg::API::Base> for auth and search.

=head2 account

Returns L<WWW::MailboxOrg::API::Account> for account management.

=head2 domain

Returns L<WWW::MailboxOrg::API::Domain> for domain management.

=head2 mail

Returns L<WWW::MailboxOrg::API::Mail> for email operations.

=head2 mailinglist

Returns L<WWW::MailboxOrg::API::Mailinglist> for mailing list management.

=head2 blacklist

Returns L<WWW::MailboxOrg::API::Blacklist> for blacklist management.

=head2 spamprotect

Returns L<WWW::MailboxOrg::API::Spamprotect> for spam protection settings.

=head2 videochat

Returns L<WWW::MailboxOrg::API::Videochat> for video chat rooms.

=head2 backup

Returns L<WWW::MailboxOrg::API::Backup> for backup operations.

=head2 invoice

Returns L<WWW::MailboxOrg::API::Invoice> for invoice access.

=head2 passwordreset

Returns L<WWW::MailboxOrg::API::Passwordreset> for password reset.

=head2 validate

Returns L<WWW::MailboxOrg::API::Validate> for email validation.

=head2 utils

Returns L<WWW::MailboxOrg::API::Utils> for utility functions.

=head2 system

Returns L<WWW::MailboxOrg::API::System> for system info (hello, test).

=head1 SEE ALSO

L<https://api.mailbox.org/v1/doc/methods/index.html> - Mailbox.org API docs

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
