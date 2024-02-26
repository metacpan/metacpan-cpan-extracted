package WWW::Suffit::Plugin::SuffitAuth;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::SuffitAuth - The Suffit plugin for Suffit API authentication and authorization providing

=head1 SYNOPSIS

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('SuffitAuth', {
            configsection => 'suffitauth',
            expiration => SESSION_EXPIRATION,
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

=head2 configsection

    configsection => 'suffitauth'

This option sets a section name of the config file for define
namespace of configuration directives for this plugin

Default: 'suffitauth'

=head2 expiration

    expiration => SESSION_EXPIRATION

This options performs set a default expiration time

Default: 3600 secs (1 hour)

See L<WWW::Suffit::Const/SESSION_EXPIRATION>

=head1 HELPERS

This plugin provides the following helpers

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

=head2 suffitauth.client

    my $client = $self->suffitauth->client;

Returns authorization client

See L<WWW::Suffit::Client::V1>

=head2 suffitauth.authenticate

    my $auth = $self->suffitauth->authenticate({
        base_url    => $self->base_url,
        referer     => $self->req->headers->header("Referer"),
        username    => $username,
        password    => $password,
        loginpage   => 'login', # -- To login-page!!
        expiration  => $remember ? SESSION_EXPIRE_MAX : SESSION_EXPIRATION,
        realm       => "Test zone",
        options     => {},
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

=head2 suffitauth.authorize

    my $auth = $self->suffitauth->authorize({
        referer     => $referer,
        username    => $username,
        loginpage   => 'login', # -- To login-page!!
        options     => {},
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

=head1 METHODS

Internal methods

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Client::V1>, L<WWW::Suffit::Server>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.00';

use File::stat;
use Mojo::File qw/path/;
use Mojo::Util qw/encode md5_sum hmac_sha1_sum/;
use Mojo::JSON::Pointer;
use WWW::Suffit::Client::V1;
use WWW::Suffit::Const qw/ :session /;
use WWW::Suffit::Util qw/json_load json_save/;

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $opts //= {};
    my $configsection = $opts->{configsection} || 'suffitauth';
    my $expiration = $opts->{expiration} // SESSION_EXPIRATION;
    my $now = time();

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
    my $public_key_file = path($app->app->datadir, "auth_public.key");
    my $pkfile = $public_key_file->to_string;
    $public_key_file->remove if $expiration && (-e $pkfile) && (stat($pkfile)->mtime + $expiration) < $now; # Remove expired public key file
    if (-e $pkfile) { # Set public key
        $client->public_key($public_key_file->slurp);
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
        $public_key_file->spew($client->public_key);
        unless (-e $pkfile) {
            $app->log->error(sprintf("[E7004] Can't save public key file %s", $pkfile));
            $payload{error}     = sprintf("Can't save public key file %s", $pkfile);
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
    my $expiration = $args{expiration} || 0;
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
        username    => $username,   # User name
        referer     => $referer,    # Referer
        loginpage   => $loginpage,  # Login page for redirects (location)
        location    => undef,       # Location URL for redirects
    );
    my $json_file = path($self->app->datadir, sprintf("u.%s.json", $username));
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
    unless ($client->authn($username, $password)) { # Error
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
                address     => $self->remote_ip($self->app->trustedproxies),
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
        $payload{error}     = sprintf("Can't save file DATADIR/u.%s.json", $username);
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
    my $file = path($self->app->datadir, sprintf("u.%s.json", $username))->to_string;

    # Load user file
    my $user = -e $file ? json_load($file) : {};

    # Check user data
    unless ($user->{uid}) {
        $self->log->error(sprintf("[E7008] File %s not found or incorrect", $file));
        $payload{error}     = sprintf("File DATADIR/u.%s.json not found or incorrect", $username);
        $payload{status}    = 500;
        $payload{code}      = 'E7008';
        return Mojo::JSON::Pointer->new({%payload});
    }

    # Ok
    $payload{user} = {%{$user}}; # Set user data to pyload hash
    return Mojo::JSON::Pointer->new({%payload});
}

1;

__END__
