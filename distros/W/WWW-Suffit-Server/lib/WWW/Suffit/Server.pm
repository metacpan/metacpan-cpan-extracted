package WWW::Suffit::Server;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server - The Suffit API web-server class

=head1 SYNOPSIS

    WWW::Suffit::Server;

=head1 DESCRIPTION

This module provides API web-server functionality

=head1 OPTIONS

    sub startup {
        my $self = shift->SUPER::startup( OPTION_NAME => VALUE, ... );

        # ...
    }

List of allowed options (pairs of name-value):

=head2 all_features

    all_features => 'on'

This option enables all of the init_* options, which are described bellow

Default: off

=head2 config_opts

    config_opts => { ... }

This option sets L<WWW::Suffit::Plugin::ConfigGeneral> plugin options

Default:

    `noload => 1` if $self->configobj exists
    `defaults => $self->config` if $self->config is not void

=head2 init_authdb

    init_authdb => 'on'

This option enables AuthDB initialize

Default: off

=head2 init_api_routes

    init_api_routes => 'on'

Enable Suffit API routes

Default: off

=head2 init_rsa_keys

    init_rsa_keys => 'on'

This option enables RSA keys initialize

Default: off

=head2 syslog_opts

    syslog_opts => { ... }

This option sets L<WWW::Suffit::Plugin::Syslog> plugin options

Default:

    `enable => 1` if the `Log` config directive is "syslog"

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

    private_key => '...',

Private RSA key

=head2 project_version

    project_version => '0.01',

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

Mojolicious application startup method

=head1 HELPERS

This class implements the following helpers

=head2 authdb

This is access method to the AuthDB object (state object)

=head2 jwt

This helper makes JWT object with RSA keys and returns it

=head2 token

This helper performs get of current token from HTTP Request headers

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit>, L<WWW::Suffit::RSA>, L<WWW::Suffit::JWT>, L<WWW::Suffit::AuthDB>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.10';

use Mojo::Base 'Mojolicious';

use Carp qw/carp croak/;
use POSIX qw//;
use File::Spec;

use Mojo::URL;
use Mojo::File qw/ path /;
use Mojo::Home qw//;
use Mojo::Util qw/decamelize steady_time/; # decamelize(ref($self))
use Mojo::Loader qw/load_class/;
use Mojo::Server::Prefork;

use WWW::Suffit::Const qw/
        :general :security :session :dir :server
        AUTHDBFILE JWT_REGEXP
    /;
use WWW::Suffit::Util qw/ color parse_time_offset /;
use WWW::Suffit::RefUtil qw/ as_array_ref as_hash_ref isnt_void is_true_flag /;
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
    $self->raise("Incorrect `project_name`") unless $self->project_name;
    $self->raise("Incorrect `project_version`") unless $self->project_version;
    unshift @{$self->plugins->namespaces}, 'WWW::Suffit::Plugin'; # Add another namespace to load plugins from
    push @{$self->routes->namespaces}, 'WWW::Suffit::Server'; # Add Server routes namespace
    my $all_features = is_true_flag($opts->{all_features}); # on/off

    # Get all ConfigGeneral configuration attributes
    my $config_opts = as_hash_ref($opts->{config_opts}) || {};
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
    my $syslog_opts = as_hash_ref($opts->{syslog_opts}) || {};
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
    $self->helper('token'               => \&_getToken);
    $self->helper('jwt'                 => \&_getJWT);

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
    if ($all_features || is_true_flag($opts->{init_rsa_keys})) {
        my $private_key_file = $self->conf->latest("/privatekeyfile") || path($self->datadir, PRIVATEKEYFILE)->to_string;
        my $public_key_file = $self->conf->latest("/publickeyfile") || path($self->datadir, PUBLICKEYFILE)->to_string;
        if ((!-r $private_key_file) and (!-r $public_key_file)) {
            my $rsa = WWW::Suffit::RSA->new();
            $rsa->key_size($self->conf->latest("/rsa_keysize")) if $self->conf->latest("/rsa_keysize");
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

    # Init AuthDB (optional)
    if ($all_features || is_true_flag($opts->{init_authdb})) {
        _load_module("WWW::Suffit::AuthDB");
        my $authdb_file = path($self->datadir, AUTHDBFILE)->to_string;
        my $authdb_uri = $self->conf->latest("/authdburi") || qq{sqlite://$authdb_file?sqlite_unicode=1};
        $self->log->info(sprintf("AuthDB URI: \"%s\"", $authdb_uri));
        $self->helper(authdb => sub { state $authdb = WWW::Suffit::AuthDB->new(dsuri => $authdb_uri) });
    } else {
        $self->helper(authdb => sub { return undef });
    }

    # Hooks
    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->server(sprintf("%s/%s", $self->project_name, $self->project_version)); # Set Server header
    });

    # Skip set routing (optional)
    return $self unless $all_features || is_true_flag($opts->{init_api_routes});

    # General routes related to the Suffit API
    my $r = $self->routes;

    # API routes with token or cookie authorization
    my $authorized = $r->under('/api')->to('auth#is_authorized')->name('api');
    $authorized->get('/')->to('API#api')->name('api-data');
    $authorized->get('/check')->to('API#check')->name('api-check');
    $authorized->get('/status')->to('API#status')->name('api-status');

    # API::NoAPI
    $authorized->get('/file')->to('API::NoAPI#file_list')->name('api-file-list');
    $authorized->get('/file/*filepath')->to('API::NoAPI#file_download')->name('api-file-download');
    $authorized->put('/file/*filepath')->to('API::NoAPI#file_upload')->name('api-file-upload');
    $authorized->delete('/file/*filepath')->to('API::NoAPI#file_remove')->name('api-file-remove');

    # API::V1
    $authorized->post('/v1/authn')->to('API::V1#authn')->name('api-v1-authn');
    $authorized->post('/v1/authz')->to('API::V1#authz')->name('api-v1-authz');
    $authorized->get('/v1/publicKey')->to('API::V1#public_key')->name('api-v1-publickey');

    return $self;
}
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

1;

__END__
