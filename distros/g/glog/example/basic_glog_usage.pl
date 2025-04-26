#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use glog;

LogLevel(5);  # Enable DEBUG and up

LogInfo("Application started");
LogDebug("Debug info: x=%d", 42);
LogWarn("Disk space low");
LogErr("Cannot open file");

LogF(3, "User %s logged in at %s", "alice", scalar localtime);

# Switch to file logging
LogFile("glog_output.log");
LogInfo("Now logging to file");
LogFile(undef); # Back to STDERR

# Fatal log with die
eval { LogDie("Fatal error encountered") };
warn "Caught fatal: $@" if $@;
