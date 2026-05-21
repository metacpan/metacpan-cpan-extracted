package WWW::MailboxOrg::API::Base;

# ABSTRACT: Base API controller for auth and search

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
    auth => validation_for(
        params => {
            user => { type => Str, optional => 0 },
            pass => { type => Str, optional => 0 },
        },
    ),
    search => validation_for(
        params => {
            query => { type => Str, optional => 0 },
        },
    ),
);

sub auth {
    my ($self, %params) = @_;
    my $v = $validators{'auth'};
    %params = $v->(%params) if $v;
    return $self->_rpc('auth', \%params);
}

sub deauth {
    my ($self) = @_;
    return $self->_rpc('deauth');
}

sub search {
    my ($self, %params) = @_;
    my $v = $validators{'search'};
    %params = $v->(%params) if $v;
    return $self->_rpc('search', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Base - Base API controller for auth and search

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Base - Base API controller for auth and search

=head2 auth

    $api->base->auth(user => 'user@example.com', pass => 'secret');

Authenticate and get session token. Required: C<user>, C<pass>.

=head2 deauth

    $api->base->deauth;

End the current session.

=head2 search

    my $results = $api->base->search(query => 'some search terms');

Search across the API. Required: C<query>.

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
