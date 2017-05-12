#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;
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

vbox {
	relative {
		pane {
			entry { }
		} title  => 'Little panel',
		  id     => 'little',
		  border => 'round dashed single',
		  width  => '33%',
		  height => '5em';
		pane {
			entry { }
		} title     => 'Another panel',
		  id        => 'another_panel',
		  below     => 'little',
		  top_align => 'little',
		  border    => 'round dashed single',
		  width     => '33%',
		  height    => '10em';
		pane {
			entry { }
		} title        => 'Something on the right',
		  id           => 'overview',
		  right_of     => 'another_panel',
		  bottom_align => 'another_panel',
		  margin_top   => '1em';
		pane {
			static 'details area'
		} title       => 'An area for details perhaps',
		  id          => 'details',
		  below       => 'another_panel overview',
		  top_align   => 'another_panel overview',
		  margin_left => '2em',
		  border      => 'round single',
		  width       => '100%';
		pane {
			decoration class => 'vertical';
		} id          => 'gofasterstripes',
		  left_of     => 'details',
		  below       => 'another_panel',
		  border      => 'none';
		pane {
			hbox {
				decoration class => 'horizontal', 'parent:expand' => 1;
				static 'Some title text here';
			} spacing => 1;
		} id          => 'progtitle',
		  above       => 'overview',
		  right_of    => 'another_panel',
		  border      => 'none';
	} 'parent:expand' => 1;
	statusbar { };
};
tickit->run;
