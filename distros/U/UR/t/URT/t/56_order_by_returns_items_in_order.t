#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 31;

# When a different ordering is requested, make sure a get() that hits
# the DB returns items in the same order as one that returns cached objects.
# It should be sorted first by the requested key, then by ID

&setup_classes_and_db();

my @o = URT::Thing->get('name like' => 'Bob%', -order => ['data']);

my @got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

my @expected = ( { id => 5, name => 'Bobs',   data => 'aaa' },
                 { id => 2, name => 'Bob',    data => 'abc' },
                 { id => 4, name => 'Bobby',  data => 'abc' },
                 { id => 6, name => 'Bobert', data => 'infinity' },
                 { id => 1, name => 'Bobert', data => 'zzz' },
                 { id => 0, name => 'Bobbb',  data => undef },
               );

is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Bob% ordered by data');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
@o = URT::Thing->get('name like' => 'Bob%', -order => ['data']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Bob% ordered by data from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));


# Now do descending

@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( { id => 10, name => 'Freddd',  data => undef },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 15, name => 'Freds',   data => 'aaa' },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));


# Try order by -id
$_->unload foreach @o;

@o = URT::Thing->get('name like' => 'Fred%', -order => ['-id']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 15, name => 'Freds',   data => 'aaa' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 10, name => 'Freddd',  data => undef },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by id DESC');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
@o = URT::Thing->get('name like' => 'Fred%', -order => ['-id']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by id DESC from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));


# Now, try multiple order bys
$_->unload foreach @o;

@o = URT::Thing->get('name like' => 'Fred%', -order => ['+data','name']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( 
              { id => 15, name => 'Freds',   data => 'aaa' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 10, name => 'Freddd',  data => undef },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data, name');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
@o = URT::Thing->get('name like' => 'Fred%', -order => ['data','name']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data,name from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));



# multiple, different order bys
$_->unload foreach @o;

@o = URT::Thing->get('name like' => 'Fred%', -order => ['data','-name']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( 
              { id => 15, name => 'Freds',   data => 'aaa' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 10, name => 'Freddd',  data => undef },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data, name DESC');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
$DB::single=1;
@o = URT::Thing->get('name like' => 'Fred%', -order => ['data','-name']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data, name DESC from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));


# different order bys in the other order
$_->unload foreach @o;

@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data','name']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( { id => 10, name => 'Freddd',  data => undef },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 15, name => 'Freds',   data => 'aaa' },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC, name');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
$DB::single=1;
@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data','name']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC, name from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));


# And now both descending
$_->unload foreach @o;

@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data','-name']);

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

@expected = ( { id => 10, name => 'Freddd',  data => undef },
              { id => 11, name => 'Fredert', data => 'zzz' },
              { id => 16, name => 'Fredert', data => 'infinity' },
              { id => 14, name => 'Freddy',  data => 'abc' },
              { id => 12, name => 'Fred',    data => 'abc' },
              { id => 15, name => 'Freds',   data => 'aaa' },
            );
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC, name DESC');

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
$DB::single=1;
@o = URT::Thing->get('name like' => 'Fred%', -order => ['-data','-name']);
is(scalar(@o), scalar(@expected), 'Got correct number of things with name like Fred% ordered by data DESC, name DESC from the cache');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));





# Remove the test DB
unlink(URT::DataSource::SomeSQLite->server);


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

    ok($dbh, 'got DB handle');

    ok($dbh->do('create table things (thing_id integer, name varchar, data varchar)'),
       'Created things table');

    my $insert = $dbh->prepare('insert into things (thing_id, name, data) values (?,?,?)');
    # Inserting them purposfully in non-ID order so they'll get returned in non-id
    # order if the ID column isn't included in the 'order by' clause
    foreach my $row ( ( 
                        [4, 'Bobby', 'abc'],
                        [2, 'Bob', 'abc'],
                        [0, 'Bobbb', undef],
                        [1, 'Bobert', 'zzz'],
                        [6, 'Bobert', 'infinity'],
                        [5, 'Bobs', 'aaa'],

                        [14, 'Freddy', 'abc'],
                        [12, 'Fred', 'abc'],
                        [10, 'Freddd', undef],
                        [11, 'Fredert', 'zzz'],
                        [16, 'Fredert', 'infinity'],
                        [15, 'Freds', 'aaa'],
                    )) {
        unless ($insert->execute(@$row)) {
            die "Couldn't insert a row into 'things': $DBI::errstr";
        }
    }

    $dbh->commit();

    # Now we need to fast-forward the sequence past 4, since that's the highest ID we inserted manually
    my $sequence = URT::DataSource::SomeSQLite->_get_sequence_name_for_table_and_column('things', 'thing_id');
    die "Couldn't determine sequence for table 'things' column 'thing_id'" unless ($sequence);

    my $id = -1;
    while($id <= 4) {
        $id = URT::DataSource::SomeSQLite->_get_next_value_from_sequence($sequence);
    }

    ok(UR::Object::Type->define(
           class_name => 'URT::Thing',
           id_by => 'thing_id',
           has => [
               'name' => { is => 'String' },
               'data' => { is => 'String', is_optional => 1 },
           ],
           data_source => 'URT::DataSource::SomeSQLite',
           table_name => 'things'),
       'Created class URT::Thing');

}
               

