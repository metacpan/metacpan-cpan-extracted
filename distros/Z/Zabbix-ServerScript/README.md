# NAME

Zabbix::ServerScript - Simplify your Zabbix server scripts' environment.

# SYNOPSIS

    #!/usr/bin/perl
    
    use strict;
    use warnings;
    use utf8;
    use Zabbix::ServerScript;
    
    my $opt = {
        id => 1,
    };
    
    my @opt_specs = qw(
        id=i
    );
    
    sub main {
        Zabbix::ServerScript::init($opt, @opt_specs);
        Zabbix::ServerScript::return_value(1);
    }

    main();

# DESCRIPTION

Zabbix::ServerScript is a module to simplify writing new scripts for Zabbix server: external scripts, alert scripts, utils, etc.

# SUBROUTINES

## init($opt, @opt\_specs)

Initializes variables, sets logger, API, etc.

If specified, the first argument must be hashref, which can have the following keys:

        $opt = {
                config => q(path/to/local/config.yaml),
                console => 0,                           # should the script log to STDERR or not
                verbose => 0,                           # increase verbosity. By default, script will log only WARN messages and above.
                debug => 0,                             # Enable debug mode.
                logger => q(Zabbix.ServerScript),       # Log4perl logger name
                api => q(),                             # name of Zabbix API instance in global config
                id => q(),                              # unique identifier of what is being done, e.g.: database being checked
                unique => 0,                            # only one instance for each $opt->{id} is allowed
                daemon => 0,                            # daemonize during initialization. See Proc::Damon for details
        }

If specified, the 2nd argument must be array of options descriptions, as for Getopt::Long::GetOptions.

The following options descrtiptions are included by default (see their meanings above):

        verbose|v+ # --verbose (supports bundling, e.g. -vvv)
        debug
        daemon
        console

Initializes the following global variables: 

- $logger

    Log4perl instance

- $config 

    hashref contais both local (script-specific) and global config data.

    Default global config is located at Zabbix/ServerScript/DefaultConfig.pm.

    User can generate its own global config and store it into Zabbix/ServerScript/Config.pm. Config.pm is preferred over DefaultConfig.pm.

    Global config data can be accessed through $Zabbix::ServerScript::Config and $config->{global} variables.

    Script-specific config is searched within $Zabbix::ServerScript::Config->{config\_dir} path. Only YAML is currently supported for script-specific configs.

            $config = {
                    global => {
                            config_dir => q(/path/to/local/config/dir),
                            log_dir => q(/tmp),
                            ...,
                    },
                    local_item1 => ...,
                    local_item2 => ...,
            }

- $zx\_api

    Zabbix::ServerScript::API object

## return\_value($value)

Prints $value to STDOUT and exits. Throws an exception if $value is not defined.

## store\_cache($cache, $cache\_filename)

Stores cache to file using Storable module. $cache\_filename is optional.

## retrieve\_cache($cache\_filename)

Retrieves cache from file using Storable module. $cache\_filename is optional.

## connect\_to\_db($dsn, $user, $password)

Connects to database via unixODBC. $dsn is mandatory.
Returns database handle or throws an exception on failure.

## send($data\_structure, $trapper\_host, $trapper\_port)

Send data to Zabbix trapper like zabbix\_sender does.
$data\_structure is mandatory. $trapper\_host and $trapper\_port are optional, values from global config's 'trapper' section are used by default.
Returns server response on success or throws an exception on failure.
$data\_structure must be either hashref or arrayref of hashrefs.

Each of hashref must be like:

        {
                host => q(Linux host),  # hostname as in Zabbix frontend
                key => q(item_key),
                value => 1,
                clock => time,          # unix timestamp, optional
        }

## create\_config

Creates Config.pm from DefaultConfig.pm.

Usage:

        perl -MZabbix::ServerScript -e create_config

# LICENSE

Copyright (C) Anton Alekseyev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Anton Alekseyev &lt;akint.wr+github@gmail.com>
