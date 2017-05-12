#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 36;

use IO::File;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace
use URT::DataSource::SomeFileMux;

my $ds = URT::DataSource::SomeFileMux->get();
ok($ds, 'got the datasource object');

&setup_files_and_classes($ds);

my $thing1 = URT::Thing->get(thing_id => 1, thing_type => 'person');
ok($thing1, 'got an object');
ok($thing1->thing_color('changed'), 'Changed its color');

my $thing2 = URT::Thing->get(thing_id => 10, thing_type => 'robot');
ok($thing2, 'Got another object');
ok($thing2->thing_name('TomTom'), 'Changed its name');


my $thing3 = URT::Thing->get(thing_id => 2, thing_type => 'person');
ok($thing3, 'Got a third thing');
ok($thing3->delete, 'Deleted it');

my $new1 = URT::Thing->create(thing_id => 3, thing_name => 'Shaggy', thing_color => 'green', thing_type => 'person');
ok($new1, 'Created a new thing');

my $new2 = URT::Thing->create(thing_id => 9, thing_name => 'Fred', thing_color => 'white', thing_type => 'person');
ok($new2, 'Created a new thing 2');

my $new3 = URT::Thing->create(thing_id => 0, thing_name => 'Velma', thing_color => 'red', thing_type => 'person');
ok($new3, 'Created a new thing 3');

my $new4 = URT::Thing->create(thing_id => 11, thing_name => 'Robbie', thing_color => 'black', thing_type => 'robot');
ok($new4, 'Created a new thing 4');

my $new5 = URT::Thing->create(thing_id => 20, thing_name => 'Scooby', thing_color => 'brown', thing_type => 'animal');
ok($new5, 'Created a new thing 5');

ok(UR::Context->commit(), 'Commit');

&check_files($ds);

foreach my $obj ( $new1, $new2, $new3, $new4, $new5 ) {
    ok(exists($obj->{'db_committed'}), "New object now has a 'db_committed' hash key")
}


sub check_files {
    my $ds = shift;

    my $dir = $URT::DataSource::SomeFileMux::BASE_PATH;

    my $f = IO::File->new("$dir/person");
    ok($f, 'Opened file for person data');
    
    my $line = $f->getline();
    is($line, qq(0\tVelma\tred\n), 'Line 0');
    
    $line = $f->getline();
    is($line, qq(1\tJoel\tchanged\n), 'Line 1');

    $line = $f->getline();
    is($line, qq(3\tShaggy\tgreen\n), 'Line 2');

    $line = $f->getline();
    is($line, qq(4\tFrank\tblack\n), 'Line 3');

    $line = $f->getline();
    is($line, qq(5\tClayton\tgreen\n), 'Line 4');

    $line = $f->getline();
    is($line, qq(9\tFred\twhite\n), 'Line 5');

    $line = $f->getline();
    is($line, undef, 'end of file');

    $f->close();

    $f = IO::File->new("$dir/robot");
    ok($f, 'Opened file for robot data');

    $line = $f->getline();
    is($line, qq(8\tCrow\tgold\n), 'Line 0');

    $line = $f->getline();
    is($line, qq(10\tTomTom\tred\n), 'Line 1');

    $line = $f->getline();
    is($line, qq(11\tRobbie\tblack\n), 'Line 3');

    $line = $f->getline();
    is($line, qq(12\tGypsy\tpurple\n), 'Line 2');

    $line = $f->getline();
    is($line, undef, 'end of file');

    $f->close();

    $f = IO::File->new("$dir/animal");
    ok($f, 'Opened file for animal data');

    $line = $f->getline();
    is($line, qq(20\tScooby\tbrown\n), 'Line 0');

    $line = $f->getline();
    is($line, undef, 'end of file');
    $f->close();

    unlink("$dir/person", "$dir/robot", "$dir/animal");
}

    

sub setup_files_and_classes {
    my $ds = shift;

    my $dir = $URT::DataSource::SomeFileMux::BASE_PATH;
    my $delimiter = $ds->delimiter;

    unlink("$dir/person", "$dir/robot", "$dir/animal");

    my $file = "$dir/person";
    my $f = IO::File->new(">$file") || die "Can't open $file for writing: $!";
    $f->print(join($delimiter, qw(1 Joel grey)),"\n");
    $f->print(join($delimiter, qw(2 Mike blue)),"\n");
    $f->print(join($delimiter, qw(4 Frank black)),"\n");
    $f->print(join($delimiter, qw(5 Clayton green)),"\n");

    $f->close();

    $file = "$dir/robot";
    $f = IO::File->new(">$file") || die "Can't open $file for writing: $!";
    $f->print(join($delimiter, qw(8 Crow gold)),"\n");
    $f->print(join($delimiter, qw(10 Tom red)),"\n");
    $f->print(join($delimiter, qw(12 Gypsy purple)),"\n");
    $f->close();

    my $c = UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => [
            thing_id => { is => 'Integer' },
        ],
        has => [
            thing_name => { is => 'String' },
            thing_color => { is => 'String' },
            thing_type => { is => 'String' },
        ],
        table_name => 'wefwef',
        data_source => 'URT::DataSource::SomeFileMux',
    );

    ok($c, 'Created class');
}


