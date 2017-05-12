#!/usr/bin/env perl

use strict;
use Warnings::Version '5.20';

my $hash_ref = { foo => 'bar' };
foreach my $key (keys $hash_ref) { $hash_ref->{$key} .= 'baz'; }
