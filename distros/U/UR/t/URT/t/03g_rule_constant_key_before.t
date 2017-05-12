#!/usr/bin/env perl

use strict;
use warnings;

use UR;
use Test::More;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

ok(setup_classes_and_db(), 'setup classes and DB') or die;

# 'constant key before' tests were added due to bug that occurred when constant keys were specified
# before expanded properties. Since values are split based on whether they are constant (go on template)
# or non-constant (go on rule) there was a mismatch when a rule was normalized.
do {
    # This would work BUT was not equivalent to switching the -order and id k/v pairs.
    my @phone = UR::Context->current->reload('Phone', id => [0], -order => []);
    is(scalar @phone, 1, 'constant key after expanded property (op: in)');
};
do {
    # This would work since make is not expanded.
    my @phone = UR::Context->current->reload('Phone', -order => [], make => ['Nokia']);
    is(scalar @phone, 1, 'constant key before non-expanded property');
};
do {
    my @phone = UR::Context->current->reload('Phone', -order => [], id => [0]);
    is(scalar @phone, 1, 'constant key before expanded property (op: in)');
};
do {
    my @phone = UR::Context->current->reload('Phone', -order => [], id => 0);
    is(scalar @phone, 1, 'constant key before expanded property (op: eq)');
};

done_testing();

sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
    ok($dbh, 'got DB handle');
    ok($dbh->do('create table phones (phone_id integer, make varchar, model varchar)'), 'created phones table');

    my @phone_specs = (
        ['Motorola', 'Atrix'],
        ['Motorola', 'Droid Razr'],
        ['Nokia', 'N9'],
    );
    my $insert = $dbh->prepare('insert into phones (phone_id, make, model) values (?,?,?)');
    for (my $id = 0; $id < @phone_specs; $id++) {
        unless ($insert->execute($id, @{$phone_specs[$id]})) {
            die "Couldn't insert a row into 'phones': $DBI::errstr";
        }
    }
    $dbh->commit;

    my $phone_type = UR::Object::Type->define(
        class_name => 'Phone',
        id_by => [
            phone_id => { is => 'Number' },
        ],
        has => [
            make => { is => 'Text' },
            model => { is => 'Text' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'phones',
    );
    isa_ok($phone_type, 'UR::Object::Type', 'defined Phone class');

    is(Phone->class, 'Phone', 'Phone class is loaded');

    return 1;
}
