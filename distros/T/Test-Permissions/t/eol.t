#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::EOL';

Test::EOL->import();
all_perl_files_ok({ trailing_whitespace => 1 });
