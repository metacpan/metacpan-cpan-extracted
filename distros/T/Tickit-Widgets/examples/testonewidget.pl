#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Getopt::Long;

my $widgetclass;
my $file;
GetOptions(
   'widget=s' => \$widgetclass,
   'file=s'   => \$file,
) or exit 1;

defined $file or ( $file = "$widgetclass.pm" ) =~ s{::}{/}g;

require $file;

my $widget = $widgetclass->new;

Tickit->new( root => $widget )->run;
