package WWW::Suffit::Plugin::SuffitAuth;
use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::SuffitAuth - The Suffit plugin for Suffit API authentication and authorization providing

=head1 SYNOPSIS

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('SuffitAuth', {
            configsection    => 'SuffitAuth',
            expiration       => 3600, # 1h
            cache_expiration => 300, # 5m
            public_key_file  => 'suffitauth_pub.key',
            userfile_format  => 'user-%s.json',
        });

        # . . .
    }

... configuration:

    # SuffitAuth Client configuration
    <SuffitAuth>
        ServerURL       https://api.example.com/api
        Insecure        on
        AuthScheme      Bearer
        Token           "eyJhb...1Okw"
        ConnectTimeout  60
        RequestTimeout  60
    </SuffitAuth>

=head1 DESCRIPTION

The Suffit plugin for Suffit API authentication and authorization providing

=head1 OPTIONS

This plugin supports the following options

=head2 cache_expiration

    cache_expiration => 300
    cache_expiration => '5m'

This option sets default cache expiration time for keep user data in cache

Default: 300 (5 min)

=head2 configsection

    configsection => 'suffitauth'
    configsection => 'SuffitAuth'

This option sets a section name of the config file for define
namespace of configuration directives for this plugin

Default: 'suffitauth'

=head2 expiration

    expiration => 3600
    expiration => '1h'
    expiration => SESSION_EXPIRATION

This option performs set a default expiration time of session

Default: 3600 secs (1 hour)

See L<WWW::Suffit::Const/SESSION_EXPIRATION>

=head2 public_key_file

    public_key_file => 'auth_public.key'

This option sets default public key file location (relative to datadir)

Default: 'auth_public.key'

=head2 userfile_format

    userfile_format => 'u.%s.json'

This option sets default format of userdata authorization filename

Default: 'u.%s.json'

=head1 HELPERS

This plugin provides the following helpers

=head2 suffitauth.authenticate

    my $auth = $self->suffitauth->authenticate({
        address     => $self->remote_ip($self->app->trustedproxies),
        method      => $self->req->method, # 'ANY'
        base_url    => $self->base_url,
        referer     => $self->req->headers->header("Referer"),
        username    => $username,
        password    => $password,
        loginpage   => 'login', # -- To login-page!!
        expiration  => $remember ? SESSION_EXPIRE_MAX : SESSION_EXPIRATION,
        realm       => "Test zone", # Reserved. Now is not supported
        options     => {}, # Reserved. Now is not supported
    });
    if (my $err = $auth->get('/error')) {
        if (my $location = $auth->get('/location')) { # Redirect
            $self->flash(message => $err);
            $self->redirect_to($location); # 'login' -- To login-page!!
        } elsif ($auth->get('/status') >= 500) { # Fatal server errors
            $self->reply->error($auth->get('/status'), $auth->get('/code'), $err);
        } else { # User errors (show on login page)
            $self->stash(error => $err);
            return $self->render;
        }
        return;
    }

This helper performs authentication backend subprocess and returns
result object (L<Mojo::JSON::Pointer>) that contains data structure:

    {
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
        referer     => $referer,    # Referer
        loginpage   => $loginpage,  # Login page for redirects (location)
        location    => undef,       # Location URL for redirects
    }

This method is typically called in a handler responsible for the authentication and authorization
process, such as `login`. The call is typically made before a session is established, for eg.:

    # Set session
    $self->session(
            username => $username,
            remember => $remember ? 1 : 0,
            logged   => time,
            $remember ? (expiration => SESSION_EXPIRE_MAX) : (),
        );
    $self->flash(message => 'Thanks for logging in.');

    # Go to protected page (/root)
    $self->redirect_to('root');

=head2 suffitauth.authorize

    my $auth = $self->suffitauth->authorize({
        referer     => $referer,
        username    => $username,
        loginpage   => 'login', # -- To login-page!!
        options     => {}, # Reserved. Now is not supported
    });
    if (my $err = $auth->get('/error')) {
        if (my $location = $auth->get('/location')) {
            $self->flash(message => $err);
            $self->redirect_to($location); # 'login' -- To login-page!!
        } else {
            $self->reply->error($auth->get('/status'), $auth->get('/code'), $err);
        }
        return;
    }

This helper performs authorization backend subprocess and returns
result object (L<Mojo::JSON::Pointer>) that contains data structure:

    {
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
        referer     => $referer,    # Referer
        loginpage   => $loginpage,  # Login page for redirects (location)
        location    => undef,       # Location URL for redirects
        user    => {                # User data
            address     => "127.0.0.1", # User (client) IP address
            base        => "http://localhost:8080", # Base URL of request
            comment     => "No comments", # Comment
            email       => 'test@example.com', # Email address
            email_md5   => "a84450...366", # MD5 hash of email address
            method      => "ANY", # Current method of request
            name        => "Bob Smith", # Full user name
            path        => "/", # Current query-path of request
            role        => "Regular user", # User role
            status      => true, # User status in JSON::PP::Boolean notation
            uid         => 1, # User ID
            username    => $username, # User name
        },
    }

The 'user' is structure that describes found user. For eg.:

    {
        "address": "127.0.0.1",
        "base": "http://localhost:8473",
        "code": "E0000",
        "email": "foo@example.com",
        "email_md5": "b48def645758b95537d4424c84d1a9ff",
        "expires": 1700490101,
        "groups": [
            "wheel"
        ],
        "method": "ANY",
        "name": "Anon Anonymous",
        "path": "/",
        "role": "System Administratot",
        "status": true,
        "uid": 1,
        "username": "admin"
    }

Typically, this method is called in the handler responsible for session accounting (logged_in).
The call is accompanied by staking of the authorization data into the corresponding
project templates, for example:

    # Stash user data
    $self->stash(
        username => $username,
        name     => $auth->get('/user/name') // 'Anonymous',
        email_md5=> $auth->get('/user/email_md5') // '',
        role     => $auth->get('/user/role') // 'User',
        user     => $auth->get('/user') || {},
    );


=head2 suffitauth.client

    my $client = $self->suffitauth->client;

Returns authorization client

See L<WWW::Suffit::Client::V1>

=head2 suffitauth.init

    my $init = $self->suffitauth->init;

This method returns the init object (L<Mojo::JSON::Pointer>)
that contains data of initialization:

    {
        error       => '...',       # Error message
        status      => 500,         # HTTP status code
        code        => 'E7000',     # The Suffit error code
    }

For example (in your controller):

    # Check init status
    my $init = $self->suffitauth->init;
    if (my $err = $init->get('/error')) {
        $self->reply->error($init->get('/status'),
            $init->get('/code'), $err);
        return;
    }

=head2 suffitauth.options

    my $options = $self->suffitauth->options;

Returns authorization plugin options as hashref

=head2 suffitauth.unauthorize

    my $auth = $self->suffitauth->unauthorize(username => $username);
    if (my $err = $auth->get('/error')) {
        $self->reply->error($authdata->get('/status'), $authdata->get('/code'), $err);
    }

This helper performs unauthorize process - remove userdata file from disk and returns
result object (L<Mojo::JSON::Pointer>) that contains data structure:

    {
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
    }

This method is typically called in the handler responsible for the logout process.
The call usually occurs before the redirect to the `login` page, for example:

    # Remove session
    $self->session(expires => 1);

    # Unauthorize
    if (my $username = $self->session('username')) {
        my $authdata = $self->suffitauth->unauthorize(username => $username);
        if (my $err = $authdata->get('/error')) {
            $self->reply->error($authdata->get('/status'), $authdata->get('/code'), $err);
        }
    }

    # To login-page!
    $self->redirect_to('login');

=head1 METHODS

Internal methods

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

=head1 ERROR CODES

=over 8

=item B<E0xxx> -- General errors

E01xx, E02xx, E03xx, E04xx and E05xx are reserved as HTTP errors

    E0000   Ok
    E0100   Continue
    E0200   OK
    E0300   Multiple Choices
    E0400   Bad Request
    E0500   Internal Server Error

=item B<E1xxx> -- API errors

See L<WWW::Suffit::API>

=item B<E2xxx> -- Database errors

See L<WWW::Suffit::API>

=item B<E7xxx> -- SuffitAuth (application) errors

B<Auth: E70xx>

    E7000   [403]   Access denied
    E7001   [400]   Incorrect username
    E7002   [503]   Can't connect to authorization server
    E7003   [500]   Can't get public key from authorization server
    E7004   [500]   Can't save public key file %s
    E7005   [*]     Authentication error
    E7006   [*]     Authorization error
    E7007   [500]   Can't save file <USERNAME>.json
    E7008   [500]   File <USERNAME>.json not found or incorrect
    E7009   [400]   Incorrect username (while authorize)
    E7010   [400]   Incorrect username (while unauthorize)

B<*> -- this code defines on server side

=back

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Client::V1>, L<WWW::Suffit::Server>, bundled examples

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.04';

use File::stat;
use Mojo::File qw/path/;
use Mojo::Util qw/encode md5_sum hmac_sha1_sum/;
use Mojo::JSON::Pointer;

use Acrux::Util qw/parse_time_offset/;

use WWW::Suffit::Client::V1;
use WWW::Suffit::Const qw/ :session /;
use WWW::Suffit::Util qw/json_load json_save/;

use constant {
    SUFFITAUTH_PREFIX   => 'suffitauth',
    PUBLIC_KEY_FILE     => 'auth_public.key',
    USERFILE_FORMAT     => 'u.%s.json',
    CACHE_EXPIRATION    => 300, # 5 min
};

has _options => sub { {} };

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $opts //= {};
    my $configsection = lc($opts->{configsection} || SUFFITAUTH_PREFIX);
    my $expiration = parse_time_offset($opts->{expiration} // SESSION_EXPIRATION);
    my $cache_expiration = parse_time_offset($opts->{cache_expiration} // CACHE_EXPIRATION);
    my $public_key_file = $opts->{public_key_file} || PUBLIC_KEY_FILE;
       $public_key_file = path($app->app->datadir, $public_key_file)->to_string
            unless path($public_key_file)->is_abs;
    my $now = time();

    # Options
    $plugin->_options->{ 'configsection' } = $configsection;
    $plugin->_options->{ 'expiration' } = $expiration; # Session & Userdata expiration (3600)
    $plugin->_options->{ 'cache_expiration' } = $cache_expiration; # Cache expiration (300)
    $plugin->_options->{ 'public_key_file' } = $public_key_file;
    $plugin->_options->{ 'userfile_format' } = $opts->{userfile_format} || USERFILE_FORMAT;
    $app->helper( 'suffitauth.options' => sub { state $opts = $plugin->_options } );

    # Auth client (V1)
    $app->helper('suffitauth.client' => sub {
        my $c = shift;
        state $client = WWW::Suffit::Client::V1->new(
            url                 => $c->conf->latest("/$configsection/serverurl"),
            insecure            => $c->conf->latest("/$configsection/insecure"),
            max_redirects       => $c->conf->latest("/$configsection/maxredirects"),
            connect_timeout     => $c->conf->latest("/$configsection/connecttimeout"),
            inactivity_timeout  => $c->conf->latest("/$configsection/inactivitytimeout"),
            request_timeout     => $c->conf->latest("/$configsection/requesttimeout"),
            proxy               => $c->conf->latest("/$configsection/proxy"),
            token               => $c->conf->latest("/$configsection/token"),
            username            => $c->conf->latest("/$configsection/username"),
            password            => $c->conf->latest("/$configsection/password"),
            auth_scheme         => $c->conf->latest("/$configsection/authscheme"),
        );
    });

    # Auth helpers (methods)
    $app->helper('suffitauth.authenticate'=> \&_authenticate);
    $app->helper('suffitauth.authorize'   => \&_authorize);
    $app->helper('suffitauth.unauthorize' => \&_unauthorize);

    # Initialize auth client
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
    );

    # Check auth client
    my $client = $app->suffitauth->client;
    unless ($client->check) {
        my $code = $client->res->json("/code") || 'E7002';
        $app->log->error(sprintf("[%s] %s: Can't connect to authorization server: %s",
            $code, $client->code, $client->apierr // 'unknown error'));
        $payload{error}     = "Can't connect to authorization server";
        $payload{status}    = 503;
        $payload{code}      = $code;
        return $app->helper('suffitauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
    }

    # Get public_key and set it
    my $pkfile = path($public_key_file);
    $pkfile->remove if $expiration && (-e $public_key_file) && (stat($public_key_file)->mtime + $expiration) < $now; # Remove expired public key file
    if (-e $public_key_file) { # Set public key
        $client->public_key($pkfile->slurp);
    } else { # No file found - try get from auth server
        unless ($client->pubkey(1)) {
            my $code = $client->res->json("/code") || 'E7003';
            $app->log->error(sprintf("[%s] %s: Can't get public key from authorization server: %s",
                $code, $client->code, $client->apierr // 'unknown error'));
            $payload{error}     = "Can't get public key from authorization server";
            $payload{status}    = 500;
            $payload{code}      = $code;
            return $app->helper('suffitauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
        }

        # Save file
        $pkfile->spew($client->public_key);
        unless (-e $public_key_file) {
            $app->log->error(sprintf("[E7004] Can't save public key file %s", $public_key_file));
            $payload{error}     = sprintf("Can't save public key file %s", $public_key_file);
            $payload{status}    = 500;
            $payload{code}      = 'E7004';
            return $app->helper('suffitauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
        }
    }

    # Ok
    return $app->helper('suffitauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
}
sub _authenticate {
    my $self = shift;
    my %args = scalar(@_) ? scalar(@_) % 2 ? ref($_[0]) eq 'HASH' ? (%{$_[0]}) : () : (@_) : ();
    my $cache = $self->app->cache;
    my $now = time();
    my $username = $args{username} || '';
    my $password = $args{password} // '';
       $password = encode('UTF-8', $password) if length $password; # chars to bytes
    my $referer = $args{referer} // $self->req->headers->header("Referer") // '';
    my $loginpage = $args{loginpage} // '';
    my $expiration = parse_time_offset($args{expiration} || 0) || $self->suffitauth->options->{expiration} || 0;
    my $address = $args{address} || $self->remote_ip($self->app->trustedproxies);
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
        referer     => $referer,    # Referer
        loginpage   => $loginpage,  # Login page for redirects (location)
        location    => undef,       # Location URL for redirects
    );
    my $fileformat = $self->suffitauth->options->{userfile_format};
    my $json_file = path($self->app->datadir, sprintf($fileformat, $username));
    my $file = $json_file->to_string;

    # Check username
    unless (length $username) {
        $self->log->error("[E7001] Incorrect username");
        $payload{error}     = "Incorrect username";
        $payload{status}    = 400;
        $payload{code}      = 'E7001';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Get user key and file
    my $ustat_key = sprintf("auth.ustat.%s", hmac_sha1_sum(sprintf("%s:%s", encode('UTF-8', $username), $password), $self->app->mysecret));
    my $ustat_tm = $cache->get($ustat_key) || 0;
    if ($expiration && (-e $file) && ($ustat_tm + $expiration) > $now) { # Ok!
        $self->log->debug(sprintf("$$: User data is still valid. Expired at %s", scalar(localtime($ustat_tm + $expiration))));
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Get auth client
    my $client = $self->suffitauth->client;

    # Authentication
    unless ($client->authn($username, $password, $address)) { # Error
        my $code = $client->res->json("/code") || 'E7005';
        $self->log->error(sprintf("[%s] %s: %s", $code, $client->code, $client->apierr));
        $payload{error}     = $client->apierr;
        $payload{status}    = $client->code;
        $payload{code}      = $code;
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Authorization
    unless ($client->authz(
            $args{method} || $self->req->method || "ANY",
            $args{base_url} || $self->base_url,
            { # Error
                username    => $username,
                address     => $address,
                verbose     => 1,
            })
    ) {
        my $code = $client->res->json("/code") || 'E7006';
        $self->log->error(sprintf("[%s] %s: %s", $code, $client->code, $client->apierr));
        $payload{error}     = $client->apierr;
        $payload{status}    = $client->code;
        $payload{code}      = $code;
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Save json file
    json_save($file, $client->res->json);
    unless (-e $file) {
        $self->log->error(sprintf("[E7007] Can't save file %s", $file));
        $payload{error}     = sprintf("Can't save file DATADIR/$fileformat", $username);
        $payload{status}    = 500;
        $payload{code}      = 'E7007';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Fixed to cache
    $cache->set($ustat_key, $now);

    # Ok
    return Mojo::JSON::Pointer->new({%payload});
}
sub _authorize {
    my $self = shift;
    my %args = scalar(@_) ? scalar(@_) % 2 ? ref($_[0]) eq 'HASH' ? (%{$_[0]}) : () : (@_) : ();
    my $username = $args{username} || '';
    my $referer = $args{referer} // $self->req->headers->header("Referer") // '';
    my $loginpage = $args{loginpage} // '';
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
        referer     => $referer,    # Referer
        loginpage   => $loginpage,  # Login page for redirects (location)
        location    => undef,       # Location URL for redirects
        user        => {            # User data with required fields (defaults)
            status      => \0,          # User status
            uid         => 0,           # User ID
            username    => $username,   # User name
            name        => $username,   # Full name
            role        => "",          # User role
            email       => "",          # Email address
            email_md5   => "",          # MD5 of email address
            comment     => "",          # Comment
        },
    );

    # Check username
    unless (length $username) {
        $self->log->error("[E7009] Incorrect username");
        $payload{error}     = "Incorrect username";
        $payload{status}    = 400;
        $payload{code}      = 'E7009';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Get user file name
    my $fileformat = $self->suffitauth->options->{userfile_format};
    my $file = path($self->app->datadir, sprintf($fileformat, $username))->to_string;

    # Get user data from cache first
    my $cache = $self->app->cache;
    my $user_cache_key = sprintf("auth.userdata.%s", $username);
    my $user_data = $cache->get($user_cache_key);

    # Load user data from file
    unless ($user_data) {
        $user_data = -e $file ? json_load($file) : {};

        # Set loaded user data to cache
        $cache->set($user_cache_key, $user_data, $self->suffitauth->options->{cache_expiration});
    }

    # Check user data
    unless ($user_data->{uid}) {
        $self->log->error(sprintf("[E7008] File %s not found or incorrect", $file));
        $payload{error}     = sprintf("File DATADIR/$fileformat not found or incorrect", $username);
        $payload{status}    = 500;
        $payload{code}      = 'E7008';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Ok
    $payload{user} = {%{$user_data}}; # Set user data to pyload hash
    return Mojo::JSON::Pointer->new({%payload});
}
sub _unauthorize {
    my $self = shift;
    my %args = scalar(@_) ? scalar(@_) % 2 ? ref($_[0]) eq 'HASH' ? (%{$_[0]}) : () : (@_) : ();
    my $username = $args{username} || '';

    # Initialize auth client
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,
    );

    # Check username
    unless (length $username) {
        $self->log->error("[E7010] Incorrect username");
        $payload{error}     = "Incorrect username";
        $payload{status}    = 400;
        $payload{code}      = 'E7010';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Remove user data from cache first
    my $cache = $self->app->cache;
    my $user_cache_key = sprintf("auth.userdata.%s", $username);
    $cache->del($user_cache_key);

    # Get user file name
    my $fileformat = $self->suffitauth->options->{userfile_format};
    my $file = path($self->app->datadir, sprintf($fileformat, $username))->to_string;

    # Remove userdata file
    path($file)->remove if -e $file;

    # Ok
    return Mojo::JSON::Pointer->new({%payload});
}

1;

__END__
