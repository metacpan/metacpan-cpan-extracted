#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;

vbox {
	my @pending;
	my $output;
	my $con = console {
		if($output) {
			push @pending, $_[1];
			add_widgets {
				scroller_text $_ for splice @pending;
			} under => $output
		} else {
			push @pending, shift;
		}
	} 'parent:expand' => 3;
	$output = scroller {
	} gravity => 'bottom', 'parent:expand' => 1;
	$con->add_tab(
		name => 'test',
		on_line => sub {
			if($output) {
				push @pending, 'test tab: ' . $_[1];
				add_widgets {
					scroller_text $_ for splice @pending;
				} under => $output
			} else {
				push @pending, shift;
			}
		}
	);
};
tickit->run;
