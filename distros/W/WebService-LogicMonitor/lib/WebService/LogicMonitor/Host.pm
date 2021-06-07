package WebService::LogicMonitor::Host;

# ABSTRACT: A LogicMonitor Host/Device object

use v5.16.3;
use DateTime;
use List::Util 1.33 'any';
use Log::Any '$log';
use Moo;

extends 'WebService::LogicMonitor::Entity';

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my $class = shift;

    my $args;
    if (ref $_[0]) {
        $args = shift;
    } else {
        my %hash = @_;
        $args = \%hash;
    }

    my %transform = (
        agentDescription      => 'agent_description',
        agentId               => 'agent_id',
        alertEnable           => 'alert_enable',
        effectiveAlertEnabled => 'effective_alert_enabled',
        deviceType            => 'device_type',
        hostName              => 'host_name',
        inSDT                 => 'in_sdt',
        isActive              => 'is_active',
        enableNetflow         => 'enable_netflow',
        netflowAgentId        => 'netflow_agent_id',
        relatedDeviceId       => 'related_device_id',
        scanConfigId          => 'scan_config_id',
        displayedAs           => 'displayed_as',
        updatedOn             => 'updated_on',
        createdOn             => 'created_on',
        fullPathInIds         => 'full_path_in_ids',
        autoPropsAssignedOn   => 'auto_props_assigned_on',
    );

    _transform_incoming_keys(\%transform, $args);
    _clean_empty_keys([qw/description link/], $args);

    return $args;
}

# host_name is the ip_address/DNS name
has [qw/host_name displayed_as/] => (is => 'rw', required  => 1);    # str
has [qw/agent_description/]      => (is => 'rw', predicate => 1);    # str

has device_type => (is => 'ro');                                     # str
has agent_id => (is => 'rw', required => 1);                         # int

has link => (is => 'rw', predicate => 1);    # str - url

has status => (is => 'ro');                  # enum dead|

has [qw/lastdatatime lastrawdatatime/] => (is => 'ro');
has enable_netflow => (is => 'rw', predicate => 1);    # bool
has [qw/netflow_agent_id related_device_id scan_config_id/] => (is => 'ro')
  ;                                                    # int
has [qw/effective_alert_enabled is_active /] => (is => 'ro');    # bool

has [qw/updated_on auto_props_assigned_on/] => (
    is     => 'ro',
    coerce => sub {
        DateTime->from_epoch(epoch => $_[0]);
    },
);


has groups => (
    is        => 'rwp',
    lazy      => 1,
    builder   => 1,
    predicate => 1,
    isa       => sub {
        unless (ref $_[0] && ref $_[0] eq 'ARRAY') {
            die 'groups should be an arrayref';
        }
    },

    # TODO allow setting an arryref of strings which will coerce to group objects
);

has _full_path_in_ids => (
    is       => 'ro',
    init_arg => 'full_path_in_ids',
    isa      => sub {
        unless (ref $_[0] && ref $_[0] eq 'ARRAY') {
            die 'full_path_in_ids should be specified as a arrayref';
        }
    },
);

sub _build_groups {
    my $self = shift;

    my @groups;

    foreach my $full_path (@{$self->_full_path_in_ids}) {
        my $hg_id = $full_path->[-1];
        my $hg = $self->_lm->get_groups(id => $hg_id);
        push @groups, $hg->[0];
    }
    return \@groups;
}


has datasource_instances => (is => 'ro', lazy => 1, default => sub {{}});


sub create {
    my $self = shift;

    if ($self->has_id) {
        die
          'This host already has an id - you cannot create an object that already exists';
    }

    # first, get the required params
    my $params = {
        hostName    => $self->host_name,
        displayedAs => $self->displayed_as,
        agentId     => $self->agent_id,
        alertEnable => $self->alert_enable,
    };

    $params->{description} = $self->description if $self->description;
    $params->{link}        = $self->link        if $self->link;

    if ($self->has_properties) {
        $self->_format_properties($params);
    }

    if ($self->has_groups) {
        my @hostgroup_ids;
        foreach my $g (@{$self->groups}) {

            # filter out any autogroups
            next if $g->applies_to;
            push @hostgroup_ids, $g->id;
        }

        $params->{hostGroupIds} = join ',', @hostgroup_ids;
    }

    my $new_host = $self->_lm->_http_get('addHost', $params);
    return WebService::LogicMonitor::Host->new($new_host);
}


sub update {
    my $self = shift;

    if (!$self->has_id) {
        die
          'This host does not have an id - you cannot update an object that has not been created';
    }

    # first, get the required params
    my $params = {
        id            => $self->id,
        opType        => 'refresh',
        hostName      => $self->host_name,
        displayedAs   => $self->displayed_as,
        agentId       => $self->agent_id,
        alertEnable   => $self->alert_enable,
        enableNetflow => $self->enable_netflow,
    };

    $params->{description} = $self->description if $self->description;
    $params->{link}        = $self->link        if $self->link;

    # get properties because they need to be formatted
    $self->_format_properties($params);

    # convert fullPathInIds to hostGroupIds
    # TODO allow user to set hostGroupIds

    my @hostgroup_ids;
    foreach my $g (@{$self->groups}) {

        # filter out any autogroups
        next if $g->applies_to;
        push @hostgroup_ids, $g->id;
    }

    $params->{hostGroupIds} = join ',', @hostgroup_ids;

    $self->_lm->_http_get('updateHost', $params);
    return;
}


sub get_datasource_instances {
    my ($self, $ds_name) = @_;
    require WebService::LogicMonitor::DataSourceInstance;
    die 'Missing datasource name' unless $ds_name;

    $log->debug("Fetching datasource instances for $ds_name");
    my $data = $self->_lm->_http_get(
        'getDataSourceInstances',
        hostId     => $self->id,
        dataSource => $ds_name,
    );

    die 'Found datasource but no items were returned' unless scalar @$data;

    my @ds_instances;
    for (@$data) {
        $_->{host_name} = $self->name;
        push @ds_instances,
          WebService::LogicMonitor::DataSourceInstance->new($_);
    }

    $self->datasource_instances->{$ds_name} = \@ds_instances;
    return \@ds_instances;
}

sub get_alerts {
    my $self = shift;
    return $self->_lm->get_alerts(
        host_id => $self->id,
        @_,
    );
}


sub add_to_group {
    my ($self, $group) = @_;

    # first make sure we are not already in the group
    my $full_path = !ref $group ? $group : $group->full_path;

    if (any { $_->full_path eq $full_path } @{$self->groups}) {
        die "Host is already in group [$group]";
    }

    # if we get a string, try to lookup the group for it
    if (!ref $group) {
        my $groups = $self->_lm->get_groups(fullPath => $group)
          or die "No such group found";
        $group = shift @$groups;
    }

    return push @{$self->groups}, $group;
}


sub remove_from_group {
    my ($self, $group) = @_;
    my $full_path = !ref $group ? $group : $group->full_path;
    my @new_groups = grep { $_->full_path ne $full_path } @{$self->groups};
    return $self->_set_groups(\@new_groups);
}


sub delete {
    my $self = shift;

    if (!$self->has_id) {
        die
          'This host does not have an id - you cannot remove object that has not been created';
    }

    $self->_lm->_http_get(
        'deleteHost',
        hostId           => $self->id,
        deleteFromSystem => 1
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Host - A LogicMonitor Host/Device object

=head1 VERSION

version 0.211560

=head1 ATTRIBUTES

=head2 C<groups>

Array of L<WebService::LogicMonitor::Group> groups which this host is a
member of.

Whilst you can modify the array directly, you should use the L</add_to_group>
and </remove_from_group> methods instead.

=head2 C<datasource_instances>

A cache of any datasource instances that are retrieved.

=head1 METHODS

=head2 C<create>

Create this host on LogicMonitor.

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#add>

=head2 C<update>

Commit this host to LogicMonitor.

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#update>

=head2 C<get_datasource_instances(Str datasource_name)>

Return an array of instances of a datasource on this host. The array will also
be cached in L</datasource_instances>.

LogicMonitor's API does not list the datasources which actually apply to a host,
or even which datasources are available on your account, so you must know in
advance which datasource you want to retrieve.

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#instances>

=head2 C<add_to_group($group)>

Add this host to the specified group. C<$group> can be either a string
representing a group's full path, e.g. C<'/AWS/us-east-1/WebServers'>, or
a L<WebService::LogicMonitor::Group> object.

=head2 C<remove_from_group($group)>

Remove this host from the specified group. C<$group> can be either a string
representing a group's full path, e.g. C<'/AWS/us-east-1/WebServers'>, or
a L<WebService::LogicMonitor::Group> object.

=head2 C<delete>

Remove this host from LogicMonitor.

L<http://help.logicmonitor.com/developers-guide/manage-hosts/#delete>

This differes from LoMo's API in that it will always remove a host from the
system. If you want to remove a host from a group, use L</remove_from_group>.

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
