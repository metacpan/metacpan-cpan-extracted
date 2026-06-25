#!/bin/false
# ABSTRACT: Captive portal voucher controller
# PODNAME: WebService::OPNsense::CaptivePortal::Voucher
use strictures 2;

package WebService::OPNsense::CaptivePortal::Voucher;
$WebService::OPNsense::CaptivePortal::Voucher::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub list_providers {
    my ($self) = @_;
    return $self->client->get('/api/captiveportal/voucher/listProviders');
}

sub list_voucher_groups {
    my ( $self, $provider ) = @_;
    return $self->client->get("/api/captiveportal/voucher/listVoucherGroups/$provider");
}

sub list_vouchers {
    my ( $self, $provider, $group ) = @_;
    return $self->client->get("/api/captiveportal/voucher/listVouchers/$provider/$group");
}

sub generate_vouchers {
    my ( $self, $provider ) = @_;
    return $self->client->post("/api/captiveportal/voucher/generateVouchers/$provider");
}

sub expire_voucher {
    my ( $self, $provider ) = @_;
    return $self->client->post("/api/captiveportal/voucher/expireVoucher/$provider");
}

sub drop_voucher_group {
    my ( $self, $provider, $group ) = @_;
    return $self->client->post("/api/captiveportal/voucher/dropVoucherGroup/$provider/$group");
}

sub drop_expired_vouchers {
    my ( $self, $provider, $group ) = @_;
    return $self->client->post(
        "/api/captiveportal/voucher/dropExpiredVouchers/$provider/$group",
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Voucher - Captive portal voucher controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cp_voucher = $opn->captiveportal_voucher;

    my $providers = $cp_voucher->list_providers;

=head1 DESCRIPTION

Manages captive portal vouchers.

=head1 NAME

WebService::OPNsense::CaptivePortal::Voucher - Captive portal voucher controller

=head1 METHODS

=head2 list_providers

    my $providers = $cp_voucher->list_providers;

Lists voucher providers.

=head2 list_voucher_groups

    my $groups = $cp_voucher->list_voucher_groups($provider);

Lists voucher groups for a given provider.

=head2 list_vouchers

    my $vouchers = $cp_voucher->list_vouchers($provider, $group);

Lists vouchers for a given provider and group.

=head2 generate_vouchers

    my $result = $cp_voucher->generate_vouchers($provider);

Generates new vouchers for a provider.

=head2 expire_voucher

    my $result = $cp_voucher->expire_voucher($provider);

Expires vouchers for a provider.

=head2 drop_voucher_group

    my $result = $cp_voucher->drop_voucher_group($provider, $group);

Drops a voucher group.

=head2 drop_expired_vouchers

    my $result = $cp_voucher->drop_expired_vouchers($provider, $group);

Drops expired vouchers for a provider and group.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
