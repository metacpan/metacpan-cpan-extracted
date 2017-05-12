#!/usr/bin/env perl

use strict;
use Warnings::Version '5.20';
use feature 'postderef';

my $hash_ref = { foo => 'bar' };
my %foo = $hash_ref->%*;
