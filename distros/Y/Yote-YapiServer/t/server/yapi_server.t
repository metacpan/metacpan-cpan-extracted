#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

# Mock dependencies before loading Site.pm
# Use @ISA directly (not 'use base') to avoid base.pm loading real modules
BEGIN {
    package Yote::SQLObjectStore::BaseObj;
    our %field_defaults;
    sub new {
        my ($class, %args) = @_;
        my $self = bless { _id => $args{id} // ++$main::obj_counter, _data => {}, _store => $args{store} }, $class;
        $self->{_data}{$_} = $args{$_} for keys %args;
        return $self;
    }
    sub id { shift->{_id} }
    sub store { shift->{_store} }
    sub AUTOLOAD {
        my $self = shift;
        our $AUTOLOAD;
        my ($method) = $AUTOLOAD =~ /::(\w+)$/;
        return if $method eq 'DESTROY';

        if ($method =~ /^get_(.+)$/) {
            my $field = $1;
            return $self->{_data}{$field};
        }
        elsif ($method =~ /^set_(.+)$/) {
            my $field = $1;
            $self->{_data}{$field} = shift;
            return;
        }
        die "Unknown method: $method";
    }
    sub can {
        my ($self, $method) = @_;
        return 1 if $method =~ /^(get_|set_|id|store|new)/ || UNIVERSAL::can($self, $method);
        return 0;
    }
    $INC{'Yote/SQLObjectStore/BaseObj.pm'} = 1;

    # Mock Session module
    package Yote::YapiServer::Session;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');
    sub new {
        my ($class, %args) = @_;
        my $self = Yote::SQLObjectStore::BaseObj::new($class, %args);
        $self->{_data}{exposed_objs} //= {};
        return $self;
    }
    sub generate_token { 'test_token_' . int(rand(100000)) }
    sub calculate_expiry { '2099-12-31' }
    sub get_exposed_objs { shift->{_data}{exposed_objs} }
    sub expose_object {
        my ($self, $obj) = @_;
        return unless $obj && $obj->can('id');
        $self->{_data}{exposed_objs}{$obj->id} = time();
    }
    sub is_expired { shift->{_data}{expired} // 0 }
    sub touch { shift->{_data}{last_access} = time() }
    $INC{'Yote/YapiServer/Session.pm'} = 1;

    # Mock User module
    package Yote::YapiServer::User;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');
    sub verify_password {
        my ($self, $pass) = @_;
        return $pass eq ($self->{_data}{plain_password} // '');
    }
    sub set_password {
        my ($self, $pass) = @_;
        $self->{_data}{plain_password} = $pass;
    }
    sub to_client_hash {
        my ($self, $session, $viewer) = @_;
        return { handle => $self->{_data}{handle} };
    }
    sub _client_class_name { return 'User'; }
    sub method_defs { return {} }
    sub field_access { return { handle => { public => 1 } } }
    $INC{'Yote/YapiServer/User.pm'} = 1;

    # Mock App::Base
    package Yote::YapiServer::App::Base;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');
    our %METHODS = ();
    our $app_version = 1;
    sub _init {
        my $self = shift;
        $self->{_data}{owner} = $self;
        return $self;
    }
    sub version {
        my $class = ref($_[0]) || $_[0];
        no strict 'refs';
        return ${"${class}::app_version"} // 1;
    }
    $INC{'Yote/YapiServer/App/Base.pm'} = 1;

    # Mock Example App
    package Yote::YapiServer::App::Example;
    our @ISA = ('Yote::YapiServer::App::Base');
    our $app_version = 1;
    $INC{'Yote/YapiServer/App/Example.pm'} = 1;
}

our $obj_counter = 0;

#----------------------------------------------------------------------
# MockStore
#----------------------------------------------------------------------

package MockStore;

sub new {
    my $class = shift;
    return bless {
        objects => {},
        paths   => {},
        next_id => 0,
    }, $class;
}

sub fetch_root { shift->{root} }

sub new_obj {
    my ($self, $class, %args) = @_;
    my $id = ++$self->{next_id};
    $args{store} = $self;
    $args{id} = $id;
    my $obj = $class->new(%args);
    $obj->_init if $obj->can('_init');
    $self->{objects}{$id} = $obj;
    return $obj;
}

sub new_hash {
    my ($self, $type) = @_;
    return {};
}

sub new_array {
    my ($self, $type) = @_;
    return [];
}

sub fetch {
    my ($self, $id) = @_;
    return $self->{objects}{$id};
}

sub fetch_path {
    my ($self, @path) = @_;
    my $key = join('/', @path);
    return $self->{paths}{$key};
}

sub set_path {
    my $self = shift;
    my $val = pop;
    my $key = join('/', @_);
    $self->{paths}{$key} = $val;
}

sub del_path {
    my $self = shift;
    my $key = join('/', @_);
    delete $self->{paths}{$key};
}

sub save { 1 }
sub lock { 1 }
sub unlock { 1 }

#----------------------------------------------------------------------
# Load the module under test
#----------------------------------------------------------------------

package main;

use Yote::YapiServer::Site;

#----------------------------------------------------------------------
# Helper functions
#----------------------------------------------------------------------

sub setup {
    my $store = MockStore->new();
    my $root = $store->new_obj('Yote::YapiServer::Site');
    $root->{_data}{apps} //= {};
    $store->{root} = $root;
    return ($store, $root);
}

sub create_context {
    my %args = @_;
    return {
        ip_address => $args{ip} // '127.0.0.1',
        session    => $args{session},
        user       => $args{user},
    };
}

#----------------------------------------------------------------------
# Initialization tests
#----------------------------------------------------------------------

subtest 'init - creates versioned apps structure' => sub {
    my ($store, $root) = setup();

    $root->init();

    my $apps = $root->get_apps;
    is(ref($apps), 'HASH', 'apps is a hash');

    # Check nested structure: app_name => { version => app_object }
    my $version_hash = $apps->{example};
    is(ref($version_hash), 'HASH', 'example entry is a version hash');

    my $version = Yote::YapiServer::App::Example->version;
    ok(defined $version_hash->{$version}, "app object exists at version $version");
    isa_ok($version_hash->{$version}, 'Yote::YapiServer::App::Example');
};

#----------------------------------------------------------------------
# App access tests
#----------------------------------------------------------------------

subtest 'get_app - returns latest version by name' => sub {
    my ($store, $root) = setup();

    my $app_v1 = Yote::YapiServer::App::Example->new(id => 100, store => $store);
    my $app_v2 = Yote::YapiServer::App::Example->new(id => 101, store => $store);
    $root->{_data}{apps}{example} = { 1 => $app_v1, 2 => $app_v2 };

    my $result = $root->get_app('example');
    is($result, $app_v2, 'returns latest (highest) version');
};

subtest 'get_app - returns specific version' => sub {
    my ($store, $root) = setup();

    my $app_v1 = Yote::YapiServer::App::Example->new(id => 100, store => $store);
    my $app_v2 = Yote::YapiServer::App::Example->new(id => 101, store => $store);
    $root->{_data}{apps}{example} = { 1 => $app_v1, 2 => $app_v2 };

    my $result = $root->get_app('example', 1);
    is($result, $app_v1, 'returns version 1 when requested');
};

subtest 'get_app - returns undef for unknown app' => sub {
    my ($store, $root) = setup();

    my $result = $root->get_app('nonexistent');
    ok(!defined $result, 'returns undef for unknown app');
};

subtest 'list_apps - returns sorted list' => sub {
    my ($store, $root) = setup();

    my $apps = $root->list_apps();

    is(ref($apps), 'ARRAY', 'returns array');
    ok(grep { $_ eq 'example' } @$apps, 'example in list');
};

#----------------------------------------------------------------------
# createUser tests (Site returns tuples: ($ok, $result, $extra))
#----------------------------------------------------------------------

subtest 'createUser - requires handle' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->createUser({ password => 'test1234' }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/handle required/, 'error mentions handle required');
};

subtest 'createUser - requires password' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->createUser({ handle => 'testuser' }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/password required/, 'error mentions password required');
};

subtest 'createUser - password minimum length' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->createUser({
        handle   => 'testuser',
        password => 'short',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/8 characters/, 'error mentions 8 characters');
};

subtest 'createUser - handle must be alphanumeric' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->createUser({
        handle   => 'invalid handle!',
        password => 'password123',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/alphanumeric/, 'error mentions alphanumeric');
};

subtest 'createUser - validates email format' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->createUser({
        handle   => 'testuser',
        password => 'password123',
        email    => 'not-an-email',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/invalid email/, 'error mentions email format');
};

subtest 'createUser - rejects duplicate handle' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my $existing = $store->new_obj('Yote::YapiServer::User');
    $existing->set_handle('existinguser');
    $store->set_path('users', 'existinguser', $existing);

    my ($ok, $error) = $root->createUser({
        handle   => 'ExistingUser',  # Case insensitive
        password => 'password123',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/handle already taken/, 'error mentions handle taken');
};

subtest 'createUser - rejects duplicate email' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my $existing = $store->new_obj('Yote::YapiServer::User');
    $existing->set_email('used@example.com');
    $store->set_path('users_by_email', 'used@example.com', $existing);

    my ($ok, $error) = $root->createUser({
        handle   => 'newuser',
        password => 'password123',
        email    => 'Used@Example.com',  # Case insensitive
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/email already registered/, 'error mentions email registered');
};

subtest 'createUser - success creates user and logs in' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $user, $extra) = $root->createUser({
        handle   => 'newuser',
        password => 'password123',
        email    => 'new@example.com',
    }, $context);

    is($ok, 1, 'ok is 1');
    ok($extra->{token}, 'token returned');
    ok($user, 'user returned');

    # Check user was indexed
    ok($store->fetch_path('users', 'newuser'), 'user indexed by handle');
    ok($store->fetch_path('users_by_email', 'new@example.com'), 'user indexed by email');
};

subtest 'createUser - underscore allowed in handle' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok) = $root->createUser({
        handle   => 'valid_user_123',
        password => 'password123',
    }, $context);

    is($ok, 1, 'ok is 1');
};

#----------------------------------------------------------------------
# login tests
#----------------------------------------------------------------------

subtest 'login - requires handle or email' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->login({ password => 'test123' }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/handle\/email required/, 'error mentions handle/email required');
};

subtest 'login - requires password' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->login({ handle => 'testuser' }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/password required/, 'error mentions password required');
};

subtest 'login - fails with unknown user' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->login({
        handle   => 'nonexistent',
        password => 'password123',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/invalid credentials/, 'error mentions invalid credentials');
};

subtest 'login - fails with wrong password' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my $user = $store->new_obj('Yote::YapiServer::User');
    $user->set_handle('loginuser');
    $user->set_password('correctpass');
    $store->set_path('users', 'loginuser', $user);

    my ($ok, $error) = $root->login({
        handle   => 'loginuser',
        password => 'wrongpass',
    }, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/invalid credentials/, 'error mentions invalid credentials');
};

subtest 'login - success with correct password' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my $user = $store->new_obj('Yote::YapiServer::User');
    $user->set_handle('gooduser');
    $user->set_password('rightpass');
    $store->set_path('users', 'gooduser', $user);

    my ($ok, $result_user, $extra) = $root->login({
        handle   => 'gooduser',
        password => 'rightpass',
    }, $context);

    is($ok, 1, 'ok is 1');
    ok($extra->{token}, 'token returned');
    ok($result_user, 'user returned');
    ok(length($extra->{token}) > 10, 'token has reasonable length');
};

subtest 'login - works with email' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my $user = $store->new_obj('Yote::YapiServer::User');
    $user->set_handle('emailuser');
    $user->set_email('login@test.com');
    $user->set_password('mypass');
    $store->set_path('users_by_email', 'login@test.com', $user);

    my ($ok, $result_user, $extra) = $root->login({
        email    => 'login@test.com',
        password => 'mypass',
    }, $context);

    is($ok, 1, 'ok is 1');
    ok($extra->{token}, 'token returned');
};

subtest 'login - creates session in store' => sub {
    my ($store, $root) = setup();
    my $context = create_context(ip => '192.168.1.1');

    my $user = $store->new_obj('Yote::YapiServer::User');
    $user->set_handle('sessionuser');
    $user->set_password('pass');
    $store->set_path('users', 'sessionuser', $user);

    my ($ok, $result_user, $extra) = $root->login({
        handle   => 'sessionuser',
        password => 'pass',
    }, $context);

    ok($ok, 'login succeeded');

    # Check session was stored
    my $session = $store->fetch_path('sessions', $extra->{token});
    ok($session, 'session stored by token');
    is($session->get_user, $user, 'session has correct user');
};

#----------------------------------------------------------------------
# logout tests
#----------------------------------------------------------------------

subtest 'logout - fails without session' => sub {
    my ($store, $root) = setup();
    my $context = create_context();

    my ($ok, $error) = $root->logout({}, $context);

    is($ok, 0, 'ok is 0');
    like($error, qr/not logged in/, 'error mentions not logged in');
};

subtest 'logout - success with session' => sub {
    my ($store, $root) = setup();

    my $session = $store->new_obj('Yote::YapiServer::Session');
    $session->set_token('session_token');
    $store->set_path('sessions', 'session_token', $session);

    my $context = create_context(session => $session);

    my ($ok) = $root->logout({}, $context);

    is($ok, 1, 'ok is 1');

    # Session should be removed
    ok(!$store->fetch_path('sessions', 'session_token'), 'session removed');
};

#----------------------------------------------------------------------
# validateToken tests
#----------------------------------------------------------------------

subtest 'validateToken - returns undef for missing token' => sub {
    my ($store, $root) = setup();

    my $result = $root->validateToken(undef);
    ok(!defined $result, 'returns undef for undef token');

    $result = $root->validateToken('');
    ok(!defined $result, 'returns undef for empty token');
};

subtest 'validateToken - returns undef for unknown token' => sub {
    my ($store, $root) = setup();

    my $result = $root->validateToken('unknown_token');
    ok(!defined $result, 'returns undef for unknown token');
};

subtest 'validateToken - returns undef for expired session' => sub {
    my ($store, $root) = setup();

    my $session = $store->new_obj('Yote::YapiServer::Session');
    $session->{_data}{expired} = 1;
    $store->set_path('sessions', 'expired_token', $session);

    my $result = $root->validateToken('expired_token');
    ok(!defined $result, 'returns undef for expired session');
};

subtest 'validateToken - returns session for valid token' => sub {
    my ($store, $root) = setup();

    my $session = $store->new_obj('Yote::YapiServer::Session');
    $store->set_path('sessions', 'valid_token', $session);

    my $result = $root->validateToken('valid_token');
    is($result, $session, 'returns session object');
};

subtest 'validateToken - touches session' => sub {
    my ($store, $root) = setup();

    my $session = $store->new_obj('Yote::YapiServer::Session');
    $store->set_path('sessions', 'touch_token', $session);

    ok(!$session->get_last_access, 'last_access not set initially');

    $root->validateToken('touch_token');

    ok($session->get_last_access, 'last_access set after validation');
};

#----------------------------------------------------------------------
# Rate limit configuration tests
#----------------------------------------------------------------------

subtest 'RATE_LIMITS - has expected entries' => sub {
    ok(exists $Yote::YapiServer::Site::RATE_LIMITS{createUser}, 'createUser rate limit exists');
    ok(exists $Yote::YapiServer::Site::RATE_LIMITS{login}, 'login rate limit exists');
    ok(exists $Yote::YapiServer::Site::RATE_LIMITS{default}, 'default rate limit exists');
};

subtest 'RATE_LIMITS - createUser configuration' => sub {
    my $config = $Yote::YapiServer::Site::RATE_LIMITS{createUser};

    is($config->{per_ip}, 5, 'createUser allows 5 per IP');
    is($config->{window}, 3600, 'createUser window is 1 hour');
};

subtest 'RATE_LIMITS - login configuration' => sub {
    my $config = $Yote::YapiServer::Site::RATE_LIMITS{login};

    is($config->{per_ip}, 10, 'login allows 10 per IP');
    is($config->{window}, 300, 'login window is 5 minutes');
};

subtest 'RATE_LIMITS - default configuration' => sub {
    my $config = $Yote::YapiServer::Site::RATE_LIMITS{default};

    is($config->{per_session}, 100, 'default allows 100 per session');
    is($config->{window}, 60, 'default window is 1 minute');
};

#----------------------------------------------------------------------
# INSTALLED_APPS tests
#----------------------------------------------------------------------

subtest 'INSTALLED_APPS - has expected apps' => sub {
    ok(exists $Yote::YapiServer::Site::INSTALLED_APPS{example}, 'example app registered');
};

subtest 'INSTALLED_APPS - correct class names' => sub {
    is($Yote::YapiServer::Site::INSTALLED_APPS{example}, 'Yote::YapiServer::App::Example',
        'example has correct class');
};

done_testing();
