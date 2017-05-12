use strict;
use warnings;
use Test::More tests=> 41;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

# Make a tree structure of data:
#         A
#      B    C
#    D  E
#
#  Another node Z that's not connected to the other tree

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table node
            ( node_id varchar not null primary key, parent_node_id varchar )'),
   'created node table');

my $sth = $dbh->prepare('insert into node values (?,?)');
foreach my $data ( ['A', undef],
                   ['B', 'A'],
                   ['C', 'A'],
                   ['D', 'B'],
                   ['E', 'B'],
                   ['Z', undef ] ) {
    ok($sth->execute(@$data), 'Insert a row');
}

UR::Object::Type->define(
    class_name => 'URT::Node',
    id_by => 'node_id',
    has => [
        parent_node_id => { is => 'Text' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'node',
);

my @n;

foreach ( 0 .. 1 ) {
    # first time through, no objects are loaded so it'll hit the DB
    # second time, everything should be in the object cache with results handled
    # by Indexes

    # Retrieve the tree rooted at B
    @n = URT::Node->get(id => 'B', -recurse => [ parent_node_id => 'node_id' ] );
    is(scalar(@n), 3, 'Three nodes rooted at B');
    is_deeply([ sort map { $_->id } @n],
              ['B','D','E'],
              'Nodes were correct');

    # Retrieve the tree rooted at A
    @n = URT::Node->get(id => 'A', -recurse => [ parent_node_id => 'node_id' ] );
    is(scalar(@n), 5, 'Five nodes rooted at A');
    is_deeply([ sort map { $_->id } @n],
              ['A','B','C','D','E'],
              'Nodes were correct');

    # Retrieve the tree rooted at Z
    @n = URT::Node->get(id => 'Z', -recurse => [ parent_node_id => 'node_id' ] );
    is(scalar(@n), 1, 'One node rooted at Z');
    is_deeply([ sort map { $_->id } @n],
              ['Z'],
              'Nodes were correct');

    # Retrieve the tree rooted at Q
    @n = URT::Node->get(id => 'Q', -recurse => [ parent_node_id => 'node_id' ] );
    is(scalar(@n), 0, 'No nodes with id Q');
}


for ( 0 .. 1 ) {
    # first time through, unload everything.
    # second time, everything should be in the object cache with results handled
    # by Indexes
    if (! $_) {
        ok(URT::Node->unload(), 'Unload all URT::Node objects');
    }

    # Retrieve the path from E to the root
    @n = URT::Node->get(id => 'E', -recurse => [node_id => 'parent_node_id'] );
    is(scalar(@n), 3, 'Three nodes from E to the root');
    is_deeply([ sort map { $_->id } @n],
              ['A','B','E'],
              'Nodes were correct');

    # Retrieve the path from C to the root
    @n = URT::Node->get(id => 'C', -recurse => [node_id => 'parent_node_id'] );
    is(scalar(@n), 2, 'Three nodes from C to the root');
    is_deeply([ sort map { $_->id } @n],
              ['A','C'],
              'Nodes were correct');

    # Retrieve the path from A to the root
    @n = URT::Node->get(id => 'A', -recurse => [node_id => 'parent_node_id'] );
    is(scalar(@n), 1, 'One node from A to the root');
    is_deeply([ sort map { $_->id } @n],
              ['A'],
              'Nodes were correct');

    # Retrieve the path from Z to the root
    @n = URT::Node->get(id => 'Z', -recurse => [node_id => 'parent_node_id'] );
    is(scalar(@n), 1, 'One node from Z to the root');
    is_deeply([ sort map { $_->id } @n],
              ['Z'],
              'Nodes were correct');

    # Retrieve the path from Q to the root
    @n = URT::Node->get(id => 'Q', -recurse => [node_id => 'parent_node_id'] );
    is(scalar(@n), 0, 'No nodes from Q to the root');
}


