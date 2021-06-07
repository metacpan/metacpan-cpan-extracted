# NAME

WebService::LogicMonitor - Interact with LogicMonitor's API

# VERSION

version 0.211560

# SYNOPSIS

    use v5.16;
    use warnings;
    use Try::Tiny;
    use WebService::LogicMonitor;

    # find a hostgroup by name, iterate through its child groups
    # and check the status of a datasource instance

    my $lm = WebService::LogicMonitor->new(
        username => $ENV{LOGICMONITOR_USER},
        password => $ENV{LOGICMONITOR_PASS},
        company  => $ENV{LOGICMONITOR_COMPANY},
    );

    my $top_group_name = shift || die "What group?\n";
    my $datasource     = shift || 'Ping';

    sub recurse_group {
        my $group = shift;
        foreach my $entity (@{$group->children}) {
            if ($entity->is_group) {
                say 'GROUP: ' . $entity->name;
                recurse_group($entity);
            } elsif ($entity->is_host) {
                say '  HOST: ' . $entity->host_name;
                my $instances = try {
                    $entity->get_datasource_instances($datasource);
                } catch {
                    say "Failed to retrieve data source instances: " . $_;
                    next;
                };

                next unless $instances;
                # assume only one instance
                my $instance = shift @$instances;
                say '    datasource status: '
                  . ($instance->enabled ? 'enabled' : 'disabled');
                say '    alert status: '
                  . ($instance->alert_enable ? 'enabled' : 'disabled');
            }

        }
    }

    my $groups = $lm->get_groups(name => $top_group_name);
    recurse_group(shift @$groups);

# DESCRIPTION

LogicMonitor is a SaaS infrastructure monitoring provider. They provide an RPC
API which provides most of functionality of their web GUI (with the unfortunate
omission of managing DataSources).

They have recently started a REST API which covers a different set of functionality.

This module puts an OO wrapper around the RPC API in what is a hopefully a much
more convenient and user-friendly manner.

**HOWEVER** the API provided by this module is not considered stable and will
almost certainly have some changes before version 1.0.

# ATTRIBUTES

## `company`, `username`, `password`

The CUP authentication details for your LogicMonitor account. See
[http://help.logicmonitor.com/developers-guide/authenticating-requests/](http://help.logicmonitor.com/developers-guide/authenticating-requests/)

# METHODS

## `get_escalation_chains`

Returns an arrayref of all available escalation chains.

[http://help.logicmonitor.com/developers-guide/manage-escalation-chains/#get1](http://help.logicmonitor.com/developers-guide/manage-escalation-chains/#get1)

## `get_escalation_chain_by_name(Str $name)`

Convenience wrapper aroung ["get\_escalation\_chains"](#get_escalation_chains) which only returns chains
where a `name eq $name`.

## `get_accounts`

Retrieves a complete list of accounts as an arrayref.

[http://help.logicmonitor.com/developers-guide/manage-user-accounts/#getAccounts](http://help.logicmonitor.com/developers-guide/manage-user-accounts/#getAccounts)

## `get_account_by_email(Str $email)`

Convenience wrapper aroung ["get\_accounts"](#get_accounts) which only returns accounts
matching $email.

## `get_account_by_username(Str $username)`

Convenience wrapper aroung ["get\_accounts"](#get_accounts) which only returns accounts
matching `$username`.

## `get_data`

## `get_alerts(...)`

Returns an arrayref of alerts or undef if none found.

See [http://help.logicmonitor.com/developers-guide/manage-alerts/](http://help.logicmonitor.com/developers-guide/manage-alerts/) for
what parameters are available to filter the alerts.

## `add_host`

Creates and returns a new host. Shortcut for [WebService::LogicMonitor::Host](https://metacpan.org/pod/WebService%3A%3ALogicMonitor%3A%3AHost)
`new` and `create`

## `delete_host(Str displayname)`

Deletes a host identified by its displayname. Convenience wrapper around
["get\_host" in WebService::LogicMonitor](https://metacpan.org/pod/WebService%3A%3ALogicMonitor#get_host) and ["delete" in WebService::LogicMonitor::Host](https://metacpan.org/pod/WebService%3A%3ALogicMonitor%3A%3AHost#delete).

## `get_host(Str displayname)`

Return a host.

[http://help.logicmonitor.com/developers-guide/manage-hosts/#get1](http://help.logicmonitor.com/developers-guide/manage-hosts/#get1)

## `get_hosts(Int hostgroupid)`

Return an array of hosts in the group specified by `group_id`

[http://help.logicmonitor.com/developers-guide/manage-hosts/#get1](http://help.logicmonitor.com/developers-guide/manage-hosts/#get1)

In scalar context, will return an arrayref of hosts in the group.

In array context, will return the same arrayref plus a hashref of the group.

## `get_all_hosts`

Convenience wrapper around ["get\_hosts"](#get_hosts) which returns all hosts. **BEWARE** This will
probably take a while.

## `get_groups(Str|Regexp filter?)`

Returns an arrayref of all host groups.

[http://help.logicmonitor.com/developers-guide/manage-host-group/#list](http://help.logicmonitor.com/developers-guide/manage-host-group/#list)

Optionally takes a string or regexp as an argument. Only those hostgroups with names
matching the argument will be returned, or undef if there are none. If the arg is a string,
it must be an exact match with `eq`.

## `get_sdts(Str key?, Int id?)`

Returns an array of SDT hashes. With no args, it will return all SDTs in the
account. See the LoMo docs for details on what keys are supported.

[http://help.logicmonitor.com/developers-guide/schedule-down-time/get-sdt-data/](http://help.logicmonitor.com/developers-guide/schedule-down-time/get-sdt-data/)

## `set_sdt(Str entity, Int|Str id, start =` DateTime|Str, end => DateTime|Str, comment => Str?)>

Sets SDT for an entity. Entity can be

    Host
    HostGroup
    HostDataSource
    DataSourceInstance
    HostDataSourceInstanceGroup
    Agent

The id for Host can be either an id number or hostname string.

To simplify calling this we take two keys, `start` and `end` which must
be either [DateTime](https://metacpan.org/pod/DateTime) objects or ISO8601 strings parseable by
[DateTime::Format::ISO8601](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AISO8601).

[http://help.logicmonitor.com/developers-guide/schedule-down-time/set-sdt-data/](http://help.logicmonitor.com/developers-guide/schedule-down-time/set-sdt-data/)

    $lomo->set_sdt(
        Host    => 'somehost',
        start   => '20151101T1000',
        end     => '20151101T1350',
        comment => 'Important maintenance',
    );

## `set_quick_sdt(Str entity, Int|Str id, $hours, ...)`

Wrapper around ["set\_sdt"](#set_sdt) to quickly set SDT starting immediately. The lenght
of the SDT can be specfied as hours, minutes or any other unit supported by
[https://metacpan.org/pod/DateTime#Adding-a-Duration-to-a-Datetime](https://metacpan.org/pod/DateTime#Adding-a-Duration-to-a-Datetime), but only
one unit can be specified.

    $lomo->set_quick_sdt(Host => 'somehost', minutes => 30, comment => 'Reboot to annoy support');
    $lomo->set_quick_sdt(HostGroup => 456, hours => 6);

# SEE ALSO

[LogicMonitor](http://www.logicmonitor.com/)

# AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
