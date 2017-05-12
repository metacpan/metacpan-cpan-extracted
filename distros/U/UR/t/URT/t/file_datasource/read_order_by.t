#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 83;

use IO::File;
use File::Temp;


# File data: id name score color
my @data = (
            [1, 'one',   10,'red'],
            [2, 'two',   10,'green'],
            [3, 'three', 9, 'blue'],
            [4, 'four',  9, 'black'],
            [5, 'five',  8, 'yellow'],
            [6, 'six',   8, 'white'],
            [7, 'seven', 7, 'purple'],
            [8, 'eight', 7, 'orange'],
            [9, 'nine',  6, 'pink'],
            [10, 'ten',  6, 'brown'],
          );

my $datafile = File::Temp->new();
ok($datafile, 'Created temp file for data');

my $data_source = UR::DataSource::Filesystem->create(
    path => $datafile->filename,
    delimiter => "\t",
    record_separator => "\n",
#    handle_class => 'URT::FileTracker',
    columns => ['thing_id','name','score','color'],
);
ok($data_source, 'Create filesystem data source');

ok(UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Number' }
    ],
    has => [
        name  => { is => 'String' },
        score => { is => 'Integer' },
        color => { is => 'String'},
    ],
    data_source_id => $data_source->id,
),
'Defined class for things');


my @file_columns_in_order = ('id','name','score','color');
my %sorters;
foreach my $cols ( [id => 0], [name => 1], [score => 2], [color => 3] ) {
    my($key,$col) = @$cols;
    $sorters{$key} = sub { no warnings 'numeric'; $a->[$col] <=> $b->[$col] or $a->[$col] cmp $b->[$col] };
}

foreach my $cols ( [id => 0], [name => 1], [score => 2], [color => 3] ) {
    my($key,$col) = @$cols;
    $sorters{'-'.$key} = sub { no warnings 'numeric'; $b->[$col] <=> $a->[$col] or $b->[$col] cmp $a->[$col] };
}

foreach my $write_sort_order ( 'asc','desc' ) {
    foreach my $sortby_col ( 0 .. 3 ) { # The number of columns in @data
        # sort the data by one of the columns...
        my %file_write_sorters = (
            asc  => sub { no warnings 'numeric'; $a->[$sortby_col] <=> $b->[$sortby_col] or $a->[$sortby_col] cmp $b->[$sortby_col] },
            desc => sub { no warnings 'numeric'; $b->[$sortby_col] <=> $a->[$sortby_col] or $b->[$sortby_col] cmp $a->[$sortby_col] },
        );

        my $write_sorter = $file_write_sorters{$write_sort_order};
        my @write_data = sort $write_sorter @data;

        ok(save_data_to_file($datafile, \@write_data),
             "Saved data sorted by column $sortby_col $write_sort_order $file_columns_in_order[$sortby_col]");
        $data_source->sorted_columns( [ ($write_sort_order eq 'desc' ? '-' : '') . $data_source->columns->[$sortby_col] ] );

        URT::Thing->unload();
        my @results = map { [ @$_{@file_columns_in_order} ] } URT::Thing->get();
        my $sort_sub = $sorters{'id'};
        my @expected = sort $sort_sub @data;
        is_deeply(\@results, \@expected, 'Got all objects in default (id) sort order');
    
        foreach my $order_by_direction ( '', '-') {
            for my $sort_prop ( 'id', 'name', 'score', 'color' ) {
                URT::Thing->unload();
                my $order_by_prop = $order_by_direction . $sort_prop;
                my @results = map { [ @$_{@file_columns_in_order} ] } URT::Thing->get(-order => [ $order_by_prop]);
                my $sort_sub = $sorters{$order_by_prop};
                my @expected = sort $sort_sub @data;
                is_deeply(\@results, \@expected, "Got all objects sorted by $order_by_prop in the right order");
            }
        }
    }
}



sub save_data_to_file {
    my($fh, $datalist) = @_;

    $fh->seek(0,0);
    $fh->print(map { $_ . "\n" }
               map { join("\t", @$_) }
               @$datalist);
    truncate($fh, $fh->tell());
    $fh->flush();
    return 1;
}

