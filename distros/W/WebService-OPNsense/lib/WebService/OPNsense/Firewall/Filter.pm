#!/bin/false
# ABSTRACT: Firewall filter rule controller
# PODNAME: WebService::OPNsense::Firewall::Filter
use strictures 2;

package WebService::OPNsense::Firewall::Filter;
$WebService::OPNsense::Firewall::Filter::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/filter';
}

with 'WebService::OPNsense::Firewall::Role::NAT';

sub download_rules {
    my ($self) = @_;
    my $uri = $self->_path('downloadRules');

    return $self->client->get($uri);
}

sub upload_rules {
    my ( $self, $rules_data ) = @_;
    my $uri = $self->_path('uploadRules');

    return $self->client->post( $uri, $rules_data );
}

sub get_interface_list {
    my ($self) = @_;
    my $uri = $self->_path('getInterfaceList');

    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Filter - Firewall filter rule controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $ACTION_PASS $PROTO_TCP $OPN_ENABLED );

    my $filter = $opn->firewall_filter;

    # Search for rules
    my $rules = $filter->search_rule(
        current => 1,
        rowCount => 50,
    );

    # Add a new rule
    my $result = $filter->add_rule({
        rule => {
            action          => $ACTION_PASS,
            description     => 'Allow HTTP',
            destination_port => '80',
            enabled         => $OPN_ENABLED,
            protocol        => $PROTO_TCP,
            source_net      => 'any',
        },
    });

=head1 DESCRIPTION

Manages firewall filter rules.

=head1 CONSTANTS

The following constants are available from
L<WebService::OPNsense::Constants>.

=head2 Actions

Use when setting the C<action> field in a rule.

=over

=item C<$ACTION_BLOCK>

=item C<$ACTION_PASS>

=item C<$ACTION_REJECT>

=back

=head2 Address families

Use when setting the C<address_family> field.

=over

=item C<$AF_INET>

=item C<$AF_INET6>

=item C<$AF_INET46>

=back

=head2 Directions

Use when setting the C<direction> field.

=over

=item C<$DIRECTION_ANY>

=item C<$DIRECTION_IN>

=item C<$DIRECTION_OUT>

=back

=head2 Gateway

Use when setting the C<gateway> field.

=over

=item C<$GATEWAY_DEFAULT>

=back

=head2 Interface names

Use when setting the C<interface> field.

=over

=item C<$INTERFACE_WAN>

=item C<$INTERFACE_LAN>

=item C<$INTERFACE_DMZ>

=item C<$INTERFACE_GUEST>

=item C<$INTERFACE_LOOPBACK>

=item C<$INTERFACE_OPT1> through C<$INTERFACE_OPT9>

=back

=head2 Protocols

Use when setting the C<protocol> field.

=over

=item C<$PROTO_ANY>

=item C<$PROTO_ESP>

=item C<$PROTO_GRE>

=item C<$PROTO_ICMP>

=item C<$PROTO_OSPF>

=item C<$PROTO_PIM>

=item C<$PROTO_SCTP>

=item C<$PROTO_TCP>

=item C<$PROTO_TCP_UDP>

=item C<$PROTO_UDP>

=item C<$PROTO_VRRP>

=back

=head2 Rule sequence positions

Use when setting the C<sequence> field.

=over

=item C<$SEQ_EARLY>

=item C<$SEQ_FIRST>

=item C<$SEQ_FLOATING>

=item C<$SEQ_LAST>

=back

=head2 SNAT modes

Use when setting the C<snat_mode> field.

=over

=item C<$SNAT_ADVANCED>

=item C<$SNAT_AUTOMATIC>

=item C<$SNAT_DISABLED>

=item C<$SNAT_HYBRID>

=back

=head2 State types

Use when setting the C<state_type> field.

=over

=item C<$STATETYPE_KEEP>

=item C<$STATETYPE_MODULATE>

=item C<$STATETYPE_NONE>

=item C<$STATETYPE_SLOPPY>

=item C<$STATETYPE_SYNPROXY>

=back

=head2 TCP flags

Use when setting the C<tcp_flags_*> fields.

=over

=item C<$TCP_FLAG_ACK>

=item C<$TCP_FLAG_CWR>

=item C<$TCP_FLAG_ECE>

=item C<$TCP_FLAG_FIN>

=item C<$TCP_FLAG_PSH>

=item C<$TCP_FLAG_RST>

=item C<$TCP_FLAG_SYN>

=item C<$TCP_FLAG_URG>

=back

=head1 METHODS

=head2 search_rule

    my $results = $filter->search_rule(%params);

Searches for firewall rules.  Returns the raw API response hashref.

=head2 get_rule

    my $rule = $filter->get_rule($uuid);

Returns a single rule by UUID.

=head2 add_rule

    my $result = $filter->add_rule($rule_data);

Creates firewall rule.  C<$rule_data> should be a hashref matching the
OPNsense API format (e.g. C<< { rule => { ... } } >>).

=head2 set_rule

    my $result = $filter->set_rule($uuid, $rule_data);

Updates rule.

=head2 del_rule

    my $result = $filter->del_rule($uuid);

Deletes a rule by UUID.

=head2 toggle_rule

    my $result = $filter->toggle_rule($uuid, $enabled);

Enables or disables a rule.

=head2 apply

    my $result = $filter->apply;
    my $result = $filter->apply($rollback_revision);

Applies pending changes.  Optionally specify a rollback revision.

=head2 savepoint

    my $result = $filter->savepoint;

Creates a configuration savepoint for rollback.

=head2 cancel_rollback

    my $result = $filter->cancel_rollback($revision);

Cancels a pending rollback.

=head2 move_rule_before

    my $result = $filter->move_rule_before($selected_uuid, $target_uuid);

Moves a rule before another rule in the rule order.

=head2 toggle_rule_log

    my $result = $filter->toggle_rule_log($uuid, $log);

Toggles the log flag for a rule.  C<$log> should be C<0> or C<1>.

=head2 download_rules

    my $rules = $filter->download_rules;

Downloads all firewall rules.

=head2 upload_rules

    my $result = $filter->upload_rules($rules_data);

Uploads firewall rules from a data structure.

=head2 get_interface_list

    my $interfaces = $filter->get_interface_list;

Returns a list of available network interfaces.

=head2 list_categories

    my $categories = $filter->list_categories;

Returns a list of available rule categories.

=head2 list_network_select_options

    my $options = $filter->list_network_select_options;

Returns selectable network options for rule creation.

=head2 list_port_select_options

    my $options = $filter->list_port_select_options;

Returns selectable port options for rule creation.

=head2 revert

    my $result = $filter->revert( $revision );

Reverts to a previous configuration revision.

=head2 get

    my $config = $filter->get;

Returns the full firewall configuration.

=head2 set_settings

    my $result = $filter->set_settings( $settings );

Updates the firewall configuration.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Firewall::Role::NAT>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
