#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Progressbar::Horizontal;
use Tickit::Widget::Static;
use Tickit::Widget::HBox;
use Tickit::Widget::VBox;

my $tickit = Tickit->new;
my $top = Tickit::Widget::Progressbar::Horizontal->new(
	completion	=> 0,
);
my $bottom = Tickit::Widget::Progressbar::Horizontal->new(
	completion	=> 0,
	direction	=> 1,
);

my $vbox = Tickit::Widget::VBox->new;
$vbox->add($top);
$vbox->add(Tickit::Widget::Static->new(text => "Progress bar demo", align => 'centre', valign => 'middle'), expand => 1);
$vbox->add($bottom);
$tickit->set_root_widget($vbox);
my $completion = 0.0;
my $code; $code = sub {
	$completion += 0.0010;
	$_->completion($completion) for $top, $bottom;
	return if $completion >= 1.00;
	$tickit->timer(after => 0.05 => $code);
};
$tickit->timer(after => 0.05 => $code);
$tickit->run;

