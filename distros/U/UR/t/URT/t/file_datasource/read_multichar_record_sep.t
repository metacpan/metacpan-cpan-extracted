#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 8;

use IO::File;
use File::Temp;
use Sub::Install;

# Test the case where the record separator is a multi-character string, and
# make sure that the last record in the file does not match that whole string

# Make a FASTQ-like format file intentionally missing a blank line at the end
my $fh = File::Temp->new();
my $data = "read1
ACGTTGCA
+
12345678
abc
read2
GAAGTCCT
+
87654321
a";
$fh->print($data);
$fh->close;

ok(UR::Object::Type->define(
    class_name => 'URT::FastqReads',
    id_by => [
        path        => { is => 'String', column_name => '__FILE__' },
        record      => { is => 'Integer', column_name => '$.' },
    ],
    has => [
        seq_id      => { is => 'String'},
        sequence    => { is => 'String' },
        quality     => { is => 'String' },
    ],
    data_source => { is => 'UR::DataSource::Filesystem',
                     path  => '$path',
                     columns => ['seq_id','sequence', undef, 'quality'],
                     delimiter => "\n",
                     record_separator => "\nabc\n",
                   },
    ),
    'Defined class for fastq reads');

my @objs = URT::FastqReads->get(path => $fh->filename);
is(scalar(@objs), 2, 'Read in 1 records from the fastq file');
my @expected = (
    { seq_id => 'read1', sequence => 'ACGTTGCA', quality => '12345678' },
    { seq_id => 'read2', sequence => 'GAAGTCCT', quality => '87654321' },
);
for (my $i = 0; $i < @expected; $i++) {
    _compare_to_expected($objs[$i], $expected[$i]);
}

sub _compare_to_expected {
    my($obj,$expected) = @_;

    foreach my $prop ( keys %$expected ) {
        is($obj->$prop, $expected->{$prop}, "property $prop is correct");
    }
    return 1;
}

