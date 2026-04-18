#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

# Mock the base class before loading App::Base
BEGIN {
    package Yote::SQLObjectStore::BaseObj;
    sub new {
        my ($class, %args) = @_;
        bless { %args, _data => {} }, $class;
    }
    sub id { shift->{id} // int(rand(10000)) }

    for my $field (qw(app_name created settings owner)) {
        no strict 'refs';
        *{"get_$field"} = sub { shift->{_data}{$field} };
        *{"set_$field"} = sub { shift->{_data}{$field} = $_[0] };
    }

    $INC{'Yote/SQLObjectStore/BaseObj.pm'} = 1;

    # Mock BaseObj (App::Base inherits from this)
    package Yote::YapiServer::BaseObj;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');

    sub field_access {
        my ($self) = @_;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::FIELD_ACCESS"};
    }

    sub method_defs {
        my ($self) = @_;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::METHODS"};
    }

    sub _client_class_name {
        my ($self) = @_;
        my $class = ref($self) || $self;
        $class =~ s/^Yote::YapiServer::App:://;
        $class =~ s/^Yote::YapiServer:://;
        return $class;
    }

    sub to_client_hash {
        my ($self, $session, $viewer) = @_;
        my %result;
        my $field_access = $self->field_access;
        my $is_owner = $viewer && $self->can('get_owner') &&
                       $self->get_owner && $self->get_owner->id eq $viewer->id;
        my $is_admin = $viewer && $viewer->get_is_admin;
        for my $field (keys %$field_access) {
            my $rule = $field_access->{$field};
            next if $rule->{never};
            next if $rule->{owner_only} && !$is_owner && !$is_admin;
            next if $rule->{admin_only} && !$is_admin;
            my $getter = "get_$field";
            $result{$field} = $self->$getter if $self->can($getter);
        }
        return \%result;
    }

    $INC{'Yote/YapiServer/BaseObj.pm'} = 1;

    # Mock Session
    package Yote::YapiServer::Session;
    sub new { bless { exposed => {} }, shift }
    sub expose_object {
        my ($self, $obj) = @_;
        return unless $obj && $obj->can('id');
        $self->{exposed}{$obj->id} = 1;
    }
    sub can_access {
        my ($self, $obj) = @_;
        my $id = ref $obj ? $obj->id : $obj;
        return $self->{exposed}{$id};
    }
    sub get_user { shift->{user} }
    $INC{'Yote::YapiServer/Session.pm'} = 1;

    # Mock User
    package Yote::YapiServer::User;
    sub new { bless { id => $_[1] // int(rand(10000)) }, shift }
    sub id { shift->{id} }
    sub get_is_admin { shift->{is_admin} // 0 }
    sub set_is_admin { my $self = shift; $self->{is_admin} = shift }
    $INC{'Yote::YapiServer/User.pm'} = 1;
}

use Yote::YapiServer::App::Base;

#----------------------------------------------------------------------
# Test subclass for testing
#----------------------------------------------------------------------

package TestApp;
use base 'Yote::YapiServer::App::Base';

our %METHODS = (
    publicMethod    => { public => 1 },
    authMethod      => { auth => 1 },
    ownerMethod     => { owner_only => 1 },
    adminMethod     => { admin_only => 1 },
);

our %FIELD_ACCESS = (
    app_name => { public => 1 },
    secret   => { never => 1 },
    email    => { owner_only => 1 },
    status   => { admin_only => 1 },
);

our %PUBLIC_VARS = (
    appVersion => '1.0.0',
    appName    => 'Test App',
);

sub publicMethod { return "public result" }
sub authMethod { return "auth result" }
sub ownerMethod { return "owner result" }
sub adminMethod { return "admin result" }

package main;

#----------------------------------------------------------------------
# Class data accessor tests
#----------------------------------------------------------------------

subtest 'method_defs - returns class methods hash' => sub {
    my $app = TestApp->new();
    my $methods = $app->method_defs();

    is(ref($methods), 'HASH', 'returns hashref');
    ok($methods->{publicMethod}{public}, 'publicMethod is public');
    ok($methods->{authMethod}{auth}, 'authMethod requires auth');
    ok($methods->{ownerMethod}{owner_only}, 'ownerMethod is owner_only');
    ok($methods->{adminMethod}{admin_only}, 'adminMethod is admin_only');
};

subtest 'field_access - returns class field access hash' => sub {
    my $app = TestApp->new();
    my $access = $app->field_access();

    is(ref($access), 'HASH', 'returns hashref');
    ok($access->{app_name}{public}, 'app_name is public');
    ok($access->{secret}{never}, 'secret is never');
    ok($access->{email}{owner_only}, 'email is owner_only');
    ok($access->{status}{admin_only}, 'status is admin_only');
};

subtest 'public_vars - returns class public vars' => sub {
    my $app = TestApp->new();
    my $vars = $app->public_vars();

    is(ref($vars), 'HASH', 'returns hashref');
    is($vars->{appVersion}, '1.0.0', 'appVersion is correct');
    is($vars->{appName}, 'Test App', 'appName is correct');
};

#----------------------------------------------------------------------
# Version tests
#----------------------------------------------------------------------

subtest 'version - App::Base returns default version 1' => sub {
    my $version = Yote::YapiServer::App::Base->version();
    is($version, 1, 'App::Base default version is 1');
};

subtest 'version - subclass can override version' => sub {
    {
        package VersionedApp;
        use base 'Yote::YapiServer::App::Base';
        our $app_version = 3;
    }

    my $version = VersionedApp->version();
    is($version, 3, 'subclass returns overridden version');
};

subtest 'version - works on instances too' => sub {
    {
        package VersionedApp2;
        use base 'Yote::YapiServer::App::Base';
        our $app_version = 5;
    }

    my $app = VersionedApp2->new();
    is($app->version(), 5, 'version works on instance');
};

#----------------------------------------------------------------------
# Ownership tests
#----------------------------------------------------------------------

subtest 'get_owner - apps are their own owners' => sub {
    my $app = TestApp->new(id => 42);
    $app->set_owner($app);
    my $owner = $app->get_owner();
    is($owner, $app, 'app returns self as owner');
    is($owner->id, 42, 'owner id matches app id');
};

#----------------------------------------------------------------------
# Method authorization tests
#----------------------------------------------------------------------

subtest 'authorize_method - public method' => sub {
    my $app = TestApp->new();

    # No session, no user - should still work
    my ($ok, $error) = $app->authorize_method('publicMethod', undef, undef);
    ok($ok, 'public method authorized without auth');
    ok(!defined $error, 'no error message');
};

subtest 'authorize_method - unknown method' => sub {
    my $app = TestApp->new();

    my ($ok, $error) = $app->authorize_method('unknownMethod', undef, undef);
    ok(!$ok, 'unknown method not authorized');
    like($error, qr/unknown method/, 'error mentions unknown method');
};

subtest 'authorize_method - auth method without session' => sub {
    my $app = TestApp->new();

    my ($ok, $error) = $app->authorize_method('authMethod', undef, undef);
    ok(!$ok, 'auth method not authorized without session');
    like($error, qr/authentication required/, 'error mentions auth required');
};

subtest 'authorize_method - auth method with session' => sub {
    my $app = TestApp->new();
    my $session = Yote::YapiServer::Session->new();
    my $user = Yote::YapiServer::User->new();

    my ($ok, $error) = $app->authorize_method('authMethod', $session, $user);
    ok($ok, 'auth method authorized with session');
};

subtest 'authorize_method - admin method without admin' => sub {
    my $app = TestApp->new();
    my $session = Yote::YapiServer::Session->new();
    my $user = Yote::YapiServer::User->new();
    $user->set_is_admin(0);

    my ($ok, $error) = $app->authorize_method('adminMethod', $session, $user);
    ok(!$ok, 'admin method not authorized for non-admin');
    like($error, qr/admin access required/, 'error mentions admin required');
};

subtest 'authorize_method - admin method with admin' => sub {
    my $app = TestApp->new();
    my $session = Yote::YapiServer::Session->new();
    my $user = Yote::YapiServer::User->new();
    $user->set_is_admin(1);

    my ($ok, $error) = $app->authorize_method('adminMethod', $session, $user);
    ok($ok, 'admin method authorized for admin user');
};

#----------------------------------------------------------------------
# Object-level authorization tests
#----------------------------------------------------------------------

package OwnedObject;
use base 'Yote::YapiServer::App::Base';
our %METHODS = (
    publicMethod => { public => 1 },
    ownerMethod  => { owner_only => 1 },
);
sub get_owner { shift->{_data}{owner} }
sub set_owner { my $self = shift; $self->{_data}{owner} = shift }

package main;

subtest 'authorize_object_method - object not accessible' => sub {
    my $obj = OwnedObject->new(id => 100);
    my $session = Yote::YapiServer::Session->new();
    my $user = Yote::YapiServer::User->new();

    # Object not exposed to session
    my ($ok, $error) = Yote::YapiServer::App::Base->authorize_object_method(
        $obj, 'publicMethod', $session, $user
    );

    ok(!$ok, 'method not authorized when object not accessible');
    like($error, qr/object not accessible/, 'error mentions object access');
};

subtest 'authorize_object_method - public method on accessible object' => sub {
    my $obj = OwnedObject->new(id => 101);
    my $session = Yote::YapiServer::Session->new();
    my $user = Yote::YapiServer::User->new();

    $session->expose_object($obj);

    my ($ok, $error) = Yote::YapiServer::App::Base->authorize_object_method(
        $obj, 'publicMethod', $session, $user
    );

    ok($ok, 'public method authorized on accessible object');
};

subtest 'authorize_object_method - owner_only for non-owner' => sub {
    my $owner = Yote::YapiServer::User->new(100);
    my $other = Yote::YapiServer::User->new(200);

    my $obj = OwnedObject->new(id => 102);
    $obj->set_owner($owner);

    my $session = Yote::YapiServer::Session->new();
    $session->expose_object($obj);

    my ($ok, $error) = Yote::YapiServer::App::Base->authorize_object_method(
        $obj, 'ownerMethod', $session, $other
    );

    ok(!$ok, 'owner_only method not authorized for non-owner');
    like($error, qr/owner access required/, 'error mentions owner required');
};

subtest 'authorize_object_method - owner_only for owner' => sub {
    my $owner = Yote::YapiServer::User->new(100);

    my $obj = OwnedObject->new(id => 103);
    $obj->set_owner($owner);

    my $session = Yote::YapiServer::Session->new();
    $session->expose_object($obj);

    my ($ok, $error) = Yote::YapiServer::App::Base->authorize_object_method(
        $obj, 'ownerMethod', $session, $owner
    );

    ok($ok, 'owner_only method authorized for owner');
};

#----------------------------------------------------------------------
# Serialization tests
#----------------------------------------------------------------------

package SerializableApp;
use base 'Yote::YapiServer::App::Base';
our %FIELD_ACCESS = (
    app_name => { public => 1 },
    secret   => { never => 1 },
    email    => { owner_only => 1 },
    status   => { admin_only => 1 },
);
sub get_app_name { 'testapp' }
sub get_secret { 'topsecret' }
sub get_email { 'user@test.com' }
sub get_status { 'active' }

package main;

subtest 'to_client_hash - returns data fields only (no metadata)' => sub {
    my $app = SerializableApp->new(id => 500);
    my $session = Yote::YapiServer::Session->new();

    my $hash = $app->to_client_hash($session, undef);

    ok(!exists $hash->{_objId}, 'no _objId in result');
    ok(!exists $hash->{_class}, 'no _class in result');
};

subtest 'to_client_hash - public fields included' => sub {
    my $app = SerializableApp->new(id => 501);
    my $session = Yote::YapiServer::Session->new();

    my $hash = $app->to_client_hash($session, undef);

    is($hash->{app_name}, 'testapp', 'public field included');
};

subtest 'to_client_hash - never fields excluded' => sub {
    my $app = SerializableApp->new(id => 502);
    my $session = Yote::YapiServer::Session->new();

    my $hash = $app->to_client_hash($session, undef);

    ok(!exists $hash->{secret}, 'never field excluded');
};

subtest 'to_client_hash - owner_only excluded for non-owner' => sub {
    my $app = SerializableApp->new(id => 503);
    my $session = Yote::YapiServer::Session->new();
    my $viewer = Yote::YapiServer::User->new(999);

    my $hash = $app->to_client_hash($session, $viewer);

    ok(!exists $hash->{email}, 'owner_only field excluded for non-owner');
};

subtest 'to_client_hash - admin_only excluded for non-admin' => sub {
    my $app = SerializableApp->new(id => 504);
    my $session = Yote::YapiServer::Session->new();
    my $viewer = Yote::YapiServer::User->new(999);
    $viewer->set_is_admin(0);

    my $hash = $app->to_client_hash($session, $viewer);

    ok(!exists $hash->{status}, 'admin_only field excluded for non-admin');
};

subtest 'to_client_hash - admin_only included for admin' => sub {
    my $app = SerializableApp->new(id => 505);
    my $session = Yote::YapiServer::Session->new();
    my $viewer = Yote::YapiServer::User->new(999);
    $viewer->set_is_admin(1);

    my $hash = $app->to_client_hash($session, $viewer);

    is($hash->{status}, 'active', 'admin_only field included for admin');
};

subtest 'to_client_hash - does not expose object to session' => sub {
    my $app = SerializableApp->new(id => 506);
    my $session = Yote::YapiServer::Session->new();

    ok(!$session->can_access(506), 'object not accessible before serialization');

    $app->to_client_hash($session, undef);

    ok(!$session->can_access(506), 'object not accessible after to_client_hash (Handler handles exposure)');
};

#----------------------------------------------------------------------
# connect_info_methods tests
#----------------------------------------------------------------------

subtest 'connect_info_methods - includes public methods' => sub {
    my $app = TestApp->new(id => 601);

    my $methods = $app->connect_info_methods(undef, undef);

    ok(grep { $_ eq 'publicMethod' } @$methods, 'public method included');
};

subtest 'connect_info_methods - excludes auth methods for anonymous' => sub {
    my $app = TestApp->new(id => 602);

    my $methods = $app->connect_info_methods(undef, undef);

    ok(!grep { $_ eq 'authMethod' } @$methods, 'auth method excluded for anonymous');
};

subtest 'connect_info_methods - includes auth methods for logged in user' => sub {
    my $app = TestApp->new(id => 603);
    my $user = Yote::YapiServer::User->new();

    my $methods = $app->connect_info_methods(undef, $user);

    ok(grep { $_ eq 'authMethod' } @$methods, 'auth method included for user');
    ok(grep { $_ eq 'ownerMethod' } @$methods, 'owner method included for user');
};

subtest 'connect_info_methods - includes admin methods for admin' => sub {
    my $app = TestApp->new(id => 604);
    my $user = Yote::YapiServer::User->new();
    $user->set_is_admin(1);

    my $methods = $app->connect_info_methods(undef, $user);

    ok(grep { $_ eq 'adminMethod' } @$methods, 'admin method included for admin');
};

subtest 'connect_info_methods - excludes admin methods for non-admin' => sub {
    my $app = TestApp->new(id => 605);
    my $user = Yote::YapiServer::User->new();
    $user->set_is_admin(0);

    my $methods = $app->connect_info_methods(undef, $user);

    ok(!grep { $_ eq 'adminMethod' } @$methods, 'admin method excluded for non-admin');
};

done_testing();
