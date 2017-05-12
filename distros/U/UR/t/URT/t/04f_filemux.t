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

&setup_files_and_classes();

my $obj = URT::Thing->get(thing_id => 1, thing_type => 'person');
ok($obj, 'Got a person thing with id 1');
is($obj->thing_name, 'Joel', 'Name is correct');
is($obj->thing_color, 'grey', 'Color is correct');
is($obj->thing_type, 'person', 'type is correct');

$obj = URT::Thing->get(thing_id => 6, thing_type => 'robot');
ok($obj, 'Got a robot thing with id 5');
is($obj->thing_name, 'Tom', 'Name is correct');
is($obj->thing_color, 'red', 'Color is correct');

$obj = URT::Thing->get(thing_id => 3, thing_type => 'person');
ok(!$obj, 'Correctly found no person thing with id 3');


my @objs = URT::Thing->get(thing_type => ['person','robot'], thing_id => 7);
is(scalar(@objs),1, 'retrieved a thing with id 7 that is either a person or robot');
is($objs[0]->thing_id, 7, 'The retrieved thing has the right id');
is($objs[0]->thing_type, 'robot', 'The retrieved thing is a robot');
is($objs[0]->thing_name, 'Gypsy', 'Name is correct');
is($objs[0]->thing_color, 'purple', 'Color is correct');



my $filemux_error_message;
URT::DataSource::SomeFileMux->error_messages_callback(sub { $filemux_error_message = $_[1]; $_[1] = undef });

$obj = eval { URT::Thing->get(thing_id => 2) };
ok(!$obj, "Correctly couldn't retrieve a Thing without a thing_type");
like($filemux_error_message, qr(Recursive entry.*URT::Thing), 'Error message did mention recursive call trapped');

my $iter = URT::Thing->create_iterator(thing_type => ['person', 'robot']);
ok($iter, 'Created an iterator for all Things');
my $expected_id = 1;
while (my $obj = $iter->next()) {
    ok($obj, 'Got an object from the iterator');
    is($obj->id, $expected_id++, 'Its ID was the expected value');
}


# Try the object pruner to unload the File data sources
my @file_data_sources = UR::DataSource::File->is_loaded();
is(scalar(@file_data_sources), 2, 'Two file data sources were defined');
@file_data_sources = ();
do {
    my @warnings = ();
    local $SIG{'__WARN__'} = sub { push @warnings, @_ };
    UR::Context->object_cache_size_lowwater(1);
    UR::Context->object_cache_size_highwater(2);
    @warnings = grep { $_ !~ m/After several passes of pruning the object cache, there are still \d+ objects/ } @warnings;
    is(scalar(@warnings), 0, 'No unexpected warnings from pruning')
        || diag("Warning messages: ",join("\n", @warnings));
};

UR::Context->object_cache_size_lowwater(undef);
UR::Context->object_cache_size_highwater(undef);
@file_data_sources = UR::DataSource::File->is_loaded();
is(scalar(@file_data_sources), 0, 'After cache pruning, no file data sources are defined');
if (@file_data_sources) {
    foreach (@file_data_sources) {
        print STDERR Data::Dumper::Dumper($_);
    }
}

# try getting something again, should re-create the data source object
$obj = UR::Context->current->reload('URT::Thing', thing_type => 'person', thing_id => 1);
ok($obj, 'Reloading URT::Thing id 3');
@file_data_sources = UR::DataSource::File->is_loaded();
is(scalar(@file_data_sources), 1, 'The File data source was re-created');





sub setup_files_and_classes {
    my $dir = $URT::DataSource::SomeFileMux::BASE_PATH;
    my $delimiter = URT::DataSource::SomeFileMux->delimiter;

    my $file = "$dir/person";
    my $f = IO::File->new(">$file") || die "Can't open $file for writing: $!";
    $f->print(join($delimiter, qw(1 Joel grey)),"\n");
    $f->print(join($delimiter, qw(2 Mike blue)),"\n");
    $f->print(join($delimiter, qw(4 Frank black)),"\n");
    $f->print(join($delimiter, qw(5 Clayton green)),"\n");

    $f->close();

    $file = "$dir/robot";
    $f = IO::File->new(">$file") || die "Can't open $file for writing: $!";
    $f->print(join($delimiter, qw(3 Crow gold)),"\n");
    $f->print(join($delimiter, qw(6 Tom red)),"\n");
    $f->print(join($delimiter, qw(7 Gypsy purple)),"\n");
    $f->close();

    my $c = UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => [
            thing_id => { is => 'Integer' },
        ],
        has => [
            thing_name => { is => 'String' },
            thing_color => { is => 'String' },
            thing_type => { is => 'String', valid_values => ['person', 'robot'] },
        ],
        table_name => 'wefwef',
        data_source => 'URT::DataSource::SomeFileMux',
    );

    ok($c, 'Created class');
}


