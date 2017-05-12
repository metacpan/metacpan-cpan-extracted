#!/usr/bin/perl

use strict;
use warnings;

use Tickit::Async;
use Getopt::Long;

my $widgetclass;
my $file;
GetOptions(
   'widget=s' => \$widgetclass,
   'file=s'   => \$file,
) or exit 1;

my $tickit = Tickit::Async->new;

defined $file or ( $file = "$widgetclass.pm" ) =~ s{::}{/}g;

require $file;

my $widget = $widgetclass->new;

$tickit->set_root_widget( $widget );

$tickit->run;
