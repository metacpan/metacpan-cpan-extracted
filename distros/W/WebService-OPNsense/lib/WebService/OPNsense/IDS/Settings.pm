#!/bin/false
# ABSTRACT: IDS settings controller
# PODNAME: WebService::OPNsense::IDS::Settings
use strictures 2;

package WebService::OPNsense::IDS::Settings;
$WebService::OPNsense::IDS::Settings::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ids/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub list_rulesets {
    my ($self) = @_;
    return $self->client->get( $self->_path('listRulesets') );
}

sub get_ruleset {
    my ( $self, $id ) = @_;
    return $self->client->get( $self->_path( 'getRuleset/{id}', id => $id ) );
}

sub set_ruleset {
    my ( $self, $filename ) = @_;
    return $self->client->post( $self->_path( 'setRuleset/{filename}', filename => $filename ) );
}

sub get_ruleset_properties {
    my ($self) = @_;
    return $self->client->get( $self->_path('getRulesetProperties') );
}

sub set_ruleset_properties {
    my ( $self, $properties_data ) = @_;
    return $self->client->post(
        $self->_path('setRulesetProperties'), $properties_data,
    );
}

sub toggle_ruleset {
    my ( $self, $filenames ) = @_;
    return $self->client->post( $self->_path( 'toggleRuleset/{filenames}', filenames => $filenames ) );
}

sub list_rule_metadata {
    my ($self) = @_;
    return $self->client->get( $self->_path('listRuleMetadata') );
}

sub get_rule_info {
    my ( $self, $sid ) = @_;
    return $self->client->get( $self->_path( 'getRuleInfo/{sid}', sid => $sid ) );
}

sub toggle_rule {
    my ( $self, $sids, $enabled ) = @_;
    return $self->client->post( $self->_path( 'toggleRule/{sids}/{enabled}', sids => $sids, enabled => $enabled ) );
}

sub set_rule {
    my ( $self, $sid ) = @_;
    return $self->client->post( $self->_path( 'setRule/{sid}', sid => $sid ) );
}

sub search_installed_rules {
    my ( $self, %params ) = @_;
    return $self->client->post( $self->_path('searchInstalledRules'), \%params );
}

sub search_policy {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchPolicy'), \%params );
}

sub get_policy {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getPolicy/{uuid}', uuid => $uuid ) );
}

sub add_policy {
    my ( $self, $policy_data ) = @_;
    return $self->client->post( $self->_path('addPolicy'), $policy_data );
}

sub set_policy {
    my ( $self, $uuid, $policy_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'setPolicy/{uuid}', uuid => $uuid ), $policy_data,
    );
}

sub del_policy {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delPolicy/{uuid}', uuid => $uuid ) );
}

sub toggle_policy {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'togglePolicy/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub search_policy_rule {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchPolicyRule'), \%params );
}

sub get_policy_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getPolicyRule/{uuid}', uuid => $uuid ) );
}

sub add_policy_rule {
    my ( $self, $rule_data ) = @_;
    return $self->client->post( $self->_path('addPolicyRule'), $rule_data );
}

sub set_policy_rule {
    my ( $self, $uuid, $rule_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'setPolicyRule/{uuid}', uuid => $uuid ), $rule_data,
    );
}

sub del_policy_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delPolicyRule/{uuid}', uuid => $uuid ) );
}

sub toggle_policy_rule {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'togglePolicyRule/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub search_user_rule {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchUserRule'), \%params );
}

sub get_user_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getUserRule/{uuid}', uuid => $uuid ) );
}

sub add_user_rule {
    my ( $self, $rule_data ) = @_;
    return $self->client->post( $self->_path('addUserRule'), $rule_data );
}

sub set_user_rule {
    my ( $self, $uuid, $rule_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'setUserRule/{uuid}', uuid => $uuid ), $rule_data,
    );
}

sub del_user_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delUserRule/{uuid}', uuid => $uuid ) );
}

sub toggle_user_rule {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleUserRule/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IDS::Settings - IDS settings controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $ids_settings = $opn->ids_settings;

    my $settings = $ids_settings->get;

=head1 DESCRIPTION

Manages IDS/IPS settings, rulesets, policies, and user
rules.

=head1 NAME

WebService::OPNsense::IDS::Settings - IDS settings controller

=head1 METHODS

=head2 get

    my $settings = $ids_settings->get;

Returns the current IDS settings.

=head2 set_settings

    my $result = $ids_settings->set_settings($settings_data);

Updates IDS settings.

=head2 list_rulesets

    my $rulesets = $ids_settings->list_rulesets;

Lists available rulesets.

=head2 get_ruleset

    my $ruleset = $ids_settings->get_ruleset($id);

Returns a ruleset by ID.

=head2 set_ruleset

    my $result = $ids_settings->set_ruleset($filename);

Updates a ruleset by filename.

=head2 get_ruleset_properties

    my $properties = $ids_settings->get_ruleset_properties;

Returns ruleset properties.

=head2 set_ruleset_properties

    my $result = $ids_settings->set_ruleset_properties($properties_data);

Updates ruleset properties.

=head2 toggle_ruleset

    my $result = $ids_settings->toggle_ruleset($filenames);

Enables or disables rulesets by filename(s).

=head2 list_rule_metadata

    my $metadata = $ids_settings->list_rule_metadata;

Lists rule metadata.

=head2 get_rule_info

    my $info = $ids_settings->get_rule_info($sid);

Returns rule info by SID.

=head2 toggle_rule

    my $result = $ids_settings->toggle_rule($sids, $enabled);

Enables or disables rules by SID(s).

=head2 set_rule

    my $result = $ids_settings->set_rule($sid);

Updates a rule by SID.

=head2 search_installed_rules

    my $rules = $ids_settings->search_installed_rules(%params);

Searches installed rules.

=head2 search_policy

    my $policies = $ids_settings->search_policy(%params);

Searches for policies.

=head2 get_policy

    my $policy = $ids_settings->get_policy($uuid);

Returns a single policy by UUID.

=head2 add_policy

    my $result = $ids_settings->add_policy($policy_data);

Creates a new policy.

=head2 set_policy

    my $result = $ids_settings->set_policy($uuid, $policy_data);

Updates an existing policy.

=head2 del_policy

    my $result = $ids_settings->del_policy($uuid);

Deletes a policy by UUID.

=head2 toggle_policy

    my $result = $ids_settings->toggle_policy($uuid, $enabled);

Enables or disables a policy.

=head2 search_policy_rule

    my $rules = $ids_settings->search_policy_rule(%params);

Searches for policy rules.

=head2 get_policy_rule

    my $rule = $ids_settings->get_policy_rule($uuid);

Returns a single policy rule by UUID.

=head2 add_policy_rule

    my $result = $ids_settings->add_policy_rule($rule_data);

Creates a new policy rule.

=head2 set_policy_rule

    my $result = $ids_settings->set_policy_rule($uuid, $rule_data);

Updates an existing policy rule.

=head2 del_policy_rule

    my $result = $ids_settings->del_policy_rule($uuid);

Deletes a policy rule by UUID.

=head2 toggle_policy_rule

    my $result = $ids_settings->toggle_policy_rule($uuid, $enabled);

Enables or disables a policy rule.

=head2 search_user_rule

    my $rules = $ids_settings->search_user_rule(%params);

Searches for user rules.

=head2 get_user_rule

    my $rule = $ids_settings->get_user_rule($uuid);

Returns a single user rule by UUID.

=head2 add_user_rule

    my $result = $ids_settings->add_user_rule($rule_data);

Creates a new user rule.

=head2 set_user_rule

    my $result = $ids_settings->set_user_rule($uuid, $rule_data);

Updates an existing user rule.

=head2 del_user_rule

    my $result = $ids_settings->del_user_rule($uuid);

Deletes a user rule by UUID.

=head2 toggle_user_rule

    my $result = $ids_settings->toggle_user_rule($uuid, $enabled);

Enables or disables a user rule.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
