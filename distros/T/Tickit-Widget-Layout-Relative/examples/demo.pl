#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Widget::VBox;
use Tickit::Widget::Statusbar;
use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;
use Tickit::Widget::Menu::Item;
use Tickit::Widget::Layout::Relative;
use Tickit::Widget::Static;

my $l = Tickit::Widget::Layout::Relative->new;
$l->add(
	Tickit::Widget::Static->new(text => 'left'),
	title => 'Left panel',
	id => 'left',
	border => 'round dashed single',
	width => '33%',
);
$l->add(
	Tickit::Widget::Static->new(text => 'right'),
	title => 'Right panel',
	id => 'right',
	right_of => 'left',
);
if(1) {
	use Tickit::Async;
	my $tickit = Tickit::Async->new;
	my $loop = IO::Async::Loop->new;
	my $vbox = Tickit::Widget::VBox->new;
	$vbox->add(Tickit::Widget::MenuBar->new(
		items => [
           Tickit::Widget::Menu::Item->new(
              name => "Exit",
              on_activate => sub { $tickit->stop }
           ),
		],
	));
	$vbox->add(
		$l,
		expand => 1
	);
	$vbox->add(Tickit::Widget::Statusbar->new(loop => $loop));
	$tickit->set_root_widget($vbox);
	$loop->add($tickit);
	$tickit->run;
}
