#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 32;

use IO::File;
use File::Temp;

# The file tracking stuff is defined at the bottom of this file
my ($file_new, $file_open, $file_close, $file_DESTROY, $file_seek, $file_seek_pos, $file_tell, $file_getline);
IO::File::Tracker->config_callbacks(
    'new'     => sub { no warnings 'uninitialized'; $file_new++ },
    'open'    => sub { no warnings 'uninitialized'; $file_open++ },
    'close'   => sub { no warnings 'uninitialized'; $file_close++ },
    'DESTROY' => sub { no warnings 'uninitialized'; $file_DESTROY++ },
    'seek'    => sub { no warnings 'uninitialized'; $file_seek_pos = $_[0]; $file_seek++ },
    'tell'    => sub { no warnings 'uninitialized'; $file_tell++ },
    'getline' => sub { no warnings 'uninitialized'; $file_getline++ },
);
sub clear_trackers  {
    $file_new = 0;
    $file_open = 0;
    $file_close = 0;
    $file_DESTROY = 0;
    $file_seek = 0;
    $file_seek_pos = undef;
    $file_tell = 0;
    $file_getline = 0;
};


# File data: id name is_upper
my @data = (
        [1, 'AAA', 1],
        [2, 'BBB', 1],
        [3, 'CCC', 1],
        [4, 'DDD', 1],
        [5, 'EEE', 1],
        [6, 'fff', 0],
        [7, 'ggg', 0],
        [8, 'hhh', 0],
        [9, 'iii', 0],
);

my $datafile = File::Temp->new();
ok($datafile, 'Created temp file for data');

my $data_source = UR::DataSource::Filesystem->create(
    path => $datafile->filename,
    delimiter => "\t",
    record_separator => "\n",
    handle_class => 'IO::File::Tracker',
    columns => ['letter_id','name','is_upper'],
);
ok($data_source, 'Create filesystem data source');

ok(UR::Object::Type->define(
    class_name => 'URT::Letter',
    id_by => [
        letter_id => { is => 'Number' }
    ],
    has => [
        name     => { is => 'String' },
        is_upper => { is => 'Boolean' },
    ],
    data_source_id => $data_source->id,
),
'Defined class for letters');



my @file_columns_in_order = ('id','name','is_upper');
my %sorters;
foreach my $cols ( [letter_id => 0], [name => 1], [is_upper => 2] ) {
    my($key,$col) = @$cols;
    $sorters{$key} = sub { no warnings 'numeric'; $a->[$col] <=> $b->[$col] or $a->[$col] cmp $b->[$col] };
}

foreach my $cols ( [letter_id => 0], [name => 1], [is_upper => 2] ) {
    my($key,$col) = @$cols;
    $sorters{'-'.$key} = sub { no warnings 'numeric'; $b->[$col] <=> $a->[$col] or $b->[$col] cmp $a->[$col] };
}

my($write_sorter, @write_data, @matches, @results, @expected, $sorter_sub);

# First, write out the file in id-sorted order.
# Don't tell the data source about any particular sorting.
&clear_trackers();
$sorter_sub = $sorters{'letter_id'};
@write_data = sort $sorter_sub @data;
ok(save_data_to_file($datafile, \@write_data), 'Save file in id-sorted order');

@matches = URT::Letter->get(1);
@results = map { [ @$_{@file_columns_in_order} ] } @matches;
is(scalar(@results), 1, 'Got one result matching id 1');
is_deeply($results[0],
          [ 1, 'AAA', 1],
          'Got the right data back');

is($file_new, 1, 'One new filehandle was created');
is($file_getline, 10, 'getline() was called 10 times'); # One additional at the end of the file
is($file_DESTROY, 1, 'DESTROY was called one time');


ok($data_source->sorted_columns(['letter_id']), 'Configure the data source to be sorted by letter_id');

URT::Letter->unload();
&clear_trackers();
@matches = URT::Letter->get(1);
@results = map { [ @$_{@file_columns_in_order} ] } @matches;
is(scalar(@results), 1, 'Got one result matching id 1');
is_deeply($results[0],
          [ 1, 'AAA', 1],
          'Got the right data back');

is($file_new, 1, 'One new filehandle was created');
is($file_getline, 2, 'getline() was called 2 times');  # had to read the 2nd line to know there were no more matches
is($file_DESTROY, 1, 'DESTROY was called one time');



URT::Letter->unload();
&clear_trackers();
@matches = URT::Letter->get('id <' => 5);
@results = map { [ @$_{@file_columns_in_order} ] } @matches;
is(scalar(@results), 4, 'Got 4 results with id < 5');
is_deeply(\@results,
          [ [ 1, 'AAA', 1],
            [ 2, 'BBB', 1],
            [ 3, 'CCC', 1],
            [ 4, 'DDD', 1] ],
          'Got the right data back');
is($file_new, 1, 'One new filehandle was created');
is($file_getline, 5, 'getline() was called 5 times');
is($file_DESTROY, 1, 'DESTROY was called one time');


ok($data_source->sorted_columns(['-is_upper']), 'Configure the data source to be sorted by -is_upper');

URT::Letter->unload();
&clear_trackers();
@matches = URT::Letter->get('is_upper >' => 0);
@results = map { [ @$_{@file_columns_in_order} ] } @matches;
is(scalar(@results), 5, 'Got 5 results matching is_upper > 0');
is_deeply(\@results,
          [ [ 1, 'AAA', 1],
            [ 2, 'BBB', 1],
            [ 3, 'CCC', 1],
            [ 4, 'DDD', 1],
            [ 5, 'EEE', 1] ],
          'Got the right data back');

is($file_new, 1, 'One new filehandle was created');
is($file_getline, 6, 'getline() was called 6 times');
is($file_DESTROY, 1, 'DESTROY was called one time');



ok($data_source->sorted_columns(['name','-is_upper']),
    'Configure the data source to be sorted by name and -is_upper');

URT::Letter->unload();
&clear_trackers();
@matches = URT::Letter->get('name between' => ['BBB','DDD']);
@results = map { [ @$_{@file_columns_in_order} ] } @matches;
is(scalar(@results), 3, 'Got 3 results matching name between BBB and DDD');
is_deeply(\@results,
          [ [ 2, 'BBB', 1],
            [ 3, 'CCC', 1],
            [ 4, 'DDD', 1] ],
    'Got the right data back');
is($file_new, 1, 'One new filehandle was created');
is($file_getline, 5, 'getline() was called 5 times');
is($file_DESTROY, 1, 'DESTROY was called one time');


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


package IO::File::Tracker;

our %callbacks;

sub config_callbacks {
    my $class = shift;
    my %set_callbacks = @_;

    foreach my $key ( keys %set_callbacks) {
        $callbacks{$key} = $set_callbacks{$key};
    }
}

sub _call_cb {
    my($op, @args) = @_;

    my $cb = $callbacks{$op};
    if ($cb) {
        $cb->(@args);
    }
}

use vars '$AUTOLOAD';
sub AUTOLOAD {
    my $subname = $AUTOLOAD;
    $subname =~ s/^.*:://;
    my $super = IO::File->can($subname) || IO::Handle->can($subname);
    if ($super) {
        $super->(@_);
    } else {
        Carp::croak("Can't wrap method $subname because it is not implemented by IO::File");
    }
}

BEGIN {
    # Create overridden methods for the ones we want to track

    no strict 'refs';
    foreach my $subname (qw( new open close DESTROY seek tell getline ) ) {
        my $subref = sub {
                         my $self = shift;
                         _call_cb($subname, @_);
                         my $super = IO::File->can($subname);
                         return $super->($self, @_);
                     };
        my $fq_subname = 'IO::File::Tracker::'.$subname;
        *$fq_subname = $subref;
    }
}

