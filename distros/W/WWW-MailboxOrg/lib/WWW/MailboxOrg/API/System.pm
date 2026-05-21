package WWW::MailboxOrg::API::System;

# ABSTRACT: System API (hello, test, capabilities)

use Moo;
use MooX::Singleton;
use Carp qw(croak);

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

sub hello {
    my ($self) = @_;
    return $self->_rpc('hello');
}

sub test {
    my ($self) = @_;
    return $self->_rpc('test');
}

sub capabilities {
    my ($self) = @_;
    return $self->_rpc('capabilities');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::System - System API (hello, test, capabilities)

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::System - System API (hello, test, capabilities)

=head2 hello

    my $result = $api->system->hello;

Get API hello response. No parameters required.

=head2 test

    my $result = $api->system->test;

Test API connection. Returns test result.

=head2 capabilities

    my $caps = $api->system->capabilities;

Get API capabilities. Returns capability list.

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
