#!/usr/bin/perl -T

use strict;
use warnings;

use lib 't/lib';

use Test::WWW::PivotalTracker;

Test::Class->runtests();
