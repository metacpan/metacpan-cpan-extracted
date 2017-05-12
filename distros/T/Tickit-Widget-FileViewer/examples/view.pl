#!/usr/bin/env perl
use strict;
use warnings;

use Tickit;
use Tickit::Widget::FileViewer;

my $tickit = Tickit->new;
my $viewer = Tickit::Widget::FileViewer->new(
file => shift(@ARGV),
);
$tickit->set_root_widget($viewer);
$tickit->run;

