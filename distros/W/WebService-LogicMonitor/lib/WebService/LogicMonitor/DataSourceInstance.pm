package WebService::LogicMonitor::DataSourceInstance;

# ABSTRACT: A LogicMonitor DataSource instance

use v5.16.3;
use Log::Any '$log';
use Moo;

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        alertEnable           => 'alert_enable',
        dataSourceDisplayedAs => 'datasource_displayed_as',
        dataSourceId          => 'datasource_id',
        discoveryInstanceId   => 'discovery_instance_id',
        hostDataSourceId      => 'host_datasource_id',
        hasAlert              => 'has_alert',
        hasGraph              => 'has_graph',
        hasUnConfirmedAlert   => 'has_unconfirmed_alert',
        hostId                => 'host_id',
    );

    _transform_incoming_keys(\%transform, $args);
    _clean_empty_keys([qw/description wildalias wildvalue wildvalue2/], $args);

    return $args;
}

has id => (is => 'ro');    # int

has [qw/name host_name datasource_displayed_as description/] => (is => 'ro')
  ;                        # str

has [qw/alert_enable enabled has_alert has_graph has_unconfirmed_alert/] =>
  (is => 'ro');            # bool

has [qw/datasource_id discovery_instance_id host_datasource_id host_id/] =>
  (is => 'ro');            # int

has [qw/wildalias wildvalue wildvalue2/] => (is => 'ro');    # str

sub get_data {
    my $self = shift;

    return $self->_lm->get_data(
        host                => $self->host_name,
        datasource_instance => $self->name,
        @_,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::DataSourceInstance - A LogicMonitor DataSource instance

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
