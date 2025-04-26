#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use glog::logger;

my $log = glog::logger->new;

$log->LogLevel(5);  # Enable DEBUG and up

$log->LogInfo("Startup sequence initiated");
$log->LogDebug("Initializing module: Core");
$log->LogWarn("Memory usage approaching limit");

$log->LogFormat(3, "Loaded %d config entries", 27);

# File logging
$log->LogFile("logfile.txt");
$log->LogInfo("This goes to file");
$log->LogFile(undef);

# Die test
eval { $log->LogDie("Unrecoverable system fault") };
warn "Exception: $@" if $@;
