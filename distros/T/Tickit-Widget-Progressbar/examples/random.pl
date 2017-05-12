
#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async;
use IO::Async::Timer::Periodic;
use Tickit::Async;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::Progressbar::Horizontal;
use Tickit::Widget::Progressbar::Vertical;
use Tickit::Widget::Static;

my $tickit = Tickit::Async->new;
my $top = Tickit::Widget::Progressbar::Horizontal->new(
	completion	=> 0,
);
my $bottom = Tickit::Widget::Progressbar::Horizontal->new(
	completion	=> 0,
	direction	=> 1,
);
my $left = Tickit::Widget::Progressbar::Vertical->new(
	completion	=> 0,
);
my $right = Tickit::Widget::Progressbar::Vertical->new(
	completion	=> 0,
	direction	=> 1,
);
my @bars = ($left, $top, $right, $bottom);

# |-|
# | |
# |-|

my $hbox = Tickit::Widget::HBox->new;
$hbox->add($left);
my $vbox = Tickit::Widget::VBox->new;
$vbox->add($top);
$vbox->add(Tickit::Widget::Static->new(text => "Progress bar demo", align => 'centre', valign => 'middle'), expand => 1);
$vbox->add($bottom);
$hbox->add($vbox, expand => 1);
$hbox->add($right);
$tickit->set_root_widget($hbox);
my $loop = IO::Async::Loop->new;

my $completion = 0.0;
my $timer = IO::Async::Timer::Periodic->new(
	interval => 0.1,

	on_tick => sub {
		$_->completion(rand) for @bars;
		$loop->later(sub { $loop->loop_stop }) if $completion >= 1.00;
	},
);
$loop->add($timer);
$timer->start;
$loop->add($tickit);
$tickit->run;

