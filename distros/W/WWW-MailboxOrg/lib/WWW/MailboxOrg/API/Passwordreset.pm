package WWW::MailboxOrg::API::Passwordreset;

# ABSTRACT: Password reset API

use Moo;
use MooX::Singleton;
use Carp qw(croak);
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw(Str);

our $VERSION = '0.001';

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _rpc {
    my ($self, $method, @params) = @_;
    my $client = $self->client or croak "No client set";
    return $client->call($method, @params);
}

my %validators = (
    request => validation_for(
        params => {
            account => { type => Str, optional => 0 },
        },
    ),
    set => validation_for(
        params => {
            account    => { type => Str, optional => 0 },
            token     => { type => Str, optional => 0 },
            newpassword => { type => Str, optional => 0 },
        },
    ),
);

sub request {
    my ($self, %params) = @_;
    my $v = $validators{'request'};
    %params = $v->(%params) if $v;
    return $self->_rpc('passwordreset.request', \%params);
}

sub set {
    my ($self, %params) = @_;
    my $v = $validators{'set'};
    %params = $v->(%params) if $v;
    return $self->_rpc('passwordreset.set', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Passwordreset - Password reset API

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Passwordreset - Password reset API

=head2 request

    $api->passwordreset->request(account => 'user@example.com');

Request password reset. Required: C<account>.

=head2 set

    $api->passwordreset->set(
        account      => 'user@example.com',
        token        => 'reset-token-from-email',
        newpassword  => 'newsecret123',
    );

Set new password. Required: C<account>, C<token>, C<newpassword>.

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
