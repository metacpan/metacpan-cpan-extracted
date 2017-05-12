use strict;
use warnings;
use Test::More tests => 17;
use DBD::SQLite;

print $DBD::SQLite::VERSION,"\n";
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

use File::Temp;
use URT::DataSource::SomeSQLite;

# This tests a case where there are two tables, one in the default schema and one in
# an attached schema, and there is a foreign key between the two tables requiring
# UR::DataSource::RDBMS::_sync_database to process it as a prerequsite.  There was a bug 
# that could cause data to get dropped on the floor in this case (fixed in commit da174c) 

our($tmp_file1, $tmp_file2);
$tmp_file1 = File::Temp::tmpnam() . "_ur_testsuite_83_db1.sqlite3";
$tmp_file2 = File::Temp::tmpnam() . "_ur_testsuite_83_db2.sqlite3";
END {
    unlink $tmp_file1 if defined $tmp_file1;
    unlink $tmp_file2 if defined $tmp_file2;
}

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

# A sqlite-ism way of pretending we have different schemas
my $autocommit = $dbh->{'AutoCommit'};
$dbh->{'AutoCommit'} = 1;
# I'd rather use memory DBs, but SQLite segfaults in commit() below
ok($dbh->do("attach database '$tmp_file1' as PROD_DB"), 'defined PROD_DB schema');
ok($dbh->do("attach database '$tmp_file2' as PEOPLE"), 'defined PEOPLE schema');
$dbh->{'AutoCommit'} = $autocommit;

ok($dbh->do('create table PEOPLE.PEOPLE
            ( person_id int NOT NULL PRIMARY KEY, name varchar )'),
   'created product table');
ok($dbh->do('create table PROD_DB.PRODUCT
            ( product_prod_id int NOT NULL PRIMARY KEY, product_name varchar, creator_id integer references PEOPLE(person_id))'),
   'created product table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PEOPLE.PEOPLE',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for product creator');


ok(UR::Object::Type->define(
        class_name => 'URT::Product',
        table_name => 'PRODUCT',
        id_by => [
            prod_id =>           { is => 'NUMBER', sql => 'product_prod_id' },
        ],
        has => [
            name =>              { is => 'STRING', sql => 'product_name' },
            creator           => { is => 'URT::Person', id_by => 'creator_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Product");

$dbh->commit();

# SQLite doesn't really do foreign key constraints, and really doesn't do them
# between databases, so insert some metaDB info about a foreign key between
# the product's creator and a person's ID
sub URT::DataSource::SomeSQLite::owner { 'PROD_DB'; } # the default schema/owner
sub URT::DataSource::SomeSQLite::get_foreign_key_details_from_data_dictionary {
my $self = shift;

    my($fk_catalog,$fk_schema,$fk_table,$pk_catalog,$pk_schema,$pk_table) = @_;
    unless ($fk_table eq 'PRODUCT' or $pk_table eq 'PEOPLE') {
        return UR::DataSource::SQLite::get_foreign_key_details_from_data_dictionary($self,@_);
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my @returned_names = qw( FK_NAME UK_TABLE_NAME UK_COLUMN_NAME UK_TABLE_SCHEM FK_TABLE_NAME FK_COLUMN_NAME FK_TABLE_SCHEM );
    my $table = $pk_table || $fk_table;
    my @ret_data = ( { FK_NAME => 'product_person_fk',
                       UK_TABLE_SCHEM => 'PEOPLE',
                       UK_TABLE_NAME => 'PEOPLE',
                       UK_COLUMN_NAME => 'person_id',
                       FK_TABLE_SCHEM => 'PROD_DB',
                       FK_TABLE_NAME => 'PRODUCT',
                       FK_COLUMN_NAME => 'creator_id' } );
    my $returned_sth = $sponge->prepare("foreign_key_info $table", {
        rows => [ map { [ @{$_}{@returned_names} ] } @ret_data ],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());
    return $returned_sth;
}

my $person = URT::Person->create(person_id => 1, name => 'Bob');
ok($person, 'Created a person');
my $product = URT::Product->create(prod_id => 1, name => 'Jet Pack', creator => $person);
ok($product, 'Created a product created by that person');

ok(UR::Context->commit, 'Commit');

my $data = $dbh->selectrow_hashref('select * from PROD_DB.PRODUCT where product_prod_id = 1');
ok($data, 'Got back data from the DB for the product');
is($data->{'product_prod_id'}, 1, 'product_id ok');
is($data->{'product_name'}, 'Jet Pack', 'name ok');
is($data->{'creator_id'}, 1, 'creator_id ok');

$data = $dbh->selectrow_hashref('select * from PEOPLE.PEOPLE where person_id = 1');
ok($data, 'Got back data from the DB for the creator');
is($data->{'person_id'}, 1, 'person_id ok');
is($data->{'name'}, 'Bob', 'name ok');


