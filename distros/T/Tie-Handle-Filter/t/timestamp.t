#!/bin/env perl

use 5.008;
use strict;
use warnings;
use Time::Fake;
use Test::More tests => 2;
use Fcntl ':seek';
use POSIX 'strftime';
use Tie::Handle::Filter::Output::Timestamp;

open my $fh, '+>', undef or die "can't create anonymous storage: $!";
tie *$fh, 'Tie::Handle::Filter::Output::Timestamp', *$fh;

ok eval {
    Time::Fake->offset( 0 - time );
    print $fh map {"$_\n"} qw(several lines printing);
    print $fh <<'END_PRINT' } => 'print';
hello world
goodbye and good luck
END_PRINT

untie *$fh;
seek $fh, 0, SEEK_SET or die "can't seek to start of anonymous storage: $!";
my $written = join q() => <$fh>;

my $expected_time = strftime( '%x %X', localtime 0 );
is $written, <<"END_EXPECTED", 'lines were prefixed';
$expected_time several
lines
printing
$expected_time hello world
goodbye and good luck
END_EXPECTED
