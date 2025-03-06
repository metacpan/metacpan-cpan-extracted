#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use Cwd;
use File::Spec;

# Load module
use WWW::Suffit::AuthDB::Model;

# Create model instance
my $file = File::Spec->catfile(getcwd(), 'testmodel.db');
my $model = WWW::Suffit::AuthDB::Model->new(
    qq{sqlite://$file?RaiseError=0&PrintError=0&sqlite_unicode=1}
);
ok(!$model->error, "Create model instance") or diag($model->error);
#note(explain($model));

# Initialize schema
$model->connect->initialize;
ok(!$model->error, "Initialize schema") or diag $model->error;
ok($model->is_initialized, "Schema is initialized");

# Skip if no connect
unless ($model->ping) {
    fail sprintf(qq{Can't connect to database "%s"}, $model->dsn);
    diag $model->error;
    goto DONE;
}

# Meta CRUD
subtest 'Meta CRUD' => sub {

    # Get "schema.version" from meta
    {
        my %data = $model->meta_get("schema.version");
        ok(!$model->error, "Get `schema.version` from meta") or diag $model->error;
        ok($data{value}, "Key `schema.version` is true");
        #note(explain(\%data));
    }

    # Add the foo key to meta
    {
        ok($model->meta_set(
            key     => "foo",
            value   => "test",
        ), "Add the foo key to meta") or diag($model->error);
    }

    # Add the bar key to meta
    {
        ok($model->meta_set(
            key     => "bar",
            value   => "123",
        ), "Add the bar key to meta") or diag($model->error);
    }

    # Update the key in meta
    {
        ok($model->meta_set(
            key     => "foo",
            value   => "test2",
        ), "Update the foo key in meta") or diag($model->error);
    }

    # Get the `foo` key from meta
    {
        my %data = $model->meta_get("foo");
        ok(!$model->error, "Get foo from meta") or diag $model->error;
        is($data{value}, "test2", "Get the `foo` key from meta");
        #note(explain(\%data));
    }

    # Get whole meta data
    {
        my @data = $model->meta_get;
        ok(!$model->error, "Get whole meta data") or diag $model->error;
        ok(scalar(@data), "Data found");
        #note(explain(\@data));
    }

    # Delete the `foo` key from meta
    {
        ok($model->meta_del("foo"), "Delete the `foo` key from meta") or diag $model->error;
    }

};

# Stat CRUD
subtest 'Stat CRUD' => sub {

    # Add stat info
    {
        ok($model->stat_set(
            address     => '127.0.0.1',
            username    => 'bob',
            dismiss     => 1,
            updated     => time,
        ), "Add stat info") or diag($model->error);
    }

    # Set stat info
    {
        ok($model->stat_set(
            address     => '127.0.0.1',
            username    => 'bob',
            dismiss     => 2,
            updated     => time,
        ), "Set stat info") or diag($model->error);
    }

    # Get stat info
    {
        my %data = $model->stat_get('127.0.0.1', 'bob');
        ok(!$model->error, "Get stat info") or diag $model->error;
        is($data{dismiss}, "2", "Get the `dismiss` attribute from `stat` data");
        #note(explain(\%data));
    }

};

# User CRUD
subtest 'User CRUD' => sub {

    # Add new user
    {
        ok($model->user_add(
            username    => "admin",
            name        => "Administrator",
            email       => 'root@localhost',
            password    => "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
            algorithm   => "SHA256",
            role        => "System administrator",
            flags       => 0,
            created     => time(),
            not_before  => time(),
            not_after   => undef,
            public_key  => "",
            private_key => "",
            attributes  => qq/{"disabled": 0}/,
            comment     => "This user added by default",
        ), "Add new user") or diag $model->error;
    }

    # Get user's data
    {
        my %data = $model->user_get("admin");
        ok(!$model->error, "Get user's data") or diag $model->error;
        #note(explain(\%data));
    }

    # Set user's data
    {
        ok($model->user_set(
            username    => "admin",
            name        => "Administrator",
            email       => 'root@localhost',
            password    => "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
            algorithm   => "SHA256",
            role        => "System administrator",
            flags       => 0,
            not_before  => time(),
            not_after   => undef,
            public_key  => "",
            private_key => "",
            attributes  => qq/{"disabled": 0}/,
            comment     => "This user was modified",
        ), "Set user's data") or diag $model->error;
    }

    # Get all records
    {
        my @all = $model->user_getall();
        ok(scalar(@all), "Get all users") or diag $model->error;
        #note(explain(\@all));
    }
};

# Group CRUD
subtest 'Group CRUD' => sub {

    # Add new groop
    {
        ok($model->group_add(
            groupname   => "wheel",
            description => "This group added by default",
        ), "Add new group") or diag $model->error;
    }

    # Get group's data
    {
        my %data = $model->group_get("wheel");
        ok(!$model->error, "Get group's data") or diag $model->error;
        #note(explain(\%data));
    }

    # Set group's data
    {
        ok($model->group_set(
            groupname   => "wheel",
            description => "This group was modified",
        ), "Set group's data") or diag $model->error;
    }

    # Get all records
    {
        my @all = $model->group_getall();
        ok(scalar(@all), "Get all groups") or diag $model->error;
        #note(explain(\@all));
    }

    # Add the user to the group
    {
        ok($model->grpusr_add(
            groupname   => "wheel",
            username    => "root",
        ), "Add the user to the group") or diag($model->error);
    }

    # Get members of group
    {
        my @data = $model->grpusr_get( groupname => "wheel" );
        ok(!$model->error, "Get members of group") or diag $model->error;
        #note(explain(\@data));
    }

};

# Realm CRUD
subtest 'Realm CRUD' => sub {

    # Add new realm
    {
        ok($model->realm_add(
            realmname   => "root",
            url         => "http://localhost:8695",
            method      => "GET",
            realm       => "/",
            description => "Index page",
        ), "Add new realm") or diag $model->error;
    }

    # Get realm's data
    {
        my %data = $model->realm_get("root");
        ok(!$model->error, "Get realm's data") or diag $model->error;
        #note(explain(\%data));
    }

    # Set realm's data
    {
        ok($model->realm_set(
            realmname   => "root",
            url         => "http://localhost:8695",
            method      => "GET",
            realm       => "/",
            description => "Index page (was modified)",
        ), "Set realm's data") or diag $model->error;
    }

    # Get all records
    {
        my @all = $model->realm_getall();
        ok(scalar(@all), "Get all realms") or diag $model->error;
        #note(explain(\@all));
    }

    # Add new requirement
    {
        ok($model->realm_requirement_add(
            realmname   => "root",
            provider    => "user",
            entity      => "admin",
        ), "Add new requirement") or diag $model->error;
    }

    # Get requirement's data
    {
        my @data = $model->realm_requirements("root");
        ok(!$model->error, "Get requirement's data") or diag $model->error;
        #note(explain(\@data));
    }

};

# Delete entities
subtest 'Delete entities' => sub {

    # Delete realm
    {
        ok($model->realm_del("root"), "Delete realm") or diag $model->error;
    }

    # Delete all requirements
    {
        ok($model->realm_requirement_del("root"), "Delete all requirements") or diag $model->error;
    }

    # Delete all members of group
    {
        ok($model->grpusr_del( groupname => "wheel"), "Delete all members of group") or diag $model->error;
    }

    # Delete group
    {
        ok($model->group_del("wheel"), "Delete group") or diag $model->error;
    }

    # Delete user
    {
        ok($model->user_del("admin"), "Delete user") or diag $model->error;
    }

};

undef $model;
# unlink $file;

DONE: done_testing;

__END__

prove -lv t/03-model.t
