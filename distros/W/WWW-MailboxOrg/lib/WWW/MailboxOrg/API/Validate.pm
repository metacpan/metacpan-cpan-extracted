package WWW::MailboxOrg::API::Validate;

# ABSTRACT: Validation API

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
    email => validation_for(
        params => {
            email => { type => Str, optional => 0 },
        },
    ),
);

sub email {
    my ($self, %params) = @_;
    my $v = $validators{'email'};
    %params = $v->(%params) if $v;
    return $self->_rpc('validate.email', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Validate - Validation API

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Validate - Validation API

=head2 email

    my $result = $api->validate->email(email => 'user@example.com');

Validate an email address. Required: C<email>.

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
