package WebService::LogicMonitor::Alert;

# ABSTRACT: A LogicMonitor alert

use v5.16.3;
use Log::Any '$log';
use WebService::LogicMonitor::Group;
use Moo;

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        ackComment               => 'ack_comment',
        ackedBy                  => 'acked_by',
        ackedOn                  => 'acked_on',
        endOn                    => 'end_on',
        startOn                  => 'start_on',
        hostId                   => 'host_id',
        alertEscalationChainName => 'alert_escalation_chain_name',
        alertRuleName            => 'alert_rule_name',
        dataPoint                => 'datapoint',
        dataSource               => 'datasource',
        dataSource               => 'datasource_id',
        dataSourceInstance       => 'datasource_instance',
        dataSourceInstanceId     => 'datasource_instance_id',
        hostDataSourceId         => 'host_datasource_id',
        hostGroups               => 'groups',
    );

    _transform_incoming_keys(\%transform, $args);
    _clean_empty_keys([
            qw/ack_comment acked_on_local acked_by alert_escalation_chain_name alert_rule_name/
        ],
        $args
    );

    return $args;
}

has [qw/id host_id datasource_id datasource_instance_id host_datasource_id/] =>
  (is => 'ro');    # int

has [
    qw/ack_comment acked_by acked_on_local datapoint datasource_instance datasource host alert_escalation_chain_name thresholds duration/
] => (is => 'ro');    # str

has level => (is => 'ro');    # enum critical|warning|error
has type  => (is => 'ro');    # enum
has value => (is => 'ro');    # float

has [qw/acked active/] => (is => 'ro');    # bool

has [qw/acked_on end_on start_on/] => (
    is     => 'ro',
    coerce => sub {
        DateTime->from_epoch(epoch => $_[0]);
    },
);

# is this useful?
has groups => (is => 'ro');                # arrayref of WSLOMO::Group

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Alert - A LogicMonitor alert

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
