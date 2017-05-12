#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use LongTaskDistribution::Broker;

# If you use a broker with a DEALER socket to
# distribute tasks to workers with a REP socket the applied
# round robin distribution algorithm might not be what you want.

# In this example the tasks you want to distribute among your worker
# processes might take a long time and tasks may have a varying
# execution time. With round robin distribution, a worker might
# be available but not served with a pending task.

# This example has workers with a REQ socket that report to the broker
# when they are ready to receive a new task. The broker (ROUTER socket)
# stores the worker ID and replies as soon as a new task comes in.

LongTaskDistribution::Broker->new(
    address => 'tcp://*:10005',
)->start;
