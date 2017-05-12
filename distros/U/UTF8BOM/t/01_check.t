#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;
use UTF8BOM;
use IO::File;

my $fh = IO::File->new('t/dir/with_bom.txt');
my @lines = $fh->getlines;
my $text_with_bom = join "", @lines;
$fh->close;

$fh = IO::File->new('t/dir/without_bom.txt');
@lines = $fh->getlines;
my $text_without_bom = join "", @lines;
$fh->close;

ok( UTF8BOM->check_bom($text_with_bom) );
ok( !UTF8BOM->check_bom($text_without_bom) );

