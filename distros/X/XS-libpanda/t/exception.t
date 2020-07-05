use strict;
use warnings;
use lib 't';
use MyTest;
use Config;
use Test::More;
use Test::Catch;

# *bsd 32bit: libunwind: EHHeaderParser::decodeTableEntry: bad fde: CIE ID is not zero
# https://forums.freebsd.org/threads/freebsd-12-0-libunwind-error.70851/
# other: should be ok

my $frames_count = MyTest::call_dump_trace();
plan skip_all => 'it seems the system has buggy glibc/libunwind, no sense to test' if !$frames_count;

catch_run('[exception]');

done_testing;
