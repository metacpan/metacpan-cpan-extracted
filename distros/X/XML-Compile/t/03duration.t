#!/usr/bin/env perl
# Check implementation of type extension administration

use warnings;
use strict;

use File::Spec;
use POSIX  qw/strftime tzset/;

use lib 'lib', 't';
use XML::Compile::Util qw/duration2secs add_duration/;
use Test::More;

# On some platforms (Windows), tzset is not supported so we cannot produce
# consistent time output.
eval { tzset };
plan skip_all => $@ if $@;

plan tests => 16;

# examples taken from http://www.schemacentral.com/sc/xsd/t-xsd_duration.html

### test duration2secs

# 2 yrs, 6 months, 5 days, 12 hours, 35 minutes, 30 seconds
cmp_ok(duration2secs('P2Y6M5DT12H35M30S'), '==', 79352926.8);

cmp_ok(duration2secs('P1DT2H'), '==', 93600);   # 1 day, 2 hours

# 20 months (the number of months can be more than 12)
cmp_ok(duration2secs('P20M'), '==', 52531200);

cmp_ok(duration2secs('PT20M'), '==', 1200);     # 20 minutes

# 20 months (0 is permitted as a number, but is not required)
cmp_ok(duration2secs('P0Y20M0D'), '==', 52531200);

cmp_ok(duration2secs('P0Y'), '==', 0);          # 0 years
cmp_ok(duration2secs('-P60D'), '==', -5184000); # minus 60 days
cmp_ok(duration2secs('PT1M30.5S'), '==', 90.5); # 1 minute, 30.5 seconds

### test add_duration
$ENV{TZ} = 'UCT'; tzset;
sub t($) {strftime "%Y-%m-%dT%H:%M:%S", gmtime shift}

# used to calculate some fixed reference point in time
# my $now  = time;
my $now    = 1397731609;   # 2014-04-17T10:46:49Z
#print "$now=",t($now), "\n";

cmp_ok(t(add_duration('P2Y6M5DT12H35M30S', $now)), 'eq', '2016-10-22T23:22:19');
cmp_ok(t(add_duration('P1DT2H', $now)), 'eq', '2014-04-18T12:46:49');
cmp_ok(t(add_duration('P20M', $now)), 'eq', '2015-12-17T10:46:49');
cmp_ok(t(add_duration('PT20M', $now)), 'eq', '2014-04-17T11:06:49');
cmp_ok(t(add_duration('P0Y20M0D', $now)), 'eq', '2015-12-17T10:46:49');
cmp_ok(t(add_duration('P0Y', $now)), 'eq', '2014-04-17T10:46:49');
cmp_ok(t(add_duration('-P60D', $now)), 'eq', '2014-02-16T10:46:49');
cmp_ok(t(add_duration('PT1M30.5S', $now)), 'eq', '2014-04-17T10:48:19');

