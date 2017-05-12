# NAME

Ubic::Service::Starman - Helper for running psgi applications with Starman

# VERSION

version 0.004

# SYNOPSIS

    use Ubic::Service::Starman;
    return Ubic::Service::Starman->new({
        server_args => {
            listen => "/tmp/app.sock",
        },
        app => "/var/www/app.psgi",
        status => sub { ... },
        port => 4444,
        ubic_log => '/var/log/app/ubic.log',
        stdout => '/var/log/app/stdout.log',
        stderr => '/var/log/app/stderr.log',
        user => "www-data",
    });

# DESCRIPTION

This service is a common ubic wrap for psgi applications.
It uses starman for running these applications.

It is a very simple wrapper around [Ubic::Service::Plack](http://search.cpan.org/perldoc?Ubic::Service::Plack) that
uses [starman](http://search.cpan.org/perldoc?starman) as the binary instead of [plackup](http://search.cpan.org/perldoc?plackup).  It
defaults the `server` argument to 'Starman' so you don't have to pass
it in, and adds the ability to reload (which will gracefully restart
your [Starman](http://search.cpan.org/perldoc?Starman) workers without any connections lost) using
`ubic reload service_name`.

# NAME

Ubic::Service::Starman - ubic service base class for psgi applications

# METHODS

- reload

Reload adds the ability to send a `HUP` signal to the [Starman](http://search.cpan.org/perldoc?Starman) server
to gracefully reload your app and all the workers without losing any
connections.

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.