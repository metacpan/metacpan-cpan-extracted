#!/usr/bin/perl
use strict;
use Test::More;
use Time::Piece::MySQL;

my %timestamp = (
    '70' => '19700101000000',
    '1202' => '20120201000000',
    '120211' => '20120211000000',
    '20120211' => '20120211000000',
    '1202110545' => '20120211054500',
    '120211054537' => '20120211054537',
    '20120211054537' => '20120211054537',
    '2005-08-10 23:20:48' => '20050810232048',
);

#my @null = qw/ 19691231235959 20380101000000 /;

plan tests => scalar keys %timestamp;

for my $stamp (keys %timestamp) {
    my $t = Time::Piece->from_mysql_timestamp($stamp);
    is $t->mysql_timestamp, $timestamp{$stamp}, "timestamp $stamp";
}
