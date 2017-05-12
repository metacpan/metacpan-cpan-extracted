#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::SparkLine;

use Tickit::Style;
Tickit::Style->load_style(<<'EOF');
SparkLine.x1 {
fg: 22;
}
SparkLine.x2 {
fg: 28;
}
SparkLine.x3 {
fg: 34;
}
SparkLine.x4 {
fg: 40;
}
SparkLine.x5 {
fg: 46;
}
SparkLine.x6 {
fg: 2;
}
EOF

my $tickit = Tickit->new;
my $hbox = Tickit::Widget::HBox->new;
my @graphs = map { Tickit::Widget::SparkLine->new( data => [ 0..1000 ])->resample_mode('average') } 0..3;
my @other_graphs = map { Tickit::Widget::SparkLine->new( class => "x$_", data => [ map 100 * rand, 1..25 ])->resample_mode('average') } 1..5;
my $left = Tickit::Widget::VBox->new;
my $right = Tickit::Widget::VBox->new;
$left->add($_, expand => 1) for @graphs;
$right->add($_, expand => 1) for @other_graphs;
$hbox->add($left, expand => 1);
$hbox->add($right, expand => 1);
$tickit->set_root_widget($hbox);
$tickit->run;

