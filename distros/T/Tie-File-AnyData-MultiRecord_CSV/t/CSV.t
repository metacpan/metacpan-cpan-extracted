#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use lib "./lib";

use Test::More tests => 8;

BEGIN {
  use_ok ('Tie::File::AnyData::MultiRecord_CSV');
  use_ok ('Parse::CSV');
}

my $gff_file = "t/Data/apsid.gff";

tie my @gff_arr, 'Tie::File::AnyData::MultiRecord_CSV',$gff_file, 'field_sep' => "\t", 'key' => 0;

my @nlines = ($gff_arr[0] =~/\n/sg);
ok ((scalar @nlines) == 0, "OK first record");
@nlines = ($gff_arr[5] =~/\n/sg);
ok ((scalar @nlines) == 2, "OK first record");

ok (@gff_arr == 205, "OK number of records");

tie my @gff_new, 'Tie::File::AnyData::MultiRecord_CSV',"t/Data/new.gff", 'field_sep' => "\t", 'key' => 0;
@gff_new = @gff_arr;
ok (@gff_new == 205, "Ok number of new records");

my @newrec = "1000\tapsid\tSingle\t1043\t1134\t.\t+\t.\t1000";
push @newrec, "1000\tapsid\tSingle\t10254\t543154\t.\t+\t.\t1000";
push @newrec, "1000\tapsid\tSingle\t104512\t1445245\t.\t+\t.\t1000";
push @gff_new, join "\n",@newrec;
ok (@gff_new == 206, "Ok pushing");
untie @gff_new;
unlink "t/Data/new.gff";
untie @gff_arr;

my $f4 = "t/Data/f4.csv";
tie my @t4_arr, 'Tie::File::AnyData::MultiRecord_CSV',$f4, 'field_sep' => "\t", 'key' => 4;
ok (@t4_arr == 23, "Ok number of records (II)");
untie @t4_arr;
