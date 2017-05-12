#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 29;

use IO::File;
use File::Temp;

# First write some easy data
my $fh = File::Temp->new();
foreach ( 'a','b','c','d','e' ) {
    $fh->print($_,"\n");
}
$fh->close();

my $filename = $fh->filename;
ok(UR::Object::Type->define(
    class_name => 'URT::Alphabet',
    id_by => [
        file    => { is => 'String', column_name => '__FILE__'},
        lineno  => { is => 'Integer', column_name => '$.' },
    ],
    has => [
        letter  => { is => 'String' },
    ],
    data_source => { is => 'UR::DataSource::Filesystem',
                     path  => '$file',
                     columns => ['letter'],
                   },
    ),
    'Defined class for letters');


my @objs = URT::Alphabet->get(file => $filename, 'lineno <' => 4);
is(scalar(@objs), 3, 'Got 3 objects back filtering by lineno < 4');  # because line numbers ($.) start at 1

my @expected = (
    { file => $filename, lineno => 1, letter => 'a' },
    { file => $filename, lineno => 2, letter => 'b' },
    { file => $filename, lineno => 3, letter => 'c' },
);

for (my $i = 0; $i < @expected; $i++) {
    _compare_to_expected($objs[$i], $expected[$i]);
}


@objs = URT::Alphabet->get(file => $filename, lineno => 4);
is(scalar(@objs), 1, 'Got 1 object with lineno == 4');
_compare_to_expected($objs[0],
                    { file => $filename, lineno => 4, letter => 'd' });


@objs = URT::Alphabet->get(file => $filename, lineno => 10);
is(scalar(@objs), 0, 'Correctly got 0 objects with lineno == 10');


@objs = URT::Alphabet->get(file => $filename, 'lineno between' => [2,7]);
is(scalar(@objs), 4, 'Got 4 objects with lineno between 2 and 7');
@expected = (
    { file => $filename, lineno => 2, letter => 'b' },
    { file => $filename, lineno => 3, letter => 'c' },
    { file => $filename, lineno => 4, letter => 'd' },
    { file => $filename, lineno => 5, letter => 'e' },
);
for (my $i = 0; $i < @expected; $i++) {
    _compare_to_expected($objs[$i], $expected[$i]);
}




sub _compare_to_expected {
    my($obj,$expected) = @_;

    foreach my $prop ( 'file','lineno','letter' ) {
        is($obj->$prop, $expected->{$prop}, "$prop has expected value");
    }
}

