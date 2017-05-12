#!/usr/bin/perl -w

## Command line script to illustrate the use of the API and to 
## provide a convenient tool for system administrators

use strict;
use Carp;

use Verizon::Cloud::Ecloud qw(get_organizations);

my %org = get_organizations();

printf "%-10s %-40s\n", ('Org Id', 'Name');
printf "%-10s %-40s\n", %org;


