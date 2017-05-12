#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 10;

    ISA [] => "ARRAY";
    # output:
    # ok 1 - [] ISA "ARRAY"
    
    ISA {} => "HASH";
    # output:
    # ok 2 - {} ISA "HASH"
    
    ISA qr/ABC/ => "Regexp";
    # output:
    # ok 3 - qr/ABC/ ISA "Regexp"

    ISA \*STDIO => "GLOB";
    # output:
    # ok 4 - \*STDIO ISA "GLOB"
    
    my $io = IO::File->new();
    ISA $io => "IO::File";
    # output:
    # ok 5 - $io ISA "IO::File"
    
    ISA $io => "IO::Handle";
    # output:
    # ok 6 - $io ISA "IO::Handle"
    
    ISA $io => "Exporter";
    # output:
    # ok 7 - $io ISA "Exporter"
    
    ISA $io => "GLOB";
    # output:
    # ok 8 - $io ISA "GLOB"
    
    TODO ISA $io => "ARRAY";
    # output:
    # # Time: 2012-02-28 02:03:20 PM
    # ./example.t:34:1: Test 9 Failed
    # not ok 9 - $io ISA "ARRAY"
    # #   Failed test '$io ISA "ARRAY"'
    
    TODO ISA $io => "IO::Socket";
    # output:
    # # Time: 2012-02-28 02:03:20 PM
    # ./example.t:41:1: Test 10 Failed
    # not ok 10 - $io ISA "IO::Socket"
    # #   Failed test '$io ISA "IO::Socket"'
