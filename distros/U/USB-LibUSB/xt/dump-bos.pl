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
$ctx->set_debug(LIBUSB_LOG_LEVEL_DEBUG);
my $handle = $ctx->open_device_with_vid_pid(hex $vid, hex $pid);
my $bos = $handle->get_bos_descriptor();

print Dump $bos;
