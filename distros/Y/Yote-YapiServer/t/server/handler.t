#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use JSON::PP;

#----------------------------------------------------------------------
# This test file tests Handler.pm components in isolation
# without loading the full module hierarchy
#----------------------------------------------------------------------

# First, prevent loading of real modules by setting up minimal stubs
BEGIN {
    # Create a minimal BaseObj mock before any modules load
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

    # Mock BaseObj (intermediate superclass)
    package Yote::YapiServer::BaseObj;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');
    $INC{'Yote/YapiServer/BaseObj.pm'} = 1;

    # Mock File
    package Yote::YapiServer::File;
    our @ISA = ('Yote::YapiServer::BaseObj');
    our %FIELD_ACCESS = (
        url           => { public => 1 },
        type          => { public => 1 },
        size          => { public => 1 },
        original_name => { owner_only => 1 },
        file_path     => { never => 1 },
    );
    our %METHODS = ();
    $INC{'Yote/YapiServer/File.pm'} = 1;
}

our $obj_counter = 0;

#----------------------------------------------------------------------
# Create test helper - MockStore with all required methods
#----------------------------------------------------------------------

package MockStore;

sub new {
    my $class = shift;
    return bless {
        objects => {},
        paths   => {},
        root    => undef,
        next_id => 1000,
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

# Now set up the remaining mock modules
BEGIN {
    package Yote::YapiServer::Session;
    use base 'Yote::SQLObjectStore::BaseObj';

    sub new {
        my ($class, %args) = @_;
        my $self = $class->SUPER::new(%args);
        $self->{_data}{exposed_objs} //= {};
        return $self;
    }

    sub get_exposed_objs { shift->{_data}{exposed_objs} }

    sub expose_object {
        my ($self, $obj) = @_;
        return unless $obj && $obj->can('id');
        $self->{_data}{exposed_objs}{$obj->id} = time();
        return $obj->id;
    }

    sub can_access {
        my ($self, $obj_or_id) = @_;
        return 0 unless defined $obj_or_id;
        my $id;
        if (ref $obj_or_id) {
            return 0 unless $obj_or_id->can('id');
            $id = $obj_or_id->id;
        } elsif ($obj_or_id =~ /^_obj_(\d+)$/) {
            $id = $1;
        } else {
            $id = $obj_or_id;
        }
        return $self->{_data}{exposed_objs}{$id} ? 1 : 0;
    }

    sub is_expired { 0 }
    sub touch { shift->{_data}{last_access} = time() }
    sub generate_token { 'test_token_' . time() . '_' . int(rand(10000)) }
    sub calculate_expiry { '2099-12-31' }

    $INC{'Yote/YapiServer/Session.pm'} = 1;

    package Yote::YapiServer::User;
    use base 'Yote::SQLObjectStore::BaseObj';

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

    package Yote::YapiServer::App::Base;
    use base 'Yote::SQLObjectStore::BaseObj';

    our %METHODS = ();
    our %FIELD_ACCESS = ( app_name => { public => 1 } );
    our %PUBLIC_VARS = ();

    sub method_defs {
        my $self = shift;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::METHODS"};
    }

    sub field_access {
        my $self = shift;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::FIELD_ACCESS"};
    }

    sub public_vars {
        my $self = shift;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::PUBLIC_VARS"};
    }

    sub authorize_method {
        my ($self, $method, $session, $user) = @_;
        my $methods = $self->method_defs;
        return (0, "unknown method: $method") unless $methods->{$method};
        return (1) if $methods->{$method}{public};
        return (0, "authentication required") unless $session && $user;
        return (0, "admin access required") if $methods->{$method}{admin_only} && !$user->{_data}{is_admin};
        return (1);
    }

    sub authorize_object_method {
        my ($class, $obj, $method, $session, $user) = @_;
        return (0, "object not accessible") unless $session && $session->can_access($obj);
        return $obj->authorize_method($method, $session, $user);
    }

    sub connect_info_methods {
        my ($self, $session, $user) = @_;
        return [sort keys %{$self->method_defs}];
    }

    sub _client_class_name {
        my ($self) = @_;
        my $class = ref($self) || $self;
        $class =~ s/^Yote::YapiServer::App:://;
        $class =~ s/^Yote::YapiServer:://;
        return $class;
    }

    sub to_client_hash {
        my ($self, $session) = @_;
        return { app_name => $self->{_data}{app_name} };
    }

    $INC{'Yote/YapiServer/App/Base.pm'} = 1;

    # Test app
    package Yote::YapiServer::App::TestApp;
    use base 'Yote::YapiServer::App::Base';

    our %METHODS = (
        hello  => { public => 1 },
        secret => { auth => 1 },
    );
    our %PUBLIC_VARS = ( version => '1.0' );

    sub hello {
        my ($self, $args, $session) = @_;
        return 1, "Hello, " . ($args->{name} // 'World');
    }

    sub secret {
        return 1, "secret data";
    }

    # Main server (root database object)
    package Yote::YapiServer::Site;
    use base 'Yote::SQLObjectStore::BaseObj';

    our %INSTALLED_APPS = ( testapp => 'Yote::YapiServer::App::TestApp' );
    our %RATE_LIMITS = (
        createUser => { per_ip => 5, window => 3600 },
        login      => { per_ip => 10, window => 300 },
        default    => { per_session => 100, window => 60 },
    );

    sub init {
        my $self = shift;
        $self->{_data}{apps} //= {};
        return $self;
    }

    sub get_app {
        my ($self, $name) = @_;
        return $self->{_data}{apps}{$name};
    }

    sub validateToken {
        my ($self, $token) = @_;
        return unless $token;
        my $session = $self->store->fetch_path('sessions', $token);
        return unless $session;
        return if $session->is_expired;
        $session->touch;
        return $session;
    }

    sub login {
        my ($self, $args, $context) = @_;
        my $handle = $args->{handle} // $args->{email};
        my $password = $args->{password};

        return (0, "handle/email required") unless $handle;
        return (0, "password required") unless $password;

        my $user = $self->store->fetch_path('users', lc($handle));
        return (0, "invalid credentials") unless $user;
        return (0, "invalid credentials") unless $user->verify_password($password);

        my $token = Yote::YapiServer::Session->generate_token();
        my $session = $self->store->new_obj('Yote::YapiServer::Session', token => $token, user => $user);
        $self->store->set_path('sessions', $token, $session);

        # Return raw user object — Handler serializes it
        return (1, $user, { token => $token });
    }

    sub logout {
        my ($self, $args, $context) = @_;
        my $session = $context->{session};
        return (0, "not logged in") unless $session;
        $self->store->del_path('sessions', $session->{_data}{token});
        return (1);
    }

    sub createUser {
        my ($self, $args, $context) = @_;
        # Simplified mock: create user and return like login
        my $user = $self->store->new_obj('Yote::YapiServer::User', handle => $args->{handle});
        my $token = 'new_user_token';
        return (1, $user, { token => $token });
    }

    $INC{'Yote/YapiServer/Site.pm'} = 1;
}

# Now load the actual Handler module
use Yote::YapiServer::Handler;

#----------------------------------------------------------------------
# Test helpers
#----------------------------------------------------------------------

sub setup_store {
    my $store = MockStore->new();
    my $root = $store->new_obj('Yote::YapiServer::Site');
    $root->init;
    $store->{root} = $root;

    # Create test app
    my $app = $store->new_obj('Yote::YapiServer::App::TestApp', app_name => 'testapp');
    $root->{_data}{apps}{testapp} = $app;

    return ($store, $root, $app);
}

#----------------------------------------------------------------------
# Request parsing tests
#----------------------------------------------------------------------

subtest 'handle - invalid JSON' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => 'not json',
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/invalid JSON/, 'error mentions invalid JSON');
};

subtest 'handle - unknown action' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'unknown' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/unknown action/, 'error mentions unknown action');
};

#----------------------------------------------------------------------
# Connect action tests
#----------------------------------------------------------------------

subtest 'handle - connect without app name' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'connect' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/app name required/, 'error mentions app name required');
};

subtest 'handle - connect with unknown app' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'connect', app => 'nonexistent' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/unknown app/, 'error mentions unknown app');
};

subtest 'handle - connect success' => sub {
    my ($store, $root, $app) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'connect', app => 'testapp' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'r_app_testapp', 'resp is r_app_testapp (r prefix for reference)');
    ok($data->{apps}{_app_testapp}, 'apps section has _app_testapp');
    ok(grep({ $_ eq 'hello' } @{$data->{apps}{_app_testapp}}), 'hello method in app methods');
    ok(!grep({ $_ eq 'secret' } @{$data->{apps}{_app_testapp}}), 'secret method excluded for anonymous');
    ok($data->{token}, 'token always present');
    ok($data->{objects}{_app_testapp}, 'app object in objects');
    is($data->{objects}{_app_testapp}{data}{version}, 'v1.0', 'publicVars in app object data (v prefix)');
};

#----------------------------------------------------------------------
# Call action tests
#----------------------------------------------------------------------

subtest 'handle - call without target' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'call', method => 'hello' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/target required/, 'error mentions target required');
};

subtest 'handle - call without method' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({ action => 'call', target => 'testapp' }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/method required/, 'error mentions method required');
};

subtest 'handle - call public method on app' => sub {
    my ($store, $root, $app) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => 'testapp',
            method => 'hello',
            args   => { name => 'vBob' },
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'vHello, Bob', 'resp is correct (v prefix for value)');
    ok($data->{token}, 'token always present');
};

subtest 'handle - call public method with default args' => sub {
    my ($store, $root, $app) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => 'testapp',
            method => 'hello',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'vHello, World', 'default arg used (v prefix)');
};

subtest 'handle - call via _app_ target' => sub {
    my ($store, $root, $app) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => '_app_testapp',
            method => 'hello',
            args   => { name => 'vEve' },
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'vHello, Eve', '_app_ target works (v prefix)');
};

subtest 'handle - call auth method without token' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => 'testapp',
            method => 'secret',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/authentication required/, 'error mentions auth required');
};

subtest 'handle - call auth method with valid token' => sub {
    my ($store, $root) = setup_store();

    # Create a session with user
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'testuser');
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'valid_token', user => $user);
    $store->set_path('sessions', 'valid_token', $session);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => 'testapp',
            method => 'secret',
            token  => 'valid_token',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'vsecret data', 'auth method returned result (v prefix)');
    is($data->{token}, 'valid_token', 'token returned matches session token');
};

subtest 'handle - call method on object by ID' => sub {
    my ($store, $root, $app) = setup_store();

    # Create session and expose the app object
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'testuser');
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'obj_token', user => $user);
    $session->expose_object($app);
    $store->set_path('sessions', 'obj_token', $session);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => '_obj_' . $app->id,
            method => 'hello',
            args   => { name => 'vAlice' },
            token  => 'obj_token',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    is($data->{resp}, 'vHello, Alice', 'method called on object (v prefix)');
};

subtest 'handle - call on non-exposed object denied' => sub {
    my ($store, $root, $app) = setup_store();

    # Create session but don't expose the object
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'testuser');
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'no_access_token', user => $user);
    $store->set_path('sessions', 'no_access_token', $session);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => '_obj_' . $app->id,
            method => 'hello',
            token  => 'no_access_token',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'ok is 0');
    like($data->{error}, qr/access denied/, 'error mentions access denied');
};

#----------------------------------------------------------------------
# Argument validation tests
#----------------------------------------------------------------------

subtest 'validate_args - v-prefixed scalar args' => sub {
    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { name => 'vtest', count => 'v42' },
        { session => undef, store => undef }
    );

    ok($ok, 'validation succeeded');
    is($result->{name}, 'test', 'v prefix stripped from string');
    is($result->{count}, '42', 'v prefix stripped from number');
};

subtest 'validate_args - unprefixed args rejected' => sub {
    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { name => 'test' },
        { session => undef, store => undef }
    );

    ok(!$ok, 'validation failed');
    like($result, qr/invalid argument encoding/, 'error mentions missing prefix');
};

subtest 'validate_args - r-prefixed object ref without session denied' => sub {
    my $store = MockStore->new();

    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { item => 'r_obj_123' },
        { session => undef, store => $store }
    );

    ok(!$ok, 'validation failed');
    like($result, qr/access denied/, 'error mentions access denied');
};

subtest 'validate_args - r-prefixed object ref with access allowed' => sub {
    my ($store) = setup_store();
    my $obj = $store->new_obj('Yote::YapiServer::App::TestApp', app_name => 'reftest');

    my $session = $store->new_obj('Yote::YapiServer::Session');
    $session->expose_object($obj);

    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { item => 'r_obj_' . $obj->id },
        { session => $session, store => $store }
    );

    ok($ok, 'validation succeeded');
    is($result->{item}->id, $obj->id, 'object reference resolved');
};

subtest 'validate_args - nested hash and array args' => sub {
    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { outer => { inner => 'vdeep' }, list => ['va', 'vb'] },
        { session => undef, store => undef }
    );

    ok($ok, 'validation succeeded');
    is($result->{outer}{inner}, 'deep', 'nested hash v prefix stripped');
    is_deeply($result->{list}, ['a', 'b'], 'array v prefixes stripped');
};

subtest 'validate_args - f-prefixed rejected without files flag' => sub {
    my ($ok, $result) = Yote::YapiServer::Handler->validate_args(
        { pic => 'ftest.png|data:image/png;base64,iVBOR' },
        { session => undef, store => undef, allow_files => 0 }
    );

    ok(!$ok, 'validation failed');
    like($result, qr/file uploads not allowed/, 'error mentions files not allowed');
};

#----------------------------------------------------------------------
# Rate limiting tests
#----------------------------------------------------------------------

subtest 'check_rate_limit - returns undef when not exceeded' => sub {
    # Clear rate limits
    %Yote::YapiServer::Handler::rate_limits = ();

    my $result = Yote::YapiServer::Handler->check_rate_limit('default', '1.2.3.4', undef);
    ok(!defined $result, 'returns undef (OK to proceed)');
};

subtest 'check_rate_limit - per_ip limiting' => sub {
    %Yote::YapiServer::Handler::rate_limits = ();

    for my $i (1..5) {
        my $result = Yote::YapiServer::Handler->check_rate_limit('createUser', '5.6.7.8', undef);
        ok(!defined $result, "request $i allowed");
    }

    # 6th request should be rate limited
    my ($ok, $error) = Yote::YapiServer::Handler->check_rate_limit('createUser', '5.6.7.8', undef);
    is($ok, 0, 'ok is 0');
    like($error, qr/rate limit exceeded/, 'error mentions rate limit');
};

subtest 'check_rate_limit - different IPs tracked separately' => sub {
    %Yote::YapiServer::Handler::rate_limits = ();

    for (1..5) {
        Yote::YapiServer::Handler->check_rate_limit('createUser', '10.0.0.1', undef);
    }

    # Different IP should not be rate limited
    my $result = Yote::YapiServer::Handler->check_rate_limit('createUser', '10.0.0.2', undef);
    ok(!defined $result, 'different IP not rate limited');
};

#----------------------------------------------------------------------
# Response formatting tests
#----------------------------------------------------------------------

subtest 'success_response - new format with token' => sub {
    my $session = Yote::YapiServer::Session->new(token => 'test_tok');
    my $response = Yote::YapiServer::Handler->success_response('hello', {}, $session);

    ok(defined $response, 'response is defined');
    my $decoded = decode_json($response);
    is($decoded->{ok}, 1, 'ok is 1');
    is($decoded->{resp}, 'hello', 'resp preserved');
    is($decoded->{token}, 'test_tok', 'token from session');
};

subtest 'success_response - extra token overrides session' => sub {
    my $session = Yote::YapiServer::Session->new(token => 'old_tok');
    my $response = Yote::YapiServer::Handler->success_response('data', { token => 'new_tok' }, $session);

    my $decoded = decode_json($response);
    is($decoded->{token}, 'new_tok', 'extra token overrides session token');
};

subtest 'success_response - merges objects/classes/apps' => sub {
    my $session = Yote::YapiServer::Session->new(token => 'tok');
    my $extra = {
        objects => { '_obj_1' => { _class => 'Foo', data => { x => 1 } } },
        classes => { 'Foo' => ['bar'] },
        apps    => { '_app_test' => ['hello'] },
    };
    my $response = Yote::YapiServer::Handler->success_response('ok', $extra, $session);

    my $decoded = decode_json($response);
    is($decoded->{objects}{'_obj_1'}{_class}, 'Foo', 'objects merged');
    is_deeply($decoded->{classes}{Foo}, ['bar'], 'classes merged');
    is_deeply($decoded->{apps}{_app_test}, ['hello'], 'apps merged');
};

subtest 'error_response - formats error' => sub {
    my $response = Yote::YapiServer::Handler->error_response('something went wrong');

    my $decoded = decode_json($response);
    is($decoded->{ok}, 0, 'ok is 0');
    is($decoded->{error}, 'something went wrong', 'error message preserved');
};

#----------------------------------------------------------------------
# Login/logout action tests
#----------------------------------------------------------------------

subtest 'handle - login action success' => sub {
    my ($store, $root) = setup_store();

    # Create a user
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'loginuser');
    $user->set_password('pass123');
    $store->set_path('users', 'loginuser', $user);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'login',
            args   => { handle => 'loginuser', password => 'pass123' },
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'login ok');
    ok($data->{token}, 'token returned');
    # resp is the user object ID with r prefix
    like($data->{resp}, qr/^r_obj_\d+$/, 'resp is r-prefixed user object ID');
    # strip the r prefix to look up in objects map
    my $obj_id = substr($data->{resp}, 1);
    ok($data->{objects}{$obj_id}, 'user object in objects map');
    is($data->{objects}{$obj_id}{_class}, 'User', 'user class is User');
    is($data->{objects}{$obj_id}{data}{handle}, 'vloginuser', 'user handle in data (v prefix)');
};

subtest 'handle - login with wrong password' => sub {
    my ($store, $root) = setup_store();

    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'wrongpassuser');
    $user->set_password('correctpass');
    $store->set_path('users', 'wrongpassuser', $user);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'login',
            args   => { handle => 'wrongpassuser', password => 'wrongpass' },
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 0, 'login failed');
    like($data->{error}, qr/invalid credentials/, 'error mentions credentials');
};

subtest 'handle - logout action' => sub {
    my ($store, $root) = setup_store();

    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'logout_token');
    $store->set_path('sessions', 'logout_token', $session);

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'logout',
            token  => 'logout_token',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'logout ok');
};

subtest 'handle - createUser action' => sub {
    my ($store) = setup_store();

    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'createUser',
            args   => { handle => 'newuser', email => 'new@test.com', password => 'password123' },
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'createUser ok');
    ok($data->{token}, 'token returned');
};

#----------------------------------------------------------------------
# Token always present tests
#----------------------------------------------------------------------

subtest 'handle - token always present in success response' => sub {
    my ($store) = setup_store();

    # Even without providing a token, an anonymous session is created
    my $response = Yote::YapiServer::Handler->handle(
        store => $store,
        body  => encode_json({
            action => 'call',
            target => 'testapp',
            method => 'hello',
        }),
    );

    my $data = decode_json($response);
    is($data->{ok}, 1, 'ok is 1');
    ok($data->{token}, 'token present even without providing one');
};

#----------------------------------------------------------------------
# Serialization tests
#----------------------------------------------------------------------

subtest 'serialize_value - dedup objects' => sub {
    my ($store) = setup_store();
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'ser_token');
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'seruser');

    my $ctx = { objects => {}, classes => {} };

    # Serialize same object twice
    my $id1 = Yote::YapiServer::Handler->serialize_value($user, $ctx, $session, $user);
    my $id2 = Yote::YapiServer::Handler->serialize_value($user, $ctx, $session, $user);

    is($id1, $id2, 'same object returns same ID');
    is($id1, 'r_obj_' . $user->id, 'returns r_obj_ ID string (r prefix)');
    is(scalar keys %{$ctx->{objects}}, 1, 'object appears once in context');
};

subtest 'serialize_value - nested objects in hash' => sub {
    my ($store) = setup_store();
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'ser_token2');
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'nested');

    my $ctx = { objects => {}, classes => {} };
    my $result = Yote::YapiServer::Handler->serialize_value(
        { user => $user, count => 5, label => '7' },
        $ctx, $session, $user
    );

    is($result->{user}, 'r_obj_' . $user->id, 'object replaced with r-prefixed ID in hash');
    is($result->{count}, 5, 'numeric scalar passes through as JSON number');
    ok(!ref $result->{count} && "$result->{count}" eq '5', 'numeric scalar is numeric');
    is($result->{label}, 'v7', 'numeric-looking string still gets v prefix');
    ok($ctx->{objects}{'_obj_' . $user->id}, 'object accumulated in context');
};

subtest 'serialize_value - numeric vs string scalars' => sub {
    # Regression: is_admin = 0 was being emitted as the string "v0" which
    # round-tripped to truthy "0" in JS. Numbers must emit as JSON numbers,
    # strings (including numeric-looking strings) must keep the v prefix.
    my ($store) = setup_store();
    my $user = $store->new_obj('Yote::YapiServer::User', handle => 'scalartest');
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'scalar_token');

    my $ctx = { objects => {}, classes => {} };
    my $zero      = Yote::YapiServer::Handler->serialize_value(0,     $ctx, $session, $user);
    my $one       = Yote::YapiServer::Handler->serialize_value(1,     $ctx, $session, $user);
    my $float     = Yote::YapiServer::Handler->serialize_value(3.14,  $ctx, $session, $user);
    my $str_zero  = Yote::YapiServer::Handler->serialize_value('0',   $ctx, $session, $user);
    my $str_ver   = Yote::YapiServer::Handler->serialize_value('1.0', $ctx, $session, $user);
    my $str_name  = Yote::YapiServer::Handler->serialize_value('hi',  $ctx, $session, $user);

    is($zero,     0,      'numeric 0 stays numeric');
    is($one,      1,      'numeric 1 stays numeric');
    is($float,    3.14,   'numeric float stays numeric');
    is($str_zero, 'v0',   'string "0" gets v prefix');
    is($str_ver,  'v1.0', 'numeric-looking version string gets v prefix');
    is($str_name, 'vhi',  'plain string gets v prefix');
};

subtest 'serialize_value - array of objects' => sub {
    my ($store) = setup_store();
    my $session = $store->new_obj('Yote::YapiServer::Session', token => 'ser_token3');
    my $u1 = $store->new_obj('Yote::YapiServer::User', handle => 'user1');
    my $u2 = $store->new_obj('Yote::YapiServer::User', handle => 'user2');

    my $ctx = { objects => {}, classes => {} };
    my $result = Yote::YapiServer::Handler->serialize_value(
        [$u1, $u2],
        $ctx, $session, $u1
    );

    is(scalar @$result, 2, 'array has 2 elements');
    is($result->[0], 'r_obj_' . $u1->id, 'first element is r-prefixed ID');
    is($result->[1], 'r_obj_' . $u2->id, 'second element is r-prefixed ID');
    is(scalar keys %{$ctx->{objects}}, 2, '2 objects in context');
    ok($ctx->{classes}{User}, 'User class captured');
};

done_testing();
