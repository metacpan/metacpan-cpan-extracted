# NAME

Toadfarm - One Mojolicious app to rule them all

# VERSION

0.82

# DESCRIPTION

Toadfarm is a module for configuring and starting your [Mojolicious](https://metacpan.org/pod/Mojolicious)
applications. You can either combine multiple applications in one script,
or just use it as a init script.

Core features:

- Wrapper around [hypnotoad](https://metacpan.org/pod/Mojo::Server::Hypnotoad) that makes your
application [Sys-V](https://www.debian-administration.org/article/28/Making_scripts_run_at_boot_time_with_Debian)
compatible.
- Advanced routing and virtual host configuration. Also support routing
from behind another web server, such as [nginx](http://nginx.com/).
This feature is very much like [Mojolicious::Plugin::Mount](https://metacpan.org/pod/Mojolicious::Plugin::Mount) on steroids.
- Hijacking log messages to a common log file. There's also plugin,
[Toadfarm::Plugin::AccessLog](https://metacpan.org/pod/Toadfarm::Plugin::AccessLog), that allows you to log the requests sent
to your server.

# SYNOPSIS

## Script

Here is an example script that sets up logging and mounts some applications
under different domains, as well as loading in some custom plugins.

See [Toadfarm::Manual::DSL](https://metacpan.org/pod/Toadfarm::Manual::DSL) for more information about the different functions.

    #!/usr/bin/perl
    use Toadfarm -init;

    logging {
      combined => 1,
      file     => "/var/log/toadfarm/app.log",
      level    => "info",
    };

    mount "MyApp"  => {
      Host   => "myapp.example.com",
      config => {
        config_parameter_for_myapp => "foo"
      },
    };

    mount "/path/to/app" => {
      Host        => "example.com",
      mount_point => "/other",
    };

    mount "Catch::All::App";

    plugin "Toadfarm::Plugin::AccessLog";

    start; # needs to be at the last line

## Usage

You don't have to put ["Script"](#script) in init.d, but it will work with standard
start/stop actions.

    $ /etc/init.d/your-script reload
    $ /etc/init.d/your-script start
    $ /etc/init.d/your-script stop

See also ["Init script" in Toadfarm::Manual::RunningToadfarm](https://metacpan.org/pod/Toadfarm::Manual::RunningToadfarm#Init-script) for more details.

You can also start the application with normal [Mojolicious](https://metacpan.org/pod/Mojolicious) commands:

    $ morbo /etc/init.d/your-script
    $ /etc/init.d/your-script daemon

# DOCUMENTATION INDEX

- [Toadfarm::Manual::Intro](https://metacpan.org/pod/Toadfarm::Manual::Intro) - Introduction.
- [Toadfarm::Manual::DSL](https://metacpan.org/pod/Toadfarm::Manual::DSL) - Domain specific language for Toadfarm.
- [Toadfarm::Manual::Config](https://metacpan.org/pod/Toadfarm::Manual::Config) - Config file format.
- [Toadfarm::Manual::RunningToadfarm](https://metacpan.org/pod/Toadfarm::Manual::RunningToadfarm) - Command line options.
- [Toadfarm::Manual::BehindReverseProxy](https://metacpan.org/pod/Toadfarm::Manual::BehindReverseProxy) - Toadfarm behind nginx.
- [Toadfarm::Manual::VirtualHost](https://metacpan.org/pod/Toadfarm::Manual::VirtualHost) - Virtual host setup.

# PLUGINS

- [Toadfarm::Plugin::AccessLog](https://metacpan.org/pod/Toadfarm::Plugin::AccessLog)

    Log each request that hit your application.

- [Mojolicious::Plugin::SizeLimit](https://metacpan.org/pod/Mojolicious::Plugin::SizeLimit)

    Kill Hypnotoad workers if they grow too large.

- [Mojolicious::Plugin::SetUserGroup](https://metacpan.org/pod/Mojolicious::Plugin::SetUserGroup)

    Start as root, run workers as less user. See also
    ["Listen to standard HTTP ports" in Toadfarm::Manual::RunningToadfarm](https://metacpan.org/pod/Toadfarm::Manual::RunningToadfarm#Listen-to-standard-HTTP-ports).

# PREVIOUS VERSIONS

[Toadfarm](https://metacpan.org/pod/Toadfarm) prior to version 0.49 used to be a configuration file loaded in
by the `toadfarm` script. This resulted in all the executables to be named
`toadfarm` instead of something descriptive. It also felt a bit awkward to
take over `MOJO_CONFIG` and use all the crazy hacks to start `hypnotoad`.

It also didn't work well as an init script, so there still had to be a
seperate solution for that.

The new [Toadfarm](https://metacpan.org/pod/Toadfarm) DSL aim to solve all of these issues. This means that
if you decide to still use any `MOJO_CONFIG`, it should be for the
applications loaded from inside `Toadfarm` and not the startup script.

Note that the old solution still works, but a warning tells you to change
to the new [DSL](https://metacpan.org/pod/Toadfarm::Manual::DSL) based API.

# COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
