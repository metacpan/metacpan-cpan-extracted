#!/usr/bin/env perl

use strict;
use Warnings::Version 'all';

sub TIESCALAR { bless [] };

my $foo = tie my $bar, 'main';
untie $bar;
