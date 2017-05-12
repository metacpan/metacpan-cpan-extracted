#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;
fileviewer { } shift(@ARGV);
tickit->run;
