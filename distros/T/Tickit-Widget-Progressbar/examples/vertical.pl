#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Progressbar::Vertical;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;
use Tickit::Widget::VBox;

my $tickit = Tickit->new;
my $left = Tickit::Widget::Progressbar::Vertical->new(
	completion	=> 0,
);
my $right = Tickit::Widget::Progressbar::Vertical->new(
	completion	=> 0,
	direction	=> 1,
);

# |-|
# | |
# |-|

my $hbox = Tickit::Widget::HBox->new;
$hbox->add($left);
my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Static->new(text => "Progress bar demo", align => 'centre', valign => 'middle'), expand => 1);
$hbox->add($vbox, expand => 1);
$hbox->add($right);
$tickit->set_root_widget($hbox);
my $completion = 0.0;
my $code; $code = sub {
	$_->completion($completion += 0.0015) for $left, $right;
	return if $completion >= 1.00;
	$tickit->timer(after => 0.05 => $code);
};
$tickit->timer(after => 0.05 => $code);
$tickit->run;

