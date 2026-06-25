#!/bin/false
# ABSTRACT: Firewall filter rule controller
# PODNAME: WebService::OPNsense::Firewall::Filter
use strictures 2;

package WebService::OPNsense::Firewall::Filter;
$WebService::OPNsense::Firewall::Filter::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/filter';
}

with 'WebService::OPNsense::Firewall::Role::NAT';

sub download_rules {
    my ($self) = @_;
    return $self->client->get( $self->_path('downloadRules') );
}

sub upload_rules {
    my ( $self, $rules_data ) = @_;
    return $self->client->post( $self->_path('uploadRules'), $rules_data );
}

sub get_interface_list {
    my ($self) = @_;
    return $self->client->get( $self->_path('getInterfaceList') );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Filter - Firewall filter rule controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $filter = $opn->firewall_filter;

    # Search for rules
    my $rules = $filter->search_rule(
        current => 1,
        rowCount => 50,
    );

    # Add a new rule
    my $result = $filter->add_rule({
        rule => {
            description => 'Allow HTTP',
            action      => 'pass',
            protocol    => 'TCP',
            source_net  => 'any',
            destination_port => '80',
        },
    });

=head1 DESCRIPTION

Manages firewall filter rules.

=head1 NAME

WebService::OPNsense::Firewall::Filter - Firewall filter rule controller

=head1 CONSTANTS

SNAT mode constants are available from L<WebService::OPNsense::Constants>:

=over

=item C<$SNAT_ADVANCED>

=item C<$SNAT_AUTOMATIC>

=item C<$SNAT_DISABLED>

=item C<$SNAT_HYBRID>

=back

Use them when setting the SNAT mode via the C<snat_mode> field.

=head1 METHODS

=head2 search_rule

    my $results = $filter->search_rule(%params);

Searches for firewall rules.  Returns the raw API response hashref.

=head2 get_rule

    my $rule = $filter->get_rule($uuid);

Returns a single rule by UUID.

=head2 add_rule

    my $result = $filter->add_rule($rule_data);

Creates a new firewall rule.  C<$rule_data> should be a hashref matching the
OPNsense API format (e.g. C<< { rule => { ... } } >>).

=head2 set_rule

    my $result = $filter->set_rule($uuid, $rule_data);

Updates an existing rule.

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

=for Pod::Coverage _api_path _path client search_rule get_rule add_rule set_rule del_rule
toggle_rule toggle_rule_log move_rule_before apply savepoint cancel_rollback revert
set_settings get list_categories list_network_select_options list_port_select_options

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
