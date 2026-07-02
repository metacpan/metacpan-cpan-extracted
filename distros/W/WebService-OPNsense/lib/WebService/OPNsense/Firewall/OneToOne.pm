#!/bin/false
# ABSTRACT: Firewall one-to-one NAT rule controller
# PODNAME: WebService::OPNsense::Firewall::OneToOne
use strictures 2;

package WebService::OPNsense::Firewall::OneToOne;
$WebService::OPNsense::Firewall::OneToOne::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/one_to_one';
}

with 'WebService::OPNsense::Firewall::Role::NAT';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::OneToOne - Firewall one-to-one NAT rule controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $ONETOONE_NAT $PROTO_ANY $OPN_ENABLED );

    my $one_to_one = $opn->firewall_one_to_one;

    # List one-to-one NAT rules
    my $rules = $one_to_one->search_rule;

    # Create a one-to-one NAT rule
    $one_to_one->add_rule({
        rule => {
            description => 'Map public IP to internal server',
            type        => $ONETOONE_NAT,
            protocol    => $PROTO_ANY,
            external    => '203.0.113.10',
            internal    => '192.0.2.10',
            enabled     => $OPN_ENABLED,
        },
    });

=head1 DESCRIPTION

Manages one-to-one NAT rules on the OPNsense firewall.
All methods are provided by L<WebService::OPNsense::Firewall::Role::NAT>.

=head1 CONSTANTS

One-to-one NAT type and protocol constants are available from
L<WebService::OPNsense::Constants>:

=over

=item C<$ONETOONE_NAT>

=item C<$ONETOONE_BINAT>

=item C<$PROTO_TCP>

=item C<$PROTO_UDP>

=item C<$PROTO_ANY>

=item C<$AF_INET>

=item C<$AF_INET6>

=back

Use them when setting the C<type>, C<protocol>, or C<address_family> fields.

=head1 SEE ALSO

L<WebService::OPNsense::Firewall::Role::NAT>

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_rule

    my $results = $ctrl->search_rule( %params );

Searches for 1:1 NAT rules.

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
