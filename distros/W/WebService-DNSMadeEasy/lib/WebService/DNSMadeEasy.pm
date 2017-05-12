package WebService::DNSMadeEasy;

use Moo;

use WebService::DNSMadeEasy::Client;
use WebService::DNSMadeEasy::ManagedDomain;

our $VERSION = "0.02";

has api_key           => (is => 'ro', required => 1);
has secret            => (is => 'ro', required => 1);
has sandbox           => (is => 'ro', default => sub { 0 });
has user_agent_header => (is => 'rw', lazy => 1, builder => 1);
has client            => (is => 'lazy');

sub _build_user_agent_header { __PACKAGE__ . "/" . $VERSION }

sub _build_client {
    my $self = shift;
    my $client = WebService::DNSMadeEasy::Client->instance(
        api_key           => $self->api_key,
        secret            => $self->secret,
        sandbox           => $self->sandbox,
        user_agent_header => $self->user_agent_header,
    );

    $client->user_agent_header($self->user_agent_header)
        if $self->user_agent_header;

    return $client;
}

sub create_managed_domain {
    my ($self, $name) = @_;
    return WebService::DNSMadeEasy::ManagedDomain->create(
        client => $self->client,
        name   => $name,
    );
}

sub get_managed_domain {
    my ($self, $name) = @_;
    return WebService::DNSMadeEasy::ManagedDomain->new(
        client => $self->client,
        name   => $name,
    );
}

sub managed_domains { WebService::DNSMadeEasy::ManagedDomain->find(client => shift->client) }

1;

=encoding utf8

=head1 NAME

WebService::DNSMadeEasy - Implements V2.0 of the DNSMadeEasy API

=head1 SYNOPSIS

    use WebService::DNSMadeEasy;
  
    my $dns = WebService::DNSMadeEasy->new({
        api_key => $api_key,
        secret  => $secret,
        sandbox => 1,     # defaults to 0
    });

    # DOMAINS - see WebService::DNSMadeEasy::ManagedDomain
    my @domains = $dns->managed_domains;
    my $domain  = $dns->get_managed_domain('example.com');
    my $domain  = $dns->create_managed_domain('stegasaurus.com');
    $domain->update(...);
    $domain->delete;
    ...

    # RECORDS - see WebService::DNSMadeEasy::ManagedDomain::Record
    my $record  = $domain->create_record(...);
    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records
    $record->update(...);
    $record->delete;
    ...

    # MONITORS - see WebService::DNSMadeEasy::Monitor
    my $monitor = $record->get_monitor;
    $monitor->disable;     # disable failover and system monitoring
    $monitor->update(...);
    ...

=head1 DESCRIPTION

This distribution implements v2 of the DNSMadeEasy API as described in
L<http://dnsmadeeasy.com/integration/pdf/API-Docv2.pdf>.

=head1 ATTRIBUTES

=over 4

=item api_key

You can find this here: L<https://cp.dnsmadeeasy.com/account/info>.

=item secret

You can find this here: L<https://cp.dnsmadeeasy.com/account/info>.

=item sandbox

Uses the sandbox api endpoint if set to true.  Creating a sandbox account is a
good idea so you can test before messing with your live/production account.
You can create a sandbox account here: L<https://sandbox.dnsmadeeasy.com>.

=item user_agent_header

Here you can set the User-Agent http header.  

=back

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

This module started as a fork of Torsten Raudssus's WWW::DNSMadeEasy module,
but its pretty much a total rewrite especially since v1 and v2 of the DNS Made
Easy protocol are very different.

=cut

