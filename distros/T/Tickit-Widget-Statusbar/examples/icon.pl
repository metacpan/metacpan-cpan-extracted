#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Tickit::Async;
use IO::Async::Loop;
use Tickit::Widget::Statusbar;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;

my $loop = IO::Async::Loop->new;
my $tickit = Tickit::Async->new;
my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Static->new(text => 'status bar demo'), expand => 1);
$vbox->add(my $status = Tickit::Widget::Statusbar->new);
$status->update_status('testing status line');
my $icon = $status->add_icon('♻');
$tickit->set_root_widget($vbox);
$loop->add($tickit);

{
	my $code;
	my $flag = 0;
	$code = sub {
		$tickit->timer(
			after => 2,
			sub {
				$flag = !$flag;
				$icon->set_style_tag(
					ok => $flag
				);
				$icon->set_style_tag(
					error => !$flag
				);
				# $icon->redraw;
				$code->();
			}
		);
	};
	$code->();
}
$tickit->run;

