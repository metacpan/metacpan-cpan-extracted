#!/usr/bin/perl

use strict;
use warnings;

# This is as simple as the usage gets.
#
# Use the module, call new() passing a file (or a scalar containing the source
# you need to autogenerate tests for), call gen_testfile() and do something
# with the output.
#
# For example, from the commandline, call this script via:
#
#   $ mkdir t
#   $ perl module.pl > t/module.t

use Test::StubGenerator;

my $stub = Test::StubGenerator->new( { file => 'lib/Test/StubGenerator.pm',
                                       tidy => 1,
                                       perltidyrc => 't/perltidyrc'
                                     } );

my $output = $stub->gen_testfile;

print $output;
