#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::Figlet;

Tickit->new(
	root => Tickit::Widget::Figlet->new(
		font => 'standard',
		text => 'hello, world'
	)
)->run;

