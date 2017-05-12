#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::Async;
use Tickit::Widget::Term;
use IO::Async::Loop;
use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr);
use Tickit::Widget::Frame;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $tickit = Tickit::Async->new
);
my $frame = Tickit::Widget::Frame->new(
	child => my $term = Tickit::Widget::Term->new(
		command => ['/bin/bash'],
		loop => $loop
	),
	title => 'shell',
	style => {
		linetype => 'single'
	},
);
$tickit->set_root_widget(
	$frame
);
$term->take_focus;
$tickit->run;

