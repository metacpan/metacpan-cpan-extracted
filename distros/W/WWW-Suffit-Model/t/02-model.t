#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;

use lib 'eg';

use Cwd;
use File::Spec;

# Load module
use MyModel;

# Create model instance
my $file = File::Spec->catfile(getcwd(), 'test.db');
my $model = MyModel->new(
    qq{sqlite://$file?RaiseError=0&PrintError=0&sqlite_unicode=1}
);
ok(!$model->error, "Create model instance") or diag $model->error;

# Initialize schema
$model->connect->init;
ok(!$model->error, "Initialize schema") or diag $model->error;
note " Package : ", $model->initiator;
note " Schema  : ", $model->schema;

# Skip if no connect
unless ($model->ping) {
    fail sprintf(qq{Can't connect to database "%s"}, $model->dsn);
    diag $model->error;
    goto DONE;
}
#note(explain($model));

# CRUD: Create, Read, Update, Delete
subtest 'CRUD: Create, Read, Update, Delete' => sub {

    # Create (Add)
    ok($model->comment_add(
        comment => sprintf("%s [$$] Test record", scalar(localtime(time)))
    ), "Add new record") or diag $model->error;

    # Get last inserted rowid
    my $id = $model->dbh->sqlite_last_insert_rowid();
    ok($id, "Get last inserted rowid") or diag $model->error;
    return unless $id;

    # Get count
    my $count = $model->comment_cnt;
    ok($count, "Get count of records") or diag $model->error;
    note "Count = $count";

    # Get record data
    my %i = $model->comment_get($id);
    ok(!$model->error, "Get record data for id=$id") or diag $model->error;
    is($i{id}, $id, "Check id") or diag explain \%i;
    ok($i{comment} && length($i{comment}), "Check comment") or diag explain \%i;
    #note explain \%i;

    # Get all records
    my @all = $model->comment_get;
    ok(!$model->error, "Get all records") or diag $model->error;
    ok(scalar(@all), "Records >= 1");
    #note(explain(\@all));

    # Update
    ok($model->comment_set(
        id          => $id,
        comment     => "Test",
    ), "Update record") or diag $model->error;
    %i = $model->comment_get($id);
    ok(!$model->error, "Get record data for id=$id (after update)") or diag $model->error;
    is($i{comment}, "Test", "Get test string") or diag explain \%i;

    # Delete
    ok($model->comment_del($id), "Delete") or diag $model->error;
};

undef $model;

DONE: done_testing;

__END__

prove -v t/02-model.t
