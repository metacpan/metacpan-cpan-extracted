#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl;

#use Errno qw/ENOENT EBADF/;

use Test::MockFile;    # Everything below this can have its open overridden.

pass("Todo");

done_testing();
