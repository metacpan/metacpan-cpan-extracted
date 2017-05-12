use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More tests => 81;

use URT::DataSource::CircFk;
use Data::Dumper;

# This test verifies that sql generation is correct for inserts and deletes
# on tables with nullable foreign key constraints.  For a new object, an
# INSERT statement should be returned, with null values in nullable foreign
# key columns, and a corresponding UPDATE statement to set foreign key
# values after the insert.  For object deletion, an UPDATE statement
# setting nullable foreign keys to null is expected with the DELETE statement

setup_classes_and_db();

my @circular = URT::Circular->get();
my $sqlite_ds = UR::Context->resolve_data_source_for_object($circular[0]);
is (scalar @circular, 5, 'got circular objects');
for (@circular){
    my $id = $_->id;

    ok($_->delete, 'deleted object');

    my $ghost = URT::Circular::Ghost->get(id=> $id);
    my @sql = $sqlite_ds->_default_save_sql_for_object($ghost);
    ok(sql_has_update_and_delete(@sql), "got separate update and delete statement for deleting circular item w/ nullable foreign key");
}

eval{
    UR::Context->commit();
};

ok(!$@, "circular deletion committed successfully!");
diag($@) if $@;

my @bridges = URT::Bridge->get();
for (@bridges){
    my $id = $_->id;
    ok($_->delete(), 'deleted bridge');
    my $ghost = URT::Bridge::Ghost->get(id => $id);
    my @sql = $sqlite_ds->_default_save_sql_for_object($ghost);
    ok(sql_has_delete_only(@sql), "didn't update primary key nullable foreign keys on delete");
}

eval{
    UR::Context->commit();
};

ok( !$@, 'no commit errors on deleting bridge entries w/ nullable foreign keys primary key' );
diag($@) if $@;

my @bridges_check = URT::Bridge->get();

is (scalar @bridges_check, 0, "couldn't retrieve deleted bridges");

my @left = URT::Left->get(id=>[1..5]);
my @right = URT::Right->get();

while (my $left = shift @left){
    my $right = shift @right;
    my $bridge = URT::Bridge->create(left_id => $left->id, right_id => $right->id);
    my @sql = $sqlite_ds->_default_save_sql_for_object($bridge);
    ok(sql_has_insert_only(@sql), "didn't null insert values for bridge entries nullable, no update statement produced)");
}

eval{
    UR::Context->commit();
};

ok( !$@, 'no commit errors on recreating bridge entries' );
diag($@) if $@;


my @chain = ( URT::Gamma->get(), URT::Beta->get(), URT::Alpha->get());

ok (@chain, 'got objects from alpha, beta, and gamma tables');
is (scalar @chain, 3, 'got expected number of objects');
my $gamma = shift @chain;
ok ($gamma->delete, 'deleted_object');

for ("URT::Beta", "URT::Alpha"){
    my $obj = shift @chain;
    my $id = $obj->id;
    my $class = $_."::Ghost";
    ok($obj->delete, 'deleted object');
    my $ghost = $class->get(id => $id);
    my @sql = $sqlite_ds->_default_save_sql_for_object($ghost);
    ok(sql_has_update_and_delete(@sql), "got separate update and delete statement for deleting bridge items w/ nullable foreign key");
}

eval{
    UR::Context->commit();
};

ok(!$@, "no error message on commit: $@");
diag($@) if $@;

my @chain2 = (URT::Alpha->get(), URT::Beta->get(), URT::Gamma->get());

ok(!@chain2, "couldn't get deleted chain objects!");

my ($new_alpha, $new_beta, $new_gamma);

ok($new_alpha = URT::Alpha->create(id => 101, beta_id => 201), 'created new alpha');
my @alpha_sql = $sqlite_ds->_default_save_sql_for_object($new_alpha);
ok($new_beta = URT::Beta->create(id => 201, gamma_id => 301), 'created new beta');
my @beta_sql = $sqlite_ds->_default_save_sql_for_object($new_beta);
ok($new_gamma = URT::Gamma->create(id => 301, type => 'test2'), 'created new gamma');

for (\@alpha_sql, \@beta_sql){
    ok(sql_has_insert_and_update(@$_), 'got seperate insert and update statements for recreating chained objects');
}

eval {
    UR::Context->commit();
};

ok(!$@, "no error message on commit of new alpha,beta,gamma, would fail due to fk constraints if we weren't using sqlite datasource");
diag($@) if $@;

my $check_alpha = URT::Alpha->get(id => 101);
is ($check_alpha->beta_id, 201, 'initial null value updated correctly for chain object');

my $check_beta = URT::Beta->get(id => 201);
is ($check_beta->gamma_id, 301, 'initial null value updated correctly for chain object');

sub sql_has_delete_only{
    my @st = @_;
    return undef if grep {$_->{sql} =~ /update|insert/i} @st;
    return undef unless grep {$_->{sql} =~/delete/i} @st;
    return 1;
}

sub sql_has_insert_only{
    my @st = @_;
    return undef if grep {$_->{sql} =~ /update|delete/i} @st;
    return undef unless grep {$_->{sql} =~/insert/i} @st;
    return 1;
}

sub sql_has_insert_and_update{
    my @st = @_;
    return undef unless grep {$_->{sql} =~ /insert/i} @st;
    return undef unless grep {$_->{sql} =~ /update/i} @st;
    return 1;
}

sub sql_has_update_and_delete{
    my @st = @_;
    return undef unless grep {my $val = $_; $val->{sql} =~ /delete/i} @st;
    return undef unless grep {my $val = $_; $val->{sql} =~ /update/i} @st;
    return 1;

}
sub setup_classes_and_db {
    my $dbh = URT::DataSource::CircFk->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table circular (id integer primary key, parent_id integer REFERENCES circular(id))"),

       'Created circular table');

    ok( $dbh->do("create table left (id integer, right_id integer REFERENCES right(id), right_id2 integer REFERENCES right(id), primary key (id, right_id))"),
       'Created left table');

    ok( $dbh->do("create table right (id integer primary key, left_id integer REFERENCES left(id), left_id2 integer REFERENCES left(id))"),
       'Created right table');

    ok( $dbh->do("create table alpha (id integer primary key, beta_id integer REFERENCES beta(id))"),
        'Created table alpha');
    ok( $dbh->do("create table beta (id integer primary key, gamma_id integer REFERENCES gamma(id))"),
        'Created table beta');
    ok( $dbh->do("create table gamma (id integer primary key, type varchar)"),
        'Created table gamma');
    ok( $dbh->do("create table bridge (left_id integer REFERENCES left(id), right_id integer REFERENCES right(id), primary key (left_id,  right_id))"),
        'Created table bridge');


    my $ins_circular = $dbh->prepare("insert into circular (id, parent_id) values (?,?)");
    foreach my $row (  [1, 5], [2, 1], [3, 2], [4, 3], [5, 4]  ) {
        ok( $ins_circular->execute(@$row), 'Inserted into circular' );
    }
    $ins_circular->finish;

    my $ins_left = $dbh->prepare("insert into left (id, right_id, right_id2) values (?,?,?)");
    my $ins_right = $dbh->prepare("insert into right (id, left_id, left_id2) values (?,?,?)");
    foreach my $row ( ( [1,1,2], [2,2,3], [3,3,4], [4,4,5], [5,5,6]) ) {
        ok( $ins_left->execute(@$row), 'Inserted into left');
        ok( $ins_right->execute(@$row), 'Inserted into right');
    }
    
    
    my $ins_bridge_left = $dbh->prepare("insert into left(id) values (?)");
    $ins_bridge_left->execute(10);
    my $ins_bridge_right = $dbh->prepare("insert into right(id) values (?)");
    my $ins_bridge = $dbh->prepare("insert into bridge(left_id, right_id) values (?, ?)");
    for (11..15){
        $ins_bridge_right->execute($_);
        $ins_bridge->execute(10, $_);
    }
    $ins_bridge->finish;
    $ins_bridge_right->finish;
    $ins_bridge_left->finish;
    
    $ins_left->finish;
    $ins_right->finish;
    my $ins_alpha = $dbh->prepare("insert into alpha(id, beta_id) values(?,?)");
    ok($ins_alpha->execute(100,200), 'inserted into alpha');
    $ins_alpha->finish;
    my $ins_beta = $dbh->prepare("insert into beta(id, gamma_id) values(?,?)");
    ok($ins_beta->execute(200, 300), 'inserted into beta');
    $ins_beta->finish;
    my $ins_gamma = $dbh->prepare("insert into gamma(id, type) values(?,?)");
    ok($ins_gamma->execute(300, 'test'), 'inserted into gamma');
    $ins_gamma->finish;


    ok($dbh->commit(), 'DB commit');
           
 
    ok(UR::Object::Type->define(
        class_name => 'URT::Circular',
        id_by => [
            id => { is => 'Integer' },
        ],
        has_optional => [
            parent_id => { is => 'Integer'},
            parent => {is => 'URT::Circular', id_by => 'parent_id'}
        ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'circular',
    ), 'Defined URT::Circular class');
    ok(UR::Object::Type->define(
        class_name => 'URT::Left',
        id_by => [
            id => { is => 'Integer'}
        ],
        has_optional => [
            right_id => { is => 'Integer' },
            right => { is => 'URT::Right', id_by => 'right_id'},
        ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'left',
    ), 'Defined URT::Left class');
    ok(UR::Object::Type->define(
        class_name => 'URT::Right',
        id_by => [
            id => { is => 'Integer'}
        ],
        has_optional => [
            left_id => { is => 'Integer' },
            left => { is => 'URT::Left', id_by => 'left_id'},
        ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'right',
    ), 'Defined URT::Right class');
    ok(UR::Object::Type->define(
            class_name => 'URT::Alpha',
            id_by => [
                id => {is => 'Integer'}
            ],
            has_optional => [
                beta_id => { is => 'Integer' }, 
                beta => { is => 'URT::Beta', id_by => 'beta_id'},
            ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'alpha',
    ), 'Defined URT::Alpha class');
    ok(UR::Object::Type->define(
            class_name => 'URT::Beta',
            id_by => [
                id => {is => 'Integer'}
            ],
            has_optional => [
                gamma_id => { is => 'Integer' }, 
                gamma => { is => 'URT::Gamma', id_by => 'gamma_id'},
            ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'beta',
    ), 'Defined URT::Beta class');
    ok(UR::Object::Type->define(
            class_name => 'URT::Gamma',
            id_by => [
                id => {is => 'Integer'}
            ],
            has => [
                type => { is => 'Text' }, 
            ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'gamma',
    ), 'Defined URT::Alpha class');
    ok(UR::Object::Type->define(
            class_name => 'URT::Bridge',
            id_by => [
                left_id => {is => 'Integer'},
                right_id => {is => 'Integer'}
            ],
        data_source => 'URT::DataSource::CircFk',
        table_name => 'bridge',
    ), 'Defined URT::Bridge class');
}
