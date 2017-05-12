#!/usr/bin/perl
use strict; use warnings;
use Test::Reporter::POEGateway;

# let it do the work!
Test::Reporter::POEGateway->spawn() or die "Unable to spawn the POEGateway!";

# run the kernel!
POE::Kernel->run();
