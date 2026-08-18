# Introduction

WebDyne is a Perl based dynamic HTML engine. It works with web servers
(or from the command line) to render HTML documents with embedded Perl
code.

Once WebDyne is installed and initialised any file with a `.psp`
extension (designated a PSP file) is treated as a WebDyne source file.
It is parsed for WebDyne pseudo-tags (such as `<perl>` and `<block>`)
which are interpreted and executed on the server. The resulting output
is then sent to the browser.

WebDyne works with common web server persistent Perl interpreters - such
as Apache `mod_perl,``PSGI` and `PAGI` - to provide fast dynamic
content. It works with PSGI servers such as Plack and Starman, and can
be implemented as a Docker container to run HTML with embedded Perl
code.

Pages are parsed once, then stored in a partially compiled format -
speeding up subsequent processing by avoiding the need to re-parse a
page each time it is loaded.

Alternate syntaxes are available to enable WebDyne code to be used with
editors that do not recognise custom HTML tags, and the syntax supports
the use of PHP type processing instruction tags (`<?..?>`) or `<div>`
tags (via data attributes such as `<div data-webdyne-perl>`) to define
WebDyne blocks.

Perl code can be co-mingled in the HTML code for "quick and dirty" pages
or completed isolated into separate files or modules for separation of
presentation and logic layers. You can see examples in a dedicated
section - but here are a few very simple examples as an overview.

Simple HTML file with Perl code embedded using WebDyne :

``` html
<html>
<head><title>Server Time</title></head>
<body>
The local server time is:
<perl> localtime() </perl>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/introduction1.psp)

This can be abbreviated with some WebDyne shortcut tags such as
`<start_html>`. This does exactly the same thing and still renders
compliant HTML to the browser:

``` html
<start_html title="Server Time">
The local server time is: <? localtime() ?>
```

[Run](https://demo.webdyne.org/example/introduction2.psp)

Don't like the co-mingling code and HTML but still want things in one
file ?

``` html
<start_html title="Server Time">
The local server time is <? print_time() ?>
</html>
__PERL__
sub print_time {
    print(scalar localtime);
}

```

[Run](https://demo.webdyne.org/example/introduction3.psp)

Want further code and HTML separation ? You can import methods from any
external Perl module. Example from a core module below, but could be any
installed CPAN module or your own code:

``` html
<start_html title="Server Time">
Server Time::HiRes time:
<perl require="Time::HiRes" import="time">time()</perl>
```

[Run](https://demo.webdyne.org/example/introduction4.psp)

Same concepts implemented in slightly different ways:

``` html
<start_html title="Server Time">
The local server epoch time (hires) is: <? time() ?>
<end_html>
__PERL__
use Time::HiRes qw(time);
1;
```

[Run](https://demo.webdyne.org/example/introduction5.psp)

``` html
<start_html title="Server Time">
<perl require="Time::HiRes" import="time"/>
The local server time (hires) is: <? time() ?>
```

[Run](https://demo.webdyne.org/example/introduction6.psp)

Using an editor that doesn't like custom tags ? Use of the &lt;div&gt; tag
with a `data-*` attribute is valid HTML syntax and can be used to embed
Perl:

``` html
<start_html title="Server Time">
The local server time is: <div data-webdyne-perl> localtime() </div>
```

[Run](https://demo.webdyne.org/example/introduction7.psp)

Alternatively, put the code in a &lt;script&gt; block - it will be
interpreted on the server, not the client:

``` html
<start_html title="Server Time">
Server local time is:
<script type="application/perl">
    print scalar localtime()
</script>
```

[Run](https://demo.webdyne.org/example/introduction7.psp)

Template blocks and variable replacement are supported also:

``` html
<start_html>

<!-- Call perl code to render server time -->
<perl handler="server_time">

<!-- Template Block it will be rendered into -->
<block name="server_time">
<p>
Loop ${i}: The local server time is: ${time}
</block>

</perl>

__PERL__

sub server_time {

    #  Get self ref
    #
    my $self=shift();

    #  Get local time
    #
    my $time=scalar localtime();

    #  Loop 4 times
    #
    foreach my $i (1..4) {

        #  Render template block
        #
        $self->render_block('server_time', i=>$i, time=>$time)

    }

    #  Return section
    #
    return $self->render()

}
```

[Run](https://demo.webdyne.org/example/introduction9.psp)

# Installation and Quickstart {#installation_quickstart}

WebDyne will install and run on any modern Linux system that has a
recent version of Perl installed and is capable of installing Perl
modules via CPAN. Installation via Docker is also supported.

When installing WebDyne there are two components which are required
before you can begin serving PSP files:

-   The core WebDyne Perl modules

-   A web server or application configured to use WebDyne.

WebDyne will work with Apache mod_perl, PAGI or PSGI compatible web
servers (such as Plack, Starman etc.).

Docker containers with pre-built versions of WebDyne are also available.

## Quickstart

If using PSGI you can start a quick web server by creating a simple
app.psp file:

    #  Save this as app.psp
    #
    <start_html>
    My first WebDyne page. Server time: <? localtime ?>

Then test install:

``` bash
#  Install WebDyne
#
$ cpanm WebDyne

#  Render the file to STDOUT to see the HTML and check basic installation
#
$ wdrender app.psp

#  Install Plack if not already done.
#
$ cpanm Plack

#  Check all working
#
$ webdyne.psgi --test

#  Start serving only a single PSP file
#
$ webdyne.psgi app.psp

# Start serving files from the current directory. Directory requests use WebDyne's
# built-in index page by default.
#
$ webdyne.psgi .

# Start but listen on non-default port, only on localhost
#
$ webdyne.psgi --port=5001 --host=127.0.0.1
```

Connect your browser to the host and you should see the WebDyne output.

You can shortcut install of Plack/Starman versions via:

    #  Install WebDyne Plack (PSGI)
    #
    $ cpanm Task::WebDyne::Plack


    #  Or Starman. Note if Starman install fails you may need to force install of Net::Server via
    #  cpanm --force Net::Server
    #  and try again
    #
    $ cpanm Task::WebDyne::Starman

## CPAN or CPANMinus Install {#cpan_install}

Install from the Perl CPAN library using `cpan` or `cpanm` utilities.
Installs dependencies if required (also from CPAN).

Destination of the installed files is dependent on the local CPAN
configuration, however in most cases it will be to the Perl site library
location. WebDyne supports installation to an alternate location using
the PREFIX option in CPAN. Binaries are usually installed to `/usr/bin`
or `/usr/local/bin`, but may vary by distribution/local configuration.

Assuming your CPAN environment is setup correctly you can run the
command:

`perl -MCPAN -e "install WebDyne"`

Or (with `cpanminus` if installed)

`cpanm WebDyne`

This will install the base WebDyne modules, which includes the Apache
config utility and PSGI and PAGI versions. Note that Apache or PSGI/PAGI
servers and dependencies (such as Plack or Starman) are **not**
installed by default and need to be installed separately - see the
relevant section, or just run:

    cpanm Task::WebDyne::Plack

to get everything needed to run with Plack/PSGI. For PAGI run:

    cpanm Task::WebDyne::PAGI

If using Apache you will need to configure your system to use WebDyne to
serve files with the `.psp` extension - see Apache install section.

## Runtime Choices {#runtime_choices}

### PSGI

Ensure that Plack is installed on your system via CPAN after installing
WebDyne:

    # Via CPAN
    #
    perl -MCPAN -e 'install Plack'

    # Modern systems
    #
    cpan Plack

    # Or better via CPANM
    #
    cpanm Plack

    # Or just do the whole lot in one hit. For WebDyne + Plack
    #
    cpanm Task::WebDyne::Plack

    # Or WebDyne + Plack + Starman. Note if Starman install fails you may need to force install of
    # Net::Server via :
    # cpanm --force Net::Server
    #
    cpanm Task::WebDyne::Starman

you can then start a basic WebDyne server by running the webdyne.psgi
command with the --test parameter

    webdyne.psgi --test

This will start a PSGI web server on your machine listening to port 5000
(or port 5001 on a Mac). Open a connection to http://127.0.0.1:5000/ or
the IP address of your server in your web browser to view the test page
and validate the WebDyne is working correctly:

Once verified as working correctly you can serve WebDyne content from a
particular directory - or from a single file - using the syntax:

    #  To serve up all files in a directory. Directory requests use WebDyne's built-in
    #  index page by default.
    #
    $ webdyne.psgi <directory>

    #  E.g serve files in /var/www/html. By default WebDyne will display its built-in
    #  index page if no filename is specified.
    #
    $ webdyne.psgi /var/www/html

    #  Or just a single app.psp file. Only this file will be served regardless of URL
    #
    $ webdyne.psgi /var/www/html/time.psp

!!! tip

    Starting WebDyne this way enables wrapper-managed index handling and
    full error messages with code backtraces if any errors are encountered.
    Use `--index=FILE` or `DOCUMENT_DEFAULT` to nominate a site-local
    default page, or `--no-index` to rely on the underlying request layer
    default document behavior.

To start with `plackup`:

    #  Start WebDyne via plackup in the current directory. A file named app.psp must exist,
    #  directory indexing will not be performed.
    #
    DOCUMENT_ROOT=. plackup `which webdyne.psgi`

    #  Start serving a single file
    #
    DOCUMENT_ROOT=./time.psp plackup /opt/perl5/bin/webdyne.psgi

    #  Start with some Plack middleware added
    #
    DOCUMENT_ROOT=./time.psp  plackup -e 'enable Plack::Middleware::Debug' `which webdyne.psgi`

The above starts a single-threaded web server using Plack. To start the
more performant Starman server (assuming installed):

    #  Start Starman instance. Substitute port + document root and location of webdyne.psgi
    #  as appropriate for your system.
    #
    $ DOCUMENT_ROOT=/var/www/html starman --port 5001 /usr/local/bin/webdyne.psgi

!!! note

    Plack (via `webdyne.psgi` or `plackup`) and Starman versions of WebDyne
    will serve basic static files such as css, js, jpg etc. If you want more
    control over non PSP files you should use a traditional web server front
    end to serve those assets. Also note the Starman and plackup instances
    of WebDyne do not support the --test option or indexing - it assumes you
    are running in a production environment and have checked everything with
    the Plack implementation of `webdyne.psgi` first.

Numerous options can be set from the command line via environment
variables, including WebDyne configuration. See relevant section for all
WebDyne configuration options but assuming a local file
`webdyne.conf.pl`:

    #  Start instance webdyne.psgi using local config file
    #
    $ WEBDYNE_CONF=./webdyne.conf.pl webdyne.psgi --port=5012 .

WebDyne can be incorporated into a traditional app.psgi startup file for
PSGI in the following form. In this example any file with a .psp
extension is routed to WebDyne for rendering

``` perl
#  Save as app.psgi
#
use strict;
use warnings;
use Plack::Builder;
use WebDyne::PSGI;

my $home_app = sub {
    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "Welcome to the Home Page\n" ]
    ];
};

my $webdyne_app = WebDyne::PSGI->new(
    root  => '.',
    index => 1,
)->to_app;

builder {
    sub {
        my $env = shift;
        # Serve any URL ending in .psp through WebDyne
        if ($env->{PATH_INFO} =~ /\.psp$/i) {
            return $webdyne_app->($env);
        }

        return $home_app->($env);
    };
};
```

Save as app.psgi and start with command line:

    #  Assuming app.psgi in current directory
    #
    plackup


    #  Or if named differently
    #
    plackup myapp.psgi

Or you can mount all files from a particular directory against the
WebDyne render engine.

``` perl
use strict;
use warnings;
use Plack::Builder;
use WebDyne::PSGI;

# Main app for /
my $home_app = sub {
    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "Welcome to the Home Page\n" ]
    ];
};

# Mount everything using builder
builder {
    mount '/'         => $home_app;
    mount '/webdyne'  => WebDyne::PSGI->new( root => '.')->to_app;
};
```

### PAGI

WebDyne can also run as a PAGI application. PAGI support covers normal
HTTP requests and, when using a PAGI server with the relevant scope
support, server-sent events, WebSocket connections and application
lifespan events.

Ensure that PAGI is installed on your system via CPAN after installing
WebDyne:

    # Via CPAN
    #
    perl -MCPAN -e 'install PAGI'

    # Modern systems
    #
    cpan PAGI

    # Or better via CPANM
    #
    cpanm PAGI

    # Or just do the whole lot in one hit. For WebDyne + PAGI
    #
    cpanm Task::WebDyne::PAGI

you can then start a basic WebDyne server by running the webdyne.pagi
command with the --test parameter

    webdyne.pagi --test

This will start a PAGI web server on your machine listening to port 5000
(or port 5001 on a Mac). When started through `webdyne.pagi` the server
binds to `0.0.0.0` unless a host is specified on the command line. Open
a connection to http://127.0.0.1:5000/ (or the IP address of your
server) in your web browser to view the test page and validate the
WebDyne is working correctly:

Once verified as working correctly you can serve WebDyne content from a
particular directory - or from a single file - using the syntax:

    #  To serve up all files in a directory. Directory requests use WebDyne's built-in
    #  index page by default.
    #
    $ webdyne.pagi <directory>

    #  E.g serve files in /var/www/html. By default WebDyne will display its built-in
    #  index page if no filename is specified.
    #
    $ webdyne.pagi /var/www/html

    #  Or just a single app.psp file. Only this file will be served regardless of URL
    #
    $ webdyne.pagi /var/www/html/time.psp

!!! tip

    Starting WebDyne this way enables wrapper-managed index handling and
    full error messages with code backtraces if any errors are encountered.
    Use `--index=FILE` or `DOCUMENT_DEFAULT` to nominate a site-local
    default page, or `--no-index` to rely on the underlying request layer
    default document behavior.

To start with `pagi-server`:

    #  Start WebDyne via pagi-server in the current directory. A file named app.psp must exist,
    #  directory indexing will not be performed.
    #
    DOCUMENT_ROOT=. pagi-server --app `which webdyne.pagi` --port=5000 --host=0.0.0.0

    #  Start serving a single file
    #
    DOCUMENT_ROOT=./time.psp pagi-server /opt/perl5/bin/webdyne.pagi

The above starts a single-threaded web server using PAGI.

!!! note

    PAGI (via `webdyne.pagi` or `pagi-server`) versions of WebDyne will
    serve basic static files such as css, js, jpg etc. If you want more
    control over non PSP files you should use a traditional web server front
    end to serve those assets.

Numerous options can be set from the command line via environment
variables, including WebDyne configuration. See relevant section for all
WebDyne configuration options but assuming a local file
`webdyne.conf.pl`:

    #  Start instance webdyne.pagi using local config file
    #
    $ WEBDYNE_CONF=./webdyne.conf.pl webdyne.pagi --port=5012 .

WebDyne can be incorporated into a traditional app.pagi/app.pl startup
file for PAGI in the following form. In this example any file with a
.psp extension is routed to WebDyne for rendering:

``` perl
use strict;
use warnings;
use Future::AsyncAwait;
use experimental 'signatures';

use PAGI::Middleware::Builder;
use WebDyne::PAGI;

my $home_app = async sub ($scope, $receive, $send) {
    die "Unsupported scope type: $scope->{type}"
        unless $scope->{type} eq 'http';

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            [ 'content-type', 'text/plain' ],
        ],
    });

    await $send->({
        type => 'http.response.body',
        body => "Welcome to the Home Page\n",
        more => 0,
    });
};

my $webdyne_app = WebDyne::PAGI->new(
    root  => '.',
)->to_app;

builder {
    async sub ($scope, $receive, $send) {
        if (($scope->{path} // '') =~ /\.psp$/i) {
            return await $webdyne_app->($scope, $receive, $send);
        }

        return await $home_app->($scope, $receive, $send);
    };
};
```

### Apache mod_perl {#apache_mod_perl}

If using Apache with mod_perl you can initialise WebDyne using the
`wdapacheinit` command. This will attempt to auto-discover where the
Apache binary and configuration files are, then add a suitable
`webdyne.conf` file to the apache configuration. Apache will need to be
restarted for the new configuration file to take effect. This will need
to be done as a the root user.

``` bash
[root@localhost ~]# wdapacheinit

[install] - Installation source directory '/usr'.
[install] - Creating cache directory '/var/cache/webdyne'.

[install] - Writing Apache config file '/etc/httpd/conf.d/webdyne.conf'.
[install] - Writing Webdyne config file '/etc/httpd/conf.d/webdyne_conf.pl'.
[install] - Apache uses conf.d directory - not changing httpd.conf file.
[install] - Granting Apache (apache.apache) ownership of cache directory '/var/cache/webdyne'.
[install] - Install completed.

[root@localhost ~]# systemctl restart httpd
```

By default WebDyne will create a cache directory in `/var/cache/webdyne`
on Linux systems when a default CPAN install is done (no PREFIX
specified). If a PREFIX is specified the cache directory will be created
as `$PREFIX/cache`. Use the `wdapacheinit` `--cache` command-line option
to specify an alternate location.

Once `wdapacheinit` has been run the Apache server should be reloaded or
restarted. Use a method appropriate for your Linux distribution.

    [root@localhost ~]# systemctl httpd restart
    Stopping httpd:                                            [  OK  ]
    Starting httpd:                                            [  OK  ]

#### Manual Apache Configuration

If the `wdapacheinit` command does not work as expected on your system
then the Apache configuration files can be modified manually.

Include the following section in the Apache `httpd.conf` file (or create
a `webdyne.conf` file if you distribution supports `conf.d` style
configuration files). The following configuration files are written with
Apache 2.4 syntax - adjust path and syntax as required:

    #  Need mod_perl, load up if not already done. Adjust path according to your distro.
    #
    <IfModule !mod_perl.c>
    LoadModule perl_module "/etc/httpd/modules/mod_perl.so"
    </IfModule>

    #  Uncomment and update if using a local::lib location for Perl modules
    #
    #PerlSwitches -I/opt/perl -I/opt/otherperl

    #  Preload the WebDyne and WebDyne::Compile module
    #
    PerlModule    WebDyne WebDyne::Compile

    #  Associate psp files with WebDyne
    #
    AddHandler    modperl    .psp
    PerlHandler   WebDyne

    #  Set a directory for storage of cache files. Make sure this exists already is writable by the
    #  Apache daemon process.
    #
    PerlSetVar    WEBDYNE_CACHE_DN    '/opt/webdyne/cache'

    #  Allow Apache to access the cache directory if it needs to serve pre-compiled pages from there.
    #
    <Directory "/opt/webdyne/cache">
    Require all granted
    </Directory>

    # Put variables in a separate file - best
    #
    PerlRequire conf.d/webdyne_constant.pl

    #  Or use <Perl> sections - but warning, certbot doesn't like this syntax in http conf files
    #
    <Perl>

    #  Error display/extended display on/off. Set to 1 to enable, 0 to disable
    #
    $WebDyne::WEBDYNE_ERROR_SHOW=1;
    $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;
    </Perl>

!!! important

    Substitute directory paths in the above example for the
    relevant/correct/appropriate ones on your system.

Create the cache directory and assign ownership and permission
appropriate for your distribution (group name will vary by
distribution - locate the correct one for your distribution)

    [root@localhost ~]# mkdir /opt/webdyne/cache
    [root@localhost ~]# chgrp apache /opt/webdyne/cache
    [root@localhost ~]# chmod 770 /opt/webdyne/cache

Restart Apache and check for any errors.

#### Development Apache Runner

A convenience utility `webdyne.apache` is supplied which starts a
single-threaded instance of Apache on port 5000 to render WebDyne pages.
It works in the same way as the PSGI and PAGI startup scripts outlined
later

    #  Start an Apache test instance on a single .psp file
    #
    $ perl -Ilib bin/webdyne.apache ./time.psp
    /usr/sbin/httpd -D ONE_PROCESS -d /tmp/webdyne_apache_ol2EWnkb -f /tmp/webdyne_apache_ol2EWnkb/conf/httpd.conf -D APACHE2 -D APACHE2_4 -D PERL_USEITHREADS
    using Apache/2.4.62 (event MPM)

    waiting 60 seconds for server to start: .
    [Sat May 02 16:56:20.700397 2026] [core:trace3] [pid 356673:tid 356673] core.c(3505): Setting LogLevel for all modules to trace8
    [Sat May 02 16:56:21.115354 2026] [mpm_event:debug] [pid 356673:tid 356717] event.c(2402): AH02471: start_threads: Using epoll (wakeable)

    waiting 60 seconds for server to start: ok (waited 0 secs)
    server localhost:5000 started


    #  Start an instance to with a simple directory index on the current directory
    #
    $ perl -Ilib bin/webdyne.apache .

## Docker

Docker containers are available from the [Github Container
Registry](https://github.com/aspeer/WebDyne/pkgs/container/webdyne).
Install the default Docker container (based on Debian) via:

    #  Default debian version
    #
    $ docker pull ghcr.io/aspeer/webdyne:latest

    #  Or Alpine/Fedora/Perl versions
    #
    # docker pull ghcr.io/aspeer/webdyne:alpine
    # docker pull ghcr.io/aspeer/webdyne:fedora

Start the docker container with the command:

    $ docker run -e PORT=5002 -p 5002:5002 --name=webdyne ghcr.io/aspeer/webdyne:latest

This will start WebDyne running on port 5002 on the host. Connecting to
that location should show the server *localtime* test page

By default the container starts WebDyne with `starman` using the PSGI
runner. The server implementation can be selected with the
`WEBDYNE_SERVER` environment variable.

    #  Run with the default PSGI/Starman server
    #
    $ docker run -e PORT=5002 -p 5002:5002 --name=webdyne ghcr.io/aspeer/webdyne:latest

    #  Run with the PAGI server
    #
    $ docker run -e WEBDYNE_SERVER=pagi -e PORT=5002 -p 5002:5002 --name=webdyne ghcr.io/aspeer/webdyne:latest

To mount a local page and serve it through the docker container use the
command:

    $ docker run -v $(pwd):/app:ro -e PORT=5011 -e DOCUMENT_ROOT=/app -p 5011:5011 --name webdyne ghcr.io/aspeer/webdyne:latest

This will tell docker to mount the local directory into the docker
container. Because the container starts WebDyne through `starman` or
`pagi-server`, the default document is `app.psp` unless
`DOCUMENT_DEFAULT` is set. If there is a `cpanfile` in the mount
directory any modules will be installed into the docker container
automatically.

When the container is started without an explicit command, the default
entrypoint uses the following environment variables:

`PORT`

:   The TCP port the selected server listens on inside the container. If
    omitted, the entrypoint uses `8080`. The docker `-p` mapping should
    map the same container port, for example
    `-e PORT=5002 -p 5002:5002`.

`WEBDYNE_SERVER`

:   Selects the server used by the default container command. Supported
    values are `psgi` and `pagi`. If omitted, `psgi` is used. `psgi`
    runs `starman -MWebDyne` with `webdyne.psgi`. `pagi` runs
    `pagi-server` with `webdyne.pagi`, enabling PAGI request handling
    such as SSE and WebSocket support where the application uses those
    features. Any other value causes the entrypoint to exit with an
    error.

`DOCUMENT_ROOT`

:   The WebDyne document root passed through to `webdyne.psgi` or
    `webdyne.pagi`. The published images default this to `/app`.
    Override it when mounting application files somewhere else in the
    container.

`DOCUMENT_DEFAULT`

:   The default document to serve from `DOCUMENT_ROOT`. If omitted, the
    command wrappers enable WebDyne's built-in default index behavior,
    which uses `app.psp` in the published Docker images.

`WEBDYNE_CACHE_DN`

:   The WebDyne compile/cache directory. The published images set this
    to `/opt/webdyne/cache` by default via the image's
    `PERL_CARTON_PATH`. Override it if the cache should live on a
    mounted volume or another writable directory.

`PERL_CARTON_PATH`

:   The local Perl installation prefix inside the image. The published
    images default this to `/opt/webdyne` and use it to set `PERL5LIB`,
    `PATH`, the default `WEBDYNE_CACHE_DN`, and the path to the bundled
    `webdyne.psgi` and `webdyne.pagi` wrappers. This is normally only
    changed when building a custom image.

See the [Docker Runtime Server Tuning](#docker_runtime_server_tuning)
reference section for server worker, timeout and connection limit
environment variables.

# Basic Usage {#examples}

Assuming the installation has completed with no errors you are now ready
to start creating WebDyne pages and applications.

## Integrating Perl into HTML

Some code fragments to give a very high-level overview of how WebDyne
can be implemented. First the most basic usage example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Note the perl tags -->

Hello World <perl> localtime() </perl>

</body>
</html>
```

[Run](https://demo.webdyne.org/example/hello1.psp)

So far not too exciting - after all we are mixing code and content. Lets
try again - the &lt;perl&gt; tag can take a handler attribute which
references (calls) a perl subroutine - in this case embedded in the PSP
file under the \_\_PERL\_\_ token.

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Empty perl tag this time, but with method name as attribute -->

Hello World <perl handler="hello"/>

</body>
</html>

__PERL__

sub hello { return localtime }
```

[Run](https://demo.webdyne.org/example/hello2.psp)

!!! note

    In this case the &lt;perl&gt; tag is implicitly closed (contains no content)
    as it is assumed all content will be returned by the handler (i.e. the
    "hello" routine).

Better - at least code and content are distinctly separated. Note that
whatever the Perl code returns at the end of the routine is what is
displayed. Although WebDyne will happily display returned strings or
scalars, it is more efficient to return a scalar reference, e.g.:

``` perl
#  Works
#
sub greeting { print "Hello World" }


#  Is the same as
#
sub greeting { return "Hello World" }
sub greeting { my $var="Hello World"; return $var }


# But best is
#
sub greeting { my $var="Hello World"; return \$var }


# If you don't want to display anything return \undef,
#
sub greeting { return \undef }
```

Up until now all the Perl code has been contained within the WebDyne
file. The following example shows an instance where the code is
contained in a separate Perl module, which should be available somewhere
in the `@INC` path.

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Perl tag with call to external module method -->

Hello World <perl handler="Digest::MD5::md5_hex"/>

</body>
</html>
```

[Run](https://demo.webdyne.org/example/hello3.psp)

If not already resident the module (in this case `Digest::MD5`) will be
loaded by WebDyne, so it must be available somewhere in the `@INC` path.
Alternate syntaxes are supported - these all work in the same way:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<pre>

<!-- Perl tag with call to external module method -->

<perl require="Digest::MD5" import="md5_hex">

printf ("MD5_HEX: %s", md5_hex());

</perl>

</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/hello3a.psp)

### Use of the &lt;perl&gt; tag for in-line code.

The above examples show several variations of the &lt;perl&gt; tag in use.
Perl code that is enclosed by &lt;perl&gt;..&lt;/perl&gt; tags is designated as
*in-line* code:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<pre>

<!-- Perl tag containing perl code which generates output -->

<perl>

for (0..3) {
    print "Hello World\n"
}

#  Don't want anthing else displayed so return \undef
#
return \undef;

</perl>


</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/inline1.psp)

This is the most straight-forward use of Perl within a HTML document,
but does not really make for easy reading - the Perl code and HTML are
intermingled. It may be OK for quick scripts etc, but a page will
quickly become hard to read if there is a lot of in-line Perl code
interspersed between the HTML.

in-line Perl can be useful if you want a "quick" computation, e.g.
insertion of the current year. Note the ability to require external
modules via the require attribute, and import functions via the import
attribute

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<pre>

<!-- Very quick and dirty block of perl code -->

Copyright (C) <perl>(localtime())[5] + 1900</perl> Foobar Gherkin corp.

<!-- Or -->

Copyright (C) <perl require="Time::Piece" import="localtime"> localtime->year() </perl> Foobar Gherkin corp.

<!-- Or -->

Copyright (C) <perl require="POSIX"> POSIX::strftime("%Y", localtime) </perl> Foobar Gherkin corp.

<!-- Or -->

Copyright (C) <perl require="POSIX" import="strftime"> POSIX::strftime("%Y", localtime) </perl> Foobar Gherkin corp.

</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/inline2.psp)

Which can be pretty handy, but looks a bit cumbersome - the tags
interfere with the flow of the text, making it harder to read. For this
reason in-line perl can also be flagged in a WebDyne page using the
shortcuts !*{! .. !}*, or by the use of processing instructions (*&lt;? ..
?&gt;*) e.g.:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Same code with alternative denotation -->

The time is: !{! localtime() !}

<p>

The time is:  <? localtime() ?>


</body>
</html>
```

[Run](https://demo.webdyne.org/example/inline3.psp)

The *!{! .. !}* denotation can also be used in tag attributes
(processing instructions, and &lt;perl&gt; tags cannot):

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Perl code can be used in tag attributes also -->

<font color="!{! (qw(red blue green))[rand 3] !}">

Hello World

</font>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/inline4.psp)

### Use of the &lt;perl&gt; tag for non-inline code.

Any code that is not co-mingled with the HTML of a document is
*non-inline* code. It can be segmented from the content HTML using the
\_\_PERL\_\_ token, or by being kept in a completely different package
and referenced as an external Perl subroutine call. An example of
non-inline code:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Empty perl tag this time, but with method name as attribute -->

Hello World <perl handler="hello"/>

</body>
</html>

__PERL__

sub hello { return localtime }
```

[Run](https://demo.webdyne.org/example/hello2.psp)

Note that the &lt;perl&gt; tag in the above example is explicitly closed and
does not contain any content. However non-inline code can enclose HTML
or text within the tags:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The perl method will be called, but "Hello World" will not be displayed ! -->

<perl handler="hello">
Hello World
</perl>

</body>
</html>

__PERL__

sub hello { return localtime() }
```

[Run](https://demo.webdyne.org/example/noninline1.psp)

But this is not very interesting so far - the "Hello World" text is not
displayed when the example is run !

In order for text or HTML within a non-inline perl block to be
displayed, it must be "rendered" into the output stream by the WebDyne
engine. This is done by calling the render() method. Let's try that
again:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The perl method will be called, and this time the "Hello World" will be displayed-->

<perl handler="hello">
Hello World
</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    return $self->render();

}
```

[Run](https://demo.webdyne.org/example/noninline2.psp)

And again, this time showing how to render the text block multiple
times. Note that an array reference is returned by the Perl routine -
this is fine, and is interpreted as an array of HTML text, which is
concatenated and send to the browser.

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered multiple times -->

<perl handler="hello">
<p>
Hello World
</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    my @html;
    for (0..3) { push @html, $self->render() };
    return \@html;
}
```

[Run](https://demo.webdyne.org/example/noninline3.psp)

Same output using the `$self->print()` method:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered multiple times -->

<perl handler="hello">
<p>
Hello World
</perl>

</body>
</html>

__PERL__

sub hello {

    #  Note use of $self->print()
    #
    my $self=shift();
    for (0..3) { $self->print($self->render()) };
    return \undef;
}
```

[Run](https://demo.webdyne.org/example/noninline3.psp)

Note that there is a syntactic shortcut available if you have a single
handler - just call the subroutine "handler" and it will be invoked by
default:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Note shortcut via handler attribute with no value -->

<perl handler>
Hello World
</perl>

</body>
</html>

__PERL__


#  Subroutine called "handler" is invoked by default
#
sub handler {

    my $self=shift();
    return $self->render()

}
```

[Run](https://demo.webdyne.org/example/noninline_handler1.psp)

### Requiring external modules and importing methods

As noted above inline perl code can import external modules (including
any Perl core modules, any module installed via CPAN and/or any module
in the normal Perl \@INC path or any filesystem file). Syntax is as
follows:

``` perl
#  Require single module and import single method
#
<perl require="Digest::MD5" import="md5_hex"/>

#  Require single module and import multiple methods
#
<perl require="Digest::MD5" import="md5_hex md5_base64"/>

#  Alternate syntax using array attribute - see later section
#
<perl require="Digest::MD5" import="@{qw(md5_hex md5_base64)}"/>

#  You can also require a file. No import is available in this usage
#
<perl require="mymodule.pm">
```

!!! warning

    The import functionality is very basic - it only maps to the function in
    the module, it does not call the actual module import() facility. If the
    module you are importing does something sophisticated in its import()
    function (such as auto-creating methods) this will not work.
    Additionally nothing is imported by default, even if automatically
    exported by a module.

A very basic demo of the above would look as follows:

``` html
<start_html>
<pre>

<!-- Basic require of Digest::MD5 module and import of functions -->

<perl require="Digest::MD5" import="md5_hex md5_base64">

printf("MD5_HEX: %s, MD5_BASE64: %s", md5_hex(), md5_base64());

</perl>

<pre>
<end_html>
```

[Run](https://demo.webdyne.org/example/require1.psp)

If your module usage and import requirements are more sophisticated they
should be put in a \_\_PERL\_\_ section as "normal" code. Anything used
or imported will be available to any code within the page:

``` html
<start_html>
<pre>

<!-- No require or import attribute, done in __PERL__ section -->

<perl>

printf("MD5_HEX: %s, MD5_BASE64: %s", md5_hex(), md5_base64());

</perl>

<pre>
<end_html>

__PERL__

#  Use modules here if more complex needs
#
use Digest::MD5 qw(md5_hex md5_base64);
```

[Run](https://demo.webdyne.org/example/require2.psp)

### Alternate output methods from Perl handlers

When calling a perl handler from a PSP file at some stage you will want
your code to deliver output to the browser. Various examples have been
given throughout this document, here is a summary of various output
options:

``` html
<start_html>
<pre>
<perl handler="handler1" />

<perl handler="handler2" />

<perl handler="handler3" />

<perl handler="handler4" />

<perl handler="handler5" />

<perl handler="handler6" chomp />

<perl handler="handler7" />

<perl handler="handler8" chomp />

<perl handler="handler9" chomp />

<perl handler="handler9" autonewline/>

__PERL__

#  Different ways of sending output to the browser
#
sub handler1 {

    #  Simplest - just return a scalar variable
    #
    my $text='Hello World 1';
    return $text;

}

sub handler2 {

    #  Scalar ref better because if var is empty (undef) won't trigger and error
    #
    my $text='Hello World 2';
    return \$text;

}

sub handler3 {

    #  Returning an array ref is OK
    #
    my @text=('Hello', 'World', 3);


    #  This won't work
    #
    #return @text


    #  Returning an array ref is OK - note it won't auto insert spaces though !
    #
    return \@text

}

sub handler4 {

    #  Print something also using the print statement
    #
    my $text='Hello World 4';
    print $text;
    print "\n";

    #  Printing a scalar ref is OK
    #
    print \$text;

}

sub handler5 {

    #  Print arrays
    #
    my @text=('Hello ', 'World ', 5);
    print @text;


    #  Print new line manually, or turn on autonewline -
    #  see next example;
    #
    print "\n";

    #  Array refs are OK
    #
    print \@text;


    #  Printing hash ref's won't work ! This will fail
    #
    # print { a=>1, b=>2 }
    return \undef;

}

sub handler6 {

    #  You can print using a webdyne method handler
    #
    my $self=shift();


    #  Text we want to print
    #
    my $text="Hello World 6\n";
    my @text=('Hello ', 'World ', 6, "\n");


    #  These all work
    #
    $self->print($text);
    $self->print(\$text);
    $self->print(@text);
    $self->print(\@text);
    return \undef;

}

sub handler7 {

    #  You can print using a webdyne method handler
    #
    my $self=shift();


    #  Text we want to print
    #
    my $text="Hello World 7";
    my @text=('Hello ', 'World ', 7);


    #  Turn on autonew line to print "\n" at end of every call
    #
    $self->autonewline(1);


    #  These work
    #
    $self->print($text);
    $self->print(\$text);


    #  These put a CR between every element in the array
    $self->print(@text);
    $self->print(\@text);


    #  Turn off autonewline and return
    #
    $self->autonewline(0);
    return \undef;

}

sub handler8 {

    #  The say() method is supported also
    #
    use feature 'say';
    my $self=shift();
    my $text='Hello World 8';


    #  These will print, but won't send newline - say() won't send \n to TIEHANDLE
    #
    say($text);
    say($text);
    $self->print("\n");


    #  Use this instead
    #
    $self->say($text, $text);
}

sub handler9 {

    #  The autonewline directive is supported as a <perl> attribute
    #
    my $self=shift();
    my $text='Hello World 9';


    #  These will print, but won't send newline unless the autonewline attribute is specified
    #
    $self->print($text);
    $self->print($text);
    $self->print("\n");

}
```

[Run](https://demo.webdyne.org/example/output1.psp)

### Passing parameters to subroutines

The behaviour of a called \_\_PERL\_\_ subroutine can be modified by
passing parameters which it can act on:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- The "Hello World" text will be rendered with the param name -->

<perl handler="hello" param="Alice"/>
<p>
<perl handler="hello" param="Bob"/>
<p>

<!-- We can pass an hashref also - see variables section for more info on this syntax -->

<perl handler="hello_again" param="%{ firstname=>'Alice', lastname=>'Smith' }"/>

</body>
</html>

__PERL__

sub hello {

    my ($self, $param)=@_;
    return \"Hello world $param"
}

sub hello_again {

    my ($self, $param_hr)=@_;
    my $firstname=$param_hr->{'firstname'};
    my $lastname =$param_hr->{'lastname'};
    return \"Hello world $firstname $lastname";

}
```

[Run](https://demo.webdyne.org/example/noninline7.psp)

### Parameter inheritance

In-line code can inherit parameters passed from a perl handler/method.
In-line code gets two parameters supplied - the first (`$_[0]`) is the
self reference (e.g. `$self`), the second (`$_[1]`) is any inherited
parameters, passed as a hash reference. This can be useful for quick
"in-line" formatting, e.g:

``` html
<start_html>
<perl handler="inherit">
<pre>
Time - Unix epoch format: ${time}
Time - local time format: <? strftime('%X', localtime($_[1]->{'time'})) ?>
Date - ISO format: <? strftime('%Y-%m-%d', localtime($_[1]->{'time'})) ?>
Date - US format: <? strftime('%m/%d/%Y', localtime($_[1]->{'time'})) ?>
Date - UK format: <? strftime('%d/%m/%Y', localtime($_[1]->{'time'})) ?>
</pre>
</perl>
__PERL__
use POSIX qw(strftime);
sub inherit {
    shift()->render( time=>time() )
}
```

[Run](https://demo.webdyne.org/example/inherit1.psp)

### Notes about \_\_PERL\_\_ sections

Code in \_\_PERL\_\_ sections has some particular properties.
\_\_PERL\_\_ code is only executed once. Subroutines defined in a
\_\_PERL\_\_ section can be called as many times as you want, but the
code outside of subroutines is only executed the first time a page is
loaded. No matter how many times it is run, in the following code `$i`
will always be 1:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<perl handler="hello"/>
<p>
<perl handler="hello"/>

</body>
</html>

__PERL__

my $i=0;
$i++;

my $x=0;

sub hello {

    #  Note x may not increment as you expect because you will probably
    #  get a different Apache process each time you load this page
    #
    return sprintf("value of i: $i, value of x in PID $$: %s", $x++)
}
```

[Run](https://demo.webdyne.org/example/noninline4.psp)

Lexical variables are not accessible outside of the \_\_PERL\_\_ section
due to the way perl's eval() function works. The following example will
fail:

``` html
<html>
<head><title>Hello World</title></head>
<body>

The value of $i is !{! \$i !}

</body>
</html>

__PERL__

my $i=5;
```

[Run](https://demo.webdyne.org/example/noninline5.psp)

Package defined vars declared in a \_\_PERL\_\_ section do work, with
caveats:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Does not work -->
The value of $i is !{! $::i !}
<p>

<!-- Ugly hack, does work though -->
The value of $i is !{! ${__PACKAGE__.::i} !}
<p>

<!-- Probably best to just do this though -->
The value of $i is !{! &get_i() !}
<p>

<!-- Or this - see variable substitution section  -->
<perl handler="render_i">
The value of $i is ${i}
</perl>

</body>
</html>

__PERL__

our $i=5;

sub get_i { \$i }

sub render_i { shift()->render(i=>$i) }
```

[Run](https://demo.webdyne.org/example/noninline6.psp)

See the Variables/Substitution section for clean ways to insert variable
contents into the page.

## Variables

WebDyne starts to get more useful when variables are used to modify the
content of a rendered text block. A simple example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- The var ${time} will be substituted for the correspondingly named render parameter -->

<perl handler="hello">
Hello World ${time}
</perl>

</body>
</html>

__PERL__

sub hello {
    my $self=shift();
    my $time=localtime();
    $self->render( time=>$time );
}
```

[Run](https://demo.webdyne.org/example/var1.psp)

Note the passing of the `time` value as a parameter to be substituted
when the text is rendered.

Combine this with multiple call to the render() routine to display
dynamic data:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Multiple variables can be supplied at once as render parameters -->

<perl handler="hello0">
<p>
Hello World ${time}, loop iteration ${i}.
</perl>

<br>
<br>

<perl handler="hello1">
<p>
Hello World ${time}, loop iteration ${i}.
</perl>

</body>
</html>

__PERL__

sub hello0 {

    my $self=shift();
    my @html;
    my $time=localtime();
    for (my $i=0; $i<3; $i++) {
        push @html, $self->render( time=>$time, i=>$i)
    };
    return \@html;
}

sub hello1 {

    #  Alternate syntax using print
    #
    my $self=shift();
    my $time=localtime();
    for (my $i=0; $i<3; $i++) {
        print $self->render( time=>$time, i=>$i)
    };
    return \undef
}
```

[Run](https://demo.webdyne.org/example/var2.psp)

Variables can also be used to modify tag attributes:

``` html
<html>
<head><title>Hello World</title></head>
<body>

<!-- Render paramaters also work in tag attributes -->

<perl handler="hello">
<p>
<font color="${color}">
Hello World
</font>
</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    my @html;
    for (0..3) {
        my $color=(qw(red green yellow blue orange))[rand 5];
        push @html, $self->render( color=>$color );
    }
    \@html;

}
```

[Run](https://demo.webdyne.org/example/var3.psp)

Other variable types are available also, including:

-   `@{var,var,..}` for arrays, e.g. `@{'foo', 'bar'}`

-   `%{key=>value, key=>value, ..}` for hashes e.g.`%{ a=>1, b=>2 }`

-   `+{varname}` for CGI form parameters, e.g. `+{firstname}`

-   `*{varname}`for environment variables, e.g. `*{HTTP_USER_AGENT}`

-   `^{requestmethod}` for Apache request (`$r=Apache->request`) object
    methods, e.g. `^{protocol}`. Only available for in Apache/mod_perl,
    and only useful for request methods that return a scalar value.

The following template uses techniques and tags discussed later, but
should provide an example of potential variable usage:

``` html
<html>
<head>
<title>Variables</title>
</head>
<body>

<!-- Environment variables -->

<p>
<!-- Short Way -->
Request Method: *{REQUEST_METHOD}
<br>
<!-- Same as Perl code -->
Request Method:
<perl> $ENV{'REQUEST_METHOD'} </perl>


<!-- Request record methods. Only methods that return a scalar result are usable -->

<p>
<!-- Short Way -->
Request Protocol: ^{protocol}
<br>
<!-- Same as Perl code -->
Request Protocol:
<perl> my $self=shift(); my $r=$self->r(); return $r->protocol() </perl>


<!-- CGI params -->

<form>
Your Name:
<p><textfield name="name" default="Test" size="12">
<p><submit name="Submit">
</form>
<p>
<!-- Short Way -->
You Entered: +{name}
<br>
<!-- Same as Perl code -->
You Entered:
<perl> my $self=shift(); my $cgi_or=$self->CGI(); return $cgi_or->param('name') </perl>
<br>
<!-- CGI vars are also loaded into the %_ global var, so the above is the same as -->
You Entered:
<perl> $_{'name'} </perl>


<!-- Array Syntax -->

<form>
<p>
Favourite colour 1:
<p><popup_menu name="popup_menu1" values="@{qw(red green blue)}">


<!-- Hash Syntax -->

<p>
Favourite colour 2 (pick multiple):
<p><popup_menu multiple name="popup_menu2" values="%{red=>Red, green=>Green, blue=>Blue, orange=>'Orange', yellow=>'Yellow'}" default='green'>
<p><submit name="Submit">

</form>

<perl handler run="+{popup_menu1}">
Favourite colour 1: +{popup_menu1}
<p>
Favourite colour 2: ${popup_menu2_values}
</perl>

</body>
</html>

__PERL__

sub handler {
    return join(',', shift->CGI->param('popup_menu2'));
}
```

[Run](https://demo.webdyne.org/example/var4.psp)

## Shortcut Tags

Previous versions of WebDyne used Lincoln Stein's CGI.pm module to
render tags, and supported CGI.pm shortcut tags such as &lt;start_html&gt;,
&lt;popup_menu&gt; etc. Modern versions of WebDyne do not use CGI.pm in any
modules, having ported tag generation to HTML::Tiny. Support for
shortcut tags is preserved though - they provide a quick and easy way to
generate simple web pages.

### Quick pages using shortcut &lt;start_html&gt;, &lt;end_html&gt; tags

For rapid development you can take advantage of the &lt;start_html&gt; and
&lt;end_html&gt; tags. The following page generates compliant HTML (view the
page source after loading it to see for yourself):

``` html
<start_html title="Quick Page">
The time is: !{! localtime() !}
<end_html>
```

[Run](https://demo.webdyne.org/example/cgi6.psp)

!!! tip

    The &lt;end_html&gt; tag can be omitted if desired, the HTML parser will
    auto close any dangling tags at the end of the document, including
    adding any omitted &lt;/body&gt; or &lt;/html&gt; tags. So even if omitted from
    the PSP file WebDyne should still generate valid HTML to be served to
    the browser.

The &lt;start_html&gt; tag generates all the &lt;html&gt;, &lt;head&gt;, &lt;title&gt;
tags etc needed for a valid HTML page plus an opening body tag. Just
enter the body content, then optionally finish with &lt;end_html&gt; to
generate the closing &lt;body&gt; and &lt;html&gt; tags (optional because the
page is automatically closed if these are omitted). See the tag
reference section but here is an example using several of the properties
available in the &lt;start_html&gt; tag including loading multiple scripts
and stylesheets:

``` html
<start_html title="Hello World"
    style="@{qw(https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.css https://fonts.googleapis.com/css2?family=Inter:wght@400;600&family=Playfair+Display:wght@700&display=swap)}"
    script="@{qw(https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.js https://cdn.jsdelivr.net/npm/typed.js@2.1.0/dist/typed.umd.js)}"
>
<p>
<h2 id="typed"></h2>
<div data-aos="fade-up">I animate on load and scroll !</div>

<script>
  AOS.init({
    duration: 1000,  // 1s animations
    once: true       // animate only once
  });
</script>

<script>
  new Typed('#typed', {
    strings: ["Lorem", "Ipsum", "Dictum"],
    typeSpeed: 50,
    backSpeed: 25,
    loop: true
  });
</script>
```

[Run](https://demo.webdyne.org/example/start_html1.psp)

!!! caution

    Make sure any attributes using the `@{..}` or `%{..}` convention are on
    one line - the parser may not interpret them correctly if spanning
    multiple lines.

If using the &lt;start_html&gt; shortcut tag you can optionally insert
default stylesheets and/or &lt;head&gt; sections from the Webdyne
configuration file. E.g if in your `webdyne.conf.pl` file you have the
following:

    $_={
        'WebDyne::Constant' => {

            #  Inserted as <meta> into <head> section
            #
            WEBDYNE_META => {
                #  These all rendered as <meta name="$key" content="$value">
                viewport => 'width=device-width, initial-scale=1.0',
                author => 'Bob Foobar',
                #  This one rendered as <meta http-equiv="X-UA-Compatible" content="IE=edge">
                'http-equiv=X-UA-Compatible' => 'IE=edge',
                'http-equiv=refresh' => '5; url=https://www.example.com'
            }

            #  This is inserted inside the <html> starting tag, works for <start_html> or straight <html>
            #
            WEBDYNE_HTML_PARAM => {
                lang => 'de'
            }

            #  This is inserted before the </head> closing tag, works for <start_html> or straight <html>
            #
            WEBDYNE_HEAD_INSERT => << 'END'
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css">
    <style>
    :root { --pico-font-size: 85% }
    body { padding-top: 10px; padding-left: 10px;
    </style>
    END

        }
    }

Then any `PSP` file with a &lt;start_html&gt; tag will have the following
content:

    <!DOCTYPE html><html lang="de">
    <head>
    <title>Untitled Document</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="author" content="Bob Foobar">
    <meta http-equiv="refresh" content="5; url=https://www.example.com">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css">
    <style>
        :root { --pico-font-size: 85% }
    </style>
    </head>

### HTML Forms using &lt;popup_menu&gt;,&lt;checkbox_group&gt; and other tags

The CGI.pm module presented several shortcut tags for generating HTML
forms. These tags have been recreated in WebDyne and act in a similar
way.

The manual page for CGI.pm contains the following synopsis example:

    use CGI qw/:standard/;
       print header,
             start_html('A Simple Example'),
             h1('A Simple Example'),
             start_form,
             "What's your name? ",textfield('name'),p,
             "What's the combination?", p,
             checkbox_group(-name=>'words',
                            -values=>['eenie','meenie','minie','moe'],
                            -defaults=>['eenie','minie']), p,
             "What's your favorite color? ",
             popup_menu(-name=>'color',
                        -values=>['red','green','blue','chartreuse']),p,
             submit,
             end_form,
             hr;

        if (param()) {
            print "Your name is",em(param('name')),p,
                  "The keywords are: ",em(join(", ",param('words'))),p,

If the example was ported to a WebDyne compatible page it might look
something like this:

``` html
<!-- The same form from the CGI example -->

<start_html title="A simple example">
<h1>A Simple Example</h1>
<start_form>
<p>
What's your name ?
<p><textfield name="name">
<p>
What's the combination ?
<p><checkbox_group
    name="words" values="@{qw(eenie meenie minie moe)}" defaults="@{qw(eenie minie)}">
<p>
What's your favourite color ?
<p><popup_menu name="color" values="@{qw(red green blue chartreuse)}">
<p><submit>
<end_form>
<hr>


<!-- This section only rendered when form submitted -->

<perl handler="answers">
<p>
Your name is: <em>+{name}</em>
<p>
The keywords are: <em>${words}</em>
<p>
Your favorite color is: <em>+{color}</em>
</perl>

__PERL__

sub answers {

    my $self=shift();
    my $cgi_or=$self->CGI();
    if ($cgi_or->param()) {
        my $words=join(",", $cgi_or->param('words'));
        return $self->render( words=>$words )
    }
    else {
        return \undef;
    }

}
```

[Run](https://demo.webdyne.org/example/cgi1.psp)

!!! note

    When using the WebDyne form tags, state (previous form values) are
    preserved after the Submit button is presented. This makes building
    single page application simple as there is no need to implement logic to
    adjust options in a traditional HTML form to reflect the user's choice.

### More on HTML shortcut tags in forms

Tags such as &lt;popup_menu&gt; output traditional HTML form tags such as
&lt;select&gt;&lt;option&gt;...&lt;/select&gt;, but they have the advantage of
allowing Perl data types as attributes. Take the following example:

    <popup_menu values="%{red=>Red, green=>Green, blue=>Blue}"/>

it is arguably easier to read than:

    <select name="values" tabindex="1">
    <option value="green">Green</option>
    <option value="blue">Blue</option>
    <option value="red">Red</option>
    </select>

So there is some readability benefit, however the real advantage shows
when we consider the next example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl handler="countries">
<popup_menu values="${countries_ar}" default="Australia">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {

    my $self=shift();
    my @countries = sort { $a cmp $b } all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/example/cgi5.psp)

All values for the menu item were pre-populated from one WebDyne
variable - which saves a significant amount of time populating a
"countries" style drop-down box.

### Access to HTML form responses and query strings

Once a form is submitted you will want to act on responses. There are
several ways to do this - you can access a CGI::Simple object instance
in any WebDyne template by calling the CGI() method to obtain form
responses:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Note use of CGI.pm derived textfield tag -->

<form>
Enter your name:
<p><textfield name="name">
<p><submit>
</form>


<!-- And print out name if we have it -->

<perl handler="hello" run="+{name}">
Hello ${name}, pleased to meet you.
</perl>

</body>
</html>

__PERL__

sub hello {
    my $self=shift();

    #  Get CGI instance
    #
    my $cgi_or=$self->CGI();

    #  Use CGI.pm param() method. Could also use other
    #  methods like keywords(), Vars() etc.
    #
    my $name=$cgi_or->param('name');

    $self->render( name=>$name);
}
```

[Run](https://demo.webdyne.org/example/cgi3.psp)

From there you can all any method supported by the CGI::Simple module -
see the CGI::Simple manual page (`man CGI::Simple`) or review on CPAN:
[CGI::Simple](https://metacpan.org/pod/CGI::Simple)

!!! note

    WebDyne actually wraps the CGI::Simple object to emulate aspects of a
    Plack::Request handler, including supporting Hash::MultiValue
    parameters. For the most part this is transparent but something to be
    aware of if working with parameters which may have multiple values.

Since one of the most common code tasks is to access query parameters,
WebDyne stores them in the special `%_` global variable before any user
defined Perl methods are called. For example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name:
<p><textfield name="name">
<p><submit>
</form>

<!-- Use the %_ global var, other options below -->
<p>
Hello <? uc($_{'name'} || 'Anonymous') ?>, pleased to meet you.


<!-- Quick and dirty, no perl code at all -->

<p>
Hello +{name}, pleased to meet you.


<!-- Traditional, using the CGI::Simple param() call in the hello1 sub -->

<p>
<perl handler="hello1">
Hello ${name}, pleased to meet you.
</perl>


<!-- Quicker method using %_ global var in the hello2 sub -->

<p>
<perl handler="hello2">
Hello ${name}, pleased to meet you.
</perl>


<!-- Quick and dirty using inline Perl. Note use of \ to prevent error if param empty -->

<p>
Hello !{! \$_{name} !}, pleased to meet you.

</body>
</html>


__PERL__

sub hello1 {
    my $self=shift();
    my $cgi_or=$self->CGI();
    my $name=$cgi_or->param('name');
    $self->render( name=>$name);
}

sub hello2 {

    my $self=shift();

    #  Quicker method of getting name param
    #
    my $name=$_{'name'};
    $self->render( name=>$name);
}
```

[Run](https://demo.webdyne.org/example/cgi4.psp)

!!! note

    Values stored in the `%_` variable are single value only, and reflect
    the "last" value of any multivalue parameter supplied. The `%_` variable
    is a convenience for simple access - if more complex operations are
    required use the `CGI()` object.

# Advanced Usage {#advanced_usage}

A lot of tasks can be achieved just using the basic features detailed
above. However there are more advanced features that can make life even
easier

## Deploying WebDyne apps with Docker

After validating a WebDyne application locally, the published WebDyne
container can be used as a base image for packaging the application and
its Perl dependencies.

The WebDyne container can be used as the basis for new docker images
containing your application files. Consider the following directory
structure (available from Github as
[aspeer/psp-WebDyne-Fortune](https://github.com/aspeer/psp-WebDyne-Fortune):

    psp-WebDyne-Fortune/
    ├── app.pm
    ├── app.psp
    ├── cpanfile
    ├── Dockerfile
    └── webdyne.conf.pl

Where:

app.psp

:   The main and default psp file

app.pm

:   Perl code used in the psp file

cpanfile

:   A list of Perl modules to be installed in the docker container by
    cpanm

Dockerfile

:   The docker build file

webdyne.conf.pl

:   Any variables to be set for the WebDyne environment

Constitute all the files needed to stand up a WebDyne based application
in a Docker container. The contents of the Dockerfile are minimal:

    FROM webdyne:latest
    WORKDIR /app
    # Debian packages needed for this app
    RUN apt-get update && apt-get -y install fortunes
    COPY app.* .
    COPY cpanfile .
    COPY webdyne.conf.pl /etc

Build the Docker container:

    docker build  -t webdyne-app-fortune -f ./Dockerfile .

And run it:

    $ docker run -e PORT=5010 -p 5010:5010 --name=webdyne-app-fortune webdyne-app-fortune

Your application should now be available:

![](images/webdyne-app-fortune1.png)

## Blocks

Blocks are a powerful dynamic content generation tool. WebDyne can
render arbitrary blocks of text or HTML within a page, which makes
generation of dynamic content generally more readable than similar
output generated within Perl code. An example:

``` html
<html>
<head>
<title>Blocks</title>
</head>
<body>
<p>

<form>
2 + 2 = <textfield name="sum">
<p><submit>
</form>

<p>
<perl handler="check">


<!-- Each block below is only rendered if specifically requested by the Perl code -->

<block name="pass">
Yes, +{sum} is the correct answer ! Brilliant ..
</block>

<block name="fail">
I am sorry .. +{sum} is not correct .. Please try again !
</block>

<block name="silly">
Danger, does not compute ! .. "+{sum}" is not a number !
</block>

<p>
Thanks for playing !

</perl>

</body>
</html>

__PERL__

sub check {

    my $self=shift();

    if ((my $ans=$_{'sum'}) == 4) {
        $self->render_block('pass')
    }
    elsif ($ans=~/^[0-9.]+$/) {
        $self->render_block('fail')
    }
    elsif ($ans) {
        $self->render_block('silly')
    }

    #  Blocks aren't displayed until whole section rendered
    #
    return $self->render();

}

```

[Run](https://demo.webdyne.org/example/block1.psp)

There can be more than one block with the same name - any block with the
target name will be rendered:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name:
<p><textfield name="name">
<p><submit>
</form>

<perl handler="hello">


<!-- The following block is only rendered if we get a name - see the perl
    code -->

<block name="greeting">
Hello +{name}, pleased to meet you !
<p>
</block>


<!-- This text is always rendered - it is not part of a block -->

The time here is !{! localtime() !}


<!-- This block has the same name as the first one, so will be rendered
    whenever that one is -->

<block name="greeting">
<p>
It has been a pleasure to serve you, +{name} !
</block>


</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();

    #  Only render greeting blocks if name given. Both blocks
    #  will be rendered, as the both have the name "greeting"
    #
    if ($_{'name'}) {
        $self->render_block('greeting');
    }

    $self->render();
}
```

[Run](https://demo.webdyne.org/example/block2.psp)

Like any other text or HTML between &lt;perl&gt; tags, blocks can take
parameters to substitute into the text:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
<form>
Enter your name: <textfield name="name">
&nbsp;
<submit>
</form>

<perl handler="hello">


<!-- This block will be rendered multiple times, the output changing depending
    on the variables values supplied as parameters -->

<block name="greeting">
${i} .. Hello +{name}, pleased to meet you !
<p>
</block>

The time here is <? localtime() ?>

</perl>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();

    #  Only render greeting blocks if name given. Both blocks
    #  will be rendered, as the both have the name "greeting"
    #
    if ($_{'name'}) {
        for(my $i=0; $i<3; $i++) {
            $self->render_block('greeting', i=>$i );
        }
    }

    $self->render();
}
```

[Run](https://demo.webdyne.org/example/block3.psp)

Blocks have a non-intuitive feature - they still display even if they
are outside of the &lt;perl&gt; tags that made the call to render them. e.g.
the following is OK:

``` html
<html>
<head><title>Hello World</title></head>

<body>

<!-- Perl block with no content -->
<perl handler="hello">
</perl>

<p>

<!-- This block is not enclosed within the <perl> tags, but will still render -->
<block name="hello">
Hello World
</block>

<p>

<!-- So will this one -->
<block name="hello">
Again
</block>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    $self->render_block('hello');

}
```

[Run](https://demo.webdyne.org/example/block4.psp)

You can mix the two styles:

``` html
<html>
<head><title>Hello World</title></head>

<body>
<perl handler="hello">

<!-- This block is rendered -->
<block name="hello">
Hello World
</block>

</perl>

<p>
<!-- So is this one, even though it is outside the <perl>..</perl> block -->
<block name="hello">
Again
</block>

</body>
</html>

__PERL__

sub hello {

    my $self=shift();
    $self->render_block('hello');
    $self->render();

}
```

[Run](https://demo.webdyne.org/example/block5.psp)

You can use the &lt;block&gt; tag display attribute to hide or show a block,
or use a CGI parameter to determine visibility (e.g for a status update
or warning):

``` html
<start_html>

<!-- Form to get block toggle status. Update hidden param based on toggle button -->
<form>
<submit name="button" value="Toggle">
<hidden name="toggle" value="!{! $_{'toggle'} ? 0 : 1 !}">
</form>

<!-- This block will only be displayed if the toggle value is true -->
<block name="toggle1" display="!{! $_{'toggle'} !}">
Toggle On (+{toggle})
</block>
<p>

<!-- This block will always display -->
<block name="hello" display=1>
Hello World
</block>

<!-- This block will never display unless called from a perl handler -->
<block name="hello" display=0>
Goodbye world
</block>
```

[Run](https://demo.webdyne.org/example/block_toggle1.psp)

## File inclusion

You can include other file fragments at compile time using the include
tag:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
The protocols file on this machine:
<pre>
<include file="/etc/protocols">
</pre>
</body>
</html>
```

[Run](https://demo.webdyne.org/example/include1.psp)

If the file name is not an absolute path name is will be loaded relative
to the directory of the parent file. For example if file "`bar.psp`"
incorporates the tag &lt;include file="foo.psp"&gt; it will be expected that
"`foo.psp`" is in the same directory as "`bar.psp`".

!!! important

    The include tag pulls in the target file at compile time. Changes to the
    included file after the WebDyne page is run the first time (resulting in
    compilation) are not reflected in subsequent output unless the `nocache`
    attribute is set. Thus the include tag should not be seen as a shortcut
    to a pseudo Content Management System. For example &lt;include
    file="latest_news.txt"&gt; may not behave in the way you expect. The first
    time you run it the latest news is displayed. However updating the
    "latest_news.txt" file will not result in changes to the output (it will
    be stale).

    If you do use the `nocache` attribute the included page will be loaded
    and parsed every time, significantly slowing down page display. There
    are betters ways to build a CMS with WebDyne - use the include tag
    sparingly !

You can include just the head or body section of a HTML or PSP file by
using the head or body attributes. Here is the reference file (file to
be included). It does not have to be a PSP file - a standard HTML file
can be supplied :

``` html
#  This file is named include2.psp and used in the next example
#
<start_html title="Include Head Title">
Body from include2.psp file
```

[Run](https://demo.webdyne.org/example/include2.psp)

And here is the generating file (the file that includes sections from
the reference file).

``` html
<html>
<head>
<include head file="./include2.psp">
</head>
<body>
<include body file="./include2.psp">
Body from include3.psp file
```

[Run](https://demo.webdyne.org/example/include3.psp)

You can also include block sections from `PSP` files. If this is the
reference file (the file to be included) containing two blocks. This is
a renderable `PSP` file in it's own right. The blocks use the `display`
attribute to demonstrate that they will produce output, but it's not
required:

``` html
<start_html>
<p>
<block name="block1" display>
This is block 1
</block>

<p>
<block name="block2" display>
This is block 2
</block>
```

[Run](https://demo.webdyne.org/example/include4.psp)

And here is the file that brings in the blocks from the reference file
and incorporates them into the output:

``` html
<start_html>
This is my master file
<p>
Here is some text pulled from the "include4.psp" file:
<p>
<include file="include4.psp" block="block1">
<p>
And another different block from the same file with caching disabled:
<p>
<include file="include4.psp" block="block2" nocache>
```

[Run](https://demo.webdyne.org/example/include5.psp)

## Static Sections {#static_sections}

Sometimes it is desirable to generate dynamic output in a page once only
(e.g. a last modified date, a sidebar menu etc.) Using WebDyne this can
be done with Perl or CGI code flagged with the "static" attribute. Any
dynamic tag so flagged will be rendered at compile time, and the
resulting output will become part of the compiled page - it will not
change on subsequent page views, or have to be re-run each time the page
is loaded. An example:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
Hello World
<hr>


<!-- Note the static attribute -->

<perl handler="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>

</body>
</html>

__PERL__

sub mtime {

    my $self=shift();
    my $r=$self->request();

    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/example/static1.psp)

In fact the above page will render very quickly because it has no
dynamic content at all once the &lt;perl&gt; content is flagged as static.
The WebDyne engine will recognise this and store the page as a static
HTML file in its cache. Whenever it is called WebDyne will use the
Apache lookup_file() or equivalent Plack function to return the page as
if it was just serving up static content.

You can check this by looking at the content of the WebDyne cache
directory (usually /var/webdyne/cache). Any file with a ".html"
extension represents the static version of a page.

Of course you can still mix static and dynamic Perl sections:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>
Hello World
<p>

<!-- A normal dynamic section - code is run each time page is loaded -->

<perl handler="server_time">
Current time: ${time}
</perl>
<hr>

<!-- Note the static attribute - code is run only once at compile time -->

<perl handler="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>


</body>
</html>

__PERL__


sub server_time {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();

    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/example/static2.psp)

If you want the whole pages to be static, then flagging everything with
the "static" attribute can be cumbersome. There is a special meta tag
which flags the entire page as static:

``` html
<html>
<head>

<!-- Special meta tag -->
<meta name="WebDyne" content="static=1">

<title>Hello World</title>
</head>
<body>
<p>
Hello World
<hr>


<!-- A normal dynamic section, but because of the meta tag it will be frozen
    at compile time -->

<perl handler="server_time">
Current time: ${time}
</perl>

<!-- Note the static attribute. It is redundant now the whole page is flagged
    as static - it could be removed safely. -->

<p>
<perl handler="mtime" static="1">
<em>Last Modified: </em>${mtime}
</perl>


</body>
</html>

__PERL__


sub server_time {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();

    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/example/static3.psp)

If you don't like the idea of setting the static flag in meta data, then
"using" the special package "WebDyne::Static" will have exactly the same
effect:

``` html
<html>
<head>
<title>Hello World</title>
</head>
<body>
<p>
Hello World
<hr>

<perl handler="server_time">
Current time: ${time}
</perl>

<p>

<perl handler="mtime">
<em>Last Modified: </em>${mtime}
</perl>

</body>
</html>

__PERL__


#  Makes the whole page static
#
use WebDyne::Static;


sub server_time {

    shift()->render(time=>scalar localtime);

}


sub mtime {

    my $self=shift();
    my $r=$self->request();

    my $srce_pn=$r->filename();
        my $srce_mtime=(stat($srce_pn))[9];
    my $srce_localmtime=localtime $srce_mtime;

        return $self->render( mtime=>$srce_localmtime )

}
```

[Run](https://demo.webdyne.org/example/static3a.psp)

If the static tag seems trivial consider the example that displayed
country codes:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl handler="countries">
<popup_menu values="${countries_ar}" default="Australia">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {

    my $self=shift();
    my @countries = sort { $a cmp $b } all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/example/cgi5.psp)

Every time the above example is viewed the Country Name list is
generated dynamically via the Locale::Country module. This is a waste of
resources because the list changes very infrequently. We can keep the
code neat but gain a lot of speed by adding the `static` tag attribute:

``` html
<html>
<head><title>Hello World</title></head>
<body>
<p>

<!-- Generate all country names for picklist -->

<form>

Your Country ?
<perl handler="countries" static="1">

<!-- Note the addition of the static attribute -->

<popup_menu values="${countries_ar}">
</perl>

</form>
</body>
</html>

__PERL__

use Locale::Country;

sub countries {

    my $self=shift();
    my @countries = sort {$a cmp $b} all_country_names();
    $self->render( countries_ar=>\@countries );

}
```

[Run](https://demo.webdyne.org/example/static4.psp)

By simply adding the "static" attribute output on a sample machine
resulted in a 4x speedup in page loads. Judicious use of the static tag
in places with slow changing data can markedly increase efficiency of
the WebDyne engine.

## Caching {#caching_section}

WebDyne has the ability to cache the compiled version of a dynamic page
according to specs you set via the API. When coupled with pages/blocks
that are flagged as static this presents some powerful possibilities.

!!! important

    Caching will only work effectively if `$WEBDYNE_CACHE_DN` is defined and
    set to a directory that the web server has write access to. If caching
    does not work check that `$WEBDYNE_CACHE_DN` is defined and permissions
    set correctly for your web server.

There are many potential examples, but consider this one: you have a
page that generates output by making a complex query to a database,
which takes a lot of CPU and disk IO resources to generate. You need to
update the page reasonably frequently (e.g. a weather forecast, near
real time sales stats), but can't afford to have the query run every
time someone view the page.

WebDyne allows you to configure the page to cache the output for a
period of time (say 5 minutes) before re-running the query. In this way
users sees near real-time data without imposing a high load on the
database/Web server.

WebDyne knows to enable the caching code by looking for a meta tag, or
by loading the `WebDyne::Cache` module in a \_\_PERL\_\_ block.

The cache code can command WebDyne to recompile a page based on any
arbitrary criteria it desires. As an example the following code will
recompile the page every 10 seconds. If viewed in between refresh
intervals WebDyne will serve up the cached HTML result using Apache
`$r->lookup_file()` or the FCGI equivalent, which is very fast.

Try it by running the following example and clicking refresh a few times
over a 20 second interval

``` html
<html>
<head>
<title>Caching</title>
<!-- Set static and cache meta parameters -->
<meta name="WebDyne" content="cache=&cache">
</head>

<body>
<p>
This page will only update the time once every 10 seconds. Click refresh to test.
<p>
Hello World !{! localtime() !}
<p>
<button onclick="location.reload()">Refresh</button>
</body>
</html>

__PERL__


#  The following would work in place of the meta tags
#
#use WebDyne::Cache (\&cache);


sub cache {

    my $self=shift();

    #  Get cache file mtime (modified time)
        #
        my $mtime=${ $self->cache_mtime() };


        #  If older than 10 seconds force recompile
        #
        if ((time()-$mtime) > 10) {
                $self->cache_compile(1)
        };

    #  Done
    #
    return \undef;

}
```

[Run](https://demo.webdyne.org/example/cache1.psp)

You can start to get more advanced in your handling of cached pages by
manipulating the page UUID based on some arbitrary criteria. To extend
our example above: say we have a page that generated sales figures for a
given month. The SQL code to do this takes a long time, and we do not
want to hit the database every time someone loads up the page. However
we cannot just cache the output, as it will vary depending on the month
the user chooses. We can tell the cache code to generate a different
UUID based on the month selected, then cache the resulting output.

The following example simulates such a scenario:

``` html
<!-- Start to cheat by using start/end_html tags to save space -->

<start_html>
<start_form>
Get sales results for:&nbsp;<popup_menu name="month" values="@{qw(January February March)}">
<p>
<submit>
<end_form>

<perl handler="results">
Sales results for +{month}: $${results}
</perl>

<hr>
This page generated: !{! localtime() !}
<end_html>

__PERL__

use WebDyne::Cache (\&cache);

my %results=(

    January     => 20,
    February    => 30,
    March       => 40
);


sub cache {


    #  Get self ref
    #
    my $self=shift();


    #  Change page UUID based on month to cache
    #  reults for that month to static HTML
    #
    if (my $month=$_{'month'}) {

        #  Make sure month is valid
        #
        if (defined(my $uid=$results{$month})) {

            #   It is. Change page UUID (inode) using month as a seed
            #
            $self->inode($uid)

        }

    }


    #  Done
    #
    return \undef;

}


sub results {

    my $self=shift();
    if (my $month=$_{'month'}) {

        #  Could be a really long complex SQL query ...
        #
        my $results=$results{$month};


        #  And display
        #
        return $self->render(results => $results);
    }
    else {
        return \undef;
    }

}
```

[Run](https://demo.webdyne.org/example/cache2.psp)

!!! important

    Take care when using user-supplied input to generate the page UID. There
    is no inbuilt code in WebDyne to limit the number of UID's associated
    with a page. Unless we check it, a malicious user could potentially DOS
    the server by supplying endless random "months" to the above page with a
    script, causing WebDyne to create a new file for each UID - perhaps
    eventually filling the disk partition that holds the cache directory.
    That is why we check the month is valid in the code above.

## Dynamic Interfaces {#dynamic_interfaces}

### JSON

WebDyne has a &lt;json&gt; tag that can be used to present JSON data objects
to Javascript libraries in an output page. Here is a very simple
example:

``` html
<start_html title="Sample JSON Chart" script="https://cdn.jsdelivr.net/npm/chart.js">

<h2>Monthly Sales Chart</h2>

<canvas id="myChart"></canvas>

<json handler="chart_data" id="chartData">

<script>
  // Parse JSON from the script tag
  const data = JSON.parse(document.getElementById("chartData").textContent);

  const ctx = document.getElementById('myChart').getContext('2d');
  new Chart(ctx, {
    type: 'bar', // You can also use 'line', 'pie', etc.
    data: {
      labels: data.labels,
      datasets: [{
        label: 'Sales',
        data: data.values,
      }]
    }
  });
</script>

__PERL__

sub chart_data {

    my %data=(
        labels  => [qw(Jan Feb Mar Apr)],
        values  => [(120, 150, 180, 100)]
    );
    return \%data

}

```

[Run](https://demo.webdyne.org/example/chart1.psp)

If you run it and review the source HTML you will see the JSON data
rendered into the page as &lt;script&gt;&lt;/script&gt; block of type
application/json with an id of "chartData". Any data returned by the
perl routine nominated by the json tag is presented as JSON within that
tag block, and available to Javascript libraries within the page. JSON
data is kept in canonical order by default, which can be adjusted with
the WEBDYNE_JSON_CANONICAL variable if not desired/needed for a very
small speed-up.

Another example demonstrating a table constructed with the Grid.js
library

``` html
<start_html style="@{qw(https://cdn.jsdelivr.net/npm/water.css@2/out/water.css https://unpkg.com/gridjs/dist/theme/mermaid.min.css)}">

  <h1>User Sales Dashboard</h1>

  <!-- Grid container for rendered table -->
  <div id="table"></div>

  <!-- JSON dataset generated by server  -->
  <json id="data" handler="data" pretty>

  <!-- Grid.js table render -->
  <script type=module>

    import { Grid, html } from "https://unpkg.com/gridjs?module";

    // Parse JSON from script tag
    const json = JSON.parse(document.getElementById("data").textContent);

    // Initialize Grid.js
    new Grid({
      columns: [
        { id: "id", name: "ID" },
        { id: "name", name: "Name" },
        { id: "email", name: "Email" },
        { id: "sales", name: "Sales ($)", formatter: cell => `$${cell}` }
      ],
      data: json,
      search: true,
      sort: true,
      pagination: {
        enabled: true,
        limit: 3,
      },
      style: {
        table: { "font-size": "14px" },
        th: { "background-color": "#f5f5f5" },
      },
    }).render(document.getElementById("table"));
  </script>

__PERL__

sub data {

    #  Build dummy data for display by grid.js
    #
    my @rows=(qw(id name email sales));
    my @data=(
        [qw(1 Alice alice@example.com 320)],
        [qw(2 Bob bob@example.com 150)],
        [qw(3 Charles charles@example.com 470)],
        [qw(4 Diana diana@example.com 290)],
        [qw(6 Evan evan@example.com 510)],
    );
    my @json=map {my %data; @data{@rows}=@{$data[$_]}; \%data} (0..$#data);
    return \@json;

}
```

[Run](https://demo.webdyne.org/example/grid1.psp)

### API

WebDyne has the ability to make available a basic REST API facility
using the &lt;api&gt; tag in conjunction with the Router::Simple CPAN
module. Documents that utilise the &lt;api&gt; tag are somewhat unique in
that:

-   There is no need for any other tags in the document besides the
    &lt;api&gt; tag. All other tags are ignored - in fact they are
    discarded.

-   Any PSP file file an &lt;api&gt; tag will only emit JSON data with a
    content type of "`application/json`"

-   The REST api path must correspond to a PSP file at some path level,
    e.g. if your path is `/api/user/42` you must have a file called
    either "`api.psp`" or "`api/user.psp`" in your path.

-   A PSP file can contain multiple &lt;api&gt; tags corresponding to
    different `Router::Simple` routes

-   PSGI and PAGI maintain a basic in-process cache of discovered API
    PSP filenames to avoid repeated filesystem checks. If API filenames
    or API path structure are changed, a server restart may be required
    for the changes to be discovered.

Here is a very simple example. Note the format of the URL in the Run
hyperlink:

``` html
<api handler=uppercase pattern="/api/uppercase/{user}/:id">
<api handler=doublecase pattern="/api/doublecase/{user}/:id">
__PERL__
sub uppercase {

    my ($self, $match_hr)=@_;
    my ($user, $id)=@{$match_hr}{qw(user id)};
    my %data=(
        user => uc($user),
        id   => $id
    );
    return \%data

}

sub doublecase {

    my ($self, $match_hr)=@_;
    my ($user, $id)=@{$match_hr}{qw(user id)};
    my %data=(
        user => join('_', uc($user), lc($user)),
        id   => $id
    );
    return \%data

}
```

[Run uppercase API
example](https://demo.webdyne.org/example/api/uppercase/bob/42)

[Run doublecase API
example](https://demo.webdyne.org/example/api/doublecase/bob/42)

!!! caution

    The &lt;api&gt; tag is still somewhat experimental and is not intended to
    replace a full service API handler. Use with caution

!!! note

    The REST-style API route fallback described above is implemented for the
    PSGI and PAGI adapters. Apache mod_perl does not currently perform this
    automatic route-prefix discovery because WebDyne is invoked only after
    Apache has resolved a request to a `.psp` file. The &lt;api&gt; tag can
    still be processed under Apache when a `.psp` request is explicitly
    routed to WebDyne, but extensionless API paths require suitable Apache
    rewrite or routing configuration.

### HTMX

WebDyne has support for &lt;htmx&gt; tags to supply fragmented HTML to pages
using the [HTMX Javascript Library](https://htmx.org) and similar
libraries such as [Alpine Ajax](https://alpine-ajax.js.org). WebDyne can
support just supplying HTML snippet to pages in response to htmx or
similar calls. HTMX/Alpine Ajax and WebDyne are complementary libraries
which can be combined together to support dynamic pages with in-place
updates from a WebDyne Perl backend.

!!! important

    The htmx javascript library must be activated in any file that utilises
    htmx calls (initiates a `hx-get` or similar operation). The javascript
    can be loaded in any convenient way, via a &lt;start_html&gt; script
    attribute, traditional &lt;script&gt; tags etc.

Here is a simple HTML file (`htmx_demo1.psp`) incorporating HTMX calls
to a backend file called `htmx_time1.psp`. Here is the display file,
`htmx_demo1.psp`

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>Current time</h2>
<p>Click the button below to load time data from the server</p>

<!-- HTMX Trigger Button -->
<button
  hx-get="htmx_time1.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
>
Get Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/example/htmx_demo1.psp)

And the backend file which generates the HTMX data for the above page
(`htmx_time1.psp`):

``` html
<start_html>
<htmx force=1>Server local time: <? localtime() ?> </htmx>
```

[Run](https://demo.webdyne.org/example/htmx_time1.psp)

Note the &lt;htmx&gt; tags. You can run the above htmx resource file and it
will render correctly as a full HTML page - however if WebDyne detects a
'hx-request' HTTP header it will only send the fragment back.

!!! important

    Only one &lt;htmx&gt; section from a file will ever be rendered. You can
    have multiple &lt;htmx&gt; sections in a PSP file however only one can be
    rendered at any time. You can use the display attribute with dynamic
    matching (see later) to render different &lt;htmx&gt; sections in a PSP
    file, or you can keep them all in different files (e.g. one &lt;htmx&gt;
    section per PSP file

!!! important

    Content in &lt;htmx&gt; tags will not be rendered unless a hx-request HTTP
    header is detected, or (as in the above example) the force attribute is
    nominated.

#### Using Perl within &lt;htmx&gt; tags

&lt;htmx&gt; tags can be called with the same attributes as &lt;perl&gt; tags,
including nominating a handler to generate data. See the following
example:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>Current time</h2>
<p>Click the button below to load time data from the server</p>

<!-- HTMX Trigger Button -->
<button
  hx-get="htmx_time2.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
>
Get Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/example/htmx_demo2.psp)

And the backend file which generates the HTMX data for the above page -
now with the HTML fragment generated by Perl:

``` html
<start_html>
<htmx force handler="server_time">
<p>
Server local time: ${server_time}
</htmx>

__PERL__

sub server_time {
    my $self=shift();
    my $time=scalar localtime;
    for (1..3) {
        $self->print( $self->render( server_time=> $time ));
    }
    return \undef;
}
```

[Run](https://demo.webdyne.org/example/htmx_time2.psp)

#### Using multiple &lt;htmx&gt; tags in one PSP file

As is mentioned above only one &lt;htmx&gt; fragment can be returned by a
PSP page at a time - but you can use techniques to select which tag
should be rendered. The &lt;htmx&gt; tag supports the display attribute. If
this attribute exists and is a "true" value then the &lt;htmx&gt; fragment
will be returned. At first this doesn't seem very useful - but when
combined with dynamic evaluation via either page query parameters or
`!{! .. !}` evaluation it becomes more compelling. Take the following
two button example:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>HTMX Demo</h2>
<p>
Click the button below to load time data from the server.</p>

<!-- HTMX Trigger Button for Local Time -->
<button
  style="width:180px"
  hx-get="/htmx_time3.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
  hx-vals="js:{ 'time_local': 1 }"
>
Get Local Time
</button>

<p>

<!-- HTMX Trigger Button for UTC Time -->
<button
  style="width:180px"
  hx-get="/htmx_time3.psp"
  hx-target="#time-container"
  hx-swap="innerHTML"
  hx-vals="js:{ 'time_utc': 1 }"
>
Get UTC Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time-container">
  <em>Time data not loaded yet.</em>
</div>
```

[Run](https://demo.webdyne.org/example/htmx_demo3.psp)

!!! important

    WebDyne does not support single quoted tags - you can use them in PSP
    files, but the rendered HTML will always emit tag attributes as double
    quoted. For attributes such as hx-vals it is not possible to supply JSON
    strings within single quotes, i.e. this will not work: &lt;button
    hx-vals='{ "foo" : "bar" }'&gt; - the single quotes will be emitted as
    double quotes, causing the browser to misinterpret the tag. If you need
    to supply quoted keys uses the `js:{}` syntax above.

Here is the HTML page used by the above example to fetch the requested
time. You can run it, however nothing will be emitted unless you supply
a `?time_local=1` or `?time_utc=1` query parameter in your browser.

``` html
<htmx display="+{time_local}"> Time Local: <? localtime() ?></htmx>
<htmx display="+{time_utc}"> Time UTC: <? gmtime() ?></htmx>
```

[Run](https://demo.webdyne.org/example/htmx_time3.psp)

Normally you would expect to have the hx-get attribute for each button
go to a different PSP page. But in this instance they refer to the same
page. So how do we discriminate ? The key is in the supply of the
hx-vals attribute, which allows us to send query strings to the htmx
resource page. We can then use them to select which &lt;htmx&gt; block is
returned.

!!! note

    Note the use of `js:{ <json> }` notation in the &lt;htmx&gt; `hx-vals`
    attribute. It allows for easier supply of JSON data without needed to
    manipulate/escape double-quotes in raw JSON data. You'll also note there
    is no &lt;start_html&gt; tag. It's not necessary for &lt;htmx&gt; pages.

#### Putting everything in one file

Because &lt;htmx&gt; tag does not render unless a hx-request header is
received we can serve htmx content from the same PSP file that calls it.
Here is an example that brings everything into one file:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
Click button for current server time:
<button hx-get="#" hx-target="#time">Refresh</button>
<p>
<div id="time"><em>Time Not Loaded Yet</div>
<htmx perl>
return localtime
</htmx>
```

[Run](https://demo.webdyne.org/example/htmx_time4.psp)

Or the local/UTC time example converted to run everything from one file:

``` html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
<h2>HTMX Demo</h2>
<p>
Click the button below to load time data from the server.</p>

<!-- HTMX Trigger Button for Local Time -->
<button
  style="width:180px"
  hx-get="#"
  hx-target="#time"
  hx-vals="js:{ 'time_local': 1 }"
>
Get Local Time
</button>

<p>

<!-- HTMX Trigger Button for UTC Time -->
<button
  style="width:180px"
  hx-get="#"
  hx-target="#time"
  hx-vals="js:{ 'time_utc': 1 }"
>
Get UTC Time
</button>

<!-- Where the fetched HTML fragment will go -->
<p>
<div id="time">
<em>Time data not loaded yet.</em>
</div>

<!-- HTMX fragments -->
<htmx display="+{time_local}"> Time Local: <? localtime() ?></htmx>
<htmx display="+{time_utc}"> Time UTC: <? gmtime() ?></htmx>
```

[Run](https://demo.webdyne.org/example/htmx_demo4.psp)

### Server-Sent Events (SSE)

When run in a PAGI environment WebDyne supports Server-Sent Events
(SSE). An async `sse` subroutine can be defined which will be called
when an SSE event stream is requested. The handler can access the
underlying `PAGI::SSE` helper via `$self->r->sse()`.

SSE pages normally declare their event handler through the
&lt;start_html&gt; tag. The bare sse attribute is equivalent to sse=sse, so
WebDyne will call an async subroutine named `sse`. To use a different
handler name, supply it as the attribute value, for example &lt;start_html
sse="my_sse_handler"&gt;.

The following example also uses h3, hr and alpine on &lt;start_html&gt;. The
heading and rule attributes are syntactic shortcuts for simple page
formatting, while alpine is a shortcut that loads the Alpine.js
JavaScript library. See the &lt;start_html&gt; tag reference for the
complete list of shortcuts and options. Longer form HTML, such as
writing a normal &lt;script&gt; tag to load a JavaScript library yourself,
is still supported.

``` html
<start_html title="Progress Bar" h3 hr alpine sse>
<progress id="bar" value="0" max="100"></progress>
<span id="pct">0%</span>

<script>
const bar = document.getElementById('bar');
const pct = document.getElementById('pct');

const es = new EventSource("#");

es.addEventListener("progress", e => {
    const value = parseInt(e.data, 10);
    bar.value = value;
    pct.textContent = value + "%";
});

es.addEventListener("done", () => {
    es.close();
});
</script>

__PERL__
use HTTP::Status qw(HTTP_OK);
use Future::AsyncAwait;

async sub sse {

    #  Get self ref, PAGI::SSE object
    #
    my $self=shift();
    my $sse_or=$self->r->sse();


    #  Send start with some extra headers to discourage buffering
    #
    await $sse_or->start(status => HTTP_OK,
        headers => [
            ['X-Accel-Buffering' => 'no'],
            ['Content-Encoding' => 'identity']
        ]);


    #  Now main loop
    #
    my $progress = 0;
    await $sse_or->every(1, async sub {

        $progress += 10;
        await $sse_or->send_event(
            event => 'progress',
            data  => $progress,
        );

        if ($progress >= 100) {
            await $sse_or->send_event(event => 'done');
            $sse_or->close;  # stop stream
        }
    });

}
```

[Run](https://demo.webdyne.org/example/progress.psp)

If you do not wish to use the &lt;start_html&gt; tag with the sse attribute
you can use a meta tag to denote which subroutine to call for SSE
events, e.g. &lt;meta name="WebDyne" content="sse=sse"&gt;.

### WebSockets

When run in a PAGI environment WebDyne supports WebSockets (WS). An
async `ws` subroutine can be defined which will be called when a PAGI
WebSocket connection is opened. The request object exposes the
underlying PAGI scope and send/receive callbacks, and the handler can
use those to accept the connection and exchange WebSocket messages.

WebSocket pages normally declare their event handler through the
&lt;start_html&gt; tag. The bare ws attribute is equivalent to ws=ws, so
WebDyne will call an async subroutine named `ws`. To use a different
handler name, supply it as the attribute value, for example &lt;start_html
ws="my_ws_handler"&gt;.

As with SSE pages, &lt;start_html&gt; can also use formatting and framework
shortcuts such as h3, hr and alpine. The alpine shortcut loads the
Alpine.js JavaScript library; normal HTML &lt;script&gt; tags can still be
used instead when you want to load JavaScript in the traditional manner.
See the &lt;start_html&gt; tag reference for details.

``` html
<start_html ws title="WebSocket Demo" h3>
<input id="msg" value="Hello from browser">
<button id="send">Send</button>
<pre id="log"></pre>

<script>
  const log = (line) => {
    document.getElementById('log').textContent += line + "\n";
  };

  const ws = new WebSocket(
    `${location.origin.replace(/^http/, "ws")}${location.pathname}`
  );

  ws.onopen = () => log("connected");
  ws.onmessage = (ev) => log("server: " + ev.data);
  ws.onclose = () => log("closed");
  ws.onerror = (ev) => log("error");

  document.getElementById('send').onclick = () => {
    const text = document.getElementById('msg').value;
    log("client: " + text);
    ws.send(text);
  };
</script>
__PERL__
use Future::AsyncAwait;

async sub ws {

    my $self=shift();
    my $r=$self->r();
    my ($scope, $receive, $send) = map {$r->{$_}} qw(scope receive send);

    await $send->({
        type => 'websocket.accept',
    });

    while (1) {
        my $event = await $receive->();

        last if $event->{type} eq 'websocket.disconnect';

        if (defined $event->{text}) {
            my $text=$event->{text}. ' '. scalar localtime;
            await $send->({
                type => 'websocket.send',
                text => "$text",
            });
        }
        elsif (defined $event->{bytes}) {
            await $send->({
                type  => 'websocket.send',
                bytes => $event->{bytes},
            });
        }
    }

    return;
}
```

[Run](https://demo.webdyne.org/example/ws.psp)

If you do not wish to use the &lt;start_html&gt; tag with the ws attribute
you can use a meta tag to denote which subroutine to call for WebSocket
events, e.g. &lt;meta name="WebDyne" content="ws=ws"&gt;.

# Error Handling {#error_handling}

## Dump {#dump_tag}

The &lt;dump&gt; tag is a informational element which can be included in a
page for diagnostic or debugging purposes. It will show various variable
and state values for the page. By default if a &lt;dump&gt; flag is embedded
in a page diagnostic information is not shown unless the `force`
attribute is specified or the `$WEBDYNE_DUMP_FLAG` is set, the latter
allowing the &lt;dump&gt; tag to be embedded into all pages on a site but
not activated unless debugging enabled.

Various diagnostic elements can be displayed - see the &lt;dump&gt; tag
section for information on what they are. In this example all components
are enabled and display is forced:

``` html
<start_html>
<p>
<form>
Your Name: <textfield name="name">
<p>
<submit>
</form>
<dump all force>
```

[Run](https://demo.webdyne.org/example/dump1.psp)

Dump display/hide can be controlled by form parameters or run URI query
strings. In the example below ticking the checkbox or simply appending
"?dump_enable=1" to the URL will display the dump information:

``` html
<start_html>
<p>
<form>
Your Name: <textfield name="name">
<p>
Show Dump: <checkbox name="dump_enable">
<p>
<submit>
</form>
<dump all force="!{! $_{'dump_enable'} !}">
```

[Run](https://demo.webdyne.org/example/dump2.psp)

## Error Messages

Sooner or later something is going to go wrong in your code. If this
happens WebDyne will generate an error showing what the error was and
attempting to give information on where it came from: Take the following
example:

``` html
<start_html title="Error">
Let's divide by zero: !{! my $z=0; return 5/$z !}
<end_html>
```

[Run](https://demo.webdyne.org/example/err1.psp)

If you run the above example an error message will be displayed

![](images/err1.png)

In this example the backtrace is within in-line code, so all references
in the backtrace are to internal WebDyne modules. The code fragment will
show the line with the error.

If we have a look at another example:

``` html
<start_html title="Error">
<perl handler="hello"/>
<end_html>

__PERL__

sub hello {

    die('bang !');

}
```

[Run](https://demo.webdyne.org/example/err2.psp)

And the corresponding screen shot:

![](images/err2.png)

We can see that the error occurred in the "hello" subroutine (invoked at
line 2 of the page) within the perl block on line 9. The 32 digit
hexadecimal number is the page unique ID - it is different for each
page. WebDyne runs the code for each page in a package name space that
includes the page's UID - in this way pages with identical subroutine
names (e.g. two pages with a "hello" subroutine) can be accommodated
with no collision.

## Exceptions

Errors (exceptions) can be generated within a WebDyne page in two ways:

-   By calling die() as shown in example above.

-   By returning an error message via the err() method, exported by
    default.

Examples

    __PERL__


    #  Good
    #
    sub hello {

        return err('no foobar') if !$foobar;

    }

    # Also OK
    #
    sub hello {

        return die('no foobar') if !$foobar;

    }

## Error Checking

So far all the code examples have just assumed that any call to a
WebDyne API method has been successful - no error checking is done.
WebDyne always returns "undef" if an API method call fails - which
should be checked for after every call in a best practice scenario.

``` html
<start_html title="Error">
<perl handler="hello">

Hello World ${foo}

</perl>
<end_html>

__PERL__

sub hello {

    #  Check for error after calling render function
    #
    shift()->render( bar=> 'Again') || return err();

}
```

[Run](https://demo.webdyne.org/example/err3.psp)

You can use the err() function to check for errors in WebDyne Perl code
associated with a page, e.g.:

``` html
<start_html title="Error">
<form>
<submit name="Error" value="Click here for error !">
</form>
<perl handler="foo"/><end_html>

__PERL__

sub foo {

    &bar() || return err();
    \undef;

}

sub bar {

    return err('bang !') if $_{'Error'};
    \undef;
}
```

[Run](https://demo.webdyne.org/example/err4.psp)

Note that the backtrace in this example shows where the error was
triggered from.

# Utilities

## Command Line Utilities {#command_line_utilities}

WebDyne installs several command line utilities for setup, local
development and troubleshooting. Installation location will vary
depending on your distribution - most will default to `/usr/local/bin`,
but may be installed elsewhere in some cases, especially if you have
nominated a `PREFIX` option when using CPAN. The commands provide their
own help or manual output for detailed options.

`wdapacheinit`

:   Runs the WebDyne initialization routines, which create needed
    directories, modify and create Apache .conf files etc.

    [Full manual page](utilities/wdapacheinit.md){.manual-page-new-tab}

`wdcompile`

:   Usage: `wdcompile filename.psp`. Will compile a PSP file and use
    Data::Dumper to display the WebDyne internal representation of the
    page tree structure. Useful as a troubleshooting tool to see how
    HTML::TreeBuilder has parsed your source file, and to show up any
    misplaced tags etc.

    [Full manual page](utilities/wdcompile.md){.manual-page-new-tab}

`wdrender`

:   Usage: `wdrender filename.psp`. Will attempt to render the source
    file to screen using WebDyne. It is useful for testing page output
    from the command line and can exercise fake, PSGI, PAGI and mod_perl
    style request backends for troubleshooting.

    [Full manual page](utilities/wdrender.md){.manual-page-new-tab}

`wddump`

:   Usage: `wddump filename`. Where filename is a compiled WebDyne
    source file (usually in `/var/webdyne/cache`). Will dump out the
    saved data structure of the compiled file.

    [Full manual page](utilities/wddump.md){.manual-page-new-tab}

`wddebug`

:   Usage: `wddebug --status|--enable|--disable`. Enable/disable
    debugging in the WebDyne code. This uses some pretty ugly methods to
    enable debugging in already installed modules by editing the code
    on-disk to re-enable debug calls - do not use in a production
    environment !

    [Full manual page](utilities/wddebug.md){.manual-page-new-tab}

`webdyne.psgi`

:   Used to run WebDyne as a PSGI process- usually invoked by Plack via
    `plackup` or `starman`, but can be run directly for development
    purposes.

    [Full manual page](utilities/webdyne.psgi.md){.manual-page-new-tab}

`webdyne.pagi`

:   Used to run WebDyne as a PAGI application. It can be run directly
    for development or used as a PAGI application entry point, including
    PAGI HTTP, SSE and WebSocket request handling where supported by the
    server.

    [Full manual page](utilities/webdyne.pagi.md){.manual-page-new-tab}

`webdyne.apache`

:   Starts a temporary Apache mod_perl instance for local development
    and troubleshooting. It can serve a directory or a single PSP file
    without installing a full system Apache configuration.

    [Full manual
    page](utilities/webdyne.apache.md){.manual-page-new-tab}

`wdlint`

:   Run `perl -c -w` over code in \_\_PERL\_\_ sections on any PSP file
    to check for syntax errors. Will automatically skip HTML code. It
    only checks code in the \_\_PERL\_\_ area, and won't check syntax in
    in-line perl, dynamic attributes etc.

    [Full manual page](utilities/wdlint.md){.manual-page-new-tab}

# Modules

The following module reference pages are generated from markdown sidecar
files maintained beside the Perl modules in `lib`. They are copied into
the MkDocs tree during documentation generation so the source module
documentation only needs to be maintained in one place.

-   [`WebDyne`](modules/WebDyne.md){.manual-page-new-tab}

-   [`WebDyne::CGI`](modules/WebDyne_CGI.md){.manual-page-new-tab}

-   [`WebDyne::CGI::Simple`](modules/WebDyne_CGI_Simple.md){.manual-page-new-tab}

-   [`WebDyne::Cache`](modules/WebDyne_Cache.md){.manual-page-new-tab}

-   [`WebDyne::Chain`](modules/WebDyne_Chain.md){.manual-page-new-tab}

-   [`WebDyne::Chain::Constant`](modules/WebDyne_Chain_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Compile`](modules/WebDyne_Compile.md){.manual-page-new-tab}

-   [`WebDyne::Constant`](modules/WebDyne_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Err`](modules/WebDyne_Err.md){.manual-page-new-tab}

-   [`WebDyne::Err::Constant`](modules/WebDyne_Err_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Filter`](modules/WebDyne_Filter.md){.manual-page-new-tab}

-   [`WebDyne::Filter::Constant`](modules/WebDyne_Filter_Constant.md){.manual-page-new-tab}

-   [`WebDyne::HTML::Tiny`](modules/WebDyne_HTML_Tiny.md){.manual-page-new-tab}

-   [`WebDyne::HTML::TreeBuilder`](modules/WebDyne_HTML_TreeBuilder.md){.manual-page-new-tab}

-   [`WebDyne::Handler`](modules/WebDyne_Handler.md){.manual-page-new-tab}

-   [`WebDyne::Install`](modules/WebDyne_Install.md){.manual-page-new-tab}

-   [`WebDyne::Install::Apache`](modules/WebDyne_Install_Apache.md){.manual-page-new-tab}

-   [`WebDyne::Install::Apache::Constant`](modules/WebDyne_Install_Apache_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Install::Constant`](modules/WebDyne_Install_Constant.md){.manual-page-new-tab}

-   [`WebDyne::PAGI`](modules/WebDyne_PAGI.md){.manual-page-new-tab}

-   [`WebDyne::PAGI::Constant`](modules/WebDyne_PAGI_Constant.md){.manual-page-new-tab}

-   [`WebDyne::PSGI`](modules/WebDyne_PSGI.md){.manual-page-new-tab}

-   [`WebDyne::PSGI::Constant`](modules/WebDyne_PSGI_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Request::Apache`](modules/WebDyne_Request_Apache.md){.manual-page-new-tab}

-   [`WebDyne::Request::Common`](modules/WebDyne_Request_Common.md){.manual-page-new-tab}

-   [`WebDyne::Request::Fake`](modules/WebDyne_Request_Fake.md){.manual-page-new-tab}

-   [`WebDyne::Request::PAGI`](modules/WebDyne_Request_PAGI.md){.manual-page-new-tab}

-   [`WebDyne::Request::PSGI`](modules/WebDyne_Request_PSGI.md){.manual-page-new-tab}

-   [`WebDyne::Request::PSGI::Constant`](modules/WebDyne_Request_PSGI_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Request::PSGI::Static`](modules/WebDyne_Request_PSGI_Static.md){.manual-page-new-tab}

-   [`WebDyne::Session`](modules/WebDyne_Session.md){.manual-page-new-tab}

-   [`WebDyne::Session::Constant`](modules/WebDyne_Session_Constant.md){.manual-page-new-tab}

-   [`WebDyne::Static`](modules/WebDyne_Static.md){.manual-page-new-tab}

-   [`WebDyne::Template`](modules/WebDyne_Template.md){.manual-page-new-tab}

-   [`WebDyne::Util`](modules/WebDyne_Util.md){.manual-page-new-tab}

# Reference

## Tag Reference {#tag_reference}

Reference of WebDyne tags and supported attributes

### Core Tags {#tag_reference_core}

#### &lt;perl&gt; {#tag_perl}

Run Perl code either in-line (between the &lt;perl&gt;..&lt;/perl&gt;) tags, or
non-inline via the subroutine/method nominated by the handler attribute.
If this tag is invoked without a handler attribute, text between the
tags will be interpreted as perl code and executed. If invoked with a
handler attribute, text between the tags will be interpreted as a
template - which can be output by a call to the WebDyne render() method
within the handler.

``` html
<perl
  [handler=METHOD]
  [require=MODULE | FILE]
  [import=FUNCTION [, FUNCTION ...]]
  [param=SCALAR | HASHREF]
  [run]
  [static]
  [file]
  [hidden]
  [display=0]
  [chomp]
  [autonewline]
>
```

handler=METHOD

:   Call an external Perl method from a module, or a subroutine in the
    \_\_PERL\_\_ block at the end of the PSP file. If the handler is
    specified as "fully qualified" module call (e.g.
    `Digest::MD5::md5_hex()`) then a require will be made automatically
    to load the module (`Digest::MD5` in this example)

    ``` html
    #  Call method in the same file
    #
    <perl handler="hello">
    __PERL__
    sub hello {
    ...
    }

    #  Call method in another class
    #
    <perl handler="Digest::MD5::md5_hex()">
    ```

require=MODULE \| FILE

:   Load a Perl module or file needed to support a method call. E.g.
    &lt;perl require="Digest::MD5"/&gt; to load the `Digest::MD5` module.
    Anything with a \[./\\\] character is treated as a file path to a
    Perl file (e.g. "`/home/user/module.pm`"), otherwise it is treated
    as module name ("`Digest::MD5`")

    ``` html
    #  Load a module
    #
    <perl require="Digest::MD5">

    #  Load a file
    #
    <perl require="module.pm">
    ```

import=FUNCTION \[, FUNCTION …\]

:   Import a single or multiple functions into the file namespace. Use a
    single SCALAR for importing one function, or pass an ARRAY reference
    for multiple functions.

    ``` html
    # Import single function
    #
    <perl require="Digest::MD5" import="md5_hex">

    # Import multiple functions
    #
    <perl require="Digest::MD5" import="@{'md5_hex', 'md5_base64'}">
    <perl require="Digest::MD5" import="@{qw(md5_hex md5_base64)}">
    ```

    Imported methods available anywhere in the namespace of that page.

param=SCALAR \| HASHREF

:   Parameters to be supplied to perl routine, can be a single SCALAR
    value (string, numeric etc.) or a HASH reference.

    ``` html
    #  Pass parameters to a handler. Single parameter
    #
    <perl handler="hello" param="Bob">

    #  Pass hash ref
    #
    <perl handler="hello" param="%{ name=> 'Bob', age => 42 }">
    ```

static

:   Boolean flag. The Perl code is run once only and the output cached
    for all subsequent requests. If omitted the code is not cached (i.e.
    it is run each time).

run

:   Boolean flag. If evaluated to a true value exists the code is run,
    if not the code is skipped. If omitted the code is run by default.
    Useful for conditional running of code when a form has been
    submitted or a particular logic threshold reached.

    ``` html
    #  Run code only at 4am
    #
    <perl handler="banner" run="(localtime)[2] == 4">

    #  Run code only if a "name" form parameter supplied, all below equivalent
    #
    <perl handler="hello" run="+{name}"> ...
    <perl handler="hello" run="!{! exists $_{'name'} !}"> ...
    <perl handler="hello" run="!{! defined shift()->CGI->param('name') !}
    ```

file

:   Boolean flag. Force package\|require attribute value to be treated
    as a file, even if it appears to "look like" a module name to the
    loader. Rarely needed, use case would be a Perl module in the
    current directory without an extension.

hidden

:   Boolean flag. The output from the Perl module will be hidden and not
    rendered to the page.

display=0

:   Equivalent to setting hidden attribute.

method=METHOD

:   Compatibility alias for handler. Prefer handler in new documentation
    and examples.

package=PACKAGE

:   Optional package component used when constructing a fully qualified
    handler call. Prefer a fully qualified handler value unless
    separating the package and method names is useful for compatibility
    with older PSP files.

chomp

:   Boolean flag. Any new lines at the end of the output will be
    truncated.

autonewline

:   Boolean flag. A newline character will be inserted between each
    print statement.

#### &lt;json&gt; {#tag_json}

Run Perl code similar to &lt;perl&gt; tag but expects code to return a HASH,
ARRAY ref or plain scalar, which is encoded into JSON, outputting within
a &lt;script&gt; tag with type="application/json". When supplied with an id
attribute this data can be used by any Javascript function in the page.
Takes the same options as the &lt;perl&gt; tag and behaves similarly - if a
handler attribute is given it is called, if the perl attribute is given
text between the &lt;json&gt; tags in treated as in-line perl code and
executed.

``` html
<json
  [id=NAME]
  [handler=METHOD]
  [pretty]
  [canonical]
  [perl]
>
```

id=NAME

:   the DOM ID the &lt;script&gt; tag output from the tag will be given,
    e.g.
    `<script id="mydata" type="application/json">{"foo":1}</script>`

pretty

:   Boolean flag. Use the JSON pretty() method to format the output data
    into something more human readable. Not enabled by default. Enable
    with pretty=1 attribute or globally via `$WEBDYNE_JSON_PRETTY=1`
    configuration setting.

canonical

:   Boolean flag. Use the JSON canonical() method to sort JSON data.
    Enabled by default, disable using canonical=0 attribute value or via
    `$WEBDYNE_JSON_CANONICAL=0` configuration setting.

perl

:   Interpret content between starting and ending &lt;json&gt; tag as perl
    code and run it. The code should return a HASH, ARRAY or BOOLEAN
    value which will then be encoded to JSON data.

handler=METHOD

:   Call the perl method nominated. The code should return a HASH, ARRAY
    or BOOLEAN value which will then be encoded to JSON data.

!!! note

    If returning JSON boolean values in code you should use the JSON::true
    and JSON::false values rather than 0 or 1, e.g.

    ``` html
    <start_html>
    <json handler/>
    ...
    __PERL__
    use JSON:
    sub handler {
        return { enabled => JSON::true }
    }
    ```

#### &lt;block&gt; {#tag_block}

Block of HTML code to be optionally rendered if desired by call to
render_block() Webdyne method:

``` html
<block
  name=NAME
  [display]
  [static]
>
```

name=NAME

:   *Mandatory.* The name for this block of PSP or HTML. Referenced when
    rendering a particular block within perl code, e.g.
    `return $self->render_block("foo")`

display

:   Boolean flag. Force display of this block even if not invoked by
    render_block() method in handler. Useful for prototyping or
    conditional display. Any true value will force display, so this can
    be coupled with a form parameter to only show a block when a form
    has been submitted in a similar form to the &lt;perl&gt; tag run
    attribute.

    ``` html
    #  Only show a block if a name parameter has been supplied
    #
    <block name="showname" display="+{name}">
    Thank you for registering +{name} !
    </block>
    ```

static

:   Boolean flag. This block is rendered once only and the output cached
    for all subsequent requests

#### &lt;include&gt; {#tag_include}

Include HTML, PSP or text from an external file. Can pull in just the
&lt;head&gt;, &lt;body&gt; or a &lt;block&gt; section from another HTML or PSP file.
If pulled in from a PSP file it will be compiled and interpreted in the
context of the current page.

``` html
<include
  file=PATH | ARRAYREF
  [block=NAME]
  [wrap=TAG]
  [head]
  [body]
  [param=HASHREF]
  [nocache]
>
```

file=PATH \| ARRAYREF

:   *Mandatory*. Name of file or files we want to include. Can be
    relative to current directory or absolute path.

head

:   Boolean flag. File is an HTML or PSP file and we want to include
    just the &lt;head&gt; section

body

:   Boolean flag/ File is an HTML or PSP file and we want to include
    just the &lt;body&gt; section.

block=NAME

:   File is a PSP file and we want to include a &lt;block&gt; section from
    that file with the nominated name.

wrap=TAG

:   Wrap the text from a plain file include in the nominated tag. Do not
    use &lt;&gt; symbols, just the plain tag name. This option applies when
    including a file directly, not when extracting head, body, or block
    content from another HTML or PSP file.

    ``` html
    #  Include the protocols file and wrap in <pre>
    #
    <include="/etc/protocols" wrap="pre">
    ```

param=HASHREF

:   Parameter hash supplied while rendering included PSP content. This
    is used when extracting a head, body, or named block from another
    PSP file.

nocache

:   Don't cache the results of the include, bring them in off disk each
    time. Will incur performance penalty

#### &lt;api&gt; {#tag_api}

Respond to a JSON request made from a client. Takes the same options as
the &lt;perl&gt; tag and behaves similarly - if a handler attribute is given
it is called, if the perl attribute is given the text between the
&lt;api&gt; tags is treated as in-line perl code and executed. Responses
from perl code are encoded as JSON and returned.

``` html
<api
  pattern=ROUTE
  [match=ROUTE]
  [destination=HASHREF | dest=HASHREF | data=HASHREF]
  [option=HASHREF | options=HASHREF | constraint=HASHREF | constraints=HASHREF]
  [canonical]
>
```

pattern=ROUTE

:   *Mandatory*. Name of `Router::Simple` pattern we want to serve, e.g.
    /api/{user}/:id. The match attribute is accepted as an alias.

destination=HASHREF \| dest=HASHREF \| data=HASHREF

:   Hash we want to supply to perl routine if match made. See
    `Router::Simple`

option=HASHREF \| options=HASHREF \| constraint=HASHREF \| constraints=HASHREF

:   Match options, GET, PUT etc. `Router::Simple`

canonical

:   Boolean flag. Use the JSON canonical() method to sort JSON response
    data. Enabled by default, disable using canonical=0 attribute value
    or via `$WEBDYNE_JSON_CANONICAL=0` configuration setting.

#### &lt;htmx&gt; {#tag_htmx}

Serve HTML fragments in response to [htmx](https://htmx.org) type
requests (or similar clients). Takes the same options as the &lt;perl&gt;
tag and behaves similarly - if a handler attribute is given it is
called, if the perl attribute is given the text between the &lt;htmx&gt;
tags is treated as in-line perl code and executed.

``` html
<htmx
  [handler=METHOD]
  [perl]
  [display]
  [force]
>
```

display

:   Boolean. If evaluates to true then this &lt;htmx&gt; snippet fires. You
    can have multiple htmx tag sections in a page, but only one can fire
    at a time. Use this attribute in conjunction with dynamic evaluation

    ``` html
    #  Fire htmx tag only if a name parameter matches
    #
    <htmx display="!{! $_{name} eq 'Bob' !}">
    Hello Bob
    </htmx>


    #  Or Alice. Both tags can live in same document as only one will ever fire
    #
    <htmx display="!{! $_{name} eq 'Alice' !}">
    Hello Alice
    </htmx>
    ```

force

:   Boolean. Force the code referenced by a &lt;htmx&gt; tag to run, and
    content be returned/displayed even if the request is not triggered
    by the htmx javascript module (which is determined by looking for a
    `hx-request` HTTP header). Useful for troubleshooting/debugging
    and/or showing what the generated HTML snippet will look like. Can
    be dynamic and be triggered by GET parameter:

    ``` html
    <htmx force="+{debug}">
    This is my output
    </htmx>
    ```

perl

:   Boolean. Interpret content between starting and ending &lt;htmx&gt; tags
    as perl code and run it. Anything returned by the perl code will be
    sent as the HTML fragment.

handler=METHOD

:   Call the perl method nominated. Whatever is returned or rendered by
    the handler will be returned as the HTML fragment.

#### &lt;dump&gt; {#tag_dump}

Display CGI and other parameters in `Data::Dumper` dump format. Useful
for debugging. Only rendered if `$WEBDYNE_DUMP_FLAG` global set to 1 in
WebDyne constants or the display\|force attribute specified (see below).
Useful while troubleshooting or debugging pages.

``` html
<dump
  [display]
  [force]
  [all]
  [cgi]
  [env]
  [lib | inc]
  [constant]
  [dir_config]
  [version]
>
```

display\|force

:   Boolean. Force display even if `$WEBDYNE_DUMP_FLAG` global not set

all

:   Boolean. Display all diagnostic blocks

cgi

:   CGI parameters and query strings are always displayed once dump
    output is enabled.

env

:   Boolean. Display environment variables

lib \| inc

:   Boolean. Display the Perl include paths and loaded module table
    (`@INC` and `%INC`).

constant

:   Boolean. Display WebDyne configuration constants.

dir_config

:   Boolean. Display WebDyne request directory configuration.

version

:   Version strings are always displayed once dump output is enabled.

#### &lt;start_html&gt; {#tag_start_html}

Start a HTML page with all conventional tags. This will produce the
output:

``` html
<html><head><title></title><meta></head><body>
```

with appropriate content attributes as output.

``` html
<start_html
  [title=TEXT]
  [meta=HASHREF]
  [style=URL | ARRAYREF]
  [style_prepend=URL | ARRAYREF]
  [style_append=URL | ARRAYREF]
  [script=URL | ARRAYREF]
  [script_prepend=URL | ARRAYREF]
  [script_append=URL | ARRAYREF]
  [base=URL]
  [target=TARGET]
  [author=EMAIL]
  [include=PATH | ARRAYREF]
  [include_script=PATH | ARRAYREF]
  [include_style=PATH | ARRAYREF]
  [static]
  [cache=METHOD]
  [handler=METHOD]
  [h1 | h2 | h3 | h4 | h5 | h6]
  [hr]
  [sse=METHOD]
  [ws=METHOD]
  [pico]
  [htmx]
  [alpine]
>
```

Any attributes not listed here are passed through to the generated
&lt;html&gt; tag after WebDyne has consumed the page-control attributes. The
shortcut attributes `pico`, `htmx`, and `alpine` are defined by
`WEBDYNE_START_HTML_SHORTCUT_HR` and can be changed or extended in
WebDyne configuration.

Values in `WEBDYNE_START_HTML_PARAM` are applied before attributes from
the page &lt;start_html&gt; tag. If a page supplies the same attribute with
a value, the page value replaces the configured value for that
attribute. For example, style replaces a configured style list, and
script replaces a configured script list. Use style_prepend,
style_append, script_prepend, or script_append when a page should add
resources around configured defaults instead of replacing them.

title=TEXT

:   Content to be inserted into the &lt;title&gt; section tag.

meta=HASHREF

:   Meta section content, supplied as a hash reference. Processing is
    nuanced. Standard *key*=&gt;*value* hash pairs are displayed as &lt;meta
    name=key content=value&gt; meta tags. Pairs of the type
    *"property=name"=&gt;value* are displayed as &lt;meta property=name
    content=value&gt;.

    ``` html
    <start_html meta="%{ author => 'Bob Smith', 'http-equiv=refresh' => '5; url=https://www.example.com' }">
    ```

    Will produce:

    ``` html
    <meta name="author" content="Bob Smith">
    <meta http-equiv="refresh" content="5; url=https://www.example.com" >
    ```

style=URL \| ARRAYREF

:   Stylesheets to load. Values to this attribute will be output as href
    attributes of type rel=stylesheet in a &lt;link&gt; tag.

    ``` html
    <start_html style="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4">
    ```

    Will produce:

    ``` html
    <link href="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4" rel="stylesheet">
    ```

    Array types are supported as values to the style property to allow
    multiple style sheet &lt;link&gt; tags to be created at once, e.g.

    ``` html
    <start_html style="@{
        'https://cdn.jsdelivr.net/npm/water.css@2/out/water.css',
        'https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css'
    }">
    ```

    Will produce:

    ``` html
    <link href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css" rel="stylesheet">
    ```

    Linked stylesheets are emitted before include_style content.

style_prepend=URL \| ARRAYREF; style_append=URL \| ARRAYREF

:   Stylesheets to add before or after the current style value. This is
    useful when `WEBDYNE_START_HTML_PARAM` supplies default styles and a
    page needs to add styles without replacing those defaults.

    ``` html
    <start_html style_append="app.css">
    ```

    The existing style attribute keeps its current override behaviour.
    If style is supplied with style_prepend or style_append, the prepend
    and append values are added around the explicit style value.

script=URL \| ARRAYREF

:   Similar facility to the style attribute. Any values supplied to this
    attribute will be output as src attributes to a &lt;script&gt; tag.

    ``` html
    <start_html script="https://cdn.jsdelivr.net/npm/chart.js">
    ```

    Will produce:

    ``` html
    <script src="https://cdn.jsdelivr.net/npm/chart.js">
    ```

    Anything supplied after the URL section as an anchor will be used in
    the script tag as an attribute, e.g.

    ``` html
    <start_html script="https://cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js#defer&integrity=sha..">
    ```

    Will produce:

    ``` html
    <script defer integrity=sha.. src="https://cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js">
    ```

    As per the style attribute you can supply an array of resources to
    load using the same syntax.

    External scripts are emitted before include_script content.

script_prepend=URL \| ARRAYREF; script_append=URL \| ARRAYREF

:   Scripts to add before or after the current script value. This is
    useful when `WEBDYNE_START_HTML_PARAM` supplies default scripts and
    a page needs to add scripts without replacing those defaults.

    ``` html
    <start_html script_append="app.js">
    ```

    The existing script attribute keeps its current override behaviour.
    If script is supplied with script_prepend or script_append, the
    prepend and append values are added around the explicit script
    value.

base, target = URL, TARGET

:   Generate a &lt;base&gt; tag within the &lt;head&gt; section containing
    attributes equivalent to href=value of the base attribute,
    target=value of the target attribute

    ``` html
    <start_html base="https://example.com" target="_blank">
    ```

    Will produce:

    ``` html
    <base href="https://example.com/" target="_blank">
    ```

author=EMAIL

:   Generate an author link in the &lt;head&gt; section. The supplied value
    is URL encoded and emitted as a &lt;link rel="author"
    href="mailto:..."&gt; tag.

include=PATH \| ARRAYREF

:   Will include the raw text from the nominated file (supplied as the
    value) within the &lt;head&gt; section. No processing is done, the file
    contents are inserted verbatim.

include_script=PATH \| ARRAYREF

:   As per above include attribute, raw text from the nominated file is
    inserted into the &lt;head&gt; section, however it is wrapped in a
    &lt;script&gt; tag. Included scripts are emitted after external scripts
    from the script attribute.

include_style=PATH \| ARRAYREF

:   As per standard include attribute raw text from the nominated file
    is inserted into the &lt;head&gt; section, however it is wrapped in a
    &lt;style&gt; tag. Included styles are emitted after linked stylesheets
    from the style attribute.

static

:   Boolean. If the static attribute is present in the &lt;start_html&gt;
    tag the entire page is designated static. It will be compiled and
    generated once (at first load) and the resulting HTML will be cached
    and served on subsequent loads.

cache=METHOD

:   Use a cache handler to determine how often the page should be
    recompiled. See the [Caching](#caching_section) section. Sample:

    ``` html
    <start_html cache="&cache">
    ```

handler=METHOD

:   Store a page handler method in the compiled page metadata. This is
    used by WebDyne's request dispatch path when a page needs to
    nominate a handler from the &lt;start_html&gt; tag instead of relying on
    surrounding server configuration.

h1 \| h2 \| h3 \| h4 \| h5 \| h6

:   Boolean heading shortcut. If one of these attributes is present and
    a title is available, WebDyne inserts a heading of the requested
    level at the start of the generated &lt;body&gt; using the page title
    text.

    ``` html
    <start_html title="Hello World" h1>
    ```

hr

:   Boolean heading companion shortcut. When used with one of `h1`
    through `h6`, WebDyne inserts an &lt;hr&gt; immediately after the
    generated heading.

    ``` html
    <start_html title="Hello World" h1 hr>
    ```

sse=METHOD

:   Mark the page as providing Server-Sent Events when run through the
    PAGI request layer. The value is stored in WebDyne page metadata and
    names the async subroutine to call for SSE requests. If used as a
    bare boolean attribute, the method name defaults to `sse`.

    ``` html
    <start_html sse>
    ```

ws=METHOD

:   Mark the page as providing WebSocket handling when run through the
    PAGI request layer. The value is stored in WebDyne page metadata and
    names the async subroutine to call for WebSocket requests. If used
    as a bare boolean attribute, the method name defaults to `ws`.

    ``` html
    <start_html ws>
    ```

pico

:   Framework shortcut defined by `WEBDYNE_START_HTML_SHORTCUT_HR`. Adds
    Pico CSS to the style list, using
    `https://cdn.jsdelivr.net/npm/@picocss/pico@latest/css/pico.min.css`
    by default.

    ``` html
    <start_html pico title="Pico Example">
    ```

htmx

:   Framework shortcut defined by `WEBDYNE_START_HTML_SHORTCUT_HR`. Adds
    htmx to the script list, using
    `https://cdn.jsdelivr.net/npm/htmx.org@latest/dist/htmx.min.js` by
    default.

    ``` html
    <start_html htmx>
    ```

alpine

:   Framework shortcut defined by `WEBDYNE_START_HTML_SHORTCUT_HR`. Adds
    Alpine.js to the script list, using
    `https://cdn.jsdelivr.net/npm/alpinejs@latest/dist/cdn.min.js#defer`
    by default. The URL fragment is interpreted as script attributes, so
    the generated &lt;script&gt; tag includes defer.

    ``` html
    <start_html alpine>
    ```

#### &lt;end_html&gt; {#tag_end_html}

End a HTML page. This will produce the &lt;/body&gt;&lt;/html&gt; tags. It is
not strictly necessary as the parser will automatically close dangling
tags if it gets to the end of the file without seeing them, however is
provided for completeness.

### Form Tags {#tag_reference_forms}

#### &lt;popup_menu&gt; {#tag_popup_menu}

Provide a drop-down menu of options for a user to select from. Other
standard HTML &lt;select&gt; attributes are passed through to the generated
element.

``` html
<popup_menu
  name=NAME
  values=ARRAYREF | HASHREF
  [labels=HASHREF]
  [attributes=HASHREF]
  [label=TEXT]
  [multiple]
  [disabled=VALUE | ARRAYREF]
  [selected | defaults | default=VALUE | ARRAYREF]
  [force]
  (standard HTML <select> attributes)
>
```

name=NAME

:   The name associated with this form component. This is the CGI
    parameter to be interrogated for value(s) once the form is
    submitted.

values=ARRAYREF \| HASHREF

:   List of items to be presented in the drop down. If an array ref
    labels will be the same as values. If a hash ref the value will be
    the hash key, the label the hash label. If predictable display order
    matters, use an array ref for values and a separate labels hash ref.

labels=HASHREF

:   If values is presented as an array ref, a hash ref of labels to be
    associated with each value can be supplied.

attributes=HASHREF

:   Hash reference of additional attributes to apply to individual
    &lt;option&gt; elements, keyed by option value.

label=TEXT

:   Wrap the generated &lt;select&gt; element in a &lt;label&gt; element using
    the supplied text.

multiple

:   Boolean. If enabled allows multiple options to be selected. If not
    present (disabled) only one option can be selected.

disabled=VALUE \| ARRAYREF

:   Single (string scalar) item or multiple (array ref) items which
    should be greyed out (not selectable) in menu options.

selected \| defaults \| default=VALUE \| ARRAYREF

:   Single (string scalar) item or multiple (array ref) items which
    should be pre-selected in menu options.

force

:   By default selected values are stateful, and submitted values for
    this field override the configured default or selected values.
    Setting force always uses the configured default or selected values.

#### &lt;radio_group&gt; {#tag_radio_group}

Provide a grouped list of radio buttons for a user to choose from. Only
one radio button item can be selected.

``` html
<radio_group
  name=NAME
  values=ARRAYREF | HASHREF
  [labels=HASHREF]
  [attributes=HASHREF]
  [disabled=VALUE | ARRAYREF]
  [checked | defaults | default=VALUE | ARRAYREF]
  [linebreak]
  [force]
>
```

name=NAME

:   The name associated with this form component. This is the CGI
    parameter to be interrogated for value(s) once the form is
    submitted.

values=ARRAYREF \| HASHREF

:   List of items to be presented. If an array reference, labels will be
    the same as values. If a hash reference the value will be the hash
    key, the label the hash value. If predictable display order matters,
    use an array reference for values and a separate labels hash
    reference.

labels=HASHREF

:   If values is presented as an array ref a hash ref of labels to be
    associated with each value can be supplied.

attributes=HASHREF

:   Hash reference of additional attributes to apply to individual
    &lt;input type="radio"&gt; elements, keyed by radio value.

disabled=VALUE \| ARRAYREF

:   Single (string) or multiple (array ref) of items which should be
    greyed out (not selectable) in radio group items.

checked \| defaults \| default=VALUE \| ARRAYREF

:   Single (string) or multiple (array ref) items which should be
    pre-selected in radio group items. Radio groups can only select one
    value; if multiple defaults are supplied, the first value in sorted
    order is used.

linebreak

:   Separate generated radio items with &lt;br&gt; tags.

force

:   By default checked values are stateful, and submitted values for
    this field override the configured defaults. Setting force always
    uses the configured defaults.

#### &lt;checkbox_group&gt; {#tag_checkbox_group}

Provide a grouped list of checkbox items for a user to choose from.
Multiple checkboxes can be selected.

``` html
<checkbox_group
  name=NAME
  values=ARRAYREF | HASHREF
  [labels=HASHREF]
  [attributes=HASHREF]
  [disabled=VALUE | ARRAYREF]
  [checked | defaults | default=VALUE | ARRAYREF]
  [linebreak]
  [force]
>
```

name=NAME

:   The name associated with this form component. This is the
    `$self->CGI()` parameter to be interrogated for value(s) once the
    form is submitted.

values=ARRAYREF \| HASHREF

:   List of items to be presented. If an array ref labels will be the
    same as values. If a hash ref the value will be the hash key, the
    label the hash label. If predictable display order matters, use an
    array ref for values and a separate labels hash ref.

labels=HASHREF

:   If values is presented as an array ref a hash ref of labels to be
    associated with each value can be supplied.

attributes=HASHREF

:   Hash reference of additional attributes to apply to individual
    &lt;input type="checkbox"&gt; elements, keyed by checkbox value.

disabled=VALUE \| ARRAYREF

:   Single (string) or multiple (array ref) items which should be greyed
    out (not selectable) in checkbox group items.

checked \| defaults \| default=VALUE \| ARRAYREF

:   Single (scalar) or multiple (array ref) items which should be
    pre-selected in checkbox group items.

linebreak

:   Separate generated checkbox items with &lt;br&gt; tags.

force

:   By default checked values are stateful, and submitted values for
    this field override the configured defaults. Setting force always
    uses the configured defaults.

#### &lt;checkbox&gt; {#tag_checkbox}

Single checkbox for a user to select or clear.

``` html
<checkbox
  name=NAME
  [value=VALUE | BOOLEAN]
  [checked]
  [disabled]
  [label=TEXT]
  (standard HTML <input> attributes)
>
```

name=NAME

:   The name associated with this form component. This is the CGI
    parameter to be interrogated for value(s) once the form is
    submitted.

value=VALUE \| BOOLEAN

:   The value to be returned in the CGI parameter if this checkbox is
    ticked (selected). If not supplied defaults to 1.

disabled

:   If present the checkbox will be displayed but cannot be selected.

checked

:   If present the checkbox is initially selected. For the default
    boolean value path, submitted values for the field are stateful and
    override this initial setting.

label=TEXT

:   Wrap the generated checkbox in a &lt;label&gt; element using the
    supplied text.

!!! note

    In order to retain state all checkbox form items will present a hidden
    parameter with the same name as the checkbox. This is notable because
    querying the parameter associated with a checkbox component will always
    return a `Hash::MultiValue` object with two items, the last of which is
    the checkbox value. When using `$self->CGI->param(<checkbox name>)` form
    of query, or `$_{<checkbox name>}` the user selected checkbox value will
    always be returned as a boolean or scalar value. This automatic
    hidden-field and persistence behaviour applies when no explicit value is
    supplied.

#### &lt;scrolling_list&gt; {#tag_scrolling_list}

Presents a scrolling list of options for a user to choose from. It uses
the same attributes as &lt;popup_menu&gt; with the addition of a size
attribute.

``` html
<scrolling_list
  (same attributes as <popup_menu>)
  [size=ROWS]
>
```

size=ROWS

:   Number of rows to make visible in the user interface for the
    scrolling list. If omitted, WebDyne sets this to the number of
    configured values.

#### &lt;textarea&gt; {#tag_textarea}

A text box for freeform text entry. All attributes are the same as the
HTML standard &lt;textarea&gt; tag with attributes:

``` html
<textarea
  name=NAME
  [default=TEXT]
  [label=TEXT]
  [force]
  (all standard HTML <textarea> attributes)
>
```

name=NAME

:   The name associated with this form component. This is the CGI
    parameter to be interrogated for value(s) once the form is
    submitted.

default=TEXT

:   The default content to be pre-filled out in the &lt;textarea&gt;
    component

label=TEXT

:   Wrap the generated &lt;textarea&gt; element in a &lt;label&gt; element using
    the supplied text.

force

:   By default the component is stateful, and user entered text will
    persist after form submission. Setting the force attribute will
    always present the default content regardless of user input.

#### &lt;textfield&gt; {#tag_textfield}

The standard &lt;input type="text"&gt; tag type. User input with this tag is
persistent. Other standard HTML &lt;input&gt; attributes are passed through
to the generated element.

``` html
<textfield
  name=NAME
  [value=TEXT]
  [label=TEXT]
  [force]
  (standard HTML <input> attributes)
>
```

label=TEXT

:   Wrap the generated input in a &lt;label&gt; element using the supplied
    text.

force

:   By default the field is stateful, and submitted values override the
    configured value. Setting force always uses the configured value.

#### &lt;password_field&gt; {#tag_password_field}

The standard &lt;input type="password"&gt; tag type. It uses the same
attributes as &lt;textfield&gt;, with the generated input type set to
`password`.

#### &lt;filefield&gt; {#tag_filefield}

The standard &lt;input type="file"&gt; tag type. It uses the same attributes
as &lt;textfield&gt;, with the generated input type set to `file`. When
querying this parameter after form submission responses will be in the
form of a Plack::Request::Upload object. Example to demonstrate minimal
file upload facility:

``` html
<start_html title="File Upload">
<start_multipart_form>
<filefield name="file" multiple required>
<p>
<submit name=Upload>
<end_form>

<pre>
<perl handler/>
</pre>

__PERL__

use Data::Dumper;
sub handler {

    my $self=shift();
    my $cgi_or=$self->CGI();
    return Dumper($cgi_or->uploads()->flatten);

}
```

#### &lt;image_button&gt; {#tag_image_button}

The standard &lt;input type="image"&gt; tag type. It accepts standard HTML
&lt;input&gt; attributes and supports label wrapping using the same
behaviour as &lt;textfield&gt;.

#### &lt;button&gt; {#tag_button}

The standard HTML &lt;button&gt; element. Standard button attributes and
enclosed content are passed through to the generated element.

#### &lt;submit&gt; {#tag_submit}

The standard &lt;input type="submit"&gt; tag type to initiate form
submission. It accepts standard HTML &lt;input&gt; attributes and supports
label wrapping using the same behaviour as &lt;textfield&gt;.

#### &lt;reset&gt; {#tag_reset}

The standard &lt;input type="reset"&gt; tag type to reset form fields to
their initial values. It accepts standard HTML &lt;input&gt; attributes and
supports label wrapping using the same behaviour as &lt;textfield&gt;.

#### &lt;defaults&gt; {#tag_defaults}

A CGI-style shortcut rendered as a submit input. It is supported for
compatibility with CGI.pm-style form helpers and uses the same
attributes as &lt;submit&gt;.

#### &lt;hidden&gt; {#tag_hidden}

The standard &lt;input type="hidden"&gt; tag type. Standard HTML &lt;input&gt;
attributes are passed through to the generated element.

#### &lt;isindex&gt; {#tag_isindex}

Legacy &lt;isindex&gt; output is supported for compatibility, but the HTML
element is deprecated and should not be used for new pages. Prefer
normal form tags such as &lt;start_form&gt;, &lt;textfield&gt;, and &lt;submit&gt;.

#### &lt;start_form&gt; {#tag_start_form}

Start a form with method=POST. Other standard HTML &lt;form&gt; attributes
are passed through to the generated element.

``` html
<start_form
  [method=METHOD]
  (standard HTML <form> attributes)
>
```

#### &lt;start_multipart_form&gt; {#tag_start_multipart_form}

Start a form with method=POST and enctype="multipart/form-data". Other
standard HTML &lt;form&gt; attributes are passed through to the generated
element. The enctype attribute can be overridden because form attributes
are passed through, but this is normally only useful if you are
deliberately replacing multipart form encoding.

``` html
<start_multipart_form
  [method=METHOD]
  [enctype=ENCODING]
  (standard HTML <form> attributes)
>
```

## Method Reference {#method_reference}

When running Perl code within a WebDyne page the very first parameter
passed to any routine (in-line or in a \_\_PERL\_\_ block) is an
instance of the WebDyne page object (referred to as `$self` in most of
the examples, e.g. `$self->print("Hello World")`). All methods return
undef on failure, and raise an error using the `err()` function. The
following methods are available to any instance of the WebDyne object:

CGI()

:   Returns an instance of a CGI::Simple type object for the current
    request.

r(), request()

:   Returns the current WebDyne request adapter. WebDyne provides a
    common request interface across Apache, PSGI, PAGI and command-line
    render contexts, with backend-specific details available where
    supported.

html_tiny()

:   Returns an instance of the HTML::Tiny object, can be used for
    creating programmatic HTML output

include()

:   Returns HTML derived from a file, using the same parameters as the
    &lt;include&gt; tag

render( &lt;key=&gt;value, key=&gt;value&gt;, .. )

:   Called to render the text or HTML between &lt;perl&gt;..&lt;/perl&gt; tags.
    Optional key and value pairs will be substituted into the output as
    per the variable section. Returns a scalar ref of the resulting
    HTML.

render_block( blockname, &lt;key=&gt;value, key=&gt;valufge, ..&gt;).

:   Called to render a block of text or HTML between
    &lt;block&gt;..&lt;/block&gt; tags. Optional key and value pairs will be
    substituted into the output as per the variable section. Returns
    scalar ref of resulting HTML if called with from &lt;perl&gt;..&lt;/perl&gt;
    section containing the block to be rendered, or true (`\undef`) if
    the block is not within the &lt;perl&gt;..&lt;/perl&gt; section (e.g.
    further into the document, see the block section for an example).
    Rendered blocks must be "published' if visibility required via
    return as array, or return of `$self->render()`.

render_reset()

:   Erase anything previously set to render - it will not be sent to the
    browser. Limited use, may be helpful in error handling to "pull"
    anything previously published and replace with error message.

redirect( uri=&gt;uri \| file=&gt;filename \| html=&gt;\\html_text \| json=&gt;\\json_text \| text=&gt;\\plain_text)

:   Will redirect to URI or file nominated, or display only nominated
    text. Any rendering done to prior to this method is abandoned. If
    supplying HTML text to be rendered supply as a SCALAR reference.
    Content type header will be automatically adjusted to MIME type
    appropriate for type if redirecting to html, json or plain text
    content.

inode( &lt;seed&gt;, &lt;seed&gt; )

:   Returns the page unique ID (UID). Called inode for legacy reasons,
    as that is what the UID used to be based on. If a seed value is
    supplied a new UID will be generated based on an MD5 of the seed(s)
    combined with other information (such as `$r->location`) to generate
    a unique UUID. Seed only needs to be supplied if using cache
    handlers, see the "[Caching](#caching_section)" section

cache_mtime( &lt;uid&gt; )

:   Returns the mtime (modification time) of the cache file associated
    with the optionally supplied UID. If no UID supplied the current one
    will be used. Can be used to make cache compile decisions by
    WebDyne::Cache code (e.g if page &gt; x minutes old, recompile).

source_mtime()

:   Returns the mtime (modification time) of the source PSP file
    currently being rendered.

cache_compile()

:   Force recompilation of cache file. Can be used in cache code to
    force recompilation of a page, even if it is flagged static. Returns
    current value if no parameters supplied, or sets if parameter
    supplied.

filename()

:   Return the full filename (including path) of the file being
    rendered. Will only return the core (main) filename - any included
    files, templates etc. are not reported.

cwd()

:   Return the current working directory WebDyne is operating in.

no_cache()

:   Send headers indicating that the page is not be cached by the
    browser or intermediate proxies. By default WebDyne pages
    automatically set the no-cache headers, although this behaviour can
    be modified by clearing the `$WEBDYNE_NO_CACHE` variable and using
    this function

meta()

:   Return a hash ref containing the meta data for this page.
    Alterations to meta data are persistent for this process, and carry
    across Apache requests (although not across different Apache
    processes)

print( &lt;output&gt; ), printf( &lt;output&gt; ), say( &lt;output&gt; )

:   Render the output of the print(), printf() or say() routines into
    the current HTML stream. The print() and printf() methods emulate
    their Perl functions in not appending a new line into the output
    (unless autonewline() is set), where as say() does.

autonewline()

:   Get or set the autonewline flag. If set will add a new line
    automatically when using print() or `$self->print()`, essentially
    emulating say(). Supply undef or 0 to clear.

render_time()

:   Return the elapsed time since the WebDyne hander started rendering
    this page. Obviously only meaningful if called at the end of a page,
    just before final output to browser.

err( &lt;message&gt; )

:   Return and/or raise an error to the WebDyne handler. Supply the
    actual error message as text.

## Configuration Reference {#configuration_reference}

### Constants {#webdyne_constants}

Constants defined in the WebDyne::Constant package control various
aspects of how WebDyne behaves. Constants can be modified globally by
altering a global configuration file (`/etc/webdyne.conf.pl` under Linux
distros), setting environment variable or by altering configuration
parameters within the Apache web server config.

#### Global constants file

WebDyne will look for a system constants file under
`/etc/webdyne.conf.pl` and set package variables according to values
found in that file. The file is in Perl Data::Dumper format, and takes
the format:

    # sample /etc/webdyne.conf.pl file
    #
    $VAR1={
            WebDyne::Constant => {

                    WEBDYNE_CACHE_DN       => '/data1/webdyne/cache',
                    WEBDYNE_STORE_COMMENTS => 1,
                    #  ... more variables for WebDyne package

           },

           WebDyne::Session::Constant => {

                    WEBDYNE_SESSION_ID_COOKIE_NAME => 'session_cookie',
                    #  ... more variables for WebDyne::Session package

           },

    };

The file is not present by default and should be created if you wish to
change any of the WebDyne constants from their default values.

!!! important

    Always check the syntax of the `/etc/webdyne.conf.pl` file after editing
    by running `perl -c -w /etc/webdyne.conf.pl` to check that the file is
    readable by Perl. Files with syntax errors will fail silently and the
    variables will revert to module defaults.

#### PSGI and PAGI root configuration

When the `webdyne.psgi` or `webdyne.pagi` wrapper builds an application
it also loads `$DOCUMENT_ROOT/.webdyne.conf.pl`, if present. This
applies both when the wrapper is started directly and when it is loaded
by an external PSGI or PAGI server. If the effective document root is a
file, the parent directory is checked for `.webdyne.conf.pl`.

This root configuration file is separate from request-directory
configuration. When `WEBDYNE_DIR_CONFIG_CWD_LOAD` is enabled, WebDyne
can also inspect a `.webdyne.conf.pl` file in the directory of the
current PSP file, but only the `WEBDYNE_DIR_CONFIG` section is used from
that per-directory file.

#### Setting WebDyne constants in Apache

WebDyne constants can be set in an Apache httpd.conf file using the
PerlSetVar directive:

    PerlHandler     WebDyne
    PerlSetVar      WEBDYNE_CACHE_DN                '/data1/webdyne/cache'
    PerlSetVar      WEBDYNE_STORE_COMMENTS          1

    #  From WebDyne::Session package
    #
    PerlSetVar      WEBDYNE_SESSION_ID_COOKIE_NAME  'session_cookie'

!!! important

    WebDyne constants cannot be set on a per-location or per-directory
    basis - they are read from the top level of the config file and set
    globally.

    Some 1.x versions of mod_perl do not read PerlSetVar variables
    correctly. If you encounter this problem use a &lt;Perl&gt;..&lt;/Perl&gt;
    section in the `httpd.conf` file, e.g.:

        # Mod_perl 1.x

        PerlHandler     WebDyne
        <Perl>
        $WebDyne::Constant::WEBDYNE_CACHE_DN='/data1/webdyne/cache';
        $WebDyne::Constant::WEBDYNE_STORE_COMMENTS=1;
        $WebDyne::Session::Constant::WEBDYNE_SESSION_ID_COOKIE_NAME='session_cookie';
        </Perl>

Where you need to set variables without simple string content you can
use a &lt;Perl&gt;..&lt;/Perl&gt; section in the `httpd.conf` file, e.g.:

    # Setting more complex variables

    PerlHandler     WebDyne
    <Perl>
    $WebDyne::Constant::WEBDYNE_CACHE_DN='/data1/webdyne/cache';
    $WebDyne::Constant::WEBDYNE_STORE_COMMENTS=1;
    $WebDyne::Session::Constant::WEBDYNE_SESSION_ID_COOKIE_NAME='session_cookie';
    </Perl>

!!! warning

    The letsencrypt `certbot` utility will error out when trying to update
    any Apache config file with `<Perl>` sections. To avoid this you put the
    variables in a separate file and include them, e.g. in the `apache.conf`
    file:

        # Some config setting defaults. See documentation for full range.
        # Commented out # options represent defaults
        #
        PerlRequire conf.d/webdyne_constant.pl

    And then in the webdyne_constant.pl file:

        use WebDyne;
        use WebDyne::Constant;

        #  Error display/extended display on/off. More granular options below.
        #  Set to 1 to enable, 0 to disable
        #
        $WebDyne::WEBDYNE_ERROR_SHOW=1;
        $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;

        #  Extended error control.
        #
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW=1;
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE=4;
        #  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST=4;

#### Constants Reference

The authoritative reference for constants defined by `WebDyne::Constant`
is maintained with the module sidecar documentation and copied into the
MkDocs module reference during documentation generation.

See [`WebDyne::Constant` module
reference](modules/WebDyne_Constant.md){.manual-page-new-tab} for the
complete list of constants, defaults, and behaviour descriptions.

!!! tip

    Configuration items can be overridden by setting environment variables
    of the same name with the desired value.

Extension modules, for example `WebDyne::Session`, may define their own
constants in their own `WebDyne::*::Constant` packages. See the relevant
module reference pages for details.

### Environment Variable Reference {#environment_variable_reference}

All WebDyne configuration items can be overridden by setting an
environment variable of the same name when starting PSGI or PAGI
instances, or via an Apache SetEnv directive, e.g:

    #  Start webdyne plack instance with extended error display for this run.
    #
    $ WEBDYNE_ERROR_SHOW_EXTENDED=1 plackup `which webdyne.psgi`

In addition to the configuration overrides the following environment
variables are available:

#### WEBDYNE_CONF {#env_webdyne_conf}

Location of the WebDyne configuration file to load. Loading of an
alternate configuration file will bypass loading of any/all other
configuration files (e.g. /etc/webdyne.conf.pl). They are not additive -
only configuration directives in the nominated by this environment
variable will be processed. e.g.

    #  Start webdyne with an alternate config file
    #
    WEBDYNE_CONF=./myconf.pl webdyne.psgi

!!! caution

    Your config file must be valid Perl syntax and in the format expected.
    Always check it with `perl -c -w myconf.pl` to ensure it is correct.

#### DOCUMENT_ROOT {#env_document_root}

The starting home directory or file name (if file rather than directory)
for PSGI and PAGI server wrappers to use. Defaults to the current
working directory if none specified.

#### DOCUMENT_DEFAULT {#env_document_default}

The default file to look for in a directory if none is given via browser
URL. The PSGI and PAGI constant layer defaults this to `app.psp`. The
direct `webdyne.psgi` and `webdyne.pagi` command wrappers enable
WebDyne's built-in index page by default unless `DOCUMENT_DEFAULT`,
`--index=FILE`, or `--no-index` changes that behavior.

#### WEBDYNE_DEBUG {#env_webdyne_debug}

When debugging enabled in modules only (see Troubleshooting). Set to 1
to enable all debugging (extremely verbose), or set to module/subroutine
name to filter down to that area. e.g.

``` text
#  Debug the internal perl routine in WebDyne
#
$ WEBDYNE_DEBUG=perl perl -Ilib bin/wdrender time.psp
[23:28:24.699358 WebDyne (perl)] WebDyne=HASH(0x561d4a271a28) rendering perl tag in block ARRAY(0x561d4aaace20), attr $VAR1 = {
  'inline' => 1,
  'perl' => ' localtime() '
};

[23:28:24.699490 WebDyne (perl)] found inline perl code $VAR1 = \' localtime() ';
, param $VAR2 = undef;

<!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"><link href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css" rel="stylesheet"><link href="/style.css" rel="stylesheet"></head>
<body><h1>Example File</h1><p> The current server time is: Sun Jan 11 23:28:24 2026</p></body></html>
```

#### WEBDYNE_DEBUG_FILTER {#env_webdyne_debug_filter}

When debugging enabled only output debug information that matches the
regex given by this environment variable. Useful to further filter down
to areas of interest.

### Docker Runtime Server Tuning {#docker_runtime_server_tuning}

The published WebDyne Docker images expose server tuning options through
environment variables understood by the default container entrypoint.

Runtime server tuning options can also be supplied through environment
variables. If these variables are not set, the underlying server
defaults are used.

`WEBDYNE_SERVER_PSGI_WORKERS`

:   Sets the `starman` `--workers` option.

`WEBDYNE_SERVER_PSGI_MAX_REQUESTS`

:   Sets the `starman` `--max-requests` option.

`WEBDYNE_SERVER_PSGI_BACKLOG`

:   Sets the `starman` `--backlog` option.

`WEBDYNE_SERVER_PSGI_KEEPALIVE_TIMEOUT`

:   Sets the `starman` `--keepalive-timeout` option.

`WEBDYNE_SERVER_PSGI_READ_TIMEOUT`

:   Sets the `starman` `--read-timeout` option.

`WEBDYNE_SERVER_PAGI_WORKERS`

:   Sets the `pagi-server` `--workers` option.

`WEBDYNE_SERVER_PAGI_MAX_REQUESTS`

:   Sets the `pagi-server` `--max-requests` option.

`WEBDYNE_SERVER_PAGI_LISTENER_BACKLOG`

:   Sets the `pagi-server` `--listener-backlog` option.

`WEBDYNE_SERVER_PAGI_TIMEOUT`

:   Sets the `pagi-server` `--timeout` option.

`WEBDYNE_SERVER_PAGI_REQUEST_TIMEOUT`

:   Sets the `pagi-server` `--request-timeout` option.

`WEBDYNE_SERVER_PAGI_MAX_CONNECTIONS`

:   Sets the `pagi-server` `--max-connections` option.

`WEBDYNE_SERVER_PAGI_MAX_BODY_SIZE`

:   Sets the `pagi-server` `--max-body-size` option.

### Directives {#webdyne_directives}

A limited number of directives are are available which change the way
WebDyne processes pages. Directives are set in either the Apache .conf
files and can be set differently per location. At this stage only one
directive applies to the core WebDyne module:

`WebDyneHandler`

:   The name of the handler that WebDyne should invoke instead of
    handling the page internally. The only other handler available today
    is WebDyne::Chain.

This directive exists primarily to allow PSGI to invoke WebDyne::Chain
as the primary handler. It can be used in Apache httpd.conf files, but
is not very efficient:

    #  This will work, but is not very efficient
    #
    <location /shop/>
    PerlHandler     WebDyne
    PerlSetVar      WebDyneHandler               'WebDyne::Chain'
    PerlSetVar      WebDyneChain                 'WebDyne::Session'
    </location>


    #  This is the same, and is more efficient
    #
    <location /shop/>
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain                 'WebDyne::Session'
    </location>

## File Locations {#file_locations}

`/etc/webdyne.conf.pl, ~/.webdyne.conf.pl, $DOCUMENT_ROOT/.webdyne.conf.pl`

:   Used for storage of local constants that override WebDyne defaults.
    See the [WebDyne::Constant](#webdyne_constants) section for details

# Extending WebDyne {#extending_webdyne}

WebDyne can be extended by the installation and use of supplementary
Perl packages. There are several standard packages that come with the
Webdyne distribution, or you can build your own using one of the
standard packages as a template.

The following gives an overview of the standard packages included in the
distribution, or downloadable as extensions from CPAN.

## WebDyne::Chain {#webdyne_chain}

WebDyne::Chain is a module that will cascade a WebDyne request through
one or more modules before delivery to the WebDyne engine. Most modules
that extend WebDyne rely on WebDyne::Chain to get themselves inserted
into the request lifecycle.

Whilst WebDyne::Chain does not modify content itself, it allows any of
the modules below to intercept the request as if they had been loaded by
the target page directly (i.e., loaded in the \_\_PERL\_\_ section of a
page via the "use" or "require" functions).

Using WebDyne::Chain you can modify the behaviour of WebDyne pages based
on their location. The WebDyne::Template module can be used in such
scenario to wrap all pages in a location with a particular template.
Another would be to make all pages in a particular location static
without loading the WebDyne::Static module in each page:

    <Location /static>

    #  All pages in this location will be generated once only.
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Static'

    </Location>

Multiple modules can be chained at once:

    <Location />

    #  We want templating and session cookies for all pages on our site.
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Session WebDyne::Template'
    PerlSetVar      WebDyneTemplate '/path/to/template.psp'

    </Location>

The above example would place all pages within the named template, and
make session information to all pages via `$self->session_id()`. A good
start to a rudimentary CMS.

WebDyneChain

:   Directive. Supply a space separated string of WebDyne modules that
    the request should be passed through.

## WebDyne::Static

Loading WebDyne::Static into a \_\_PERL\_\_ block flags to WebDyne that
the entire page should be rendered once at compile time, then the static
HTML resulting from that compile will be handed out on subsequent
requests. Any active element or code in the page will only be run once.
There are no API methods associated with this module

See the [Static Sections](#static_sections) reference for more
information on how to use this module within an individual page.

WebDyne::Static can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to flag all files in a directory
or location as static. An example httpd.conf snippet:

    <Location /static/>

    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Static'

    </Location>

## WebDyne::Cache

Loading WebDyne::Cache into a \_\_PERL\_\_ block flags to WebDyne that
the page wants the engine to call a designated routine every time it is
run. The called routine can generate a new UID (Unique ID) for the page,
or force it to be recompiled. There are no API methods associated with
this module.

See the [Caching](#caching_section) section above for more information
on how to use this module with an individual page.

WebDyne::Cache can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to flag all files in a
particular location are subject to a cache handling routine. An example
httpd.conf snippet:

    <Location /cache/>

    #  Run all requests through the MyModule::cache function to see if a page should
    #  be recompiled before sending it out
    #
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Cache'
    PerlSetVar      WebDyneCacheHandler '&MyModule::cache'

    </Location>

Note that any package used as the `WebDyneCacheHandler` target should be
already loaded via "PerlRequire" or similar mechanism.

As an example of why this could be useful consider the [caching
examples](#caching_section) above. Instead of flagging that an
individual file should only be re-compiled every "x" seconds, that
policy could be applied to a whole directory with no alteration to the
individual pages.

## WebDyne::Session

WebDyne::Session generates a unique session ID for each browser
connection and stores it in a cookie. It has the following API:

session_id()

:   Function. Returns the unique session id assigned to the browser.
    Call via `$self->session_id()` from perl code.

`$WEBDYNE_SESSION_ID_COOKIE_NAME`

:   Constant. Holds the name of the cookie that will be used to assign
    the session id in the users browser. Defaults to "session". Set as
    per [WebDyne::Constants](#webdyne_constants) section. Resides in the
    `WebDyne::Session::Constant` package namespace.

Example:

    <start_html>

    Session ID: !{! shift()->session_id() !}

    <end_html>

    __PERL__

    use WebDyne::Session;
    1;

[Run](https://demo.webdyne.org/example/session1.psp)

WebDyne::Session can also be used in conjunction with the
[WebDyne::Chain](#webdyne_chain) module to make session information
available to all pages within a location. An example httpd.conf snippet:

    <Location />

    # We want session cookies for our whole site
    #
    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Session'

    #  Change cookie name from "session" to "gingernut" for something different
    #
    PerlSetVar      WEBDYNE_SESSION_ID_COOKIE_NAME    'gingernut'

    </Location>

## WebDyne::Template

One of the more powerful WebDyne extensions. WebDyne::Template can be
used to build CMS (Content Management Systems). It will extract the
&lt;head&gt; and &lt;body&gt; sections from an existing HTML or WebDyne page and
insert them into the corresponding head and body blocks of a template
file.

The merging is done once at compile time - there are no repeated search
and replace operations each time the file is loaded, or server side
includes, so the resulting pages are quite fast.

Both the template and content files should be complete - there is no
need to write the content without a &lt;head&gt; section, or leave out
&lt;html&gt; tags. As a result both the content and template files can be
viewed as standalone documents.

The API:

template ( filename )

:   Function. Set the file name of the template to be used. If no path
    is specified file name will be relative to the current request
    directory

WebDyneTemplate

:   Directive. Can be used to supply the template file name in a Apache
    Dir_Config section, or a the WEBDYNE_DIR_CONFIG section of a
    webdyne.conf.pl file for PSGI

Example:

The template:

``` html
<start_html title="Template" style="@{qw(https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css template1.css https://unpkg.com/gridjs/dist/theme/mermaid.min.css)}">
  <div class="app">
    <header class="topbar">
      <div class="topbar-inner">
        <a class="brand" href="home.psp">
          <div class="logo" aria-hidden="true">WS</div>
          <span>Web Site</span>
        </a>
        <nav aria-label="Top">
          <ul style="margin:0; padding:0; display:flex; gap:0.75rem; list-style:none;">
            <li><a href="#" class="secondary" role="button" style="padding:0.45rem 0.75rem;">Sign in</a></li>
          </ul>
        </nav>
      </div>
    </header>

    <aside class="sidebar" aria-label="Sidebar">
      <div class="sidebar-inner">
        <h6 style="margin-bottom:0.75rem;">Menu</h6>
        <ul class="navlist">
          <li><a href="template_home1.psp" aria-current="page">Home</a></li>
          <li><a href="template_content1.psp">Content</a></li>
          <li><a href="template_about1.psp">About</a></li>
          <li><a href="template_dump1.psp">Dump</a></li>
        </ul>
      </div>
    </aside>

    <main id="home" tabindex="-1">
      <div class="main-inner">
    <block name="body">
    Template Content
    </block>
      </div>
    </main>

    <footer>
      <div class="footer-inner">
        <small>Copyright 2025 Some Web Site. Built with WebDyne using pico.css</small>
      </div>
    </footer>
  </div>
<end_html>
```

[Run](https://demo.webdyne.org/example/template1.psp)

The content, run to view resulting merge:

    <start_html title="Home">
    <h1>Home Content</h1>
    <p>
    Home Page: <? localtime ?>
    <p>
    Click the content menu item to display demo data from the JSON example using an &lt;include&gt; tag
    __PERL__
    use WebDyne::Template qw(template1.psp);

[Run](https://demo.webdyne.org/example/template_home1.psp)

In real life it is not desirable to put the template name into every
content file (as was done in the above example), nor would we want to
have to "use WebDyne::Template" in every content file.

To overcome this WebDyne::Template can read the template file name using
the Apache `dir_config` function, and assign a template on a per
location basis using the WebDyneTemplate directive. Here is a sample
`httpd.conf` file:

    <Location />

    PerlHandler     WebDyne::Chain
    PerlSetVar      WebDyneChain    'WebDyne::Template'
    PerlSetVar      WebDyneTemplate '/path/to/template.psp'

    </Location>

Alternatively in a PSGI environment you can create a .webdyne.conf.pl
file in the directory with the template directives as follows:

    $_={
        'WebDyne::Constant' => {
            WEBDYNE_DIR_CONFIG => {
                '' => {
                    'WebDyneHandler'    => 'WebDyne::Chain',
                    'WebDyneChain'      => 'WebDyne::Template',
                    'WebDyneTemplate'   => 'template.psp'
                },
            },
        }
    }

# Troubleshooting

At some stage a PSP file is not going to output what you expect. This
could be for many reasons:

-   Incorrectly closed or matched HTML tags in the source

-   Mismatched quotation symbols for attributes

-   Incorrect syntax in WebDyne tags, code or attributes

-   Failure by the HTML Parser to read complex or unusual HTML

-   A bug in the WebDyne code at runtime

There are several troubleshooting steps:

1.  Does the file render from the command line using `wdrender` ? Are
    there any additional warnings or error messages generated from the
    command line ?

2.  Is the file validly constructed and balanced HTML when read by the
    WebDyne parser ? Use `wdcompile` to check the parsed HTML and check
    for any errors in attributes or tags

3.  Use the `wddebug --enable` and `WEBDYNE_DEBUG=1` environment
    variable to elicit more information

If nothing obvious jumps out put a bug report on the [WebDyne
Github](https://github.com/aspeer/WebDyne) page for the author to
review.

# Credits

WebDyne relies heavily on modules and code developed and open-sourced by
other authors. Without Perl, and Perl modules such as `mod_perl/PSGI`,
`HTML::Tiny`, `HTML::TreeBuilder`, `Storable` and many others, WebDyne
would not be possible. To the authors of those modules - and all the
other modules used to a lesser extent by WebDyne - I convey my thanks.

# Additional Notes {#additional_notes}

Things to note or information not otherwise contained elsewhere:

## About handler and method calling attributes in tags {#additional_notes_handler_attribute_shortcuts}

Some WebDyne attributes name a Perl subroutine to call. In PSP syntax an
attribute with no explicit value is treated as having the attribute name
as its value, so &lt;perl handler&gt; is a shortcut for &lt;perl
handler="handler"&gt;. Defining a `handler` subroutine in the \_\_PERL\_\_
section is therefore the shortest way to make a simple PSP file call
server-side Perl code:

``` html
<start_html>
<perl handler/>

__PERL__

sub handler {
    my $self=shift();
    return "Hello from a handler";
}
```

For clarity, or where a page has more than one callable routine, the
longer form can be used instead. For example &lt;perl
handler="my_handler"&gt; calls `my_handler` and behaves the same way; it
just takes more typing:

``` html
<start_html>
<perl handler="my_handler"/>

__PERL__

sub my_handler {
    my $self=shift();
    return "Hello from my_handler";
}
```

The same bare-attribute convention applies to other handler-style
attributes in the context where those attributes are valid. In &lt;perl&gt;,
&lt;api&gt; and &lt;htmx&gt;, handler names the Perl routine to call. In
&lt;start_html&gt;, sse and ws name the PAGI Server-Sent Events and
WebSocket handlers, so &lt;start_html sse&gt; means &lt;start_html
sse="sse"&gt;, and &lt;start_html ws&gt; means &lt;start_html ws="ws"&gt;. The
cache attribute on &lt;start_html&gt; similarly names the cache handler used
by the caching layer. The method attribute is accepted as a
compatibility synonym for handler on &lt;perl&gt;-style calls, but handler
is preferred in new examples.

## About &lt;start_html&gt; shortcuts {#additional_notes_start_html_shortcuts}

The &lt;start_html&gt; tag exists as a convenience for common page setup. It
expands to normal HTML, including the document type, opening &lt;html&gt;
and &lt;body&gt; tags, and a generated &lt;head&gt; section. It is not a
separate client-side technology; the browser receives ordinary HTML
output.

Some &lt;start_html&gt; attributes are small formatting shortcuts intended
for quick page construction. For example h1 through h6 insert a heading
based on the page title, and hr adds a horizontal rule after that
generated heading. These are useful for quick examples, diagnostics and
small tools, but they can always be replaced with explicit HTML in the
body of the page.

Other &lt;start_html&gt; shortcuts load common frontend libraries or
stylesheets. The built-in shortcuts include pico for Pico CSS, htmx for
htmx, and alpine for Alpine.js. They exist to keep small PSP examples
readable and to avoid repeating common CDN &lt;link&gt; or &lt;script&gt; tags.
For example &lt;start_html alpine&gt; loads the configured Alpine.js script.
Longer form HTML is still supported, so you can load JavaScript or CSS
in the traditional way with explicit &lt;script&gt; and &lt;link&gt; tags, or by
using the script and style attributes documented in the &lt;start_html&gt;
tag reference.

## How to check syntax of a PSP file {#additional_notes_check_psp_syntax}

To check the syntax of a PSP file - or more specifically any Perl code
in the \_\_PERL\_\_ section - you can use the `wdlint` command. Take
this file with an assignment syntax error in the server_time() routine:

``` html
<start_html>
Hello World <? server_time() ?>
__PERL__
#!perl

sub server_time {
    my 2==1; #Error here
}
```

Run the command`wdlint <filename.psp>` to check for syntax error and
report back:

    $ wdlint check.psp
    syntax error at check.psp line 8, near "my 2"
    check.psp had compilation errors.

## How to pass `$self` ref if using processing instructions {#additional_notes_processing_instruction_self}

If you use the processing instruction form of calling a perl method it
will not pass the WebDyne object ref through to your code. You can pass
it by supplying \@\_ as a parameter, or just shift() and your own
parameters:

``` html
<start_html>
Hello World <? server_time(@_) ?>
Hello World <? server_time(shift(), 'UTC' ?>
Hello World <perl handler="server_time" param="UTC"/>
__PERL__

sub server_time {
    #  Now we can get self ref
    my ($self, $timezone)=@_;

    #  Do something and return
    $self->do_something()
}
```

## Use of hash characters for comments in PSP files {#additional_notes_hash_comment_characters}

Any \# characters at the very start of a PSP file (before a &lt;html&gt; or
&lt;start_html&gt;) tag are treated as comments and discarded - they will
not be stored or displayed (they are **not** translated into HTML
comments). This allows easy to read comments at the start of PSP files.
Any \# characters after the first valid tag are not treated specially -
they will be rendered as normal HTML:

``` html
#  This is my server time display file
#
#  VERSION=1.23
#
<start_html>
Server local time is: <? localtime ?>
```

## The &lt;checkbox&gt; tag will always set a hidden form field {#additional_notes_checkbox_hidden_field}

The &lt;checkbox&gt; tag is unusual in that it adds a hidden field (with the
same name as the checkbox) to the HTML page to retain state. Thus if you
are examining the checkbox parameter from CGI via `$_{'checkbox_name'}`
or `$self->CGI->param('checkbox_name')` you may get an array rather than
a single value. The value of the checkbox (boolean, checked or
unchecked, i.e. 1 or 0) will always be the first value returned. So the
code `if ($_{'checkbox_name'}) { .. do_something }` will work as
expected - but just be careful if using in an array context.

## About this documentation {#additional_notes_about_documentation}

This documentation is written with the [XMLMind XML
Editor](https://www.xmlmind.com/xmleditor/), then converted to Markdown
with [pandoc](https://pandoc.org) and displayed using
[MKdocs](https://www.mkdocs.org). The documentation for WebDyne is
maintained on a [Github repository](https://github.com/aspeer/WebDyne).

# Legal Information - Licensing and Copyright {#legal_information}

WebDyne is Copyright © Andrew Speer 2006-2025. WebDyne is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

WebDyne is written in Perl and uses modules from
[CPAN](http://www.cpan.org) (the Comprehensive Perl Archive Network).
CPAN modules are Copyright © the owner/author, and are available in
source form by downloading from CPAN directly. All CPAN modules used are
covered by the [Perl Artistic
License](http://www.perl.com/pub/a/language/misc/Artistic.html)
