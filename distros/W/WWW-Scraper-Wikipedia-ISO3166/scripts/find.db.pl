#!/usr/bin/env perl

use strict;
use warnings;

use File::ShareDir;

# -----------------

my($app_name)	= 'WWW-Scraper-Wikipedia-ISO3166';
my($db_name)	= shift || 'www.scraper.wikipedia.iso3166.sqlite';
my($path)		= File::ShareDir::dist_file($app_name, $db_name);

print "Using: File::ShareDir::dist_file('$app_name', '$db_name'): \n";
print "Found: $path\n";
