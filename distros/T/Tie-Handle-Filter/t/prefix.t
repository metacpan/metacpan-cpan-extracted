#!/bin/env perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 2;
use Fcntl ':seek';
use Tie::Handle::Filter;

my $prefix       = 'FOOBAR';
my $prefix_start = 1;

# deal with perl 5.8 lack of \R
my $newline = $] < 5.010 ? '(?>\x0D\x0A|\n)' : '\R';

open my $fh, '+>', undef or die "can't create anonymous storage: $!";
tie *$fh, 'Tie::Handle::Filter', *$fh, sub {
    my $res = join q(), @_;
    $res =~ s/($newline)(?=.)/$1$prefix: /g;
    $res =~ s/\A/$prefix: / if $prefix_start;
    $prefix_start = $res =~ /$newline\z/s;
    return $res;
};

ok eval {
    print $fh <<'END_PRINT'; 1 } => 'print with prefix';
hello world
goodbye and good luck
END_PRINT

untie *$fh;
seek $fh, 0, SEEK_SET
    or die "can't seek to start of anonymous storage: $!";
my $written = join q(), <$fh>;

is $written, <<"END_EXPECTED", 'lines were prefixed';
$prefix: hello world
$prefix: goodbye and good luck
END_EXPECTED
