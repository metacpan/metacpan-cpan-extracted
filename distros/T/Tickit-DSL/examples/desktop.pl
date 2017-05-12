#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;

desktop {
	my $txt = static 'a static widget', 'parent:label' => 'static';
	entry {
		$txt->set_text($_[1])
	} 'parent:label' => 'entry widget';
	placeholder;
};
tickit->run;

