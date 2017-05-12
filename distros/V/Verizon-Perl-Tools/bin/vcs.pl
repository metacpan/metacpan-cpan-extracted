#!/usr/bin/perl -w

## Command line script to illustrate the use of the API and to 
## provide a convenient tool for system administrators

use strict;
use Carp;

use Verizon::Cloud::Storage qw(get_buckets);

print get_buckets;

