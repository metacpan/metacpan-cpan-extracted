#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;

vbox {
	floatbox {
		vbox {
			static 'top line';
			hbox {
				button {
					float {
						frame {
							placeholder;
						};
					} top => 1, left => 1, bottom => 7, right => 30;
				} 'Create float';
				button {
					tickit->stop;
				} 'Exit';
			} 'parent:expand' => 1;
			static 'last line';
		} 'parent:expand' => 1;
	} 'parent:expand' => 1;
};
tickit->run;
