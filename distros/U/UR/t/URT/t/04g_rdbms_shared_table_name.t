use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 7;
use URT::DataSource::SomeSQLite;
use File::Temp qw();

my $new_ds_file = generate_somesqlite_datasource('URT::DataSource::AnotherSQLite');
require $new_ds_file->filename;

my $table_name = 'thing';
my %class_of_ds = (
    'URT::DataSource::SomeSQLite' => 'SomeThing',
    'URT::DataSource::AnotherSQLite' => 'AnotherThing',
);

for my $ds (qw(URT::DataSource::SomeSQLite URT::DataSource::AnotherSQLite)) {
    my $dbh = $ds->get_default_handle();
    my $sql = qq(create table $table_name (id integer));
    ok($dbh->do($sql), "$ds: $sql");

    UR::Object::Type->define(
        class_name => $class_of_ds{$ds},
        id_by => 'id',
        data_source => $ds,
        table_name => $table_name,
    );
}

my @classes_for_table = grep { $_->class_name !~ /::Ghost$/ } UR::Object::Type->is_loaded(table_name => $table_name);
is(scalar(@classes_for_table), 2, 'got two classes for table');

for my $ds (qw(URT::DataSource::SomeSQLite URT::DataSource::AnotherSQLite)) {
    my $class_name = $ds->_lookup_class_for_table_name($table_name);
    is($class_name, $class_of_ds{$ds}, qq(class for '$table_name' on $ds is correct));
}

for my $class (values %class_of_ds) {
    $class->create(id => 1) or die;
}
UR::Context->commit;

for my $ds (qw(URT::DataSource::SomeSQLite URT::DataSource::AnotherSQLite)) {
    my $dbh = $ds->get_default_handle();
    my $sth = $dbh->prepare(qq(select * from $table_name));
    $sth->execute();
    my $r = $sth->fetchall_arrayref();
    is_deeply($r, [[1]], qq($ds: got expected row));
}

sub generate_somesqlite_datasource {
    my $ds_class_name = shift;

    my $orig_path = $INC{'URT/DataSource/SomeSQLite.pm'};
    my $orig_file = IO::File->new($orig_path, 'r');
    local ($/);
    my $orig_source = <$orig_file>;

    $orig_source =~ s/URT::DataSource::SomeSQLite/$ds_class_name/g;

    my $new_file = File::Temp->new(TMPDIR => 1);
    $new_file->print($orig_source);
    $new_file->close();

    return $new_file;
}

