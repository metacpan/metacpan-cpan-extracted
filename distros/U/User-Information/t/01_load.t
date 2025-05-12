#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 3;

use_ok('User::Information');
use_ok('User::Information::Base');
use_ok('User::Information::Path');

exit 0;
