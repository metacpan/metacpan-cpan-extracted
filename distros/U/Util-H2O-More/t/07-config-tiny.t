#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin         qw/$Bin/;
use Util::H2O::More qw/o2h2o ini2h2o h2o2ini/;
use Config::Tiny    qw//;
use File::Temp      qw/tempfile/;

my $c = o2h2o( Config::Tiny->read(qq{$Bin/test.ini}) );

is $c->section1->var1, q{foo}, q{o2h2p handles Config::Tiny object as expected};

my $c2 = ini2h2o qq{$Bin/test.ini};

like $c2, qr/^Util::H2O/, q{ini2h2o returns Util::H2O object};

is $c2->section1->var1, q{foo}, q{ini2h2o read .ini file and returns object with accessors, as expected};

$c2->section1->var1(q{oof});

is $c2->section1->var1, q{oof}, q{object with setter works, as expected};

my ( $fh, $filename ) = tempfile( SUFFIX => '.ini' );

h2o2ini $c2, qq{$filename};

ok -e $filename, qq{$filename exists, so was written by h2o2ini};

my $c3 = ini2h2o qq{$filename};

is $c3->section1->var1, $c2->section1->var1, q{File written by h2o2ini stored expected configuration state};

done_testing;
