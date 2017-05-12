#!/usr/bin/perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::SparkLine;

my $tickit = Tickit->new;
my $vbox = Tickit::Widget::VBox->new;
my @graphs = map { Tickit::Widget::SparkLine->new( data => [ 1, 6, 5, 4, 3, 2, 1, 0,4 ]) } 0..3;
foreach my $g (@graphs) {
	my $hbox = Tickit::Widget::HBox->new;
	$hbox->add($g, expand => 1);
	$vbox->add($hbox, expand => 1);
}
$tickit->set_root_widget($vbox);
$tickit->run;

