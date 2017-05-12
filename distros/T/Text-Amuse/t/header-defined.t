#!perl

use strict;
use warnings;
use Text::Amuse;
use File::Temp;
use Test::More tests => 2;

my $fh = File::Temp->new(TEMPLATE => 'museXXXXXXXXX',
                         SUFFIX => '.muse',
                         TMPDIR => 1);
binmode $fh, ":encoding(utf-8)";
print $fh "#title test\n#lang hr\n\nHello\n";
close $fh;

my $muse = Text::Amuse->new(file => $fh->filename);
is_deeply($muse->header_defined, {
                                  title => 1,
                                  lang => 1,
                                 }, "header_defined is ok");

my $header_defined = $muse->header_defined;
$header_defined->{cacca} = 1;

is_deeply($muse->header_defined, {
                                  title => 1,
                                  lang => 1,
                                 }, "header_defined is immutable");
