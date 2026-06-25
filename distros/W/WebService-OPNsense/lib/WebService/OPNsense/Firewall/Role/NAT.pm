#!/bin/false
# ABSTRACT: Role for NAT controller shared rule methods
# PODNAME: WebService::OPNsense::Firewall::Role::NAT
use strictures 2;

package WebService::OPNsense::Firewall::Role::NAT;
$WebService::OPNsense::Firewall::Role::NAT::VERSION = '0.001';
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub add_rule {
    my ( $self, $rule_data ) = @_;
    return $self->client->post( $self->_path('addRule'), $rule_data );
}

sub apply {
    my ( $self, $rollback_revision ) = @_;
    my $path = $self->_path( 'apply{/rollback_revision}', rollback_revision => $rollback_revision );
    return $self->client->post($path);
}

sub cancel_rollback {
    my ( $self, $revision ) = @_;
    return $self->client->post( $self->_path( 'cancelRollback/{revision}', revision => $revision ) );
}

sub del_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delRule/{uuid}', uuid => $uuid ) );
}

sub get {
    my ($self) = @_;
    return $self->client->get( $self->_path('get') );
}

sub get_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getRule/{uuid}', uuid => $uuid ) );
}

sub list_categories {
    my ($self) = @_;
    return $self->client->get( $self->_path('listCategories') );
}

sub list_network_select_options {
    my ($self) = @_;
    return $self->client->get( $self->_path('listNetworkSelectOptions') );
}

sub list_port_select_options {
    my ($self) = @_;
    return $self->client->get( $self->_path('listPortSelectOptions') );
}

sub move_rule_before {
    my ( $self, $selected_uuid, $target_uuid ) = @_;
    validate_uuid($selected_uuid);
    validate_uuid($target_uuid);
    return $self->client->get(
        $self->_path(
            'moveRuleBefore/{selected_uuid}/{target_uuid}', selected_uuid => $selected_uuid, target_uuid => $target_uuid
        ),
    );
}

sub revert {
    my ( $self, $revision ) = @_;
    return $self->client->post( $self->_path( 'revert/{revision}', revision => $revision ) );
}

sub savepoint {
    my ($self) = @_;
    return $self->client->post( $self->_path('savepoint') );
}

sub search_rule {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchRule'), \%params );
}

sub set_rule {
    my ( $self, $uuid, $rule_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setRule/{uuid}', uuid => $uuid ), $rule_data );
}

sub set_settings {
    my ( $self, $settings ) = @_;
    return $self->client->post( $self->_path('set'), $settings );
}

sub toggle_rule {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleRule/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub toggle_rule_log {
    my ( $self, $uuid, $log ) = @_;
    validate_uuid($uuid);
    return $self->client->get(
        $self->_path( 'toggleRuleLog/{uuid}/{log}', uuid => $uuid, log => $log ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Role::NAT - Role for NAT controller shared rule methods

=head1 VERSION

version 0.001

=for Pod::Coverage _api_path _path client add_rule apply cancel_rollback del_rule get
get_rule list_categories list_network_select_options list_port_select_options
move_rule_before revert savepoint search_rule set_rule set_settings
toggle_rule toggle_rule_log

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
