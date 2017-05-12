#!/usr/bin/env perl

use strict;

use Data::Dumper;

use Find::Lib '../lib';
use Find::Lib 'lib';

use Pizza::Conf;

my $conf = Pizza::Conf->new;

print(Dumper($conf->data));
