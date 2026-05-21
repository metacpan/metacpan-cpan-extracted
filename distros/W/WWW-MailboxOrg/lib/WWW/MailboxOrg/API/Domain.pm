package WWW::MailboxOrg::API::Domain;

# ABSTRACT: Domain management API

use Moo;
use MooX::Singleton;
use Carp qw(croak);
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw(Str Bool HashRef);
use WWW::MailboxOrg::Types qw(DomainName);

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
            account               => { type => Str, optional => 0 },
            domain               => { type => DomainName, optional => 0 },
            password             => { type => Str, optional => 0 },
            context_id           => { type => Str, optional => 1 },
            create_new_context_id => { type => Bool, optional => 1 },
            memo                 => { type => Str, optional => 1 },
        },
    ),
    del => validation_for(
        params => {
            account => { type => Str, optional => 0 },
            domain  => { type => DomainName, optional => 0 },
        },
    ),
    get => validation_for(
        params => {
            domain => { type => DomainName, optional => 0 },
        },
    ),
    list => validation_for(
        params => {
            account => { type => Str, optional => 1 },
            filter  => { type => Str, optional => 1 },
        },
    ),
    set => validation_for(
        params => {
            domain                => { type => DomainName, optional => 0 },
            password              => { type => Str, optional => 1 },
            context_id            => { type => Str, optional => 1 },
            create_new_context_id => { type => Bool, optional => 1 },
            memo                  => { type => Str, optional => 1 },
        },
    ),
);

sub add {
    my ($self, %params) = @_;
    my $v = $validators{'add'};
    %params = $v->(%params) if $v;
    return $self->_rpc('domain.add', \%params);
}

sub del {
    my ($self, %params) = @_;
    my $v = $validators{'del'};
    %params = $v->(%params) if $v;
    return $self->_rpc('domain.del', \%params);
}

sub get {
    my ($self, %params) = @_;
    my $v = $validators{'get'};
    %params = $v->(%params) if $v;
    return $self->_rpc('domain.get', \%params);
}

sub list {
    my ($self, %params) = @_;
    my $v = $validators{'list'};
    %params = $v->(%params) if $v;
    return $self->_rpc('domain.list', \%params);
}

sub set {
    my ($self, %params) = @_;
    my $v = $validators{'set'};
    %params = $v->(%params) if $v;
    return $self->_rpc('domain.set', \%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::MailboxOrg::API::Domain - Domain management API

=head1 VERSION

version 0.001

=head1 NAME

WWW::MailboxOrg::API::Domain - Domain management API

=head2 add

    $api->domain->add(
        account               => 'admin@example.com',
        domain               => 'example.com',
        password             => 'secret123',
        context_id           => 'optional-context-id',
        create_new_context_id => 1,
        memo                 => 'Optional note',
    );

Add a new domain. Required: C<account>, C<domain>, C<password>.

=head2 del

    $api->domain->del(
        account => 'admin@example.com',
        domain  => 'example.com',
    );

Delete a domain.

=head2 get

    $api->domain->get(domain => 'example.com');

Get domain details.

=head2 list

    $api->domain->list;
    $api->domain->list(account => 'admin@example.com');

List domains. Optional C<account> or C<filter>.

=head2 set

    $api->domain->set(
        domain                => 'example.com',
        password              => 'newsecret',
        context_id            => 'new-context-id',
        create_new_context_id => 1,
        memo                  => 'Updated note',
    );

Update domain settings. At least C<domain> required.

    $api->domain->set(
        domain                => 'example.com',
        password              => 'newsecret',
        context_id            => 'new-context-id',
        create_new_context_id => 1,
        memo                  => 'Updated note',
    );

Update domain settings. At least C<domain> required.

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
