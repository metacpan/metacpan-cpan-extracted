#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Async;
use IO::Async::Loop;
use Tickit::Widget::Statusbar;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;
my $loop = IO::Async::Loop->new;
my $tickit = Tickit::Async->new;
my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Static->new(text => 'status bar demo'), expand => 1);
$vbox->add(my $status = Tickit::Widget::Statusbar->new(
	status => 'custom status widget'
));
$tickit->set_root_widget($vbox);
$loop->add($tickit);
$tickit->run;

