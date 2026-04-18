package Yote::YapiServer::Site;

use strict;
use warnings;
use base 'Yote::YapiServer::BaseObj';

use Digest::MD5;
use Time::Piece;

use Yote::YapiServer::User;
use Yote::YapiServer::Session;
use Yote::YapiServer::App::Base;

# Database column definitions
our %cols = (
    created        => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    apps           => '*HASH<64>_*HASH<16>_*',              # app_name => { version => App object }
    users          => '*HASH<125>_*Yote::YapiServer::User',  # handle => User
    users_by_email => '*HASH<125>_*Yote::YapiServer::User',  # email => User
    sessions       => '*HASH<128>_*Yote::YapiServer::Session', # token => Session
);

# Installed applications - add your apps here
our %INSTALLED_APPS = (
    example  => 'Yote::YapiServer::App::Example',
);

# Rate limiting configuration
our %RATE_LIMITS = (
    createUser => { per_ip => 5,  window => 3600 },   # 5 per hour
    login      => { per_ip => 10, window => 300 },    # 10 per 5 min
    default    => { per_session => 100, window => 60 }, # 100 per min
);

#----------------------------------------------------------------------
# Initialization
#----------------------------------------------------------------------

sub installed_apps {
    return \%INSTALLED_APPS;
}

sub init {
    my ($self) = @_;
    my $store = $self->store;
    my $installed = $self->installed_apps;
    my $apps = $self->get_apps;

    for my $app_name (keys %$installed) {
        my $app_class = $installed->{$app_name};
        eval "require $app_class";
        die "Failed to load $app_class: $@" if $@;

        my $version = $app_class->version;

        # get or create the version hash for this app name
        my $version_hash = $apps->{$app_name};
        unless ($version_hash) {
            $version_hash = $store->new_hash('*HASH<16>_*');
            $apps->{$app_name} = $version_hash;
        }

        # create the app object if this version doesn't exist yet
        unless ($version_hash->{$version}) {
            my $app = $store->new_obj($app_class,
                app_name    => $app_name,
                app_version => $version,
            );
            $version_hash->{$version} = $app;
        }
    }

    $store->save;
    return $self;
}

#----------------------------------------------------------------------
# App access
#----------------------------------------------------------------------

sub get_app {
    my ($self, $app_name, $version) = @_;
    my $version_hash = $self->get_apps->{$app_name};
    return unless $version_hash;

    if (defined $version) {
        return $version_hash->{$version};
    }

    # default to latest (highest) version
    my @versions = sort { $b <=> $a } keys %$version_hash;
    return $version_hash->{$versions[0]} if @versions;
    return;
}

sub list_apps {
    my ($self) = @_;
    return [ sort keys %{$self->installed_apps} ];
}

#----------------------------------------------------------------------
# User management
#----------------------------------------------------------------------

sub createUser {
    my ($self, $args, $context) = @_;
    my $store = $self->store;

    my $handle   = $args->{handle};
    my $email    = $args->{email};
    my $password = $args->{password};

    # Validation
    return 0, "handle required" unless $handle;
    return 0, "password required" unless $password;
    return 0, "password must be at least 8 characters"
        if length($password) < 8;
    return 0, "handle must be alphanumeric"
        unless $handle =~ /^[a-zA-Z0-9_]+$/;
    return 0, "invalid email format"
        if $email && $email !~ /^[^@]+@[^@]+\.[^@]+$/;

    eval {
        # Check handle uniqueness
        if ($store->fetch_path('users', lc($handle))) {
            die "handle already taken\n";
        }

        # Check email uniqueness
        if ($email && $store->fetch_path('users_by_email', lc($email))) {
            die "email already registered\n";
        }

        # Create user
        my $user = $store->new_obj('Yote::YapiServer::User',
            handle => $handle,
            email  => $email,
        );
        $user->set_password($password);

        # Index user
        $store->set_path('users', lc($handle), $user);
        if ($email) {
            $store->set_path('users_by_email', lc($email), $user);
        }

        $store->save;
    };

    if ($@) {
        chomp(my $error = $@);
        return 0, $error;
    }

    # Auto-login after registration
    return $self->login({
        handle   => $handle,
        password => $password,
    }, $context);
}

sub login {
    my ($self, $args, $context) = @_;
    my $store = $self->store;

    my $handle_or_email = $args->{handle} // $args->{email};
    my $password = $args->{password};

    return 0, "handle/email required" unless $handle_or_email;
    return 0, "password required" unless $password;

    # Look up user
    my $user = $store->fetch_path('users', lc($handle_or_email))
            // $store->fetch_path('users_by_email', lc($handle_or_email));

    return 0, "invalid credentials" unless $user;
    return 0, "invalid credentials"
        unless $user->verify_password($password);
    return 0, "account locked" if $user->get_status;

    # Create session
    my $token = Yote::YapiServer::Session->generate_token();
    my $expires = Yote::YapiServer::Session->calculate_expiry();

    my $session = $store->new_obj('Yote::YapiServer::Session',
        token      => $token,
        user       => $user,
        expires    => $expires,
        ip_address => $context->{ip_address},
    );
    $session->touch;

    # Store session by token
    $store->set_path('sessions', $token, $session);

    # Update user last login
    $user->set_last_login(localtime->strftime("%Y-%m-%d %H:%M:%S"));

    $store->save;

    # Expose user to session
    $session->expose_object($user);

    return 1, $user, { token => $token };
}

sub logout {
    my ($self, $args, $context) = @_;
    my $store = $self->store;
    my $session = $context->{session};

    return 0, "not logged in" unless $session;

    my $token = $session->get_token;
    $store->del_path('sessions', $token);
    $store->save;

    return 1;
}

sub validateToken {
    my ($self, $token) = @_;
    return unless $token;

    my $store = $self->store;
    my $session = $store->fetch_path('sessions', $token);

    return unless $session;
    return if $session->is_expired;

    $session->touch;
    return $session;
}

#----------------------------------------------------------------------
# Session cleanup
#----------------------------------------------------------------------

sub cleanup_expired_sessions {
    my ($self) = @_;
    my $store = $self->store;

    # This would need implementation based on how sessions are indexed
    # For now, sessions are checked on access via is_expired()

    return 1;
}

1;

__END__

=head1 NAME

Yote::YapiServer::Site - Root database object for Yote API server

=head1 DESCRIPTION

The root database object for the Yote API server framework. Handles:

  - Application registration and initialization
  - User account creation and management
  - Session/token authentication
  - Rate limiting coordination

=head1 INSTALLED APPS

Add applications to the %INSTALLED_APPS hash:

    our %INSTALLED_APPS = (
        example => 'Yote::YapiServer::App::Example',
        myapp   => 'MyApp::Handler',
    );

=head1 METHODS

=head2 init()

Initializes the server, creating any apps that don't exist in the database.

=head2 get_app($app_name, $version)

Returns the app object for the given name. If $version is omitted,
returns the latest (highest) version.

=head2 createUser(\%args, \%context)

Creates a new user account. Args: handle, email, password.

=head2 login(\%args, \%context)

Authenticates a user. Args: handle (or email), password.
Returns token on success.

=head2 logout(\%args, \%context)

Ends the current session.

=head2 validateToken($token)

Validates a session token, returns session object or undef.

=cut
