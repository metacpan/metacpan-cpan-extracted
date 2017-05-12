#!/usr/bin/env perl
use strict;
use warnings;

use Log::Any qw($log);

use Tickit::Async;
use Tickit::Widget::LogAny;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;

my $vbox = Tickit::Widget::VBox->new;
$vbox->add(Tickit::Widget::Static->new(
	text => 'test',
));
$vbox->add(my $w = Tickit::Widget::LogAny->new(
		warn => 1,
		io_async => 1,
	), expand => 1);
my $tickit = Tickit::Async->new(
	root => $vbox,
		# root => 
);
warn "a warning\n";
warn "a warning with no \\n";
$log->debug("This is a debug message");
$log->debug("This message $_") for 1..5;
$tickit->run;
