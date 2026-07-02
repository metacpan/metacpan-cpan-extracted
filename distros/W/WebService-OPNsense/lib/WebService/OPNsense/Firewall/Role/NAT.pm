#!/bin/false
# ABSTRACT: Role for NAT controller shared rule methods
# PODNAME: WebService::OPNsense::Firewall::Role::NAT
use strictures 2;

package WebService::OPNsense::Firewall::Role::NAT;
$WebService::OPNsense::Firewall::Role::NAT::VERSION = '0.003';
use Carp qw( croak );
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;    # must be last

with 'WebService::OPNsense::Role::APIPath';

sub add_rule {
    my ( $self, $rule_data ) = @_;
    my $uri = $self->_path('addRule');

    return $self->client->post( $uri, $rule_data );
}

sub apply {
    my ( $self, $rollback_revision ) = @_;
    my $path = $self->_path( 'apply{/rollback_revision}', rollback_revision => $rollback_revision );
    return $self->client->post($path);
}

sub cancel_rollback {
    my ( $self, $revision ) = @_;
    my $uri = $self->_path( 'cancelRollback/{revision}', revision => $revision );

    return $self->client->post($uri);
}

sub del_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delRule/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub get {
    my ($self) = @_;
    my $uri = $self->_path('get');

    return $self->client->get($uri);
}

sub get_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getRule/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub list_categories {
    my ($self) = @_;
    my $uri = $self->_path('listCategories');

    return $self->client->get($uri);
}

sub list_network_select_options {
    my ($self) = @_;
    my $uri = $self->_path('listNetworkSelectOptions');

    return $self->client->get($uri);
}

sub list_port_select_options {
    my ($self) = @_;
    my $uri = $self->_path('listPortSelectOptions');

    return $self->client->get($uri);
}

sub move_rule_before {
    my ( $self, $selected_uuid, $target_uuid ) = @_;
    validate_uuid($selected_uuid);
    validate_uuid($target_uuid);
    my $uri = $self->_path(
        'moveRuleBefore/{selected_uuid}/{target_uuid}', selected_uuid => $selected_uuid,
        target_uuid => $target_uuid
    );

    return $self->client->post($uri);
}

sub revert {
    my ( $self, $revision ) = @_;
    my $uri = $self->_path( 'revert/{revision}', revision => $revision );

    return $self->client->post($uri);
}

sub savepoint {
    my ($self) = @_;
    my $uri = $self->_path('savepoint');

    return $self->client->post($uri);
}

sub search_rule {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchRule');

    return $self->client->get( $uri, \%params );
}

sub set_rule {
    my ( $self, $uuid, $rule_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setRule/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $rule_data );
}

sub set_settings {
    my ( $self, $settings ) = @_;
    my $uri = $self->_path('set');

    return $self->client->post( $uri, $settings );
}

sub toggle_rule {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleRule/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub toggle_rule_log {
    my ( $self, $uuid, $log ) = @_;
    validate_uuid($uuid);
    defined $log
        or croak 'toggle_rule_log requires the log parameter';
    my $uri = $self->_path( 'toggleRuleLog/{uuid}/{log}', uuid => $uuid, log => $log );

    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Role::NAT - Role for NAT controller shared rule methods

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Provides shared rule CRUD and utility methods used by the NAT controller
classes.  All methods in this section are called on the consuming object,
not on the role directly.

This role is consumed by L<WebService::OPNsense::Firewall::DNat>,
L<WebService::OPNsense::Firewall::OneToOne>,
L<WebService::OPNsense::Firewall::SourceNat>,
L<WebService::OPNsense::Firewall::Npt>, and
L<WebService::OPNsense::Firewall::Filter>.

=head1 PROVIDED METHODS

=head2 add_rule

    my $result = $ctrl->add_rule( $rule_data );

Creates NAT rule.

=head2 apply

    my $result = $ctrl->apply;
    my $result = $ctrl->apply( $rollback_revision );

Applies pending NAT rule changes.  Optionally specify a rollback revision.

=head2 cancel_rollback

    my $result = $ctrl->cancel_rollback( $revision );

Cancels a pending rollback by revision number.

=head2 del_rule

    my $result = $ctrl->del_rule( $uuid );

Deletes a NAT rule by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 get

    my $config = $ctrl->get;

Returns the full NAT configuration.

=head2 get_rule

    my $rule = $ctrl->get_rule( $uuid );

Returns a single NAT rule by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 list_categories

    my $categories = $ctrl->list_categories;

Returns a list of available rule categories.

=head2 list_network_select_options

    my $options = $ctrl->list_network_select_options;

Returns selectable network options for rule creation.

=head2 list_port_select_options

    my $options = $ctrl->list_port_select_options;

Returns selectable port options for rule creation.

=head2 move_rule_before

    my $result = $ctrl->move_rule_before( $selected_uuid, $target_uuid );

Moves a NAT rule before another rule in the rule order.  Throws if either
C<$selected_uuid> or C<$target_uuid> is not a valid UUID.

=head2 revert

    my $result = $ctrl->revert( $revision );

Reverts to a previous configuration revision.

=head2 savepoint

    my $result = $ctrl->savepoint;

Creates a configuration savepoint for rollback.

=head2 search_rule

    my $results = $ctrl->search_rule( %params );

Searches for NAT rules.  Returns a hashref with C<rows> and C<total> keys.

=head2 set_rule

    my $result = $ctrl->set_rule( $uuid, $rule_data );

Updates NAT rule.  Throws if C<$uuid> is not a valid UUID.

=head2 set_settings

    my $result = $ctrl->set_settings( $settings );

Updates the NAT configuration.

=head2 toggle_rule

    my $result = $ctrl->toggle_rule( $uuid, $enabled );

Enables or disables a NAT rule.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_rule_log

    my $result = $ctrl->toggle_rule_log( $uuid, $log );

Enables or disables logging for a NAT rule.  Throws if C<$uuid> is not a
valid UUID.  C<$log> should be C<0> or C<1>.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Firewall::DNat>,
L<WebService::OPNsense::Firewall::OneToOne>,
L<WebService::OPNsense::Firewall::SourceNat>,
L<WebService::OPNsense::Firewall::Npt>,
L<WebService::OPNsense::Firewall::Filter>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
