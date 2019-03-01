#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;

use blib;
use USB::LibUSB;
use Getopt::Long qw/:config gnu_getopt/;
use Data::Dumper;
use YAML::XS;
my $vid;
my $pid;

GetOptions("vid|v=s", \$vid,
           "pid|p=s", \$pid)
    or die "getopt";

my $ctx = USB::LibUSB->init();
my $handle = $ctx->open_device_with_vid_pid_unique(hex $vid, hex $pid);
my $dev = $handle->get_device();
my $config = $dev->get_config_descriptor(0);

print Dump $config;
