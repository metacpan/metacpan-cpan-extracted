#!/bin/false
# ABSTRACT: Firewall port forward (DNAT) rule controller
# PODNAME: WebService::OPNsense::Firewall::DNat
use strictures 2;

package WebService::OPNsense::Firewall::DNat;
$WebService::OPNsense::Firewall::DNat::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/d_nat';
}

with 'WebService::OPNsense::Firewall::Role::NAT';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::DNat - Firewall port forward (DNAT) rule controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $PROTO_TCP $OPN_ENABLED );

    my $d_nat = $opn->firewall_d_nat;

    # List port forward rules
    my $rules = $d_nat->search_rule;

    # Create a port forward rule
    $d_nat->add_rule({
        rule => {
            description      => 'Forward HTTP to internal server',
            protocol         => $PROTO_TCP,
            destination_net  => '203.0.113.1',
            destination_port => '80',
            target           => '192.0.2.10',
            local_port       => '80',
            enabled          => $OPN_ENABLED,
        },
    });

=head1 DESCRIPTION

Manages destination NAT (port forward) rules on the OPNsense firewall.
All methods are provided by L<WebService::OPNsense::Firewall::Role::NAT>.

=head1 CONSTANTS

Protocol constants are available from L<WebService::OPNsense::Constants>:

=over

=item C<$PROTO_TCP>

=item C<$PROTO_UDP>

=item C<$PROTO_TCP_UDP>

=item C<$PROTO_ICMP>

=item C<$PROTO_ANY>

=back

Use them when setting the C<protocol> field in a rule.

=head1 SEE ALSO

L<WebService::OPNsense::Firewall::Role::NAT>

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_rule

    my $results = $ctrl->search_rule( %params );

Searches for NAT rules.

=head2 get_rule

    my $rule = $ctrl->get_rule( $uuid );

Returns a single rule by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_rule

    my $result = $ctrl->add_rule( $rule_data );

Creates rule.

=head2 set_rule

    my $result = $ctrl->set_rule( $uuid, $rule_data );

Updates rule.  Throws if C<$uuid> is not a valid UUID.

=head2 del_rule

    my $result = $ctrl->del_rule( $uuid );

Deletes a rule by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_rule

    my $result = $ctrl->toggle_rule( $uuid, $enabled );

Enables or disables a rule.  Throws if C<$uuid> is not a valid UUID.

=head2 toggle_rule_log

    my $result = $ctrl->toggle_rule_log( $uuid, $log );

Toggles the log flag for a rule.  Throws if C<$uuid> is not a valid UUID.

=head2 apply

    my $result = $ctrl->apply;
    my $result = $ctrl->apply( $rollback_revision );

Applies pending changes.

=head2 savepoint

    my $result = $ctrl->savepoint;

Creates a configuration savepoint for rollback.

=head2 cancel_rollback

    my $result = $ctrl->cancel_rollback( $revision );

Cancels a pending rollback.

=head2 move_rule_before

    my $result = $ctrl->move_rule_before( $selected_uuid, $target_uuid );

Moves a rule before another rule.  Throws if either UUID is invalid.

=head2 revert

    my $result = $ctrl->revert( $revision );

Reverts to a previous configuration revision.

=head2 get

    my $config = $ctrl->get;

Returns the full configuration.

=head2 set_settings

    my $result = $ctrl->set_settings( $settings );

Updates the configuration.

=head2 list_categories

    my $categories = $ctrl->list_categories;

Returns a list of available rule categories.

=head2 list_network_select_options

    my $options = $ctrl->list_network_select_options;

Returns selectable network options for rule creation.

=head2 list_port_select_options

    my $options = $ctrl->list_port_select_options;

Returns selectable port options for rule creation.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
