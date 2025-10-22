package WWW::Suffit::Server;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server - The Suffit API web-server class

=head1 SYNOPSIS

    use Mojo::File qw/ path /;

    my $root = path()->child('test')->to_string;
    my $app = MyApp->new(
        project_name => 'MyApp',
        project_version => '0.01',
        moniker => 'myapp',
        debugmode => 1,
        loglevel => 'debug',
        max_history_size => 25,

        # System
        uid => 1000,
        gid => 1000,

        # Dirs and files
        homedir => path($root)->child('share')->make_path->to_string,
        datadir => path($root)->child('var')->make_path->to_string,
        tempdir => path($root)->child('tmp')->make_path->to_string,
        documentroot => path($root)->child('www')->make_path->to_string,
        logfile => path($root)->child('log')->make_path->child('myapp.log')->to_string,
        pidfile => path($root)->child('run')->make_path->child('myapp.pid')->to_string,

        # Server
        server_addr => '*',
        server_port => 8080,
        server_url => 'http://127.0.0.1:8080',
        trustedproxies => ['127.0.0.1'],
        accepts => 10000,
        clients => 1000,
        requests => 100,
        workers => 4,
        spare => 2,
        reload_sig => 'USR2',
        no_daemonize => 1,

        # Security
        mysecret => 'Eph9Ce$quo.p2@oW3',
        rsa_keysize => 2048,
        private_key => undef, # Auto
        public_key => undef, # Auto

        # Initialization options
        all_features    => 'no',
        config_opts     => {
            file => path($root)->child('etc')->make_path->child('myapp.conf')->to_string,
            defaults => {foo => 'bar'},
        },
    );

    # Run preforked application
    $app->preforked_run( 'start' );

    1;

    package MyApp;

    use Mojo::Base 'WWW::Suffit::Server';

    sub init { shift->routes->any('/' => {text => 'Hello World!'}) }

    1;

=head1 DESCRIPTION

This module provides API web-server functionality

=head1 OPTIONS

    sub startup {
        my $self = shift->SUPER::startup( OPTION_NAME => VALUE, ... );

        # ...
    }

Options passed as arguments to the startup function allow you to customize
the initialization of plugins at the level of your descendant class, and
options are considered to have higher priority than attributes of the same name.

List of allowed options (pairs of name-value):

=head2 admin_routes_opts

    admin_routes_opts => {
        prefix_path => "/admin",
        prefix_name => "admin",
    }

=over 8

=item prefix_name

    prefix_name => "admin"

This option defines prefix of admin api route name

Default: 'admin'

=item prefix_path

    prefix_path => "/admin"

This option defines prefix of admin api route

Default: '/admin'

=back

=head2 all_features

    all_features => 'on'

This option enables all of the init_* options, which are described bellow

Default: off

=head2 api_routes_opts

    api_routes_opts => {
        prefix_path => "/api",
        prefix_name => "api",
    }

=over 8

=item prefix_name

    prefix_name => "api"

This option defines prefix of api route name

Default: 'api'

=item prefix_path

    prefix_path => "/api"

This option defines prefix of api route

Default: '/api'

=back

=head2 authdb_opts

    authdb_opts => {
        uri => "sqlite://<PATH_TO_DB_FILE>?sqlite_unicode=1",
        cachedconnection => 'on',
        cacheexpiration => 300,
        cachemaxkeys => 1024*1024,
        sourcefile => '/tmp/authdb.json',
    }

=over 8

=item uri, url

    uri => "sqlite:///tmp/auth.db?sqlite_unicode=1",

Default: See config C<AuthDBURL> or C<AuthDBURI> directive

=item cachedconnection

    cachedconnection => 'on',

Default: See config C<AuthDBCachedConnection> directive. Default: on

=item cacheexpire, cacheexpiration

    cacheexpiration => 300,

Default: See config C<AuthDBCacheExpire> or C<AuthDBCacheExpiration> directive. Default: 300

=item cachemaxkeys

    cachemaxkeys => 1024*1024,

Default: See config C<AuthDBCacheMaxKeys> directive. Default: 1024*1024

=item sourcefile

    sourcefile => '/tmp/authdb.json',

Default: See config C<AuthDBSourceFile> directive

=back

=head2 config_opts

    config_opts => { ... }

This option sets L<Mojolicious::Plugin::ConfigGeneral> plugin options

Default:

    `noload => 1` if $self->configobj exists
    `defaults => $self->config` if $self->config is not void

=head2 init_admin_routes

    init_admin_routes => 'on'

This option enables Admin Suffit API routes

Default: off

=head2 init_authdb

    init_authdb => 'on'

This option enables AuthDB initialize

Default: off

=head2 init_api_routes

    init_api_routes => 'on'

This option enables Suffit API routes

Default: off

=head2 init_rsa_keys

    init_rsa_keys => 'on'

This option enables RSA keys initialize

Default: off

=head2 init_user_routes

    init_user_routes => 'on'

This option enables User Suffit API routes

Default: off

=head2 syslog_opts

    syslog_opts => { ... }

This option sets L<WWW::Suffit::Plugin::Syslog> plugin options

Default:

    `enable => 1` if the `Log` config directive is "syslog"

=head2 user_routes_opts

    user_routes_opts => {
        prefix_path => "/user",
        prefix_name => "user",
    }

=over 8

=item prefix_name

    prefix_name => "user"

This option defines prefix of user api route name

Default: 'user'

=item prefix_path

    prefix_path => "/user"

This option defines prefix of user api route

Default: '/user'

=back

=head1 ATTRIBUTES

This class implements the following attributes

=head2 accepts

    accepts => 0,

Maximum number of connections a worker is allowed to accept, before stopping
gracefully and then getting replaced with a newly started worker,
passed along to L<Mojo::IOLoop/max_accepts>

Default: 10000

See L<Mojo::Server::Prefork/accepts>

=head2 cache

The WWW::Suffit::Cache object

=head2 clients

    clients => 0,

Maximum number of accepted connections this server is allowed to handle concurrently,
before stopping to accept new incoming connections, passed along to L<Mojo::IOLoop/max_connections>

Default: 1000

See L<Mojo::Server::Daemon/max_clients>

=head2 configobj

The Config::General object or undef

=head2 acruxconfig

The L<Acrux::Config> object or undef

=head2 datadir

    datadir => '/var/lib/myapp',

The sharedstate data directory (data dir)

Default: /var/lib/<MONIKER>

=head2 debugmode

    debugmode => 0,

If this attribute is enabled then this server is no daemonize performs

=head2 documentroot

    documentroot => '/var/www/myapp',

Document root directory

Default: /var/www/<MONIKER>

=head2 gid

    gid => 1000,
    gid => getgrnam( 'anonymous' ),

This attribute pass GID to set the real group identifier and the effective group identifier for this process

=head2 homedir

    homedir => '/usr/share/myapp',

The Project home directory

Default: /usr/share/<MONIKER>

=head2 logfile

    logfile => '/var/log/myapp.log',

The log file

Default: /var/log/<MONIKER>.log

=head2 loglevel

    loglevel => 'warn',

This attribute performs set the log level

Default: warn

=head2 max_history_size

    max_history_size => 25,

Maximum number of logged messages to store in "history"

Default: 25

=head2 moniker

    moniker => 'myapp',

Project name in lowercase notation, project nickname, moniker.
This value often used as default filename for configuration files and the like

Default: decamelizing the application class

See L<Mojolicious/moniker>

=head2 mysecret

    mysecret => 'dgdfg',

Default secret string

Default: <DEFAULT_SECRET>

=head2 no_daemonize

    no_daemonize => 1,

This attribute disables the daemonize process

Default: 0

=head2 pidfile

    pidfile => '/var/run/myapp.pid',

The pid file

Default: /tmp/prefork.pid

See L<Mojo::Server::Prefork/pid_file>

=head2 project_name

    project_name => 'MyApp',

The project name. For example: MyApp

Default: current class name

=head2 private_key

    private_key => '...'

Private RSA key

=head2 project_version

    project_version => '0.01'

The project version. For example: 1.00

B<NOTE!> This is required attribute!

=head2 public_key

    public_key => '...',

Public RSA key

=head2 requests

    requests => 0,

Maximum number of keep-alive requests per connection

Default: 100

See L<Mojo::Server::Daemon/max_requests>

=head2 reload_sig

    reload_sig => 'USR2',
    reload_sig => 'HUP',

The signal name that will be used to receive reload commands from the system

Default: USR2

=head2 rsa_keysize

    rsa_keysize => 2048

RSA key size

See C<RSA_KeySize> configuration directive

Default: 2048

=head2 server_addr

    server_addr => '*',

Main listener address (host)

Default: * (::0, 0:0:0:0)

=head2 server_port

    server_port => 8080,

Main listener port

Default: 8080

=head2 server_url

    server_url => 'http://127.0.0.1:8080',

Main real listener URL

See C<ListenAddr> and C<ListenPort> configuration directives

Default: http://127.0.0.1:8080

=head2 spare

    spare => 0,

Temporarily spawn up to this number of additional workers if there is a need.

Default: 2

See L<Mojo::Server::Prefork/spare>

=head2 tempdir

    tempdir => '/tmp/myapp',

The temp directory

Default: /tmp/<MONIKER>

=head2 trustedproxies

List of trusted proxies

Default: none

=head2 uid

    uid => 1000,
    uid => getpwnam( 'anonymous' ),

This attribute pass UID to set the real user identifier and the effective user identifier for this process

=head2 workers

    workers => 0,

Number of worker processes

Default: 4

See L<Mojo::Server::Prefork/workers>

=head1 METHODS

This class inherits all methods from L<Mojolicious> and implements the following new ones

=head2 init

    $app->init;

This is your main hook into the Suffit application, it will be called at application startup
immediately after calling the Mojolicious startup hook. Meant to be overloaded in a your subclass

=head2 listeners

This method returns server listeners as list of URLs

    $prefork->listen( $app->listeners );

=head2 preforked_run

    $app->preforked_run( COMMAND );
    $app->preforked_run( COMMAND, ...OPTIONS... );
    $app->preforked_run( COMMAND, { ...OPTIONS... } );
    $app->preforked_run( 'start' );
    $app->preforked_run( 'start', prerun => sub { ... } );
    $app->preforked_run( 'stop' );
    $app->preforked_run( 'restart', prerun => sub { ... } );
    $app->preforked_run( 'status' );
    $app->preforked_run( 'reload' );

This method runs your application using a command that is passed as the first argument

B<Options:>

=over 8

=item prerun

    prerun => sub {
        my ($app, $prefork) = @_;

        $prefork->on(finish => sub { # Finish
            my $this = shift; # Prefork object
            my $graceful = shift;
            $this->app->log->debug($graceful
                ? 'Graceful server shutdown'
                : 'Server shutdown'
            );
        });
    }

This option defines callback function that performs operations with prefork
instance L<Mojo::Server::Prefork> befor demonize and server running

=back

=head2 raise

    $app->raise("Mask %s", "val");
    $app->raise("val");

Prints error message to STDERR and exit with errorlevel = 1

B<NOTE!> For internal use only

=head2 reload

The reload hook

=head2 startup

Main L<Mojolicious/startup> hook

=head1 HELPERS

This class implements the following helpers

=head2 authdb

This is access method to the AuthDB object (state object)

=head2 clientid

    my $clientid = $app->clientid;

This helper returns client ID that calculates from C<User-Agent>
and C<Remote-Address> headers:

    md5(User-Agent . Remote-Address)

=head2 gen_cachekey

    my $cachekey = $app->gen_cachekey;
    my $cachekey = $app->gen_cachekey(16);

This helper helps generate the new CacheKey for caching user data
that was got from authorization database

=head2 gen_rsakeys

    my %keysdata = $app->gen_rsakeys;
    my %keysdata = $app->gen_rsakeys( 2048 );

This helper generates RSA keys pair and returns structure as hash:

    private_key => '...',
    public_key  => '...',
    key_size    => 2048,
    error       => '...',

=head2 jwt

This helper makes JWT object with RSA keys and returns it

=head2 token

This helper performs get of current token from HTTP Request headers

=head1 CONFIGURATION

This class supports the following configuration directives

=head2 GENERAL DIRECTIVES

=over 8

=item Log

    Log         Syslog
    Log         File

This directive defines the log provider. Supported providers: C<File>, C<Syslog>

Default: File

=item LogFile

    LogFile     /var/log/myapp.log

This directive sets the path to logfile

Default: /var/log/E<lt>MONIKERE<gt>.log

=item LogLevel

    LogLevel    warn

This directive defines log level.

Available log levels are C<trace>, C<debug>, C<info>, C<warn>, C<error> and C<fatal>, in that order.

Default: warn

=back

=head2 SERVER DIRECTIVES

=over 8

=item ListenURL

    ListenURL http://127.0.0.1:8008
    ListenURL http://127.0.0.1:8009
    ListenURL 'https://*:3000?cert=/x/server.crt&key=/y/server.key&ca=/z/ca.crt'

Directives that specify additional listening addresses in URL form

B<NOTE!> This is a multiple directive

Default: none

=item ListenAddr

    ListenAddr  *
    ListenAddr  0.0.0.0
    ListenAddr  127.0.0.1

This directive sets the master listen address

Default: * (0.0.0.0)

=item ListenPort

    ListenPort  8080
    ListenPort  80
    ListenPort  443

This directive sets the master listen port

Default: 8080

=item Accepts

    Accepts     0

Maximum number of connections a worker is allowed to accept, before
stopping gracefully and then getting replaced with a newly started worker,
defaults to the value of "accepts" in L<Mojo::Server::Prefork>.
Setting the value to 0 will allow workers to accept new connections
indefinitely

Default: 0

=item Clients

    Clients     1000

Maximum number of accepted connections each worker process is allowed to
handle concurrently, before stopping to accept new incoming connections,
defaults to 100. Note that high concurrency works best with applications
that perform mostly non-blocking operations, to optimize for blocking
operations you can decrease this value and increase "workers" instead
for better performance

Default: 1000

=item Requests

    Requests    100

Maximum number of keep-alive requests per connection

Default: 100

=item Spare

    Spare       2

Temporarily spawn up to this number of additional workers if there
is a need, defaults to 2. This allows for new workers to be started while
old ones are still shutting down gracefully, drastically reducing the
performance cost of worker restarts

Default: 2

=item Workers

    Workers     4

Number of worker processes, defaults to 4. A good rule of thumb is two
worker processes per CPU core for applications that perform mostly
non-blocking operations, blocking operations often require more and
benefit from decreasing concurrency with "clients" (often as low as 1)

Default: 4

=item TrustedProxy

    TrustedProxy  127.0.0.1
    TrustedProxy  10.0.0.0/8
    TrustedProxy  172.16.0.0/12
    TrustedProxy  192.168.0.0/16
    TrustedProxy  fc00::/7

Trusted reverse proxies, addresses or networks in C<CIDR> form.
The real IP address takes from C<X-Forwarded-For> header

B<NOTE!> This is a multiple directive

Default: All reverse proxies will be passed

=item Reload_Sig

    Reload_Sig  USR2
    Reload_Sig  HUP

This directive sets the dafault signal name that will be used to receive reload commands from the system

Default: USR2

=back

=head2 SSL/TLS SERVER DIRECTIVES

=over 8

=item TLS

    TLS         enabled

This directive enables or disables the TLS (https) listening

Default: disabled

=item TLS_CA, TLS_Cert, TLS_Key

    TLS_CA      certs/ca.crt
    TLS_Cert    certs/server.crt
    TLS_Key     certs/server.key

Paths to TLS files. Absolute or relative paths (started from /etc/E<lt>MONIKERE<gt>)

B<TLS_CA> - Path to TLS certificate authority file used to verify the peer certificate.
B<TLS_Cert> - Path to the TLS cert file, defaults to a built-in test certificate.
B<TLS_Key> - Path to the TLS key file, defaults to a built-in test key

Default: none

=item TLS_Ciphers, TLS_Verify, TLS_Version

    TLS_Version     TLSv1_2
    TLS_Ciphers     AES128-GCM-SHA256:RC4:HIGH:!MD5:!aNULL:!EDH
    TLS_Verify      0x00

Directives for setting TLS extra data

TLS cipher specification string. For more information about the format see
L<https://www.openssl.org/docs/manmaster/man1/ciphers.html/CIPHER-STRINGS>.
B<TLS_Verify> - TLS verification mode. B<TLS_Version> - TLS protocol version.

Default: none

=item TLS_FD, TLS_Reuse, TLS_Single_Accept

B<TLS_FD> - File descriptor with an already prepared listen socket.
B<TLS_Reuse> - Allow multiple servers to use the same port with the C<SO_REUSEPORT> socket option.
B<TLS_Single_Accept> - Only accept one connection at a time.

=back

=head2 SECURITY DIRECTIVES

=over 8

=item PrivateKeyFile, PublicKeyFile

    PrivateKeyFile /var/lib/myapp/rsa-private.key
    PublicKeyFile  /var/lib/myapp/rsa-public.key

Private and Public RSA key files
If not possible to read files by the specified paths, they will
be created automatically

Defaults:

    PrivateKeyFile /var/lib/E<lt>MONIKERE<gt>/rsa-private.key
    PublicKeyFile  /var/lib/E<lt>MONIKERE<gt>/rsa-public.key

=item RSA_KeySize

    RSA_KeySize     2048

RSA Key size. This is size (length) of the RSA Key.
Allowed key sizes in bits: C<512>, C<1024>, C<2048>, C<3072>, C<4096>

Default: 2048

=item Secret

    Secret      "My$ecretPhr@se!"

HMAC secret passphrase

Default: md5(rsa_private_file)

=back

=head2 ATHORIZATION DIRECTIVES

=over 8

=item AuthDBURL, AuthDBURI

    AuthDBURI "mysql://user:pass@mysql.example.com/authdb \
           ?mysql_auto_reconnect=1&mysql_enable_utf8=1"
    AuthDBURI "sqlite:///var/lib/myapp/auth.db?sqlite_unicode=1"

Authorization database connect string (Data Source URI)
This directive written in the URI form

Default: "sqlite:///var/lib/E<lt>MONIKERE<gt>/auth.db?sqlite_unicode=1"

=item AuthDBCachedConnection

    AuthDBCachedConnection  1
    AuthDBCachedConnection  Yes
    AuthDBCachedConnection  On
    AuthDBCachedConnection  Enable

This directive defines status of caching while establishing of connection to database

See L<WWW::Suffit::AuthDB/cached>

Default: false (no caching connection)

=item AuthDBCacheExpire, AuthDBCacheExpiration

    AuthDBCacheExpiration    300

The expiration time

See L<WWW::Suffit::AuthDB/expiration>

Default: 300 (5 min)

=item AuthDBCacheMaxKeys

    AuthDBCacheMaxKeys  1024

The maximum keys number in cache

See L<WWW::Suffit::AuthDB/max_keys>

Default: 1024*1024 (1`048`576 keys max)

=item AuthDBSourceFile

    AuthDBSourceFile /var/lib/myapp/authdb.json

Authorization database source file path.
This is simple JSON file that contains three blocks: users, groups and realms.

Default: /var/lib/E<lt>MONIKERE<gt>/authdb.json

=item Token

    Token   ed23...3c0a

Development token directive
This development directive allows authorization without getting real C<Authorization>
header from the client request

Default: none

=back

=head1 EXAMPLE

Example of well-structured simplified web application

    # mkdir lib
    # touch lib/MyApp.pm
    # chmod 644 lib/MyApp.pm

We will start by C<MyApp.pm> that contains main application class and controller class

    package MyApp;

    use Mojo::Base 'WWW::Suffit::Server';

    our $VERSION = '1.00';

    sub init {
        my $self = shift;
        my $r = $self->routes;
        $r->any('/' => {text => 'Your test server is working!'})->name('index');
        $r->get('/test')->to('example#test')->name('test');
    }

    1;

    package MyApp::Controller::Example;

    use Mojo::Base 'Mojolicious::Controller';

    sub test {
        my $self = shift;
        $self->render(text => 'Hello World!');
    }

    1;

The C<init> method gets called right after instantiation and is the place where the whole your application gets set up

    # mkdir bin
    # touch bin/myapp.pl
    # chmod 644 bin/myapp.pl

C<myapp.pl> itself can now be created as simplified application script to allow running tests.

    #!/usr/bin/perl -w
    use strict;
    use warnings;

    use Mojo::File qw/ curfile path /;

    use lib curfile->dirname->sibling('lib')->to_string;

    use Mojo::Server;

    my $root = curfile->dirname->child('test')->to_string;

    Mojo::Server->new->build_app('MyApp',
        debugmode => 1,
        loglevel => 'debug',
        homedir => path($root)->child('www')->make_path->to_string,
        datadir => path($root)->child('var')->make_path->to_string,
        tempdir => path($root)->child('tmp')->make_path->to_string,
        config_opts     => {
            noload => 1, # force disable loading config from file
            defaults => {
                foo => 'bar',
            },
        },
    )->start();

Now try to run it

    # perl bin/myapp.pl daemon -l http://*:8080

Now let's get to simplified testing

    # mkdir t
    # touch t/myapp.t
    # chmod 644 t/myapp.t

Full L<Mojolicious> applications are easy to test, so C<t/myapp.t> can be containts:

    use strict;
    use warnings;

    use Test::More;
    use Test::Mojo;

    use Mojo::File qw/ path /;

    use MyApp;

    my $root = path()->child('test')->to_string;

    my $t = Test::Mojo->new(MyApp->new(
        homedir => path($root)->child('www')->make_path->to_string,
        datadir => path($root)->child('var')->make_path->to_string,
        tempdir => path($root)->child('tmp')->make_path->to_string,
        config_opts     => {
            noload => 1, # force disable loading config from file
            defaults => {
                foo => 'bar',
            },
        },
    ));

    subtest 'Test workflow' => sub {

        $t->get_ok('/')
          ->status_is(200)
          ->content_like(qr/working!/, 'right content by GET /');

        $t->post_ok('/' => form => {'_' => time})
          ->status_is(200)
          ->content_like(qr/working!/, 'right content by POST /');

        $t->get_ok('/test')
          ->status_is(200)
          ->content_like(qr/World/, 'right content by GET /test');

    };

    done_testing();

Now try to test

    # prove -lv t/myapp.t

And our final directory structure should be looking like this

    MyApp
    +- bin
    |  +- myapp.pl
    +- lib
    |  +- MyApp.pm
    +- t
    |  +- myapp.t
    +- test
       +- tmp
       +- var
       +- www

Test-driven development takes a little getting used to, but can be a very powerful tool

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::RSA>, L<WWW::Suffit::JWT>, L<WWW::Suffit::API>, L<WWW::Suffit::AuthDB>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.12';

use Mojo::Base 'Mojolicious';

use Carp qw/ carp croak /;
use POSIX qw//;
use File::Spec;

use Mojo::URL;
use Mojo::File qw/ path /;
use Mojo::Home qw//;
use Mojo::Util qw/ decamelize steady_time md5_sum /; # decamelize(ref($self))
use Mojo::Loader qw/ load_class /;
use Mojo::Server::Prefork;

use Acrux::Util qw/ color parse_time_offset randchars /;
use Acrux::RefUtil qw/ as_array_ref as_hash_ref isnt_void is_true_flag /;

use WWW::Suffit::Const qw/
        :general :security :session :dir :server
        AUTHDBFILE JWT_REGEXP
    /;
use WWW::Suffit::Cache;
use WWW::Suffit::RSA;
use WWW::Suffit::JWT;

use constant {
        MAX_HISTORY_SIZE    => 25,
        DEFAULT_SERVER_URL  => 'http://127.0.0.1:8080',
        DEFAULT_SERVER_ADDR => '*',
        DEFAULT_SERVER_PORT => 8080,
    };

# Common attributes
has 'project_name';         # Anonymous
has 'project_version';      # 1.00
has 'server_url';           # http://127.0.0.1:8080
has 'server_addr';          # * (0.0.0.0)
has 'server_port';          # 8080
has 'debugmode';            # 0
has 'configobj';            # Config::General object
has 'acruxconfig';          # Acrux::Config object
has 'cache' => sub { WWW::Suffit::Cache->new };

# Files and directories
has 'documentroot';         # /var/www/<MONIKER>
has 'homedir';              # /usr/share/<MONIKER>
has 'datadir';              # /var/lib/<MONIKER>
has 'tempdir';              # /tmp/<MONIKER>
has 'logfile';              # /var/log/<MONIKER>.log
has 'pidfile';              # /run/<MONIKER>.pid

# Logging
has 'loglevel' => 'warn';   # warn
has 'max_history_size' => MAX_HISTORY_SIZE;

# Security
has 'mysecret' => DEFAULT_SECRET; # Secret
has 'private_key' => '';    # Private RSA key
has 'public_key' => '';     # Public RSA key
has 'rsa_keysize' => sub { shift->conf->latest("/rsa_keysize") };
has 'trustedproxies' => sub { [grep {length} @{(shift->conf->list("/trustedproxy"))}] };

# Prefork
has 'clients' => sub { shift->conf->latest("/clients") || SERVER_MAX_CLIENTS }; # 10000
has 'requests' => sub { shift->conf->latest("/requests") || SERVER_MAX_REQUESTS}; # 100
has 'accepts' => sub { shift->conf->latest("/accepts") }; # SERVER_ACCEPTS is 0 -- by default not specified
has 'spare' => sub { shift->conf->latest("/spare") || SERVER_SPARE }; # 2
has 'workers' => sub { shift->conf->latest("/workers") || SERVER_WORKERS }; # 4
has 'reload_sig' => sub { shift->conf->latest("/reload_sig") // 'USR2' };
has 'no_daemonize';
has 'uid';
has 'gid';

# Startup options as attributes
has [qw/all_features init_rsa_keys init_authdb init_api_routes init_user_routes init_admin_routes/];
has 'config_opts' => sub { {} };
has 'syslog_opts' => sub { {} };
has 'authdb_opts' => sub { {} };
has 'api_routes_opts' => sub { {} };
has 'user_routes_opts' => sub { {} };
has 'admin_routes_opts' => sub { {} };

sub raise {
    my $self = shift;
    say STDERR color "bright_red" => @_;
    $self->log->error((scalar(@_) == 1) ? shift : sprintf(shift, @_));
    exit 1;
}
sub startup {
    my $self = shift;
    my $opts = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $self->project_name(ref($self)) unless defined $self->project_name;
    $self->project_version($self->VERSION) unless defined $self->project_version;
    $self->raise("Incorrect `project_name`") unless $self->project_name;
    $self->raise("Incorrect `project_version`") unless $self->project_version;
    unshift @{$self->plugins->namespaces}, 'WWW::Suffit::Plugin'; # Add another namespace to load plugins from
    push @{$self->routes->namespaces}, 'WWW::Suffit::Server'; # Add Server routes namespace
    my $all_features = is_true_flag($opts->{all_features} // $self->all_features); # on/off

    # Get all ConfigGeneral configuration attributes
    my $config_opts = as_hash_ref($opts->{config_opts} || $self->config_opts) || {};
    if (my $configobj = $self->configobj) {
        $self->raise("The `configobj` must be Config::General object")
            unless ref($configobj) eq 'Config::General';
        $self->config($configobj->getall); # Set config hash
        $config_opts->{noload} = 1 unless exists $config_opts->{noload};
    }

    # Get all Acrux configuration attributes
    if (my $acruxconfig = $self->acruxconfig) {
        $self->raise("The `acruxconfig` must be Acrux::Config object")
            unless ref($acruxconfig) eq 'Acrux::Config';
        $self->config($acruxconfig->config); # Set config hash
        $config_opts->{noload} = 1 unless exists $config_opts->{noload};
    }

    # Init ConfigGeneral plugin
    unless (exists($config_opts->{noload})) { $config_opts->{noload} = 0 }
    unless (exists($config_opts->{defaults})) { $config_opts->{defaults} = as_hash_ref($self->config) }
    $self->plugin('ConfigGeneral' => $config_opts);

    # Syslog
    my $syslog_opts = as_hash_ref($opts->{syslog_opts} || $self->syslog_opts) || {};
    my $syslogen = ($self->conf->latest('/log') && $self->conf->latest('/log') =~ /syslog/i) ? 1 : 0;
    unless (exists($syslog_opts->{enable})) { $syslog_opts->{enable} = $syslogen };
    $self->plugin('Syslog' => $syslog_opts);

    # PRE REQUIRED Plugins
    $self->plugin('CommonHelpers');

    # Logging
    $self->log->level($self->loglevel || ($self->debugmode ? "debug" : "warn"))
        ->max_history_size($self->max_history_size || MAX_HISTORY_SIZE);
    $self->log->path($self->logfile) if $self->logfile;

    # Helpers
    $self->helper('token'       => \&_getToken);
    $self->helper('jwt'         => \&_getJWT);
    $self->helper('clientid'    => \&_genClientId);
    $self->helper('gen_cachekey'=> \&_genCacheKey);
    $self->helper('gen_rsakeys' => \&_genRSAKeys);

    # DataDir (variable data, caches, temp files and etc.) -- /var/lib/<MONIKER>
    $self->datadir(path(SHAREDSTATEDIR, $self->moniker)->to_string()) unless defined $self->datadir;
    $self->raise("Startup error! Data directory %s not exists", $self->datadir) unless -e $self->datadir;

    # HomeDir (shared static files, default templates and etc.) -- /usr/share/<MONIKER>
    $self->homedir(path(DATADIR, $self->moniker)->to_string()) unless defined $self->homedir;
    $self->home(Mojo::Home->new($self->homedir)); # Switch to installable home directory

    # DocumentRoot (user's static data) -- /var/www/<MONIKER>
    my $documentroot = path(WEBDIR, $self->moniker)->to_string();
    $self->documentroot(-e $documentroot ? $documentroot : $self->homedir) unless defined $self->documentroot;

    # Reset static dirs
    $self->static->paths()->[0] = $self->documentroot; #unshift @{$static->paths}, '/home/sri/themes/blue/public';
    $self->static->paths()->[1] = $self->homedir if $self->documentroot ne $self->homedir;

    # Add renderer path (templates)
    push @{$self->renderer->paths}, $self->documentroot, $self->homedir;

    # Remove system favicon file
    delete $self->static->extra->{'favicon.ico'};

    # Set secret
    $self->mysecret($self->conf->latest("/secret")) if $self->conf->latest("/secret");
    $self->secrets([$self->mysecret]);

    # Init RSA keys (optional)
    if ($all_features || is_true_flag($opts->{init_rsa_keys} // $self->init_rsa_keys)) {
        my $private_key_file = $self->conf->latest("/privatekeyfile") || path($self->datadir, PRIVATEKEYFILE)->to_string;
        my $public_key_file = $self->conf->latest("/publickeyfile") || path($self->datadir, PUBLICKEYFILE)->to_string;
        if ((!-r $private_key_file) and (!-r $public_key_file)) {
            my $rsa = WWW::Suffit::RSA->new();
            $rsa->key_size($self->rsa_keysize) if $self->rsa_keysize;
            $rsa->keygen;
            path($private_key_file)->spew($rsa->private_key)->chmod(0600);
            $self->private_key($rsa->private_key);
            path($public_key_file)->spew($rsa->public_key)->chmod(0644);
            $self->public_key($rsa->public_key);
        } elsif (!-r $private_key_file) {
            $self->raise("Can't read RSA private key file: \"%s\"", $private_key_file);
        } elsif (!-r $public_key_file) {
            $self->raise("Can't read RSA public key file: \"%s\"", $public_key_file);
        } else {
            $self->private_key(path($private_key_file)->slurp);
            $self->public_key(path($public_key_file)->slurp)
        }
    }

    # Init AuthDB plugin (optional)
    if ($all_features || is_true_flag($opts->{init_authdb} // $self->init_authdb)) {
        #_load_module("WWW::Suffit::AuthDB");
        my $authdb_opts = as_hash_ref($opts->{authdb_opts} || $self->authdb_opts) || {};
        my $authdb_file = path($self->datadir, AUTHDBFILE)->to_string;
        my $authdb_uri = $authdb_opts->{uri} || $authdb_opts->{url}
            || $self->conf->latest("/authdburl") || $self->conf->latest("/authdburi")
            || qq{sqlite://$authdb_file?sqlite_unicode=1};
        my $cacheexpiration = $self->conf->latest("/authdbcacheexpire") || $self->conf->latest("/authdbcacheexpiration");
        $self->plugin('AuthDB' => {
            ds          => $authdb_uri,
            cached      => $authdb_opts->{cachedconnection} // $self->conf->latest("/authdbcachedconnection") // 'on',
            expiration  => $authdb_opts->{cacheexpire} || $authdb_opts->{cacheexpiration} ||
                           (defined($cacheexpiration) ? parse_time_offset($cacheexpiration) : undef),
            max_keys    => $authdb_opts->{cachemaxkeys} || $self->conf->latest("/authdbcachemaxkeys"),
            sourcefile  => $authdb_opts->{sourcefile} || $self->conf->latest("/authdbsourcefile"),
        });
        $self->authdb->with_roles(qw/+CRUD +AAA/);
        #$self->log->info(sprintf("AuthDB URI: \"%s\"", $authdb_uri));
    }

    # Set API routes plugin (optional)
    $self->plugin('API' => as_hash_ref($opts->{api_routes_opts} || $self->api_routes_opts) || {})
        if $all_features || is_true_flag($opts->{init_api_routes} // $self->init_api_routes);
    $self->plugin('API::User' => as_hash_ref($opts->{user_routes_opts} || $self->user_routes_opts) || {})
        if $all_features || is_true_flag($opts->{init_user_routes} // $self->init_user_routes);
    $self->plugin('API::Admin' => as_hash_ref($opts->{admin_routes_opts} || $self->admin_routes_opts) || {})
        if $all_features || is_true_flag($opts->{init_admin_routes} // $self->init_admin_routes);

    # Hooks
    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->server(sprintf("%s/%s", $self->project_name, $self->project_version)); # Set Server header
    });

    # Init hook
    $self->init;

    return $self;
}
sub init { } # Overload it
sub reload { # Reload hook
    my $self = shift;
    $self->log->warn("Request for reload $$");
    return 1; # 1 - ok; 0 - error :(
}
sub listeners {
    my $self = shift;

    # Resilver cert file
    my $_resolve_cert_file = sub {
        my $f = shift;
        return $f if File::Spec->file_name_is_absolute($f);
        return File::Spec->catfile(SYSCONFDIR, $self->moniker, $f);
    };

    # Master URL
    my $url = Mojo::URL->new($self->server_url || DEFAULT_SERVER_URL);
    my $host = $self->server_url ? $url->host : ($self->server_addr || DEFAULT_SERVER_ADDR);
    my $port = $self->server_url ? $url->port : ($self->server_port || DEFAULT_SERVER_PORT);
    $url->host($self->conf->latest("/listenaddr") || $host);
    $url->port($self->conf->latest("/listenport") || $port);

    # Added TLS parameters
    if (is_true_flag($self->conf->latest("/tls"))) {
        $url->scheme('https');
        foreach my $k (qw/ciphers version verify fd reuse single_accept/) {
            my $v = $self->conf->latest("/tls_$k") // '';
            next unless length $v;
            $v ||= '0x00' if $k eq 'verify';
            $url->query->merge($k, $v);
        }
        foreach my $k (qw/ca cert key/) {
            my $v = $self->conf->latest("/tls_$k") // '';
            next unless length $v;
            my $file = $_resolve_cert_file->($v);
            $self->raise("Can't load file \"%s\"", $file) unless -e $file and -r $file;
            $url->query->merge($k, $file);
        }
    }

    # Make master listener
    my $listener = $url->to_unsafe_string;

    # Make additional (slave) listeners
    my @listeners = ();
    push @listeners, $listener; # Ass master listener
    my $slaves = as_array_ref($self->conf->list("/listenurl")) // [];
    push @listeners, @$slaves if isnt_void($slaves);

    # Return listeners
    return [@listeners];
}
sub preforked_run {
    my $self = shift; # app
    my $dash_k = shift || '';
    my $opts = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    # Dash k
    $self->raise("Incorrect LSB command! Please use start, status, stop, restart or reload")
        unless (grep {$_ eq $dash_k} qw/start status stop restart reload/);

    # Mojolicious Prefork server
    my $prefork = Mojo::Server::Prefork->new( app => $self );
       $prefork->pid_file($self->pidfile) if length $self->pidfile;

    # Hypnotoad Pre-fork settings
    $prefork->max_clients($self->clients) if defined $self->clients;
    $prefork->max_requests($self->requests) if defined $self->requests;
    $prefork->accepts($self->accepts) if defined $self->accepts;
    $prefork->spare($self->spare) if defined $self->spare;
    $prefork->workers($self->workers) if defined $self->workers;

    # Listener
    $prefork->listen($self->listeners);

    # Working with Dash k
    my $upgrade = 0;
    my $reload = 0;
    my $upgrade_timeout = SERVER_UPGRADE_TIMEOUT; # 30
    if ($dash_k eq 'start') {
        if (my $pid = $prefork->check_pid()) {
            print "Already running $pid\n";
            exit 0;
        }
    } elsif ($dash_k eq 'stop') {
        if (my $pid = $prefork->check_pid()) {
            kill 'QUIT', $pid;
            print "Stopping $pid\n";
        } else {
            print "Not running\n";
        }
        exit 0;
    } elsif ($dash_k eq 'restart') {
        if (my $pid = $prefork->check_pid()) {
            $upgrade ||= steady_time;
            kill 'QUIT', $pid;
            my $up = $upgrade_timeout;
            while (kill 0, $pid) {
                $up--;
                sleep 1;
            }
            die("Can't stop $pid") if $up <= 0;
            print "Stopping $pid\n";
            $upgrade = 0;
        }
    } elsif ($dash_k eq 'reload') {
        my $pid = $prefork->check_pid();
        if ($pid) {
            if (my $s = $self->reload_sig) {
                # Start hot deployment
                kill $s, $pid; # 'USR2'
                print "Reloading $pid\n";
                exit 0;
            }
        }
        print "Not running\n";
    } else { # status
        if (my $pid = $prefork->check_pid()) {
            print "Running $pid\n";
        } else {
            print "Not running\n";
        }
        exit 0;
    }

    # Listen USR2 (reload)
    if (my $s = $self->reload_sig) {
        $SIG{$s} = sub { $upgrade ||= steady_time };
    }

    # Set system hooks
    $prefork->on(wait => sub { # Manage (every 1 sec)
        my $this = shift; # Prefork object

        # Upgrade
        if ($upgrade) {
            #$this->app->log->debug(">>> " . $this->healthy() || '?');
            unless ($reload) {
                $reload = 1; # Off next reloading
                if ($this->app->reload()) {
                    $reload = 0;
                    $upgrade = 0;
                    return 1;
                }
            }

            # Timeout
            if (($upgrade + $upgrade_timeout) <= steady_time()) {
                kill 'KILL', $$;
                $upgrade = 0;
            }
        }
    });
    $prefork->on(finish => sub { # Finish
        my $this = shift; # Prefork object
        my $graceful = shift;
        $this->app->log->debug($graceful ? 'Graceful server shutdown' : 'Server shutdown');
    });

    # Set GID and UID
    if (IS_ROOT) {
        if (my $gid = $self->gid) {
            POSIX::setgid($gid) or $self->raise("setgid %s failed - %s", $gid, $!);
            $) = "$gid $gid"; # this calls setgroups
            $self->raise("detected strange gid") if !($( eq "$gid $gid" && $) eq "$gid $gid"); # just to be sure
        }
        if (my $uid = $self->uid) {
            POSIX::setuid($uid) or $self->raise("setuid %s failed - %s", $uid, $!);
            $self->raise("detected strange uid") if !($< == $uid && $> == $uid); # just to be sure
        }
    }

    # PreRun callback
    if (my $prerun = $opts->{prerun}) {
        $prerun->($self, $prefork) if ref($prerun) eq 'CODE';
    }

    # Daemonize
    $prefork->daemonize() unless $self->no_daemonize;

    # Running
    print "Running\n";
    $prefork->run();
}

sub _load_module {
    my $module = shift;
    if (my $e = load_class($module)) {
        croak ref($e) ? "Exception: $e" : "The module $module not found!";
    }
    return 1;
}
sub _getToken {
    my $self = shift;

    # Get authorization string from request header
    my $token = $self->req->headers->header(TOKEN_HEADER_NAME) // '';
    if (length($token)) {
        return '' unless $token =~ JWT_REGEXP;
        return $token;
    }

    # Get authorization string from request authorization header
    my $auth_string = $self->req->headers->authorization
        || $self->req->env->{'X_HTTP_AUTHORIZATION'}
        || $self->req->env->{'HTTP_AUTHORIZATION'}
        || '';
    if ($auth_string =~ /(Bearer|Token)\s+(.*)/) {
        $token = $2;
        return '' unless length($token) && $token =~ JWT_REGEXP;
        return $token;
    }

    # In debug mode see "Token" config directive
    if ($self->app->debugmode and $token = $self->conf->latest("/token")) {
        return '' unless $token =~ JWT_REGEXP;
    }

    return $token // '';
}
sub _getJWT {
    my $self = shift;
    return WWW::Suffit::JWT->new(
        secret      => $self->app->mysecret,
        private_key => $self->app->private_key,
        public_key  => $self->app->public_key,
    );
}
sub _genCacheKey {
    my $self = shift;
    my $len = shift || 12;
    return randchars($len);
}
sub _genRSAKeys {
    my $self = shift;
    my $key_size = shift || $self->app->rsa_keysize;
    my $rsa = WWW::Suffit::RSA->new();
       $rsa->key_size($key_size) if $key_size;
       $rsa->keygen;
    my ($private_key, $public_key) = ($rsa->private_key // '', $rsa->public_key // '');
    return (
        private_key => $private_key,
        public_key  => $public_key,
        key_size    => $rsa->key_size,
        error       => $rsa->error
            ? sprintf("Error occurred while generation %s bit RSA keys: %s",  $rsa->key_size // '?', $rsa->error)
            : '',
    );
}
sub _genClientId {
    my $self = shift;
    my $user_agent = $self->req->headers->header('User-Agent') // 'unknown';
    my $remote_address = $self->remote_ip($self->app->trustedproxies)
        || $self->tx->remote_address || '::1';
    # md5(User-Agent . Remote-Address)
    return md5_sum(sprintf("%s%s", $user_agent, $remote_address));
}

1;

__END__
