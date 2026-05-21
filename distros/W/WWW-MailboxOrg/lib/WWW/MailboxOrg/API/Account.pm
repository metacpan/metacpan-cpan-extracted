package WWW::MailboxOrg::API::Account;

# ABSTRACT: Account management API

use Moo;
use MooX::Singleton;
use Carp qw(croak);
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw(Str Enum HashRef);
use WWW::MailboxOrg::Types qw(EmailAddress);

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
    add => validation_for(
        params => {
            account      => { type => EmailAddress, optional => 0 },
            password     => { type => Str, optional => 0 },
            plan         => { type => Enum[qw(basic profi profixl reseller)], optional => 0 },
            tarifflimits => { type => HashRef, optional => 1 },
            memo         => { type => Str, optional => 1 },
        },
    ),
    del => validation_for(
        params => {
            account => { type => EmailAddress, optional => 0 },
        },
    ),
    get => validation_for(
        params => {
            account => { type => EmailAddress, optional => 0 },
        },
    ),
    list => validation_for(
        params => {
            account => { type => EmailAddress, optional => 1 },
        },
    ),
    set => validation_for(
        params => {
            account                    => { type => EmailAddress, optional => 0 },
            password                   => { type => Str, optional => 1 },
            plan                       => { type => Enum[qw(basic profi profixl reseller)], optional => 1 },
            memo                       => { type => Str, optional => 1 },
            address_payment_first_name => { type => Str, optional => 1 },
            address_payment_last_name  => { type => Str, optional => 1 },
            address_payment_street     => { type => Str, optional => 1 },
            address_payment_zipcode    => { type => Str, optional => 1 },
            address_payment_town       => { type => Str, optional => 1 },
            av_contract_accept_name    => { type => Str, optional => 1 },
            tarifflimits               => { type => HashRef, optional => 1 },
        },
    ),
);

sub add {
    my ($self, %params) = @_;
    my $v = $validators{'add'};
    %params = $v->(%params) if $v;
    return $self->_rpc('account.add', \%params);
}

sub del {
    my ($self, %params) = @_;
    my $v = $validators{'del'};
    %params = $v->(%params) if $v;
    return $self->_rpc('account.del', \%params);
}

sub get {
    my ($self, %params) = @_;
    my $v = $validators{'get'};
    %params = $v->(%params) if $v;
    return $self->_rpc('account.get', \%params);
}

sub list {
    my ($self, %params) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc('account.list', \%params);
}

sub set {
    my ($self, %params) = @_;
    my $v = $validators{'set'};
    %params = $v->(%params) if $v;
    return $self->_rpc('account.set', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Account - Account management API

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Account - Account management API

=head2 add

    $api->account->add(
        account      => 'user@example.com',
        password     => 'secret123',
        plan         => 'basic',
        tarifflimits => { ... },
        memo         => 'Optional note',
    );

Add a new account. Required: C<account>, C<password>, C<plan>.

=head2 del

    $api->account->del(account => 'user@example.com');

Delete an account.

=head2 get

    $api->account->get(account => 'user@example.com');

Get account details.

=head2 list

    $api->account->list;
    $api->account->list(account => 'admin@example.com');

List accounts. Optional C<account> filter.

=head2 set

    $api->account->set(
        account => 'user@example.com',
        plan    => 'profi',
        memo    => 'Updated note',
    );

Update account settings. At least C<account> required.

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
