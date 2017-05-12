#!/usr/bin/perl
#
# Copyright (C) 2012 by Lieven Hollevoet

# Verify the basic log parse functionality
# this is typically used after synthesis
use strict;
use Test::More tests => 7;

use_ok 'Text::Cadenceparser';

my $parser = Text::Cadenceparser->new(folder => 't/stim');
ok $parser, 'object created';

my $nr_files = $parser->files_parsed();
is $nr_files, 7, '... all input files parsed';

my $count = $parser->count('info');
is $count, 13, '... all info messages found';
$count = $parser->count('warning');
is $count, 5, '... all warning messages found';
$count = $parser->count('error');
is $count, 1, '... all error messages found';

my $slack = $parser->slack('main_clk');
is $slack, -243.7, '... slack detected OK'



