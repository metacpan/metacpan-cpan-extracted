package WWW::Suffit::Plugin::FileAuth;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::FileAuth - The Suffit plugin for authentication and authorization by password file

=head1 SYNOPSIS

    sub startup {
        my $self = shift->SUPER::startup();
        $self->plugin('FileAuth', {
            configsection => 'auth',
        });

        # . . .
    }

... configuration:

    # FileAuth configuration
    <Auth>
        AuthUserFile /etc/myapp/passwd.db
    </Auth>

=head1 DESCRIPTION

This plugin provides authentication and authorization by looking up users in plain text password files

The C<AuthUserFile> configuration directive sets the path to the user file of a textual file containing the list of users and passwords
for user authentication.

If it is not absolute, it is treated as relative to the project C<data> directory.

By default use C<passwd.db> file name

Each line of the user file contains a username followed by a colon, followed by the encrypted password.
If the same user ID is defined multiple times, plugin will use the first occurrence to verify the password.
Try to avoid such cases!

The encrypted password format depends on which length of this encrypted-string and character-set:

    md5     32 hex digits and chars
    sha1    40 hex digits and chars
    sha224  56 hex digits and chars
    sha256  64 hex digits and chars
    sha384  96 hex digits and chars
    sha512  128 hex digits and chars
    unsafe plain text otherwise

Also, each line of the user file can contain parameters in the C<Query of URL> format
(L<RFC 3986|https://tools.ietf.org/html/rfc3986>), which must be placed at the end of the line with
a leading colon character, which is the delimiter

For example:

    admin:5f4dcc3b5aa765d61d8327deb882cf99
    test:5f4dcc3b5aa765d61d8327deb882cf99:uid=1&name=Test%20user
    anonymous:password

=head1 OPTIONS

This plugin supports the following options

=head2 configsection

    configsection => 'auth'

This option sets a section name of the config file for define
namespace of configuration directives for this plugin

Default: none (without section)

=head1 HELPERS

This plugin provides the following helpers

=head2 fileauth.init

    my $init = $self->fileauth->init;

This method returns the init object (L<Mojo::JSON::Pointer>)
that contains data of initialization:

    {
        error       => '...',       # Error message
        status      => 500,         # HTTP status code
        code        => 'E7000',     # The Suffit error code
    }

For example (in your controller):

    # Check init status
    my $init = $self->fileauth->init;
    if (my $err = $init->get('/error')) {
        $self->reply->error($init->get('/status'),
            $init->get('/code'), $err);
        return;
    }

=head2 fileauth.authenticate

    my $auth = $self->fileauth->authenticate({
        username    => $username,
        password    => $password,
        loginpage   => 'login', # -- To login-page!!
        expiration  => $remember ? SESSION_EXPIRE_MAX : SESSION_EXPIRATION,
        realm       => "Test zone",
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

=head2 fileauth.authorize

    my $auth = $self->fileauth->authorize({
        referer     => $referer,
        username    => $username,
        loginpage   => 'login', # -- To login-page!!
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
        user    => {        # User data
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

=head1 METHODS

Internal methods

=head2 register

This method register the plugin and helpers in L<Mojolicious> application

=head1 SEE ALSO

L<Mojolicious>, L<WWW::Suffit::Server>

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

use Digest::SHA qw/sha224_hex sha256_hex sha384_hex sha512_hex/;
use Mojo::File qw/path/;
use Mojo::Util qw/trim encode md5_sum sha1_sum hmac_sha1_sum secure_compare/;
use Mojo::JSON::Pointer;
use Mojo::Parameters;
use WWW::Suffit::Const qw/ :session /;
use WWW::Suffit::Util qw/json_load json_save/;

use constant PASSWD_FILENAME => 'passwd.db';

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $opts //= {};
    my $configsection = $opts->{configsection};
    my %payload = ( # Ok by default
        error       => '',          # Error message
        status      => 200,         # HTTP status code
        code        => 'E0000',     # The Suffit error code
    );

    # Load pwdb file
    my @users = ();
    my $pwdb_file = $configsection
        ? $app->conf->latest("/$configsection/authuserfile")
        : $app->conf->latest("/authuserfile");
    $pwdb_file ||= path($app->app->datadir, PASSWD_FILENAME)->to_string;
    $pwdb_file = path($app->app->datadir, $pwdb_file)->to_string unless path($pwdb_file)->is_abs;
    if (-e $pwdb_file) {
        if (open my $records, '<', $pwdb_file) {
            while(<$records>) {
                chomp;
                next unless $_;
                my $l = trim($_);
                next unless $l;
                next if $l =~ /^[#;]/;
                push @users, $l;
            }
            close $records;
        } else {
            $app->log->error(sprintf("[E7000] Error opening password file \"%s\: %s", $pwdb_file, $!));
            $payload{error}     = "Error opening password file: $!";
            $payload{status}    = 500;
            $payload{code}      = 'E7000';
        }
    } else {
        $app->log->error(sprintf("[E7000] Password file \"%s\" not found", $pwdb_file));
        $payload{error}     = "Password file not found";
        $payload{status}    = 500;
        $payload{code}      = 'E7000';
    }

    # List of users from config
    $app->helper('fileauth.users' => sub { \@users });

    # Auth helpers (methods)
    $app->helper('fileauth.authenticate'=> \&_authenticate);
    $app->helper('fileauth.authorize'   => \&_authorize);

    # Return with errors
    return $app->helper('fileauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) })
        if $payload{error};

    # Check users
    unless (scalar @users) {
        $app->log->error(sprintf("[E7010] No any users found in password file \"%s\"", $pwdb_file));
        $payload{error}     = "No any users found in password file";
        $payload{status}    = 500;
        $payload{code}      = 'E7010';
        return $app->helper('fileauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
    }
    #$app->log->error(Mojo::Util::dumper($users));

    # Ok
    return $app->helper('fileauth.init' => sub { Mojo::JSON::Pointer->new({%payload}) });
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

    # Get password database from cache
    my $pwdb = $cache->get('auth.pwdb');
    unless ($pwdb) {
        my $users = $self->fileauth->users || [];
        $pwdb = { (_parse_pwdb_lines(@$users)) };
        $cache->set('auth.pwdb' => $pwdb); # store whole password database to cache
        #$self->log->error(Mojo::Util::dumper( $pwdb ));
    }

    # Authentication: Check by password database
    my $pw = encode('UTF-8', $pwdb->{$username}->{pwd} // '');
    my $ar = Mojo::Parameters->new($pwdb->{$username}->{arg} // '')->charset('UTF-8');
    unless (_check_pw($password, $pw)) { # Oops. Incorrect username/password
        $self->log->error(sprintf("[%s] %s: %s", 401, 'E7005', 'Incorrect username/password'));
        $payload{error}     = 'Incorrect username/password';
        $payload{status}    = 401;
        $payload{code}      = 'E7005';
        return Mojo::JSON::Pointer->new({%payload});
    }
    #$self->log->error(Mojo::Util::dumper( $ar ));

    # User data with required fields!
    my $data = $ar->to_hash || {};
    $data->{address}    = $self->remote_ip($self->app->trustedproxies);
    $data->{base}       = $args{base_url} || $self->base_url;
    $data->{method}     = $args{method} || $self->req->method || "ANY";
    $data->{path}       = $self->req->url->path->to_string || "/";
    $data->{referer}    = $referer;
    # required fields:
    $data->{status}     = $data->{status} ? \1 : \0;
    $data->{uid}        ||= 0;
    $data->{username}   //= $username;
    $data->{name}       //= $username;
    $data->{role}       //= '';
    $data->{email}      //= '';
    $data->{email_md5}  //= $data->{email} ? md5_sum($data->{email}) : '',
    $data->{comment}    //= '';

    # Save json file with user data
    json_save($file, $data);
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

    # Load user file with user data
    my $user = -e $file ? json_load($file) : {};

    # Check user data
    unless ($user->{username}) {
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

sub _parse_pwdb_lines {
    my @lines = @_;
    my %r = ();
    for (@lines) {
        next unless $_;
        my @line = split ':', $_;
        my ($usr, $pwd, $arg) = ($line[0] // '', $line[1] // '', $line[2] // '');
        next unless length($usr) && length($pwd);
        if (@line == 3) { # username:password:params
            $r{$usr} = {
                pwd => $pwd,
                arg => $arg,
            };
        } elsif (@line == 2) { # username:password
            $r{$usr} = {
                pwd => $pwd
            };
        }
    }
    return %r;
}
sub _check_pw {
    my $pwd = shift // '';
    my $sum = shift // '';
    return 0 unless length($pwd) && length($sum);
    if ($sum =~ /^[0-9a-f]+$/i) {
        if (length($sum) == 32) { # md5: acbd18db4cc2f85cedef654fccc4a4d8
            return secure_compare(md5_sum($pwd), lc($sum));
        } elsif(length($sum) == 40) { # sha1: 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
            return secure_compare(sha1_sum($pwd), lc($sum));
        } elsif(length($sum) == 56) { # sha224: d63dc919e201d7bc4c825630d2cf25fdc93d4b2f0d46706d29038d01
            return secure_compare(sha224_hex($pwd), lc($sum));
        } elsif(length($sum) == 64) { # sha224: 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8
            return secure_compare(sha256_hex($pwd), lc($sum));
        } elsif(length($sum) == 96) { # sha384: a8b64babd0aca91a59bdbb7761b421d4f2bb38280d3a75ba0f21f2bebc45583d446c598660c94ce680c47d19c30783a7
            return secure_compare(sha384_hex($pwd), lc($sum));
        } elsif(length($sum) == 128) { # sha512: b109f3bbbc244eb82441917ed06d618b9008dd09b3befd1b5e07394c706a8bb980b1d7785e5976ec049b46df5f1326af5a2ea6d103fd07c95385ffab0cacbc86
            return secure_compare(sha512_hex($pwd), lc($sum));
        } else { # Plain text (unsafe)
            return secure_compare($pwd, $sum);
        }
    } else { # Plain text (unsafe)
        return secure_compare($pwd, $sum);
    }
    return 0;
}

1;

__END__
