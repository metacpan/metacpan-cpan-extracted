#!/usr/bin/perl
use warnings;
use strict;
use lib 'lib';
use URI::Title qw(title);
use Encode;

my $title = title(shift);
binmode STDOUT, ":utf8";
print $title || 'no title';
print "\n";
