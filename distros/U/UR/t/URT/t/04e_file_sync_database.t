#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

use IO::File;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use URT; # dummy namespace

# FIXME - this doesn't test the UR::DataSource::File internals like seeking and caching

my $ds = URT::DataSource::SomeFile->get();
ok($ds, 'Got SomeFile data source');

&setup($ds);


my $thing1 = URT::Things->get(thing_name => 'Fred');
ok($thing1, 'singular get() returned an object');
ok($thing1->thing_color('blueish'), 'Changed color');

my $thing2 = URT::Things->get(thing_name => 'Frank');
ok($thing2->thing_name('Anonymous'), 'Changed name on a different thing');

my $thing3 = URT::Things->get(thing_name => 'Joe');
ok($thing3->delete, 'Deleted a third thing');

my $new_thing1 = URT::Things->create(thing_id => 3, thing_name => 'Newby', thing_color=> 'clear');
ok($new_thing1, 'created new thing');
ok(!exists($new_thing1->{'db_committed'}), "New thing correctly has no 'db_committed' hash key");

my $new_thing2 = URT::Things->create(thing_id => 0, thing_name => 'Something', thing_color => 'white');
ok($new_thing2, 'created new thing 2');

my $new_thing3 = URT::Things->create(thing_id => 10, thing_name => 'Bobish', thing_color => 'redish');
ok($new_thing3, 'created new thing 3');

ok(UR::Context->commit, 'Commit');

&check_file($ds);

ok(exists($new_thing1->{'db_committed'}), "New thing 1 now has a 'db_committed' has key");

unlink $ds->server;


sub setup {
    my $ds = shift;
    my $filename = $ds->server;
    my $delimiter = $ds->delimiter;
    my $rs = $ds->record_separator;

    ok($filename, 'URT::DataSource::SomeFile has a server');
    unlink $filename if -f $filename;

    my @data = ( [ 1, 'Bob', 'blue' ],
                 [ 2, 'Fred', 'green' ],
                 [ 4, 'Joe', 'red' ],
                 [ 5, 'Frank', 'yellow' ],
               );

    my $fh = IO::File->new($filename, '>');
    ok($fh, 'opened file for writing');

    foreach my $line ( @data ) {
        $fh->print(join($delimiter, @$line),$rs);
    }
    $fh->close;

    my $c = UR::Object::Type->define(
        class_name => 'URT::Things',
        id_by => [
            thing_id => { is => 'Integer' },
        ],
        has => [
            thing_name => { is => 'String' },
            thing_color => { is => 'String' },
        ],
        table_name => 'FILE',
        data_source => 'URT::DataSource::SomeFile'
    );

    ok($c, 'Created class');
}

sub check_file {
    my $ds = shift;

    my $fh = IO::File->new($ds->server);
   
    my $line = $fh->getline();
    is($line, qq(0\tSomething\twhite\n), 'Line 0 ok');

    $line = $fh->getline();
    is($line, qq(1\tBob\tblue\n), 'Line 1 ok');

    $line = $fh->getline();
    is($line, qq(2\tFred\tblueish\n), 'Line 2 ok');

    $line = $fh->getline();
    is($line, qq(3\tNewby\tclear\n), 'Line 3 ok');

    $line = $fh->getline();
    is($line, qq(5\tAnonymous\tyellow\n), 'Line 4 ok');

    $line = $fh->getline();
    is($line, qq(10\tBobish\tredish\n), 'Line 5 ok');

}


1;
