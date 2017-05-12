#!/usr/bin/perl

use strict;
use warnings;

use Tie::CSV_File;
use File::Temp qw/tmpnam/;
use t::CommonStuff;
use Test::ManyParams;
use Test::More qw/no_plan/;

my $fname = tmpnam();

my @data = @{ CSV_DATA() };
tie my @file, 'Tie::CSV_File', $fname;
@file = @data;

all_ok  {exists $file[$_[0]]} [0 .. $#data, -1], 
          "Every line from the data exists in the csv array";
all_ok  {!exists $file[$_[0]]} [$#data+1 .. 2*$#data],
          "Every line more than the data doesn't exists in the csv array";

for my $row (0 .. $#data) {
    all_ok {exists $file[$row]->[$_[0]]} [0 .. $#{$data[$row]}],
           "Every column from the row $row has to exist";
    all_ok {!exists $file[$row]->[$_[0]]} 
           [scalar(@{$data[$row]}) .. 2 * scalar(@{$data[$row]})],
           "Every colum more than in $row mustn't exist in the csv array";
}

$file[2 * @data] = [];
all_ok     {exists $file[$_[0]] && defined($file[$_[0]]) && (@{$file[$_[0]]} == 0)} 
           [@data .. 2*@data],
           "Appended a row, now everything between need to exist (beeing an empty list)";

$file[-1]->[10] = "";
all_ok     {exists $file[-1]->[$_[0]]  && 
            defined($file[-1]->[$_[0]]) && 
            ($file[-1]->[$_[0]] eq "")
           }
           [0 .. 9],
           "Appended a col, now everything between need to exist (as an empty string)";

untie @file;
