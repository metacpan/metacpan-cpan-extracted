#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw();
use Test::Pod tests => 1;

pod_file_ok( Cwd::cwd() . '/lib/Unicode/Peek.pm', "Unicode::Peek" );
