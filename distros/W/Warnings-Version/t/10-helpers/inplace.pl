#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

my $filename = $0 . "nonexistant";
unlink $filename;
@ARGV=($filename);
my $line = <>;
