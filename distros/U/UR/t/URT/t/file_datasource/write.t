#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 15;

use IO::File;
use File::Temp;

# File data: id name score
my @data = (
        [1, 'AAA', 1],
        [2, 'BBB', 1],
        [4, 'DDD', 1],
        [5, 'EEE', 1],
        [6, 'fff', 0],
        [7, 'ggg', 0],
        [9, 'iii', 0],
);

my $datafile = File::Temp->new();
ok($datafile, 'Created temp file for data');
$datafile->print(join("\t",@$_),"\n") foreach (@data);
$datafile->flush();

my $data_source = UR::DataSource::Filesystem->create(
    path => $datafile->filename,
    delimiter => "\t",
    record_separator => "\n",
    columns => ['letter_id','name','score'],
    sorted_columns => ['name','letter_id'],
);
ok($data_source, 'Create filesystem data source');

ok(UR::Object::Type->define(
    class_name => 'URT::Letter',
    id_by => [
        letter_id => { is => 'Number' }
    ],
    has => [
        name  => { is => 'String' },
        score => { is => 'Number' },
    ],
    data_source_id => $data_source->id,
),
'Defined class for letters');

my $letter_a = URT::Letter->get(name => 'AAA');
ok($letter_a, 'Got Letter named AAA');
ok($letter_a->score(2), 'Changed score to 2');

my $letter_i = URT::Letter->get(name => 'iii');
ok($letter_i, 'Got letter named iii');
ok($letter_i->name('III'), 'Changed name to III');

my $letter_f = URT::Letter->get(name =>'fff');
ok($letter_f, 'Got letter named fff');
ok($letter_f->delete(), 'Delete letter fff');

my $letter_a2 = URT::Letter->create(id => 10, name => 'aaa', score => 2);
ok($letter_a2, 'Created new letter named aaa');

my $letter_a3 = URT::Letter->create(id => 11, name => 'AAA', score => 4);
ok($letter_a3, 'Created new letter named aaa');

my $letter_z = URT::Letter->create(id => 12, name => 'zzz', score => 6);
ok($letter_z, 'Created new letter named zzz');

ok(UR::Context->commit(), 'Commit changes');

my $fh = IO::File->new($datafile->filename);
ok($fh, 'Open data file for reading');
my @lines = <$fh>;
is_deeply(\@lines,
          [ "1\tAAA\t2\n",
            "11\tAAA\t4\n",
            "2\tBBB\t1\n",
            "4\tDDD\t1\n",
            "5\tEEE\t1\n",
            "9\tIII\t0\n",
            "10\taaa\t2\n",
            "7\tggg\t0\n",
            "12\tzzz\t6\n",
          ],
          'File contents are correct');
