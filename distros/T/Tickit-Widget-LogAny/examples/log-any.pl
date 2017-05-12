#!/usr/bin/env perl
use strict;
use warnings;

use Log::Any qw($log);

use Tickit;
use Tickit::Widget::LogAny;
use Tickit::Widget::Static;
use Tickit::Widget::VBox;

my $vbox = Tickit::Widget::VBox->new;
$vbox->add(my $w = Tickit::Widget::LogAny->new(
), expand => 1);
$vbox->add(Tickit::Widget::Static->new(
	text => 'This is another widget',
));
my $tickit = Tickit->new(
	root => $vbox,
		# root => 
);
$log->debug("This is a debug message");
$log->debug("This message $_") for 1..5;
$tickit->run;
