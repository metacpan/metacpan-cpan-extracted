#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Async;
use IO::Async::Loop;
use Tickit::Widget::Statusbar;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;
use Tickit::Utils qw(textwidth);
my $loop = IO::Async::Loop->new;
$loop->add(my $tickit = Tickit::Async->new);
my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Static->new(text => 'status bar demo'), expand => 1);
$vbox->add(my $status = Tickit::Widget::Statusbar->new);
$status->update_status('testing status line');
$tickit->timer(
	after => 0.5,
	sub {
		$status->update_status(
			String::Tagged->new(
				"Some tagged text using String::Tagged"
			)->apply_tag(0, 4, fg => 'green')
			 ->apply_tag(5, 6, fg => 'hi-green')
			 ->apply_tag(12, 4, fg => 'hi-red')
			 ->apply_tag(17, 5, fg => 'hi-blue')
		);
		my @words = qw(some words to use in the status bar for rendering random things);
		my @colours = qw(red green blue hi-green hi-red hi-blue yellow hi-yellow brown white);
		my $code;
		$code = sub { $tickit->timer(
			after => 0.75,
			sub {
				my @selection = map $words[rand @words], 1..rand(@words);
				my $st = String::Tagged->new(
					join ' ', @selection
				);
				my $idx = 0;
				for (@selection) {
					$st->apply_tag($idx, textwidth($_), fg => $colours[rand @colours]);
					$idx += 1 + textwidth($_);
				}
				$status->update_status(
					$st
				);
				$code->();
			}
		);};
		$code->();
	}
);
$tickit->set_root_widget($vbox);
$tickit->run;

