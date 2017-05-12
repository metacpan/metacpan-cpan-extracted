BEGIN {
    # This test requires committing to be enabled
    delete $ENV{UR_DBI_NO_COMMIT};
}
use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 91;
use URT::DataSource::SomeSQLite;
use File::Temp;
use File::Spec;

# Make a few couple classes attached to a data source.  Load some of the objects.
# The data should be copied to the test database

fill_primary_db();
setup_classes();

foreach my $no_commit ( 0, 1 ) {
    diag("no_commit $no_commit");
    UR::DBI->no_commit($no_commit);

    diag('sqlite file');
    my $db_file = load_objects_fill_file();
    test_results_db_file($db_file);

    diag('sqlite directory');
    my $db_dir = load_objects_fill_dir();
    test_results_db_dir($db_dir);
}

sub fill_primary_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    $dbh->do('PRAGMA foreign_keys = ON');

    # "simple" is a basic table, no inheritance or hangoffs
    ok($dbh->do('create table simple (simple_id integer NOT NULL PRIMARY KEY, name varchar)'),
        'create table simple');
    my $sth = $dbh->prepare('insert into simple (simple_id, name) values (?,?)') || die "prepare simple: $DBI::errstr";
    foreach my $row ( [1, 'use'], [2, 'ignore'] ) {
        $sth->execute(@$row) || die "execute simple: $DBI::errstr";
    }
    $sth->finish;

    # "parent" and "child" tables with inheritance
    ok($dbh->do('create table parent (parent_id integer NOT NULL PRIMARY KEY, name varchar)'),
        'create table parent');
    ok($dbh->do('create table child (child_id integer NOT NULL PRIMARY KEY REFERENCES parent(parent_id), data varchar)'),
        'create table child');
    $sth = $dbh->prepare('insert into parent (parent_id, name) values (?,?)') || die "prepare parent: $DBI::errstr";
    foreach my $row ( [1, 'use'], [2, 'ignore']) {
        $sth->execute(@$row) || die "execute parent: $DBI::errstr";
    }
    $sth->finish;

    $sth = $dbh->prepare('insert into child (child_id, data) values (?,?)') || die "prepare child: $DBI::errstr";
    foreach my $row ( [1, 'child data 1'], [2, 'child data 2'] ) {
        $sth->execute(@$row) || die "execute child: $DBI::errstr";
    }
    $sth->finish;


    # "obj" and "hangoff" tables
    ok($dbh->do('create table obj (obj_id integer NOT NULL PRIMARY KEY, name varchar)'),
        'create table obj');
    ok($dbh->do('create table hangoff (hangoff_id integer NOT NULL PRIMARY KEY, value varchar, obj_id integer REFERENCES obj(obj_id))'),
        'create table hangoff');
    $sth = $dbh->prepare('insert into obj (obj_id, name) values (?,?)') || die "prepare obj: $DBI::errstr";
    foreach my $row ( [1, 'use'], [2, 'ignore'], [3, 'keep'] ) {
        $sth->execute(@$row) || die "execute hangoff: $DBI::errstr";
    }
    $sth->finish;

    $sth = $dbh->prepare('insert into hangoff (hangoff_id, value, obj_id) values (?,?,?)') || die "prepare hangoff: $DBI::errstr";
    foreach my $row ( [1, 'use', 1], [2, 'ignore', 2], [3, 'keep', 3] ) {
        $sth->execute(@$row) || die "execute obj: $DBI::errstr";
    }
    $sth->finish;


    # data and data_attribute tables
    ok($dbh->do('create table data (data_id integer NOT NULL PRIMARY KEY, name varchar)'),
        'create table data');
    ok($dbh->do('create table data_attribute (data_id integer, name varchar, value varchar, PRIMARY KEY (data_id, name, value))'),
        'create table data_attribute');
    $sth = $dbh->prepare('insert into data (data_id, name) values (?,?)') || die "prepare data: $DBI::errstr";
    foreach my $row ( [ 1, 'use'], [2, 'ignore'], [3, 'use'] ) {
        $sth->execute(@$row) || die "execute data: $DBI::errstr";
    }
    $sth->finish;

    $sth = $dbh->prepare('insert into data_attribute (data_id, name, value) values (?,?,?)') || die "prepare data_attribute: $DBI::errstr";
    # data_id 3 has no data_attributes
    foreach my $row ( [1, 'coolness', 'high'], [1, 'foo', 'bar'], [2, 'coolness', 'low']) {
        $sth->execute(@$row) || die "execute data_attribute: $DBI::errstr";
    }
    $sth->finish;


    # a table that references itself
    ok($dbh->do('create table self_reference (sr_id integer NOT NULL PRIMARY KEY, prev_id integer REFERENCES self_reference(sr_id), name varchar)'),
        'create table self_reference');
    $sth = $dbh->prepare('insert into self_reference (sr_id, prev_id, name) values (?,?,?)');
    foreach my $row ( [1, undef, 'use parent'], [2, 1, 'use'], [3, undef, 'ignore parent'], [4, 3, 'ignore']) {
        $sth->execute(@$row) || die "execute self_reference: $DBI::errstr";
    }

    # Entities and relationships
    ok($dbh->do('create table entity (entity_id integer NOT NULL PRIMARY KEY, name VARCHAR)'),
        'create entity table');
    ok($dbh->do('create table relationship (from_entity_id integer NOT NULL REFERENCES entity(entity_id), to_entity_id integer NOT NULL REFERENCES entity(entity_id), label varchar, PRIMARY KEY (from_entity_id, to_entity_id))'),
        'create entity relationship table');
    $sth = $dbh->prepare('insert into entity (entity_id, name) values (?,?)');
    foreach my $row ( [1, 'use parent'], [2, 'ignore parent'], [3, 'use child'], [4, 'ignore child'] ) {
        $sth->execute(@$row) || die "execute entity insert: $DBI::errstr";
    }
    $sth = $dbh->prepare('insert into relationship (from_entity_id, to_entity_id, label) values (?,?,?)');
    foreach my $row ( [1,3,'use'], [2,4,'ignore']) {
        $sth->execute(@$row) || die "execute relationship insert: $DBI::errstr";
    }

    # subclassable hangoff data
    ok($dbh->do('create table obj_with_subclassable_hangoff (obj_id integer NOT NULL PRIMARY KEY, name varchar)'),
        'create table obj_with_subclassable_hangoff');
    ok($dbh->do('create table subclassable_hangoff (hangoff_id integer NOT NULL PRIMARY KEY, value varchar, obj_id integer REFERENCES obj(obj_id), subclass_name varchar NOT NULL)'),
        'create table subclassable_hangoff');
    $sth = $dbh->prepare('insert into obj_with_subclassable_hangoff (obj_id, name) values (?,?)') || die "prepare obj_with_subclassable_hangoff: $DBI::errstr";
    foreach my $row ( [1, 'use'], [2, 'ignore'], [3, 'keep'] ) {
        $sth->execute(@$row) || die "execute hangoff: $DBI::errstr";
    }
    $sth->finish;

    $sth = $dbh->prepare('insert into subclassable_hangoff (hangoff_id, value, obj_id, subclass_name) values (?,?,?,?)') || die "prepare subclassable_hangoff: $DBI::errstr";
    foreach my $row ( [1, 'use', 1, 'URT::SubclassedHangoff'], [2, 'ignore', 2, 'URT::SubclassedHangoff'], [3, 'keep', 3, 'URT::SubclassedHangoff'] ) {
        $sth->execute(@$row) || die "execute obj: $DBI::errstr";
    }
    $sth->finish;

    ok($dbh->commit(), 'Commit initial database state');
}

sub setup_classes {
    UR::Object::Type->define(
        class_name => 'URT::Simple',
        id_by => 'simple_id',
        has => ['name'],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'simple',
    );

    UR::Object::Type->define(
        class_name => 'URT::Parent',
        id_by => 'parent_id',
        has => ['name'],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'parent',
    );

    UR::Object::Type->define(
        class_name => 'URT::Child',
        is => 'URT::Parent',
        id_by => 'child_id',
        has => ['data'],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'child',
    );

    UR::Object::Type->define(
        class_name => 'URT::Obj',
        id_by => 'obj_id',
        has => [
            name => { is => 'String' },
            hangoff => { is => 'URT::Hangoff', reverse_as => 'obj', is_many => 1 },
            hangoff_value => { via => 'hangoff', to => 'value' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'obj',
    );

    UR::Object::Type->define(
        class_name => 'URT::Hangoff',
        id_by => 'hangoff_id',
        has => [
            value => { is => 'String' },
            obj => { is => 'URT::Obj', id_by => 'obj_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'hangoff',
    );


    UR::Object::Type->define(
        class_name => 'URT::Data',
        id_by => 'data_id',
        has => [
            name => { is => 'String' },
            attributes => { is => 'URT::DataAttribute', reverse_as => 'data', is_many => 1 },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'data',
    );

    UR::Object::Type->define(
        class_name => 'URT::DataAttribute',
        id_by => ['data_id', 'name', 'value' ],
        has => [
            data => { is => 'URT::Data', id_by => 'data_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'data_attribute',
    );

    UR::Object::Type->define(
        class_name => 'URT::SelfReferencing',
        id_by => 'sr_id',
        has => [
            prev => { is => 'URT::SelfReferencing', id_by => 'prev_id', is_optional => 1 },
            name => { is => 'String' },
        ],
        data_source  => 'URT::DataSource::SomeSQLite',
        table_name => 'self_reference',
    );

    UR::Object::Type->define(
        class_name => 'URT::Entity',
        id_by => 'entity_id',
        has => [
            name => { is => 'String' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'entity',
    );

    UR::Object::Type->define(
        class_name => 'URT::Relationship',
        id_by => ['from_entity_id','to_entity_id'],
        has => [
            label => { is => 'String' },
            from_entity => { is => 'URT::Entity', id_by => 'from_entity_id' },
            to_entity => { is => 'URT::Entity', id_by => 'to_entity_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'relationship',
    );

    UR::Object::Type->define(
        class_name => 'URT::ObjWithSubclassedHangoff',
        id_by => 'obj_id',
        has => [
            name => { is => 'String' },
            hangoff => { is => 'URT::SubclassedHangoff', reverse_as => 'obj', is_many => 1 },
            hangoff_value => { via => 'hangoff', to => 'value' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'obj_with_subclassable_hangoff',
    );

    UR::Object::Type->define(
        class_name => 'URT::SubclassableHangoff',
        is_abstract => 1,
        subclassify_by => 'subclass_name',
        id_by => 'hangoff_id',
        has => [
            value => { is => 'String' },
            obj => { is => 'URT::ObjWithSubclassedHangoff', id_by => 'obj_id' },
            subclass_name => { is => 'String' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'subclassable_hangoff',
    );

    UR::Object::Type->define(
        class_name => 'URT::SubclassedHangoff',
        is => 'URT::SubclassableHangoff',
    );
}


sub load_objects_fill_file {
    my $temp_db_file = File::Temp->new();
    $temp_db_file->close();
    URT::DataSource::SomeSQLite->alternate_db_dsn('dbi:SQLite:dbname='.$temp_db_file->filename);
    _load_objects();
    URT::DataSource::SomeSQLite->alternate_db_dsn('');
    return $temp_db_file;
}

sub _load_objects {
    ok(scalar(URT::Simple->get(name => 'use')), 'Get simple object');

    ok(scalar(URT::Child->get(name => 'use')), 'Get child object');

    my @got = URT::Obj->get(hangoff_value => 'use');
    ok(scalar(@got), 'Get obj with hangoff');

    ok(scalar(URT::Hangoff->get(value => 'keep')), 'Get hangoff data directly');

    @got = URT::Data->get(name => 'use', -hints => 'attributes');
    ok(scalar(@got), 'Get data and and data attributes');

    ok(scalar(URT::SelfReferencing->get(name => 'use')), 'Get object via self-referencing table');

    ok(scalar(URT::Relationship->get(label => 'use')), 'Get relationship with two PKs');

    @got = URT::ObjWithSubclassedHangoff->get(hangoff_value => 'use');
    ok(scalar(@got), 'Get obj with subclassed hangoff');

    # The Obj is a prerequisite of the Hangoff.  Create the Obj with a dummy ID, which won't
    # be inserted to the alternate DB, which means the Hangoff can't be inserted either.
    eval {
        UR::DBI->no_commit(1);
        my $obj = URT::Obj->create(id => 999, name => 'use');
        ok($obj, 'Create URT::Obj with dummy IDs on');

        my $hangoff = URT::Hangoff->create(value => 'use', obj => $obj, id => $$);

        UR::Context->commit();
        UR::Context->current->reload('URT::Obj', hangoff_value => 'use');
        UR::Context->rollback;
        $obj->delete;  # need delete because no-commit is on inside here
    };
    UR::DBI->no_commit(0);

    $_->unload() foreach ( qw( URT::Simple
                                URT::Child URT::Obj URT::Hangoff
                                URT::Data URT::DataAttribute
                                URT::SelfReferencing
                                URT::Entity URT::Relationship
                                URT::ObjWithSubclassedHangoff URT::SubclassableHangoff ) );
}

sub test_results_db_file {
    my $db_file = shift;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file",'','');
    $dbh->{FetchHashKeyName} = 'NAME_lc';

    my $simple = $dbh->selectall_hashref('select * from simple', 'simple_id');
    is_deeply($simple,
                { 1 => { simple_id => 1, name => 'use' } },
                'simple table created with correct column names');

    my $parent = $dbh->selectall_hashref('select * from parent', 'parent_id');
    is_deeply($parent,
        { 1 => { parent_id => 1, name => 'use' } },
        'table parent');

    my $child = $dbh->selectall_hashref('select * from child', 'child_id');
    is_deeply($child,
        { 1 => { child_id => 1, data => 'child data 1' } },
        'table child');

    my $obj = $dbh->selectall_hashref('select * from obj', 'obj_id');
    is_deeply($obj,
        { 1 => { obj_id => 1, name => 'use' },
          3 => { obj_id => 3, name => 'keep' },
         },
        'table obj');

    my $hangoff = $dbh->selectall_hashref('select * from hangoff', 'hangoff_id');
    is_deeply($hangoff,
        {
          1 => { hangoff_id => 1, obj_id => 1, value => 'use' },
          3 => { hangoff_id => 3, obj_id => 3, value => 'keep'},
         },
        'table hangoff');

    my $data = $dbh->selectall_hashref('select * from data', 'data_id');
    is_deeply($data,
        { 1 => { data_id => 1, name => 'use' },
          3 => { data_id => 3, name => 'use' },
        },
        'table data');

    my $data_attribute = $dbh->selectall_hashref('select * from data_attribute', 'name');
    is_deeply($data_attribute,
        { coolness  => { data_id => 1, name => 'coolness', value => 'high' },
          foo       => { data_id => 1, name => 'foo', value => 'bar' }
        },
        'table data_attribute'
    );

    my $self_referencing = $dbh->selectall_hashref('select * from self_reference', 'name');
    is_deeply($self_referencing,
        { 'use parent' => { sr_id => 1, prev_id => undef, name => 'use parent' },
          use => { sr_id => 2, prev_id => 1, name => 'use' },
        },
        'table self_referencing');

    my $entities = $dbh->selectall_hashref('select * from entity', 'entity_id');
    is_deeply($entities,
        { 1 => { entity_id => 1, name => 'use parent' },
          3 => { entity_id => 3, name => 'use child' },
        },
        'table entity',
    );

    my $relationships = $dbh->selectall_hashref('select * from relationship', 'from_entity_id');
    is_deeply($relationships,
        { 1 => { from_entity_id => 1, to_entity_id => 3, label => 'use'} },
        'table relationship',
    );
}

sub load_objects_fill_dir {
    my $temp_db_dir = File::Temp::tempdir( CLEANUP => 1 );
    URT::DataSource::SomeSQLite->alternate_db_dsn('dbi:SQLite:dbname='.$temp_db_dir);
    _load_objects();
    URT::DataSource::SomeSQLite->alternate_db_dsn('');
    return $temp_db_dir;
}

sub test_results_db_dir {
    my $temp_db_dir = shift;
    my $main_schema_file = File::Spec->catfile($temp_db_dir, 'main.sqlite3');
    ok(-f $main_schema_file, 'main schema file main.sqlite3');
    test_results_db_file($main_schema_file);
}
