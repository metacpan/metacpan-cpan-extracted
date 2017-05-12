#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 100;


use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use URT; # dummy namespace

use File::Temp;

# The file tracking stuff is defined at the bottom of this file
my ($file_new, $file_open, $file_close, $file_DESTROY, $file_seek, $file_seek_pos, $file_tell);
IO::File::Tracker->config_callbacks(
    'new'     => sub { no warnings 'uninitialized'; $file_new++ },
    'open'    => sub { no warnings 'uninitialized'; $file_open++ },
    'close'   => sub { no warnings 'uninitialized'; $file_close++ },
    'DESTROY' => sub { no warnings 'uninitialized'; $file_DESTROY++ },
    'seek'    => sub { no warnings 'uninitialized'; $file_seek_pos = $_[0]; $file_seek++ },
    'tell'    => sub { no warnings 'uninitialized'; $file_tell++ },
);
sub clear_trackers  { 
    $file_new = 0;
    $file_open = 0;
    $file_close = 0;
    $file_DESTROY = 0;
    $file_seek = 0;
    $file_seek_pos = undef;
    $file_tell = 0;
};

my $file_line_length = 8; # Includes the newline
my $file_data = qq(1\tAAA\t1
2\tBBB\t1
3\tCCC\t1
4\tDDD\t1
5\tEEE\t1
6\tfff\t0
7\tggg\t0
8\thhh\t0
9\tiii\t0
);


# First, make up a File datasource with the default behavior of keeping its file
# handle open as long as possible
my(undef,$tempfile_name_1) = File::Temp::tempfile();
END { unlink $tempfile_name_1 }
my $fh_1 = IO::File->new($tempfile_name_1, 'w');
   $fh_1->print($file_data);
   $fh_1->close();
my $keepopen_ds = UR::DataSource::File->create(
             delimiter => "\t",
             quick_disconnect => 0,
             handle_class => 'IO::File::Tracker',
             server => $tempfile_name_1,
             column_order => ['letter_id', 'name', 'is_upper'],
             sort_order => ['letter_id'],
         );
UR::Object::Type->define(
    class_name => 'URT::Letters',
    id_by => 'letter_id',
    has => [
        letter_id => { is => 'Integer' },
        name   => { is => 'String' },
        is_upper => { is => 'Boolean' },
    ],
    data_source_id => $keepopen_ds->id,
);



&clear_trackers();

my $obj = URT::Letters->get(1);
ok($obj, 'Got an object from the file');
is($obj->name, 'AAA', 'it has the correct name');
ok($file_new, 'new() was called on the file handle');
ok($file_open, 'open() was called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, 0, 'seek() was to the correct position');


&clear_trackers();
$obj = URT::Letters->get(2);
ok($obj, 'Got second object from the file');
is($obj->name, 'BBB', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, 0, 'seek() was to the correct position');

&clear_trackers();
$obj = URT::Letters->get(5);
ok($obj, 'Got fifth object from the file');
is($obj->name, 'EEE', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length * 2, 'seek() was to the correct position');

# This one should still be in the data source's cache
&clear_trackers();
$obj = URT::Letters->get(4);
ok($obj, 'Got fourth object');
is($obj->name, 'DDD', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length * 2, 'seek() was to the correct position');


# This datasource points to the same file (not a problem since we're not writing to it)
# but with the quick_disconnect flag on
my $close_ds = UR::DataSource::File->create(
             delimiter => "\t",
             quick_disconnect => 1,
             handle_class => 'IO::File::Tracker',
             server => $tempfile_name_1,
             column_order => ['letter_id', 'name', 'is_upper'],
             sort_order => ['letter_id'],
         );
UR::Object::Type->define(
    class_name => 'URT::LettersAlternate',
    id_by => 'letter_id',
    has => [
        letter_id => { is => 'Integer' },
        name   => { is => 'String' },
        is_upper => { is => 'Boolean' },
    ],
    data_source_id => $close_ds->id,
);

# Create a couple of iterators on the same datasource and interleave their
# reads, and make sure they seek back to the correct positions
&clear_trackers();
my $lower_iter = URT::LettersAlternate->create_iterator(is_upper => 0);
ok($lower_iter, 'Created an iterator for lower case objects');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 0, 'seek() was not called on the file handle');

&clear_trackers();
$obj = $lower_iter->next();
ok($obj, 'Got an object from the lower case iterator');
is($obj->name, 'fff', 'It was the first lowercase object');
is($file_new, 1, 'new() was called on the file handle');
is($file_open, 1, 'open() was called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, 0, 'seek() was to the correct position');

&clear_trackers();
$obj = $lower_iter->next();
ok($obj, 'Got another object from the lower case iterator');
is($obj->name, 'ggg', 'It was the next lowercase object');
is($file_new, 0, 'new() was called on the file handle');
is($file_open, 0, 'open() was called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 0, 'seek() was not called on the file handle');

&clear_trackers();
# This get() won't close the handle because $all_iter is still running
$obj = URT::LettersAlternate->get(9);
ok($obj, 'Use get() to get the ninth object');
is($obj->name, 'iii', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length * 7, 'seek() set the file pos to the 7th line'); # Because the lower-case iter gets us this far

&clear_trackers();
my $upper_iter = URT::LettersAlternate->create_iterator(is_upper => 1);
ok($upper_iter, 'Created an iterator for upper case objects');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 0, 'seek() was not called on the file handle');

&clear_trackers();
$obj = $upper_iter->next();
ok($obj, 'Got an object from the upper case iterator');
is($obj->name, 'AAA', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, 0, 'seek() set the file pos to 0');

&clear_trackers();
$obj = $lower_iter->next();
ok($obj, 'Got an object from the lower case iterator');
is($obj->name, 'hhh', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length * 8, 'seek() set the file pos to the 8th line');

&clear_trackers();
$obj = $upper_iter->next();
ok($obj, 'Got an object from the upper case iterator');
is($obj->name, 'BBB', 'The name was correct');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length * 2, 'seek() set the file pos to the 1th (second) line');


&clear_trackers();
$lower_iter = undef;
#diag('Closing the lower case object iterator');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 0, 'seek() was not called on the file handle');

&clear_trackers();
$obj = $upper_iter->next();
ok($obj, 'Got an object from the upper case iterator');
is($obj->name, 'CCC', 'It was the third object');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 0, 'close() was not called on the file handle');
is($file_seek, 0, 'seek() was not called on the file handle');

&clear_trackers();
$upper_iter = undef;
#diag('Closing the upper case object iterator');
is($file_new, 0, 'new() was not called on the file handle');
is($file_open, 0, 'open() was not called on the file handle');
is($file_close, 1, 'close() was called on the file handle');
is($file_seek, 0, 'seek() was called on the file handle');


&clear_trackers();
$obj = URT::LettersAlternate->get(5);  # something not in the object cache so it will hit the data source
ok($obj, 'Got object with id 5');
is($obj->name, 'EEE', 'It has the right name');
is($file_new, 1, 'new() was called on the file handle');
is($file_open, 1, 'open() was called on the file handle');
is($file_close, 1, 'close() was called on the file handle');
is($file_seek, 1, 'seek() was called on the file handle');
is($file_seek_pos, $file_line_length*3, 'seek() was to the correct position');  # The uppercase iter gets us this far










sub IO::File::Tracker::config_callbacks {
    my $class = shift;
    my %set_callbacks = @_;

    foreach my $key ( keys %set_callbacks) {
        $IO::File::Tracker::callbacks{$key} = $set_callbacks{$key};
    }
}

sub IO::File::Tracker::_call_cb {
    my($op, @args) = @_;

    my $cb = $IO::File::Tracker::callbacks{$op};
    if ($cb) {
        $cb->(@args);
    }
}

BEGIN {
    @IO::File::Tracker::ISA = qw( IO::File );
    # Create overridden methods for the ones we want to track
    
    foreach my $subname (qw( new open close DESTROY seek tell getline ) ) {
        no strict 'refs';
        my $subref = sub {
                         my $self = shift;
                         IO::File::Tracker::_call_cb($subname, @_);
                         my $super = IO::File->can($subname);
                         return $super->($self, @_);
                     };
        my $fq_subname = 'IO::File::Tracker::'.$subname;
        *$fq_subname = $subref;

    }
}

