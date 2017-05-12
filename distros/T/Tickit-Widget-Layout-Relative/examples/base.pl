#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;
use Tickit::Widget::Layout::Relative;
use Tickit::Style;

Tickit::Style->load_style(<<'EOF');
Decoration.horizontal {
 gradient-direction: 'horizontal';
}
Decoration.vertical {
 gradient-direction: 'vertical';
 start-fg: 255;
 end-fg: 232;
}
EOF

my $l = Tickit::Widget::Layout::Relative->new(width => 80, height => 45);
$l->add(
	Tickit::Widget::Entry->new,
	title  => 'Little panel',
	id     => 'little',
	border => 'round dashed single',
	width  => '33%',
	height => '5em',
);
$l->add(
	Tickit::Widget::Entry->new,
	title     => 'Another panel',
	id        => 'another_panel',
	below     => 'little',
	top_align => 'little',
	border    => 'round dashed single',
	width     => '33%',
	height    => '10em',
);
$l->add(
	Tickit::Widget::Entry->new,
	title        => 'Something on the right',
	id           => 'overview',
	right_of     => 'another_panel',
	bottom_align => 'another_panel',
	margin_top   => '1em',
	# width      => '67%',
	# margin_right => '3em',
);
$l->add(
	Tickit::Widget::Static->new(text => '...'),
	title       => 'An area for details perhaps',
	id          => 'details',
	below       => 'another_panel overview',
	top_align   => 'another_panel overview',
	margin_left => '2em',
	border      => 'round single',
	width       => '100%',
	line_style  => 'thick',
);
$l->add(
	Tickit::Widget::Decoration->new(class => 'vertical'),
	id          => 'gofasterstripes',
	left_of     => 'details',
	below       => 'another_panel',
	border      => 'none',
);
{
	my $hb = Tickit::Widget::HBox->new(spacing => 1);
	$hb->add(Tickit::Widget::Decoration->new(class => 'horizontal'), expand => 1);
	$hb->add(Tickit::Widget::Static->new(text => 'Some title text here'));

	$l->add(
		$hb,
		id          => 'progtitle',
		above       => 'overview',
		right_of    => 'another_panel',
		border      => 'none',
	);
}
if(1) {
	my $tickit = Tickit->new;
	my $vbox = Tickit::Widget::VBox->new;
	$vbox->add($l, expand => 1);
	$vbox->add(Tickit::Widget::Statusbar->new);
	$tickit->set_root_widget($vbox);
	$tickit->run;
}
